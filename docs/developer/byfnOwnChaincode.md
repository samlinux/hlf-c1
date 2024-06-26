# How to use the byfn network to run and test your own chaincode?

To do so, we create the following two scripts in a new directory. The first script is to start the network and install our custom chaincode. The second one is used to stop the network.

```bash 
# create a new directory under the fabric-samples
cd $HOME/fabric/fabric-samples
mkdir rb-test-network && cd rb-test-network
touch start.sh stop.sh addCC.sh
.
├── addCC.sh
├── start.sh
└── stop.sh
```

- The start.sh script is used to start the network, install the chaincode on peer0 for both organizations.
- The stop.sh script is used to stop and clean up the network.
- The addCC.sh script ist used to add an further chaincode to the running network.

Add the following to the start.sh script.
```bash 
#!/bin/bash
# Exit on first error
set -e

CC_CHANNEL_NAME=channel1
CC_NAME=sacc
CC_SRC_PATH=github.com/chaincode/sacc

startNetworkWithChaincode() {
  cd ../first-network
  echo y | ./byfn.sh down
  echo y | ./byfn.sh up -a -n -c $CC_CHANNEL_NAME

  CONFIG_ROOT=/opt/gopath/src/github.com/hyperledger/fabric/peer
  Org1Path=$CONFIG_PATH/crypto/peerOrganizations/org1.example.com
  Org2Path=$CONFIG_PATH/crypto/peerOrganizations/org2.example.com
  TlsPath=$CONFIG_PATH/crypto/ordererOrganizations/example.com/orderers/orderer.example.com
  
  ORG1_MSPCONFIGPATH=${Org1Path}/users/Admin@org1.example.com/msp
  ORG1_TLS_ROOTCERT_FILE=${Org1Path}//peers/peer0.org1.example.com/tls/ca.crt
  ORG2_MSPCONFIGPATH=${Org2Path}/users/Admin@org2.example.com/msp
  ORG2_TLS_ROOTCERT_FILE=${Org2Path}/peers/peer0.org2.example.com/tls/ca.crt
  ORDERER_TLS_ROOTCERT_FILE=${TlsPath}/msp/tlscacerts/tlsca.example.com-cert.pem

  set -x

  echo "Installing smart contract: $CC_NAME on peer0.org1.example.com"
  docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
    -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE} \
    cli \
    peer chaincode install \
      -n "$CC_NAME" \
      -v 1.0 \
      -p "$CC_SRC_PATH" 

  echo "Installing smart contract: $CC_NAME on peer0.org2.example.com"
  docker exec \
    -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH} \
    -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE} \
    cli \
    peer chaincode install \
      -n "$CC_NAME" \
      -v 1.0 \
      -p "$CC_SRC_PATH" 

  echo "Instantiating smart contract: $CC_NAME on $CC_CHANNEL_NAME"
  docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
    cli \
    peer chaincode instantiate \
      -o orderer.example.com:7050 \
      -C $CC_CHANNEL_NAME \
      -n $CC_NAME \
      -v 1.0 \
      -c '{"Args":["msg","hello blockchain"]}' \
      -P "AND('Org1MSP.member','Org2MSP.member')" \
      --tls \
      --cafile ${ORDERER_TLS_ROOTCERT_FILE} \
      --peerAddresses peer0.org1.example.com:7051 \
      --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE}

  echo "Waiting for instantiation request to be committed ..."
  sleep 10
  echo "Ready to use the network ..."
}

# start the network with a custom chaincode
startNetworkWithChaincode
```

Add the following to the stop.sh script.
```bash
#!/bin/bash
# Exit on first error
set -e

# bring down the network and clear all relevant data without the crypto artifacts
cd ../first-network
echo y | ./byfn.sh down
```

Add the following to the addCC.sh script.
```bash
#!/bin/bash
# Exit on first error
set -e

CC_CHANNEL_NAME=channel1
CC_NAME=go02
CC_SRC_PATH=github.com/chaincode/go02

addNewChaincode() {
  cd ../first-network

  CONFIG_ROOT=/opt/gopath/src/github.com/hyperledger/fabric/peer
  ORG1_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  ORG1_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  ORG2_MSPCONFIGPATH=${CONFIG_ROOT}/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  ORG2_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  ORDERER_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

  set -x

  echo "Installing smart contract: $CC_NAME on peer0.org1.example.com"
  docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
    -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG1_TLS_ROOTCERT_FILE} \
    cli \
    peer chaincode install \
      -n "$CC_NAME" \
      -v 1.0 \
      -p "$CC_SRC_PATH" 

  echo "Installing smart contract: $CC_NAME on peer0.org2.example.com"
  docker exec \
    -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH} \
    -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE} \
    cli \
    peer chaincode install \
      -n "$CC_NAME" \
      -v 1.0 \
      -p "$CC_SRC_PATH" 

  echo "Instantiating smart contract: $CC_NAME on $CC_CHANNEL_NAME"
  docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
    cli \
    peer chaincode instantiate \
      -o orderer.example.com:7050 \
      -C $CC_CHANNEL_NAME \
      -n $CC_NAME \
      -v 1.0 \
      -c '{"Args":["init","a","100","b","100"]}' \
      -P "AND('Org1MSP.member','Org2MSP.member')" \
      --tls \
      --cafile ${ORDERER_TLS_ROOTCERT_FILE} \
      --peerAddresses peer0.org1.example.com:7051 \
      --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE}

  echo "Waiting for instantiation request to be committed ..."
  sleep 10
  echo "Ready to use the network ..."
}

## add new chaincode to running network
addNewChaincode

```

## Use this chaincode

```bash 
# Start your test network for cli queries
docker exec -it cli bash

# we set some environment vars as placeholders to reduce the cli command
export TEST_CHANNEL_NAME=channel1

export TEST_CC_NAME=go02

export TEST_CA_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

export TEST_TLS_ROOT_CERT_ORG1=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

export TEST_TLS_ROOT_CERT_ORG2=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# show your variables
printenv | grep TEST

# query the ledger
peer chaincode query -C $TEST_CHANNEL_NAME -n $TEST_CC_NAME -c '{"Args":["query","a"]}'

# store something to the ledger
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile $TEST_CA_FILE -C $TEST_CHANNEL_NAME -n $TEST_CC_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $TEST_TLS_ROOT_CERT_ORG1 --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles $TEST_TLS_ROOT_CERT_ORG2 -c '{"Args":["addKey","c","1000"]}'

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile $TEST_CA_FILE -C $TEST_CHANNEL_NAME -n $TEST_CC_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles $TEST_TLS_ROOT_CERT_ORG1 --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles $TEST_TLS_ROOT_CERT_ORG2 -c '{"Args":["invoke","c","a","500"]}'
```
