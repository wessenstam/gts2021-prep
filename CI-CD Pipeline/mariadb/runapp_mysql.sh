#!/bin/sh

# Clone the Repo into the container in the /code folder we already created in the dockerfile
git clone https://github.com/sharonpamela/Fiesta /code/Fiesta

# Change the configuration from the git clone action
sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_HOST_ADDRESS/10.42.37.59/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_DIALECT/mysql/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_USER_NAME/fiesta/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_PASSWORD/fiesta/g" /code/Fiesta/config/config.js

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