FROM php:7.2.4-apache
MAINTAINER Ricardo Coelho <rcoelho@mpma.mp.br>

ARG context
RUN a2enmod rewrite
RUN apt-get update
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install --no-install-recommends -y \
        git \
        libpq-dev \
        libicu-dev \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxslt1-dev \
        libldb-dev \
        libmemcached-dev \
        freetds-dev \        
        build-essential \
        libaio1 \
        libldap2-dev
ENV DEBIAN_FRONTEND teletype
RUN docker-php-ext-install -j$(nproc) pgsql pdo_pgsql pdo_mysql ldap xsl gettext mysqli \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd intl zip \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

COPY assets/oracle /opt/oracle/
COPY assets/php.ini /usr/local/etc/php/
COPY assets/000-default.conf /etc/apache2/sites-available/

RUN gunzip /opt/oracle/instantclient_12_2/*.gz
RUN ln /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so \
    && ln /opt/oracle/instantclient_12_2/libocci.so.12.1 /opt/oracle/instantclient_12_2/libocci.so \
    && echo /opt/oracle/instantclient_12_2 > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig \
    && echo "instantclient,/opt/oracle/instantclient_12_2" | pecl install oci8 \
    && docker-php-ext-configure pdo_oci \
       --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_2,12.2 \
    && docker-php-ext-install pdo_oci \
    && docker-php-ext-configure pdo_dblib --with-libdir=/lib/x86_64-linux-gnu \
    && docker-php-ext-install pdo_dblib \
    && git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached \
    && cd /usr/src/php/ext/memcached && git checkout -b php7 origin/php7 \
    && docker-php-ext-configure memcached && docker-php-ext-install memcached \
    && docker-php-ext-enable memcached oci8 pdo_oci pdo_dblib

