FROM alpine:3.10
LABEL maintainer="Wazo Authors <dev@wazo.community>"
ENV VERSION 1.0.0

RUN apk add --update \
    bash \
    sngrep \
    curl \
    netcat-openbsd \
    kamailio \
    kamailio-db \
    kamailio-jansson \
    kamailio-json \
    kamailio-utils \
    kamailio-extras \
    kamailio-outbound \
    kamailio-http_async \
    kamailio-ev

COPY ./scripts/wait-for /usr/bin/wait-for
RUN chmod +x /usr/bin/wait-for

RUN mkdir -p /etc/kamailio
COPY kamailio/kamailio-local.cfg.example /etc/kamailio/kamailio-local.cfg.example
COPY kamailio/kamailio.cfg /etc/kamailio/kamailio.cfg
COPY kamailio/routing.cfg /etc/kamailio/routing.cfg
COPY kamailio/cdrs.cfg /etc/kamailio/cdrs.cfg

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
CMD ["/docker-entrypoint.sh"]
