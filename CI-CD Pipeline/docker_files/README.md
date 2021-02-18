# Explanation

The docker-compose.yaml file builds:

1. A Database (MySQL) for the Gitea environment
2. Gitea itself (https://gitea.io)
3. Drone.io server (https://drone.io)
4. Drone.io Docker runner

## Requirements

The following needs to be installed on the machine to run the environment:
1. Installation of docker
2. Installation of docker-compose

## Extra installation steps

This part describes what needs to be done after the containers are running

### Extra volumes for the containers
The containers are using external volumes. The root is under `/gitea` and the containers are using paths under `/gitea` to store applicaiton data so at restart of the container the data, configuration and other needed files are not deleted. The tree under /gitea looks like this:

	root [~]$ tree -L 2 -d /gitea
	/gitea
	|-- auth
	|-- docker_reg
	|   `-- data
	|-- drone
	|   |-- agent
	|   `-- server
	|-- git
	|   |-- lfs
	|   `-- repositories
	|-- gitea
	|   |-- attachments
	|   |-- avatars
	|   |-- conf
	|   |-- indexers
	|   |-- log
	|   |-- queues
	|   |-- repo-avatars
	|   `-- sessions
	`-- mysql
	    |-- gitea
	    |-- mysql
	    |-- performance_schema
	    `-- sys
	


### General changes

The following needs to be changed to match your environment:
1. IP addresse (in most cases the IP address of the VM you run the containers on) 
2. Volume redirection
3. Parameters like password and usernames
4. External port numbers 

### Gitea

The default installation of Gitea is running HTTP only. To make the change to HTTPS, follow these steps:
1. After the container are running using `docker-compose up -d`, run `docker exec -it gitea /bin/bash`
2. Create your certificates via one of the two methods:
	1. In the container run `gitea cert --host [HOST]` where [HOST] is the IP address, or hostname of the Gitea server to get the certificates ready to be used. The certificates (cert.pem and key.pem are writen in the root of the container). 
	2. Follow these steps to create the certificates:
		1. Make sure you have openssl installed on your machine (Linux) 
		2. `openssl genrsa -des3 -passout pass:x -out keypair.key 2048`
		3. `openssl rsa -passin pass:x -in keypair.key -out keyfile.key`
		4. `openssl req -new -key keyfile.key -out certificate_req.csr`
		5. `openssl x509 -req -days 365 -in certificate_req.csr -signkey keyfile.key -out certificate.crt`
3. Then use vi /data/gitea/conf/app.ini and add as described in article the parameters at https://docs.gitea.io/en-us/https-setup/. Use `docker-compose stop gitea` and `docker-compose start gitea` to restart the Gitea server after the made changes and now the site will be accessable via HTTPS. The `CERT_FILE` can also be the `.crt` file. Same for the `KEY_FILE`. it can be the `.key` file.

### Drone.io Server

For the Drone server UI to be able to start, you need to make sure you have started the containers and assign Drone as the an application allowed to use your account for login. To do this, login into Gitea (**first user will also be the Admin for Gitea!**) and 
1. Click on your Avatar (right top side of the screen in Gitea)
2. Settings
3. Applications
4. Fill out **Create a new OAuth2 Appplication** fields and make sure the **Redirect URI** is 100% correct
5. Click **Create Application** button
6. Use the shown data in the docker-compose.yaml under `drone-server`. Set the parameters *DRONE_GITEA_CLIENT_ID* and *DRONE_GITEA_CLIENT_SECRET* to their corresponding values

---
**NOTE**

Make sure you save the data somewhere. As soon as you hit the **Save** button you will not see the value of secret field anymore.

---
7. Click the **Save** button in the Gitea interface
8. Restart the drone-server container via `docker-compose stop drone-server` and `docker-compose start drone-server`
9. Open the interface of the drone-server using a browser
10. This will show an Warning about an application wants to open in your name, do you want to authorize or not
11. Select the **Authorize** button and now you should see the Drone server UI


### Your local Laptop/Machine
The Gitea environment that we will deploy is using Self Signed Certificates. To allow git to also use this repository, provide the following commands:
1. On a per pull/push basis, `git -c http.sslVerify=false REPO URL` or
2. As a global setting for the whole system `git config --global http.sslVerify false`. This also works for all tools that use git in the background. Like GitDesktop.


## Usage
Use `docker-compose up -d` to start the network and containers defined in the docker-compose.yaml file. Your environment should now be available. 


**********

# Happy DevOps-ing...
