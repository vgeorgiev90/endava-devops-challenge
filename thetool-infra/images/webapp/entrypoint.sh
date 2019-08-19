#!/bin/bash

set -x


/usr/sbin/php-fpm7.3
sed -i "s/DOMAIN/$DOMAIN/g" /etc/nginx/conf.d/website.conf
cd /usr/share/nginx/html
chown nginx:nginx .env
chmod 644 .env
sleep 5
npm run prod
sleep 2
php artisan migrate

exec "$@"
