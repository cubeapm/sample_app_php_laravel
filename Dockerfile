FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# For dev
RUN apt-get update && apt-get install -y vim curl wget

# Install PHP
RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:ondrej/php -y
RUN apt-get update && apt-get install -y --no-install-recommends unzip nginx php8.3 php8.3-cli php8.3-common php8.3-zip php8.3-mbstring php8.3-curl php8.3-xml php8.3-mysql php8.3-redis php8.3-sqlite3 php8.3-fpm ca-certificates

# php8.3-fpm needs this directory but doesn't create it
RUN mkdir /run/php

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Install Elastic APM PHP Agent
RUN wget https://github.com/elastic/apm-agent-php/releases/download/v1.15.0/apm-agent-php_1.15.0_amd64.deb && \
    dpkg -i apm-agent-php_1.15.0_amd64.deb && \
    rm apm-agent-php_1.15.0_amd64.deb

# Enable Elastic APM extension for both CLI and FPM
RUN echo "extension=elastic_apm.so" > /etc/php/8.3/mods-available/elastic_apm.ini && \
    echo "elastic_apm.bootstrap_php_part_file=/opt/elastic/apm-agent-php/src/bootstrap_php_part.php" >> /etc/php/8.3/mods-available/elastic_apm.ini && \
    echo "elastic_apm.server_url=http://host.docker.internal:3130" >> /etc/php/8.3/mods-available/elastic_apm.ini && \
    echo "elastic_apm.service_name=cube_sample_app_php_laravel_elastic" >> /etc/php/8.3/mods-available/elastic_apm.ini && \
    # optional settings
    echo "elastic_apm.environment=UNSET" >> /etc/php/8.3/mods-available/elastic_apm.ini && \
    echo "elastic_apm.service_version=1.2.3" >> /etc/php/8.3/mods-available/elastic_apm.ini && \
    echo 'elastic_apm.global_labels="mykey1=myvalue1,mykey2=myvalue2"' >> /etc/php/8.3/mods-available/elastic_apm.ini && \
    # Set Elastic agent log level to debug if needed to see detailed logs
    echo "elastic_apm.log_level=debug" >> /etc/php/8.3/mods-available/elastic_apm.ini && \
    phpenmod -v 8.3 -s ALL elastic_apm
    
# update nginx config
ADD nginx/default /etc/nginx/sites-available/default

# RUN composer create-project laravel/laravel sample_php_laravel

WORKDIR /sample_php_laravel

ADD . .

RUN composer install

RUN chown -R www-data:www-data .

EXPOSE 80
# RUN service php8.3-fpm restart
# RUN service nginx restart
CMD service php8.3-fpm start && nginx -g "daemon off;"
# EXPOSE 8000
# CMD ["php", "artisan", "serve", "--host=0.0.0.0"]
