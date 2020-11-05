#!/bin/sh

# Start the mysql daemon
/usr/bin/mysqld --user=mysql &

# Get the Fiesta code into the system
git clone https://github.com/sharonpamela/Fiesta.git /code/Fiesta

# Change the code so it works in the container
sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
sed -i 's/REPLACE_DB_HOST_ADDRESS/localhost/g' /code/Fiesta/config/config.js
sed -i 's/REPLACE_DB_DIALECT/mysql/g' /code/Fiesta/config/config.js
sed -i 's/DB_DOMAIN_NAME/\/\/DB_DOMAIN_NAME/g' /code/Fiesta/config/config.js
sed -i 's/REPLACE_DB_USER_NAME/fiesta/g' /code/Fiesta/config/config.js
sed -i 's/REPLACE_DB_PASSWORD/fiesta/g' /code/Fiesta/config/config.js

# Get data in to the MariaDB
/usr/bin/mysql -uroot < /code/Fiesta/seeders/FiestaDB-mySQL.sql
/usr/bin/mysql -uroot < /code/set_privileges.sql

# Set the MySQL root password
/usr/bin/mysqladmin -u root password 'nutanix/4u'

npm install -g nodemon

# Get ready to start the application
cd /code/Fiesta
npm install
cd /code/Fiesta/client
npm install

# Update the packages
npm fund
npm update
npm audit fix

# Build the app
npm run build

# Run the NPM Application
cd /code/Fiesta 
npm start