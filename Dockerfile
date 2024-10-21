FROM alpine:latest

ENV TZ Etc/UTC
ENV ITFLOW_NAME ITFlow
ENV ITFLOW_URL demo.itflow.org
ENV ITFLOW_PORT 443
ENV ITFLOW_REPO github.com/itflow-org/itflow
ENV ITFLOW_REPO_BRANCH master
# apache2 log levels: emerg, alert, crit, error, warn, notice, info, debug
ENV ITFLOW_LOG_LEVEL warn
ENV ITFLOW_DB_HOST itflow-db
ENV ITFLOW_DB_PASS null


RUN apk update && apk upgrade && \
    apk add --no-cache \
        apache2 \
        apache2-proxy \
        apache2-ssl \
        php83 \
        php83-intl \
        php83-imap \
        php83-pecl-mailparse \
        php83-mysqli \
        php83-curl \
        php83-gd \
        php83-mbstring \
        php83-apache2 \
        git \
        whois \
        openssl \
        openrc

RUN sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf && \
    sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /etc/apache2/httpd.conf && \
    mkdir /var/www/itflow

WORKDIR /var/www/itflow

COPY entrypoint.sh /usr/bin/

RUN chmod +x /usr/bin/entrypoint.sh

RUN ln -sf /dev/stdout /var/log/apache2/access.log && ln -sf /dev/stderr /var/log/apache2/error.log

ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE $ITFLOW_PORT

CMD [ "rc-service ", "apache2", "start"]