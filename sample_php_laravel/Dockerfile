FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /sample_php_laravel

# Install PHP and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends unzip php php-cli php-common php-zip php-mbstring php-curl php-xml php-mysql php-sqlite3 ca-certificates

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN EXPECTED_HASH="dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6" && \
    ACTUAL_HASH="$(php -r 'echo hash_file("sha384", "composer-setup.php");')" && \
    if [ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]; then \
        echo 'ERROR: Invalid installer hash' && \
        rm composer-setup.php && \
        exit 1; \
    fi
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Add OpenTelemetry
RUN apt-get install -y gcc make autoconf php-dev php-pear libtool libz-dev zip
RUN pecl install opentelemetry protobuf
RUN printf '\n[opentelemetry]\nextension=opentelemetry.so\nextension=protobuf.so\n' >> `php --ini | grep /php.ini | cut -d : -f 2 | tr -d ' '`

COPY . /sample_php_laravel

WORKDIR /sample_php_laravel

# Set environment variable to allow Composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN composer install

# Set up OpenTelemetry
RUN composer config allow-plugins.php-http/discovery false
RUN composer require guzzlehttp/psr7 php-http/guzzle7-adapter open-telemetry/sdk open-telemetry/exporter-otlp open-telemetry/opentelemetry-auto-laravel

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0"]
