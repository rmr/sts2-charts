#!/bin/bash

set -x

base=$(dirname $(realpath "${BASH_SOURCE[0]}"))
bin=$base/bin
PATH=$PATH:$bin
WEB_PORT=8080
sro_ns="sro"
ns="sts-silicom"

if $(oc get ns -A | grep -q $sro_ns) ; then
    oc delete ns $sro_ns
fi

if $(oc get ns -A | grep -q $ns) ; then
    oc delete ns $ns
fi

if $(oc get ns -A | grep -q driver-container-base) ; then
    oc delete ns driver-container-base
fi

oc label nodes worker2 specialresource.openshift.io/state-sts-silicom-0000-
oc label nodes worker2 specialresource.openshift.io/state-sts-silicom-1000-
oc label nodes worker2 specialresource.openshift.io/state-sts-silicom-3000-

# oc delete buildconfigs.build.openshift.io -n $ns --all
# oc delete imagetags.image.openshift.io -n $ns --all
# oc delete imagestreams.image.openshift.io -n $ns  --all
# oc delete daemonset  -n $ns --all
#if $(oc get crd -A | grep -q specialresources.sro.openshift.io) ; then
    # oc delete crd specialresources.sro.openshift.io
#fi

if ! $(oc describe configs.imageregistry.operator.openshift.io cluster | grep "Management State:  Managed") ; then
    echo "Registry not enabled."
    oc patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'
    oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
    oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
fi

if $(oc get apiservice -A | grep -q v1beta1.sro.openshift.io) ; then
    oc delete apiservice v1beta1.sro.openshift.io
fi

sleep 10

oc create ns $sro_ns

# Lose the images built.
oc rollout restart deploy -n openshift-image-registry

sleep 2

operator-sdk run bundle quay.io/ryan_raasch/special-resource-operator-bundle:4.9.0 --timeout 600s --verbose -n $sro_ns

sleep 15

# oc apply -k $base/config/clusteroperator

make -C $base/../.. oc-sts-silicom-configmap
