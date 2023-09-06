# Use the official PHP FPM image as the base image                                                                                                                                                                                                            
FROM php:8.1-fpm-alpine                                                                                                                                                                                                                                       

# Set the working directory                                                                                                                                                                                                                                   
WORKDIR /var/www/html                                                                                                                                                                                                                                         

ADD https://github.com/mlocati/docker-php-extension-installer/releases/download/2.1.37/install-php-extensions /usr/local/bin/                                                                                                                                 

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \                                                                                                                                                                                                   
    && echo "memory_limit = -1" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini \                                                                                                                                                                        
    && pecl install uploadprogress \                                                                                                                                                                                                                          
    && docker-php-ext-enable uploadprogress \                                                                                                                                                                                                                 
    && apk del .build-deps $PHPIZE_DEPS \                                                                                                                                                                                                                     
    && chmod uga+x /usr/local/bin/install-php-extensions && sync \                                                                                                                                                                                            
    && install-php-extensions bcmath bz2 calendar curl exif fileinfo ftp gd gettext imagick imap intl ldap mbstring mcrypt \                                                                                                                                  
    memcached mongodb mysqli opcache openssl pdo pdo_mysql pdo_pgsql redis soap sodium sysvsem sysvshm xmlrpc xsl zip \                                                                                                                                   
    &&  echo -e "\n opcache.enable=1 \n opcache.enable_cli=1 \n opcache.memory_consumption=128 \n opcache.interned_strings_buffer=8 \n opcache.max_accelerated_files=4000 \n opcache.revalidate_freq=60 \n opcache.fast_shutdown=1" >> /usr/local/etc/php/     conf.d/docker-php-ext-opcache.ini \                                                                                                                                                                                                                           
    &&  echo -e "\n xhprof.output_dir='/var/tmp/xhprof'" >> /usr/local/etc/php/conf.d/docker-php-ext-xhprof.ini \                                                                                                                                             
    && cd ~ \                                                                                                                                                                                                                                                 

    # Install composer                                                                                                                                                                                                                                            
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \                                                                                                                                                                            
    && php -r "copy('https://composer.github.io/installer.sig', 'signature');" \                                                                                                                                                                              
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === trim(file_get_contents('signature'))) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \                                       
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \                                                                                                                                                                              
    && php -r "unlink('composer-setup.php');" \                                                                                                                                                                                                               
    && rm /usr/local/etc/php/conf.d/docker-php-memlimit.ini \                                                                                                                                                                                                 
    # Install msmtp and rsync - To Send Mails on Production & Development                                                                                                                                                                                     
    && apk add msmtp rsync openssh-client curl zip unzip wget                                                                                                                                                                                                 

# Install required packages and extensions                                                                                                                                                                                                                    
RUN apk --no-cache add nginx supervisor                                                                                                                                                                                                                       

# Copy the Laravel application files into the container                                                                                                                                                                                                       
COPY . .                                                                                                                                                                                                                                                      

# Configure NGINX                                                                                                                                                                                                                                             
COPY nginx.conf /etc/nginx/nginx.conf                                                                                                                                                                                                                         
COPY site.conf /etc/nginx/conf.d/default.conf                                                                                                                                                                                                                 

# Copy Supervisor configuration                                                                                                                                                                                                                               
COPY supervisord.conf /etc/supervisord.conf                                                                                                                                                                                                                   

# Increase PHP Upload
RUN echo "file_uploads = On\n" \
    "memory_limit = 20M\n" \
    "upload_max_filesize = 20M\n" \
    "post_max_size = 20M\n" \
    "max_execution_time = 300\n" \
    > /usr/local/etc/php/conf.d/uploads.ini

# Expose port 80                                                                                                                                                                                                                                              
EXPOSE 80                                                                                                                                                                                                                                                     

# Start Supervisor to manage NGINX and PHP-FPM                                                                                                                                                                                                                
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]                                                                                                                                                                                                      

