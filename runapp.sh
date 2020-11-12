#!/bin/sh

# Runapp for having the specific npm image container created

# If there is a "/" in the password or user name we need to change it otherwise sed goes haywire
if [ `echo $DB_PASSWD | grep "/" | wc -l` -gt 0 ]
    then 
        DB_PASSWD1=$(echo "${DB_PASSWD//\//\\/}")
fi
echo "DB_PASSWD1 is "$DB_PASSWD1
if [ `echo $DB_USER | grep "/" | wc -l` -gt 0 ]
    then 
        DB_USER1=$(echo "${DB_PASSWD//\//\\/}")
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
sed -i "s/REPLACE_DB_USER_NAME/$FIESTA_USER/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD1/g" /code/Fiesta/config/config.js

# Change the database pasword for the account
sed -i "s/REPLACE_DB_PASSWD/$DB_PASSWD/g" /code/MSSQL.sql

# Add the leading and ending ' symbols
/opt/mssql-tools/bin/sqlcmd -S $DB_SERVER -U sa -P $DB_PASSWD -i /code/MSSQL.sql

cd /code/Fiesta 
npm start