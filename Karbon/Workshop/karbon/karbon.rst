.. _environment_karbon:

Kubernetes configuration 
========================

After we have created and configured the needed pre-requirements in the earlier module, we are now going to configure our deployed Kubernetes cluster so we can start using it. in this part of the workshop we cover the following items:

- Get the kubeconfig file so we can interact with the kubernetes cluster
- Install and configure MetalLB Load Balancer that mimics the Load Balancers like you would have with Google, Azure or AWS as example.
- Install and configure Traefik Ingress Controller
- Install and configure dashboards so we can visualize the kubernetes cluster

.. note::
   Estimated time **45 minutes**

   All screenshots have the **Downloads** folder of the logged in user as the location where we save files

Interact with your kubernetes cluster
-------------------------------------

Kubernetes uses by default a file for authentication and not username and password combinations. This file, called kubeconf.cfg, has be downloaded and stored local. As we will be using the command line a lot during this part of the workshop, we are going to set an environmental variable so if the command line is closed, we still are able to use the file.

Follow these steps to get to interact with your kubernetes cluster.

#. Open the Karbon UI in Prism Central via :fa:`bars` -> Services -> Karbon (if not already)
#. Select your kubernets cluster by clicking the check box in front of the name.
#. Click on the **Actions** button and select **Download Kubeconfig**

   .. figure:: images/1.png

#. Click on the Blue **Download** text
#. Save the file somewhere on your machine, but remember where you have saved it as we need it in the next steps

.. note:: 
    When you get an error message from your browser about it could harm your machine, please click the **Keep** button.

    .. figure:: images/2.png

#. For Windows, open the Environment (Right CLick on the "start" button -> System -> Advanced System Settings -> Environment Variables)

   .. figure:: images/3.png

   #. Click on the **Environmental Variables** button and then on the **New...** button under the **User variables** (top of the screen)
   #. Create a new variable and use the following parameters
   
      - **Variable Name** - KUBECONFIG
      - **Variable Value** - <Path of where you stored the file>/kubectl.cfg (screenshot below is the default Download location of the Administrator user)
   
        .. figure:: images/5.png
   
   #. Close all the windows, you have opened with respect to setting the **Environment Variable**

#. For Linux or MacOS use the export functionality after you have opened the terminal session

#. Open a terminal or powershell (on Windows only) and type

   .. code-block:: bash

      kubectl get nodes

#. You should see something like the below screenshot

   .. figure:: images/6.png

   .. note::
    If you don't then check the variable you just set by typing **dir env:** in PowerShell or **set** on Linux/MacOS machine and check the **KUBECONFIG** variable and check that is pointing to the kubectl.cfg file you downloaded earlier

    .. figure:: images/7.png


External Load Balancer
---------------------

Customers that use kubernetes from a cloud provider like Google, AWS and Azure will have the benefit of Load Balancers. On Premise installation could use the same or have the possibility to use other Hardware Load Balancers like F5, Palo-Alto, NGINX Plus, HAProxy or whatever is available.

.. note:: 
   As we are limited by docker pull rules, we have decided to use a "proxy" for the images that are being pulled by the Kubernetes servers. (https://www.docker.com/increase-rate-limits#:~:text=Anonymous%20and%20Free%20Docker%20Hub,%3A%20toomanyrequests%3A%20Too%20Many%20Requests.&text=You%20have%20reached%20your%20pull%20rate%20limit)
   That means that we need to make same changes to the YAML files we will be using. We need to change the location where the images are to be pulled from.

Installation
^^^^^^^^^^^^

As there is a small difference in the Windows and Linux/MacOS versions of wget and therefore the installation we show them separately

For Windows
************

#. In a Powershell interface, type the following commands to install MetalLB 

   .. code-block:: bash
     
     cd <LOCATION WHERE TO STORE FILES>
     wget https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml -OutFile namespace.yaml
     wget https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml -OutFile metallb.yaml

Now that we have the yaml files we need to manipulate them so we grab the images from the "proxy" account.

#. Open metallb.yaml file in Visual Code via File -> Open.. 
#. Change the following two lines:

   - On **Line 316** change *metallb/speaker:v0.9.5* into **wessenstam/metallb-contr:v0.9.5**
   - On **Line 372** change *metallb/controller:v0.9.5* into **wessenstam/metallb-spkr:v0.9.5**

#. Save the file
#. Run these two commands

   .. code-block:: bash

      kubectl apply -f namespace.yaml
      kubectl apply -f metallb.yaml

   .. figure:: images/9.png

   .. note:: 
        We are going to use Notepad to **construct** the needed command as it allows of basic manipulation of text. Powershell does not like the extra lines in variables.

#. Open Notepad
#. Copy the below command Notepad
      
   .. code-block:: bash
        
        kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="<TO BE COPIED OUTPUT>"

#. Back in Powershell, run
      
   .. code-block:: bash
      
      openssl rand -base64 128

#. Copy the output of the command in your Notepad in place of the text <TO BE COPIED OUTPUT> and remove the extra lines at the end of the copied key.
#. Copy the entire long line into the Powershell session and run the command
   
   .. figure:: images/8.png

For Linux/MacOS
****************

#. In a terminal session, type the following commands to install MetalLB 

   .. code-block:: bash
     
     cd <LOCATION WHERE TO STORE FILES>
     wget https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml -O
     wget https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml -O


#. Open metallb.yaml file in Visual Code via File -> Open.. 
#. Change the following two lines:

   - On **Line 316** change *metallb/speaker:v0.9.5* into **wessenstam/metallb-contr:v0.9.5**
   - On **Line 372** change *metallb/controller:v0.9.5* into **wessenstam/metallb-spkr:v0.9.5**

#. Save the file
#. Run these two commands

   .. code-block:: bash

      kubectl apply -f namespace.yaml
      kubectl apply -f metallb.yaml

#. When you are running MacOS or Linux use:

   .. code-block:: bash

     kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

For all systems
***************

Now that we have installed MetalLB we need to make sure that the Pod are in a running state. To do this open your terminal or Powershell sessions and type 

.. code-block:: bash

   kubectl get pods -n metallb-system

This should show that there are two Pods, one with in the name controller and one with in the name speaker and they should have the status Running

.. figure:: images/10.png

If you don't see this status,we have to investigate what is the issue at hand. We can do this simply by looking at the command 

.. code-block:: bash

   kubectl describe pods <name of the POD that has an issue> -n metallb-system

This will show detailed information on the pod, the statuses and errors. INvestigate the last part of the information to get a direction where to search. Mostly it has been that the name of the image has been typed wrong, or not changed at all..
   
.. figure:: images/11.png

Configuration
^^^^^^^^^^^^^

Now that we know are sure that we have the POds running we need to configure MetalLB. To do this we need to create a small yaml file that holds the IP range that we can use for MetalLB

.. raw:: html

   <font color="#FF0000"><strong> Make 100% sure you are using YOUR assinged IP addresses (4x)! Otherwise the other users on the cluster will suffice strange issues</strong></font>

Follow theses tes to get the configuration created for MetalLB

#. Open Visual Code
#. Create a New File and copy the below text

   .. code-block:: yaml
     
     apiVersion: v1
     kind: ConfigMap
     metadata:
       namespace: metallb-system
       name: config
     data:
       config: |
         address-pools:
         - name: metal-lb-ip-space
           protocol: layer2
           addresses:
           - <START IP RANGE>-<END IP RANGE>

#. Example could be

   .. code-block:: yaml
     
     apiVersion: v1
     kind: ConfigMap
     metadata:
       namespace: metallb-system
       name: config
     data:
       config: |
         address-pools:
         - name: metal-lb-ip-space
           protocol: layer2
           addresses:
           - 10.42.3.45-10.42.3.49

#. Save the file in your location of choice as **metallb-config.yaml**
#. Run this command to get the configuration activated

   .. code-block:: bash
     
     kubectl apply -f metallb-config.yaml

   .. figure:: images/12.png

Now that we have a LoadBalancer like the Pulbic Cloud providers let's start to use it. To do that we are going to install Traefik as a Ingress controller, but use a "public IP address" so we can access it from our machines without the need of an extra component.

Traefik
-------

Traefik (http://traefik.io) can be used to route inbound traffic, based on URLs, from machines to specific Pods. We are going to use Traefik in a later state of this module.

To do that we need to follow some steps. Installation, deploying and exposing the Traefik Pod using MetalLB.

Installation
^^^^^^^^^^^^

We need to provide Kubernetes specific RBAC rules so Traefik can see the new rules and be able to access the Pods we are going to have routed like our Fiesta Application. 

#. Run the following command in your Terminal or Powershell session

   .. code-block:: bash

      kubectl apply -f https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/Karbon/yaml%20files/01-traefik-CRD.yaml

      


