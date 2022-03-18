
# https://deploy-preview-35687--osdocs.netlify.app/openshift-enterprise/latest/hardware_enablement/psap-special-resource-operator.html#using-the-special-resource-operator

HELM			?= $(shell pwd)/bin/helm
SRO_NS			?= openshift-operators
OPERATOR_NS		?= openshift-operators
OPERATOR_VER	?= 0.0.4
STS_NODE		?= worker2
SPECIAL_RESOURCE = ice-special-resource

ICE_STABLE      := https://sourceforge.net/projects/e1000/files/ice%20stable
ICE_UNSUPPORTED := https://sourceforge.net/projects/e1000/files/unsupported/ice%20unsupported

ICE_URL_AUTOMATED_STABLE := $(shell curl -sL 'https://sourceforge.net/projects/e1000/rss?path=/ice%20stable' | xmllint --xpath '//item/link[contains(text(),"tar.gz")]/text()' - | sort | tail -n1)
ICE_URL_AUTOMATED_UNSUPPORTED := $(shell curl -sL 'https://sourceforge.net/projects/e1000/rss?path=/unsupported/ice%20unsupported' | xmllint --xpath '//item/link[contains(text(),"tar.gz")]/text()' - | sort | tail -n1)

ICE_VERSION := $(shell curl -sL 'https://sourceforge.net/projects/e1000/rss?path=/ice%20stable' | xmllint --xpath '//item/link[contains(text(),"tar.gz")]/text()' - | sort | tail -n1 | sed -n 's/^.*ice-\(.*\).tar.gz\/download/\1/p')
ICE_VERSION_UNSUPPORTED := $(shell curl -sL 'https://sourceforge.net/projects/e1000/rss?path=/unsupported/ice%20unsupported' | xmllint --xpath '//item/link[contains(text(),"tar.gz")]/text()' - | sort | tail -n1 | sed -n 's/^.*ice-\(.*\).tar.gz\/download/\1/p')

.PHONY: package helm ns clean helm-chart sro-driver ice-unsupported ice-stable

all: package

package:
	cd charts/$(SPECIAL_RESOURCE)-0.0.1 && $(HELM) package . -d $(shell pwd)/../

ice-unsupported:
	curl -sL "$(ICE_URL_AUTOMATED_UNSUPPORTED)" -o ice.tgz

ice-stable:
	curl -sL "$(ICE_URL_AUTOMATED_STABLE)" -o ice.tgz

helm:
	-rm -rf bin
	mkdir -p bin
	curl -sL https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz -o bin/helm.tar.gz
	tar xvf bin/helm.tar.gz -C bin && mv bin/linux-amd64/helm bin/
	chmod +x $(HELM)

charts: helm-chart-k8s helm-chart-github
helm-chart-index: package
	$(HELM) repo index .

clean:
	-oc label nodes specialresource.openshift.io/state-$(ICE_SPECIAL_RESOURCE)-0000- --all
	-oc label nodes specialresource.openshift.io/state-$(ICE_SPECIAL_RESOURCE)-1000- --all

sro-ns:
	- oc delete ns $(SRO_NS)
	oc create ns $(SRO_NS)

operator-sdk:
	-mkdir bin
	curl -sL https://github.com/operator-framework/operator-sdk/releases/download/v1.16.0/operator-sdk_linux_amd64 -o bin/operator-sdk
	chmod +x bin/operator-sdk

operator-bundle:
	-bin/operator-sdk cleanup silicom-sts-operator --timeout 600s --verbose -n $(SRO_NS)
	-oc delete subscriptions.operators.coreos.com -n openshift-operators silicom-sts-operator-v0-0-4-sub
	-oc delete pods -n openshift-operators quay-io-silicom-sts-operator-bundle-0-0-4
	-oc delete catalogsources.operators.coreos.com -n openshift-operators silicom-sts-operator-catalog
	-oc delete crds stsconfigs.sts.silicom.com
	-oc delete crds stsnodes.sts.silicom.com
	-oc delete crds stsoperatorconfigs.sts.silicom.com
	-oc delete csvs silicom-sts-operator.v$(OPERATOR_VER)
	- for ns in $$(oc get csvs -A | grep silicom-sts | awk '{print $$1}'); do oc delete csv silicom-sts-operator.v$(OPERATOR_VER) -n $$ns; done
	bin/operator-sdk run bundle quay.io/silicom/sts-operator-bundle:$(OPERATOR_VER) --timeout 800s --verbose -n $(OPERATOR_NS)
	oc label nodes $(STS_NODE) sts.silicom.com/config="gm-1" --overwrite
	sleep 60
#	oc apply -f cr/sts/stsoperator-config.yaml
#	oc apply -f cr/sts/stsconfig-gm.yaml

sro-bundle: sro-ns
	-oc delete apiservices.apiregistration.k8s.io v1beta1.sro.openshift.io
	bin/operator-sdk run bundle quay.io/silicom/special-resource-operator-bundle:4.9.0 --timeout 600s --verbose -n $(SRO_NS)

lose-images:
	oc rollout restart deploy -n openshift-image-registry

$(SPECIAL_RESOURCE): clean helm-chart ice.tgz lose-images
	-oc delete -f cr/sro/ice-cr.yaml
	-oc delete cm $(SPECIAL_RESOURCE)  -n $(SRO_NS)
	-oc delete cm $(SPECIAL_RESOURCE)-src  -n $(SRO_NS)
	oc get nodes -l feature.node.kubernetes.io/custom-intel.e810_c.devices=true
	oc create cm $(SPECIAL_RESOURCE)-src --from-file=ice.tgz -n $(SRO_NS)
	oc create cm $(SPECIAL_RESOURCE) --from-file=charts/cm/index.yaml --from-file=charts/cm/$(SPECIAL_RESOURCE)-0.0.1.tgz -n $(SRO_NS)
#	oc apply -f cr/sro/ice-cr.yaml

charts-image: ice-stable
	docker build . --build-arg ICE_URL=$(ICE_URL_STABLE) --build-arg ICE_VERSION=$(ICE_VERSION) -f docker/Dockerfile -t quay.io/silicom/ice-driver-src:$(ICE_VERSION)

charts-image-unsupported: ice-unsupported
	docker build . --build-arg ICE_VERSION=$(ICE_VERSION_UNSUPPORTED) -f docker/Dockerfile -t quay.io/silicom/ice-driver-src:$(ICE_VERSION_UNSUPPORTED)

charts-image-push:
	docker push quay.io/silicom/ice-driver-src:$(ICE_VERSION)

charts-image-unsupported-push:
	docker push quay.io/silicom/ice-driver-src:$(ICE_VERSION_UNSUPPORTED)
