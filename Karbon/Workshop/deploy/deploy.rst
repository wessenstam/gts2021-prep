.. _environment_deploy:

Fiesta Application 
==================

During the workshop we are at the stage where we are going to start deploying our application, Fiesta App, on the Kubernetes cluster. This module is explaining the following

- Deploy the Fiesta App and service for the App so we can communicate with the Application
- Configure Traefik for the "URL routing"
- Connect to the database

.. note::
   Estimated time **45 minutes**

   All screenshots have the **Downloads** folder of the logged in user as the location where we save files

Deploy the Fiesta App
---------------------

As you have noticed Kubernetes uses YAML file to deploy the different resources like pods, deployments, namespaces and services. As we haven't a YAML file already we need to build that for the Fiesta App.

#. Open Visual Cafe
#. Create a new file
#. Copy the below content and paste it in the file

   .. code-block:: yaml

      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: npm-fiesta
        namespace: default
      spec:
        selector:
          matchLabels:
            run: npm-fiesta
        replicas: 3
        template:
          metadata:
            labels:
              run: npm-fiesta
          spec:
            containers:
            - name: npm-fiesta
              image: wessenstam/npm_fiesta
              ports:
              - containerPort: 3000
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: npm-fiesta
        namespace: default
        labels:
          run: npm-fiesta
      spec:
        ports:
        - port: 3000
          protocol: TCP
        selector:
          run: npm-fiesta

#. Save the file as **fiesta_app.yaml**

Let's dissect the content high level.

The top part until the ``---`` icon is a deployment, so consider that the installation of the application (Pod). In the lower part after the ``---`` sign we see the service deployment. Service is how can we communicate with the Pod. The ``---`` is the resource separator for Kubernetes. So the split symbol between Deployment and Service in the above example. 

Explained Deployment
^^^^^^^^^^^^^^^^^^^^

In the deployment area there are some important parts.

- **kind**: Deployment, this tells Kubernetes what to expect for a resource perspective
- **namespace**: default, Namespaces can be used to separate logically Pod, Services or other resources. Consider namespace as a subnet in a network. All can still communicate with each other, but are logically separated
- **spec->selector->matchLabels->run**: Labels or tagging a Deployment. Using labeling we can tie resources together. We will see this in the Services part as well.
- **replicas**: how many pods should be started of the application.
- **image**: name of the image that needs to be used. Kubernetes will pull the images from the repo, in this case the hub.docker.com repo, from the user wessenstam and the name of the image is npm_fiesta
- **containerPort**: This is the port the container will use natively! This is important due to the fact that a wrong port definition will NOT allow any communication to the container.

Explained Service
^^^^^^^^^^^^^^^^^

In the Service part fo the YAML file we see also important parameters.

- **spec -> ports -> port**: the port definition for the service to start listening on port 3000 and the TCP protocol
- **spec -> selector -> run**: this is where we tie this service together with the deployment. This tells Kubernetes that the service must be tied to all resources that have the label **run: npm-fiesta**. Reason for using labels tieing resources together independent of the amount, as example pods, is that it is much easier then using it on name based or even IP based. Consider the labeling in the same context as the categories in Nutanix' solutions, like Flow or even grouping VMs together in categories

Deployment
^^^^^^^^^^

Now we have the basic YAML file ready, let's deploy the Pod.

#. Open your Terminal or Powershell session and run

   .. code-block:: bash

      kubectl apply -f fiesta_app.yaml

   .. figure:: images/1.png

#. As we have Lens running, let's use that dashboard to see what influence the YAML had on the Kubernetes environment (if you have skipped that part, follow this :ref:`link` )
#. Click on the Workloads -> Pods
#. Search for  **npm-fiesta**, based on the YAML file, there should be three (replicas)

   .. figure:: images/2.png

#. Open Visual Cafe and change in the fiesta_app.yaml and change the **replicas** number to 2
#. Save the file
#. In your terminal run **kubectl apply -f fiesta_app.yaml** and see the effect in Lens on the change.
#. Lens is showing a Terminating message under the status column of one of the npm-fiesta pods

   .. figure:: images/3.png

Check deployment
^^^^^^^^^^^^^^^^

Let's see if the application is running. To do that we are going to use Lens as that can also show pods that have not been published yet and only inside the kubernetes separated network.

#. Click on one of the npm-fiesta pods and scroll on the right hand side down till you see Ports

   .. figure:: images/4.png

#. Click on the text 3000/TCP. A new browser tab will open and shows you the Fiesta App. But if you click on the Stores, Products or Inventory icons click, not really useful information. e have forgotten to tell the Fiesta App where the database is located. At least the Application is running....

Now let's make sure we can access the application from outside the Kubernetes cluster before we fix the database issue.

Traefik configuration
---------------------

#. Open in Visual Code the earlier created **traefik-routes.yaml** file.
#. Copy all the content which already in the file. Wea re going to use that as a template to have another route for our Fiesta App
#. At the end of the file, on a new line at the beginning of the file, type ``---`` so we have a separator in the file. Again we are going to created a new section for another route the ``---`` symbol is that separator symbol
#. Past the content **BELOW** the ``---`` symbol on a new line
#. Your file should like the below screenshot

   .. figure:: images/5.png

#. In the lower part change the following fields:

   - **namespace:** portainer -> default
   - **Host:** portainer.gts2021.local -> fiesta.gts2021.local
   - **services -> name:** portainer -> npm-fiesta
   - **port:** 9000 -> 3000

   .. figure:: images/6.png

#. Save the file
#. Run the command ``kubectl apply -f traefik-routes.yaml``
#. Open the Traefik page again and click on the HTTP text at the top of the screen...
#. You should see the new route being mentioned and a green check mark in front of the rule.

   .. figure:: images/7.png

#. Now that the route is in Traefik, we need to tell our machine where to find the URL. Change the **hosts** file like we done before and add the line for the resolving of fiesta.gts2021.local to point to the EXTERNAL-IP address of Traefik and save the file.

   .. figure:: images/8.png

#. Back to the browser and type in ``http://fiesta.gts2021.local`` and the Fiesta App as we have seen using Lens should appear. Still the database is unknown to the app, but we see at least the page, so we know that the routing is working and can access the page from outside the Kubernetes cluster.

Connect to the database
-----------------------

As the application is running and accessible from our machine, we need to tell the application where the database is. o make that happen, follow these steps.

#. In your Prism Central go to the Calm page via :fa:`bars` **-> Services -> Calm**
#. in the Applications view, click on your **mariadb** application -> Services and the MariaDB icon.
#. Note the IP address which is mentioned on the right hand side of the screen

   .. figure:: images/9.png

#. In Visual Code, open the file **fiesta_app.yaml**
#. As the application needs environmental parameters, we are going to make changes to the YAML file. Use this URL for more background information (https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
#. In the containers section (in the Deployment section) add the following lines under image and use the same ident (**image** line is for reference!):

   .. code-block:: yaml

      image: wessenstam/npm_fiesta
      env:
        - name: DB_PASSWD
          value: fiesta
        - name: DB_USER
          value: fiesta
        - name: DB_SERVER
          value: <IP ADDRESS OF YOUR MARIADB SERVER>
        - name: DB_TYPE
          value: mysql

   .. figure:: images/10.png
      
#. Save the file and run the command ``kubectl apply -f fiesta_app.yaml`` from your terminal or Powershell session.
#. The command should show a configured text in the output of the command with respect to the deployment. This means that the change we made, the environmental variables, have been configured and executed.

   .. figure:: images/11.png

#. Now let's open the browser and refresh the page where we only had the app running, but no output in the Products etc. 
#. The page is showing the correct output as we expected using the environmental variables when we redeployed the Fiesta App Pods

   .. figure:: images/12.png


.. raw:: html

    <BR><center><h2>That concludes this module!</H2></center>


------

All is working! We have deployed our app into a Kubernetes, changed the URL routing and connected to the database. Next we need to figure out the day-2 stuff...

- Monitoring, not just using a Dashboard, but also having some more insights
- Logging
- Backup
- Expand the Kubernetes cluster
- Change the replicas AFTER we have expanded the cluster
- Upgrade the cluster

The rest of the workshop will focus on that....

Takeaways
---------

- Deploying an container based that uses environmental variables is relatively easy to do
- Changing the routing of URL into the application is just a few lines and traffic moves into the Kubernetes cluster without to difficult configuration changes
- Changes to YAML files and applying the using ``kubectl apply`` are seamlessly activated, not need to drop the "old" config and rerun the config. Kubernetes takes care of that.
- Using external application outside of Kubernetes can easily be configured. All depends on the "power" of the container being used and the underlying network. Nothing specific to Kubernetes

