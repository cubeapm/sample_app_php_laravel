FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ARG ELASTIC_APM_SERVER_URL=""

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

# Configure Elastic APM PHP Agent
RUN sed -i 's|;elastic_apm.service_name = "REPLACE_WITH_SERVICE_NAME"|elastic_apm.service_name = "cube_sample_app_php_laravel_elastic"|g' /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini
RUN sed -i "s|;elastic_apm.server_url = \"http://localhost:8200\"|elastic_apm.server_url = \"$ELASTIC_APM_SERVER_URL\"|g" /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini

# optional settings
# RUN sed -i 's|;elastic_apm.environment = "production"|elastic_apm.environment = "UNSET"|g' /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini
# RUN sed -i 's|;elastic_apm.service_version = "REPLACE_WITH_OUTPUT_FROM_git rev-parse HEAD"|elastic_apm.service_version = "1.2.3"|g' /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini
# RUN grep -q '^elastic_apm.global_labels' /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini \
#   && sed -i 's|^elastic_apm.global_labels.*|elastic_apm.global_labels = "mykey1=myvalue1,mykey2=myvalue2"|g' /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini \
#   || echo 'elastic_apm.global_labels = "mykey1=myvalue1,mykey2=myvalue2"' >> /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini

# Set Elastic agent log level to debug if needed to see detailed logs
RUN sed -i 's|;elastic_apm.log_level = "INFO"|elastic_apm.log_level = "DEBUG"|g' /opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini
    
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
