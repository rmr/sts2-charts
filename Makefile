
# https://deploy-preview-35687--osdocs.netlify.app/openshift-enterprise/latest/hardware_enablement/psap-special-resource-operator.html#using-the-special-resource-operator

HELM			?= $(shell pwd)/bin/linux-amd64/helm
SRO_NS			?= openshift-operators
OPERATOR_NS		?= openshift-operators2
OPERATOR_VER	?= 0.0.2
STS_NODE		?= worker2
SPECIAL_RESOURCE = ice-special-resource
ICE_VERSION      ?= 1.7.16
ICE_VERSION_UNSUPPORTED ?= 1.7.16.1

ICE_STABLE      := https://sourceforge.net/projects/e1000/files/ice%20stable
ICE_UNSUPPORTED := https://sourceforge.net/projects/e1000/files/unsupported/ice%20unsupported

ICE_URL_UNSUPPORTED	?= $(ICE_UNSUPPORTED)/$(ICE_VERSION_UNSUPPORTED)/ice-$(ICE_VERSION_UNSUPPORTED).tar.gz/download
ICE_URL_STABLE   	?= $(ICE_STABLE)/$(ICE_VERSION)/ice-$(ICE_VERSION).tar.gz/download

.PHONY: package helm ns clean helm-chart sro-driver

all: package

package:
	cd charts/$(SPECIAL_RESOURCE)-0.0.1 && $(HELM) package . -d $(shell pwd)

ice.tgz:
	curl -sL "https://sourceforge.net/projects/e1000/files/ice%20stable/$(ICE_VERSION)/ice-$(ICE_VERSION).tar.gz/download" -o ice.tgz

helm:
	-rm -rf bin
	mkdir -p bin
	curl -sL https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz -o bin/helm.tar.gz
	tar xvf bin/helm.tar.gz -C bin
	chmod +x bin/linux-amd64/helm

helm-chart: package
	-rm charts/cm/*.tgz
	mv $(SPECIAL_RESOURCE)-0.0.1.tgz charts/cm/
	cd charts && $(HELM) repo index cm --url=http://ice-driver-src:3000/ice-special-resource/

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

operator-ns:
	-oc delete ns $(OPERATOR_NS)
	oc create ns $(OPERATOR_NS)
	-oc get clusterrolebindings | grep silicom | awk '{print $1}' | xargs oc delete clusterroles
	-oc get clusterroles | grep silicom | awk '{print $1}' | xargs oc delete clusterroles
	-oc delete csvs silicom-sts-operator.v$(OPERATOR_VER)

operator-bundle: operator-ns
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

charts-image:
	docker build . --build-arg ICE_URL=$(ICE_URL_STABLE) --build-arg ICE_VERSION=$(ICE_VERSION) -f docker/Dockerfile -t quay.io/silicom/ice-driver-src:$(ICE_VERSION)

charts-image-unsupported:
	docker build . --build-arg ICE_URL=$(ICE_URL_UNSUPPORTED) --build-arg ICE_VERSION=$(ICE_VERSION_UNSUPPORTED) -f docker/Dockerfile -t quay.io/silicom/ice-driver-src:$(ICE_VERSION_UNSUPPORTED)

charts-image-push:
	docker push quay.io/silicom/ice-driver-src:$(ICE_VERSION)

charts-image-unsupported-push:
	docker push quay.io/silicom/ice-driver-src:$(ICE_VERSION_UNSUPPORTED)
