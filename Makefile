
# https://deploy-preview-35687--osdocs.netlify.app/openshift-enterprise/latest/hardware_enablement/psap-special-resource-operator.html#using-the-special-resource-operator

HELM			?= $(shell pwd)/bin/linux-amd64/helm
SRO_NS			?= sro
OPERATOR_NS		?= sts-silicom
STS_NODE		?= worker2
SPECIAL_RESOURCE = ice-special-resource

.PHONY: package helm ns clean helm-chart sro-driver

all: package

package:
	cd charts/$(SPECIAL_RESOURCE)-0.0.1 && $(HELM) package . -d $(shell pwd)

ice.tgz:
	curl -sL "https://sourceforge.net/projects/e1000/files/ice%20stable/1.6.4/ice-1.6.4.tar.gz/download" -o ice.tgz

helm:
	-rm -rf bin
	mkdir -p bin
	curl -sL https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz -o bin/helm.tar.gz
	tar xvf bin/helm.tar.gz -C bin
	chmod +x bin/linux-amd64/helm

helm-chart: package
	-rm charts/cm/*.tgz
	mv $(SPECIAL_RESOURCE)-0.0.1.tgz charts/cm/
	cd charts && $(HELM) repo index cm --url=cm://$(SRO_NS)/$(SPECIAL_RESOURCE)

clean:
	-oc label nodes specialresource.openshift.io/state-$(ICE_SPECIAL_RESOURCE)-0000- --all
	-oc label nodes specialresource.openshift.io/state-$(ICE_SPECIAL_RESOURCE)-1000- --all

sro-ns:
	- oc delete ns $(SRO_NS)
	oc create ns $(SRO_NS)

operator-ns:
	- oc delete ns $(OPERATOR_NS)
	oc create ns $(OPERATOR_NS)

operator-bundle: operator-ns
	operator-sdk run bundle quay.io/silicom/sts-operator-bundle:v0.0.1 --timeout 600s --verbose -n $(OPERATOR_NS)
	oc label nodes $(STS_NODE) sts.silicom.com/config="gm-1" --overwrite
	oc apply -f cr/sts/stsconfig-gm.yaml

sro-bundle: sro-ns
	operator-sdk run bundle quay.io/silicom/special-resource-operator-bundle:4.9.0 --timeout 600s --verbose -n $(SRO_NS)
	oc apply -f cr/nfd/nfd_cr.yaml

lose-images:
	oc rollout restart deploy -n openshift-image-registry

$(SPECIAL_RESOURCE): clean helm-chart ice.tgz lose-images
	-oc delete -f cr/sro/ice-cr.yaml
	-oc delete cm $(SPECIAL_RESOURCE)  -n $(SRO_NS)
	-oc delete cm $(SPECIAL_RESOURCE)-src  -n $(SRO_NS)
	oc get nodes -l feature.node.kubernetes.io/custom-intel.e810_c.devices=true
	oc create cm $(SPECIAL_RESOURCE)-src --from-file=ice.tgz -n $(SRO_NS)
	oc create cm $(SPECIAL_RESOURCE) --from-file=charts/cm/index.yaml --from-file=charts/cm/$(SPECIAL_RESOURCE)-0.0.1.tgz -n $(SRO_NS)
	oc apply -f cr/sro/ice-cr.yaml

