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
auto_prepend_file=/var/www/html/auth.php
INI

exec apache2-foreground
