## ubuntu-bakery.ps1

ubuntu bakery is a Joint work from Project dodo to provide a simple, streamlined, basic configuration of Openstack running on ubuntu including components like EMC SaleIO with Cinder Support.
## requirements
* Internet Gateway, most probably labbuildr´s openwrt
```Powershell
Receive-LabOpenWRT -start
```
* DNS Service, labbuild dcnode recommended 
```Powershell
.\build-lab.ps1 -Defaults -DConly
```
### Bakery Flours
[Openstack](https://github.com/bottkars/labbuildr/wiki/ubuntu-bakery.ps1#openstack)  
[kubernetes](https://github.com/bottkars/labbuildr/wiki/ubuntu-bakery.ps1#kubernetes)  

<h2 id="Openstack">openstack</h2>

## example
```Powershell
\ubuntu-bakery.ps1 -openstack
```
this will install:

* 3 Ubuntu 14_4 Nodes
* ScaleIO Configuration with MDM´s on Ubuntu1 and Ubuntu2, Gateway / TB on Ubuntu3
* ScaleIO SDS on all 3 Nodes
* Horizon Dashbord on Ubuntu3
* Nova Compute on Ubuntu1 and Ubuntu2
* Default Openstack liberty

_**You may want to select mitaka or even Newton, however, as netwon deploys Ubuntu16_4**_
you can tweak the Size of controllernodes / Openstack Release with
```Powershell
.\ubuntu-bakery.ps1 -openstack -openstack_release mitaka -Compute_Size TXL
```
this will configure the  compute nodes with 6GB of Memory and will aslo install a base tenant config 
![image](https://cloud.githubusercontent.com/assets/8255007/18787425/28e0c696-81a3-11e6-972b-4006a2879a64.png)
## create a volume from Horizon Portal  
![image](https://cloud.githubusercontent.com/assets/8255007/18471448/34528fda-79b2-11e6-9731-788fb08b0f4a.png)   
## create Snapshot from Horizon Portal  
![image](https://cloud.githubusercontent.com/assets/8255007/18466722/146f0686-799d-11e6-97e4-5da2c0de81c5.png)
## view Volume and Snap Properties
![image](https://cloud.githubusercontent.com/assets/8255007/18466748/3168ab5c-799d-11e6-9bd6-d65264e8ffd2.png)  
![image](https://cloud.githubusercontent.com/assets/8255007/18466766/4961d954-799d-11e6-89f6-6b920142c887.png)


## view volume from ScaleIO Gui
![image](https://cloud.githubusercontent.com/assets/8255007/18466621/b43b3992-799c-11e6-8092-5623e849a8b4.png)


## Options
the Default configuration uses ScaleIO as a cinder Backend.
you can Switch / add a backend / multi-backend with 
##troubleshooting
for the bakery process of scaleio tail into /tmp/labbuildr.log on the Controller node:
![image](https://cloud.githubusercontent.com/assets/8255007/18591724/0ec59ff8-7c34-11e6-9068-44e1653a6d22.png)
<h2 id="Kubernetes">kubernetes</h2>

you can start a basic Kubernetes setup by simply typing

```Powershell
.\ubuntu-bakery.ps1 -kubernetes
```

this will create a basic, 2-Node Kubernetes Deployment with a dedicated Master
the default configuration builds up the system pod, flannel pod networking support, and the dashboard with rbac constraints.
the deployment will take up to 6 Minutes.

you may also add scaleio switch, this will build a 3-node scaleio/kubernetes cluster

```Powershell
.\ubuntu-bakery.ps1 -kubernetes -scaleio
```

in step1, labbuildr deploy´s the 2 Nodes

![image](https://cloud.githubusercontent.com/assets/8255007/24656102/52bb7d7c-1941-11e7-8ae0-c7bbe59b58ec.png)

then, after basic node config is done, kubernetes and docker binaries are installed.
the first node will install the kubernetes master with kubeadm  
![image](https://cloud.githubusercontent.com/assets/8255007/24656180/babe890a-1941-11e7-84e0-3618bd6d0e49.png)

the slave nodes will use kubeadm join to join the cluster.
once the cluster is built, kubernetes dashboard deployment starts.

![image](https://cloud.githubusercontent.com/assets/8255007/24656226/eb3f4510-1941-11e7-8ad3-8e366aa462e6.png)


follow the instructions for [Kubernetes Dashboard](https://github.com/bottkars/labbuildr/wiki/ubuntu-bakery.ps1#kubernetes-dashboard)  

<h2 id="kubernetesdash">Kubernetes Dashboard</h2> 

there are multiple options to run the kubernetes dashboard
if you are running windows 10 with Bash support( requires at least Anniversary Update) the do the following:
Open Bash on ubuntu on windows
![image](https://cloud.githubusercontent.com/assets/8255007/24656353/7bf784c8-1942-11e7-9d2b-c06fd5f9dec2.png)
if not already added, add the kubernetes repo to apt sources:

do a su session in bash
```bash
sudo su
```
run as root:
```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubectl
```
![image](https://cloud.githubusercontent.com/assets/8255007/24663358/fc7386dc-1957-11e7-9006-33488c4dc427.png)

once kubectl is installed, exit the su session, make a .kube directory in your $HOME and copy the admin.conf from the master to your machine.  
```bash
exit
mkdir $HOME/.kube
scp root@192.168.2.201:/root/admin.conf $HOME/.kube/config
```
start kubectl proxy to start serving the proxy to the dashboard

```bash
kubectl proxy
```
![image](https://cloud.githubusercontent.com/assets/8255007/24664097/083f5a84-195a-11e7-8b93-9fbf8bc349e7.png)

you can now start the dashboard by pointing the Browser to http://localhost:8001/ui

![image](https://cloud.githubusercontent.com/assets/8255007/24664182/49bba698-195a-11e7-918f-b7c66186ff52.png)

