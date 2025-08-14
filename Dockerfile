FROM wordpress:6.8-php8.1-apache

# Instala dependências e WP-CLI
RUN apt-get update && apt-get install -y less unzip curl \
  && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copia o entrypoint customizado
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
