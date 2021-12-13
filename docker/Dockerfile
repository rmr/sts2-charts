FROM golang:1.16
RUN apt update && apt install -y curl tar gzip golang

ARG ICE_VERSION="1.6.7"

RUN curl -sL https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz -o helm.tar.gz && \
    tar xvf helm.tar.gz && \
    chmod +x linux-amd64/helm && \
    mv linux-amd64/helm /usr/bin/helm

RUN curl -sL "https://sourceforge.net/projects/e1000/files/ice%20stable/${ICE_VERSION}/ice-${ICE_VERSION}.tar.gz/download" -o /ice.tgz

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
RUN mv kustomize /usr/bin/kustomize

WORKDIR /
ADD charts/ice-special-resource-0.0.1/templates charts/ice-special-resource-0.0.1/templates
ADD charts/ice-special-resource-0.0.1/Chart.yaml charts/ice-special-resource-0.0.1/Chart.yaml
ADD kustomization.yaml kustomization.yaml

RUN /bin/bash -c "echo \"---\" >> charts/ice-special-resource-0.0.1/templates/0000-state-driver-buildconfig.yaml"
RUN /bin/bash -c "kustomize build >> charts/ice-special-resource-0.0.1/templates/0000-state-driver-buildconfig.yaml"

WORKDIR /charts
RUN helm package ice-special-resource-0.0.1 -d . && \
    helm repo index .

WORKDIR /
ADD docker/main.go main.go
RUN GOOS=linux GOARCH=amd64  go build -ldflags="-w -s" -o server main.go

FROM registry.access.redhat.com/ubi8/ubi-minimal

COPY --from=0 /server /server
COPY --from=0 /charts/ice-special-resource-0.0.1.tgz /charts/ice-special-resource-0.0.1.tgz
COPY --from=0 /charts/index.yaml /charts/index.yaml

ENTRYPOINT [ "/server" ]
