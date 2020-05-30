# Set up ca-orderer.morgen.net
The first organisation we are going to set up is the orderer organisation. The set up process can be divided into following main steps:

1. basic preparation (including TLS certificate for the CA bootstrap identity, docker-compose set up and CA set up process)
2. the creation of the CA admin 
3. the enrollment of the organisation members

# (1) Basic preparation
## (1.1) Create the base folders
Frist we switch into the organisation folder and create the base folders.

```bash
cd ca-orderer.morgen.net
# the server base folder
mkdir -p ca/server

# the ca client folder for the admin and the tls-cert from the central tls-service
mkdir -p ca/client/{admin,tls-admin}
```

As a next step we are going the enroll the TLS certificate for the CAs bootstrap admin identity. This identity we have already registered in the set up process from the ca-tls.morgen.net organisation.

For this we have to copy the main TLS-CA cert to the both admin directories.

```bash
# copy ca-tls cert for bootstrap ca identity
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/client/tls-admin/

# copy ca-tls cert for admin ca admin identity
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/client/admin/
```

Now we can enroll the TLS identity for the organizations admin.
```bash
# set the needed environment vars
export FABRIC_CA_CLIENT_HOME=./ca/client/tls-admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=./ca-tls.morgen.net.cert.pem

# enroll the admin
fabric-ca-client enroll -d -u https://ca-orderer.morgen.net-admin:ca-orderer-adminpw@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'ca-orderer.morgen.net'

# rename admins private key for later CA configuration
mv ca/client/tls-admin/msp/keystore/*_sk ca/client/tls-admin/msp/keystore/key.pem
```

>**Important:** The organization CA TLS signed certificate is generated under ca/client/admin/msp/signcert and the private key is available under ca/client/admin/msp/keystore.<br><br>**When you deploy the organization CA you will need to point to the location of these two files in the tls section of the CA configuration .yaml file.** <br><br>For ease of reference, you can rename the file in the keystore folder to key.pem.

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
  ca-orderer.morgen.net:
    container_name: ca-orderer.morgen.net
    image: hyperledger/fabric-ca:1.4.4
    command: sh -c 'fabric-ca-server init -b ca-orderer.morgen.net-admin:${CaOrdererAminPw} --port 7053'
    environment:
      - FABRIC_CA_SERVER_HOME=/tmp/hyperledger/fabric-ca/crypto
      - FABRIC_CA_SERVER_CSR_CN=ca-orderer.morgen.net
      - FABRIC_CA_SERVER_CSR_HOSTS=ca-orderer.morgen.net
      - FABRIC_CA_SERVER_DEBUG=true
    volumes:
      - ./ca/server:/tmp/hyperledger/fabric-ca
      - ./ca/client:/tmp/hyperledger/fabric-ca-client
    networks:
      - morgen
    ports:
      - 7053:7053
```

To hide the bootstrap identity password we can use the docker-compose .env file functionality. As you can see in the command line above we use a docker-compose environment variable ${CaOrdererAminPw} for this. In order to get this working we need to create a .env file beside the docker-compose.yaml file.

```bash
# create the file
vi .env

# add the password in the format: var=value
CaOrdererAminPw=ca-orderer-adminpw
````
>**One note at this point**: It is not allowed to use signs like spaces ( ), hyphen
(-) or underlines (_) in the variable name.


## (1.3) Initialise the CA
To initialise the CA we start the CA with the following command. 
```bash
docker-compose up
```

>Note, we use the fabric-ca **init** command in docker-compose file. So to start the server finally we have to change the command from init to start.

The set up process is basically the same as for ca-tls.morgen.net. The only thing we have to do is modify the fabric-ca-server-config.yaml. After you have done this, you can modify the docker-compose.yaml file and replace the init command with start to start the CA finally.

```bash
# ------------------------------------------
# modify fabric-ca-server-config.yaml file
# ------------------------------------------
vi ca/server/crypto/fabric-ca-server-config.yaml

# tls:
#   # Enable TLS (default: false)
#   enabled: true
#   # TLS for the server's listening port
#   certfile: /tmp/hyperledger/fabric-ca-client/tls-admin/msp/signcerts/cert.pem
#   keyfile: /tmp/hyperledger/fabric-ca-client/tls-admin/msp/keystore/key.pem

# ca:
#   # Name of this CA
#   name: ca-orderer.morgen.net
```

```bash
# --------------------------------
# modify docker-compose.yaml file
# --------------------------------
vi docker-compose.yaml

# change the command parameter
command: sh -c 'fabric-ca-server start -b ca-orderer.morgen.net-admin:${CaOrdererAminPw} --port 7053'
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

## (1.5) Enroll the ca-orderer.morgen-net-admin - preparation
First we have to set two enviroments variables.
```bash
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-tls.morgen.net.cert.pem
```

## (1.7) Enroll the ca-orderer.morgen-net-admin - enrollement
After the environment variables are set we can enroll the ca-admin user for this particular organisation.
```bash
fabric-ca-client enroll -d -u https://ca-orderer.morgen.net-admin:ca-orderer-adminpw@ca-orderer.morgen.net:7053  --csr.hosts 'ca-orderer.morgen.net'
```
With these steps we have finally finished the set up process of the ca-orderer.morgen.net CA. Now the admin of this CA can start to interact with this CA to register members for this organization.

## (1.8) Register the members of the network
As a next step we register the organization members for a later usage. In this organization we are going to use two organization members:

1. one orderer node (we use the solo orderer system) and
2. one admin user for this orderer

The steps to enroll an identity are basically always the same:

1. We register an identity with the corresponding CA.
2. We enroll the identity.
3. If needed, we enroll the TLS identity with the corresponding TLS-CA. Note in our case we have already registered the orderer node TLS identity in previous steps.

Let's go and register the members.
```bash
# orderer node
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererpw --id.type orderer -u https://ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'

# admin for the orderer node
fabric-ca-client register -d --id.name admin-orderer.morgen.net --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'
````

# (2) Creation of the Orderer admin
Now we can set up the admin user for the orderer node. The admin user is required to administrate this orderer node.

## (2.1) Create base folder
We create an base folder for the orderer admin user.
```bash
mkdir  -p admin/ca
```

## (2.2) Copy TLS cert
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
fabric-ca-client enroll -d -u https://admin-orderer.morgen.net:org0adminpw@ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'
```

# (3) Setup the orderer

## (3.1) Preparetion
We create an assets folder for the orderer. This folder is used later at runtime and will mountend into the orderer container.

```bash
mkdir -p orderer/assets/ca
mkdir orderer/assets/ca-tls.morgen.net
```

## (3.2) Copy needed ca-certs
We copy two certificates to the orderers assets folder. 
1. the ca-cert.pem from the orderer organization CA and 
2. the ca-cert.pem from the TLS CA.

```bash
# ca-orderer ca-cert
cp ./ca/server/crypto/ca-cert.pem ./orderer/assets/ca/orderer.morgen.net-ca-cert.pem

# ca-tls ca-cert
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./orderer/assets/ca-tls.morgen.net/ca-tls.morgen.net.cert.pem

#cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./admin/ca-tls.morgen.net.cert.pem
```

## (3.3) Enroll the orderer

### (3.3.1) Set environment variables
We set two environment variables for the enrollment of the orderer.
```bash
export FABRIC_CA_CLIENT_HOME=./orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=./assets/ca-tls.morgen.net/ca-tls.morgen.net.cert.pem
```

### (3.3.2) Enroll the orderer
Since we have already registered the orderer as an identity, we can now enroll it (ca-orderer.morgen.net).

```bash
fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererpw@ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'
```

### (3.3.3) Enroll the orderer TLS
Since we have already registered the TLS identity for the orderer, we can now enroll it (ca-tls.morgen.net).

```bash
# set the required environment vars
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=./assets/ca-tls.morgen.net/ca-tls.morgen.net.cert.pem

# enroll the tls profile of the orderer
fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererPW@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'orderer.morgen.net'
```

### (3.3.4) Rename the orderers private key
We can rename the private key of the orderer for a possible later useage.
```bash
mv ./orderer/tls-msp/keystore/*_sk ./orderer/tls-msp/keystore/key.pem
```

# (4) Setup the MSP
The orderer as any other part of a fabric-network need a Membership Service Provider (MSP). We create that as a last step in the set up process of the orderer. In this steps we are going to copy the created certifcates to the right place.

## (4.1) Create base folder structure
The MSP has a fixed folder structure which we can create with the following command.
```bash
mkdir -p msp/{admincerts,cacerts,tlscacerts,users}
```

## (4.2) Copy necessary certs
```bash
# organization ca-cert
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/orderer.morgen.net-ca-cert.pem

# TLS ca-cert
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/ca-tls.morgen.net.cert.pem

# organization admin cert
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/orderer.morgen.net-admin-cert.pem
```

# (5) Identity Classification
For identity classification we have to set up the config.yaml file in a given MSP folder.

```bash
# create the config.yaml file
vi orderer/msp/config.yaml

# add the following content
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/orderer.morgen.net-ca-cert.pem
    OrganizationalUnitIdentifier: orderer
```
