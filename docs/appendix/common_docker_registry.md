## how to build a docker registry for windows an linux

### using: docker registry on photon os

##### requires : docker registry 2.5 or later ( using 2.61 in this example )
##### requires : docker daemon on windows, minimum 17.06

### Setup:
install a docker host for your registry. in my example, i deploy a docker registry on a Photon Containerhost  
for labbuildr, you can use use the command:
```Powershell
.\install-photon.ps1 -docker_registry
```

this will
- install latest phopton os
- pull docker-registry latest
if you install manually, here is an example docker compose:

```yaml
    - path: /root/docker-compose.yml
      content: | 
       registry:
         restart: always
         image: registry:latest
         ports:
          - 5000:5000
         volumes:
          - /data:/var/lib/registry
```

you can build your registry manually by

```
/usr/bin/docker-compose -f /root/docker-compose.yml up -d
```
![image](https://user-images.githubusercontent.com/8255007/27326254-4803f9ee-55ab-11e7-84cf-73a0a9eeb735.png)
the registry in this example uses /data dockervolume, a mountpoint for sdb1 in my case

to make Docker Windows able to push images to the linux registry, the allow-nondistributable-artifacts must be set in 
 c:\programdata\docker\config\daemon.json 
insecure registry is also defined in that by insecure-registries directive
example
```json
{
"insecure-registries":["192.168.2.40:5000"],
"allow-nondistributable-artifacts": ["192.168.2.40:5000"]
}
```
When using labbuildr a windows dockerhost can be automatically brought online by running:

```Powershell
.\build-lab.ps1 -Master 2016core -docker -Size xl -defaults
```

modifications for the private registry and nondistributable artifacts are made automatically then.
#### verify
run docker info to verify setings and versions on your windows host
```Powershell
docker info
```
![image](https://user-images.githubusercontent.com/8255007/27322624-182bb3d0-559f-11e7-8280-cfed52ec2bc6.png)

#### test

to download a windows based image from the docker hub, run 
docker pull <iamge:tag>
in this example i used microsoft sql server, as the size was the original reason to build this :-)
```
docker pull microsoft/mssql-server-windows
```
![image](https://user-images.githubusercontent.com/8255007/27322680-492cf660-559f-11e7-9ee4-db88ade0c121.png)

once download is complete, we tag the image with the local registry name/ip:
```
docker tag microsoft/mssql-server-windows:latest 192.168.2.40:5000/microsoft/mssql-server-windows:latest
```
and push it to the local registry
```
docker push 192.168.2.40:5000/microsoft/mssql-server-windows:latest
```

![image](https://user-images.githubusercontent.com/8255007/27324683-3ee90c0a-55a6-11e7-8428-bb70b1df3632.png)
we can now ask the registry for the catalog by 
```
Invoke-RestMethod http://192.168.2.40:5000/v2/_catalog | Select-Object -ExpandProperty repositories
```
![image](https://user-images.githubusercontent.com/8255007/27326026-8ce55388-55aa-11e7-9614-bb7f7f0daa2c.png)



on a second docker windows host, we verify the image by pulling it
```Powershell
docker pull 192.168.2.40:5000/microsoft/mssql-server-windows:latest
```
![image](https://user-images.githubusercontent.com/8255007/27325356-731643f6-55a8-11e7-902c-4b753b1d7124.png)

you will notice a faster download speed now as you refer to your local repo
