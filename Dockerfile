FROM influxdb:latest

MAINTAINER Andreas Skoglund <andreas.skoglund@basefarm.com>

LABEL io.k8s.description="Kapacitor var-file testing" \
    io.k8s.display-name="Kapacitor-test" \
    io.openshift.expose-services="" \
    io.openshift.tags="influxdata,kapacitor,test"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y bash-completion procps python && \
    awk 'f{if(sub(/^#/,"",$0)==0){f=0}};/^# enable bash completion/{f=1};{print;}' /etc/bash.bashrc > /etc/bash.bashrc.new && \
    mv /etc/bash.bashrc.new /etc/bash.bashrc

ENV KAPACITOR_VERSION=1.5.0
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
      amd64) ARCH='amd64';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armhf';; \
      armel) ARCH='armel';; \
      *)     echo "Unsupported architecture: ${dpkgArch}"; exit 1;; \
    esac && \
    wget --no-verbose https://dl.influxdata.com/kapacitor/releases/kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
    dpkg -i kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb && \
rm -f kapacitor_${KAPACITOR_VERSION}_${ARCH}.deb*

COPY kapacitor.conf /etc/kapacitor/kapacitor.conf
RUN mkdir -p /etc/kapacitor/load/handlers && \
    mkdir -p /etc/kapacitor/load/tasks && \
    mkdir -p /etc/kapacitor/load/templates && \
    mkdir -p /var/local/kapacitor/sideload && \
    mkdir -p /alerts && \
    mkdir -p /checks && \
    mkdir -p /tests


COPY run.sh /run.sh
COPY alert.sh /alert.sh
COPY run_tests.sh /run_tests.sh
COPY check_tests.py /check_tests.py

COPY topic_handler_exec.yaml /etc/kapacitor/load/handlers/topic_handler_exec.yaml

ADD kapacitor-templates/*.* /etc/kapacitor/load/templates/
ADD kapacitor-var-files/*.* /etc/kapacitor/load/tasks/
ADD kapacitor-var-tests/checks/* /checks/
ADD kapacitor-var-tests/testdata/* /testdata/

ENTRYPOINT ["/run.sh"]

CMD ["/bin/true"]