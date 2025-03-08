FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ARG NEW_RELIC_HOST=""

# For dev
RUN apt-get update && apt-get install -y vim curl

# Install PHP
RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:ondrej/php -y
RUN apt-get update && apt-get install -y --no-install-recommends unzip nginx php8.3 php8.3-cli php8.3-common php8.3-zip php8.3-mbstring php8.3-curl php8.3-xml php8.3-mysql php8.3-sqlite3 php8.3-fpm ca-certificates

# php8.3-fpm needs this directory but doesn't create it
RUN mkdir /run/php

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Install newrelic agent
RUN apt-get install -y wget
RUN echo 'deb [signed-by=/usr/share/keyrings/download.newrelic.com-newrelic.gpg] http://apt.newrelic.com/debian/ newrelic non-free' | tee /etc/apt/sources.list.d/newrelic.list
RUN wget -O- https://download.newrelic.com/548C16BF.gpg | gpg --dearmor -o /usr/share/keyrings/download.newrelic.com-newrelic.gpg
RUN apt-get update && apt-get install -y newrelic-php5

# update newrelic config
RUN sed -i 's/newrelic.license = ""/newrelic.license = "ABC4567890ABC4567890ABC4567890ABC4567890"/g' /etc/php/8.3/mods-available/newrelic.ini
RUN sed -i 's/newrelic.appname = "PHP Application"/newrelic.appname = "cube_sample_php_laravel_newrelic"/g' /etc/php/8.3/mods-available/newrelic.ini
RUN sed -i "s/;newrelic.daemon.collector_host = \"\"/newrelic.daemon.collector_host = \"$NEW_RELIC_HOST\"/g" /etc/php/8.3/mods-available/newrelic.ini
# remove irrelevant spans from traces (optional but highly recommended)
RUN sed -i 's/;newrelic.transaction_tracer.detail = 1/newrelic.transaction_tracer.detail = 0/g' /etc/php/8.3/mods-available/newrelic.ini
# set newrelic agent and daemon log level to debug
RUN sed -i 's/;newrelic.loglevel = "info"/newrelic.loglevel = "debug"/g' /etc/php/8.3/mods-available/newrelic.ini
RUN sed -i 's/;newrelic.daemon.loglevel = "info"/newrelic.daemon.loglevel = "debug"/g' /etc/php/8.3/mods-available/newrelic.ini

# update nginx config
ADD nginx/default /etc/nginx/sites-available/default

# RUN composer create-project laravel/laravel sample_php_laravel

WORKDIR /sample_php_laravel

ADD . .

RUN chown -R www-data:www-data .

EXPOSE 80
# RUN service php8.3-fpm restart
# RUN service nginx restart
CMD service php8.3-fpm start && nginx -g "daemon off;"
# EXPOSE 8000
# CMD ["php", "artisan", "serve", "--host=0.0.0.0"]
