# install-mesos including support for emc rexray volume driver and scaleio

mesos with rexray requires a running scaleio environment. i recommend [ScaleIO SVM Solutionpack](http://labbuildr.readthedocs.io/en/latest/Solutionpacks//install-scaleiosvm.ps1)
In this example, ScleIO SVM was deployed and now additional Volumes / SDC´s are created.  
Please make sure to approve the MDM Certificates via the REST Gateway on https://gatewayip:443/rest.jsp
![image](https://cloud.githubusercontent.com/assets/8255007/17048627/a1774de8-4fe7-11e6-8f44-a4b174ad148a.png)
if you are not using a labbuildr deployed scaleio environment, create a scaleioenv.xml file in the labbuildr dir similar to
```
<scaleio>
<sio_mdm_ipa>192.168.2.191</sio_mdm_ipa>
<sio_mdm_ipb>192.168.2.192</sio_mdm_ipb>
<sio_gateway_ip>192.168.2.193</sio_gateway_ip>
<sio_system_name>ScaleIO@labbuildr</sio_system_name>
<sio_pool_name>SP_labbuildr</sio_pool_name>
<sio_pd_name>PD_labbuildr</sio_pd_name>
</scaleio>
```

you can test the configfile with
```Powershell
Get-LABSIOConfig
```
![image](https://cloud.githubusercontent.com/assets/8255007/17048878/9202426c-4fe9-11e6-9620-80a7399d13dd.png)

we start the dployment using  
```Powershell
.\install-mesos.ps1 -Defaults -rexray
```
mesos / rexray requires the Centos7 Master. if it is not found in the defaults Masterpath, it will be dowbloaded and extracted from labbuildr repo

![image](https://cloud.githubusercontent.com/assets/8255007/17048923/d76e8d60-4fe9-11e6-9af9-f1e16357a234.png)

once the download is finished, labbuildr will check for ScaleIO Linux Binaries. 
ScaleIO Binaries are required for the SDC to enable Container / Application Persisitence on mesos nodes.   
if not found, labbuildr will fetch the latest binaries from emc.com

![image](https://cloud.githubusercontent.com/assets/8255007/17048985/5a4367d8-4fea-11e6-84d2-2fb6545d231c.png)
once all downloads are finished, a default of 3 mesos is created. the nodes will start, and each nodes get a starting configuration:
![image](https://cloud.githubusercontent.com/assets/8255007/17049211/2edf1d2e-4fec-11e6-9b32-1a9b410325f2.png)
the sdc gets installed with pointing to the mdm`s provided in the scaleio config file.
each individual node configuration is finished once docker and zookeper are configured and started:

![image](https://cloud.githubusercontent.com/assets/8255007/17049283/a5d571a8-4fec-11e6-8bd7-c2c7412c5b1b.png)

once all nodes are configured, the rexray configuration is pushed to the hosts and the rexray service is enabled.
![image](https://cloud.githubusercontent.com/assets/8255007/17051495/585c718a-4ff9-11e6-8768-edb87deb2947.png)

a default application not using volume persistence, and a docker postgres container is created using marathon

![image](https://cloud.githubusercontent.com/assets/8255007/17049471/cd1e7f2e-4fed-11e6-9853-ee03c04eff38.png)

check the ScaleIO UI for new registerd SDC´s and Volumes:  
![image](https://cloud.githubusercontent.com/assets/8255007/17049505/fcbce662-4fed-11e6-9dd6-8d94e7992608.png)
![image](https://cloud.githubusercontent.com/assets/8255007/17049519/0feb5322-4fee-11e6-9985-7740ff2dd014.png)

verify the sdc / rexray / container status from the node the container is running on 
````bash
rexray volume list
docker ps
````
![image](https://cloud.githubusercontent.com/assets/8255007/17049648/d6157758-4fee-11e6-9d87-88c642d2fede.png)

do the same from any other node: 
![image](https://cloud.githubusercontent.com/assets/8255007/17049676/f80986ba-4fee-11e6-900e-6da0c2d2337f.png)


