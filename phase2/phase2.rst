.. _phase2_container:

Using tooling
=============

As you have noticed we have create our containerized version of Fiesta, but we have been using vi or nano to manipluate files. These tools work, but are not easy and efficient to change files on a large scale. So we are going to use Visual Code to manipulate the files we create or change from now on.

After we have the Visual Code setup and configured, we are going to set up our CI/CD pipeline using Drone (http://harness.io).

Visual Code
-----------

As we have Visual Code already installed and added extension, we are going to use it.

#. Start Visual Code(VC) in your Windows Tools VM or your laptop
#. Click in VC on **View -> Command Palette...**

   .. figure:: images/1.png

#. Type **Remote SSH** and select ** Remote-SSH: Connect Current Window to Host...**

   .. figure:: images/2.png

#. Click on **+ Add New SSH Host...** and type **ssh root@<IP ADDRESS OF YOUR DOCKER VM>**
#. Select the location where you want to update the config file. Your choice..
#. Select **Connect** (right bottom corner) to connect to the VM
#. Answer the following, if you get the questions from VC

   - O/S - Linux
   - Fingerprint - Continue
   - Password - nutanix/4u

#. Click on both messages that may pop-up the **Don't Show Again** button

   .. figure:: images/3.png

#. If not already selected, click in the left pane on the **Files** button and select **Open Folder**

   .. figure:: images/4.png

#. Provide the **/** as the folder you want to open
#. It will take some time before it opens as VC needs to install and configure the remote host. This takes approximately <1 minute
#. Now you should see the folder structure of the VM, open /root and you will see everything including the earlier created **github** directory
#. Open the **github** directory and you wil find the same information as you had created earlier using ``vi`` or ``nano``

   .. figure:: images/5.png

This way of chnaging files is easier then using the ``vi`` or ``nano``. Even though quick changes can be done using those tools.

------

Build the CI/CD Infrastructure
------------------------------

Now that we have our tooling ready we need to build the CI/CD pipeline. For this we are going to setup the following parts:

- Gitea as the Version Control Manager
- Drone for the CI/CD part of the pipeline
- Use of GitDesktop or GitKraken for controlling the push and pull of the new code

As we already have created the needed infrastructure using docker-compose we're going to pull the existing yaml file, make changes and start the CI/CD pipeline

#. Open a ssh session to your *Initials*\ **-docker-vm** by using VC's built in Terminal
#. In VC click on **Terminal ->  New Terminal**. This will open a new ssh session to the machine you had already opened to see the "remote folder" and saves switching between windows

   .. figure:: images/6.png
   .. figure:: images/7.png

#. In the terminal run the following commands to get the needed directories

   - ``mkdir -p /docker-location/gitea``
   - ``mkdir -p /docker-location/drone/server``
   - ``mkdir -p /docker-location/drone/agent``
   - ``mkdir -p /docker-location/mysql``

#. In the Terminal of VC, run ``cd ~/github``
#. Run the command ``curl --silent https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/CI-CD%20Pipeline/docker_files/docker-compose.yaml -O`` to pull the yaml file

#. Open in VC the **docker-compose.yaml** file by clicking in the left hand pane

   .. figure:: images/8.png

#. 






