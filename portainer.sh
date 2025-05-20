#!/usr/bin/env bash
set -euo pipefail

# Nome do usuário a ser adicionado ao grupo docker
USER_TO_ADD="${SUDO_USER:-$USER}"

echo "🚀 Iniciando instalação do Docker e Portainer no Debian 12..."

# 1. Atualizar sistema
echo "• Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y

# 2. Instalar pré-requisitos
echo "• Instalando dependências..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 3. Adicionar chave GPG do Docker
echo "• Importando chave GPG do Docker..."
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 4. Adicionar repositório estável do Docker
echo "• Adicionando repositório Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
   https://download.docker.com/linux/debian \
   $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

# 5. Instalar Docker Engine e Compose plugin
echo "• Instalando Docker Engine e Docker Compose plugin..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 6. Verificar instalação mínima
echo "• Verificando instalação..."
docker --version
docker compose version

# 7. Adicionar usuário ao grupo docker
echo "• Adicionando usuário '${USER_TO_ADD}' ao grupo docker..."
sudo usermod -aG docker "${USER_TO_ADD}"

# 8. Criar rede nginx_proxy, se não existir
if ! docker network ls --format '{{.Name}}' | grep -q '^nginx_proxy$'; then
  echo "• Criando rede Docker 'nginx_proxy'..."
  docker network create nginx_proxy
else
  echo "• Rede 'nginx_proxy' já existe — pulando."
fi

# 9. Criar volume para dados do Portainer
echo "• Criando volume 'portainer_data'..."
docker volume create portainer_data

# 10. Parar e remover container portainer existente (se houver)
if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
  echo "• Parando e removendo container 'portainer' existente..."
  docker stop portainer
  docker rm portainer
fi

# 11. Executar container do Portainer CE
echo "• Iniciando container Portainer CE..."
docker run -d \
  --name portainer \
  --restart=always \
  --network nginx_proxy \
  -p 8000:8000 \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce

# 12. Conclusão
IP_ADDR=$(hostname -I | awk '{print $1}')
echo
echo "✅ Instalação concluída!"
echo "   Acesse o Portainer em: http://$IP_ADDR:9000"
echo
echo "ℹ️ Para aplicar a nova associação ao grupo 'docker', faça logout/login ou execute:"
echo "   newgrp docker"

