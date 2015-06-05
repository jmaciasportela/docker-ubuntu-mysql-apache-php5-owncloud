FROM phusion/baseimage:latest
MAINTAINER Jesus Macias <jesus@owncloud.com>
ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables
ENV HOME /root
# Fix a Debianism of the nobody's uid being 65534
RUN usermod -u 99 nobody
RUN usermod -g 100 nobody

# Activar SSH
RUN rm -fr /etc/service/sshd/down

# Update root password
# CHANGE IT # to something like root:ASdSAdfÑ3
RUN echo "root:root" | chpasswd

# Enable ssh for root
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
# Enable this option to prevent SSH drop connections
RUN printf "ClientAliveInterval 15\\nClientAliveCountMax 8" >> /etc/ssh/sshd_config

#Setup environment
ENV OC_URL http://download.owncloud.org/community/owncloud-daily-master.tar.bz2
ENV OC_ADMIN_USER admin
ENV OC_ADMIN_PASS Password
ENV DB_REMOTE_ROOT_USER root
ENV DB_REMOTE_ROOT_PASS owncloud

# Push install script
ADD installoc.sh /etc/my_init.d/10_installoc.sh
RUN chmod +x /etc/my_init.d/10_installoc.sh

# Install owncloud dependencies
RUN apt-get update -q && apt-get install -y --force-yes apache2 php5 php5-mysql php5-common php5-gd php-xml-parser php5-intl php5-mcrypt php5-curl php5-json php5-ldap php-soap php5-xdebug wget rsync unzip

# Modify php.ini
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 5000M/g' /etc/php5/apache2/php.ini
RUN sed -i 's/post_max_size = 8M/post_max_size = 5000M/g' /etc/php5/apache2/php.ini
RUN sed -i 's/;default_charset = "UTF-8"/default_charset = "UTF-8"/g' /etc/php5/apache2/php.ini

#Enable Xdebug
# Added for xdebug
RUN printf "xdebug.remote_enable=1\\nxdebug.remote_handler=dbgp\\nxdebug.remote_mode=req\\nxdebug.remote_host=0.0.0.0\\nxdebug.remote_port=9000" >> /etc/php5/mods-available/xdebug.ini

# Install mysql-server with default password for root -> owncloud
RUN echo 'mysql-server-5.5 mysql-server/root_password  password owncloud' | debconf-set-selections
RUN echo 'mysql-server-5.5 mysql-server/root_password_again password owncloud' | debconf-set-selections
RUN apt-get install mysql-server -y

# Generate selfsigned certificate
RUN mkdir /etc/apache2/ssl
# CHANGE ME # your.server.com to your server FQDN
RUN printf "ES\\nCYL\\nValladolid\\nOwncloud\\nDocker\\nyour.server.com\\n\\n" | openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -keyout /etc/apache2/ssl/server.key -out /etc/apache2/ssl/server.crt

# Configure apache to run owncloud
ADD apache_owncloud.conf /etc/apache2/sites-available/
RUN a2dissite 000-default
RUN a2ensite apache_owncloud
RUN a2enmod ssl

# Install phpMyadmin
RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password owncloud' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/app-pass password owncloud' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/app-password-confirm password owncloud' | debconf-set-selections
RUN service mysql start && sleep 5 && service mysql status && apt-get install phpmyadmin -y

# Configure Apache service
RUN mkdir /etc/service/apache2
RUN echo '#!/bin/sh' > /etc/service/apache2/run
RUN echo 'exec /usr/sbin/apache2ctl -D FOREGROUND' >> /etc/service/apache2/run && chmod +x /etc/service/apache2/run

# Configure Mysql service
RUN mkdir /etc/service/mysql
RUN echo '#!/bin/sh' > /etc/service/mysql/run
RUN echo 'exec /usr/bin/mysqld_safe' >> /etc/service/mysql/run && chmod +x /etc/service/mysql/run

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Autoconfig owncloud
ADD generate_autoconfig.php /root/generate_autoconfig.php

# Push mysql reset password on boot
ADD reset_mysql_pwd.sh /etc/my_init.d/02_reset_mysql_pwd.sh
RUN chmod +x /etc/my_init.d/02_reset_mysql_pwd.sh

# Expose port. Cannot be modified!
EXPOSE 22 80 443 9000

# Expose ownCloud's data dir
VOLUME ["/opt/owncloud/data"]

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]
