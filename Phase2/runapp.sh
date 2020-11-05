#!/bin/sh
/usr/bin/mysqld --user=mysql &
/usr/bin/mysqladmin -u root password 'nutanix/4u'

# Get the Fiesta code into the system
git clone https://github.com/sharonpamela/Fiesta.git /code/Fiesta

# Change the code so it works in the container
sed -i "s/REPLACE_DB_NAME/$DB_NAME/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
sed -i "s/DB_DOMAIN_NAME/$DB_DOMAIN/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_USER_NAME/$DB_USER/g"/code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD/g" /code/Fiesta/config/config.js

# start the python file where we use the environmentals to see what we need to do
python3 /code/python/checker.py

# Install nodemon and needed dependencies for the application
npm install -g nodemon

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