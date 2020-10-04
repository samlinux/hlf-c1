# Setup
These steps describes a fabric installation on a DigitalOcean Droplet.

## Droplet 
Digital Ocean Droplet, 1 CPU, 2 GB, 50 GB SSD  
OS, Ubuntu 20.04 (LTS) x64

## Access via ssh
ssh root@ssh root@165.227.146.125

## Perparations
The following steps are required to prepare the Droplet.
```bash
# update the OS
apt update && apt upgrade

# install some useful helpers
apt install tree htop jq

# it's always good the use the right time
# so setup the correct timezone
timedatectl set-timezone Europe/Vienna

# check the time
date
```

## Secure your installation
We secure our installation with ufw.
```bash
# check if ufw is installed (should be by default)
ufw status

# set default behavier
ufw default deny incoming
ufw default allow outgoing

# allow only ssh access
ufw allow ssh

# show added rules
ufw show added

# enable the firewall
ufw enable

# check the status again 
ufw status
```


## Install Docker
The following steps are required to install docker on the Droplet.

```bash
# set up the repository
sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

# add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -


# set up the stable repository
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"


# install docker engine
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io

# check the docker version
docker --version
```

## Install Docker-Compose

```bash
# install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# apply executable permissions to the binary
chmod +x /usr/local/bin/docker-compose

# check the docker-compose version
docker-compose --version
```

## Install Go Programming Language
Hyperledger Fabric uses the Go Programming Language for many of its components. Go version 1.14.x is required.

```bash 
# download and extract go
# latest version 04.10.20 1.14.9
wget -c https://dl.google.com/go/go1.14.9.linux-amd64.tar.gz -O - | tar -xz -C /usr/local

# add the go binary to the path
vi $HOME/.profile
export PATH="$PATH:/usr/local/go/bin"

# point the GOPATH env var to the base fabric workspace folder
export GOPATH=$HOME/fabric

# reload the profile
source $HOME/.profile

# check the go version
go version
```

**Second**, you should (again, in the appropriate startup file) extend your command search path to include the Go bin directory, such as the following example for bash under Linux:

```bash
export PATH=$PATH:$GOPATH/bin
```

## Install node.js

```bash
# add PPA from NodeSource
# curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh 
curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh

# call the install script
bash nodesource_setup.sh

# install node.js
apt-get install -y nodejs

# check the version
node -v
```

## Install Samples, Binaries and Docker Images

```bash
mkdir fabric
cd fabric

# install the latest production release from the 1.4.x branch
# curl -sSL http://bit.ly/2ysbOFE | bash -s -- <fabric_version> <fabric-ca_version> <thirdparty_version>

# curl -sSL http://bit.ly/2ysbOFE | bash -s -- 1.4.6 1.4.6 0.4.18
# curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.1 1.4.9

# latest production ready release, omit all version identifiers.
curl -sSL https://bit.ly/2ysbOFE | bash -s


# check downloaded images
docker images

# add the bin directory to your path
vi $HOME/.profile
PATH=/root/fabric/fabric-samples/bin:$PATH
```

## Check the installation
The build your first network (BYFN) scenario provisions a sample Hyperledger Fabric network consisting of two organizations, each maintaining two peer nodes. It also will deploy a "Solo" ordering service by default, though other ordering service implementations are available. To test your installationen we can start the network.

```bash
# switch to the base folder
cd fabric-samples/test-network

# bring up the network
./network.sh up

# optional a fast track
./network.sh up createChannel -c channel1

# show if some containers are running
docker ps
docker-compose -f docker/docker-compose-test-net.yaml ps

# create a channel, mychannel as a default name, between org1 and org2
./network.sh createChannel

# use custom channel name with -c option
# you can use also different channels with the -c option
./network.sh createChannel -c channel1

# install default CC - asset-transfer (basic) chaincode
./network.sh deployCC -c channel1


# bring down the network
./network.sh down
```

## Interacting with the network


# Environment variables for Org1

```bash
export FABRIC_CFG_PATH=$HOME/fabric/fabric-samples/config/
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
```

Run the following command to initialize the ledger with assets:
```bash
export CHANNEL_NAME="channel1"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'
```
