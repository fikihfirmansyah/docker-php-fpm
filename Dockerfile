FROM php:8.1.14-fpm-alpine3.17

LABEL MAINTAINER="Fikih Firmansyah" \
    "GitHub Link"="https://github.com/fikihfirmansyah" \
    "PHP Version"="8.1.14" \
    "Alpine Linux Version"="3.17"

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apk update \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && echo "memory_limit = -1" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini \
    && pecl install uploadprogress \
    && docker-php-ext-enable uploadprogress \
    && apk del .build-deps $PHPIZE_DEPS \
    && chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && install-php-extensions bcmath bz2 calendar curl exif fileinfo ftp gd gettext imagick imap intl ldap mbstring mcrypt \
    memcached mysqli opcache openssl pdo pdo_mysql pdo_pgsql soap sodium sysvsem sysvshm xmlrpc xsl zip gnupg \
    &&  echo -e "\n opcache.enable=1 \n opcache.enable_cli=1 \n opcache.memory_consumption=128 \n opcache.interned_strings_buffer=8 \n opcache.max_accelerated_files=4000 \n opcache.revalidate_freq=60 \n opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    &&  echo -e "\n xhprof.output_dir='/var/tmp/xhprof'" >> /usr/local/etc/php/conf.d/docker-php-ext-xhprof.ini \
    && cd ~ \
    # Install composer
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "copy('https://composer.github.io/installer.sig', 'signature');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === trim(file_get_contents('signature'))) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');" \
    && rm /usr/local/etc/php/conf.d/docker-php-memlimit.ini \
    # Install msmtp - To Send Mails on Production & Development
    && apk add msmtp \
    #Download the desired package(s)
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.2.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.apk \
    #(Optional) Verify signature, if 'gpg' is missing install it using 'apk add gnupg':
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.2.1-1_amd64.sig \
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.sig \
    && curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import - \
    && gpg --verify msodbcsql17_17.10.2.1-1_amd64.sig msodbcsql17_17.10.2.1-1_amd64.apk \
    && gpg --verify mssql-tools_17.10.1.1-1_amd64.sig mssql-tools_17.10.1.1-1_amd64.apk \
    #Install the package(s)
    && apk add --allow-untrusted msodbcsql17_17.10.2.1-1_amd64.apk \
    && apk add --allow-untrusted mssql-tools_17.10.1.1-1_amd64.apk

RUN apk update && \
    apk add --no-cache \
        php81 \
        php81-dev \
        php81-pear \
        php81-mbstring \
        php81-mysqli \
        php81-json \
        php81-openssl \
        make \
        autoconf-archive \
        gcc \
        g++ \
        libc-dev \
        pkgconf \
        libffi-dev \
        openssl-dev \
	unixodbc-dev \
    && pecl install sqlsrv \ 
    && pecl install pdo_sqlsrv \ 
    && echo -e "extension=pdo_sqlsrv.so" > /usr/local/etc/php/conf.d/10_pdo_sqlsrv.ini \ 
    && echo -e "extension=sqlsrv.so" > /usr/local/etc/php/conf.d/20_sqlsrv.ini 
