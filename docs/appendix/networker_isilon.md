### kudo´s for alex gaiswinkler for the MPSS and fast incrementals Setup doku
this is a installation faststart for networker champions using newtorker, isilon and MPSS
the installation allows to be in Corporate Network / VPN ! ( but is faster without :-) )  

Assumptions:
 - using Windows10 ( EMC Image or native)
 - have VMware 12 installed
( you may wan´t to review http://labbuildr.readthedocs.io/en/master/student_guide/ if new to labbuildr) 
## check vmware installed with proper vmnet !!
make sure you have vmnet2 set to 192.168.2.0 and connect a host virtual adapter to it !


![image](https://user-images.githubusercontent.com/8255007/28767140-d3321752-75d2-11e7-91b8-d95dd13e2b61.png)

## install and customize labbuildr if not already done

<script src="https://gist.github.com/bottkars/822916c35f032794997ec587d1db6e72.js"></script>


## install latest isilon
this will download the latest isilon from www.emc.com and build a standard master from the ova

```Powershell
#force download of latest isilon
.\install-isiova.ps1 -import -forcedownload
# install isilon
.\install-isiova.ps1
```

# MPSS and Fast Incrementals
# Setup in Networker:
![image](https://user-images.githubusercontent.com/8255007/28766065-0f587d5c-75ce-11e7-92b7-afaaece7657b.png)
## Multiple Parallel Save Streams and Fast Incremental:
![image](https://user-images.githubusercontent.com/8255007/28766075-184376b0-75ce-11e7-9d0d-e0f5c3918d22.png)
 
 
## Unfortunately the wizard does NOT show the MPSS feature !!
This should be implemented in the wizard as well as the fast_incremental feature.
Parallelism:
![image](https://user-images.githubusercontent.com/8255007/28766083-2009f48c-75ce-11e7-8215-608cfcf53174.png)
 
 
That's it!
 
## Looks like this:
![image](https://user-images.githubusercontent.com/8255007/28766095-2a18cd7c-75ce-11e7-9356-375d4aa95c32.png)  
 
 
 
suppressed 1872 bytes of output.
27.07.2017 12:02:08 smartconnect.labbuildr.local:savefs succeeded.
27.07.2017 12:02:08 Bronze-Filesystem smartconnect.labbuildr.local:savefs See the file C:\Program Files\EMC NetWorker\nsr\logs\policy\Bronze\Filesystem\Backup_000076_logs\77.log for command output
27.07.2017 12:02:08 NDMP multistreaming, '-A multistreams=4' is being applied to client 'smartconnect.labbuildr.local' saveset '/ifs'
27.07.2017 12:02:08 smartconnect.labbuildr.local:/ifs                          started
27.07.2017 12:02:08 nsrndmp_save -LL -T dump -s nwserver.labbuildr.local -c smartconnect.labbuildr.local -g Bronze/Filesystem/Backup/Bronze-Filesystem -A "*policy action jobid=76" -A "*policy name=Bronze" -A "*policy workflow name=Filesystem" -A "*policy action name=Backup" -y "Sun Aug 27 23:59:59 GMT+0200 2017" -w "Sun Aug 27 23:59:59 GMT+0200 2017" -A multistreams=4 -b Default -t 1499172191 -l incr -q -W 78 -N /ifs /ifs
27.07.2017 12:02:46 smartconnect.labbuildr.local:/ifs succeeded.
27.07.2017 12:02:46 Bronze-Filesystem smartconnect.labbuildr.local:/ifs See the file C:\Program Files\EMC NetWorker\nsr\logs\policy\Bronze\Filesystem\Backup_000076_logs\78.log for command output
27.07.2017 12:02:51 Action backup traditional 'Backup' with job id 76 is exiting with status 'succeeded', exit code 0
 
## On Isilon it looks like this:
![image](https://user-images.githubusercontent.com/8255007/28766105-378aadae-75ce-11e7-9294-3c1414c1770a.png)  
## Why are old Snaps not deleted by Networker ?  Strange….   
![image](https://user-images.githubusercontent.com/8255007/28766109-487c020c-75ce-11e7-8134-791909c32a85.png)
![image](https://user-images.githubusercontent.com/8255007/28766114-5347b4c4-75ce-11e7-8bf0-90943a62084a.png)

 
## Job Details Full Backup:   
  

  
144324:nsrndmp_save: Adding attribute *policy action jobid = 86
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144327:nsrndmp_save: Number of NDMP streams has been set to 4.
42909:nsrndmp_save: Performing DAR Backup.. 
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing full backup with BACKUP_MODE=SNAPSHOT.
152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.144324:nsrndmp_save: Adding attribute *policy action jobid = 86
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144324:nsrndmp_save: Adding attribute *policy action jobid = 86
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144324:nsrndmp_save: Adding attribute *policy action jobid = 86
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144327:nsrndmp_save: Number of NDMP streams has been set to 4.
144327:nsrndmp_save: Number of NDMP streams has been set to 4.
144327:nsrndmp_save: Number of NDMP streams has been set to 4.
42909:nsrndmp_save: Performing DAR Backup.. 
42909:nsrndmp_save: Performing DAR Backup.. 
42909:nsrndmp_save: Performing DAR Backup.. 
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing full backup with BACKUP_MODE=SNAPSHOT.
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing full backup with BACKUP_MODE=SNAPSHOT.
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing full backup with BACKUP_MODE=SNAPSHOT.
152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.42794:nsrndmp_save: Performing backup to Non-NDMP type of device
152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.42794:nsrndmp_save: Performing backup to Non-NDMP type of device
42794:nsrndmp_save: Performing backup to Non-NDMP type of device
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3849960775' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150535
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 8895
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48214
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3833183559' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150536
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 9029
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48213
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3816406343' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150537
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 9577
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48215
42794:nsrndmp_save: Performing backup to Non-NDMP type of device
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3799629134' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150540
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 8525
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48211
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 4608 bytes in 14.889 seconds throughput of 0.302 KB/s
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 4608 total bytes 
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.015599  sys=0.238698  ft=14.112411  cdb=0.000000
42617:nsrndmp_save: NDMP Service Log: maxrss=22916  in=12  out=29  vol=1839  inv=1331
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 22056448 bytes in 18.876 seconds throughput of 1141.085 KB/s
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 777570304 bytes in 22.355 seconds throughput of 33967.772 KB/s
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 22056448 total bytes 
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 777570304 total bytes 
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.013903  sys=0.419535  ft=17.547035  cdb=0.000000
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.076795  sys=3.112856  ft=22.050853  cdb=0.000000
42617:nsrndmp_save: NDMP Service Log: maxrss=44744  in=2769  out=29  vol=4175  inv=2097
42617:nsrndmp_save: NDMP Service Log: maxrss=135128  in=95415  out=35  vol=26598  inv=11212
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 283659776 bytes in 21.730 seconds throughput of 12747.800 KB/s
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 283659776 total bytes 
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.099467  sys=2.706596  ft=21.422602  cdb=0.000000
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (126/126)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (38/38)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: maxrss=140408  in=35110  out=29  vol=21881  inv=12814
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                38
Max Depth:                6
 
File Size (count)
----------------------------
== 0                        1
<= 8k                        42
<= 64k                        31
<= 1M                        50
<= 20M                        2
<= 100M                        0
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                126
Total Bytes:                21711729
Max Size:                1164288
Mean Size:                172315
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                164
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (798/798)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (316/316)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (6/6)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                316
Max Depth:                12
 
File Size (count)
----------------------------
== 0                        135
<= 8k                        288
<= 64k                        123
<= 1M                        213
<= 20M                        37
<= 100M                        7
<= 1G                        1
 > 1G                        0
-------------------------
Total Files:                804
Total Bytes:                775427993
Max Size:                181337356
Mean Size:                964462
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                1120
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (0/0)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (1/1)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                1
Max Depth:                1
 
File Size (count)
----------------------------
== 0                        0
<= 8k                        0
<= 64k                        0
<= 1M                        0
<= 20M                        0
<= 100M                        0
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                0
Total Bytes:                0
Max Size:                0
Mean Size:                0
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                1
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (1470/1470)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (947/947)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                947
Max Depth:                17
 
File Size (count)
----------------------------
== 0                        0
<= 8k                        967
<= 64k                        349
<= 1M                        128
<= 20M                        23
<= 100M                        3
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                1470
Total Bytes:                277927127
Max Size:                63031808
Mean Size:                189066
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                2417
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42951:nsrdsa_save: Successfully Done.
smartconnect.labbuildr.local: /ifs level=full, 23 MB 00:00:38    164 files
completed savetime=1501150537
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
80319:nsrndmp_2fh: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
An established connection was aborted by the software in your host machine.
 
42916:nsrndmp_save: Sorting File History completed Successfully in 00:00:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
42951:nsrdsa_save: Successfully Done.
80319:nsrdsa_save: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
90005:nsrdsa_save: Unable to end job: An established connection was aborted by the software in your host machine.
 
 
smartconnect.labbuildr.local: /ifs level=full, 761 MB 00:00:40   1120 files
completed savetime=1501150535
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
80319:nsrndmp_2fh: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
An established connection was aborted by the software in your host machine.
 
42916:nsrndmp_save: Sorting File History completed Successfully in 00:00:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
80319:nsrdmpix: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
80319:nsrdmpix: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:01 Hours
 
42920:nsrndmp_save: browsable savetime=1501150535
42697:nsrndmp_save: Leaving C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3849960775\fhfile.0
42927:nsrndmp_save: Successfully done
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:01 Hours
 
42920:nsrndmp_save: browsable savetime=1501150537
42697:nsrndmp_save: Leaving C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3816406343\fhfile.0
42927:nsrndmp_save: Successfully done
42951:nsrdsa_save: Successfully Done.
smartconnect.labbuildr.local: /ifs level=full, 2053 KB 00:00:44      1 file
completed savetime=1501150540
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
42951:nsrdsa_save: Successfully Done.
80319:nsrdsa_save: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
90005:nsrdsa_save: Unable to end job: An established connection was aborted by the software in your host machine.
 
 
smartconnect.labbuildr.local: /ifs level=full, 279 MB 00:00:49   2417 files
completed savetime=1501150536
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
80319:nsrndmp_2fh: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
An established connection was aborted by the software in your host machine.
 
42916:nsrndmp_save: Sorting File History completed Successfully in 00:00:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
80319:nsrdmpix: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:00 Hours
 
42920:nsrndmp_save: browsable savetime=1501150536
42697:nsrndmp_save: Leaving C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3833183559\fhfile.0
42927:nsrndmp_save: Successfully done
80319:nsrndmp_save: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
83523:nsrndmp_save: Failed to send nsrjobd a progress message: An established connection was aborted by the software in your host machine.
 
 
Cannot remove temporary FH index directory C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3799629134, it is safe to remove it manually.
42916:nsrndmp_save: Sorting File History completed Successfully in 00:01:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:00 Hours
 
42920:nsrndmp_save: browsable savetime=1501150540
88397:nsrndmp_save: Couldn't unlink NDMP file history database file S \FileIndex3799629134\FhParams, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file S \FileIndex3799629134\VolHdr, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file S \FileIndex3799629134\NodeRecords, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file S \FileIndex3799629134\NodeRecords_i0, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file S \FileIndex3799629134\NodeRecords_i0.0, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file S \FileIndex3799629134\NodeRecords_i1, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file S \FileIndex3799629134\NodeRecords_i1.0, No error
143867:nsrndmp_save: Saveset '3799629134' (MSB_SUMMARY='6:0:0') completed successfully.
143867:nsrndmp_save: Saveset '3816406343' (MSB_SUMMARY='6:1:0') completed successfully.
143867:nsrndmp_save: Saveset '3833183559' (MSB_SUMMARY='6:2:0') completed successfully.
143867:nsrndmp_save: Saveset '3849960775' (MSB_SUMMARY='6:3:0') completed successfully.
144080:nsrndmp_save: Successful multi-streaming backup. All expected 6 segments were backed up.
Stale asynchronous RPC handle42927:nsrndmp_save: Successfully done
 
 
Detailed Logs of an incremental backup (after adding one file):
144324:nsrndmp_save: Adding attribute *policy action jobid = 96
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144327:nsrndmp_save: Number of NDMP streams has been set to 4.
42909:nsrndmp_save: Performing DAR Backup.. 
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing incr backup with BACKUP_MODE=SNAPSHOT.
152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.144324:nsrndmp_save: Adding attribute *policy action jobid = 96
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144324:nsrndmp_save: Adding attribute *policy action jobid = 96
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144324:nsrndmp_save: Adding attribute *policy action jobid = 96
.144324:nsrndmp_save: Adding attribute *policy name = Bronze
.144324:nsrndmp_save: Adding attribute *policy workflow name = Filesystem
.144324:nsrndmp_save: Adding attribute *policy action name = Backup
.144327:nsrndmp_save: Number of NDMP streams has been set to 4.
144327:nsrndmp_save: Number of NDMP streams has been set to 4.
144327:nsrndmp_save: Number of NDMP streams has been set to 4.
42909:nsrndmp_save: Performing DAR Backup.. 
42909:nsrndmp_save: Performing DAR Backup.. 
42909:nsrndmp_save: Performing DAR Backup.. 
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing incr backup with BACKUP_MODE=SNAPSHOT.
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing incr backup with BACKUP_MODE=SNAPSHOT.
101922:nsrndmp_save: Forcing USE_TBB_IF_AVAILABLE to n because BACKUP_MODE=SNAPSHOT was found.
101924:nsrndmp_save: Performing incr backup with BACKUP_MODE=SNAPSHOT.
152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.42794:nsrndmp_save: Performing backup to Non-NDMP type of device
152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.152041:nsrndmp_save: Setting file history to file-based (HIST=F) for proper indexing of multistream backups.42794:nsrndmp_save: Performing backup to Non-NDMP type of device
42794:nsrndmp_save: Performing backup to Non-NDMP type of device
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3782852287' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150911
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 9792
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48865
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3766075071' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150912
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 9152
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48866
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3749297855' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150913
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 7984
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48867
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 1009152 bytes in 1.100 seconds throughput of 896.314 KB/s
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 1009152 total bytes 
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 23712768 bytes in 2.113 seconds throughput of 10961.733 KB/s
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.009143  sys=0.089608  ft=0.825625  cdb=0.003166
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 23712768 total bytes 
42617:nsrndmp_save: NDMP Service Log: maxrss=24456  in=142  out=29  vol=559  inv=943
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.018066  sys=0.452694  ft=1.162188  cdb=0.474540
42617:nsrndmp_save: NDMP Service Log: maxrss=36792  in=3001  out=47  vol=3389  inv=4882
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (1/1)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (3/2)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                2
Max Depth:                1
 
File Size (count)
----------------------------
== 0                        0
<= 8k                        0
<= 64k                        0
<= 1M                        1
<= 20M                        0
<= 100M                        0
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                1
Total Bytes:                1001472
Max Size:                1001472
Mean Size:                1001472
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                3
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 4608 bytes in 0.504 seconds throughput of 8.936 KB/s
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 4608 total bytes 
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.009373  sys=0.079760  ft=0.166210  cdb=0.002859
42617:nsrndmp_save: NDMP Service Log: maxrss=22000  in=12  out=29  vol=547  inv=533
42794:nsrndmp_save: Performing backup to Non-NDMP type of device
129292:nsrdsa_save: Successfully established Client direct save session for save-set ID '3732520643' (smartconnect.labbuildr.local:/ifs) with adv_file volume 'nwserver.labbuildr.local.001'.
42658:nsrdsa_save: DSA savetime = 1501150915
85183:nsrndmp_save: DSA is listening for an NDMP data connection on: 192.168.2.11, port = 7939
42952:nsrndmp_save: smartconnect.labbuildr.local:/ifs NDMP save running on 'nwserver.labbuildr.local'
accept connection: accepted a connection
42953:nsrdsa_save: Performing Non-Immediate save
42617:nsrndmp_save: NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.48863
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 4608 bytes in 0.355 seconds throughput of 12.677 KB/s
42617:nsrndmp_save: NDMP Service Log: Filetransfer: Transferred 4608 total bytes 
42617:nsrndmp_save: NDMP Service Log: CPU  user=0.007482  sys=0.059492  ft=0.158948  cdb=0.002625
42617:nsrndmp_save: NDMP Service Log: maxrss=22156  in=17  out=65  vol=457  inv=431
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (134/134)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (86/86)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                86
Max Depth:                6
 
File Size (count)
----------------------------
== 0                        18
<= 8k                        90
<= 64k                        19
<= 1M                        6
<= 20M                        0
<= 100M                        1
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                134
Total Bytes:                23331719
Max Size:                21102592
Mean Size:                174117
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                220
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (0/0)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (1/1)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                1
Max Depth:                1
 
File Size (count)
----------------------------
== 0                        0
<= 8k                        0
<= 64k                        0
<= 1M                        0
<= 20M                        0
<= 100M                        0
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                0
Total Bytes:                0
Max Size:                0
Mean Size:                0
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                1
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42617:nsrndmp_save: NDMP Service Log: 
Objects (scanned/included):
----------------------------
Regular Files:                (0/0)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (1/1)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_save: NDMP Service Log: 
Dir Depth (count)
----------------------------
Total Dirs:                1
Max Depth:                1
 
File Size (count)
----------------------------
== 0                        0
<= 8k                        0
<= 64k                        0
<= 1M                        0
<= 20M                        0
<= 100M                        0
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                0
Total Bytes:                0
Max Size:                0
Mean Size:                0
 
42617:nsrndmp_save: NDMP Service Log: 
File History
----------------------------
Num FH_HIST_FILE messages:                1
Num FH_HIST_DIR  messages:                0
Num FH_HIST_NODE messages:                0
 
42951:nsrdsa_save: Successfully Done.
smartconnect.labbuildr.local: /ifs level=incr, 3034 KB 00:00:17      3 files
completed savetime=1501150912
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
80319:nsrndmp_2fh: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
An established connection was aborted by the software in your host machine.
 
42916:nsrndmp_save: Sorting File History completed Successfully in 00:00:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
80319:nsrdmpix: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:00 Hours
 
42920:nsrndmp_save: browsable savetime=1501150912
42697:nsrndmp_save: Leaving C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3766075071\fhfile.0
42927:nsrndmp_save: Successfully done
42951:nsrdsa_save: Successfully Done.
80319:nsrdsa_save: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
90005:nsrdsa_save: Unable to end job: An established connection was aborted by the software in your host machine.
 
 
smartconnect.labbuildr.local: /ifs level=incr, 25 MB 00:00:28    220 files
completed savetime=1501150911
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
80319:nsrndmp_2fh: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
An established connection was aborted by the software in your host machine.
 
42916:nsrndmp_save: Sorting File History completed Successfully in 00:00:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
80319:nsrdmpix: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:00 Hours
 
42920:nsrndmp_save: browsable savetime=1501150911
42697:nsrndmp_save: Leaving C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3782852287\fhfile.0
42927:nsrndmp_save: Successfully done
42951:nsrdsa_save: Successfully Done.
80319:nsrdsa_save: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
90005:nsrdsa_save: Unable to end job: An established connection was aborted by the software in your host machine.
 
 
smartconnect.labbuildr.local: /ifs level=incr, 2053 KB 00:00:26      1 file
completed savetime=1501150913
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
80319:nsrndmp_2fh: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
An established connection was aborted by the software in your host machine.
 
42916:nsrndmp_save: Sorting File History completed Successfully in 00:00:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
80319:nsrdmpix: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:01 Hours
 
42920:nsrndmp_save: browsable savetime=1501150913
42697:nsrndmp_save: Leaving C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3749297855\fhfile.0
42927:nsrndmp_save: Successfully done
80319:nsrndmp_save: Aborting session channel connection (1) to 127.0.0.1; why = An established connection was aborted by the software in your host machine.
 
 
86866:nsrndmp_save: Cannot send attributes to the job daemon: An established connection was aborted by the software in your host machine.
 
 
42951:nsrdsa_save: Successfully Done.
smartconnect.labbuildr.local: /ifs level=incr, 2053 KB 00:00:27      1 file
completed savetime=1501150915
42913:nsrndmp_save: Save session closed with NW server successfully
 
42914:nsrndmp_save: Sorting File History....
Cannot remove temporary FH index directory C:\Program Files\EMC NetWorker\nsr\tmp\FileIndex3732520643, it is safe to remove it manually.
42916:nsrndmp_save: Sorting File History completed Successfully in 00:00:00 Hours
 
42917:nsrndmp_save: Processing NDMP File History...
42918:nsrndmp_save: smartconnect.labbuildr.local:/ifs Processing NDMP File History completed Successfully on 'nwserver.labbuildr.local' in 00:00:00 Hours
 
42920:nsrndmp_save: browsable savetime=1501150915
88397:nsrndmp_save: Couldn't unlink NDMP file history database file  a&\FileIndex3732520643\FhParams, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file  a&\FileIndex3732520643\VolHdr, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file  a&\FileIndex3732520643\NodeRecords, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file  a&\FileIndex3732520643\NodeRecords_i0, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file  a&\FileIndex3732520643\NodeRecords_i0.0, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file  a&\FileIndex3732520643\NodeRecords_i1, No error
88397:nsrndmp_save: Couldn't unlink NDMP file history database file  a&\FileIndex3732520643\NodeRecords_i1.0, No error
143867:nsrndmp_save: Saveset '3732520643' (MSB_SUMMARY='4:0:0') completed successfully.
143867:nsrndmp_save: Saveset '3749297855' (MSB_SUMMARY='4:0:0') completed successfully.
143867:nsrndmp_save: Saveset '3766075071' (MSB_SUMMARY='4:2:0') completed successfully.
143867:nsrndmp_save: Saveset '3782852287' (MSB_SUMMARY='4:2:0') completed successfully.
144080:nsrndmp_save: Successful multi-streaming backup. All expected 4 segments were backed up.
Stale asynchronous RPC handle42927:nsrndmp_save: Successfully done
 
 
Recovery of a single file:
Recovering 1 file into its original location
Total estimated disk space needed for recover is 978 KB.
Requesting 1 file(s), this may take a while...
42795:nsrndmp_recover:ssid'3766075071': Performing recover from Non-NDMP type of device
85183:nsrndmp_recover:ssid'3766075071': DSA is listening for an NDMP data connection on: 192.168.2.11, port = 9131
42689:nsrndmp_recover:ssid'3766075071': Performing DAR Recovery..
42617:nsrndmp_recover:ssid'3766075071': NDMP Service Log: 
Isilon NDMP 2.4.0
OneFS: B_8_1_0_011
Session ID: 1.49879
86724:nsrdsa_recover: DSA listening at: host 'nwserver.labbuildr.local', IP address '192.168.2.11', port '9131'.
129290:nsrdsa_recover: Successfully established direct file retrieve session for save-set ID '3766075071' with adv_file volume 'nwserver.labbuildr.local.001'.
42938:nsrdsa_recover: Performing Direct File Access Restore
42940:nsrdsa_recover: Reading Data...
42617:nsrndmp_recover:ssid'3766075071': NDMP Service Log: Filetransfer: Transferred 1005056 bytes in 0.493 seconds throughput of 1991.830 KB/s
42617:nsrndmp_recover:ssid'3766075071': NDMP Service Log: 
Objects (scanned/recovered):
----------------------------
Regular Files:                (1/1)
Sparse Files:                (0/0)
Stub Files:                (0/0)
Directories:                (0/0)
ADS Entries:                (0/0)
ADS Containers:                (0/0)
Soft Links:                (0/0)
Hard Links:                (0/0)
Block Device:                (0/0)
Char Device:                (0/0)
FIFO:                        (0/0)
Socket:                        (0/0)
Whiteout:                (0/0)
Unknown:                (0/0)
 
42617:nsrndmp_recover:ssid'3766075071': NDMP Service Log: 
File Size (count)
----------------------------
== 0                        0
<= 8k                        0
<= 64k                        0
<= 1M                        1
<= 20M                        0
<= 100M                        0
<= 1G                        0
 > 1G                        0
-------------------------
Total Files:                1
Total Bytes:                1001472
Max Size:                1001472
Mean Size:                1001472
 
42927:nsrndmp_recover:ssid'3766075071': Successfully done
07/27/17 12:33:14.827924 Unexpected reply on session channel 1: reqid expected:1029, received:0
80318:recover: Encountered an error finalizing recover job: Stale asynchronous RPC handle
 

