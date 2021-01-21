.. _environment_start:


Starting the CI/CD workshop
===========================

This workshop is trying to teach the basic steps to get from an existing application (NPM and a MariaDB) to a contairezed application where a CI/CD pipeline is being created to:

- Build the new containers
- Test the build container
- Upload the containers to Docker hub registry
- Deploy the new build container

.. note::
   Estimated time **45 minutes**

Pre-requisite
-------------

To run the workshop some extra resources are needed on your laptop (besides Terminal or Putty for the SSH session) are needed.

.. note::

   You can also use the Windows Tool VM as it has Visual Code installed. You have to deploy it yourself as it is not being deployed by default. **Just make sure you update it before you install the extensions**. You can force the update by clicking **Help -> Check for Updates...**. If there is an update available the :fa:`gear` icon (bottom of the left pane) will shown a **1**. Click it and then click **Install update**. In the message that will apear, right bottom corner, Click **Restart** to update VC. That way you don't "mess up" your laptop.

The following resources are needed for the workshop:

- Visual Code (VC) (VC can be found in the Tools map on the desktop of the Windows Tools VM. If not installed on your laptop: https://code.visualstudio.com/download), please install the following extensions:

  - YAML (https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
  - GitLens (https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)
  - Git History (https://marketplace.visualstudio.com/items?itemName=donjayamanne.githistory)
  - Docker (https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
  - Kubernetes (https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)
  - Remote SSH (https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
  - Remote SSH: Editing Configuration Files (https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit)
  - Shell Syntax (https://marketplace.visualstudio.com/items?itemName=bmalehorn.shell-syntax)
  - Bracket Pair Colorizer 2 (https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer-2)

  To install the extensions use the extensions button (left hand pane, fourth icon from the top) in VC and use the Search Extensions field to find and install them.

  .. figure:: images/1.png

- Docker Hub account is needed for saving/uploading the images for the Fiesta application. Create an account using http://hub.docker.com.
- Blueprint of the Dev Environment to you are going to deploy. This saves you in building the environment. The blueprint can be download :download:`here <Docker MariaDB FiestaApp.json>`. If you also have Era deployed, you can also use :download:`this blueprint <Docker MariaDB FiestaApp - ERA.json>`. The last blueprint will also register the MariaDB in Era.

Prepare your environment
------------------------

For this workshop to be run, we need to prepare the environment. Follow the next steps to make your environment ready. They are in high level:

- Prepare Calm to have a Project
- Upload a Blueprint
- Configure the blueprint
- Deploy the blueprint

Create your project
^^^^^^^^^^^^^^^^^^^
Projects are the logical construct that integrate Calm with Nutanix' native Self-Service Portal (SSP) capabilities, allowing an administrator to assign both infrastructure resources and the roles/permissions of Active Directory users/groups to specific Blueprints and Applications. By using different projects assigned to different clusters and users, administrators can ensure that workloads are deployed the right way each time.  For example, a developer can be a Project Admin for a dev/test project, so they have full control to deploy to their development clusters or to a cloud, while having Read Only access to production projects, allowing them access to logs but no ability to alter production workloads.

Configure users, cluster and network to use
*******************************************

#. Open your assigned PRISM Central
#. Click the :fa:`bars` **->  Calm**
#. Within the Calm UI, Select |proj-icon| **Projects** from the sidebar.

   .. figure:: images/calm3/projects1.png

#. Click + Create Project

#. Fill out the following fields:

   - **Project Name** - *initials*-Calm
   - **Description** - *initials*-Calm

#. Under **Users, Groups, and Roles**, click **+ User**.

#. Fill out the following fields and click **Save**:

   - **Name** - SSP Admins
   - **Role** - Project Admin

#. Click **+ User**, fill out the following fields and click **Save**:

   - **Name** - SSP Developers
   - **Role** - Developer

#. Click **+ User**, fill out the following fields and click **Save**:

   - **Name** - SSP Consumers
   - **Role** - Consumer

#. Click **+ User**, fill out the following fields and click **Save**:

   - **Name** - SSP Operators
   - **Role** - Operator

   .. figure:: images/projects_name_users1.png

   .. note::

    Click `here <https://portal.nutanix.com/#/page/docs/details?targetId=Nutanix-Calm-Admin-Operations-Guide-v56:nuc-roles-responsibility-matrix-c.html>`_ to view the complete matrix of default SSP roles and associated permissions.

#. Under **Infrastructure**, click the blue **Select Provider** button, and then **Nutanix**.

#. In the box that appears, click the white **Select Clusters & Subnets** button, and in the pop-up, select your AHV cluster.  Once your cluster is selected, choose the **Primary** network, and if available, the **Secondary** network, and click **Confirm**.

   .. figure:: images/projects_cluster_subnet_selection1.png

#. Within the **Selected Subnets** table, select :fa:`star` for the **Primary** network to make it the default virtual network for VMs in the **Calm** project.

   .. figure:: images/projects_infrastructure1.png

#. Click **Save & Configure Environment**.
#. Wait a few minutes till the spinning wheel in the **Save & Configure Environment** button has stopped and you see your project appear when you click on the |proj-icon|

   .. note::
      If after 5 minutes you don't see your project show up, please refresh your browser.
------

Configure Environment
*********************

Now that we have set the users, their roles, which cluster and networks to use, we need to tell the project about the environment. In this part of the project we tell Calm the following per O/S.

1. VM Name using Calm macros
2. VM Resources (CPU, Cores per vCPU, Memory)
3. Guest customization (CloudInit or Sysprep)
4. Disks configuration
5. Boot configuration
6. vGPU use
7. Network adapters
8. Need of a serial port
9. Connection configuration including general credentials
    
.. note::
  These parameters are set as DEFAULT parameters. Meaning you can change them in the Blueprints you are going to create and deploy.

As we are mostly using the Linux O/S in this workshop we are just configuring these parameters.

#. When you dropped back to the Projects, click your created project to start the configuration
#. In the **Enviroment** part we're assigning the parameters needed for Calm to be able to deploy VMs

   .. figure:: images/calm3/environment.png

#. In the **VM Configuration** area, provide the VM Name as @@{initials}@@_VM

#. Provide the **vCPU, Cores per vCPU** and the **Memory (GiB)** fields with the value of **1**

#. Under **DISKS (1)** Select the *CentOS7.qcow2* under the Image field. Leave the other options in this area of the configuration.
   
   .. figure:: images/calm3/disk.png

#. Under **NETWORK ADAPTERS (NICS)(1)** Select your Cluster name and Primary as the network. Make sure you have the **Private IP** set as *Dynamic*.

   .. figure:: images/calm3/network.png

#. At the **CONNECTION** area, click on the Credential and select *Add New Credential*. As we are using in the Blueprints new setting, we still need to provide them to the Project. 

   .. figure:: images/calm3/credential.png

#. In the new screen use **centos** as the Credential Name, **root** as the user and **nutanix/4u** as the password. Click on **Done** if your are ready.

  
   .. figure:: images/calm3/credential-2.png

#. Click **Save** to save the project.

#. After a few seconds, the system saves the project and configure itself so it can use the configuration, you should see that the Exclamation mark behind Environment should not be shown as we had before (see step 1).
   
   .. figure:: images/calm3/environment-2.png

------

Build the test environment
^^^^^^^^^^^^^^^^^^^^^^^^^^

Follow these steps to deploy the blueprint.

Upload the Blueprint
********************

#. Click on the **Blueprint** (|bp_icon|) icon
#. Upload the downloaded blueprint
#. Rename the Bueprint to *initials* **-Docker MariaDB Fiesta**. If you have the Era version add **-Era** at the end of the name
#. Assign it to your project that you have created.
#. Click the **Upload** button. 

After the upload we have to configure the Blueprint so we can deploy it

Configure the blueprint
***********************

#. Open the uploaded Blueprint on clicking on its name
#. Click on the **Credentials** button to set the credentials

   .. figure:: images/3.png

#. Click on the **Edit** text
#. Provide the password **nutanix/4** as the password and click the **Save** button right hand top corner

   .. figure:: images/4.png

#. Click the **Back** button next to the **Save** button
#. Check the VMs configuation

   - Click on the **Docker_VM** in the Services pane (on the dark blue bakground)
   - Check the VM Name is **@@{initilas}@@-<NAME OF THE SERVICE>>** (Docker, MariaDB or Fiesta)

     .. figure:: images/5.png

   - **Disk (1)** - Clone from Imagse service and **CentOS_PHX_DFS**
   - **NIC 1** - **Primary** and **Dynamic** selected
   - **CONNECTION** - CentOS

#. Repeat for the other two VMs using their corresponding Service name as the VM's name
#. Click the **Save** button. If all went well the **Launch** button should become active

Deploy the blueprint
********************

#. Deploy your Blueprint and provide the needed Name:
   
   For the None Era version of the blueprint:

   - **Name of the Application** - *Initials*-Dev-Environment
   - **initials** - your initials

   For the the Era version also provide:

   - **era_ip** - <IP ADDRESS OF THE ERA INSTANCE>
   - **era_admin** - admin
   - **era_passwd** - <GIVEN PASSWORD>

     .. note::
       The below screenshot is from the Era version of he Blueprint. The not Era blueprint will only have the initials field.

     .. figure:: images/6.png

#. Click on the **Create** button
#. You can follow the installation process by clicking **Audit -> Create**
#. Wait untill the Application is running before moving forward. The deployment takes approximately 10-15 minutes

   .. note::

    The Fiesta App VM will be build last as it has a dependency on your MariaDB VM. You can see the dependency by clicking on **Manage -> Create** and click the :fa:`eye` **button**

    .. figure:: images/7.png

Checking the deployment
^^^^^^^^^^^^^^^^^^^^^^^

#. After the application is running, while still being in the Application you just deployed, click **Services** and note the IP addresses of the following VMs by clicking on them (IP addresses of the selected VM will shown at the right hand of the screen):

   - Docker VM
   - FiestaApp VM
   - MariaDB VM

   .. figure:: images/8.png

   .. note::

      The screenshot is from the MariaDB Server, make sure you selected the right service for its IP Address!

#. Open a browser and use the IP address of the FiestaApp VM and port 5001. That should open a webpage of the FiestaApp. Example: **\http://10.42.37.83:5001**
#. Then click on **Products**. This should show a webpage wih text and some pictures. If you see that, the deployment has been successful.

   .. figure:: images/9.png

#. Open a SSH session to the Docker VM using its IP Address you note earlier with **root** and **nutanix/4u** as the credentials
#. Run the **mount** command you should see a line that says: **\/dev\/sdb1 on \/docker-location type ext4 (rw,realtime,seclabel,stripe=256,data=ordered)**. This is the second disk we are using for Docker specific actions
#. Run the command **docker info** in the ssh session and look for

   - **Storage Driver** 
   - **Docker Root Dir**

   They should be according to the below screenshot (the red arrows)

   .. figure:: images/10.png

------

Description of the Blueprint
----------------------------

The blueprint you just deployed provides the following automated steps:

#. Deploy three CentOS VMs with your initials as their names
#. Update the CentOS with the latest packages
#. Install Docker in one of the VM where:

   - A second disk is attached and formated
   - Mounted to a directory
   - Used for docker actions, like build and store the build images

#. Deploy the MariaDB Database for storing the needed data by the Fiesta App
#. Register the MariaDB VM to Era (if the Era BP has been uploaded and deployed otherwise this step will not be run)
#. Fiesta Application that will create a dynamical webpage based on the data in the MariaDB database.




.. |proj-icon| image:: ../images/projects_icon.png
.. |bp_icon| image:: ../images/blueprints_icon.png
.. |mktmgr-icon| image:: ../images/marketplacemanager_icon.png
.. |mkt-icon| image:: ../images/marketplace_icon.png
.. |bp-icon| image:: ../images/blueprints_icon.png