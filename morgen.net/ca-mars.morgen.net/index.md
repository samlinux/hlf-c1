# Set up ca-mars.morgen.net

The set up process can be divided into three parts:

1. Basic preparation
2. Creation of the CA admin 
3. Enrollment of the members

# (1) Basic preparation
## (1.1) Create the base folders
Frist we switch into the organisation folder and create the base folders, where our CA is living.

```bash
cd ca-mars.morgen.net
mkdir -p ca/server
mkdir -p ca/client/{admin,tls-admin}

# copy ca-tls cert for bootstrap ca identity
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/client/tls-admin

# copy ca-tls cert for admin ca admin identity
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/client/admin
```

We enroll the TLS identity for the organizations admin.
```bash
export FABRIC_CA_CLIENT_HOME=./ca/client/tls-admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=./ca-tls.morgen.net.cert.pem

fabric-ca-client enroll -d -u https://ca-mars.morgen.net-admin:ca-mars-adminpw@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'ca-mars.morgen.net'

mv ca/client/tls-admin/tls-msp/keystore/*_sk ca/client/tls-admin/tls-msp/keystore/key.pem
```

```bash
# modify fabric-ca-server config
vi ca/server/crypto/fabric-ca-server-config.yaml

# change - modify docker-compose.yaml file
#tls:
## Enable TLS (default: false)
#  enabled: true
## TLS for the server's listening port
#  certfile: /tmp/hyperledger/fabric-ca-client/tls-admin/msp/signcerts/cert.pem
#  keyfile: /tmp/hyperledger/fabric-ca-client/tls-admin/msp/keystore/key.pem

#ca:
  # Name of this CA
  # name: ca-mars.morgen.net

vi docker-compose.yaml
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
    command: /bin/bash -c 'fabric-ca-server init -b ca-mars.morgen.net-admin:ca-mars-adminpw --port 7054'
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

The set up process is the same as for ca-tls.morgen.net. The only think we have to do is modify the fabric-ca-server-config.yaml and set the ca.name to ca-mars.morgen.net. Then you can modify the docker-compose.yaml file and replace the **init** command with **start**.
```bash
# modify fabric-ca-server config
vi ca/server/crypto/fabric-ca-server-config.yaml

# modify docker-compose.yaml file
vi docker-compose.yaml
```

## (1.4) Start the CA
Start the orderer ca and check if it is running.
```bash
docker-compose up -d
docker-compose ps
```
## (1.5) Copy the ca-mars root certificate
We copy the ca-mars server root ceritficate to the tls-orderer client folder for tls authentication.
This certificate is also known as the TLS CA’s signing certificate and it is going to be used to validate the TLS certificate of the CA.

```bash
# cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/admin
```

## (1.5) Preparation
We set two environment variables.

```bash
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-tls.morgen.net.cert.pem
```

## (1.8) Enroll the organization admin 

```bash
fabric-ca-client enroll -d -u https://ca-mars.morgen.net-admin:ca-mars-adminpw@ca-mars.morgen.net:7054 --csr.hosts 'ca-mars.morgen.net'
```

## (1.9) Register the organization members
```bash
# peer0
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://ca-mars.morgen.net:7054 --csr.hosts 'peer0.mars.morgen.net'

# peer1
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://ca-mars.morgen.net:7054 --csr.hosts 'peer1.mars.morgen.net'

# an organization admin
fabric-ca-client register -d --id.name admin-mars.morgen.net --id.secret marsAdminPW --id.type admin -u https://ca-mars.morgen.net:7054 --csr.hosts '*.mars.morgen.net'

# an organization client user
fabric-ca-client register -d --id.name user1-mars.morgen.net --id.secret marsUserPW --id.type client -u https://ca-mars.morgen.net:7054 --csr.hosts '*.mars.morgen.net'
```

# (2) Set up admin  

## (2.1) Create the ca admin base folder
```bash
mkdir  -p admin/ca
```
## (2.2) Copy ca-cert file
```bash
# cp ./ca/server/crypto/ca-cert.pem ./admin/ca/mars.morgen.net-ca-cert.pem
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem admin/ca

```

## (2.3) Preparation
```bash
export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/ca-tls.morgen.net.cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
```

## (2.3) Enroll the admin
```bash
fabric-ca-client enroll -d -u https://admin-mars.morgen.net:marsAdminPW@ca-mars.morgen.net:7054 --csr.hosts '*.mars.morgen.net'
````

# (3) Set up peers

## (3.1) enroll peer0 

### (3.1.1) we create base peers folder
```bash
mkdir -p peers/peer0/assets/{ca,tls-ca}
```

#### (3.1.2) copy orgs root certificate to the peer
```bash
cp ./ca/server/crypto/ca-cert.pem ./peers/peer0/assets/ca/mars.morgen.net-ca-cert.pem
```

### (3.1.3) copying TLS-CA root certificate to the peer for tls authentication
```bash
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ./peers/peer0/assets/tls-ca/
```

#### (3.1.4) enroll the peer0 against ca from mars.morgen.net
```bash
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./peers/peer0/
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/ca-tls.morgen.net.cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@ca-mars.morgen.net:7054 --csr.hosts 'peer0.mars.morgen.net'
```

#### (3.1.5) peer0-mars.morgen.net enrolling with TLS-CA to get the tls certificate
```bash
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/tls-ca/ca-tls.morgen.net.cert.pem

fabric-ca-client enroll -d -u https://peer0.mars.morgen.net:peer0PW@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'peer0.mars.morgen.net'
```

#### (3.1.6) rename the private key from tls-ca
```bash
mv peers/peer0/tls-msp/keystore/*_sk peers/peer0/tls-msp/keystore/key.pem
```

## (3.2) Enroll peer1 

#### (3.2.1) we create base peers folder
```bash
mkdir -p peers/peer1/assets/{ca,tls-ca}
```

#### (3.2.2) copy orgs root certificate to the peer
```bash
cp ./ca/server/crypto/ca-cert.pem ./peers/peer1/assets/ca/mars.morgen.net-ca-cert.pem
```

#### (3.2.3) copying TLS-CA root certificate to the peer for tls authentication
```bash
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ./peers/peer1/assets/tls-ca/
```
tree

#### (3.2.4) enroll the peer1 against ca from mars.morgen.net
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
````

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

## (4.2) copying org mars root ca certificat to msp/cacerts directory
```bash
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/mars.morgen.net-ca-cert.pem
```

## (4.3) copying TLS CA root certificat to msp/tlscacerts directory
```bash
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ./peers/peer1/assets/tls-ca/
```

## (4.5) copying org mars admin singning certificat to msp/admincerts directory
```bash
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/mars.morgen.net-admin-cert.pem
```

# (5) config.yaml

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










