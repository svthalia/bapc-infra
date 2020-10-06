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

#### CDS, nginx proxy and HTTPS
TODO explain how to use the `create_cds_certificate` script etc...


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
	
- TODO wipe database command


#### Configuring a contest
When everything is setup, you can import the contest and specify the specific settings. When importing problem archives, make sure to be logged in as a user with Jury permissions and associated to a team. This way, after import all test cases that are specified in the problem archive will be submitted and judged for verification in order to check the correct working of the judgehosts. In the "judging verifier", you can then see whether all test cases were correctly verified, or that you might hit some timelimits while that should not be the case. 

For further instructions, we refer to Domjudge's admin documentation.

### CDS configuration
If the contests are correctly set up in Domjudge, we can configure the Contest Data Server to correctly read from Domjudge.

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
TODO

## Judgehosts
For judgehosts 


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


## Credits
We would like to give credits to:

- [https://github.com/DOMjudge/domjudge/wiki/Connecting-the-ICPC-Tools-with-DOMjudge](https://github.com/DOMjudge/domjudge/wiki/Connecting-the-ICPC-Tools-with-DOMjudge) (Nicky Gerritsen) for a lot of help
- [https://github.com/WISVCH/docker-domjudge](https://github.com/WISVCH/docker-domjudge) for some reference material

