.. _environment_day2:

Day2 operations 
===============

As we are now looking at the day-2 operations, we are going to focus on these items which are still open:

- Monitoring, not just using a Dashboard, but also having some more insights
- Logging
- Backup
- Expand the Kubernetes cluster
- Change the replicas AFTER we have expanded the cluster
- Upgrade the cluster

.. note::
   Estimated time **45 minutes**

   All screenshots have the **Downloads** folder of the logged in user as the location where we save files

Monitoring
----------

Monitoring is one of the most important parts in administrating a Kubernetes Cluster. Especially as the application are running in a network that can not be reached from the outside world.
We are going to build a monitoring system using Prometheus and Grafana for the visualization.


.. TODO:: 
   NEED TO RECREATE TO OWN PROMETHEUS installation

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

#.  Copy the below content in the file, this will deploy Grafana in the just created **monitoring** namespace

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

#. Using Lens we should now see Grafana being mentioned in the Workloads -> Pods section

   .. figure:: images/3.png

Traefik configuration
*********************

Now that Grafana is eployed, we need to tell Traefik to route traffic from a specific URL to the Grafana Service we created.

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
#. Switch to Lens and get the IP address of the Prometheus operator Pod as shown in Lens (Workloads -> Pods -> prometheus-operatord)

   .. figure:: images/8.png

#. Change the **Name** field to prometheus (lower case)
#. In the URL field type the IP address you have found. The port is 9090, so the URL, using the example screen shots, is http://172.20.1.11:9090
#. Click the **Save & Test** button. If all is correct, you should recieve a green bar above the button stating **Data source is working**

   .. figure:: images/9.png

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

To have a logical separation of the POds we are going to create a new namespace in which we will deploy the full new stack

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

#. This will create the Namespace **Serice and Deployment**

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
#. 

Backup
------



Expand the cluster
------------------



Change replicas
---------------


Upgrade the cluster
-------------------


