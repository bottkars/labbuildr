## install-ecs
a new ecs single node deployment is started with
```Powershell
.\install-ecs.ps1 -Defaults
```
if no operating system master for centos is found, it will be downloaded automatically from labbuildr repo on azure
![image](https://cloud.githubusercontent.com/assets/8255007/17015627/73d4cf76-4f2b-11e6-9067-a0e37e14e17d.png)
enter y to start download 
![image](https://cloud.githubusercontent.com/assets/8255007/17015681/ce980e8c-4f2b-11e6-89c1-d37d19040f68.png)

after the master is downloaded, a base snap is created.  

a linked clone is than created a and customized. ( -fullclone create a full clone )
![image](https://cloud.githubusercontent.com/assets/8255007/17016167/190dd170-4f2e-11e6-92ec-f7c6d791a57e.png)
during customization, 3 disks, 12GB and 4CPU are added
custom parameters can be specified, see get-help install-ecs.ps1


once the node is booted, the system is running the network configuration of the node

![image](https://cloud.githubusercontent.com/assets/8255007/17015941/06fc0fe8-4f2d-11e6-86e7-86e1e944b025.png)

before starting package installs and downloads, the default route is verified.
after that, various downloads are started and saved to reduce downloads for subsequent redeploys:
* yum packages, wich will be stored in $sources\centos using redirected yum directory for later use
* docker image, wich will be saved in $sources\docker, for later use

![image](https://cloud.githubusercontent.com/assets/8255007/17016402/544d40da-4f2f-11e6-9f39-66e764df742b.png)

once the base installation is finished and the docker container is downloaded,  the script will run the step1 installation from ECS Community Edition
![image](https://cloud.githubusercontent.com/assets/8255007/17016651/506a2cac-4f30-11e6-872e-d498cec3ccd6.png)
this will
* configure disk drives for the ecs system
* configure the network / hostname for the container 
* tweak some settngs in the ecs container to run as single node
the step will take some minutes and is finished once the ecs default website is reachable

once the system can login to the ecs site, the docker container is set to start on boot.
next, the initial configuration of namespace, pools, datastores, virtual datacenter and users is done:
![image](https://cloud.githubusercontent.com/assets/8255007/17017050/0e11a4dc-4f32-11e6-8089-66c574879efd.png)

for first login, please wait until deployment is finished:  
![image](https://cloud.githubusercontent.com/assets/8255007/17020888/7ef6f9a6-4f44-11e6-88b6-11fdf39217a0.png)

log on to you ecs instance with root/ChangeMe
![image](https://cloud.githubusercontent.com/assets/8255007/17020983/003d6b76-4f45-11e6-8e04-8b22256b7323.png)

change your password, ecs ui will reload
![image](https://cloud.githubusercontent.com/assets/8255007/17021032/66168e0a-4f45-11e6-9156-0caa58be802a.png)

when the wizard starts again, click "no thanks, i`ll get started on my own"

![image](https://cloud.githubusercontent.com/assets/8255007/17021075/aecac45e-4f45-11e6-8056-3eea2f2bda7c.png)

