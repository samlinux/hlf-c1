# Setup
These steps describes a fabric installation on a DigitalOcean Droplet.

## Droplet 
Digital Ocean Droplet, 1 CPU, 2 GB, 50 GB SSD  
OS, Ubuntu 18.04.3 (LTS) x64

## Access via ssh
ssh root@64.227.115.55

## Perparations
The following steps are required to prepare the Droplet.
```bash
# update the OS
apt update && apt upgrade

# install some useful helpers
apt install tree

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
curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# apply executable permissions to the binary
chmod +x /usr/local/bin/docker-compose

# check the docker-compose version
docker-compose --version
```

## Install Go Programming Language
Hyperledger Fabric uses the Go Programming Language for many of its components. Go version 1.12.x is required.

```bash 
# add the golang backports ppa
add-apt-repository ppa:longsleep/golang-backports

# install golang 
apt-get install golang-1.12

# add the go binary to the path
vi ~/.profile
PATH="$PATH:/usr/lib/go-1.12/bin"

# reload the profile
source ~/.profile

# check the go version
go version
```

**First**, we must set the environment variable GOPATH to point at the Go workspace containing the downloaded Fabric code base.

```bash
export GOPATH=$HOME/fabric
```

**Second**, you should (again, in the appropriate startup file) extend your command search path to include the Go bin directory, such as the following example for bash under Linux:

```bash
export PATH=$PATH:$GOPATH/bin
```

## Install node.js

```bash
# add PPA from NodeSource
curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh

# call the install script
bash nodesource_setup.sh

# install node.js
apt-get install -y nodejs

# check the version
nodejs -v
```

## Install Samples, Binaries and Docker Images

```bash
mkdir fabric
cd fabric

# install the latest production release from the 1.4.x branch
# curl -sSL http://bit.ly/2ysbOFE | bash -s -- <fabric_version> <fabric-ca_version> <thirdparty_version>

curl -sSL http://bit.ly/2ysbOFE | bash -s -- 1.4.6 1.4.6 0.4.18

# check downloaded images
docker images

# add the bin directory to your path
vi ~/.profile
PATH=/root/fabric/fabric-samples/bin:$PATH
```

## Install Fabric-CA binary

Install some dependencies on Ubuntu
``` bash
apt install libtool libltdl-dev
```
The following installs both the fabric-ca-server and fabric-ca-client binaries in $GOPATH/bin. We need the fabric-ca-client.

```bash
# install the binaries
go get -u github.com/hyperledger/fabric-ca/cmd/...

# check the version
fabric-ca-client version
```

## Check the installation
The build your first network (BYFN) scenario provisions a sample Hyperledger Fabric network consisting of two organizations, each maintaining two peer nodes. It also will deploy a "Solo" ordering service by default, though other ordering service implementations are available. To test your installationen we can start the network.

```bash
cd fabric-samples/first-network

# generate network artifacts
./byfn.sh generate

# bring up the network
./byfn.sh up

# show if some containers are running
docker ps

# bring down the network
./byfn.sh down
```