FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# For dev
RUN apt-get update && apt-get install -y vim curl

# Install PHP
RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:ondrej/php -y
RUN apt-get update && apt-get install -y --no-install-recommends unzip nginx php8.3 php8.3-cli php8.3-common php8.3-zip php8.3-mbstring php8.3-curl php8.3-mysql php8.3-redis php8.3-sqlite3 php8.3-fpm ca-certificates php-pear php8.3-dev php8.3-xml libtool make gcc autoconf libz-dev zip

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

# Install required PHP extensions using pecl 
RUN pecl install opentelemetry protobuf && \
    echo "extension=opentelemetry.so" > /etc/php/8.3/cli/conf.d/20-opentelemetry.ini && \
    echo "extension=protobuf.so" > /etc/php/8.3/cli/conf.d/20-protobuf.ini && \
    echo "extension=opentelemetry.so" > /etc/php/8.3/fpm/conf.d/20-opentelemetry.ini && \
    echo "extension=protobuf.so" > /etc/php/8.3/fpm/conf.d/20-protobuf.ini

# Disable composer plugin security warnings
RUN composer config allow-plugins.php-http/discovery false

RUN composer install

RUN chown -R www-data:www-data .

# EXPOSE 80
# RUN service php8.3-fpm restart
# RUN service nginx restart
# CMD service php8.3-fpm start && nginx -g "daemon off;"
EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0"]
