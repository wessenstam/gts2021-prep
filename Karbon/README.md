# Karbon workshop vGTS 2021

This workshop is to figure out how we can use Karbon to do the following (high level)

1. Deploy a MariaDB using Era after registration of one
2. Deploy Karbon (if not already done) in a dev setting (1 node for all needed components Master, Worker and etc.)
3. Deploy the needed other components:
    - Ingress Controller
    - Load balancer
    - Logging
    - Monitoring
4. Deploy an already created FiestaDB Container (maybe as optional from the CICD workshop)
5. Deploy Backup solution
6. Upgrade the Kubernetes cluster (compared to vide or text so people have a reference)
7. Expand the k8s cluster with two worker nodes
8. Have more Replicas of the app and see what the impact is on monitoring

## Deploy Karbon

- Best to have Karbon alrady deployed as it takes approx 20-30 minutes to have it operational

## Era

Using Era makes the life of DBAs easier, espscialy when developers are asking a lot of their time to clone/deploy databases for their applications.

- Register a MariaDB before hand so Era can deploy this. If not scriptable, have them do it by hand. -> Need BP to deploy MariaDB server and have data in the database
- Deploy a Database that will be used by the Fiest app
