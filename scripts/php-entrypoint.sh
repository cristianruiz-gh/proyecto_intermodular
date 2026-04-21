#!/bin/sh
set -eu

# Crear index.php si no existe
if [ ! -f /var/www/html/index.php ]; then
  echo '<?php phpinfo(); ?>' > /var/www/html/index.php
fi

# Regenerar php.ini personalizado en cada arranque
cat > /usr/local/etc/php/conf.d/custom.ini <<'INI'
opcache.enable=0
opcache.revalidate_freq=0
session.use_strict_mode=1
INI

# Habilitar pdo_mysql y mysqli para conexión a MySQL
if ! php -m | grep -qi '^mysqli$'; then
  docker-php-ext-install mysqli
fi

exec apache2-foreground
