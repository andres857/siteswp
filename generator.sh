#!/bin/bash

read -p 'Database name: ' dbname
read -p 'Database username: ' dbuser
read -p 'Database password: ' dbpass
read -p 'domain:' wpdomain

echo

DIR="./$wpdomain"

if [ -d "$DIR" ]; then
 echo "${DIR} directory already exists"
 exit 0
fi

mkdir -p $wpdomain
mkdir -p $wpdomain/nginx/conf.d

cat <<EOT >> ./$wpdomain/docker-compose.yml/default.conf
version: '3'
services: 

    nginx:
        image: nginx:1.21.6-alpine
        restart: unless-stopped
        volumes:
            - ./nginx/conf.d:/etc/nginx/conf.d
            - ./html:/var/www/html
        environment:
            - VIRTUAL_HOST=$wpdomain
            - LETSENCRYPT_HOST=$wpdomain
            - LETSENCRYPT_EMAIL=info@windowschannel.com
        links:
            - wordpress
        expose: 
            - "80"

    wordpress: 
        image: wordpress:php8.1-fpm-alpine
        volumes:      
         - ./html:/var/www/html
        environment:
            - WORDPRESS_DB_HOST=db 
            - WORDPRESS_DB_NAME=$dbname
            - WORDPRESS_DB_USER=$dbuser
            - WORDPRESS_DB_PASSWORD=$dbpass

EOT

cat <<EOT >> ./$wpdomain/nginx/conf.d
server {  
	listen 80;  
	listen [::]:80;  
	access_log off;  
	root /var/www/html;  
	index index.php index.html;  
	server_tokens off;  

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		# With php-fpm (or other unix sockets):
		fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
		# With php-cgi (or other tcp sockets):
		#fastcgi_pass 127.0.0.1:9000;
	}

	}
EOT