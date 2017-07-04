# this guide descripes how to deploy scom testbed

follow the deployment from, and choose some otional hosts to install:

<script src="https://gist.github.com/bottkars/b28326bb6b0595192508530777abed84.js"></script>


after the ESI Powershell is installed, verify the service is up and Running

![image](https://user-images.githubusercontent.com/8255007/27819069-cc536502-6098-11e7-8aa0-448266ed8c66.png)

browse to https://localhost:54501/esi/console to view the Service for you webbrowser

Adding systems ( on Controller node, EG, Blanknode ):

Add the UnityVSA to ESI Service:


first, verify connection with uemcli
```Powershell
uemcli.exe -d 192.168.2.171 -u admin -p Password123! /sys/soft/ver show -detail
```

Add the System
```Powershell
$params = @{"Username"="admin";"Password"="Password123!";"ManagementIp"="192.168.2.171"};
Add-EmcSystem -SystemType Unity -Params $params -UserFriendlyName UnityVSA
```

Now proceed 