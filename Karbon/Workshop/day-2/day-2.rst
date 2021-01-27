.. _environment_day2:

Day2 operations 
===============

As we are now looking at the day-2 operations, we are going to focus on these items which are still open:

- Monitoring, not just using a Dashboard, but also having some more insights
- Logging
- Expand the Kubernetes cluster
- Change the replicas AFTER we have expanded the cluster
- Upgrade the cluster
- Backup

.. note::
   Estimated time **60 minutes**

   All screenshots have the **Downloads** folder of the logged in user as the location where we save files

Monitoring
----------

Monitoring is one of the most important parts in administrating a Kubernetes Cluster. Especially as the application are running in a network that can not be reached from the outside world.
We are going to build a monitoring system using Prometheus and Grafana for the visualization.


.. TODO: NEED TO RECREATE TO OWN PROMETHEUS installation

Prometheus
^^^^^^^^^^

For Prometheus (http://www.prometheus.io) we are already done. Reason is that Karbon by default has Prometheus installed. 

#. In your Dashboard of choice, we are going to use Lens, open the **Worklodas -> Pods** there you will see prometheus being mentioned.

   .. figure:: images/1.png

Grafana
^^^^^^^

Grafana (http://www.grafana.com)is a open source application that can vizualize multiple sources. Prometheus being one of them. This part of the workshop is where we will:

- Deploy Grafana
- Use Traefik to open the Grafana UI to the external world
- Configure Grafana to use the Prometheus built-in deployment
- Import some dashboard that are available in the Grafana dashboard "marketplace"

Deployment
**********

#. In Visual Cafe create a new YAML file called **grafana-deploy.yaml**
#. Run the following command to create the Namespace monitoring in which we will deploy Grafana ``kubectl create ns monitoring``

   .. figure:: images/2.png

#. Copy the below content in the file, this will deploy Grafana in the just created **monitoring** namespace

   .. code-block:: yaml

        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: grafana
          namespace: monitoring
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: grafana
          template:
            metadata:
              name: grafana
              labels:
                app: grafana
            spec:
              containers:
              - name: grafana
                image: grafana/grafana:latest
                ports:
                - name: grafana
                  containerPort: 3000
                resources:
                  limits:
                    memory: "2Gi"
                    cpu: "1000m"
                  requests: 
                    memory: "1Gi"
                    cpu: "500m"
                volumeMounts:
                  - mountPath: /var/lib/grafana
                    name: grafana-storage
                  - mountPath: /etc/grafana/provisioning/datasources
                    name: grafana-datasources
                    readOnly: false
              volumes:
                - name: grafana-storage
                  emptyDir: {}
                - name: grafana-datasources
                  configMap:
                      defaultMode: 420
                      name: grafana-datasources

#. Save the file
#. Create a new file in Visual Cafe called **grafana-svc.yaml** for the service for Grafana and copy the below content in the file
    
    .. code-block:: yaml
        
        apiVersion: v1
        kind: Service
        metadata:
          name: grafana
          namespace: monitoring
          annotations:
              prometheus.io/scrape: 'true'
              prometheus.io/port:   '3000'
        spec:
          selector: 
            app: grafana
          ports:
            - port: 3000

#. Save the file
#. Use the following commands to deploy and configure Grafana

   .. code-block:: bash

        kubectl apply -f grafana-deploy.yaml
        kubectl apply -f grafana-svc.yaml

#. Using Lens we should now see Grafana being mentioned in the **Workloads -> Pods** section

   .. figure:: images/3.png


Traefik configuration
*********************

Now that Grafana is deployed, we need to tell Traefik to route traffic from a specific URL to the Grafana Service we created.

#. Open the file **traefik-routes.yaml** in Visual Code and add the following content to the end of the file:

   .. code-block:: yaml
      
       ---
       apiVersion: traefik.containo.us/v1alpha1
       kind: IngressRoute
       metadata:
         name: simpleingressroute
         namespace: monitoring
       spec:
         entryPoints:
           - web
         routes:
         - match: Host(`grafana.gts2021.local`)
           kind: Rule
           services:
           - name: grafana
             port: 3000

#. Save the file and run ``kubectl apply -f traefik-routes.yaml`` to have Traefik being configured with the new route.
#. Open the Traefik Dashboard -> HTTP and there should now be the route mentioned

   .. figure:: images/4.png

#. Make the needed changes to the **hosts** file so we can open the URL in the browser

   .. figure:: images/5.png

Datasource configuration
************************

#. Open a browser and point it ot the just created URL http://grafana.gts2021.local. Your Grafana interface should be shown with a login page

   .. figure:: images/6.png

#. Use the combination **admin and admin** for the login and choose a new password in the screen that follows.

   .. note::
     You might get a popup p save the password, click on your preference. The workshop has no dependency on it.

#. In the Grafana UI, click the :fa:`cog` Icon on the left hand side and click **Data Sources**

   .. figure:: images/7.png

#. Click the **Add data source** button to add the built-in Prometheus deployment
#. Select Prometheus in the next screen by clicking the **Select** button
#. Switch to Lens and get the IP address of the Prometheus operator Pod as shown in Lens (**Workloads -> Pods -> prometheus-operatord**)

   .. figure:: images/8.png

#. In the URL field type the IP address you have found. The port is 9090, so the URL, using the example screen shots, is http://172.20.1.11:9090
#. Click the **Save & Test** button. If all is correct, you should recieve a green bar above the button stating **Data source is working**

   .. figure:: images/9.png

.. TODO: Check this process why we can't use the internal DNS **prometheus-operatord.svc.monitoring.cluster.local**

Dashboard
*********

Let's see if everything is working by creating a simple chart. We are going to create a chart that shows the cluster's CPU load average over 5 minutes.

**Build your own dashboard**

#. In Grafana hoover over the Dashboards icon (third from the top on the left hand navigation bar)
#. Select manage
#. Click **New Dashboard**
#. Click the **+ Add new panel** button
#. Select the field right to Metrics (half way the screen in the middle)
#. Start typing **cpu** as soon as you start typing, data should be seen. 

   .. figure:: images/10.png
   
   .. note::
       If not, that means that the Prometheus server can not be reached. All the data points come from that infrastructure. One way to solve this is to wait a few minutes as it takes some time for Grafana to pull data from the data sources that have been defined.

#. Select the line that shows **cluster:node_cpu:sum_rate5m** and click on another field. That way Grafana will pull the data and start displaying the chart.

   .. figure:: images/11.png

#. As this is working, click the **Discard**  button in the right top corner
#. Hoover over the Dashbard icon again and select **Manage**, in the error screen click **Discard**.

**Import dashboard**

We are going to import some dashboard that are already pre-built for people.

#. CLick the **Import** button
#. In the **Import via Grafana.com** type the number **1621** and click the **Load** button
#. Under the Prometheus, select your prometheus _environment and click **Import*
#. It will immediately pull data and start showing graphs..

   .. figure:: images/12.png

#. Other dashboards can be found using the Grafana webpage at https://www.grafana.com/grafana/dashboards. Search for your dashboard of choice and click on it. On the right hand side of the screen you see the ID that we just used. Follow the same process as we have just now done and import your choice. The one we used is just an example....


Logging
-------

Logging is very important to see what are possible reasons for rising issue. Logging can be done using the Kubernetes Dashboard, Portainer or the Lens application. Downside of this is that it doesn't show a full logging experience where you can drill down into the logs themselves or even search.
To help in this area, Karbon already has an ELK (Elastic Search, Logfile and Kibana environment installed). This logging platform provides information for the Kubernetes installation only. 

As we need to see the logs from our pods, at the current release of Karbon, we have to build our own logging Stack. This part of the Module will show you how to use the internal only logging stack and how to install, configure and use another Stack that can be used for the user pods like our MetalLB, Traefik, Fiesta, Grafana and Prometheus Pods.

Built-in logging environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Open Karbon via **Prism Central ->** :fa:`bars` **-> Services -> Karbon**
#. Click on your cluster
#. Click on **Add on -> Logging** (to the right)
#. Accept the certification issue
#. Kibana interface will Open
#. Click **Explore on my Own**
#. Click the :fa:`cog` Management icon on the bottom left side
#. Click on **Index Patterns** in the Kibana section
#. In the Index pattern field type *****
#. Click on the **> Next step** button
#. In the **Time Filter field name** select the **@timestamp**
#. CLick the **Create index pattern** button
#. When ready, click on the **Discover** text to the left of the screen in the navigation bar
#. If all went ok, you should see now a vertical bar chart and the logs below in a chronological order.

   .. figure:: images/13.png

User space logging environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This part is all about creating our own Logging Stack.

We are going to do the following:

- Create a namespace for the logging
- Create Elasticsearch environment
- Create Kibana environment
- Create Fluentd environment
- Configure Traefik to alow access to the Kibana Pod

Namespace
*********

To have a logical separation of the Pods we are going to create a new namespace in which we will deploy the full new stack

#. In the terminal or Powershell session run the following command

   .. code-block:: yaml

        kubectl apply -f https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/Karbon/yaml%20files/EFK%20session/kube-logging-ns.yaml

#. This will create the Namespace **kube-logging**

   .. figure:: images/14.png

Elacsticsearch environment
**************************

To get this working we need to install a service and the deployment of the Elasticsearch environment

#. Run the following commands to get the Elasticsearch environment ready

   .. code-block:: yaml

        kubectl apply -f https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/Karbon/yaml%20files/EFK%20session/elasticsearch_svc.yaml
        kubectl apply -f https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/Karbon/yaml%20files/EFK%20session/elasticsearch_statefulset.yaml

#. This will create the Namespace **Service and Deployment**

   .. figure:: images/15.png

Kibana environment
******************

To get this working we need to install a service and the deployment of the Kibana environment

#. Run the following commands to get the Kibana environment ready

   .. code-block:: yaml

        kubectl apply -f https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/Karbon/yaml%20files/EFK%20session/kibana.yaml

#. This will create the Namespace **Service and Deployment**

   .. figure:: images/16.png


Fluentd environment
*******************

To get this working we need to install a RBAC, Service account and the Daemonset (pods that are running on all Nodes of the Cluster) of the Fluentd environment

#. Run the following commands to get the Fluentd environment ready

   .. code-block:: yaml

        kubectl apply -f https://raw.githubusercontent.com/wessenstam/gts2021-prep/main/Karbon/yaml%20files/EFK%20session/fluentd.yaml

#. This will create the Namespace **Service and Deployment**

   .. figure:: images/17.png

Total overview
**************

#. To get a full overview of the Pods, in Lens change the *Namespace:* to **kube-logging**

   .. figure:: images/18.png

#. Now only the pods that are part of that namespace. All should have the **Running** status

   .. figure:: images/19.png

#. When clicking the Network -> Services you would also see the services for the same Namespace

   .. figure:: images/20.png

Now that we have the EFK logging environment ready, let tell Traefik to route http://kibana.gts2021.local to the Kibana interface so we can administer the logging externally from the Kubernetes cluster.

Traefik configuration
*********************

#. Open the traefik-routes.yaml file and add the following to the end  of the file

   .. code-block:: yaml

        ---
        apiVersion: traefik.containo.us/v1alpha1
        kind: IngressRoute
        metadata:
          name: simpleingressroute
          namespace: kube-logging
        spec:
          entryPoints:
            - web
          routes:
          - match: Host(`kibana.gts2021.local`)
            kind: Rule
            services:
            - name: kibana
              port: 5601

#. Save the file
#. Make the changes to the **hosts** file so kibana.gts2021.local points to the External IP address of Traefik
#. Use ``kubectl apply -f traefik-routes.yaml`` to tell Traefik to start routing the URL to the Kibana service
#. Open the Traefik page to see that the route has been aded and is green

   .. figure:: images/21.png

#. Open a browser and point it to http://kibana.gts2021.local/ . The Kibana page will open

   .. figure:: images/22.png

#. Click the **Explore on my own** button to proceed
#. Click the **No** button at the top of the screen
#. Click on **Index Patterns** under the *Kibana* section
#. In the **Index pattern** field, type **logstash\*** and click the **> Next step** button

   .. figure:: images/23.png

#. In the **Time Filter field name** select **@timestamp** and click the **Create index pattern** button

   .. figure:: images/24.png

#. After a few seconds, when you see the total overview of all possible fields, click on the Discover (compass :fa:`compass`) icon on the left hand side of the screen
#. This should show you all the logs from the system as well as our deployed pods (traefik, fiesta). 
#. In the Filters field, type ``kubernetes.pod_name : traefik*`` and hit the enter key to filter just on that. Now you would see all logs lines that have the line **kubernetes.pod_name : traefik\*** in them

   .. figure:: images/25.png

#. There is much more you can do with Kibana, but that is outside of this workshop.


Expand the cluster
------------------

Over time a Kubernetes may need to be expanded due to the workloads that are going to be landing on the Kubernetes cluster. Expanding an existing cluster, can be easy or difficult based on the way the cluster has been created. With Karbon, this si nothing more than clicking a few buttons.

#. Open the Karbon interface via **Prism Central ->** :fa:`bars` **-> Services -> Karbon**
#. Click on your cluster
#. In the navigation pane, click on Nodes -> Worker
#. Click the **+ Add worker** button to start the adding of two workers.

   .. note::
      As we have deployed a Develop environment, we can not expand the etcd or the Master nodes. On a production version we would be able to also expand those two type of nodes.

#. Change the field **Number of Nodes** to 2 and click the **Create** button to have your cluster being extended with two worker nodes.

   .. figure:: images/26.png
   .. figure:: images/27.png

#. Wait till the two nodes are installed before proceeding (approx. 15-20 minutes)

   .. figure:: images/28.png
   .. figure:: images/29.png

#. In Lens, we now see the two new nodes also appear.

   .. figure:: images/30.png

Your Kubernetes Cluster is now a 5 nodes cluster by just clicking a few buttons.

Change replicas
---------------

Now that we have 3 workers, let's change the deployment of our application to start using all three worker nodes.

#. Open your fiesta_app.yaml in Visual Code
#. Change the number after **replicas:** to 3
#. Run ``kubectl apply -f fiesta_app.yaml`` to get the new configuration activated in the cluster.
#. In Lens goto **Workloads -> Deployments** you should see now three Pods requested and after a few seconds should see below screenshot.

   .. figure:: images/31.png

So scaling an application is a very simple step after you have expanded your cluster.

Upgrade the cluster
-------------------

Upgrading a Kubernetes cluster is for now the O/S of the nodes. Upgrading the Kubernetes Version is on the roadmap. For now it has to be done using normal API/CLI commands.
A video on upgrading the O/S of the nodes can be found here:

The video can be found here. https://www.youtube.com/watch?v=IucbVL8lECk

Backup
------

Backup is one of the most important processes for organizations. Is it not just arranged by internal policies, the process can be mandated by regulations in the country where the organization is located. This part of the workshop is using one of the backup solutions for Kubernetes. We are going to implement K10 and use Nutanix Objects as the target for the backups

High level we are going to do the following steps:

- Install an Object Store, if not already available
- Create a Bucket for K10 called *initials* **-stash**
- Deploy and configure K10 backup (http://www.kasten.io)
- Config Traefik to publish the UI of K10
- Run a backup in K10
- Restore the Fiesta App as a clone

Nutanix Objects
^^^^^^^^^^^^^^^

As we want to use Nutanix Objects for the backup, we need to make sure there is a object-store in the environment.

Install an Object store
***********************

#. In your Prism Central click :fa:`bars` **-> Services -> Objects** and see if there is already an Object Store defined. If it is, skip to the next part, **Create a bucket**. If not follow these below steps

   #. If it doesn't exists use the following parameters (after you have clicked on the **Create Object Store** button -> Continue):
      
      #. **Object store name**: nutanix
      #. **Domain**: ntnxlab.local (click **Next**)
      #. **Performance** and **Resources**: leave default
      #. **Capacity**: 1 TiB (click **Next**)
      #. **Cluster Details**: your cluster
      #. **Objects Infra Network**: your IP subnet of the primary network and then the .18 and .19, example 10.42.3.18,10.42.3.19
      #. **Objects Public Network**: your IP subnet of the primary network and then the .20 till .23, example 10.42.3.20-10.42.3.23 (click **Create**)

   #. The Object store is being created. The process takes approx. 10-20 minutes

Setting access to the Object Store
**********************************

As we need to provide access to the objects store and to be created buckets, access needs to be granted to people or services/applications.

#. In your Objects UI, click on the top of the screen the **Access Keys** text
#. Click the **Add People** Button
#. In the new screen, as we have not defined a user in the AD that we want to use, click the *Add people not in a directory service*
#. Provide the following parameters:

   - Email Address: *initials*-**k10-backup@gts2021.local**
   - Name (Optional): *initials*- XYZ K10 Backup

   .. figure:: images/32.png

#. Click the **Next** button
#. Click the **Generate Keys** button
#. Make sure you click the **Download Keys** BEFORE you click the close button. Otherwise the keys can not be re-downloaded!

Create a bucket
***************

The Object store is build, let's create a bucket and get some credentials we need for K10 to be able to write to the bucket.

#. In Objects, select the available object store (example. nutanix)
#. Click on the name of the object store and click the **Create Bucket** button
#. Provided the name *initials*-**k10-bucket**, leave all other fields default
#. Click the **Create** button to have the bucket created

Assign access right to the bucket
*********************************

#. Click on the bucket you just created and select the **User Access**
#. In the **People** field start typing your earlier created user. Select the user by clicking the checkbox in front on the user

   .. figure:: images/33.png

#. In the **Permissions**, select Read AND Write and click the **Save** button
#. Your created "user account" should be shown


Add the bucket to the DNS
*************************

As the bucket can only be addressed by a URL we need to make sure that we have added the name to the DNS server that we have in our environment.

#. Open the DNS tool on your Windows Tools VM via **Desktop -> Tools -> Administrative Tools -> DNS**

   .. figure:: images/34.png

#. In the Message box **Connect to DNS Server** type **DC**
#. Your DC will open in the DNS, Expand till you see the content of ntnxlab.local
#. Check to see if the DNS name ntnxlab.local has a subdomain with the same name as the Object Store. 

   .. note::
      As the cluster is a shared resource, someone else has created the domain already for you.

#. If this is not the case, create it using the below steps

   #. Right click on the ntnxlab.local domain name
   #. Click **New Domain**

      .. figure:: images/35.png

   #. Type the name of the object store you have in your Prism Central (examples are using nutanix-demo)
   #. Click the **OK** button to get the new domain created

#. Right click the Domain ntnxlab.local and select  **New Host (A or AAAA)**...
#. For the name type **<NAME OF THE OBJECT STORE>** (example nutanix-demo)
#. For the IP address, use one of the public IP addresses of the Object Store you see in the Object Store interface in PRISM Central.

   .. figure:: images/36.png

#. Click **Add Host -> OK -> Done** 
#. Select the subdomain of ntnxlab.local, you should see the just recreated A records in the form off **(same as parent folder)**
#. Right Click the subdomain and select **New Host (A or AAAA)**...
#. For the name, use the name of the bucket you just created for K10 Backup (Example. xyz-k10-bucket)
#. In the IP address type one of the Public IP addresses of the Object Store
#. Click the **Add Host** button and then the **OK -> DONE** buttons to close the windows

   .. figure:: images/37.png


Update the Kubernetes DNS Services
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

As we also need to have the kubernetes environment updated for the DNS entries we just made, we need to tell the DNS service in the Kubernetes Cluster where the ntnxlab.local and <OBJECT STORE NAME>>.nutanix.local DNS servers/entries can be found. To do this follow these simple steps:

#. In your terminal or Powershell session type ``kubectl -n kube-system edit configmap coredns`` this will open on Windows Notepad.
#. Add the following before **kind:ConfigMap**

   .. code-block:: bash

     ntnxlab.local:53 {
         errors
         cache 30
         forward . <AUTO AD Server>
     }

   .. note:: 
      Make sure you change the **<AUTO AD Server>** BEFORE you save and close the editor!!! Otherwise you end up in a strange situation!!
      In the following screenshots we have used **nutanix-demo** as the name of the Object Store and **10.42.3.41** as the IP addresses of AutoAD

#. Run ``kubectl -n kube-system describe configmap corredns`` to see that the information is correct

   .. figure:: images/40.png

#. This should tell the DNS service in Kubernetes to forward the DNS requests for domains **ntnxlab.local** and sub domains to **10.42.3.41**

We are now ready to have the Bucket and Object Store to be used by applications that need to have access.

- Object Store available
- Bucket created
- Security Access key and secret are available
- Buckets can be addressed by a FQDN


K10 backup
^^^^^^^^^^

We are going to run a few steps to get K10 installed:

- Get helm installed in our system as the installation of the backup application uses helm to install the application. More information can be found at https://helm.sh/
- Install K10
- Define the URL route in Traefik
- Add our created Object Store as S3 storage for K10
- Run a backup, export to S3 storage
- Restore as a "clone"


Install helm on your machine
****************************

Helm is another way of deploying applications.
#. Open in a browser https://github.com/helm/helm/releases and select your helm version for your operating system
#. Extract the downloaded file and make sure your can execute it (Linux and MacOS)
#. Run **helm** from the Powershell or a terminal session, to make sure you can run the command

K10 installation
******************

#. In your terminal or Powershell, run the following command to create the logical separator for K10:

   .. code-block:: bash

      kubectl create namespace kasten-io

#. In your terminal or Powershell, run the following commands:

   .. code-block:: bash

      helm repo add helm repo add kasten https://charts.kasten.io/
      helm repo update
      helm install k10 kasten/k10 --namespace=kasten-io

   .. figure:: images/38.png

#. Run the following two commands to see if all has been installed

   .. code-block:: bash

      kubectl get pods --namespace kasten-io

#. Wait until all pods are in the running state (approx. 5 minutes). To have an auto update of the commend. add --watch so you keep updated on any changes that happen on the status of the pods.
#. In Lens you can also track the status of the pods. 

#. If the all pods are in the running state use the following temporary command in your terminal or Powershell session to see if we can get to the Dashboard of K10 kasten
   
   .. code-block:: bash

      kubectl --namespace kasten-io port-forward service/gateway 8080:8000

#. Open a browser and point it to http://127.0.0.1:8080/k10/#/ this should provide you access to the dashboard. Have a quick look around and then close the browser.
#. In your terminal/Powershell session hit <CTRL>+C to stop the proxy process. 

Define Traefik for routing
**************************

Let's make this a more convenient solution by using Traefik. 

#. Open the treafik-routes.yaml in Visual Cafe
#. Add the following content to the end of the yaml file

   .. code-block:: yaml
      
      ---
      apiVersion: traefik.containo.us/v1alpha1
      kind: IngressRoute
      metadata:
        name: simpleingressroute
        namespace: kasten-io
      spec:
        entryPoints:
          - web
        routes:
        - match: Host(`k10.gts2021.local`)
          kind: Rule
          services:
          - name: gateway
            port: 8000

#. Save the file
#. Run ``kubectl apply -f traefik-routes.yaml`` to have the new routing rules activated.

   .. figure:: images/39.png

K10 - Configure S3 storage
**************************

#. Make the needed change to the hosts file of your machine so you can target the host **k10.gts2021.local** as resolving to the K10 Dashboard.
#. Open a browser and type the URL **k10.gts2021.local/k10/#/** this should open the K10 dashboard
#. Provide some information in the first screen you get.

#. Now you should see the "default" dashboard of K10

   .. figure:: images/41.png

#. Click on **Cluster Settings** on the right hand side of the Screen
#. In the **Location Profiles** click the ** + New Profile** button
#. Fill the fields with the following values:

   - **Profile Name**: nutanix-objects (only lower cases are allowed)
   - **Cloud Storage Provider**: S3 Compatible
   - **S3 Access Key**: from the file that you downloaded during the Access Rights in the Nutanix Objects part.
   - **S3 Secret**: from the file that you downloaded during the Access Rights in the Nutanix Objects part.
   - **Endpoint**: https://<OBJECT STORE NAME>.ntnxlab.local
   - **Skip certification...**: Checked, click then the Disable SSL Verify button
   - **REgion**: Leave empty if you want
   - **Bucket Name**: <NAME OF THE BUCKET YOU HAVE CREATED>

     .. figure:: images/42.png

     .. note:: 
        The File of the secret has been slightly changed so we see the information in one screen with the settings we have set. For the Endpoint and the Bucket we have used our example information we used earlier.

#. Click the **Save Profile** button. This should result in a green bar at the top of the screen and the just defined profile should be shown.

   .. figure:: images/43.png

#. Click on the K10 Logo in the top left corner of your screen to return to the Dashboard.

K10 - Configure backup policy
*****************************

#. Click in the **Applications** box, **unmanaged**
#. In the **default** box (default namespace), click the **Create Policy** button

   .. figure:: images/44.png

#. On the right side of the screen, you see the new policy with default settings. 
#. Leave all default Except the **Enable Backups via Snapshot Exports** and check that your created Location Profile (nutanix-demo) is shown

   .. figure:: images/45.png

#. Click the **Create Policy** button so we have a policy
#. Now to run the Policy, click the **run once** button (running man icon)
#. Click **Run Policy** to have the policy run immediate.
#. In the Dashboard a few seconds after the policy has been in a running state, it will start to export the data to the S3 bucket we created.

   .. figure:: images/46.png

K10 - Restore data
*******************

Now that we have a backup and an export, let's restore some data in the form of "clone" the Pods we just backup-ed... The clone will be a separate name space.

#. Click on the Application box
#. Click on the **restore** text in the bottom area of the box called default.

   .. figure:: images/47.png

#. Click the first icon (from the right). That is your first manually started backup.
#. Click the **EXPORTED** box as we want the restore to be made from our Nutanix Objects S3 storage
#. In the **Application Name**, click the **Create na New Namespace** text and call it **default-restore**
#. Click the **Create** button. This will set the **Application name** to the just created **default-restore**
#. Scroll down to the Artifacts and select the **Deselect All Artifacts** text
#. Only select (by clicking on the Checkbox) 

   #. Type **deployment** that has the name **npm-fiesta** in the Name field
   #. Type **services** that has the name **npm-fiesta** in the Name field

   .. figure:: images/48.png

#. Click the **Restore** button to start the restore process.
#. Click **Restore** again in the message that appears
#. Go back to your Dashboard, by clicking the text Dashboard at the top of your screen. You should see a Blue bar appear and rising. Also under the Actions you will see the Restore action taking place.

   .. figure:: images/49.png

#. Open up your Lens installation and look to see for:

   #. A new name space: default-restore
   #. In that name space: the Pod npm-fiesta in a running state.

   .. figure:: images/50.png
   .. figure:: images/50a.png

.. note:: 
   To use the "restored" Fiesta app, you can use the Traefik and change the original route to point to the restored svc, OR create a new route, like fiesta_restore. The only thing that you need to change is the parameter namespace in the traefik-routes.yaml file.
   Apply the file using ``kubectl apply -f traefik.yaml`` and you have the restore app available for testing etc.

Impact on the objects store
***************************

#. Open your bucket in Nutanix Objects via **Prism Central ->** :fa:`bars` **-> Services -> Objects -> Your Object store -> Your bucket**
#. Click on the Performance on the right hand side and you should see the "load" the backup has had on your bucket.

   .. figure:: images/51.png

.. raw:: html

    <BR><center><h2>That concludes this module!</H2></center>

------

All is working! We have deployed the following items in this part of the lab

- Monitoring, not just using a Dashboard, but also having some more insights
- Logging
- Expand the Kubernetes cluster
- Change the replicas AFTER we have expanded the cluster
- Upgrade the cluster (video)
- Defined a Nutanix Objects Bucket
- Made changes to the built-in DNS in Kubernetes
- Install K10 backup solution using Helm, and not YAML files
- Configured backup policies and ran a manual triggered backup
- Restored an application to a new namespace


Takeaways
---------

- Monitoring and logging are crucial as it is the only way to get an overview if there are issues in an environment which consists out of small spinning wheels and the possibility of loosing the overview is at hand.
- Expanding and upgrading the nodes in the cluster has to be just some small clicks. Organizations don;t want to much time in expanding their infrastructure as manual labor could lead to inconsistency and failure
- Using Objects in any backup scenario is a great value add. The Objects store is build in and can be used quickly by just a few mouse clicks.
- The used backup solution, K10 from Kasten.io, is just an example of many backup solutions out in the market, but backups are important. Things will happen. People make mistakes and they can have a very big impact on the organization. Think of the following: running the command ``kubectl delete ns default-restore`` would literally delete ALL items in that name space! If you want to rebuild everything from hand, can be done, but is taken a lot of effort as not all steps that have been run AFTER the initial deployment might be documented. Kubernetes is capable of keeping pods alive and accessible via services, but a small mistake, even typo could lead to disaster.... 







