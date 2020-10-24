#!/bin/sh
git clone https://github.com/sharonpamela/Fiesta.git
cd ~/Fiesta
npm install
cd ~/Fiesta/client
npm install
npm run build
cd ~/Fiesta 
npm start