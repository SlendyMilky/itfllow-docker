#!/bin/sh
# Update the apache2 conf.d
echo "<Directory '/var/www/itflow'>
   Order allow,deny
   Allow from all
   Require all granted
</Directory>
<VirtualHost *:443>
    ServerName $ITFLOW_URL
    DocumentRoot /var/www/itflow/
    LogLevel $ITFLOW_LOG_LEVEL
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>" > /etc/apache2/conf.d/000-default.conf

# if itflow is not downloaded, perform the download after the volume mounting process within dockerfile is complete.
if [[ -f /var/www/itflow/index.php ]]; then 
    cd /var/www/itflow
    git fetch
else
    git clone --branch $ITFLOW_REPO_BRANCH https://$ITFLOW_REPO /var/www/itflow
fi

git config --global --add safe.directory /var/www/itflow

# Verify permissions of itflow git repository
chown -R apache:apache /var/www/itflow

# This updates the config.php file once initialization through setup.php has completed
if [[ -f /var/www/itflow/config.php ]]; then 
    # Company Name
    sed -i "s/\$config_app_name.*';/\$config_app_name = '$ITFLOW_NAME';/g" /var/www/itflow/config.php

    # MariaDB Host
    sed -i "s/\$dbhost.*';/\$dbhost = '$ITFLOW_DB_HOST';/g" /var/www/itflow/config.php

    # Database Password
    sed -i "s/\$dbpassword.*';/\$dbpassword = '$ITFLOW_DB_PASS';/g" /var/www/itflow/config.php

    # Base URL
    sed -i "s/\$config_base_url.*';/\$config_base_url = '$ITFLOW_URL';/g" /var/www/itflow/config.php

    # Repo Branch
    sed -i "s/\$repo_branch.*';/\$repo_branch = '$ITFLOW_REPO_BRANCH';/g" /var/www/itflow/config.php
    
    find /var/www/itflow -type d -exec chmod 775 {} \;
    find /var/www/itflow -type f -exec chmod 664 {} \;
    chmod 640 /var/www/itflow/config.php
else 
    chmod -R 777 /var/www/itflow
fi

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/apache2/server.key -out /etc/ssl/apache2/server.pem -subj "/CN=*"

# Enable the apache2 sites-available
httpd -k restart
httpd -k stop

# Execute the command in the dockerfile's CMD
exec "$@"