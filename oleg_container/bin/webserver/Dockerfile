#Container needs driver to conect mysql
FROM php:7.2.2-apache
RUN docker-php-ext-install mysqli 
RUN docker-php-ext-enable mysqli
RUN a2enmod rewrite
RUN  apachectl restart

#Add other programs that you need, ex: 
RUN apt-get update
RUN apt-get install nano

