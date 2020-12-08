.. _phase3_container:

Using the CI/CD Infrastructure
==============================

This part of the workshop is about

- Configure the CI/CD infrastructure to:

  - Build the images and tag the images using a tag convention of <IP ADDRESS OF DOCKER VM>:<commit number>
  - Test the build images
  - Upload the images to Dockerhub so we still have our images even after we have destroyed our development environment
  - Deploy the images as containers

- Use of tooling

.. note::
   Estimated time **45-60 minutes**


Start using the CI/CD pipeline
------------------------------

Now that we have our tooling and basic CI/CD infrastructure up and running let's start using it. To do that we need to run a few steps.

- Create a repo in Gitea
- Tell our development environment to use the Gitea environment
- Configure Drone to run

  - build images
  - test images
  - save images in Dockerhub
  - deploy the image as containers

Create a repo in Gitea
^^^^^^^^^^^^^^^^^^^^^^

Let's create a repository (repo) that we can use to store our files in from which we want to have our images/containers build.

#. Open in a browser your Gitea interface (**\https://<IP ADDRESS OF DOCKER VM>:3000**) and login using your set credentials (workshop uses **nutanix** and **nutanix/4u**) by clicking on the Login icon (top right corner). You might be auto logged in if the token is still valid

#. Click on the **+** sign in the top right hand corner and select **+New Repository**

   .. figure:: images/1.png

#. Provide a name, we have chosen **Fiesta_Application**, and click the **Create Repository** button
#. After the Repo has been created, you will see the possibilities on how to clone the Repo

   .. figure:: images/2.png

#. Copy the https URL
#. Open a command line or terminal on your laptop or Windows Tools VM and run ``git config --global http.sslVerify false``. This step is necessary otherwise git is not willing to clone anything from a Version Control Manager using Self signed certificates. In the same command line or terminal session run the following two commands ``git config --global user.name "FIRST_NAME LAST_NAME"`` and ``git config --global user.email "MY_NAME@example.com"`` to set the user's name and email address so all the pushes can be identified.

#. On your laptop or the Windows Tools VM environment open VC, unless already open, and click **File -> New Window**

   .. figure:: images/3.png

#. In the new Window click **View -> Command Palette** and type ``git clone``
#. Paste the earlier copied URl from Gitea's Repo

   .. figure:: images/5.png

#. Provide the location where to clone the data in from the Gitea Repo in the next screen (**Select Folder**). Create a new folder called **github**, open that folder and click the **Select Repository Location** button.
#. This will clone the repo into our development environment. In the bottom right corner you will see a message, *Open*, *Open in New Window*, Click the **Open** button

   .. figure:: images/7.png

#. You have your FIESTA_APPLICATION folder on the left side of the screen with no files in there.
#. Click on the **new File** icon (first one next to the name of the folder FIESTA_APPLICATION) and call it README.md

   .. figure:: images/8.png

#. Copy the below text in the README.md file and save it.

   .. code-block:: bash

    # Fiesta Application

    This Repo is built for the Fiesta Application and has all needed files to build the containerized version of the Fiesta app.
    Original version of the Fiesta Application can be found at https://github.com/sharonpamela/Fiesta

#. As we have Git integration installed in VC, we get a blue number on the Git extension (third icon from the top in the left hand pane)

   .. figure:: images/9.png

#. Click the icon that has the **1** on it and provide a message in the Text field and click the :fa:`check` symbol (Commit)
#. Click **Always** on the Warning screen you get
#. Click on the **...** icon next to the SOURCE CONTROL and select Push. This will push the new file onto the Repo in Gitea
#. Provide the login information for Gitea

   .. note::
    In the lower right corner you will get a message with respect to have VC run periodically a git fetch. This is useful if you have multiple people working against the repo, but as we are the only ones, click on **No**

    .. figure:: images/10.png

#. Open Gitea, your Repo and see that a push has been made by user nutanix. README.md is shown in the page and is corresponding to the file we created.

   .. figure:: images/11.png

Now that we have a repo and some data in it, we can configure drone to see the push and start running the CI/CD pipeline...

------

Configure Drone
^^^^^^^^^^^^^^^

Drone needs to understand which Repos to track. To do this we will tell Drone what the repos are.

#. Open Drone in a browser by using the URL **\http://<IP ADDRESS DOCKER VM>:8080** (Drone Authenticates via Gitea)
#. Click the **SYNC** button to have Drone grab the Repos of the user it authenticated against.
#. After a few seconds you will see your **nutanix/Fiesta_Application** Repo
#. Click the **ACTIVATE** button to the right hand side of the Repo
#. Click the **ACTIVATE REPOSITORY** button
#. In the **Main** section click the **Trusted** checkbox. That way we allow drone to use the Repo.
#. Click the **SAVE** button
#. Click the **Repositories** text just above the *Fiesta_Application* text to return to your main dashboard. You can return to the settings by clicking the name of the repo

Drone is now ready to be used. it is looking from a file **.drone.yml** in the root of the repo to tell it what to do. Let's get one created and see what happens...

Use Drone to build an image
^^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Go to your VC instance and create a file in the root of FIESTA_APPLICATION called **.drone.yml**

   .. note::
    If you don't see your FIESTA_APPLICATION click on the two Files icon (first icon in the left hand pane)

#. Copy the below content to the file

   .. code-block:: yaml

    kind: pipeline
    name: default
    
    clone:
      skip_verify: true
    
    steps:
    
      - name: build test image
        image: docker:latest
        pull: if-not-exists
        volumes:
          - name: docker_sock
            path: /var/run/docker.sock
        commands:
          - docker build -t fiesta_app:${DRONE_COMMIT_SHA:0:6} .
    
    volumes:
      - name: docker_sock
        host:
          path: /var/run/docker.sock

#. Save the file. You will see **1** on the Git extension again after you have saved the file.
#. Commit and push the file to the repo as you have done before by following thees steps

   - Click on the Git extension (the one with the **1** on it)
   - Provide a message in the text field and click on the :fa:`check` icon
   - Click the three dots and click **Push**

#. Drone has seen a push action and starts to follow the content of the **.drone.yml** file.
#. Open the **Drone UI -> nutanix/Fiesta_Application -> ACTIVITY FEED -> #1 -> build test image** which has errors.

   .. figure:: images/12.png

#. The steps has searched for a dockerfile, but couldn't find it. Let's fix that
#. Back to VC, create a new file in the root of the **FIESTA_APPLICATION** and call it **dockerfile** and copy the below text (we used this before)

   .. code-block:: docker

      # Grab the needed OS image
      FROM alpine:3.11
      
      # Install the needed packages
      RUN apk add --no-cache --update nodejs npm mysql-client git python3 python3-dev gcc g++ unixodbc-dev curl
      
      # Create a location in the container for the Fiesta Application Code
      RUN mkdir /code
      
      # Make sure that all next commands are run against the /code directory
      WORKDIR /code

      # Copy needed files into the container
      COPY set_privileges.sql /code/set_privileges.sql
      COPY runapp.sh /code
      
      # Make the runapp.sh executable
      RUN chmod +x /code/runapp.sh

      # Start the application
      ENTRYPOINT [ "/code/runapp.sh"]
      
      # Expose port 30001 and 3000 to the outside world
      EXPOSE 3001 3000

#. Save the file, commit and push it to the Gitea repo using VC

#. Open immediately the Drone UI and click on **ACTIVITY FEED**

   .. figure:: images/13.png
     
#. Create the following files and copy the respective content in the files as the build step is missing them...

   .. figure:: images/14.png

   - set_privileges.sql

     .. code-block:: sql

       grant all privileges on FiestaDB.* to fiesta@'%' identified by 'fiesta';
       grant all privileges on FiestaDB.* to fiesta@localhost identified by 'fiesta';

   - runapp.sh

     .. code-block:: bash

       #!/bin/sh

       # Clone the Repo into the container in the /code folder we already created in the dockerfile
       git clone https://github.com/sharonpamela/Fiesta /code/Fiesta
       
       # Change the configuration from the git clone action
       sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
       sed -i "s/REPLACE_DB_HOST_ADDRESS/<IP ADDRESS OF MARIADB SERVER>/g" /code/Fiesta/config/config.js
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

#. Save the files in the FIESTA_APPLICATION
#. Commit and push the new files to the Repo
#. Open immediately the Drone UI and click on **ACTIVITY FEED**
#. You see now that the steps have been completed all without any issues.

   .. figure:: images/15.png

#. Switch the VC window to the **docker VM** so we can use the terminal to run some commands
#. Run ``docker image ls`` to see our create image via the CI/CD pipeline


   .. figure:: images/16.png

------

Test the build images
^^^^^^^^^^^^^^^^^^^^^

In a CI/CD pipeline testing is very important and needs to be run automatically. Let's get this step in our **.drone.yml** file

#. Open the VC window that we used to push the files to Gitea
#. Open the **.drone.yml** file
#. Add the following to the **.drone.yml** file, before the **volumes:** section (we are using variables in the test step)

   .. code-block:: yaml

      - name: Test built container
        image: fiesta_app:${DRONE_COMMIT_SHA:0:6}
        pull: if-not-exists
        environment:
          DB_SERVER: <IP ADDRESS OF MARIADB SERVER>
          DB_PASSWD: fiesta
          DB_USER: fiesta
          DB_TYPE: mysql
        commands:
          - npm version
          - mysql -u$DB_PASSWD -p$DB_USER -h $DB_SERVER FiestaDB -e "select * from Products;"
          - git clone https://github.com/sharonpamela/Fiesta.git /code/Fiesta
          - sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
          - sed -i "s/DB_DOMAIN_NAME/LOCALHOST/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_USER_NAME/$DB_USER/g" /code/Fiesta/config/config.js
          - sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD/g" /code/Fiesta/config/config.js
          - cat /code/Fiesta/config/config.js
    
   .. note::
     Make sure you have the **- name** at the same indent as the already **- name** section in the file. Otherwise you'll get an error message like below...
     Also change the **<IP ADDRESS OF MARIADB SERVER>** to the correct IP address

     .. figure:: images/17.png
   
   This is how it should look like

   .. figure:: images/18.png

#. This step will do the following:

   - Use the earlier build container (*image* section)
   - Set variables so we can use them in the commands (*environment* section)
   - Run commands to see if (*commands* section)
     
     - npm has been installed in the container
     - can we connect to the MySQL database SERVER
     - can we clone the data from the github repo
     - can we change a file that exists after the git clone command
     - show the end result of the changed config file
  
#. Save the file, commit and push to Gitea and open the Drone UI.
#. Drone will only move to the next step if the previous step was successful.

   .. figure:: images/19.png

As all steps have completed successful and the output of the **config.js** file is according to what is expected, looking at the bash commands, we can start with the next phase. Upload the image to Dockerhub...

-------

Upload the images
^^^^^^^^^^^^^^^^^

For this part of the workshop you should have a Dockerhub account created. The examples we will be using are using **devnutanix** as the username for Dockerhub. The user **nutanix** was already taken...

For images to be uploaded, we need to do two things, 1) We need to tag images we want to upload to dockerhub with the username (**devnutanix** in our example) and we need to login to docker hub before we can push images.

Manual upload of images
***********************

.. warning::
   The below steps are using the **devnutanix** as the user name for the dockerhub username. you have to use **YOUR** dockerhub username and password!!

#. Login to your Docker VM, if not already done, using **root** and **nutanix/4u** as the credentials or use your terminal in VC both options work.
#. Run the command ``docker login`` and use your credentials you used to set up your Dockerhub account

   .. figure:: images/20.png

#. If you see the message **Login Succeeded** Docker has stored the credentials and will use them the next time you run ``docker login``
#. Run ``docker image ls`` to get the list of images on your docker VM

   .. figure:: images/21.png

#. Run ``docker image tag fiesta_app:15b0c0 devnutanix/fiesta_app:1.0`` (the version **15b0c0** came from step 6 in the **Test the build images** screenshot. Please use yours as mentioned in the Drone UI) this will create a new image which will be tagged **devnutanix/fiesta_app** with version **1.0**
#. Running ``docker image ls`` is showing the image in the list

   .. figure:: images/22.png

#. Run ``docker push devnutanix/fiesta_app:1.0`` to initiate to push of the image onto the Dockerhub environment
#. After a few seconds you should see this in your screen

   .. figure:: images/23.png

#. Open your dockerhub account using a browser. In your account you should now see the just pushed image 

   .. figure:: images/24.png

Now that we can do this manually, let's get drone to do it for us the next time.

CI/CD Upload of images
**********************

#. Open the VC instance where you have changed, created, committed and pushed files, like **.drone.yml** before.
#. Open the .drone.yml file and add the following part (before the **volumes** section!)

   .. code-block:: yaml

      - name: Push to Dockerhub
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
          - docker image tag fiesta_app:${DRONE_COMMIT_SHA:0:6} devnutanix/fiesta_app:latest
          - docker image tag fiesta_app:${DRONE_COMMIT_SHA:0:6} devnutanix/fiesta_app:${DRONE_COMMIT_SHA:0:6}
          - docker push devnutanix/fiesta_app:${DRONE_COMMIT_SHA:0:6}
          - docker push devnutanix/fiesta_app:latest
 
#. Save the file. **DON'T COMMIT AND PUSH YET!!!!** we need to make a small change to Drone to make the step work
#. As we are using the **from_secret** parameter we need to tell Drone what the secret is. Open the Drone UI (**\http://<IP ADDRESS OF DOCKER VM>:8080**)
#. Click on your **Fiesta_Application repository -> SETTINGS**
#. Under the **Secrets** section type the following - Hit the **ADD SECRET** button after each line:

   - **dockerhub_username** - Your DockerHub Account name (we will use devnutanix)
   - **dockerhub_password** - The password of the Dockerhub Account

   .. figure:: images/25.png

#. Return to the VC instance we left earlier and run the Commit and push step via the Git extension, to get the CI/CD running. The end stage will be a push to the Dockerhub. The end of the CI/CD Pipeline should be that we have three images/versions in the Dockerhub environment (the below image is composed out of Drone UI and Dockerhub UI)

   .. figure:: images/27.png

Now that we are able to use the CI/CD pipeline to build, basic test and push to Dockerhub repository the last step is to deploy the image as a container to the docker VM.

-------

Deploy the images
^^^^^^^^^^^^^^^^^

As we already deployed our own build Fiesta_App image in a former part of the workshop (:ref:`basic_container`) we know what the steps are to deploy an image. Those steps need to be repeated by the CI/CD pipeline AFTER the test and the upload have passed. Only then we are allowing the deployment of the image.

#. Open the **.drone.yml** file
#. Add the following text 

   .. code-block:: yaml
    
       - name: Deploy newest image
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
           - if [ `docker ps | grep Fiesta_App | wc -l` -eq 1 ]; then echo "Stopping existing Docker Container...."; docker stop Fiesta_App; else echo  "Docker container has not been found..."; fi
           - sleep 10
           - docker run --name Fiesta_App --rm -p 5000:3000 -d devnutanix/fiesta_app:latest

   .. note::
      The commands are there to:

      - Make sure that there is no running container with the name Fiesta_App, if it is, it will stop it. Also provide some information in the console of the step in Drone
      - Wait 10 seconds so Docker Engine can close the container
      - Deploy the container and:

        - *--name* Provide the name of the container
        - *--rm* Remove the container if it is being stopped
        - *-p* Open port 5000 for the outside world and map it to port 3000 on the container
        - *-d* Run in the background as a daemon 

#. Save the file, Commit and push the image
#. This will make drone also deploy the container

-------

Use variables outside of the container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

As we have now a running CI/CD pipeline that is functional, we need to start thinking about the parameters that may change during new tests. These changes can be due to the environment we use being Dev/Test or Production. Having passwords and/or secrets in plain text is not the best idea as well. This means that the variables/parameters, we now have defined in the different files, need to be stored somewhere. The location where we put these variables/parameters must be used during build, test, upload and deploy time by the CI/CD pipeline. We already used the **Secrets** in the upload and deploy steps of Drone. So let's extend it for the images that need to be built for all variables/parameters.

List of variables/parameters
****************************

The following parameters are being used by the image (Description of the variable/parameter - name of the variable/parameter):

- Dockerhub username - dockerhub_username
- Dockerhub password - dockerhub_password
- Database Server IP - DB_SERVER
- Database name - DB_NAME
- Database type - DB_TYPE
- Database user - DB_USER
- Database password - DB_PASSWD

We need to make changes to the following files so they use the set variables/parameters

- .drone.yml
- runapp.sh

We are also going to recreate the images, but that will be solved by the CI/CD pipeline, so no need to rebuild manually images etc.. 

Change runapp.sh
****************

#. Open the VC that you used to create the **runapp.sh** earlier (you should have the .drone.yml and dockerfile in the the same directory)
#. Exchange **all** content of the file with the below

   .. code-block:: bash

      #!/bin/sh

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

      # Clone the Repo into the container in the /code folder we already created in the dockerfile
      git clone https://github.com/sharonpamela/Fiesta /code/Fiesta

      # Change the Fiesta configuration code so it works in the container
      sed -i "s/REPLACE_DB_NAME/$DB_NAME/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_USER_NAME/$DB_USER1/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD1/g" /code/Fiesta/config/config.js

      # Install the nodemon package
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

#. Save the file
#. Open the **.drone.yml** file and replace **all** content with the following

   .. code-block:: yaml

      kind: pipeline
      name: default

      clone:
        skip_verify: true

      steps:

        - name: build test image
          image: docker:latest
          pull: if-not-exists
          volumes:
            - name: docker_sock
              path: /var/run/docker.sock
          commands:
            - docker build -t fiesta_app:${DRONE_COMMIT_SHA:0:6} .

        - name: Test local built container
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
            - git clone https://github.com/sharonpamela/Fiesta /code/Fiesta
            - if [ `echo $DB_PASSWD | grep "/" | wc -l` -gt 0 ]; then DB_PASSWD=$(echo "${DB_PASSWD//\//\\/}"); fi
            - sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
            - sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
            - sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
            - sed -i "s/REPLACE_DB_USER_NAME/$DB_USER/g" /code/Fiesta/config/config.js
            - sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD/g" /code/Fiesta/config/config.js

        - name: Push to Dockerhub
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

        - name: Deploy newest image
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
            - if [ `docker ps | grep Fiesta_App | wc -l` -eq 1 ]; then echo "Stopping existing Docker Container...."; docker stop Fiesta_App; else echo "Docker container has not been found..."; fi
            - sleep 10
            - docker run --name Fiesta_App --rm -p 5000:3000 -d -e DB_SERVER=$DB_SERVER -e DB_USER=$DB_USER -e DB_TYPE=$DB_TYPE -e DB_PASSWD=$DB_PASSWD -e DB_NAME=$DB_NAME $USERNAME/fiesta_app:latest

      volumes:
      - name: docker_sock
        host:
          path: /var/run/docker.sock

#. Save the file
#. Open the Drone UI so we can set the variables/parameters we need during the different steps of the CI/CD pipeline
#. Open your repository and click the **SETTINGS** tab
#. Scroll a bit down to the **Secrets** section
#. Create the following secrets and their values (click the **ADD A SECRET** button to save the secret)

   - **db_server_ip** - <IP ADDRESS OF MARIADB SERVER>
   - **db_passwd** - fiesta
   - **db_user** - fiesta
   - **db_type** - mysql
   - **db_name** - FiestaDB

   .. figure:: images/28.png

#. In Drone click the **ACTIVITY FEED** text (top of the screen) to return to the activity screen
#. Now go back to the VC UI and **Commit and Push** the changed files. As soon as you have done so, return to the Drone UI to see the steps being run using the created variables/parameters

   .. figure:: images/29.png

#. To see the progress of the container switch to the VC that we used to connect to the docker vm, or use a ssh session to the docker server and run ``docker logs --follow Fiesta_App``. The process will take approx 2-3 minutes. Wait to open the browser till you see a message like ``On Your Network:  http://172.17.0.6:3000``.
#. Point your browser to **\http://<IP ADDRESS DOCKER VM>:5000/Products** and you'll see the Fiesta Application as you have seen before.

------
.. raw:: html

.. raw:: html

    <H1><font color="#AFD135"><center>Congratulations!!!!</center></font></H1>

We have just used our CI/CD pipeline and solved, so far, these topics. 

- The way of working using **vi** or **nano** is not very effective and ready for human error (:fa:`thumbs-up`)
- Variables needed, have to be set outside of the image we build (:fa:`thumbs-up`)
- The container build takes a long time and is a tedeous work including it's management (:fa:`thumbs-up`)
- The image is only available as long as the Docker VM exists (:fa:`thumbs-up`)
- The start of the container takes a long time (:fa:`thumbs-down`)

The next and last module in this workshop, is solving the last :fa:`thumbs-down`. Having the container start faster... Let's go for it!