
# https://deploy-preview-35687--osdocs.netlify.app/openshift-enterprise/latest/hardware_enablement/psap-special-resource-operator.html#using-the-special-resource-operator

HELM = $(shell pwd)/bin/linux-amd64/helm

.PHONY: package helm ns bundle

all: package

package:
	cd charts/sts-silicom-0.0.1 && $(HELM) package . -d $(shell pwd)

ice.tgz:
	curl -sL "https://sourceforge.net/projects/e1000/files/ice%20stable/1.6.4/ice-1.6.4.tar.gz/download" -o ice.tgz

helm:
	-rm -rf bin
	mkdir -p bin
	curl -sL https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz -o bin/helm.tar.gz
	tar xvf bin/helm.tar.gz -C bin
	chmod +x bin/linux-amd64/helm

sts-silicom-configmap: package
	mv sts-silicom-0.0.1.tgz charts/cm/
	cd charts && $(HELM) repo index cm --url=cm://sts-silicom/sts-silicom	

clean:
	-oc label nodes specialresource.openshift.io/state-sts-silicom-0000- --all
	-oc label nodes specialresource.openshift.io/state-sts-silicom-1000- --all
	-oc label nodes specialresource.openshift.io/state-sts-silicom-2000- --all
	-oc label nodes specialresource.openshift.io/state-sts-silicom-3000- --all

ns:
	- oc delete ns sts-silicom
	oc create ns sts-silicom

bundle: ns
	operator-sdk run bundle  quay.io/silicom/sts-operator-bundle:v0.0.1 --timeout 600s --verbose -n sts-silicom
	oc apply -f cr/sts/stsconfig-gm.yaml
	oc label nodes worker2 mode.sts.silicom.com/gm-1="true" --overwrite

oc-sts-silicom-configmap: clean sts-silicom-configmap ice.tgz ns
	oc delete specialresources.sro.openshift.io sts-silicom
	oc get nodes -l feature.node.kubernetes.io/custom-silicom.sts.devices=true
	oc create cm ice-driver --from-file=ice.tgz -n sts-silicom
	oc create cm sts-silicom --from-file=charts/cm/index.yaml --from-file=charts/cm/sts-silicom-0.0.1.tgz -n sts-silicom
	oc apply -f cr/sro/sts-silicom-cr.yaml
