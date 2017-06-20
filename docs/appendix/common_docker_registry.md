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

to make Docker Windows able to pusk images to the linux registry, the allow-nondistributable-artifacts must be set in 
 c:\programdata\docker\config\daemon.json 
example
```json
{
"insecure-registries":["192.168.2.40:5000"],
"allow-nondistributable-artifacts": ["192.168.2.40:5000"]
}
```
