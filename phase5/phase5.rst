.. _phase5_era:

Getting a development environment with Era
==========================================

Now that we have a CI/CD pipeline doing our work with respect to building, pushing and deploying our Fiesta container, let's bring in the database manipulation as well.

For this part of the workshop we are going to do the following:

- Check the registration the deployed MariaDB in Era
- Get the API calls for Clone the Production environment MariaDB database server if it doesn't exist
- Create a developer's version of the runapp.sh script
- If a clone of the production database doesn't exist, create a clone of the database

.. note::
  
  Estimated time **45-60 minutes**


Check Era version
-----------------

As we are using Era 2.0 version please make sure that the version of Era is 2.0.0.2. If it is not, please upgrade to this version as we have dependencies in the APIs call we are using in this part of the workshop. If you are on this version, you can proceed.

Check MariaDB registration in Era
---------------------------------

The blueprint that been deployed installs the VM, but also registers the MariaDB Database server and the FiestaDB to the Era instance you have running

#. Open the Era instance in your cluster
#. Login using the username and password given
#. Click on **Dashboard -> Databases**

   .. figure:: images/1.png

#. Click **Sources**. Your *Initials* **-FiestaDB** database should be registered and shown

   .. figure:: images/2.png

Create a snapshot of the deployed MariaDB database
--------------------------------------------------

To be able to clone a Database and its Database Server we need to have a snapshot.

#. Open in your Era instance **Time Machines** from the dropdown menu
#. Select the radio button in front of your *Initials* **-MariaDB_TM** instance
#. Select **Actions -> Snapshot**
#. Type the name **First-Snapshot** and click the **Create** button

   .. note::

      Make 110% sure you have typed it in as mentioned in this step, otherwise the deployment of the Development container will not work later in the script!!!

   .. figure:: images/2a.png

#. Click on **Operations** (via the drop down menu or by clicking in the top right hand corner)
#. Wait till the operation has finished (approx. 2 minutes)

Now that the snapshot is there we can proceed to the next step.

Get the API to Clone the MariaDB database
-----------------------------------------

As we want to have the creation of the Fiesta Dev environment to clone the Production MariaDB server before we play with it, we need the API calls of Era to do so. This part of the module is going to use Era UI to get the API calls.
After we have the API calls we are going to use variables to set the correct values.

#. In your Era UI, click on **Time Machine** 
#. Click the radio button in front of *Initials* **-FiestaDB_TM**
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

#. Take a closer look at the curl command and especially at the JSON data being send (left hand side of the screen)
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

Now that we know how to get the API calls we are going to change the deployment with tour CI/CD pipeline so it calls the commands.

Changes for Drone
----------------

We need to tell drone to make a difference in the steps it needs to run.

#. In VC open the **.drone.yml** file
#. Copy and paste below content over the exiting content in the **.drone.yml** file
   
   .. code-block:: yaml

    kind: pipeline
    name: default
    
    clone:
      skip_verify: true
    
    steps:
    
      - name: Build Image (Prod)
        image: docker:latest
        pull: if-not-exists
        volumes:
          - name: docker_sock
            path: /var/run/docker.sock
        commands:
          - docker build -t fiesta_app:${DRONE_COMMIT_SHA:0:6} .
        when:
          branch:
            - master
    
      - name: Build Image (Dev)
        image: docker:latest
        pull: if-not-exists
        volumes:
          - name: docker_sock
            path: /var/run/docker.sock
        commands:
          - docker build -t fiesta_app_dev:${DRONE_COMMIT_SHA:0:6} -f dockerfile-dev .
        when:
          branch:
            - dev
    
      - name: Test container (Prod)
        image: fiesta_app:${DRONE_COMMIT_SHA:0:6}
        pull: if-not-exists
        environment:
          USERNAME:
            from_secret: dockerhub_username
          PASSWORD:
            from_secret: dockerhub_password
          DB_SERVER:
            from_secret: db_server_ip
          DB_PASSWD:
            from_secret: db_passwd
          DB_USER:
            from_secret: db_user
          DB_TYPE:
            from_secret: db_type
          DB_NAME:
            from_secret: db_name
        commands:
          - npm version
          - mysql -u$DB_PASSWD -p$DB_USER -h $DB_SERVER $DB_NAME -e "select * from Products;"
          - if [ `echo $DB_PASSWD | grep "/" | wc -l` -gt 0 ]; then DB_PASSWD=$(echo "${DB_PASSWD//\//\\/}"); fi
          - sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_USER_NAME/$DB_USER/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD/g" /code/Fiesta/config/config.js
        when:
          branch:
            - master
    
      - name: Test container (Dev)
        image: fiesta_app_dev:${DRONE_COMMIT_SHA:0:6}
        pull: if-not-exists
        environment:
          USERNAME:
            from_secret: dockerhub_username
          PASSWORD:
            from_secret: dockerhub_password
          DB_SERVER:
            from_secret: db_server_ip
          DB_PASSWD:
            from_secret: db_passwd
          DB_USER:
            from_secret: db_user
          DB_TYPE:
            from_secret: db_type
          DB_NAME:
            from_secret: db_name
        commands:
          - npm version
          - mysql -u$DB_PASSWD -p$DB_USER -h $DB_SERVER $DB_NAME -e "select * from Products;"
          - if [ `echo $DB_PASSWD | grep "/" | wc -l` -gt 0 ]; then DB_PASSWD=$(echo "${DB_PASSWD//\//\\/}"); fi
          - sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_USER_NAME/$DB_USER/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD/g" /code/Fiesta/config/config.js
        when:
          branch:
            - dev
    
      - name: Push to Dockerhub (Prod)
        image: docker:latest
        pull: if-not-exists
        environment:
          USERNAME:
            from_secret: dockerhub_username
          PASSWORD:
            from_secret: dockerhub_password
        volumes:
          - name: docker_sock
            path: /var/run/docker.sock
        commands:
          - docker login -u $USERNAME -p $PASSWORD
          - docker image tag fiesta_app:${DRONE_COMMIT_SHA:0:6} $USERNAME/fiesta_app:latest
          - docker image tag fiesta_app:${DRONE_COMMIT_SHA:0:6} $USERNAME/fiesta_app:${DRONE_COMMIT_SHA:0:6}
          - docker push $USERNAME/fiesta_app:${DRONE_COMMIT_SHA:0:6}
          - docker push $USERNAME/fiesta_app:latest
        when:
          branch:
            - master
    
      - name: Deploy Prod image
        image: docker:latest
        pull: if-not-exists
        environment:
          USERNAME:
            from_secret: dockerhub_username
          PASSWORD:
            from_secret: dockerhub_password
          DB_SERVER:
            from_secret: db_server_ip
          DB_PASSWD:
            from_secret: db_passwd
          DB_USER:
            from_secret: db_user
          DB_TYPE:
            from_secret: db_type
          DB_NAME:
            from_secret: db_name
        volumes:
          - name: docker_sock
            path: /var/run/docker.sock
        commands:
          - if [ `docker ps | grep fiesta_app | wc -l` -eq 1 ]; then echo "Stopping existing Docker Container...."; docker stop fiesta_app; else echo "Docker container has not been found..."; fi
          - sleep 10
          - docker run --name fiesta_app --rm -p 5000:3000 -d -e DB_SERVER=$DB_SERVER -e DB_USER=$DB_USER -e DB_TYPE=$DB_TYPE -e DB_PASSWD=$DB_PASSWD -e DB_NAME=$DB_NAME $USERNAME/fiesta_app:latest
        when:
          branch:
            - master
    
      - name: Deploy Dev image
        image: docker:latest
        pull: if-not-exists
        environment:
          USERNAME:
            from_secret: dockerhub_username
          PASSWORD:
            from_secret: dockerhub_password
          DB_SERVER:
            from_secret: db_server_ip
          DB_PASSWD:
            from_secret: db_passwd
          DB_USER:
            from_secret: db_user
          DB_TYPE:
            from_secret: db_type
          DB_NAME:
            from_secret: db_name
          ERA_IP:
            from_secret: era_ip
          ERA_USER:
            from_secret: era_user
          ERA_PASSWORD:
            from_secret: era_password
          INITIALS:
            from_secret: initials
        volumes:
          - name: docker_sock
            path: /var/run/docker.sock
        commands:
          - if [ `docker ps | grep fiesta_app_dev | wc -l` -eq 1 ]; then echo "Stopping existing Docker Container...."; docker stop fiesta_app_dev; else echo "Docker container has not been found..."; fi
          - sleep 10
          - docker run -d --rm --name fiesta_app_dev -p 5050:3000 -e DB_SERVER=$DB_SERVER -e DB_USER=$DB_USER -e DB_TYPE=$DB_TYPE -e DB_PASSWD=$DB_PASSWD -e DB_NAME=$DB_NAME -e initials=$INITIALS -e era_ip=$ERA_IP -e era_admin=$ERA_USER -e era_password=$ERA_PASSWORD fiesta_app_dev:${DRONE_COMMIT_SHA:0:6}
        when:
          branch:
            - dev
    
    volumes:
    - name: docker_sock
      host:
        path: /var/run/docker.sock

   
   The new **.drone.yml** file does a few things

   - Run distinct steps based on the branch the push has been made on
   - If branch is dev, the following changes in the steps, compared to earlier runs, are:

     - Change the name of the build image to **fiesta_app_dev**
     - Use a different dockerfile to build the image (**dockerfile-dev**)
     - Don't push the image to Dockerhub
     - Start a container using the dev built container on port **5050, not 5000**
     - name the container **fiesta_app_dev**

#. Save, Commit and Push to Gitea.
#. This will fire a new build, but you should see the steps with **(Prod)** 

   .. figure:: images/7.png

Now we know that Drone is capable of changing steps based on braches (in .drone.yml you see the **when: branche: - master/dev**) we are going to use that.

Create a new branch in VC
-------------------------

As we are mimicking the full development of the applicaiton, we are going to create a new branch. This branch will be used to do a few things:

- Change the creation of the development container
- Run a different start script which will:

  - Deploy a clone of the MariaDB server, if there is none
  - Use the cloned MariaDB server and not the MariaDB production server for the development of our application

- Don't upload the container onto our DockerHub repo as it has no Production value

#. Open VC
#. Close all open files
#. Click in the bottom left corner on the text **master**

   .. figure:: images/8.png

#. Than in the message box that opens at the top of the screen select **+ Create new branch...** 

   .. figure:: images/9.png

#. Type **dev** in the next message box and hit enter

This will have all the same files that the master branch had (our original) but we can independently develop our code

Create development script version
---------------------------------

As we have seen in former steps, there are a lot of variables that are installation dependent for the cloning of the MariaDB server you deployed with the Blueprint.
To make your life easier we have already created the needed content for the files (besides Drone secrets we are going to set later).

#. Make sure you are in the **dev** branch.

   .. figure:: images/10.png

#. Create a new file called **runapp-dev.sh**
#. Copy and paste the below content in the file

   .. code-block:: bash

      #!/bin/sh

      # Install curl and jq package as we need it
      apk add curl jq

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
              '{"name":"'$db_name_dev'","description":"Dev clone from the "'$db_name_prod'","createDbserver":true,"clustered":false,"nxClusterId":"'$era_uuid'","sshPublicKey":"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmhJS2RbHN0+Cz0ebCmpxBCT531ogxhxv8wHB+7Z1G0I77VnXfU+AA3x7u4gnjbZLeswrAyXk8Rn/wRMyJNAd7FTqrlJ0Imd4puWuE2c+pIlU8Bt8e6VSz2Pw6saBaECGc7BDDo0hPEeHbf0y0FEnY0eaG9MmWR+5SqlkepgRRKN8/ipHbi5AzsQudjZg29xra/NC/BHLAW/C+F0tE6/ghgtBKpRoj20x+7JlA/DJ/Ec3gU0AyYcvNWlhlR+qc83lXppeC1ie3eb9IDTVbCI/4dXHjdSbhTCRu0IwFIxPGK02BL5xOVTmxQyvCEOn5MSPI41YjJctUikFkMgOv2mlV root@centos","dbserverId":null,"dbserverClusterId":null, "dbserverLogicalClusterId":null,"timeMachineId":"'$tms_id'","snapshotId":"'$snap_id'",  "userPitrTimestamp":null,"timeZone":"Europe/Amsterdam","latestSnapshot":false,"nodeCount":1,"nodes":[{"vmName":"'$vm_name_dev'",  "computeProfileId":"'$compute_id'","networkProfileId":"'$network_id'","newDbServerTimeZone":null,   "nxClusterId":"'$era_uuid'","properties":[]}],"actionArguments":[{"name":"vm_name","value":"'$vm_name_dev'"}, {"name":"dbserver_description","value":"Dev clone from the '$vm_name'"},{"name":"db_password","value":"nutanix/4u"}],"tags":[],"newDbServerTimeZone":"UTC","computeProfileId":"'$compute_id'","networkProfileId":"'$network_id'",    "databaseParameterProfileId":"'$db_param_id'"}')

          # Call the waitloop function
          waitloop "$opanswer" 30
      fi

      # Let's get the IP address of the cloned database server
      cloned_vm_ip=$(curl --silent -k "https://${era_ip}/era/v0.9/dbservers" -H 'Content-Type: application/json' --user $era_admin:$era_password | jq --arg clone_name $vm_name_dev '.[] | select (.name==$clone_name) .ipAddresses[0]' | tr -d \")

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
     This script will:

     - Check if there is a clone from the *Initials* **-MariaDB_VM** server, if not create one with the naming of:
       
       - *Initials* **-MariaDB_DEV-VM** as the Database server
       - *Initials* **-FiestaDB_DEV** as the name of the cloned Database
       - *Initials* **-FiestaDB_DEV_TM** as the name of the Time Machine of the cloned Database

     - Set the script to use the cloned database as its database server
     - Run the rest as the normal production script deployed earlier

#. Save the file in VC **DON'T COMMIT AND PUSH TO GITEA!**

Create a new dockerfile
-----------------------

Now we need to make sure that the development container is using the newly created **runapp-dev.sh** file.

#. Create a new file called **dockerfile-dev**
#. Copy and paste the below content in the file
   
   .. code-block:: docker

      # This dockerfile multi step is to start the container faster as the runapp.sh doesn't have to run all npm steps

      # Grab the Alpine Linux OS image and name the container base
      FROM alpine:3.11 as base

      # Install needed packages
      RUN apk add --no-cache --update nodejs npm git

      # Create and set the working directory
      RUN mkdir /code
      WORKDIR /code

      # Get the Fiesta Application in the container
      RUN git clone https://github.com/sharonpamela/Fiesta.git /code/Fiesta

      # Get ready to install and build the application
      RUN cd /code/Fiesta && npm install
      RUN cd /code/Fiesta/client && npm install
      RUN cd /code/Fiesta/client && npm audit fix
      RUN cd /code/Fiesta/client && npm fund
      RUN cd /code/Fiesta/client && npm update
      RUN cd /code/Fiesta/client && npm run build

      # Grab the Alpine Linux OS image and name it Final_Image
      FROM alpine:3.11 as Final_Image

      # Install some needed packages
      RUN apk add --no-cache --update nodejs npm mysql-client

      # Get the NMP nodemon and install it
      RUN npm install -g nodemon

      # Copy the earlier created application from the first step into the new container
      COPY --from=base /code /code

      # Copy the starting app, but dev version
      COPY runapp-dev.sh /code/runapp.sh
      RUN chmod +x /code/runapp.sh
      WORKDIR /code

      # Start the application
      ENTRYPOINT [ "/code/runapp.sh"]
      EXPOSE 3001 3000
   
   As you can see there is just a small change where we copied **runapp.sh** in earlier steps, we now copy **runapp-dev.sh** as **runapp.sh**

#. Save the file in VC **DON'T COMMIT AND PUSH TO GITEA!**

Add extra Drone secrets
-----------------------

As we need to tell drone where our Era instance is and what credentials are needed, we need to create these as secrets.

#. Open your Drone UI at **\http://<IP ADDRESS DOCKERVM>:8080**
#. Click on your **Repository -> SETTINGS**
#. Add the following secrets (Click **ADD SECRET** to save the secret):

   - **era_ip** - <IP ADDRESS OF ERA>
   - **era_user** - admin
   - **era_password** - <ADMIN PASSWORD ERA>
   - **initials** - <YOUR INITIALS>

   .. note::
     You should now have 11 secrets
   
   .. figure:: images/11.png


Push your files to Gitea
------------------------

#. Open your VC
#. Commit and push all to your Gitea
#. Click **OK** on the message box you get as Gitea doesn't know YET about this branch
  
   .. figure:: images/12.png

#. Open Drone UI to see the job running

   .. figure:: images/13.png

#. Open a ssh session to your docker vm server and run ``docker logs --follow fiesta_app_dev``
#. You will see a step running mentioning ```Operation still in progress...``

   .. figure:: images/14.png

#. Open your Era interface and you will see in **Operations** a **Clone Database** operation

   .. figure:: images/15.png

#. Wait till the step is done (approx. 10 minutes)
#. Return to your ssh session to see the progress of the ``docker logs`` command.
#. Wait til you see the line ``On Your Network:  http://172.17.0.7:3000``

#. Open the development version of the Fiesta Application at **\http://<IP ADDRESS DOCKERVM>:5050**
#. Goto **Products**
#. Add an extra product by clicking on the **Add New Product** button
#. Use the following values for the fields
   
   - **Product Name (\*)** - Nutanix HQ JS Reception
   - **Suggested Retail Price (\*)** - 10000
   - **Product Image URL (optional)** - \https://images.squarespace-cdn.com/content/v1/5d31ebb829f8cc0001b2481b/1564761967972-SUOBVO463RDQ2GSY9JD1/ke17ZwdGBToddI8pDm48kGmScA6V2_DHTkmfhjdEzm97gQa3H78H3Y0txjaiv_0fDoOvxcdMmMKkDsyUqMSsMWxHk725yiiHCCLfrh8O1z5QPOohDIaIeljMHgDF5CVlOqpeNLcJ80NK65_fV7S1UZMI6X7yGUDybalAFUlJQFpALT4Jd0h1Jp53vKTUc5VLbka3MzgShcsnUbwZjk4-8w/Nutanix+%282%29.jpg?format=1500w
   - **Product Comments (optional)** - Full reception including screens 

#. Click the **Submit** button
#. Click the **OK** button
#. Scroll all the way down to see the new added item
#. Change the URL to the production application by changing the port number from **5000** to **5050** and the new added item is NOT there. 

Now that we have seen that we are working on two different database, the development area is complete. Whatever we do, it will have no impact on the production database!

.. let's roll the Development database back to the time we created the snapshot.

    Refresh the development database
    --------------------------------
    
    #. Open your Era instance
    #. Goto **Databases (drop down menu) -> Clones**
    #. Click the radio button in from of your *Initials* **-FiestaDB_DEV** clone
    #. Click the **Refresh** button
    #. Select under **Snapshot** your **First-Snapshot**
    
       .. figure:: images/16.png
    
    #. Click **Refresh**
    #. Click **Operations** to follow the process (approx. 5-7 minutes)

------

Takeaways
---------

- Ease of use for the deployment of a development environment using Era for database management
- Use of Calm to deploy a development environment that integrates with Era
- Use of a CI/CD and Era is quiet easy to set update
- CI/CD pipeline to have a distinction between Production and Development.