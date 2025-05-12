FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# For dev
RUN apt-get update && apt-get install -y vim curl

# Install PHP
RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:ondrej/php -y
RUN apt-get update && apt-get install -y --no-install-recommends unzip nginx php8.4 php8.4-cli php8.4-common php8.4-zip php8.4-mbstring php8.4-curl php8.4-mysql php8.4-redis php8.4-sqlite3 php8.4-fpm ca-certificates php-pear php-dev libtool make gcc autoconf libz-dev zip

# php8.4-fpm needs this directory but doesn't create it
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
    echo "extension=opentelemetry.so" > /etc/php/8.4/cli/conf.d/20-opentelemetry.ini && \
    echo "extension=protobuf.so" > /etc/php/8.4/cli/conf.d/20-protobuf.ini && \
    echo "extension=opentelemetry.so" > /etc/php/8.4/fpm/conf.d/20-opentelemetry.ini && \
    echo "extension=protobuf.so" > /etc/php/8.4/fpm/conf.d/20-protobuf.ini

# Disable composer plugin security warnings
RUN composer config allow-plugins.php-http/discovery false

RUN composer install

RUN chown -R www-data:www-data .

# EXPOSE 80
# RUN service php8.4-fpm restart
# RUN service nginx restart
# CMD service php8.4-fpm start && nginx -g "daemon off;"
EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0"]
