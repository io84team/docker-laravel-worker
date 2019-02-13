FROM php:7.3-alpine

RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    shadow \
    zlib-dev \
    libzip-dev \
    gmp-dev \
    supervisor
    
RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data


###########################################################################
# PHP REDIS EXTENSION
###########################################################################

ARG INSTALL_PHPREDIS=true

RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    # Install Php Redis Extension
    printf "\n" | pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis \
;fi

###########################################################################
# MongoDB:
###########################################################################

ARG INSTALL_MONGO=false

RUN if [ ${INSTALL_MONGO} = true ]; then \
    # Install the mongodb extension
    pecl install mongodb && \
    docker-php-ext-enable mongodb \
;fi

###########################################################################
# ZipArchive:
###########################################################################

ARG INSTALL_ZIP_ARCHIVE=true

RUN if [ ${INSTALL_ZIP_ARCHIVE} = true ]; then \
    # Install the zip extension
    docker-php-ext-install zip \
;fi

###########################################################################
# GMP:
###########################################################################

ARG INSTALL_GMP=true

RUN if [ ${INSTALL_GMP} = true ]; then \
    # Install the gmp extension
    docker-php-ext-install gmp \
;fi

###########################################################################
# Exif:
###########################################################################

ARG INSTALL_EXIF=false

RUN if [ ${INSTALL_EXIF} = true ]; then \
    # Enable Exif PHP extentions requirements
    docker-php-ext-install exif \
;fi

###########################################################################
# Mysqli Modifications:
###########################################################################

ARG INSTALL_MYSQLI=true

RUN if [ ${INSTALL_MYSQLI} = true ]; then \
    docker-php-ext-install mysqli \
;fi

###########################################################################
# Human Language and Character Encoding Support:
###########################################################################

ARG INSTALL_INTL=false

RUN if [ ${INSTALL_INTL} = true ]; then \
    apk add --no-cache g++ zlib-dev icu-dev && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl \
;fi

###########################################################################
# GD:
###########################################################################

ARG INSTALL_GD=true

RUN if [ ${INSTALL_GD} = true ]; then \
    set -xe \
    && apk add --no-cache libpng-dev libjpeg-turbo-dev freetype-dev \
    && docker-php-ext-configure gd \
    --with-jpeg-dir=/usr/include \
    --with-freetype-dir=/usr/include/freetype2 \
    && docker-php-ext-install gd mbstring \
;fi

###########################################################################
# Mcrypt:
###########################################################################

ARG INSTALL_MCRYPT=true

RUN if [ ${INSTALL_MCRYPT} = true ]; then \
    set -xe \
    && apk add --no-cache libmcrypt-dev \
    && yes  "" | pecl install mcrypt-1.0.2 \
    && docker-php-ext-enable mcrypt \
;fi

###########################################################################
# PDO Mysql:
###########################################################################

RUN docker-php-ext-install pdo_mysql

RUN rm /var/cache/apk/*

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

COPY ./conf/supervisord.conf /etc/supervisord.conf
COPY ./conf/supervisord.d /etc/supervisord.d

RUN mkdir -p /app
RUN chown -R www-data:www-data /app

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisord.conf"]

VOLUME /app

WORKDIR /etc/supervisor/conf.d/