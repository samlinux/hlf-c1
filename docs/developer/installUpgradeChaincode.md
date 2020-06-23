# Install chaincode

```bash 
peer chaincode install -n sacc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/sacc/
```

Check if the chaincode is installed.
```bash 
peer chaincode list --installed
``` 


# Update chaincode
To upgrade an existing chaincode you have to do two steps:

1. Install the new chaincode with the same name under a new verions no
2. Upgrade the chaincode


After modification of the chaincode we have to install the chaincode under a new version first.
```bash
peer chaincode install -n sacc4 -v 1.1 -p github.com/hyperledger/fabric-samples/chaincode/sacc4/
```

After installation of the new chaincode version we can fire up the upgrade of the chaincode. But you have to be aware about the init function of the chaincode!

```bash
peer chaincode upgrade -o orderer.morgen.net:7050 --tls --cafile /tmp/hyperledger/mars.morgen.net/peers/peer0/tls-msp/tlscacerts/tls-ca-tls-morgen-net-7052.pem -C channel1 -n sacc4 -v 1.1 -c '{"Args":["msg","upgrade"]}'
```