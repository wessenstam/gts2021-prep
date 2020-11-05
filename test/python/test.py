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
import pyodbc
import os
import sys


# * Functions we are going to use ********************************************************
# MSSL Connection
def mssql(serverip,database,username,password): 
    try:
        cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+serverip+';DATABASE='+database+';UID='+username+'; PWD='+password)
        cursor = cnxn.cursor()
        """ cursor.execute("SELECT * from testtable;")
        row = cursor.fetchone()
        while row:
            print(row)
            row = cursor.fetchone()
        """
        print("FiestaDB has been found, so we can skip the initiation of the database....")
    except: 
        print("Database not found! We need to inject the data...")

# Upload to S3 bucket
def s3_upload(serverip,access_key, acces_secret,bucket,file):
    print("Images have been downloaded by the Shell script into "+file+". Now the S3 upload needs to take place via boto3")

# Manipulate the sql file
def sql_change(file,find,replace): 
    print("Test")

# *********************************************************#********************************************************
# Main routine
# Setting the given arguments to the vars in the Python script
app_mode=sys.argv[0]
app_storage=sys.argv[1]
app_db=sys.argv[2]
app_db_user=sys.argv[3]
app_db_passwd=sys.argv[4]
app_s3_ip=sys.argv[5]
app_s3_bckt=sys.argv[6]
app_era_ip=sys.argv[7]
app_prism_pwd=sys.argv[8]
app_img_loc=sys.argv[9]

# Start the MSSQL connection
mssql('10.38.11.174','FiestaDB','sa','Nutanix/4u')

if os.environ.get('MODE') == 'DEV':
    print("We need a Dev Enviroment!!")
else:
    print("We need a normal Environment!!")
    
if os.environ.get('STORAGE') == "S3":
    print(os.environ.get('IMAGE_LOC'))
    s3_upload("","","","",os.environ.get('IMAGE_LOC'))
else:
    print("We don't need S3 storage..")

