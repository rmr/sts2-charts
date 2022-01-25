FROM golang

ARG ICE_VERSION="1.6.7"

RUN curl -sL https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz -o helm.tar.gz && \
    tar xvf helm.tar.gz && \
    chmod +x linux-amd64/helm && \
    mv linux-amd64/helm /usr/bin/helm

WORKDIR /
ADD charts/ice-special-resource-0.0.1/templates charts/ice-special-resource-0.0.1/templates
ADD charts/ice-special-resource-0.0.1/Chart.yaml charts/ice-special-resource-0.0.1/Chart.yaml

WORKDIR /charts
RUN helm package ice-special-resource-0.0.1 -d . && \
    helm repo index .

WORKDIR /
ADD docker/main.go main.go
RUN GOOS=linux GOARCH=amd64  go build -ldflags="-w -s" -o server main.go

FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG ICE_VERSION="1.6.7"
ARG ICE_URL="1.6.7"

COPY --from=0 /server /server
COPY --from=0 /charts/ice-special-resource-0.0.1.tgz /charts/ice-special-resource-0.0.1.tgz
COPY --from=0 /charts/index.yaml /charts/index.yaml
ADD "${ICE_URL}" /charts/ice.tgz

ENTRYPOINT [ "/server" ]
