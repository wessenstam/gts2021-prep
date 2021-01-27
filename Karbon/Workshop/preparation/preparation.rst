.. _environment_setup:


Preparation
===========

To run this Karbon/Kubernetes related workshop we have to prepare some VMs and applications we are going to use.

.. note::
   Estimated time **45 minutes**

Pre-requisite
-------------

To run the workshop some extra resources are needed on your laptop (besides Terminal or Putty for the SSH session) are needed.

.. note::

   You can also use the Windows Tool VM as it has Visual Code installed. You have to deploy it yourself as it is not being deployed by default. **Just make sure you update it before you install the extensions**. You can force the update by clicking **Help -> Check for Updates...**. If there is an update available the :fa:`gear` icon (bottom of the left pane) will shown a **1**. Click it and then click **Install update**. In the message that will appear, right bottom corner, Click **Restart** to update VC. That way you don't "mess up" your laptop.

The following resources are needed for the workshop:

- Visual Code (VC) (VC can be found in the Tools map on the desktop of the Windows Tools VM. If not installed on your laptop: https://code.visualstudio.com/download), please install the following extensions:

  - YAML (https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
  - Bracket Pair Colorizer 2 (https://marketplace.visualstudio.com/items?itemName=CoenraadS.bracket-pair-colorizer-2)

  To install the extensions use the extensions button (left hand pane, fourth icon from the top) in VC and use the Search Extensions field to find and install them.

  .. figure:: images/1.png

- Install Openssl into your Windows deployment (Linux and Mac have it installed by default). Follow this article to install it to your Windows instance https://medium.com/swlh/installing-openssl-on-windows-10-and-updating-path-80992e26f6a1


Prepare your environment
------------------------

For this workshop to be run, we need to prepare the environment. Follow the next steps to make your environment ready. They are in high level:

- Enable Karbon (if not already done)
- Download the Karbon needed OS
- Deploy a Kubernetes Development cluster
- Deploy a MariaDB database for our application using a Blueprint

Enable Karbon
^^^^^^^^^^^^^

Follow these steps to enable Karbon

#. Open your Prism Central and click :fa:`bars` -> Services -> Karbon
#. If Karbon has not been enabled yet, click the Enable button. This will take a few seconds
#. To deploy a Kubernetes cluster we need to have an operating system ready. If you see the Download button, click this button to have the OS downloaded.
#. Click the **+Create Kubernetes Cluster** button to start creating a cluster
#. Select the Development Cluster as the Recommended Configuration, and click **Next**

   .. figure:: images/2.png

#. Provide a name for the Kubernetes cluster. Recommended *Initials*-karbon
#. Select your cluster in the **Nutanix CLuster** field. Leave the rest of the fields default.
#. Click **Next**
#. Select your Primary network in the **Network Resources** and leave the **Worker Resources** to 1. Click **Next**

    .. figure:: images/3.png

#. Under the Network Provider, click **Next**
#. In the **Storage Class** screen provide the following information:

   - **Nutanix Cluster** - your assigned cluster
   - **Cluster Username** - admin
   - **Cluster Password** - corresponding password
   - Leave the rest of the fields default

   .. figure:: images/4.png

#. Click on the **Create** button to have the system create the Development cluster. This process takes approx. 5-10 minutes. 

   .. figure:: images/5.png

Deploy the MariaDB Server
^^^^^^^^^^^^^^^^^^^^^^^^^

As we will deploy the Fiesta Application (a simple e-Commerce application) to our Kubernetes cluster, one part of the application is a MariaDB. This database will be deployed using a blueprint so it can be done easily.

#. Open Calm in your Prism Central interface via :fa:`bars` -> Services -> Calm
#. Download the needed blueprint that we're going to use to your machine. :download:`mariadb.json`
#. Upload the Blueprint By clicking on the Blueprint Icon and the **Upload Blueprint** button
#. Assign the Blueprint to your project. If your product is not allowing anything, make sure it has been configured. If not, please follow these settings:
   
   Configure users, cluster and network to use
   *******************************************
   
   #. Open your assigned PRISM Central
   #. Click the :fa:`bars` **-> Calm**
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
   
   #. In the box that appears, click the white **Select Clusters & Subnets** button, and in the pop-up, select your AHV cluster.  Once your cluster is selected,  choose the **Primary** network, and if available, the **Secondary** network, and click **Confirm**.
   
      .. figure:: images/projects_cluster_subnet_selection1.png
   
   #. Within the **Selected Subnets** table, select :fa:`star` for the **Primary** network to make it the default virtual network for VMs in the **Calm** project.
   
      .. figure:: images/projects_infrastructure1.png
   
   #. Click **Save & Configure Environment**.
   #. Wait a few minutes till the spinning wheel in the **Save & Configure Environment** button has stopped and you see your project appear when you click on the | proj-icon|
   
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
   
   #. At the **CONNECTION** area, click on the Credential and select *Add New Credential*. As we are using in the Blueprints new setting, we still need to provide       them to the Project. 
   
      .. figure:: images/calm3/credential.png
   
   #. In the new screen use **centos** as the Credential Name, **root** as the user and **nutanix/4u** as the password. Click on **Done** if your are ready.
   
     
      .. figure:: images/calm3/credential-2.png
   
   #. Click **Save** to save the project.
   
   #. After a few seconds, the system saves the project and configure itself so it can use the configuration, you should see that the Exclamation mark behind       Environment should not be shown as we had before (see step 1).
      
      .. figure:: images/calm3/environment-2.png

Configure the blueprint
***********************

After uploading the BP we need to configure the deployment.

#. Click the uploaded Blueprint in the Blueprints "overview" |bp_icon|
#. Click on the MariaDB_VM in the middle part of the screen
#. Click Credentials, and set the password to **nutanix/4u**
#. Click **Save** and the **Back** button to return back to the main part of the Blueprint
#. Click VM and make sure to check the following parameters:

   - **Disk**: Clone from Image Service - CentOS7 (or you can use the Download Configuration as mentioned in the blueprint)
   - **NETWORK ADAPTERS**: NIC 1 - Primary - Dynamic
   - **Credentials**: CentOS

#. Click the **Save** button and the **Launch**
#. Provide your initials and click the **Create** button to have the application deployment Started
#. You can follow the process by clicking in the application (which has opened) the **Audit** tab
#. The process will take about 5-10 minutes

.. raw:: html

    <BR><center><h2>That concludes this module!</H2></center>
    
-----

Now that the pre-requirements are ready, we can proceed.

.. |proj-icon| image:: ../images/projects_icon.png
.. |bp_icon| image:: ../images/blueprints_icon.png
.. |mktmgr-icon| image:: ../images/marketplacemanager_icon.png
.. |mkt-icon| image:: ../images/marketplace_icon.png
.. |bp-icon| image:: ../images/blueprints_icon.png