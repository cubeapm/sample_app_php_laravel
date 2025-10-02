FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# For dev
RUN apt-get update && apt-get install -y vim curl

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

# Download and install the Datadog PHP tracer (inside container)
RUN curl -LO https://github.com/DataDog/dd-trace-php/releases/latest/download/datadog-setup.php \
  && php datadog-setup.php --php-bin php8.3 \
  && php datadog-setup.php --php-bin php-fpm8.3 \
  && rm datadog-setup.php

# Configure PHP-FPM pool to use Datadog INI values
RUN echo "\n\
php_value[datadog.trace.agent_url] = http://host.docker.internal:3130\n\
php_value[datadog.service]         = cube_sample_app_php_laravel_datadog\n\
php_value[datadog.env]             = myenv\n\
php_value[datadog.version]         = 1.2.3\n\
php_value[datadog.tags]            = mykey1:myvalue1,mykey2:myvalue2\n\
php_value[datadog.trace.log_file]  = "/var/log/php8.3-fpm.log"\n\
php_value[datadog.trace.debug]     = 1\n\  
php_value[datadog.trace.log_level] = debug\n"\
>> /etc/php/8.3/fpm/pool.d/www.conf

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
