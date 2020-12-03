.. _phase5_era:

Getting a development environment with Era
==========================================

Now that we have a CI/CD pipeline doing our work with respect to building, pushing and deploying our Fiesta container, let's bring in the database manipulation as well.

For this part of the workshop we are going to do the following:

- Check the registration the deployed MariaDB in Era
- Get the API calls for Clone the Production environment MariaDB database server if it doesn't exist
- Update the runapp.sh script
- If it does exist, refresh the database content so we have the latest Database entries from the production MariaDB database

.. note::
Estimated time **45-60 minutes**

Check MariaDB registration in Era
---------------------------------

The blueprint that been deployed installs the VM, but also registers the MariaDB Database server and the FiestaDB to the Era instance you have running

#. Open the Era instance in your cluster
#. Login using the username and password given
#. Click on **Dashboard -> Databases**

   .. figure:: images/1.png

#. Click **Sources**. Your *Initials* **-FiestaDB** database should be registered and shown

   .. figure:: images/2.png

Get the API to Clone the MariaDB database
-----------------------------------------

As we want to have the creation of the Fiesta Dev environment to clone the Production MariaDB server before we play with it, we need the API calls of Era to do so. This part of the module is going to use Era UI to get the API calls.
After we have the API calls we are going to use variables to set the correct values.

#. In your Era UI, click on **Time Machine** 
#. Click the radio button in front of *Initials* **-FiestaDB_TM**

   .. danger::

      Be 100% sure you have typed the name of the snapshot as it is mentioned in the step you are about to do. If there is a typo, the script will fail during the creation of the Clone!!!

#. Click **Actions -> Snapshot** and call it **First-Snapshot**
#. Click on **Operations** (via the drop down menu or by clicking in the top right hand corner)
#. Wait till the snapshot operation has ended before moving forward
#. Return to the Time Machine, click the radio button in front of *Initials* **-FiestaDB_TM**
#. Click **Actions -> Create a Clone of MariaDB Instance**

   .. figure:: images/3.png

#. Select the **First-Snapshot** as the snapshot to use and click **Next**
#. Provide the follow information in the fields

   - **Database Server VM** - Create New Server
   - **Database Server VM Name** - *Initials* -MariaDB_DEV_VM
   - **Description** - (Optional) Dev clone from the *Initials* -FiestaDB
   - **Compute Profile** - CUSTOM_EXTRA_SMALL
   - **Network Profile** - Era_Managed_MariaDB
   
   - Use for **Provide SSH Public Key Through** the following key (select **Text** first):

     .. code-block:: SSH
    
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmhJS2RbHN0+Cz0ebCmpxBCT531ogxhxv8wHB+7Z1G0I77VnXfU+AA3x7u4gnjbZLeswrAyXk8Rn/wRMyJNAd7FTqrlJ0Imd4puWuE2c+pIlU8Bt8e6VSz2Pw6saBaECGc7BDDo0hPEeHbf0y0FEnY0eaG9MmWR+5SqlkepgRRKN8/ipHbi5AzsQudjZg29xra/NC/BHLAW/C+F0tE6/ghgtBKpRoj20x+7JlA/DJ/Ec3gU0AyYcvNWlhlR+qc83lXppeC1ie3eb9IDTVbCI/4dXHjdSbhTCRu0IwFIxPGK02BL5xOVTmxQyvCEOn5MSPI41YjJctUikFkMgOv2mlV root@centos
#. Click **Next**
#. Provide the following information:

   - **Name** - *Initials*-FiestaDB_DEV
   - **Description** - (Optional) Dev clone from the *Initials* -FiestaDB
   - **New ROOT Password** - nutanix/4u
   - **Database Parameter Profile** - DEFAULT_MARIADB_PARAMS

#. Then **DON'T CLICK THE CLONE BUTTON!!**, but click the **API Equivalent** button

   .. figure:: images/4.png

#. Take closer look at the curl command and especially at the JSON data being send (left hand side of the screen)
#. The JSON data being send to the Era server is full of variable values
  
   - Era instance IP
   - Era User Name
   - Era Password
   - Era ClusterUUID
   - TimeMachineID
   - SnapshotID
   - vmName
   - ComputeProfileID
   - NetworkProfileID
   - vm_name
   - databaseParameterProfileID

#. Click the **Close** button and the **X** to close the Clone button.

Now that we know how to get the API calls we are going to change the **runapp.sh** script so it calls the commands if needed.

Change the runapp.sh script
---------------------------

As we have seen in former steps there are a lot of variables that are installation dependent. TO make your life a easier we have already created a script that will grab the needed variables (besides Drone secrets we are going to set later)

#. Open your VC that we used to manipulate the dockerfile and **runapp.sh**
#. Open the **runapp.sh** file
#. Copy the content of the following over the existing content in the **runapp.sh** file

   .. code-block:: bash

      #!/bin/sh

      # Install curl package
      apk add curl
      
      # Function area
      function waitloop {
        op_answer="$1"
        loop=$2
        # Get the op_id from the task
        op_id=$(echo $op_answer | jq '.operationId' | tr -d \")
      
      
        # Checking on error. if we have received an error, show it and exit 1
        if [[ -z $op_id ]]
        then
            echo "We have received an error message. The reply from the Era system has been "$op_answer" .."
            exit 1
        else
          counter=1
          # Checking routine to see that the registration in Era worked
          while [[ $counter -le $loop ]]
          do
              ops_status=$(curl -k --silent https://${era_ip}/era/v0.9/operations/${op_id} -H 'Content-Type: application/json'  --user $era_admin:$era_password | jq '.["percentageComplete"]' | tr -d \")
              if [[ $ops_status == "100" ]]
              then
                  ops_status=$(curl -k --silent https://${era_ip}/era/v0.9/operations/${op_id} -H 'Content-Type: application/json'  --user $era_admin:$era_password | jq '.status' | tr -d \")
                  if [[ $ops_status == "5" ]]
                  then
                     echo "Database and Database server have been registreed in Era..."
                     break
                  else
                     echo "Database and Database server registration not correct. Please look at the Era GUI to find the reason..."
                     exit 1
                  fi
              else
                  echo "Operation still in progress, it is at $ops_status %... Sleep for 30 seconds before retrying.. ($counter/$loop)"
                  sleep 30
              fi
              counter=$((counter+1))
          done
          if [[ $counter -ge $loop ]]
          then
            echo "We have tried for "$(expr $loop / 2)" minutes to register the MariaDB server and Database, but were not successful. Please look at the Era GUI to see if anything has happened..."
          fi
      fi
      }
      
      # Variables received from the environmental values via the Drone Secrets
      # era_ip, era_user, era_password and initials
      
      # Create VM-Name
      vm_name_dev=$initials"-MariaDB_DEV-VM"
      db_name_prod=$initials"-FiestaDB"
      db_name_dev=$initials"-FiestaDB_DEV"
      
      # Get the UUID of the Era server
      era_uuid=$(curl -k --insecure --silent https://${era_ip}/era/v0.9/clusters -H 'Content-Type: application/json' --user $era_admin:$era_password | jq '.[].id' | tr -d \")
      
      # Get the UUID of the network called Era_Managed_MariaDB
      network_id=$(curl --silent -k "https://${era_ip}/era/v0.9/profiles?type=Network&name=Era_Managed_MariaDB" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq '.id' | tr -d \")
      
      # Get the UUID for the ComputeProfile
      compute_id=$(curl --silent -k "https://${era_ip}/era/v0.9/profiles?&type=Compute&name=CUSTOM_EXTRA_SMALL" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq '.id' | tr -d \")
      
      # Get the UUID for the DatabaseParameter ID
      db_param_id=$(curl --silent -k "https://${era_ip}/era/v0.9/profiles?engine=mariadb_database&name=DEFAULT_MARIADB_PARAMS" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq '.id' | tr -d \")
      
      # Get the UUID of the timemachine
      db_name_tm=$initials"-FiestaDB_TM"
      tms_id=$(curl --silent -k "https://${era_ip}/era/v0.9/tms" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq --arg db_name_tm $db_name_tm '.[] | select (.name==$db_name_tm) .id' | tr -d \")
      
      # Get the UUID of the First-Snapshot for the TMS we just found
      snap_id=$(curl --silent -k "https://${era_ip}/era/v0.9/snapshots" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq --arg tms_id $tms_id '.[] | select (.timeMachineId==$tms_id) | select (.name=="First-Snapshot") .id' | tr -d \")
      
      # Now that we have all the needed parameters we can check if there is a clone named INITIALS-FiestaDB_DEV
      clone_id=$(curl --silent -k "https://${era_ip}/era/v0.9/clones" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq --arg db_name_dev $db_name_dev '.[] | select (.name==$db_name_dev) .id' | tr -d \")
      
      # Check if there is a clone already. if not, start the clone process
      if [[ -z $clone_id ]]
      then
          # Clone call of the MariaDB
          opanswer=$(curl --silent -k -X POST \
              "https://${era_ip}/era/v0.9/tms/$tms_id/clones" \
              -H 'Content-Type: application/json' \
              --user $era_admin:$era_password  \
              -d \
              '{"name":"'$db_name_dev'","description":"Dev clone from the '$db_name_prod'","createDbserver":true,"clustered":false,"nxClusterId":"'$era_uuid'","sshPublicKey":"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmhJS2RbHN0+Cz0ebCmpxBCT531ogxhxv8wHB+7Z1G0I77VnXfU+AA3x7u4gnjbZLeswrAyXk8Rn/wRMyJNAd7FTqrlJ0Imd4puWuE2c+pIlU8Bt8e6VSz2Pw6saBaECGc7BDDo0hPEeHbf0y0FEnY0eaG9MmWR+5SqlkepgRRKN8/ipHbi5AzsQudjZg29xra/NC/BHLAW/C+F0tE6/ghgtBKpRoj20x+7JlA/DJ/Ec3gU0AyYcvNWlhlR+qc83lXppeC1ie3eb9IDTVbCI/4dXHjdSbhTCRu0IwFIxPGK02BL5xOVTmxQyvCEOn5MSPI41YjJctUikFkMgOv2mlV root@centos","dbserverId":null,"dbserverClusterId":null, "dbserverLogicalClusterId":null,"timeMachineId":"'$tms_id'","snapshotId":"'$snap_id'",  "userPitrTimestamp":null,"timeZone":"Europe/Amsterdam","latestSnapshot":false,"nodeCount":1,"nodes":[{"vmName":"'$vm_name_dev'",  "computeProfileId":"'$compute_id'","networkProfileId":"'$network_id'","newDbServerTimeZone":null,   "nxClusterId":"'$era_uuid'","properties":[]}],"actionArguments":[{"name":"vm_name","value":"'$vm_name_dev'"}, {"name":"dbserver_description","value":"Dev clone from the '$vm_name'"},{"name":"db_password","value":"nutanix/4u"}],"tags":[],"newDbServerTimeZone":"UTC","computeProfileId":"'$compute_id'","networkProfileId":"'$network_id'",    "databaseParameterProfileId":"'$db_param_id'"}')
          # Call the waitloop function
          waitloop "$opanswer" 30
      fi
      
      # Let's get the IP address of the cloned database server
      cloned_vm_ip=$(curl --silent -k "https://${era_ip}/era/v0.9/dbservers" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq '.[] | select (.name=="xyz-MariaDB_DEV-VM") .ipAddresses[0]' | tr -d \")
      
      DB_SERVER=$cloned_vm_ip
      
      # If there is a "/" in the password or username we need to change it otherwise sed goes haywire
      if [ `echo $DB_PASSWD | grep "/" | wc -l` -gt 0 ]
          then
              DB_PASSWD1=$(echo "${DB_PASSWD//\//\\/}")
          else
              DB_PASSWD1=$DB_PASSWD
      fi
      
      if [ `echo $DB_USER | grep "/" | wc -l` -gt 0 ]
          then
              DB_USER1=$(echo "${DB_USER//\//\\/}")
          else
              DB_USER1=$DB_USER
      fi
      
      # Change the Fiesta configuration code so it works in the container
      sed -i "s/REPLACE_DB_NAME/$DB_NAME/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_USER_NAME/$DB_USER1/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD1/g" /code/Fiesta/config/config.js
      
      # Run the NPM Application
      cd /code/Fiesta
      npm start

   .. note::
     This script will create a clone of your *Initils***-MariaDB_VM** it does not exist. If it exists, or is created, it will grab the IP address of the Cloned Database Server and use that in the application.

#. Save the file in VC **DON"T COMMIT OR PUSH TO GITEA!** as we need to make changes to the **.dron.yml** file and create three secrets in Drone.

Changes for Drone
----------------

Now that we have the runapp.sh done, let's make the needed changes for Drone

#. In VC open the **.drone.yml** file
#. In the **Deploy newest image** section add to the **environment** part:

   .. code-block:: yaml

    ERA_IP:
     from_secret: era_ip
    ERA_USER:
     from_secret: era_user
    ERA_PASSWORD:
     from_secret: era_password
    INITIALS:
     from_secret: initials

#. In the line that holds ``docker run`` add the following before ``$USERNAME/fiesta_app:latest``

   .. code-block:: yaml
    
    -e initials=$INITIALS -e era_ip=$ERA_IP -e era_user=$ERA_USER -e era_password=$ERA_PASSWORD

#. The total section **Deploy newest image** should look like this

   .. figure:: images/6.png

#. Save the file in VC **DON"T COMMIT OR PUSH TO GITEA!**
#. Open the Drone UI at **\http://<IP ADDRESS OF DOCKER VM>:8080**
#. Click on our **Repo (nutanix/Fiesta) -> Settings**
#. Add the four extra secrets to Drone (hit **ADD SECRET** button to save the secret)

   - **initials** - *Initials*
   - **era_ip** - <IP ADDRESS OF ERA INSTANCE>
   - **era_user** - admin
   - **era_password** - <FROM YOUR CLUSTER>

#. 