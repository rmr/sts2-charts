# Silicom STS2 PTP PCI card SRO usage

This is a repository of the helm charts needed to use the STS2 card from Silicom in the Openshift cluster environment.

## Notes
    * Installed to sts-silicom namespace.
    * Special Resource Operator version 4.9 is used.


## Prerequisites

### SRO

Within the cr/sro directory, there is a file `setup.sh`. This is used to create and tear down the SRO for 4.9.

### NFD configuration
This CR will configure NFD to label the nodes with the STS2 (feature.node.kubernetes.io/usb-ff_1374_0001.present)

`oc apply cr/nfd_cr.yaml`

## Usage

    * Get the helm tool
        `make helm`

    * Create the sts2 helm package
        `make package`

    * Deploy the helm package to the cluster using oc.
        `make oc-sts-silicom-configmap`

##