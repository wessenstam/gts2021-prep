#!/bin/sh

# Use with MariaDB database and the script doesn't need to build the npm steps

# If there is a "/" in the password or user name we need to change it otherwise sed goes haywire
if [ `echo $DB_PASSWD | grep "/" | wc -l` -gt 0 ]
    then 
        DB_PASSWD1=$(echo "${DB_PASSWD//\//\\/}")
    else
        DB_PASSWD1=$DB_PASSWD
fi
echo "DB_PASSWD1 is "$DB_PASSWD1
if [ `echo $DB_USER | grep "/" | wc -l` -gt 0 ]
    then 
        DB_USER1=$(echo "${DB_USER//\//\\/}")
    else
        DB_USER1=$DB_USER
fi
# Change the code so it works in the container
sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
if [ "${DB_TYPE}" = "mssql" ]
then    
    sed -i 's/REPLACE_DB_DOMAIN_NAME/localhost/g' /code/Fiesta/config/config.js
else
    sed -i 's/REPLACE_DB_DOMAIN_NAME/\/\/DB_DOMAIN_NAME/g' /code/Fiesta/config/config.js
fi
sed -i "s/REPLACE_DB_USER_NAME/$DB_USER1/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD1/g" /code/Fiesta/config/config.js

# Run the NPM Application
cd /code/Fiesta 
npm start