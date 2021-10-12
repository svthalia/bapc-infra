# Setting up programming contest team machines

## Template accounts
Usually we first ask 1 template account from CNCZ that can be used to set everything up.
Then when everything is ready, we ask CNCZ to sync the template directory to the homedirectories of the other test accounts. They should have some script available to do that.

Below will be some things that should be set up

## Software versions
Make sure that the correct versions of all languages are installed, and that they match
the versions used by the CCS. CNCZ can install apt versions. Alternatively, you can ask them put binaries in an `/opt/bapc` folder that they can sync to the machines. The BAPC often wants `pypy3`.

## IDE's
The most important thing is to make sure IDE's are installed. Some will be installed by default, others can be installed via apt. The onces that normally would be installed with `snap`, cannot be installed by CNCZ. However, for IntelIJ en PyCharm, you can download the community editions as `.tar.gz`. CNCZ can put them in a `/opt/bapc` folder and sync it with the machines you will be using. You can then run the IDE's, and in the `tools` menu click 'make desktop shortcut' to add the IDE's to the ubuntu software overview.

For IDE's like VSCode, make sure that the required extensions are also installed. For PyCharm, make sure to correct interpreters are installed. For IntelIJ, make sure the correct JRE is set up.

### Template projects
If you want to be nice to students, you can set up some template projects for development in certain languages and IDE's, that contain a "Hello, World!" command line app. Make sure that the correct build actions with correct compiler flags are configured, so you know for sure that the code will be compiled and run under the exact same conditions locally as on the judgehosts.

## Firewall 
You can ask CNCZ to set up a firewall, so that collaboration is impossible. The should have some ip tables set up that can be applied to machines in a certain room. They are not water-proof, but should work for most cases:
- disallow outgoing traffic except for some IP (that of the domjudge server)
- disallow SSH traffic to each other or to lilo

Note that it is still possible to collaborate via other protocols/ports. It is very hard (practically impossible) to block this entirely, as the machines will need to communicate with the CNCZ file system. But this firewall will be sufficient for most cases.

## Presentation client
Before the start of the contest, machines are configured to display a certain presentation
that shows the (contest) time, and that locks the keyboard. For this, all team machines
can be configured to start a presentation client that hooks up to the contest data server 
right after login.

To realize this, the user root directory contains a `.profile` file 
that contains a bash script that is run on login, which starts a presentation client in
the background. This presentation client will lock the keyboard and mouse and take over 
the screen to show a presentation. Admins can then remotely kill the presentation client
via the ICPC presentation admin tool, to release the machine to the team right when the 
contest starts.

Note that stopping the clients remains a manual action, it does **not** happen automatically on contest start.

A sample script to retrieve the team id from the username of the logged in account, pass it as env variable to the presentation client in team-mode (only executed if shell is non-interactive, so not executed when launching a terminal from an IDE or on SSH connection!):

```bash
#!/bin/bash
if ! [[ $- == *i* ]]
then
TEAMID=$(echo $USERNAME | grep -Eo '[0-9]+$' | sed 's/^0*//')
env "team-id=$TEAMID" ~/.local/presentations/client.sh https://contestdata.thalia.nu presentation rbARdoIS --name team &
fi
```

This expects the presentation client to be installed in the user home directory under `.local`.

Note that, because the CDS url does not specify the contest (so not `/api/contests/testsession`), the presentation client will by default hook itself up to the earliest active contest. If you want to avoid this (for example, when using separate accounts for testsession and contest) you might want to hard code the path.

## Documentation 
Language documentation is made available via Zeal. After opening Zeal, the docsets for
different languages (that are allowed in the contest) can be downloaded and installed. By default, they will be installed under `~/.local/share/zeal`, but this should be changed. The docsets can take up quite some disk space. Therefore, move them to some shared folder (such as `/opt/bapc` that all users will have access to). Then, under Zeal's preferences, change the storage location of the docsets to that path, so all Zeal instances will use the same docsets.

Check the versions of the documentation with the actual software versions installed on
the systems.

## Desktop background image
This speaks for itself.

## Favorites
It is nice to add some IDE's and commonly used tools (Zeal, Firefox, Terminal, etc.)
to the quick access toolbar.

## Home directory structure
We don't need `~/Movies/` or `~/Music/`... Note that it is possible that CNCZ will keep these folders when syncing home directories with the template account.

## Firefox landing page
It is nice to set the CCS homepage (the domjudge homepage) as start up page for Firefox.

## Domjudge CLI
Some teams like to use the command line. Domjudge offers a command line tool for 
`submit`ting solutions to Domjudge. You can install this client to the team machines following the instructions in the domjudge documentation. You probably also want to place the executable in the `/opt/bapc` folder and you will probably need to adapt the PATH variable for your shell to find the executable

## SSH authorized_keys
To make it easy for you to access the data in an account, it is very handy to add the ssh keys from organization members to the `authorized_keys` for the accounts. This way, you will not need passwords.

## Video streams
We have not tried this out yet, but apparently it should be possible to stream a screen capture and webcam feed to the CDS. You probably need to add this to the `.profile` script

## Important: cleaning things up
It is important to leave the template account clean before using it in the contest.

- Files that should be there (the startup script for the presentation client) should be
hidden (so `~/.presentation-client/client.sh` instead of `~/presentation-client/client.sh`)
- Delete files that are not needed anymore
- Remove browser data and history
- Remove command line history (.bash_history)
- Remove python history (.python_history)
- Remove log files (like those from the presentation client)
- Clear trash can 


# Presentation clients
In addition to team machines, it is probably also desirable to have accounts available to run a scoreboard presentation client. These need subtly different settings. For example, you do not want to call the presentation client
on login with the `--name team` argument. Perhaps, you dont even want to start the presentation client by default at all. Or maybe, you want to start an presentation admin by default.

To set up a jury room, you probably want multiple independent presentation clients to display different presentations, possibly in `blue` mode (so not with the regular CDS presentation account, but with the `blue` account that ignores frozen scoreboards). You need to think about how to set this up exactly (possibly, you need your own hardware for this).

# During contest
If everything is set up correctly, during the contest you will only need to login the accounts on the correct machines. They should immediately boot up in presentation mode, locking the screen.
Via the presentation admin, you can then set the "Team > Desktop" presentation as default. This will display the organization logo and team name, and a countdown, and it will lock the machine entirely.
On t=0, the presadmin should then remotely stop all team machines. 

If domjudge is set up to use IP authentication to log teams in, teams will not need any passwords.

Make sure to reboot machines when switching accounts or moving from test session to real contest. It is, for example, possible to place files in the machines local `/tmp` folder. A reboot will clean this up, guaranteeing a clean machine.
