#!/bin/sh

# Get the Fiesta code into the system
git clone https://github.com/sharonpamela/Fiesta.git /code/Fiesta

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