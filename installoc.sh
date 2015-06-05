#!/bin/bash

if [ -z "$OC_URL" ] ; then
    exit 0
else
    echo =================
    date
    echo =================
    mkdir -p /opt/owncloud-packages
    cd /opt/owncloud-packages

    wget $OC_URL

    if [[ $(basename ${OC_URL}) == *.tar.bz2 ]]; then
        tar -xjvf $(basename ${OC_URL})
    elif [[ $(basename ${OC_URL}) == *.tar.gz ]]; then
        tar -xxvf $(basename ${OC_URL})
    elif [[ $(basename ${OC_URL}) == *.zip ]]; then
        unzip $(basename ${OC_URL})
    fi

    rsync -rtvua /opt/owncloud-packages/owncloud/ /opt/owncloud/
    mkdir -p /opt/owncloud/data
    php /root/generate_autoconfig.php >  /opt/owncloud/config/autoconfig.php
    chown -R www-data: /opt/owncloud
fi
