# ICE driver for the E810-C

This is a repository of the helm charts needed to use the newer ICE out of tree driver source in the Openshift cluster environment.

`feature.node.kubernetes.io/custom-intel.e810-c.devices=true`

## Notes
    * Installed to namespace.
    * Deploy sts-silicom-operator bundle
    * Special Resource Operator version 4.9 is used.

## Prerequisites

### SRO

Create and tear down the SRO for 4.9.

`make sro-bundle`

### ICE special resource

Start the build and driver container charts.

`make ice-special-resource`

### STS Operator bundle

Create and tear down the sts bundle operator.

`make operator-bundle`


## Usage

    * Get the ICE driver src
        `make ice.tgz`

    * Get the helm tool
        `make helm`

    * Create the sts2 helm package only
        `make package`

    * Deploy the SRO bundle and the NFD configuration
        `make sro-bundle`

    * Deploy the helm package to the cluster using oc.
        `make ice-special-resource`

## STSConfig CRDS

Accepted modes are
- T-GM.8275.1
- T-BC-8275.1
- T-TSC.8275.1

### GM Mode
`oc apply -f cr/sts/stsconfig-gm.yaml`

### BC Mode
`oc apply -f cr/sts/stsconfig-bc.yaml`
