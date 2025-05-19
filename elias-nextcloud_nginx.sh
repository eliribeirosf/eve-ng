#!/bin/bash

set -e

echo "▶️ Instalando Docker e Docker Compose..."

apt update
apt install -y docker.io docker-compose curl nano

echo "▶️ Criando rede Docker externa 'nginx_proxy'..."
docker network create nginx_proxy || echo "Rede já existe"

echo "▶️ Subindo NGINX Proxy Manager..."
cat > docker-compose.nginx.yml <<EOF
version: '3'

services:
  npm-db:
    image: mariadb:10.5
    container_name: npm-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootSenhaForte
      MYSQL_DATABASE: npm
      MYSQL_USER: npm
      MYSQL_PASSWORD: senhaNpm123
    volumes:
      - npm_db:/var/lib/mysql
    networks:
      - nginx_proxy

  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "81:81"
    environment:
      DB_MYSQL_HOST: npm-db
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: npm
      DB_MYSQL_PASSWORD: senhaNpm123
      DB_MYSQL_NAME: npm
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt
    networks:
      - nginx_proxy

volumes:
  npm_db:
  npm_data:
  npm_letsencrypt:

networks:
  nginx_proxy:
    external: true
EOF

docker compose -f docker-compose.nginx.yml up -d

echo "▶️ Subindo Portainer..."
docker run -d \
  -p 9000:9000 \
  --name portainer \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce

echo "▶️ Subindo Nextcloud stack..."
cat > docker-compose.nextcloud.yml <<EOF
version: '3.8'

services:
  db:
    image: mariadb:11.3
    container_name: nextcloud-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD=MinhaSenhaRootAqui
      MYSQL_DATABASE=nextcloud
      MYSQL_USER=nextclouduser
      MYSQL_PASSWORD=SenhaDoBancoAqui
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - nextcloudnet
      - nginx_proxy

  redis:
    image: redis:alpine
    container_name: nextcloud-redis
    restart: unless-stopped
    networks:
      - nextcloudnet
      - nginx_proxy

  nextcloud:
    image: nextcloud:31.0.5-apache
    container_name: nextcloud-app
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      MYSQL_HOST=db
      MYSQL_DATABASE=nextcloud
      MYSQL_USER=nextclouduser
      MYSQL_PASSWORD=SenhaDoBancoAqui
      REDIS_HOST=redis
    volumes:
      - nextcloud_data:/var/www/html
    depends_on:
      - db
      - redis
    networks:
      - nextcloudnet
      - nginx_proxy

volumes:
  db_data:
  nextcloud_data:

networks:
  nextcloudnet:
    driver: bridge
  nginx_proxy:
    external: true
EOF

docker compose -f docker-compose.nextcloud.yml up -d

echo "▶️ Ambiente completo está no ar!"
echo "🌐 Acesse o NGINX Proxy Manager em http://<SEU_IP>:81"
echo "🌐 Acesse o Portainer em http://<SEU_IP>:9000"
echo "🌐 Acesse o Nextcloud em http://<SEU_IP>:8080"
echo "✅ Lembre-se de configurar o proxy reverso no NGINX Proxy Manager"

