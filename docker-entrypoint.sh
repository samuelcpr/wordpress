#!/bin/bash
set -e

# Executa entrypoint oficial original do WordPress
if [ ! -f /usr/local/bin/docker-entrypoint.sh.orig ]; then
  mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh.orig
fi

# Chama o entrypoint original em background
/usr/local/bin/docker-entrypoint.sh.orig "$@" &

# Espera o banco de dados ficar disponível
echo "Esperando o banco de dados ${WORDPRESS_DB_HOST} ficar disponível..."
until mysqladmin ping -h"${WORDPRESS_DB_HOST%%:*}" --silent; do
  sleep 3
done

# Espera o WordPress estar instalado via WP-CLI
TRIES=0
MAX_TRIES=30
while ! wp core is-installed --allow-root --path=/var/www/html; do
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo "Timeout esperando instalação do WordPress. Abortando."
    exit 1
  fi
  echo "WordPress não instalado ainda. Instalando... (tentativa $TRIES)"
  wp core install \
    --url="${WP_SITE_URL:-http://localhost:8000}" \
    --title="${WP_TITLE:-Meu Site}" \
    --admin_user="${WP_ADMIN_USER:-admin}" \
    --admin_password="${WP_ADMIN_PASSWORD:-admin123}" \
    --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}" \
    --skip-email \
    --allow-root \
    --path=/var/www/html && break
  TRIES=$((TRIES+1))
  sleep 5
done

# Instala plugins e ativa
PLUGINS=(classic-editor contact-form-7 elementor)
for plugin in "${PLUGINS[@]}"; do
  echo "Instalando plugin $plugin"
  wp plugin install "$plugin" --activate --allow-root --path=/var/www/html || true
done

# Instala tema e ativa
THEME="astra"
echo "Instalando tema $THEME"
wp theme install "$THEME" --activate --allow-root --path=/var/www/html || true

wait
