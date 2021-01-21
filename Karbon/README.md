# Karbon workshop vGTS 2021

This workshop is to figure out how we can use Karbon to do the following (high level)

1. Deploy a MariaDB (using Era after registration of one)
2. Deploy Karbon (if not already done) in a dev setting (1 node for all needed components Master, Worker and etc.)
3. Deploy the needed other components:

    - Ingress Controller
    - Load balancer
    - Logging
    - Monitoring

4. Deploy an already created FiestaDB Container 
5. Deploy Backup solution
6. Upgrade the Kubernetes cluster
7. Expand the Kubernetes cluster with two worker nodes
8. Have more Replicas of the app and see what the impact is on monitoring

## Era

Using Era makes the life of DBAs easier, especially when developers are asking a lot of their time to clone/deploy databases for their applications.

- Register a MariaDB before hand so Era can deploy this. If not scriptable, have them do it by hand. -> Need BP to deploy MariaDB server and have data in the database
- Deploy a Database that will be used by the Fiesta app

## Deploy Karbon

- Best to have Karbon already deployed as it takes approx 20 minutes to have it operational

### Configure Karbon

- Get MetalLB installed and configured
- Install Traefik and configure it
- Monitoring possibilities

    - Kubernetes Dashboard
    - Lens as an application to monitor the Kubernetes cluster
    - Portainer as an application to monitor the Kubernetes cluster (Traefik change needed)

- Deploy logging using an ELK stack

## Next steps

- Deploy the application using environmental parameters (Traefik change needed)
- Deploy Objects
- Deploy a backup solution
- Expand the current cluster
- Upgrade the cluster native vs Nutanix' way (video)