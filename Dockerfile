FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive


# Install PHP and create basic project

RUN apt-get update && apt-get install -y --no-install-recommends unzip php php-cli php-common php-zip php-mbstring php-curl php-xml php-mysql php-sqlite3 ca-certificates

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

RUN composer create-project laravel/laravel sample_php_laravel

WORKDIR /sample_php_laravel



# Add OpenTelemetry

RUN apt-get install -y gcc make autoconf php-dev php-pear libtool libz-dev zip
RUN pecl install opentelemetry protobuf
RUN printf '\n[opentelemetry]\nextension=opentelemetry.so\nextension=protobuf.so\n' >> `php --ini | grep /php.ini | cut -d : -f 2 | tr -d ' '`

RUN composer config allow-plugins.php-http/discovery false
RUN composer require guzzlehttp/psr7 php-http/guzzle7-adapter open-telemetry/sdk open-telemetry/exporter-otlp open-telemetry/opentelemetry-auto-laravel



EXPOSE 8000

CMD ["php", "artisan", "serve"]
