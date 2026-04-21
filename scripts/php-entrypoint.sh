#!/bin/sh
set -eu

if [ ! -f /var/www/html/index.php ]; then
  echo '<?php phpinfo(); ?>' > /var/www/html/index.php
fi

cat > /usr/local/etc/php/conf.d/custom.ini <<'INI'
opcache.enable=0
opcache.revalidate_freq=0
session.use_strict_mode=1
INI

if ! php -m | grep -qi '^mysqli$'; then
  docker-php-ext-install mysqli
fi

exec apache2-foreground
