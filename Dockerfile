FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# For dev
RUN apt-get update && apt-get install -y vim curl

# Install PHP
RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:ondrej/php -y
RUN apt-get update && apt-get install -y --no-install-recommends unzip nginx php8.3 php8.3-cli php8.3-common php8.3-zip php8.3-mbstring php8.3-curl php8.3-xml php8.3-mysql php8.3-redis php8.3-sqlite3 php8.3-fpm ca-certificates php-pear php8.3-dev libtool make gcc autoconf libz-dev zip

# php8.3-fpm needs this directory but doesn't create it
RUN mkdir /run/php

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# update nginx config
ADD nginx/default /etc/nginx/sites-available/default

# RUN composer create-project laravel/laravel sample_php_laravel

WORKDIR /sample_php_laravel

ADD . .

# Install PECL + enable extensions
RUN pecl install opentelemetry protobuf \
 && echo "extension=opentelemetry.so" > /etc/php/8.3/fpm/conf.d/20-opentelemetry.ini \
 && echo "extension=protobuf.so" > /etc/php/8.3/fpm/conf.d/20-protobuf.ini \
 && echo "extension=opentelemetry.so" > /etc/php/8.3/cli/conf.d/20-opentelemetry.ini \
 && echo "extension=protobuf.so" > /etc/php/8.3/cli/conf.d/20-protobuf.ini

# FOR FPM
# enable FPM stdout capture
RUN sed -i 's/;catch_workers_output = .*/catch_workers_output = yes/' /etc/php/8.3/fpm/pool.d/www.conf

# Append OTEL ENV
RUN { \
    echo 'env[OTEL_SERVICE_NAME] = "cube_sample_php_laravel_otel"'; \
    echo 'env[OTEL_EXPORTER_OTLP_COMPRESSION] = "gzip"'; \
    echo 'env[OTEL_EXPORTER_OTLP_PROTOCOL] = "http/protobuf"'; \
    echo 'env[OTEL_PHP_AUTOLOAD_ENABLED] = "true"'; \
    echo 'env[OTEL_PROPAGATORS] = "baggage,tracecontext"'; \
    # print traces to this file location /var/log/php8.3-fpm.log
    echo 'env[OTEL_TRACES_EXPORTER] = "console"'; \
    echo 'env[OTEL_LOG_LEVEL] = "debug"'; \
    # example for sending traces to CubeAPM OTLP collector
    # echo 'env[OTEL_EXPORTER_OTLP_TRACES_ENDPOINT] = "http://host.docker.internal:4318/v1/traces"'; \
 } >> /etc/php/8.3/fpm/pool.d/www.conf

# FOR CLI
# Use Environment variables (in docker-compose.yml)

# Disable composer plugin security warnings
RUN composer config allow-plugins.php-http/discovery false

RUN composer install

RUN chown -R www-data:www-data .

EXPOSE 80
# RUN service php8.3-fpm restart
# RUN service nginx restart
CMD service php8.3-fpm start && nginx -g "daemon off;"
# EXPOSE 8000
# CMD ["php", "artisan", "serve", "--host=0.0.0.0"]
