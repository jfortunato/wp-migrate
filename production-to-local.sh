#!/bin/bash

# Usage: ./production-to-local.sh ssh-user@server:/path/to/public example.com

# TODO verify the first argument syntax is correct
# TODO verify docker-compose is installed

SSH_LOGIN=`echo "$1" | cut -d':' -f1`
PATH_TO_PUBLIC=`echo "$1" | cut -d':' -f2`

CURRENT_DIRECTORY=`basename "$PWD"`
DB_CONTAINER_NAME="$CURRENT_DIRECTORY"_db_1
WORDPRESS_CONTAINER_NAME="$CURRENT_DIRECTORY"_wordpress_1
DOMAIN_NAME=$2


echo ""
echo ""
echo ""
echo ""
echo "Please Supply SSH Password"
echo "=========================="
rsync -za $1 .

WP_CONFIG=`cat public/wp-config.php`

DB_NAME=`echo $WP_CONFIG | grep -o -P "['\"]DB_NAME['\"], ?['\"]([^'\"]+)['\"]" | awk '{ print $2 }' | sed "s/['\"]//g"`
DB_USER=`echo $WP_CONFIG | grep -o -P "['\"]DB_USER['\"], ?['\"]([^'\"]+)['\"]" | awk '{ print $2 }' | sed "s/['\"]//g"`
DB_PASS=`echo $WP_CONFIG | grep -o -P "['\"]DB_PASSWORD['\"], ?['\"]([^'\"]+)['\"]" | awk '{ print $2 }' | sed "s/['\"]//g"`


echo ""
echo ""
echo ""
echo ""
echo "Please Supply SSH Password Again"
echo "================================"
ssh "$SSH_LOGIN" "mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"" > "$DB_NAME".sql

echo ""
echo ""
echo ""
echo ""
echo "Starting Docker"
echo "================================"
docker-compose up -d
echo "$DB_CONTAINER_NAME"
sleep 10
cat "$DB_NAME".sql | docker exec -i "$DB_CONTAINER_NAME" mysql -uwordpress -pwordpress -h127.0.0.1 wordpress
docker exec -i "$WORDPRESS_CONTAINER_NAME" curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker exec -i "$WORDPRESS_CONTAINER_NAME" chmod +x wp-cli.phar
docker exec -i "$WORDPRESS_CONTAINER_NAME" mv wp-cli.phar /usr/local/bin/wp
docker exec -i "$WORDPRESS_CONTAINER_NAME" wp --allow-root search-replace http://"$DOMAIN_NAME" http://localhost:8000
docker exec -i "$WORDPRESS_CONTAINER_NAME" wp --allow-root search-replace https://"$DOMAIN_NAME" http://localhost:8000
