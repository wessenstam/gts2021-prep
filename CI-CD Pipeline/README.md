# Explanation of files

This repo is having the needed files for the following scenarios:

1. Refactor the Fiesta App into a container
2. Change the container to start faster
3. Build a CI/CD pipeline
4. Build, store and deploy the changed dockerfile using the CI/CD
5. Change the Deployment to be a karbon cluster

# Pre-requisits

1. Dockerhub account
2. Knowledge on docker and docker-compose
3. Knowledge on Linux in general

# File location

- mariadb

    This folder contains all the needed files to start building the refactoring for MariaDB environment

- mssql

    This folder contains all the needed files to start building the refactoring for MSSQL environment

- docker_files

    This folder holds all the needed files to build the CI/CD infrastructure using docker containers

## Refactor the Fiesta App

This first step is to show how to build a container using the command line. The following files need to be used:

1. dockerfile.mariadb
2. runapp_mariadb.sh
3. set_priveleges.sql

### Goal

Get an understanding of how to build a container from an existing application and the impact of refactoring on an organisation. This by using the command line, manual commands

## Change to container to start faster

Due to the long start, because of the npm stuff that needs to be run (from npom install to nom build), the build of a new container (image) makes the start way faster. The following files need to be used:

1. dockerfile.npm
2. runapp_npm_container.sh
3. set_privileges.sql

### Goal

Get an understanding what multi step creation of an image impacts, not just the time to start an app, but also the size.

## Build CI/CD Pipeline

Building a CI/CD Pipeline is being used by organisations to speed up the tedious tasks of building, testing, storing and deploying containers in Dev and Prod environments. The file to be used is the docker-compose.yml file. This docker-compose.yaml file builds:

1. A Database (MySQL) for the Gitea environment
2. Gitea itself (https://gitea.io)
3. Drone.io server (https://drone.io)
4. Drone.io Docker runner
5. Docker registry in http (https://docs.docker.com/registry/)
6. Docker Registry UI using Crane (https://hub.docker.com/r/parabuzzle/craneoperator)
7. Nginx server for HTTPS proxy for Docker Registry 

After the docker containers are running, some small changes need to be made to the "infrastructure" to get it running. 
1. For getting https access to the Docker registry :
   
    - https://phoenixnap.com/kb/set-up-a-private-docker-registry use `sudo yum install -y httpd-tools` to install the `htpasswd` command
    - https://www.rosehosting.com/blog/how-to-generate-a-self-signed-ssl-certificate-on-linux/ for SSL certs for NGINX

2. For Gitea to get https support, and not http (default)
    
    - https://docs.gitea.io/en-us/https-setup/

3. Docker on the VM where docker-compose.yml is to be "run"

    - https://docs.docker.com/registry/insecure/

4. Physical machine; as we use self signed certificates, git doesn't allow pull and paush to Gitea. To fix that, follow https://confluence.atlassian.com/fishkb/unable-to-clone-git-repository-due-to-self-signed-certificate-376838977.html

More deatiled information can be found here <docker_files/README.md>.

### Goal

Understand a possible CI/CD solution for an organisation. What is takes to build one and how to use it.

## Build, store and deploy the changed dockerfile using the CI/CD

This part is to show the CI/CD pipeline in action to clone, build, test, store (in the earlier created Docker Registry) and deploy the changed files for the container to the Docker VM which is also running the CI/CD pipeline.

### Goal

Undestand the value of the CI/CD pipeline for an organisation with respect to the speed of deveoping and deploying. 

## Change the Deployment to be a karbon cluster

This last pasrt is to get the created containers to be used with the k8s solution of choice.

### Goal

Making a small change will lead to deployment onto a k8s platform, but still everything is being used by the same push trigger.


## Extras - TO BE BUILT!!!

- Open ended question, make all of this for MS SQL and incorporate ERA for MS SQL? 

    - Provide the first steps
    - How do we value this???


# TO BE BUILT!!!

- Add a second disk of 30 GB and have it being used by the CI/CD pipeline ans well as Docker. Also include the overlay2 storage driver.
- Integration into Karbon or k8s cluster, so we need to build one.
- If on Green don't rebuild the Database, just use it.
- If on Blue, see if Dev Database exists, if not create database (clone)/if exists, use the existing database.

    - Use API calls, but do we use Cluster or Era API to see if database is there?
    - USE API calls to clone databse server if doesn't exist

- Use a loadbalancer (Nginx or HAProxy) to have a LB where we can use Blue (Dev/Test) and Green (Production) networks? Like `URL/dev` goes to the Blue and `URL` goes to Green.
    
    - Can we use the Clusters environment for Dev/Test and HPOC for Prod?
    - Can we use a branch in Gitea to make the difference?
    - Use Era clones of MariaDB when we are in Dev branch?

      - First research delivers:
      
        - We can trigger Drone to do steps based on branch
        - This URL where we can get the Variables needed, at least some of them: https://docs.drone.io/pipeline/environment/reference/
        - This URL for triggers: https://docs.drone.io/pipeline/triggers/
        - When merge (seen as push by Drone) we need to use the Prod environment. https://discourse.drone.io/t/whats-the-event-after-merging-a-pull-request/2733
        
