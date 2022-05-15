#!/bin/bash
read -p 'Database name: ' dbname
read -p 'Database username: ' dbuser
read -p 'Database password: ' dbpass
read -p 'domain:' wpdomain

echo

DIR="./$wpdomain"

if [ -d "$DIR" ]; then
 echo "${DIR} Directory already exists"
 exit 0
fi

mkdir -p $wpdomain
mkdir -p ./$wpdomain/nginx/conf.d

cat <<EOT >> ./$wpdomain/docker-compose.yml
version: '3'
services: 

    nginx:
        depends_on:
            - wordpress
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
            - 80

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

cat <<EOT >> ./$wpdomain/nginx/conf.d/nginx.conf
server {
        listen 80;
        listen [::]:80;

        server_name $wpdomain;

        index index.php index.html index.htm;

        root /var/www/html;

        location ~ /.well-known/acme-challenge {
                allow all;
                root /var/www/html;
        }

        location / {
                try_files $uri $uri/ /index.php$is_args$args;
        }

        location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass wordpress:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
        }

        location ~ /\.ht {
                deny all;
        }

        location = /favicon.ico {
                log_not_found off; access_log off;
        }
        location = /robots.txt {
                log_not_found off; access_log off; allow all;
        }
        location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
                expires max;
                log_not_found off;
        }
}
EOT
