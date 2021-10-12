# Setting up Domjudge

The domjudge docker mostly speaks for itself, so the other README about setting up this infrastructure, should cover most interesting information. Here, we will give some more advanced info.

### Database connection
For a lot of actions, it is very handy to have direct database access, rather than doing everything via the domjudge web interface. Your favorite SQL client (such as Sequel Pro for Mac) can connect via ssh proxy with the database server running on 127.0.0.1 port 13306:
Here, you can change data in any way you want. 

- Note that after deleting data, you probably want to reset the AUTO_INCREMENT value as well
- The event table contains the event feed that the CDS will use. When the table is empty and the CDS tries to fetch it, some data will be re-created (the contest data, allowed languages, etc). 
However, not all submissions and judgements will be recreated! So when the contest is running, don't touch it. And remember that changing data in the database might result in out-of-sync event feeds
that are hard to recover from during a contest.

### Importing problems
- Make sure your adminsitrative/jury user is also a team member of an internal team, when importing problem archives. If you are not a team member, domjudge will not auto-upload and test the jury submissions.
- When creating your own problem archives, they must be zipped in the correct wy in order for domjudge to parse it correctly: `zip ../X.zip -r *`. Note that you must `zip` the individual files recursively. `zip X.zip -r X/` will **not** work.

### Printing
Domjudge offers a team and jury interface to print code files. Often, this is the easiest way to set up printing. However, to be flexible here, we need to make some tweaks to the docker container so it is actually able to do something with our prints.

#### Printing via CUPS
It is possible to do proper printing via a printer server. If you have set up a CUPS server at some ip address with open port 631, you can let domjudge send the printjobs to this server. The server address can be set 
in the domserver.env, which is also the only reason we build our own docker container rather than just using the latest.

 As configuration, you wil neeed:

	```bash
	enscript -b "Location: [location] - Team [teamid] [teamname]|| [original] - Page $% of $=" -a 0-10 -f Courier9 --printer $(echo [location] | sed -e 's/HG075.*/BAPC-north/' -e 's/HG.*/BAPC-south/' -e '/^BAPC/ !s/.*/BAPC-printing/') $([ ! -z [language] ] && echo "--highlight=$(echo [language] | sed 's/py[23]/python/')") [file] 2>&1
	```
	This command will add a header with team id and name to each page, as well as selecting the correct printer based on the loaction field (locations starting with 'HG075' will go to printer BAPC-north, other locations with 'HG' will go to BAPC-south and everything else will go to BAPC-printing). 
	
	```bash
	enscript -b "Location: [location] - Team [teamid] [teamname]|| [original] - Page $% of $=" -a 0-10 -f Courier9 --printer CUPS-PDF $([ ! -z [language] ] && echo "--highlight=$(echo [language] | sed 's/py[23]/python/')") [file] 2>&1
	```

#### Printing without CUPS
If no CUPS server is set up, you can also write print jobs to .ps files that can then be printed manually:
	```bash
	enscript -b "Location: [location] - Team [teamid] [teamname]|| [original] - Page $% of $=" -a 0-10 -f Courier9 -p $(echo /printjobs/team[teamid]-[location]-$(date +"%T").ps) [file] 2>&1
	```

The regular domjudge docker could suffice in this case, as no extra dependencies are required then.
