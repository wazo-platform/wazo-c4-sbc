FROM debian:buster-slim
LABEL maintainer="Wazo Authors <dev@wazo.community>"
ENV VERSION 1.0.0

RUN apt-get update -qq && apt-get install -y --no-install-recommends gnupg2
RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xfb40d3e6508ea4c8

RUN echo "deb     http://deb.kamailio.org/kamailio52 buster main" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.kamailio.org/kamailio52 buster main" >> /etc/apt/sources.list

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
bash \
supervisor \
sipsak \
sngrep \
net-tools \
inetutils-ping \
sip-tester \
curl \
kamailio \
sudo \
netcat \
consul \
iproute2 \
kamailio-json-modules \
kamailio-utils-modules \
kamailio-extra-modules \
kamailio-xml-modules \
&& apt-get clean

COPY ./scripts/wait-for /usr/bin/wait-for
RUN chmod +x /usr/bin/wait-for

RUN curl -SLOk https://releases.hashicorp.com/consul-template/0.23.0/consul-template_0.23.0_linux_amd64.tgz \
    && tar -xvf consul-template_0.23.0_linux_amd64.tgz \
    && chmod a+x consul-template \
    && mv consul-template /usr/sbin/ \
    && rm -rf consul-template*

RUN mkdir -p /etc/kamailio
COPY kamailio/kamailio-local.cfg.example /etc/kamailio/kamailio-local.cfg.example
COPY kamailio/kamailio.cfg /etc/kamailio/kamailio.cfg
COPY kamailio/xhttp.cfg /etc/kamailio/xhttp.cfg
COPY kamailio/dispatcher.list /etc/kamailio/dispatcher.list
COPY kamailio/dbtext /etc/kamailio/dbtext
COPY consul-templates /consul-templates
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
CMD ["/docker-entrypoint.sh"]
