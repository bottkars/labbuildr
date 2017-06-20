## how to build a docker registry for windows an linux

### example uing: docker registry on photon os

##### requires : docker registry 2.5 or later ( using 2.61 in this example )
##### requires : docker daemon on windows, minimum 17.06

### Setup:
install a docker host for your registry. in my example, i deploy a docker registry on a Photon Containerhost
in labbuildr use the command:
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
```docker info
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

