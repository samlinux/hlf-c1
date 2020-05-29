# Clear the network

Switch to the base folder.
```bash
cd morgen.net
````

## Remove chaincode container
```bash
docker rm -f $(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}
')

docker rm $(docker ps -a -f status=exited -q)

```

## Remove production data

We can clear the network data, but not the artifacts. This is useful if you want to practies the process of chaincode installation.

```bash
# remove genesis block and channel config
sudo rm -r ./ca-orderer.morgen.net/orderer/genesis.block
sudo rm -r ./ca-mars.morgen.net/peers/peer0/assets/channel.tx
sudo rm ./ca-mars.morgen.net/peers/peer1/assets/channel1.block

# remove persistent data if you use it
sudo rm -R ./ca-mars.morgen.net/peers/peer0/production
sudo rm -R ./ca-mars.morgen.net/peers/peer1/production
sudo rm -R ./ca-orderer.morgen.net/orderer/production
```

## Clear crypto material

 To start from the ground you can clear all artifacts, production data and chaincode containers.

```bash
# clear tls-ca.morgen.net
sudo rm -R ca-tls.morgen.net/ca

# clear ca-orderer.morgen.net
sudo rm -R ca-orderer.morgen.net/admin
sudo rm -R ca-orderer.morgen.net/ca
sudo rm -R ca-orderer.morgen.net/orderer
sudo rm -R ca-orderer.morgen.net/msp

# clear ca-mars.morgen.net
sudo rm -R ca-mars.morgen.net/admin
sudo rm -R ca-mars.morgen.net/ca
sudo rm -R ca-mars.morgen.net/msp 
sudo rm -R ca-mars.morgen.net/peers
sudo rm -R ca-mars.morgen.net/users
```
