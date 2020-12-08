.. _phase4_container:

Starting the container faster
=============================

As you may have noticed it takes a while before the Fiesta_App container is up and running. The CI/CD pipeline does it work in automating the build, test, upload to our Dockerhub registry and deployment steps, but still takes a few minutes before the application is up and running and serving \HTTP requests.

The reason for the time needed is that during the start of the container it has to run multiple npm commands to become ready. This part of the module is to see if we can speed this up and at the same time lower the size of the Fiesta_App image.

.. note::
   Estimated time **45 minutes**

Multi step image build
----------------------

To do the step up of the Fiesta Application we are going to do three things

#. Recreate the **dockerfile** to become a multi-step build
#. Change the **runapp.sh** so it doesn't start all the installation steps for the Application
#. Change the test step in **.drone.yml**

.. ntoe::
   Please follow the steps to the letter as they are dependent on each other. When we save a file, just save and **don't commit and/or push** the files!!

Change dockerfile
^^^^^^^^^^^^^^^^^

#. Open your VC that you used before to manipulate the **runapp.sh, .drone.yml** and the **dockerfile**
#. Exchange **all** content in the **dockerfile** with the content below

   .. code-block:: yaml

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
      
      # Copy the starting app
      COPY runapp.sh /code
      RUN chmod +x /code/runapp.sh
      WORKDIR /code
      
      # Start the application
      ENTRYPOINT [ "/code/runapp.sh"]
      EXPOSE 3001 3000

#. Save the file

Change runapp.sh
^^^^^^^^^^^^^^^^

Now the dockerfile is running the npm stuff compared to earlier images, this has been done by the runapp.sh. We can change the file to less lines.

#. Open in your VC **runapp.sh**
#. Delete **all** lines from the file and copy paste the following in the file

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
      
      # Change the Fiesta configuration code so it works in the container
      sed -i "s/REPLACE_DB_NAME/$DB_NAME/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_HOST_ADDRESS/$DB_SERVER/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_DIALECT/$DB_TYPE/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_USER_NAME/$DB_USER1/g" /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_PASSWORD/$DB_PASSWD1/g" /code/Fiesta/config/config.js
      
      # Run the NPM Application
      cd /code/Fiesta
      npm start

#. Save the file

Change the .drone.yml file
^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Open the **.drone.yml** file
#. Under the **Test local built container** section, remove the line ``- git clone https://github.com/sharonpamela/Fiesta /code/Fiesta`` as we already took care of that in **dockerfile**. Testing this step would lead to an error.
#. Save the file
#. **Commit and push** the changed files to Gitea and look at the Drone UI to see the container being build
#. As you can see, the build phase is taking more time as it needs to run multiple steps.

   .. figure:: images/1.png

#. Wait till all steps have been run before moving forward

Check effect of the new build method
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To see the difference of these "New Way of Building" let's check two things:

- Size fo the new image
- Start time using the new image

Check size difference
*********************

#. Open a ssh session to the docker vm (using your other VC window or via terminal/putty)
#. Run ``docker image ls`` to see the size of the images. As we can see the image has gone from 371 MB to 277 MB

   .. figure:: images/3.png

Check the start time needed
***************************

#. Open a ssh session to the docker vm (using your other VC window or via terminal/putty)
#. Stop the Fiesta_App container using ``docker stop Fiesta_App``
#. Run ``docker ps --all`` to make sure the Fiesta_App is not there anymore

   .. figure:: images/4.png

#. Run the following from the command line (**make sure you use your information!!**)

   .. code-block:: bash
      
      DB_SERVER=<IP ADDRESS OF MARIADB VM>
      DB_NAME=FiestaDB
      DB_USER=fiesta
      DB_PASSWD=fiesta
      DB_TYPE=mysql
      USERNAME=<DOCKERHUB USERNAME>
      docker run --name Fiesta_App --rm -p 5000:3000 -d -e DB_SERVER=$DB_SERVER -e DB_USER=$DB_USER -e DB_TYPE=$DB_TYPE -e DB_PASSWD=$DB_PASSWD -e DB_NAME=$DB_NAME $USERNAME/fiesta_app:latest && docker logs --follow Fiesta_App

#. See how long it takes to get to the line that tells ``On Your Network:  http://172.17.0.6:3000`` **(approx. 15 seconds)**
#. Run ``docker stop Fiesta_App`` to stop and remove the container
#. Repeat the aboves steps, but change the image by **not using the latest as the version, but one that is 371 MB in size** *(use* ``docker image ls`` *to see the images available)* and keep track how long it takes to get to the same line ``On Your Network:  http://172.17.0.6:3000`` **(approx. 220 seconds)**
#. Run ``docker stop Fiesta_App`` to stop and remove the container

-------

.. raw:: html

.. raw:: html

    <H1><font color="#AFD135"><center>Congratulations!!!!</center></font></H1>

We have just used our CI/CD pipeline and solved these topics. 

- The way of working using **vi** or **nano** is not very effective and ready for human error (:fa:`thumbs-up`)
- Variables needed, have to be set outside of the image we build (:fa:`thumbs-up`)
- The container build takes a long time and is a tedeous work including it's management (:fa:`thumbs-up`)
- The image is only available as long as the Docker VM exists (:fa:`thumbs-up`)
- The start of the container takes a long time (:fa:`thumbs-up`)





..   .. TODO:: 

        All on MariaDB

        - Integrate with Era if we have a dev branch
        - Use Era to clone a Dev database from Production Database if there is none
        - Use Era to refresh the data if there is a cloned Dev MariaDB server