# PHP-FPM Dockerfile for WordPress
# Optimized with necessary extensions and security hardening

ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm-alpine

LABEL maintainer="BPKAD Bengkalis <admin@bpkad.bengkaliskab.go.id>"
LABEL description="PHP-FPM optimized for WordPress"

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    # Build dependencies
    $PHPIZE_DEPS \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    icu-dev \
    libxml2-dev \
    oniguruma-dev \
    imagemagick-dev \
    # Runtime dependencies
    freetype \
    libjpeg-turbo \
    libpng \
    libwebp \
    libzip \
    icu-libs \
    imagemagick \
    bash \
    curl \
    wget \
    git \
    unzip \
    # MariaDB client
    mariadb-client

# Configure and install PHP extensions required by WordPress
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

RUN docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql \
    gd \
    intl \
    zip \
    exif \
    bcmath \
    opcache \
    soap \
    xml \
    mbstring

# Install ImageMagick extension (optional but recommended)
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Redis extension (optional, for object caching)
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install APCu (optional, for local object caching)
RUN pecl install apcu \
    && docker-php-ext-enable apcu

# Clean up build dependencies
RUN apk del $PHPIZE_DEPS \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Create healthcheck script
RUN echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck \
    && echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1' >> /usr/local/bin/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

# Install fcgi for healthcheck
RUN apk add --no-cache fcgi

# Download WordPress core (latest stable)
RUN curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /tmp \
    && rm /tmp/wordpress.tar.gz

# Set up WordPress directory
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

# Create log directories for PHP-FPM
RUN mkdir -p /var/log/php-fpm \
    && chown -R www-data:www-data /var/log/php-fpm \
    && chmod 755 /var/log/php-fpm

# Copy WordPress files to the container (will be used if volume is empty)
RUN cp -rp /tmp/wordpress/* /var/www/html/ \
    && rm -rf /tmp/wordpress

# Set proper permissions
RUN find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# Create entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html

# Switch to www-data user for security
USER www-data

EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]

