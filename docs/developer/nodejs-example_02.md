# Step by step - how to access HLF ledger data
This is a step by step guide how you can use node.js based on the byfn.sh script.

## Clean up 

```bash
# stop the network
./byfn.sh down

# delete stopped containers
docker rm -v $(docker ps -a -q -f status=exited)

# Delete all docker volumnes
docker volume prune
```

## Start the network

```bash 
cd fabric-samples

cp -r first-network hsc-frist-network

cd hsc-frist-network

./byfn.sh generate -c channel1

./byfn.sh up -a -c channel1

```
## Develop an application

### Project setup
```bash
cd ../../
mkdir appHsc && cd appHsc

# for cli commands and node.js tests
mkdir cli test

# create a npm project
npm init

# add node.js dependencies to the package.json file

 "dependencies": {
   "express": "^4.17.1",
   "fabric-ca-client": "^1.4.8",
   "fabric-network": "^1.4.8"
 },
 "devDependencies": {
   "mocha": "^7.1.2",
   "supertest": "^4.0.2"
 }

npm install

npm install -g nodemon
```

### Add an identity to the wallet
```bash
cd cli 
cp ../../fabric-samples/commercial-paper/organization/digibank/application/addToWallet.js ./
cp ../../fabric-samples/fabcar/javascript/enrollAdmin.js ./
cp ../../fabric-samples/fabcar/javascript/registerUser.js ./

ll ../../fabric-samples/hsc-first-network/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore/

# adjust the addToWallet to User1@org1.example.com
node addToWallet.js

# adjust the enrollAdmin to your needs (if it's time at the end)
node enrollAdmin.js

# adjust the registerUser.js script to your needs (if it's time at the end)
node registerUser.js
```

### Inspect the connection profile

```bash 
jq '.' ../fabric-samples/hsc-first-network/connection-org1.json
```

### Create the node.js application

- create index.js (and copy source)

Start the application in a new panel
```bash 
nodemon index.js
```