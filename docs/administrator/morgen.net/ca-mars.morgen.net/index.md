# Set up ca-mars.morgen.net
The ca-mars.morgen.net organization is our main organization in this example. This organization runs the blockchain for hin own need. As we have seen the set up process for the CA is the same as we have done it already for the ca-orderer.morgen.net.

1. basic preparation (including TLS certificate for the CA bootstrap identity, docker-compose set up and CA set up process)
2. the creation of the CA admin 
3. the enrollment of the organisation members

# (1) Basic preparation
## (1.1) Create the base folders
Frist we switch into the organisation folder and create the base folders, where our CA is living.

```bash
cd ca-mars.morgen.net
mkdir -p ca/server
mkdir -p ca/client/{admin,tls-admin}
```

As a next step we are going the enroll the TLS certificate for the CAs bootstrap admin identity. This identity we have already registered in the set up process from the ca-tls.morgen.net organisation.

For this we have to copy the main TLS-CA cert to the both admin directories.

```bash
# copy ca-tls cert for bootstrap ca identity
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/client/tls-admin

# copy ca-tls cert for admin ca admin identity
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/client/admin
```

Now we can enroll the TLS identity for the organizations admin.
```bash
# set the needed environment vars
export FABRIC_CA_CLIENT_HOME=./ca/client/tls-admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=./ca-tls.morgen.net.cert.pem

# enroll the admin
fabric-ca-client enroll -d -u https://ca-mars.morgen.net-admin:ca-mars-adminpw@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'ca-mars.morgen.net'

# rename admins private key for later CA configuration
mv ca/client/tls-admin/tls-msp/keystore/*_sk ca/client/tls-admin/tls-msp/keystore/key.pem
```

## (1.2) Create docker-compose file

We create the following docker.compose.yaml file.
```bash
# create a new file
vi docker-compose.yaml 

# add the following content
version: "3.3"

networks:
  morgen:

services:
  ca-mars.morgen.net:
    container_name: ca-mars.morgen.net
    image: hyperledger/fabric-ca:1.4.6
    command: /bin/bash -c 'fabric-ca-server init -b ca-mars.morgen.net-admin:${CaMarsAdminPw} --port 7054'
    environment:
      - FABRIC_CA_SERVER_HOME=/tmp/hyperledger/fabric-ca/crypto
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_CSR_CN=ca-mars.morgen.net
      - FABRIC_CA_SERVER_CSR_HOSTS=ca-mars.morgen.net
      - FABRIC_CA_SERVER_DEBUG=true
    volumes:
      - ./ca/server:/tmp/hyperledger/fabric-ca
      - ./ca/client:/tmp/hyperledger/fabric-ca-client
    networks:
      - morgen
    ports:
      - 7054:7054
```
## (1.3) Initialise the CA
```bash
docker-compose up
```

The set up process is the same as for ca-tls.morgen.net. The only thing we have to do is modify the fabric-ca-server-config.yaml and set the ca.name to ca-mars.morgen.net. Then you can modify the docker-compose.yaml file and replace the **init** command with **start**.

```bash
# modify fabric-ca-server config
vi ca/server/crypto/fabric-ca-server-config.yaml

# change - modify docker-compose.yaml file
#tls:
## Enable TLS (default: false)
#  enabled: true
## TLS for the server's listening port
#  certfile: /tmp/hyperledger/fabric-ca-client/tls-admin/tls-msp/signcerts/cert.pem
#  keyfile: /tmp/hyperledger/fabric-ca-client/tls-admin/tls-msp/keystore/key.pem

#ca:
  # Name of this CA
  # name: ca-mars.morgen.net

# --------------------------------
# modify docker-compose.yaml file
# --------------------------------
vi docker-compose.yaml

# change the command parameter
command: sh -c 'fabric-ca-server start -b ca-orderer.morgen.net-admin:${CaMarsAdminPw} --port 7053'
```

## (1.4) Start the CA
After following the previous steps, we can start the orderer organisation CA.

```bash
# start the CA in the background
docker-compose up -d

# check it the CA is running
docker-compose ps

# check the logs
docker-compose logs
```

## (1.5) Enroll the ca-mars.morgen.net-admin - preparation
First we have to set two enviroments variables.
```bash
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-tls.morgen.net.cert.pem
```
## (1.6) Enroll the ca-orderer.morgen-net-admin - enrollement
After the environment variables are set we can enroll the ca-admin user for this particular organisation.
```bash
fabric-ca-client enroll -d -u https://ca-mars.morgen.net-admin:ca-mars-adminpw@ca-mars.morgen.net:7054 --csr.hosts 'ca-mars.morgen.net'
```
With these steps we have finally finished the set up process of the ca-orderer.morgen.net CA. Now the admin of this CA can start to interact with this CA to register members for this organization.


## (1.7) Register the members of the network

As a next step we register the organization members for a later usage. In this organization we are going to use following organization members:

1. two peer nodes and
2. one admin user for this organization
3. one client user for the node.js application

The steps to enroll an identity are basically always the same:

1. We register an identity with the corresponding CA.
2. We enroll this identity.
3. If needed, we enroll the TLS identity with the corresponding TLS-CA. Note in our case we have already registered the orderer node TLS identity in previous steps.

Let's go and register the members.

```bash
# peer0
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://ca-mars.morgen.net:7054 --csr.hosts 'peer0.mars.morgen.net'

# peer1
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer0PW --id.type peer -u https://ca-mars.morgen.net:7054 --csr.hosts 'peer1.mars.morgen.net'

# an organization admin
fabric-ca-client register -d --id.name admin-mars.morgen.net --id.secret marsAdminPW --id.type admin -u https://ca-mars.morgen.net:7054 --csr.hosts '*.mars.morgen.net'

# an organization client user
fabric-ca-client register -d --id.name user1-mars.morgen.net --id.secret marsUserPW --id.type client -u https://ca-mars.morgen.net:7054 --csr.hosts '*.mars.morgen.net'
```

# (2) Creation of the mars organization admin
Now we can set up the admin user for the mars organization nodes. The admin user is required to administrate the peer nodes of this organization.

## (2.1) Create base folder
We create an base folder for the orderer admin user.
```bash
mkdir  -p admin/ca
```

## (2.2) Copy ca-cert file
For TLS communication we copy the ca-tls.morgen.net.cert.pem file to the admin folder.

```bash
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem admin/ca
```

## (2.3) Enroll the admin
To enroll the orderer admin we have to do two steps

1. we need to set some environment variables
2. we enroll the admin

### (2.3.1) Set environment variables

```bash
# set needed environment vars
export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/ca-tls.morgen.net.cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
```
## (2.3.2) Enrollment of the admin
Enroll the orderer admin user.

```bash
fabric-ca-client enroll -d -u https://admin-mars.morgen.net:marsAdminPW@ca-mars.morgen.net:7054 --csr.hosts '*.mars.morgen.net'
```

# (3) Set up the peers

## (3.1) Enroll peer peer0.mars.morgen.net

### (3.1.1) Preparation
We create the following folderstructur for the peer. This folder is used later at runtime and will mountend into the each peer container.

```bash
mkdir -p peers/peer0/assets/{ca,tls-ca}
```

#### (3.1.2) Copy needed CA certs
```bash
# copy orgs root certificate to the peer
cp ./ca/server/crypto/ca-cert.pem ./peers/peer0/assets/ca/mars.morgen.net-ca-cert.pem

# copying TLS-CA root certificate to the peer for tls authentication
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ./peers/peer0/assets/tls-ca/
```

#### (3.1.3) Enroll peer0
Now we can enroll peer0 from the ca-mars.morgen.net CA.

```bash
# set the required environment vars
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer0/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/ca-tls.morgen.net.cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@ca-mars.morgen.net:7054 --csr.hosts 'peer0.mars.morgen.net'
```

#### (3.1.5) peer0-mars.morgen.net enrolling with TLS-CA to get the tls certificate
Now that we have enrolled the peer0 identity we also need to enroll the TLS identity for the peer.

```bash
# set the required environment vars
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/ca-tls.morgen.net.cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'peer0.mars.morgen.net'
```

#### (3.1.6) Rename the private key from tls-ca
We can rename the private key of the orderer for a possible later useage.
```bash
mv peers/peer0/tls-msp/keystore/*_sk peers/peer0/tls-msp/keystore/key.pem
```

## (3.2) Enroll peer1 
For peer1 we can do exactly the same enroll process as we did for peer0.

#### (3.2.1) Preparation
```bash
# we create peers folder
mkdir -p peers/peer1/assets/{ca,tls-ca}
```

#### (3.2.2) Copy needed CA certs
```bash
# copy orgs root certificate to the peer
cp ./ca/server/crypto/ca-cert.pem ./peers/peer1/assets/ca/mars.morgen.net-ca-cert.pem

# copying TLS-CA root certificate to the peer for tls authentication
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ./peers/peer1/assets/tls-ca/
```

#### (3.2.4) Enroll peer1
Now we can enroll peer1 from the ca-mars.morgen.net CA.

```bash
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer1/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/ca-tls.morgen.net.cert.pem

fabric-ca-client enroll -d -u https://peer1.mars.morgen.net:peer1PW@ca-mars.morgen.net:7054 --csr.hosts 'peer1.mars.morgen.net'
```

#### (3.2.5) peer1-mars.morgen.net enrolling with TLS-CA to get the tls certificate
```bash
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/ca-tls.morgen.net.cert.pem

fabric-ca-client enroll -d -u https://peer1.mars.morgen.net:peer1PW@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'peer1.mars.morgen.net'
```

#### (3.2.6) rename the private key from tls-ca
```bash
mv peers/peer1/tls-msp/keystore/*_sk peers/peer1/tls-msp/keystore/key.pem
```

# (4) Set up MSP
We have to set up the organization MSP.

## (4.1) Create base MSP folder
```bash
mkdir -p msp/{admincerts,cacerts,tlscacerts,users}
```

## (4.3)  Copy necessary certs

```bash
# copy org mars root ca certificat to msp/cacerts directory
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/mars.morgen.net-ca-cert.pem

#copy TLS CA root certificat to msp/tlscacerts directory
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ./peers/peer1/assets/tls-ca/

# copy org mars admin singning certificat to msp/admincerts directory
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/mars.morgen.net-admin-cert.pem
```

# (5) Identity Classification
For identity classification we have to set up the config.yaml file in a given MSP folder.

```bash
vi msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/mars.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: orderer
```

```bash
vi admin/msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: orderer
```

```bash
vi peers/peer0/msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: orderer
```

```bash
vi peers/peer1/msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: orderer
```
