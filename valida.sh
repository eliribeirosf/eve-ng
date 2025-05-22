
echo "*******************************************************"
echo "*                                                     *"
echo "*                       JOTA'S                        *"
echo "*                     SOLUÇÕES EM TI                  *"
echo "*                                                     *"
echo "*******************************************************"

echo Este script irá instalar e configurar o Docker - Grafana, MySQL e Zabbix.

sleep 3

#!/bin/bash

# Instalação das dependências
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Adiciona a chave GPG do repositório do Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Adiciona o repositório do Docker ao sistema
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Atualiza a lista de pacotes e instala o Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Inicia e habilita o serviço do Docker
systemctl start docker
systemctl enable docker

#!/bin/bash

# Configuração para parar o script em caso de erro
set -e

# Inicia os contêineres do Grafana, MySQL e Zabbix
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.9.3 ||
{ echo "Erro ao iniciar o contêiner Portainer"; exit 1; }

docker run -d -p 3000:3000 --name grafana grafana/grafana-enterprise ||
{ echo "Erro ao iniciar o contêiner Grafana"; exit 1; }

docker run --name mysql-server -t -e MYSQL_DATABASE="zabbix" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="zabbix" -e MYSQL_ROOT_PASSWORD="zabbix" -d mysql:8.0.30 --character-set-server=utf8 --collation-server=utf8_bin --default-authentication-plugin=mysql_native_password ||
{ echo "Erro ao iniciar o contêiner MySQL"; exit 1; }

docker run --name zabbix-java-gateway -t --restart unless-stopped -d zabbix/zabbix-java-gateway ||
{ echo "Erro ao iniciar o contêiner Zabbix Java Gateway"; exit 1; }

docker run --name zabbix-server -t -e DB_SERVER_HOST="mysql-server" -e MYSQL_DATABASE="zabbix" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="zabbix" -e MYSQL_ROOT_PASSWORD="zabbix" -e ZBX_JAVAGATEWAY="zabbix-java-gateway" --link mysql-server:mysql --link zabbix-java-gateway:zabbix-java-gateway -p 10051:10051 --restart unless-stopped -d zabbix/zabbix-server-mysql ||
{ echo "Erro ao iniciar o contêiner Zabbix Server"; exit 1; }

docker run -d -p 10050:10050 --name zabbix-agent --link mysql-server:mysql --link zabbix-server:zabbix-server -e ZBX_HOSTNAME="Zabbix server" -e ZBX_SERVER_HOST="zabbix-server" -d zabbix/zabbix-agent ||
{ echo "Erro ao iniciar o contêiner Zabbix Agent"; exit 1; }

docker run --name zabbix-web-nginx-mysql -t -e DB_SERVER_HOST="mysql-server" -e MYSQL_DATABASE="zabbix" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="zabbix" -e MYSQL_ROOT_PASSWORD="zabbix" --link mysql-server:mysql -p 80:8080 --restart unless-stopped -d zabbix/zabbix-web-nginx-mysql ||
{ echo "Erro ao iniciar o contêiner Zabbix Web"; exit 1; }

echo "Contêineres iniciados com sucesso."


