FROM php:8.5-fpm-alpine

ARG WORDPRESS_VERSION=7.1

RUN apk add --no-cache \
    $PHPIZE_DEPS \
    nginx \
    supervisor \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    icu-dev \
    shadow \
    bash \
    curl \
    unzip

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        mysqli \
        pdo_mysql \
        gd \
        zip \
        intl \
        bcmath \
        exif

RUN pecl install redis \
    && docker-php-ext-enable redis

RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=32'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.jit=tracing'; \
    echo 'opcache.jit_buffer_size=128M'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
    echo 'memory_limit = 512M'; \
    echo 'upload_max_filesize = 64M';\
    echo 'post_max_size = 64M';\
    echo 'max_execution_time = 300';\
} > /usr/local/etc/php/conf.d/wordpress-limits.ini

RUN mkdir -p /var/run/php-fpm /run/nginx /var/cache/nginx /usr/share/aqn-wp && \
    usermod -u 82 www-data && \
    groupmod -g 82 www-data && \
    chown -R www-data:www-data /var/run/php-fpm /run/nginx /var/cache/nginx /usr/share/aqn-wp

WORKDIR /var/www/html

RUN curl -o wordpress.zip -fSL "https://wordpress.org/wordpress-$WORDPRESS_VERSION.zip" \
    && unzip wordpress.zip \
    && mv wordpress/* ./ \
    && rmdir wordpress \
    && rm wordpress.zip \
    && chown -R www-data:www-data /var/www/html

COPY src/php-fpm.d/* /usr/local/etc/php-fpm.d/
COPY src/aqn-wp/* /usr/share/aqn-wp/

COPY src/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY src/nginx.conf /etc/nginx/http.d/default.conf
COPY entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]