.. _phase2_container:

Using tooling
=============

As you have noticed we have create our containerized version of Fiesta, but we have been using vi or nano to manipluate files. These tools work, but are not easy and efficient to change files on a large scale. So we are going to use Visual Code to manipulate the files we create or change from now on.

After we have the Visual Code setup and configured, we are going to set up our CI/CD pipeline using Drone (http://harness.io).

.. note::
   Estimated time **30 minutes**

Visual Code
-----------

As we have Visual Code already installed and added extensions, we are going to use it.

#. Start Visual Code (VC) in your Windows Tools VM or on your laptop
#. Click in VC on **View -> Command Palette...**

   .. figure:: images/1.png

#. Type **Remote SSH** and select **Remote-SSH: Connect Current Window to Host...**

   .. figure:: images/2.png

#. Click on **+ Add New SSH Host...** and type **ssh root@<IP ADDRESS OF YOUR DOCKER VM>**
#. Select the location where you want to update the config file. Your choice..
#. Select **Connect** (right bottom corner) to connect to the VM
#. Answer the following, if you get the questions from VC

   - O/S - Linux
   - Fingerprint - Continue
   - Password - nutanix/4u

#. Click on both messages that may pop-up in the bottom right hand corner, the **Don't Show Again** button

   .. figure:: images/3.png

#. If not already selected, click in the left pane on the **Files** button (left hand pane, first icon) and select **Open Folder**

   .. figure:: images/4.png

#. Provide the **/** as the folder you want to open and click on **OK**
#. It will take some time before it opens as VC needs to install and configure the remote host. This takes approximately <1 minute (you might be asked for the password again)
#. Now you should see the folder structure of the VM, open **/root/github** and you will see everything created earlier

   .. figure:: images/5.png

This way of changing files is easier then using the ``vi`` or ``nano``. Even though quick changes can be done using those tools.

.. note::

    During the working with VC, you might get pop-up messages due to updates or extensions having some extra information like the below screenshot. It is up to you what to do with them. Those messages can be denied by clicking the **X** in the right hand top corner. They have no influence on the workshop...

    .. figure:: images/message-box.png

------

Build the CI/CD Infrastructure
------------------------------

Now that we have our tooling ready we need to build the CI/CD pipeline. For this we are going to setup the following parts:

- Gitea as the Version Control Manager
- Drone for the CI/CD part of the pipeline
- Use of VC for controlling the Commit and push of the new code

Preparation
^^^^^^^^^^^

As we already have created the needed infrastructure using docker-compose we're going to pull the existing yaml file, make changes and start the CI/CD pipeline.

#. Open a ssh session to your *Initials*\ **-docker-vm** by using VC's built in Terminal
#. In VC click on **Terminal ->  New Terminal**. This will open a new ssh session to the machine you had already opened to see the "remote folder" and saves switching between windows

   .. figure:: images/6.png
   .. figure:: images/7.png

#. In the terminal run the following commands to get the needed directories

   .. code-block:: bash

       mkdir -p ~/github
       mkdir -p /docker-location/gitea
       mkdir -p /docker-location/drone/server
       mkdir -p /docker-location/drone/agent
       mkdir -p /docker-location/mysql

#. In the Terminal of VC, run ``cd ~/github``
#. Run the command ``curl --silent https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/CI-CD%20Pipeline/docker_files/docker-compose.yaml -O`` to pull the yaml file
#. To make sure we're not blocked by any rate limit on pulls, run ``docker login`` and authenticate using your dockerhub account you created earlier
#. In the terminal screen run the command ``docker-compose create db gitea`` and wait for the command prompt to return. You will see that images are pulled and at the end that the two services have been created

   .. figure:: images/9.png

#. Run ``docker-compose start db gitea`` to start the MySQL and Gitea containers.

Now that we have part of our CI/CD running, we need to configure it. We start with Gitea and end with Drone.

------

Gitea configuration
^^^^^^^^^^^^^^^^^^^

To make sure we can use https with Gitea, we need to go into the gitea docker container. Run a command and define what we need. Then we can configure Gitea to use the Self Signed SSL certificates.

#. Run ``docker exec -it gitea /bin/bash``
#. In the docker prompt run ``gitea cert --host <IP ADDRESS OF THE DOCKER VM>``. This will create two files **cert.pem** and **key.pem** in the root of the container.

   .. figure:: images/10.png

#. Copy the \*.pem files using ``cp /*.pem /data/gitea``
#. Run ``chmod 744 /data/gitea/*.pem``
#. Close the docker connection using **<CTRL>+d**
#. Open a browser and point it to **http://<IP ADDRESS DOCKER VM>:3000**
#. Make the following changes:
   
   - MySQL section:

     - **Host**: <IP ADDRESS OF YOUR DOCKER VM>:3306
     - **Password**: gitea

   
   - General Settings:

     - **SSH Server Port**: 2222
     - **Gitea Base URL**: \https://<IP ADDRESS OF YOUR DOCKER VM>:3000

   .. figure:: images/11.png

#. Click the **Install Gitea** button

Now you will receive an error that **This site can’t provide a secure connection**, but we are going to change that. 
In VC, as we have all files for the containers being saved on the docker VM in the earlier created folders in /docker-location, we can change a file that is needed by Gitea and holds the config. 

#. Open your VC
#. Open the file **/docker-location/gitea/conf/app.ini** and make the following changes under the **[server]** section:

   - **PROTOCOL**  = https
   - **CERT_FILE** = cert.pem
   - **KEY_FILE**  = key.pem

     .. figure:: images/12.png

#. Save the file and restart the container using ``docker-compose restart gitea`` in your terminal windows in VC
#. Reloading the browser page will show an error on the certificate, which is logical as we are now using a Self Signed certificate. Use the normal ways to get to the login screen.
#. The first user will be the admin user of the Gitea application (default)
#. Click the **Register button** to create an account. Provide whatever you want. We are going to use **nutanix**, **nutanix@atnutanix.com** and **nutanix/4u** during the workshop as examples.
#. Click the Register button to have your account created. Welcome to Gitea!!!

   .. figure:: images/14.png

------

Drone configuration
^^^^^^^^^^^^^^^^^^^

As Drone will use Gitea for its authentication, we need to get some parameters from Gitea and change the docker-compose.yaml file.

#. In your gitea click **Settings** by clicking on the Avatar in the right hand top corner

   .. figure:: images/15.png

#. Select Applications and fill the following parameters (under the **Manage OAuth2 Applications** section):

   - **Application name:** drone
   - **Redirect URI:** \http://<IP ADDRESS OF YOUR DOCKER VM>:8080/login

#. Click the **Create Application** button
#. Copy from the next screen the Client ID and the Client Secret

   .. figure:: images/16.png

#. Open the **docker-compose.yaml** file in VC and paste the values in their field names **DRONE_GITEA_CLIENT_ID** and **DRONE_GITEA_CLIENT_SECRET**

   .. figure:: images/17.png

#. Also change under the **drone-server** section in the docker-compose.yaml file

   - **DRONE_GITEA_SERVER=** \https://<IP ADDRESS OF DOCKER VM>:3000
   - **DRONE_SERVER_HOST=** \https://<IP ADDRESS OF DOCKER VM>:8080
   - **DRONE_USER_CREATE=** <USERNAME> to **nutanix**

   .. note::

     If you have chosen a different username (not nutanix) in Gitea, make sure you change the needed parameters in the docker-compose.yaml file (drone-server section  **DRONE_USER_CREATE=username:nutanix,admin:true**)

#. Change under the **drone-docker-runner** section

   - **DRONE_RPC_HOST=** <IP ADDRESS OF DOCKER VM>

#. Save the file
#. Click in Gitea UI the **Save** button and then the **Dashboard** text
#. Open the Terminal in VC
#. Create and start the drone server and agent container by running ``docker-compose create drone-server drone-docker-runner`` and ``docker-compose start drone-server drone-docker-runner``
#. Open a browser and point to **\http://<IP ADDRESS OF DOCKER VM>:8080**. This will try to authenticate the user **nutanix**, the defined user in Drone section in the docker-compose.yaml file with admin right
#. A warning **Authorize Application** message is shown, click on **Authorize Application**

   .. figure:: images/19.png
   
#. The Drone UI will open with nothing in it

   .. figure:: images/18.png

------

.. raw:: html

.. raw:: html

    <H1><font color="#AFD135"><center>Congratulations!!!!</center></font></H1>

We have just created our first CI/CD pipeline infrasturcture. **But** we still have to do a few thing...

- The way of working using **vi** or **nano** is not very effective and ready for human error (:fa:`thumbs-up`)
- Variables needed, have to be set outside of the image we build (:fa:`thumbs-down`)
- The container build takes a long time and is a tedeous work including it's management (:fa:`thumbs-down`)
- The start of the container takes a long time (:fa:`thumbs-down`)
- The image is only available as long as the Docker VM exists (:fa:`thumbs-down`)

The next modules in this workshop are going to address these :fa:`thumbs-down`.... Let's go for it!

