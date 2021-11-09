# Silicom STS1,STS2,STS3 PTP PCI card SRO usage

This is a repository of the helm charts needed to use the STS2 card from Silicom in the Openshift cluster environment.

## Notes
    * Installed to sts-silicom namespace.
    * Special Resource Operator version 4.9 is used.

## Prerequisites

### NFD configuration
This CR will configure NFD to label the nodes with the STS1, STS2, STS3
- feature.node.kubernetes.io/pci-0200_8086_1591_1374_02d0.present
- feature.node.kubernetes.io/pci-0200_8086_1591_1374_02de.present
- feature.node.kubernetes.io/pci-0200_8086_1591_1374_02d8.present

`oc apply -f cr/nfd/nfd_cr.yaml`

### SRO

Within the cr/sro directory, there is a file `setup.sh`. This is used to create and tear down the SRO for 4.9.

`./cr/sro/setup.sh`

#### STS discover daemon
After the SRO has build and deployed the drivercontainer, the sts-discovery daemonset will be deployed to the nodes with the card, and label the nodes accordingly. Use labels to add the correct field values to the StsConfig CR (example: cr/sts/stsconfig-gm.yaml)

`
iface.sts.silicom.com/enp2s0f0=down
iface.sts.silicom.com/enp2s0f1=down
iface.sts.silicom.com/enp2s0f2=down
iface.sts.silicom.com/enp2s0f3=down
iface.sts.silicom.com/enp2s0f4=down
iface.sts.silicom.com/enp2s0f5=down
iface.sts.silicom.com/enp2s0f6=down
iface.sts.silicom.com/enp2s0f7=down
`

## Usage

    * Get the ICE driver src
        `make ice.tgz`

    * Get the helm tool
        `make helm`

    * Create the sts2 helm package only
        `make package`

    * Deploy the helm package to the cluster using oc.
        `make oc-sts-silicom-configmap`

## STSConfig CRDS

Accepted modes are
- T-GM.8275.1
- T-BC-8275.1
- T-TSC.8275.1

### GM Mode
`oc apply -f cr/sts/stsconfig-gm.yaml`

### BC Mode
`oc apply -f cr/sts/stsconfig-bc.yaml`
