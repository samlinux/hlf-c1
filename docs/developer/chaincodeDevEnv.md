# Chaincode development environment
Below you will find a chaincode development environment with screen windows.

## Create screen session
To create a named session, run the screen command with the following arguments:
```bash
screen -S chaincode
```

### Create windows
As a next step we are going to create three windows. Notice we are in an active screen session. To create a second window we can use the command:
```bash
CTRL + a c
```
With CTRL + a you will come to a kind of "cmd modus" where you can start several commands. E.g c for a new window. Notice that this command has actually two commands. The CTRL + a command and c.

To create a third window we can use the command again:
```bash 
CTRL + a c
```

To check if all three windows are ready use the comman:
```bash 
CTRL + a "
```

As a next step we can rename the three windows from bash to what it does. Jump to window 0.
```bash
CTRL + a 0
```

Now we can rename the window. To rename the window use the command:
```bash 
CTRL + a A

#type the name: start the network
```

Jump to window 1.
```bash
CTRL + a 1
```

Now we can rename the window. To rename the window use the command:
```bash 
CTRL + a A

#type the name: build & start the chaincode
```

Jump to window 2.
```bash
CTRL + a 2
```

Now we can rename the window. To rename the window use the command:
```bash 
CTRL + a A

#type the name: use the chaincode
```

Check your windows names with the command.
```bash 
CTRL + a "
```
 
### Create split view
Switch to window 0.
```bash 
CTRL + a 0
``` 

Split the window horizontally.
```bash
CTRL + S
```
Now you can see two screens, one with the name 0 start the network and a second one unnamed. Now we switch to the second region with the command and link window 1 to that region.
```bash 
CTRL + a [Tab] (= tab key)
# now you see the course in the second view.

# now link the second split view to window 1 with the command.
CTRL + a 1
``` 

Split the window horizontally again and link window 2 to that region.
```bash
# split the screen again
CTRL + S

# link the third window to that region
CTRL + a 2 
```
Now you should have one session with three named regions.

### Start the environment
Switch to region 1 named 0 start the network
```bash
# switch back 
CTRL + tab

# start the network
docker-compose -f docker-compose-simple.yaml up
```

### Build the chaincode
Switch to the second region with the command.
```bash 
CTRL + a 1 
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
Switch to region 3.
```bash 
CTRL + a tab
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

## Leave the screen session
To leave the current screen session detach from it.
```bash 
CTRL + a d
```

## Reattach to the screen session
To resume your screen session use the following command.
```bash 
screen -r
```

## Kill the screen session
```bash
# shows existing screen session - you need the name of the session
screen -ls

# kill the session per name
screen -S 22104.chaincode -p 0 -X quit
```