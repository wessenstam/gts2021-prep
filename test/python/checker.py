# Script for running checks before we start the application
# *********************************************************
# Use of environmental values to make changes
# - Mode Dev or Prod
# - Storage Normal or S3
# - Username and password for MSSQL DB, ERA and PC so we can ask the data needed for the changes to be made in the config file
# - If S3
#       access credentials
#       IP address
#       Bucket name
# Do we need to change the to be imported SQL data?
# 1. Are we running dev or prod?
#   - If Dev, tell Era to clone a MSSQL database
#       - Use the reported name from Era to find the IP address and change the config files that Fiesta use
#   - If Prod, don't do anything, skip the data import
# 2. Are we going to use S3 or not
#   - If yes, import and upload to the S3 bucket we need to use. Also need to manipulate the data we have received from the MSSQL server to reflect the new S3 data URLs for the images
#   - If no, no changes to be made
# *********************************************************#********************************************************

# Import the needed modules
import boto3
import os
import sqlalchemypymssql


# * Functions we are going to use ********************************************************
# MSSL Connection
def mssql(serverip,username,passwd,database): {

}

# Download the images for upload
def img_dl(url, location): {

}

# Uppload to S3 bucket
def s3_upload(serverip,access_key_acces_secret,bucket,file): {

}

# Manipulate the sql file
def sql_change(file,find,replace): {

}


