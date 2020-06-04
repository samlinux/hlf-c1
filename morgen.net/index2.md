# Put all things together

Make sure you have done all steps in:

- ca-tls.morgen.net/index.md
- ca-orderer.morgen.net/index.md
- ca-mars.morgen.net/index.md

After we have created the crypto materials we can bootstrap the fabric network.

This process can be summarized in the following steps:

1. Create the network docker-compose.file
2. Create the genesis block
3. Create the channel config
4. Start the network
5. Create the channel and join all peers
6. Install and instantiate the chaincode
7. Test the network with some queries

## (1) Create docker-compose.file
First we have to setup our docker-compose file. You can find the details in docker-compose.yaml file in this directory.

Overall we have six services in this composer file. We can group these services by type.

### Orderer service (1)
- orderer.morgen.net

### Peers (2)
- peer0.mars.morgen.net
- peer1.mars.morgen.net

### State Database (1 db per each peer)
- couchdb0
- couchdb1

### Cli (1)
- cli-mars.morgen.net

To keep our couchDb database credentials secure we use the docker-compose .env file.

```bash
# create the file
vi .env

# add the password in the format: var=value
couchdbUser=root
couchdbPwd=toor
```

## (2) Create the genesis block

```bash
configtxgen -profile OneOrgOrdererGenesis -channelID orderersyschannel -outputBlock ./ca-orderer.morgen.net/orderer/genesis.block
```

## (3) Create the channel config

```bash 
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./ca-mars.morgen.net/peers/peer0/assets/channel.tx -channelID channel1
``` 

## (4) Start the network
We start the network in the background.

```bash 
# start the network
docker-compose -f docker-compose-couch.yaml up -d

# watch logs
docker-compose logs -f

``` 

Open a further terminals and check if the network is running.
```bash

# check if the network is running
docker-compose ps

# you should see
        Name                Command       State           Ports
------------------------------------------------------------------------
cli-mars.morgen.net     sh                Up
orderer.morgen.net      orderer           Up      0.0.0.0:7050->7050/tcp
peer0.mars.morgen.net   peer node start   Up      0.0.0.0:7051->7051/tcp
peer1.mars.morgen.net   peer node start   Up      0.0.0.0:8051->7051/tcp

# check all running containers
docker ps --format 'table {{.Names}}\t {{.Ports}}'

# you should see
NAMES                    PORTS
peer1.mars.morgen.net    0.0.0.0:8051->7051/tcp
peer0.mars.morgen.net    0.0.0.0:7051->7051/tcp
cli-mars.morgen.net
couchdb1                 4369/tcp, 9100/tcp, 0.0.0.0:6984->5984/tcp
orderer.morgen.net       0.0.0.0:7050->7050/tcp
couchdb0                 4369/tcp, 9100/tcp, 0.0.0.0:5984->5984/tcp
ca-mars.morgen.net       0.0.0.0:7054->7054/tcp
ca-orderer.morgen.net    0.0.0.0:7053->7053/tcp, 7054/tcp
ca-tls.morgen.net        0.0.0.0:7052->7052/tcp, 7054/tcp
```
## (5) Create the channel and join all peers
To create the channel and join it to the peers we can use the cli container (cli-mars.morgen.net).

```bash
# switch into this container
docker exec -it cli-mars.morgen.net bash 
```

To interact with the network we make sure that some environment variables are set correctly. For peer0 all environment variables are already set in the docker-compose file.
```bash
# needed environment variables
export CORE_PEER_LOCALMSPID="marsMSP"
export CORE_PEER_MSPCONFIGPATH="/tmp/hyperledger/mars.morgen.net/admin/msp"

# these variables depends on the peer
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"
```

We can check the existing environment variables in the cli container.
```bash 
printenv |grep CORE

# you should see
CORE_PEER_LOCALMSPID=marsMSP
CORE_PEER_TLS_ENABLED=true
CORE_PEER_ID=cli-mars.morgen.net
CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/mars.morgen.net/admin/msp

CORE_PEER_TLS_ROOTCERT_FILE=/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem
CORE_PEER_ADDRESS=peer0.mars.morgen.net:7051
```

As a next step we can create the channel on peer0.
```bash
peer channel create -c channel1 -f /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel.tx -o orderer.morgen.net:7050 --outputBlock /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel1.block --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem
```

After this step we can join peer0 to the new channel.

```bash 
peer channel join -b /tmp/hyperledger/mars.morgen.net/peers/peer0/assets/channel1.block
``` 

We can check if channel1 is successfully joind to peer0.
```bash 
peer channel list

# you should see
Channels peers has joined:
channel1
```

After this step we can switch over to peer1. For that we have to change the corresponding environment variables.

```bash 
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem"
export CORE_PEER_ADDRESS="peer1.mars.morgen.net:7051"
```

Check if you are on peer1.
```bash 
printenv | grep CORE_PEER_ADDRESS
```

On peer1 we have to fetch the newest channel information from the orderer. We can do that with the following command.

```bash 
peer channel fetch newest /tmp/hyperledger/mars.morgen.net/peers/peer1/assets/channel1.block -c channel1 --orderer orderer.morgen.net:7050 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem 
```

The next step is to join peer1 to channel1.
```bash 
peer channel join -b /tmp/hyperledger/mars.morgen.net/peers/peer1/assets/channel1.block
``` 

Check if channel1 is successfully joind to peer1.
```bash 
peer channel list

# you should see
Channels peers has joined:
channel1
``` 

## (6) Install and instantiate the chaincode

To install the chaincode we switch back to peer0. For that we set the corresponding environment variables.

```bash 
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"
```

Check if you are on peer0 again.
```bash 
printenv | grep CORE_PEER_ADDRESS
```

Basically the process of installing a chaincode is divided in the following steps:

1. install the chaincode
2. check if chaincode is installed
3. instantiate the chaincode
4. use the chaincode with invoke or query operations

To do this steps we can use the cli container. The cli container has mounted our chaincode folder (see the network docker-compose.yaml file). Becaue of this, we can call the following command to install the chaincode on the channel. 

```bash 
peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/
```

Check if the chaincode is installed.
```bash 
peer chaincode list --installed

# you should see
Get installed chaincodes on peer:
Name: sacc, Version: 1.0, Path: github.com/hyperledger/fabric-samples/chaincode/sacc/, Id: c05aa7ef2...
``` 

Based on the chaincode you have to instantiate the chaincode. In our example we use the sacc chaincode from the fabric-samples.

```bash 
peer chaincode instantiate -n sacc -v 1.0 -o orderer.morgen.net:7050 -C channel1  -c '{"Args":["msg","hello blockchain"]}' --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem
```

>Note: during this process a new container is created, the chaincode container dev-peer0.mars.morgen.net-sacc-1.0-82a3...

We can no test the chaincode with a simple query.

```bash 
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem

# you should see
hello blockchain
``` 

Now we are ready on peer0. Let's switch to peer1 to sync that peer. For that we switch to peer1 again by chaning the corresponding environment variables.
```bash  
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem"
export CORE_PEER_ADDRESS="peer1.mars.morgen.net:7051"
``` 

Check again if you are on peer1 again.
```bash 
printenv | grep CORE_PEER_ADDRESS
```

On peer1 no chaincode is installed, so we have to install the chaincode first to query the ledger from peer1. We do that with the following command.

```bash 
peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/
```

Check if the chaincode is installed.
```bash 
peer chaincode list --installed

# you should see
Get installed chaincodes on peer:
Name: sacc, Version: 1.0, Path: github.com/hyperledger/fabric-samples/chaincode/sacc/, Id: c05aa...
``` 

Now you can query the leder from peer1.

```bash 
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem
```

To set a new value to the key we can use the invoke command.
```bash  
peer chaincode invoke -n sacc -c '{"Args":["set", "msg","hello morgen.net"]}' -C channel1  --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer1/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem
```

At this point you can switch back to peer0 and query the ledger to see if the peer0 is in sync with the ledger.

```bash  
export CORE_PEER_TLS_ROOTCERT_FILE="/tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem"
export CORE_PEER_ADDRESS="peer0.mars.morgen.net:7051"
``` 

```bash 
peer chaincode query -n sacc -c '{"Args":["query","msg"]}' -C channel1 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem

# you should see
hello morgen.net
```









