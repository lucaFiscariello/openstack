#!/bin/sh
password=$1
sudo mysql -e "CREATE DATABASE keystone;"

sudo mysql -e "CREATE USER 'keystone'@'%' IDENTIFIED BY '"$password"';"
sudo mysql -e  "CREATE USER 'keystone'@'localhost' IDENTIFIED BY '"$password"';"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost';"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%';"
sudo mysql -e  "FLUSH PRIVILEGES;"


sudo apt install keystone -y
sudo sed -i '/connection =/d ' /etc/keystone/keystone.conf
sudo sed -i '/\[database\]/d' /etc/keystone/keystone.conf
sudo sed -i '/\[token\]/d' /etc/keystone/keystone.conf

sudo echo \
"[database]
connection = mysql+pymysql://keystone:"$password"@controller/keystone"\
>> /etc/keystone/keystone.conf

sudo echo \
"[token]
provider = fernet"\
>> /etc/keystone/keystone.conf

sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone && \
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

sudo keystone-manage bootstrap --bootstrap-password $password \
 --bootstrap-admin-url http://controller:5000/v3/ \
 --bootstrap-internal-url http://controller:5000/v3/ \
 --bootstrap-public-url http://controller:5000/v3/ \
 --bootstrap-region-id RegionOne
 
sudo echo "ServerName controller" >>  /etc/apache2/apache2.conf
sudo service apache2 restart
 
export OS_USERNAME=admin && \
export OS_PASSWORD=$password && \
export OS_PROJECT_NAME=admin && \
export OS_USER_DOMAIN_NAME=Default && \
export OS_PROJECT_DOMAIN_NAME=Default && \
export OS_AUTH_URL=http://controller:5000/v3 && \
export OS_IDENTITY_API_VERSION=3 

sudo apt install python3-openstackclient -y

echo \
"export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2"\
> admin-openrc

