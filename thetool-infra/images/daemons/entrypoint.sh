#!/bin/bash
#Entry point script for laravel daemons

set -x

cmd="${1}"
cd /usr/share/nginx/html
case ${cmd} in
	## If container is run with websocket cmd arg , execute websocket
	'websocket')
		php artisan websockets:serve
		;;
	## queue worker process
	'queue')
		php artisan horizon
		;;
	## cron scheduler process
	'scheduler')
		job=$(crontab -l | head -1)
		if [ -z "$job" ];then
		    echo "* * * * * cd /usr/share/nginx/html && php artisan schedule:run >> /root/cron-log 2>&1" | crontab - 
		    /usr/sbin/cron -f
		else
		    /usr/sbin/cron -f
		fi
		;;
	## Default catch all
	*)
		echo "Allowed options: websocket, queue, scheduler"
		;;
esac

