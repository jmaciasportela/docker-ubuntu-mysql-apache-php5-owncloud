#!/bin/bash

# Start mysql without grant tables
mysqld_safe --skip-grant-tables >res 2>&1 &

echo 'Resetting password... hold on'

# Sleep for 5 while the new mysql process loads (if get a connection error you might need to increase this.)
sleep 5

# Creating the password

DB_ROOT_PASS=${DB_REMOTE_ROOT_PASS:-"owncloud"}
DB_ROOT_USER='root'

# Update root user with new password
mysql mysql -e "UPDATE user SET Password=PASSWORD('$DB_ROOT_PASS') WHERE User='$DB_ROOT_USER';FLUSH PRIVILEGES;"

echo 'Cleaning up...'

# Sleep for 5 while the mysql process
sleep 2

# Kill the insecure mysql process
killall -v mysqld

echo "Password reset has been completed"
