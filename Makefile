
# https://deploy-preview-35687--osdocs.netlify.app/openshift-enterprise/latest/hardware_enablement/psap-special-resource-operator.html#using-the-special-resource-operator

HELM = $(shell pwd)/bin/linux-amd64/helm

.PHONY: package helm

all: package

package:
	cd charts/sts-silicom-0.0.1 && $(HELM) package . -d $(shell pwd)

helm:
	-rm -rf bin
	mkdir -p bin
	curl -sL https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz -o $(shell pwd)/bin/helm.tar.gz
	tar xvf $(shell pwd)/bin/helm.tar.gz -C bin
	chmod +x bin/linux-amd64/helm

sts-silicom-configmap: package
	mv sts-silicom-0.0.1.tgz charts/cm/
	cd charts && $(HELM) repo index cm --url=cm://sts-silicom/sts-silicom	

oc-sts-silicom-configmap: sts-silicom-configmap
	- oc delete cm sts-silicom -n sts-silicom
	- oc create namespace sts-silicom
	oc create cm sts-silicom --from-file=charts/cm/index.yaml --from-file=charts/cm/sts-silicom-0.0.1.tgz -n sts-silicom
	- oc delete -f cr/sro/sts-silicom-cr.yaml
	oc apply -f cr/sro/sts-silicom-cr.yaml
