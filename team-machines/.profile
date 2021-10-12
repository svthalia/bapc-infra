#!/bin/bash
if ! [[ $- == *i* ]]
then
TEAMID=$(echo $USERNAME | grep -Eo '[1-9]+$')
env "team-id=$TEAMID" ~/.local/presentations/client.sh https://contestdata.thalia.nu presentation rbARdoIS --name team &
fi


