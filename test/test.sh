#!/bin/sh

MODE="DEV"
STORAGE="S3"
DB_SERVER="10.38.11.174"
DB="FiestaDB"
DB_USER="sa"
DB_PASSWD='Nutanix\/4u'
S3_IP="10.38.11.132"
S3_BCKT="TEST1"
ERA_IP="10.38.11.170"
PRISM_PWD='techX2021!'
IMAGE_LOC='/code/images4S3'


# Get the Fiesta code into the system
git clone https://github.com/sharonpamela/Fiesta.git /code/Fiesta

# Change the code so it works in the container
sed -i "s/REPLACE_DB_NAME/$DB/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_DIALECT/mssql/g" /code/Fiesta/config/config.js
sed -i "s/DB_DOMAIN_NAME/\/\/DB_DOMAIN_NAME/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_USER_NAME/$DB_USER/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD/g" /code/Fiesta/config/config.js

if [[ $STORAGE="S3" ]]; then
    echo "Need to download the images from the sql files before progressing.."
    mkdir $IMAGE_LOC
    cd $IMAGE_LOC
    wget `cat /code/Fiesta/seeders/FiestaDB-MSSQL.sql| grep "INSERT INTO Products" | cut -d "," -f 6 | tr -d \' | cut -d "?" -f 1`
    cd /code
fi
python3 ~/test.py $MODE $STORAGE $DB_SERVER $DB $DB_USER $DB_PASSWD $S3_IP $S3_BCKT $ERA_IP $PRISM_PWD $IMAGE_LOC
