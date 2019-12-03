FROM alpine:3.10
LABEL maintainer="Wazo Authors <dev@wazo.community>"
ENV VERSION 1.0.0

RUN true \
    && apk add --update \
        bash \
        supervisor \
        sipsak \
        sngrep \
        curl \
        netcat-openbsd \
        kamailio \
        kamailio-db \
        kamailio-dbtext \
        kamailio-jansson \
        kamailio-json \
        kamailio-utils \
        kamailio-extras \
        kamailio-outbound \
        kamailio-http_async \
        kamailio-ev

RUN true \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --update \
        consul-template \
        envconsul \
    && rm -rf /var/lib/apt/lists/*

COPY ./scripts/wait-for /usr/bin/wait-for
RUN chmod +x /usr/bin/wait-for

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
