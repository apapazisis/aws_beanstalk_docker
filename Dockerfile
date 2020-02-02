FROM php:7.2.14-fpm

RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libpng-dev \
    libxml2-dev \
    vim \
    curl \
    supervisor \
    zip \
    unzip

RUN docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql \
    mbstring \
    bcmath \
    zip \
    pcntl \
    gd \
    iconv \
    xml \
    ctype \
    json \
    tokenizer \
    calendar \
    soap \
    intl

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -
RUN apt-get install -y nodejs

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY laravel-worker.conf /etc/supervisor/conf.d
CMD supervisord -c /etc/supervisor/conf.d/laravel-worker.conf
