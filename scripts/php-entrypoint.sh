#!/bin/sh
set -eu

# Crear index.php si no existe
if [ ! -f /var/www/html/index.php ]; then
  echo '<?php phpinfo(); ?>' > /var/www/html/index.php
fi

# Crear php.ini para desactivar OPcache y habilitar guard global
if [ ! -f /usr/local/etc/php/conf.d/custom.ini ]; then
  echo "opcache.enable=0" > /usr/local/etc/php/conf.d/custom.ini
  echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/custom.ini
  echo "session.use_strict_mode=1" >> /usr/local/etc/php/conf.d/custom.ini
  echo "auto_prepend_file=/var/www/html/auth_guard.php" >> /usr/local/etc/php/conf.d/custom.ini
fi


exec apache2-foreground