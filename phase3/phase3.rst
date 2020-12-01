.. _phase3_container:

Using the CI/CD Infrastructure
==============================

This part of the workshop is all about using

- Configure the CI/CD infrastructure
- The CI/CD infrastructure/pipeline to:

  - Build the images and tag the images using a tag convention of <IP ADDRESS OF DOCKER VM>:<commit number>
  - Test the build images
  - Upload the images to Dockerhub so we can have even after we have destroyed our development environment
  - Deploy the images as containers

- Tooling

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

#. Open in a browser your Gitea interface and login using your set credentials (default is **nutanix** and **nutanix/4u**) by clicking on the Login icon (top right corner)
#. Click on the **+** sign in the top right hand corner and select **+New Repository**

   .. figure:: images/1.png

#. Provide a name, we have chosen **Fiesta_Application**, and click the **Create Repository** button
#. After the Repo has been created, you will see the possibilities on how to clone the Repo

   .. figure:: images/2.png

#. Copy the https URL
#. Open a command line or terminal on your laptop or Windows Tools Vm and run ``git config --global http.sslVerify false``. This step is necessary otherwise git is not willing to clone anything from a Version Control Manager using Self signed certificates. In the same command line or terminal session run the following two commands ``git config --global user.name "FIRST_NAME LAST_NAME"`` and ``git config --global user.email "MY_NAME@example.com"``

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

#. As we have Git integration installed in VC, we get a blue number in the extension left hand bar

   .. figure:: images/9.png

#. Click the icon that has the *1* on it and provide a message in the Text field and click the :fa:`check` symbol (Commit)
#. Click **Always** on the Warning screen you get
#. Click on the **...** icon next to the SOURCE CONTROL and select Push. This will push the new file onto the Repo in Gitea
#. Provide the login information for Gitea

   .. note::
    In the lower right corner you will get a message with respect to have VC run periodically a git fetch. This is useful if you have multiple people working against the repo, but as we are the only ones, click on **No**

    .. figure:: images/10.png

#. Open Gitea, your Repo and see that a push has been made by user nutanix. README.md is shown in the page and is corresponding to the file we created.

   .. figure:: images/11.png

Now that we have a repo and some data in it we can configure drone to see the push and pick up the dockerfile and start running the CI/CD pipeline...

------

Configure Drone
^^^^^^^^^^^^^^^

Drone needs to understand which Repos to track. To do this we will tell Drone what the repos are.

#. Open Drone in a browser by using the URL **\http://<IP ADDRESS DOCKER VM>:8080**. Drone Authenticates via Gitea
#. Click the **SYNC** button to have Drone grab the Repos of the user it authenticated against.
#. After a few seconds you will see your **nutanix/Fiesta_Application** Repo
#. Click the **Activate** button to the right hand side of the Repo
#. Click the **ACTIVATE REPOSITORY** button
#. In the **Main** section click the **Trusted** checkbox. That way we allow drone to use the Repo.
#. Click the **SAVE** button
#. Click the **Repositories** text just above the *Fiesta_Application* text to return to your main dashboard. You can return to the settings by clicking the name of the repo

Drone is now ready to be used. it is looking from a file **.drone.yml** in the root of the repo to tell it what to do. Let's get one created and see what happens...

Use Drone to build an image
^^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Go to your VC instance and create a file in the root of FIESTA_APPLICATION called **.drone.yml**

   .. note::
    If you don't see your FIESTA_APPLICATION click on the two Files icon

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

   - Click on the Git extension( the one with the **1** on it
   - Provide a message in the text field and click on the :fa:`check` icon
   - Click the three dots and click **Push**

#. Drone has seen a push action and starts to follow the content of the **.drone.yml** file.
#. Open the **Drone UI -> nutanix/Fiesta_Application -> ACTIVITY FEED -> #1 -> build test image** which has errors.

   .. figure:: images/12.png

   .. TODO:: change the image to reflect the correct information!!!   

#. The steps has searched for a dockerfile, but couldn't find it. Let's fix that
#. Back to VC, create a new file in the root of the **FIESTA_APPLICATION** and call it **dockerfile** and copy the below text (we used this before)

   .. code-block:: docker

      # Grab the needed OS image
      FROM alpine:3.11
      
      # Install the needed packages
      RUN apk add --no-cache --update nodejs npm mysql-client git python3 python3-dev gcc g++ unixodbc-dev curl
      
      # Create a location in the container for the Fiest Application Code
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

   .. TODO:: change the image to reflect the correct information!!!   

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

   .. TODO:: change the image to reflect the correct information!!!

#. Switch the VC window to the **docker VM** so we can use the terminal to run some commands
#. Run ``docker image ls`` to see our create image via the CI/CD pipeline


   .. figure:: images/16.png

   .. TODO:: change the image to reflect the correct information!!!

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
          DB_SERVER: 10.42.37.59
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
    
   .. danger::
     Make sure you have the **-name** at the same indent as the already **-name** section in the file. Otherwise you'll get an error message like below...

     .. figure:: images/17.png
   
   This is how it should look like

   .. figure:: images/18.png

   .. TODO:: change the image to reflect the correct information!!!

#. This step will do the following:

   - Use the earlier build container (*image* section)
   - Set variables so we can use them in the commands (*environment* section)
   - Run commands to see if (*commands* section)
     
     - npm has been installed in the container
     - can we connect to the MySQL database SERVER
     - can we clone the data from the github repo
     - can we change a file that exists after the git clone command
     - show the end result of the changed config file
  
#. Drone will only move to the next step if the previous step was successful. Save the file, commit and push to Gitea and open the Drone UI.

   .. figure:: images/19.png

As all steps have completed successful and the output of the **config.js** file is according to what is expected, looking at the bash commands, we can start with the next phase. Upload the image to Dockerhub...

-------

Upload the images
^^^^^^^^^^^^^^^^^





-------

Deploy the images
^^^^^^^^^^^^^^^^^



-------

.. raw:: html

.. raw:: html

    <H1><font color="#AFD135"><center>Congratulations!!!!</center></font></H1>

We have just created our first CI/CD pipeline driven image build. **But** we still have to do a few thing...

- The way of working using **vi** or **nano** is not very effective and ready for human error (:fa:`thumbs-up`)
- Variables needed, have to be set outside of the image we build (:fa:`thumbs-down`)
- The container build takes a long time and is a tedeous work including it's management (:fa:`thumbs-up`)
- The start of the container takes a long time (:fa:`thumbs-down`)
- The image is only available as long as the Docker VM exists (:fa:`thumbs-down`)

The next modules in this workshop are going to address these :fa:`thumbs-down`.... Let's go for it!