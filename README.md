# Setting up a domjudge system from scratch

## Domserver
Running Ubuntu 20.04 LTS on AWS EC2 t2.micro (for testing purposes). 
Using official Docker images from [https://hub.docker.com/r/domjudge/domserver/](https://hub.docker.com/r/domjudge/domserver/)

### Installation

1. Install `docker-compose` via `sudo apt install docker-compose`
2. Make sure `docker` will run directly after booting the machine: `sudo systemctl enable docker` 
2. Place the `docker-compose.yml` file in the correct directory, together with the correct `.env` files. For example, in `/opt/domjudge/`
3. `sudo docker-compose up` to boot up all services. Use `-d` to run it in the background

This will do a couple of things.

- An nginx proxy server will be started, routing all web traffic on port 80 and 443 to the designated docker container based on that container's virtual hostname (set as environment variable). The folder `nginx` will contain persistent configuration files.

	*If you want to reset your configuration because of some problem, you can simply remove this `nginx` folder and restart. This will recreate all configurations. Note that this will also trigger new requests for certificates, so you should not do this too often to avoid rate-limiting by letsencrypt.*

- A lets-encrypt nginx companion docker will start, providing SSL certificates for the proxy server will start.
- A mariadb database container will start, to be used by domjudge (with custom configurations from `db_conf`.
- A custom domjudge domserver docker will be built (based on the official domjudge/domserver container) with some extra configurations in the start script:
	- Symfony's `TRUSTED_PROXIES` will be updated to correctly work with the nginx proxy server
	- Support for an external `CUPS_SERVER` will be set up
	- Note that we have chosen for a bare installation, so we will not have any demo data but start with a clean database.
- A `CUPS_SERVER` will be set up, used by domjudge to print files to, using the custom print command that can be set in the domjudge configurations.
- An ICPC tools Contest Data Server docker will be created, to connect with the domserver. In order to correctly function, this server needs some additional setup, though.

#### nginx proxy and HTTPS
We use an nginx-proxy to forward multiple domains to the correct services, as well as to upgrade to HTTPS using letsencrypt. For domjudge, this is fully supported. The Contest Data Server, however, does not support this fully. It has been said that running the CDS behind an nginx proxy will break stuff (especially websockets), but at least in our configuration it does not (or we have not found anything yet that we use). The only thing that will break, is that the CDS will not show correct ip's for the connected clients in its webinterface, but we can live with that...

### DOMjudge configuration
To continue setup, we first need to do some configurations in domjudge:

- The domjudge initial admin password will be printed in the docker logs. Note that if you reboot the containter, but without wiping the database, the old admin password will NOT be overwritten with this new value. Resetting the password can be done by running `docker exec -it domjudge_domjudge_1 /opt/domjudge/domserver/webapp/bin/console domjudge:reset-user-password admin`
- In order for the ICPC Contest Data Server to communicate with Domjudge, it needs API credentials. Therefore, an API reader/writer user account must be created in domjudge. We will need those credentials later
- We also need to create a service account for the judgehosts that will be judging our submissions. Probably, domjudge will already create a user for that purpose, but verify that this indeed has happened. You also might want to set the password (read further to see how to configure judgehosts).
- To properly set up printing, the print command must be set in the domjudge settings.	For example:
	
	```bash
	enscript -b "Location: [location] - Team [teamid] [teamname]|| [original] - Page $% of $=" -a 0-10 -f Courier9 --printer $(echo [location] | sed -e 's/HG075.*/BAPC-north/' -e 's/HG.*/BAPC-south/' -e '/^BAPC/ !s/.*/BAPC-printing/') $([ ! -z [language] ] && echo "--highlight=$(echo [language] | sed 's/py[23]/python/')") [file] 2>&1
	```
	This command will add a header with team id and name to each page, as well as selecting the correct printer based on the loaction field (locations starting with 'HG075' will go to printer BAPC-north, other locations with 'HG' will go to BAPC-south and everything else will go to BAPC-printing). 
	
	```bash
	enscript -b "Location: [location] - Team [teamid] [teamname]|| [original] - Page $% of $=" -a 0-10 -f Courier9 --printer CUPS-PDF $([ ! -z [language] ] && echo "--highlight=$(echo [language] | sed 's/py[23]/python/')") [file] 2>&1
	```
- Make sure to double check the executables for the languages you want to support. For example, if you want to use cpython for judging python submissions, your python run.sh file should call `python3` while PyPy requires `pypy3`. Note that these settings depend on the exact judgehost that you are running (read further).
- With `./create_database_dump.sh` and `./restore_database_dump.sh <file>` you can create and restore backups
- You can hook up your own favorite MySQL client to the live database by connecting via an SSH tunnel on port 13306. This is very convenient in most cases because it makes you more flexible than by just using the domjudge webinterface while experimenting.
- In `domserver/domjudge-images` you find all images that domjudges uses in its interface. Here you can place affiliation logos, team photos and a `banner.png` to be shown on the static public scoreboard. Check the domjudge documentation for further instructions.

Also note that [https://github.com/DOMjudge/domjudge-scripts](https://github.com/DOMjudge/domjudge-scripts) might contain useful scripts.

#### Configuring a contest
When everything is setup, you can import the contest and specify the specific settings. When importing problem archives, make sure to be logged in as a user with Jury permissions and associated to a team. This way, after import all test cases that are specified in the problem archive will be submitted and judged for verification in order to check the correct working of the judgehosts. In the "judging verifier", you can then see whether all test cases were correctly verified, or that you might hit some timelimits while that should not be the case. 

For further instructions, we refer to Domjudge's admin documentation.

### CDS configuration
If the contests are correctly set up in Domjudge, we can configure the Contest Data Server to correctly read from Domjudge. 

It is important to know that, while domjudge supports users creating multiple contests from the webinterface without changing configurations or requiring server access, the CDS does require you to change some configuration file for each contest you want it to work on.

- the `cdsConfig.xml` file is mounted as volume and contains information about the contests that the CDS will work with. Make sure that each contest the CDS must use is configured in here, with the correct API credentials for DOMjudge. An example file could be: 

```xml
<cds>
        <contest location="/contest-data/1" recordReactions="false">
                <ccs url="https://bapc-domtest.technicie.nl/api/contests/1" user="cds" password="xxxxxxxxxxxxxx"/>
        </contest>
        <contest location="/contest-data/2" recordReactions="false">
                <ccs url="https://bapc-domtest.technicie.nl/api/contests/2" user="cds" password="xxxxxxxxxxxxxx"/>
        </contest>
</cds>
```
Note that `/contest-data` is also mounted as volume to be the root for all Contest Data Packages. The above configuration will use `/contest-data/1` as Contest Data Package for contest with id 1, etc. 
Make sure that these directories already exist (`mkdir 1` in `/contest-data`), the CDS will not create them but crash if they do not exist.

After the configuration has changed, make sure to **reboot the CDS** with `docker-compose restart cds`. 

#### Contest Data Package
For each contest, the Contest Data Server will pull most of its data from domjudge via the API. However for some features, additional data is required that are not provided by domjudge: team pictures, affiliation logos, contest logo and banner, photos and logos for usage in presentations, staff-members, floor-plan, affiliation coordinates. All these data can be manually written to the mounted contest data package according to the instructions below.

##### floor-map.tsv
Several tools connected to the CDS can use a schematic of the floor map. For example, the presentation clients can display balloons travelling through the venue to a team desk. Also, the balloon utility uses this map to give directions to balloon runners.

The floor map can be configured by manually adding a file in the CDP at `<CDP>/config/floor-map.tsv`. The file should contain grid-based coordinates of all (team) desks, balloon stations, printers and aisle. When building the team map, it is easy to decide on a standard unit for yourself (for example either use 'meters' or 'tables'). 

The first line of `floor-map.tsv` is expected to be in this form.

```
<team desk width>	<team desk depth>	<team area width>	<team area depth>
```
here the area of a team will be the whole rectangle for the team and the desk is the exact rectangle that will be drawn as desk. For correct visualization, it is best to just play around with these values a little bit. 
Note that for each team, 3 chairs will be drawn along the width of the desk but outside of the team area!

After the first line, all objects can be entered

- `team`: for each team, the file should contain a line in the form `team	<id>	<x>	<y>	<rotation>`. The `id` must correspond with the team id from domjudge (or, when using the CDP as data source, its team id there). If rotation is `0`, the desk will be drawn with the 3 chairs vertically stacked on the left (so desk width becomes height, and desk depth becomes width). Note again that chairs can be drawn outside of the team area. It is also possible to draw desks that are not used by a team (but by staff members or just as furniture that is not used), by using "`<-1>`" as the team id.
- `balloon`: balloon stations can be drawn by entering lines in this form `balloon	<id>	<x>	<y>`. The `id` must correspond with the problem id. 
- `printer`: printers can be added with this line: `printer	<x>	<y>`.
- `aisle`: aisles are used to display walking routes. They can be entered with `aisle	<x1>	<y1>	<x2>	<y2>`.

As an example, this file:

```tsv
12	3	12	4
team	<-1>	4	32	0
team	1	8	8	180
team	2	8	20	180
team	3	8	32	180
team	4	16	8	180
team	5	16	20	180
team	6	16	32	180
team	7	24	8	180
team	8	24	20	180
team	9	24	32	180
team	10	32	8	180
team	11	32	20	180
team	12	32	32	180
team	13	40	8	180
team	14	40	20	180
team	15	40	32	180	
team	16	48	8	180
team	17	48	20	180
team	18	48	32	180
team	19	56	8	180
team	20	56	20	180
team	21	56	32	180
```

will produce this output:

TODO


It has been experienced that problems occur when the floor-map file is not sorted on team id or coordinates, but it is unclear how and why.

##### staff-members.tsv
TODO

##### affiliation logos
TODO

##### team pictures
TODO

##### presentation promo, logo's, banners, photo(path)s
TODO

#### CDS video
TODO


### CUPS configuration
The CUPS server is based on a simple debian image running a container. It does not use the nginx-proxy for SSL (as this would not work), but the service is exposed on port 631 regardless of hostname. The certificates are mounted as a volume, which is a bit hacky, but it works.

All configuration files are persitently mounted at `cups-config/` but can also be managed via the webinterface via HTTP(s) (at port 631). Here, printers can be configured. If the `CUPS_SERVER` variable of Domjudge is set to this server, all prints from domjudge will be sent to the specified (or if not the default) print queue on this server. There are numerous ways to set this up, as you can specify multiple print queues in CUPS and they will all be available to Domjudge. 

Note that this CUPS server is not only accessible to Domjudge: any device can use this print server. To change this, the `cupsd.conf` configuration file can be adapted. 

#### At the Radboud University
At the Radboud University, with the Peage printing system, it is possible to configure printers directly to this CUPS printserver. For best results, you want to have Direct Printing access to several printers so you can bypass FollowMe printing during a contest. At the Radboud University, this requires a separate functional print account (with a separate e-number login) although probably things could theoretically also work with a student number and KUARIO account. 

The printers should be added as Windows SAMBA printers (this is just smb). The exact URL to use should include the username, password and domain(!) to use. For example, these are 3 printers at the RU:

```
smb://RU\eXXXXXXXX:PasswordOfTheRUPrintAccount@payprint02.ru.nl/KM-0026-direct
smb://RU\eXXXXXXXX:PasswordOfTheRUPrintAccount@payprint02.ru.nl/KM-0040-direct
smb://RU\eXXXXXXXX:PasswordOfTheRUPrintAccount@payprint02.ru.nl/FollowMe
```
Note that you might have the encode the password if you cannot authenticate (and please, please, do not forget the `RU\` domain, that took ages to debug). As driver we used the driver provided by university, `FollowMe.ppd` (which is the print driver for the most advanced Konica Minolta MFP available).

Note that you do not print to a printer directly, but print to a virtual print server that the university runs. For Direct Printing this virtual queue does immediately print to the device, so you do not notice this too much. However if you are printing large documents or large numbers of copies, it will take very long (sometimes even more than 10 minutes!) for printers to start receiving the print job. This is because the university virtually proof-prints the jobs before releasing them to the device, to determine the number of pages and print costs. And that takes very long.

Also note that the virtual print server of the RU (or the Konica Minolta machines, but I do not expect that) does NOT support the banner page / job sheet option of CUPS! Somehow, if it is setup, the rest of the printjob is ignored. Otherwise this was the ideal way to realize watermarked print jobs for each team.


## Judgehosts
Our judgehosts are run in EC2 instances in an Auto Scaling configuration. The instances themselves run a modified version of the judgehost Docker image. To create an autoscaling group like this you first need to create a template image that will be used as the disk for all the judgehosts. For this you can use any type of instance, I used a t2.micro instance, with Ubuntu 20.04 LTS. 

Log in to this image and add any ssh keys you want to use. In this AMI the local host is not added to the `/etc/hosts` file, which makes sudo complain with a warning. To fix this, I added a systemd service which adds the host to the hosts file on boot:

```ini
# /etc/systemd/system/write-hostname.service
[Unit]
Description=Write the hostname to /etc/hosts to make sure there are no sudo warnings
After=network.target

[Service]
ExecStart=/bin/bash -c 'echo 127.0.0.1 $(hostname) >> /etc/hosts'
Type=oneshot
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```

This re-adds the hostname on every boot, but this should not be a problem (and you'll probably boot only once anyway). Add this file to the `/etc/systemd/system` directory and use `systemctl enable write-hostname.service` to enable it at boot.

To start the Docker container at boot, another systemd service is used:
```ini
# /etc/systemd/system/judgehost.service
[Unit]
Description=DOMJudge judgehost
After=update-judgehost.target

[Service]
ExecStart=/usr/bin/docker run --restart=on-failure --network host --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name judgehost -e DOMSERVER_BASEURL=https://domjudge.thalia.nu/ -e JUDGEDAEMON_USERNAME=judgehost -e JUDGEDAEMON_PASSWORD=<REPLACEME> thalia/judgehost:7.3.1
Type=exec
ExecStop=/usr/bin/docker stop judgehost
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

You will probably want to replace the environment variables, and possibly the Docker image used for your contest. To make sure the Docker container can be started quickly, you should pull it now by running `docker pull thalia/judgehost:7.3.1`. As with the other service, you can enable this service to start at boot with: `systemctl enable judgehost.service`.

This is all you need to add to the template image, so now you should remove any temporarly files and possibly the line added to `/etc/hosts` and shutdown. Once shutdown you can create an AMI via this menu:

![screenshot from EC2 manager, showing the create image button](create_template.png)

Then you will have to create a Launch Template that uses this AMI. No special settings are needed here, but you will need to choose an instance type—we use the c5.large type. You can set a larger disk size too, we use 20GB. Now you can create the Auto Scaling Group from this Launch Template, and you can set it to use the latest version of the Launch Template so you don't have to change this when you update it. This Auto Scaling Group is useful because you can set the amount of judgehosts you want available and they will just appear, additionally you can use spot instances which are cheaper. To make it even easier you can use the following command:

```bash
aws autoscaling set-desired-capacity --auto-scaling-group-name bapc-runner --desired-capacity 1
```

### Judgehost Docker image
For the 2020 BAPC prelims it was recommended to run pypy3 for Python 3 submissions. The 7.3.0 DOMjudge server and judgehost did not include the pypy3 command, and [the PR for this](https://github.com/DOMjudge/domjudge/pull/914) would only be included in version 8.0.0 of DOMjudge. We [included the changed `dj_make_chroot`](https://github.com/DOMjudge/domjudge-packaging/blob/0cffbe54db05981d2eb894168a4a7a2910b47766/docker/judgehost/dj_make_chroot) in the build of our own Dockerfile and [overwite the included dj_make_chroot with the new version that includes pypy3](https://github.com/DOMjudge/domjudge-packaging/blob/0cffbe54db05981d2eb894168a4a7a2910b47766/docker/judgehost/Dockerfile.build#L35). Otherwise the judgehost Docker container is built as usual.

## Team systems
TODO

## Admin tools
A lot of rather simple "desktop tools" exist. They can be found on [https://icpc.global/icpctools/](https://icpc.global/icpctools/) or [https://pc2.ecs.csus.edu/pc2projects/build/](https://pc2.ecs.csus.edu/pc2projects/build/). 

### New tools to build ourselves
- A simple tool to improve the `presAdmin` by sending automatic contest-time-based requests to the CDS to update certain presentation clients (and maybe get rid of some nasty presAdmin bugs). 
  
  The web interface uses the following script:
  
  ```javascript
  var last;
  function setPresentation(id) {
   //document.getElementById("team"+id).disabled = true;

   var xmlhttp = new XMLHttpRequest();

   xmlhttp.onreadystatechange = function() {
     document.getElementById("status").innerHTML = "Changing to " + id;
     if (xmlhttp.readyState == 4) {
        if (xmlhttp.status == 200) {
           document.getElementById("status").innerHTML = "Success";
        } else
           document.getElementById("status").innerHTML = xmlhttp.responseText;
        //document.getElementById("team"+id).disabled = false;
     }
   };
   
   xmlhttp.open("PUT", "present/" + id, true);
   xmlhttp.send();
  }
  ```

## Useful commands
- `docker-compose up -d` to start all services (remove `-d` to receive full logs realtime)
- `docker-compose down` to stop all services. Note that this will also remove all data from the database, while `stop` will maintain that data.
- `docker-compose stop <service>` to stop a single service (similar with `start` or `restart`).
- `docker-compose build --no-cache <directory>` to do a full rebuild (as this will not automatically happen if you just `docker-compose up`)
- `docker system prune` to remove old data
- `docker-compose logs <service>` to check the logs
- `docker-compose exec -it <service> bash` to enter the container of a service
- `docker-compose cp <service>:<path> ./` to copy some file from inside your container, even if the container is not running. 

- When creating your own problem archives, they must be zipped in the correct wy in order for domjudge to parse it correctly: `zip ../X.zip -r *`. Note that you must `zip` the individual files recursively. `zip X.zip -r X/` will **not** work.

- `aws autoscaling set-desired-capacity --auto-scaling-group-name bapc-runner --desired-capacity 1` to set the judging capacity

## Credits
We would like to give credits to:

- [https://github.com/DOMjudge/domjudge/wiki/Connecting-the-ICPC-Tools-with-DOMjudge](https://github.com/DOMjudge/domjudge/wiki/Connecting-the-ICPC-Tools-with-DOMjudge) (Nicky Gerritsen) for a lot of help
- [https://github.com/WISVCH/docker-domjudge](https://github.com/WISVCH/docker-domjudge) for some reference material
- [https://github.com/nginx-proxy/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) for instructions how to set up the nginx proxy

