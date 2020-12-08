.. _docker_start:

Containerize the Fiesta App
===========================

This part of the workshop is showing you how the original application can be "translated" into a containerized application.

High level steps:

- use the Docker VM to build the containerized application
- test the application by deploying the container

.. note::
   Estimated time **30 minutes**

Build the container
-------------------

This part of the workshop is all about:

- Analyse the original Fiesta Application
- Get the basic container running
- Get the installation of the needed packages
- Get the Fiesta Application as a container

Analyse the original Fiesta Application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Let's start analyzing the installation of the Fiesta Application by using the Blueprint that you have deployed earlier.

#. In PRISM Central open :fa:`bars` and select **Calm**
#. Click the Blueprint |bp_icon| icon
#. Open the uploaded and deployed blueprint
#. Click on the **Fiesta_App_VM Services -> Packages -> Configure install**

   .. figure:: images/1.png

#. You see three steps that are run for the installation of the Fiesta Application.
#. Open the second step (Install npm), as the first one is for setting the hostname and the O/S related updates.
#. In that step you see what is happening:
   
   - Install some packages needed for the application to run
   - Clone a Git repository
   - Install npm
   - Build the application
   - Install a npm dependency
   - Run steps to get the application build

   .. figure:: images/2.png

These steps are to be repeated during the container creation


.. _basic_container:

Get the basic container
^^^^^^^^^^^^^^^^^^^^^^^

During this part we are going to install our first container. The building of container are being done using a specific file. This file is called ``dockerfile``.
Follow these steps to create the first container. As space consumed by the container is crucial we are going to rebuild our Fiesta Application wit the use of Alpine Linux. This is a small Linux distribution and very commonly used by containe builders.

#. Login to your docker vm using SSH as **root** and the password **nutanix/4u**
#. Run the command ``mkdir github``
#. Run ``cd github``
#. As we will be creating the Fiesta Application later in this workshop, let's clone the Github repository so we have it. Run ``git clone https://github.com/sharonpamela/Fiesta``
#. Create a ``dockerfile`` using the command ``vi dockerfile`` (we are using vi as the built-in editor during this workshop, nano works as well)
#. Copy and paste the following code:

   .. code-block:: dockerfile

      # Grab the needed OS image
      FROM alpine:3.11
      
      # Install the needed packages
      RUN apk add --no-cache --update nodejs npm mysql-client git python3 python3-dev gcc g++ unixodbc-dev curl
      
      # Create a location in the container for the Fiest Application Code
      RUN mkdir /code
      
      # Make sure that all next commands are run against the /code directory
      WORKDIR /code

      # Copy needed files into the container
      COPY runapp.sh /code
      
      # Make the runapp.sh executable
      RUN chmod +x /code/runapp.sh

      # Start the application
      ENTRYPOINT [ "/code/runapp.sh"]
      
      # Expose port 30001 and 3000 to the outside world
      EXPOSE 3001 3000

#. Save and close the file. For vi use **<ESC>:wq!**.
#. Create the last needed file ``vi runapp.sh`` and copy/paste the following:

   .. note::
    
      Make sure you have changed the **<IP ADDRESS OF YOUR MARIADB SERVER>** to correspond to your MariaDB Database VM's IP Address in the below!!

   .. code-block:: bash
      
      #!/bin/sh
    
      # Clone the Repo into the container in the /code folder we already created in the dockerfile
      git clone https://github.com/sharonpamela/Fiesta /code/Fiesta

      # Change the configuration from the git clone action
      sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
      sed -i "s/REPLACE_DB_HOST_ADDRESS/<IP ADDRESS OF YOUR MARIADB SERVER>/g" /code/Fiesta/config/config.js
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

#. Save and Close the file
#. Your github Directory should look like this

   .. figure:: images/5.png

#. Now that we have al needed files, let's run ``docker build .`` to create the container. This takes approximately 1 minute

   .. note:: 
       If you get a message stating **You have reached your pull limit...** ask the leading SE for the solution

#. Run ``docker image ls`` to see our image we've just build

   .. figure:: images/6.png

The alpine image with tag 3.11 is seen and an image with an ID, but they don't mean much to us, let's recreate the image and provide a more meaningfull name

#. Rerun ``docker build . -t fiesta_app:1.0``. This will tag the existing image **<none>** to be called **fiesta_app** with version number **1.0**
#. Run ``docker image ls`` to show the list of images we have in our docker environment.

   .. figure:: images/7.png

#. Let's start the docker image to become a container by running ``docker run -d --rm --name Fiesta_App fiesta_app:1.0``

   Explanation of the command :

   - ``--name`` give the container a name and not just some random name. This makes the management of the container easier
   - ``--rm`` remove the container after it stops
   - ``-d`` run as a Daemon in the background

#. Using ``docker logs --follow Fiesta_App`` to see the console log of the container
#. After the application has been started you will see something like the below (approx. 2-3 minutes)

   .. figure:: images/8.png

So the application has been started and the database can be received.

.. note::
    If the below error log lines are seen (**Unhandled rejection SequelizeConnectionError.....**), the database cannot be accessed. Possible first reason is that we have forgotten to change the IP address of the database, or the IP address is set wrongly. Check the IP address of the MariaDB server (via :fa:`bars` **-> Calm -> Applications -> your Application  -> Services -> MariaDB** ) and make the changes in **runapp.sh**, build the container again and start the container again.

    .. figure:: images/8a.png

That means the application is running as a container. BUT if you would open the URL as mentioned in the screenshot on port 3000, of your docker VM, you won't get any answer. The reason for this is that the IP address of the container is internal to the Docker environment. To make this work we have to tell the docker engine to "open" port 3000 to the outside world.

#. Use <CTRL>+C to drop back to the prompt
#. Stop the container running ``docker stop Fiesta_App``. This will stop the container and after that remove the container from the docker engine
#. Now using the **-p 5000:3000** parameter in the ``docker run -d --rm -p 5000:3000 --name Fiesta_App fiesta_app:1.0`` command we are telling the Docker Engine to expose port 5000 to the outside world and map port 5000 to port 3000 in the container. 
#. Wait till you see the same output in the logs as you have seen earlier (from the ``docker logs --follow Fiesta_App`` command) and open a browser. URL to be used is **\http://<IP-ADDRESS-DOCKER-VM>:5000/products**. Now you should see the Fiesta App and the data from the database.

   .. figure:: images/9.png

#. Let's stop the docker container as we don't need it for now in the running state. Run ``docker stop Fiesta_App``.

------

.. raw:: html

    <H1><font color="#AFD135"><center>Congratulations!!!!</center></font></H1>

We have just created our first container version of the Fiesta Application and it is running... **But** we still need to do a few thing...

- The way of working using **vi** or **nano** is not very effective and ready for human error
- Variables needed, have to be set outside of the image we build
- The container build takes a long time and is a tedious work including it's management
- The start of the container takes a long time
- The image is only available as long as the Docker VM exists

The next modules in this workshop are going to address all of these.... Let's go for it!


.. |proj-icon| image:: ../images/projects_icon.png
.. |bp_icon| image:: ../images/blueprints_icon.png
.. |mktmgr-icon| image:: ../images/marketplacemanager_icon.png
.. |mkt-icon| image:: ../images/marketplace_icon.png
.. |bp-icon| image:: ../images/blueprints_icon.png