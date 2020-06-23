# Chaincode Development Environment
(chaincode-docker-devmode)

Below you will find a chaincode development environment with tmux. For more commands see the <a href="https://tmuxcheatsheet.com/?q=&hPP=100&idx=tmux_cheats&p=0&is_v=1" target="_blank">cheatsheet</a>.

## Create a tmux session
To create a named session, run the tmux command with the following arguments:
```bash
tmux new -s fabric
```
 
### Create a split view
Split pane horizontally
```bash 
CTRL + b "
``` 

Split pane vertically
```bash 
CTRL + b %
``` 

Now you can see two panels. Now we switch to the second panel.
```bash 
# jump to second panel (watch the numbers after q)
CTRL + b q 1

# jump the first panel if you want
CTRL + b q 0
``` 

Split the second panel horizontally again.
```bash
# split the screen again
CTRL + b "
```
Now you should have one session with three panels.

Spread the panels evenly.
```bash
CTRL + b [space]
```

### Start the environment
Switch to panel 0. Make sure you are into the directory fabric-samples/chaincode-dev-docker. 
```bash
CTRL + b q 0

# start the network
docker-compose -f docker-compose-simple.yaml up
```

Notice: The docker-compose-simple.yaml file does not include a couchDb container. If you are going to use couchDb releated topics with this environment you have to modify the docker-compose file.

Add the following to your docker-compose file.

```bash
couchdb:
  container_name: couchdb
  image: hyperledger/fabric-couchdb:0.4.18
  # Populate the COUCHDB_USER and COUCHDB_PASSWORD to set an admin user and password
  # for CouchDB.  This will prevent CouchDB from operating in an "Admin Party" mode.
  environment:
    - COUCHDB_USER=admin
    - COUCHDB_PASSWORD=password
  # Comment/Uncomment the port mapping if you want to hide/expose the CouchDB service,
  # for example map it to utilize Fauxton User Interface in dev environments.
  ports:
    - "5984:5984"
```

And under the peer service in this docker-compose file add the following and start your network again.
```bash
  - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
  - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
  - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=password
  - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb:5984
```


### Build the chaincode
Switch to the second region with the command.
```bash 
CTRL + b q 1 
```

To build the chaincode you have to check the $GOPATH environment variable and you should have cloned the fabric git repo with the proper release. In my case I use the release 1.4.

Do this for only for the first time.

```bash 
export GOPATH=/root/fabric
cd /root/fabric
mkdir -p src/github.com/hyperledger
cd src/github.com/hyperledger

git clone -b release-1.4 https://github.com/hyperledger/fabric.git
```

To build the chaincode you have to switch into the chaincode container.

```bash 
# switch into the chaincode container
docker exec -it chaincode bash

# switch into the chaincode folder
cd chaincode/sacc

# build the chaincode
go build

# check the result
# you should see the go binary file.
ls -l
```

Now you can run the chaincode:
```bash 
CORE_PEER_ADDRESS=peer:7052 CORE_CHAINCODE_ID_NAME=mycc:0 ./sacc
```

### Use the chaincode
Switch to panel three.
```bash 
CTRL + b q 2
``` 

Switch into the cli container to use the chaincode.
```bash 
docker exec -it cli bash
cd /opt/gopath/src
```

Install and instantiate the chaincode.
```bash 
peer chaincode install -p chaincodedev/chaincode/sacc -n mycc -v 0
peer chaincode instantiate -n mycc -v 0 -c '{"Args":["a","10"]}' -C myc
```

Invoke the chaincode.
```bash
peer chaincode invoke -n mycc -c '{"Args":["set", "a", "20"]}' -C myc
```

Query the chaincode.
```bash 
peer chaincode query -n mycc -c '{"Args":["query","a"]}' -C myc
```

## Leave the tmux session
To leave the current screen session detach from it.
```bash 
CTRL + b d
```
## List all tmux sessions
```bash 
tmux ls
```

## Rename the tmux session
```bash 
tmux rename-session -t [oldname] [newname]
```

## Reattach to the tmux session
To resume your screen session use the following command.
```bash 
tmux attach -t 0
```

## Kill the tmux session
```bash
# shows existing screen session - you need the name of the session
tmux -ls

# kill the session per name
tmux kill-session -a -t mysession
```

## Scroll inside panel (Mac version)
To scroll inside of a panel use the following command.
```bash 
CTRL + b fn + up || down
```
