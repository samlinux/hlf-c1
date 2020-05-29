# Set up ca-orderer.morgen.net
The set up process can be divided into three parts:

1. Basic preparation
2. Creation of the CA admin 
3. Enrollment of the members

# (1) Basic preparation
## (1.1) Create the base folders
Frist we switch into the organisation folder and create the base folders, where our CA is living.

```bash
cd ca-orderer.morgen.net
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

fabric-ca-client enroll -d -u https://ca-orderer.morgen.net-admin:ca-orderer-adminpw@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'ca-orderer.morgen.net'

mv ca/client/tls-admin/msp/keystore/*_sk ca/client/tls-admin/msp/keystore/key.pem
```

>Important: The organization CA TLS signed certificate is generated under ca/client/admin/msp/signcert and the private key is available under ca/client/admin/msp/keystore. **When you deploy the organization CA you will need to point to the location of these two files in the tls section of the CA configuration .yaml file.** For ease of reference, you can rename the file in the keystore folder to key.pem.

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
    command: sh -c 'fabric-ca-server init -b ca-orderer.morgen.net-admin:ca-orderer-adminpw --port 7053'
    environment:
      - FABRIC_CA_SERVER_HOME=/tmp/hyperledger/fabric-ca/crypto
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_CSR_CN=ca-orderer.morgen.net
      - FABRIC_CA_SERVER_CSR_HOSTS=0.0.0.0
      - FABRIC_CA_SERVER_DEBUG=true
    volumes:
      - ./ca/server:/tmp/hyperledger/fabric-ca
    networks:
      - morgen
    ports:
      - 7053:7053
```

## (1.3) Initialise the CA
```bash
docker-compose up
```

The set up process is the same as for ca-tls.morgen.net. The only think we have to do is modify the fabric-ca-server-config.yaml and set the ca.name to ca-orderer.morgen.net. Then you can modify the docker-compose.yaml file and replace the init command with start.
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

vi docker-compose.yaml
```

## (1.4) Start the CA
Start the orderer ca and check if it is running.
```bash
docker-compose up -d
docker-compose ps
```

## (1.5) Copy the ca-orderer root certificate
We copy the ca-orderer server root ceritficate to the tls-orderer client folder for tls authentication.
This certificate is also known as the TLS CA’s signing certificate and it is going to be used to validate the TLS certificate of the CA.
```bash
# cp ./ca/server/crypto/ca-cert.pem ./ca/client/admin/tls-ca-cert.pem
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem ca/admin
```

## (1.6) Enroll the ca-orderer.morgen-net-admin - preparation
First we have to set two enviroments variables.
```bash
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-tls.morgen.net.cert.pem
```

## (1.7) Enroll the ca-orderer.morgen-net-admin - enrollement
```bash
fabric-ca-client enroll -d -u https://ca-orderer.morgen.net-admin:ca-orderer-adminpw@ca-orderer.morgen.net:7053  --csr.hosts 'ca-orderer.morgen.net'
```

## (1.8) Register the members of the network
We register the organization members for later useage.
```bash
# orderer
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererpw --id.type orderer -u https://ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'

# admin for the orderer
fabric-ca-client register -d --id.name admin-orderer.morgen.net --id.secret org0adminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'
````

# (2) Creation of the CA admin
After the preparation steps are done, we have to set up the admin user. The admin user is required to administrate this CA.

## (2.1) Create base folder
```bash
mkdir  -p admin/ca
````

## (2.2) Copy ca-cert file
Copy the ca-cert file to the admin folder.
```bash
#cp ./ca/server/crypto/ca-cert.pem ./admin/ca/orderer.morgen.net-ca-cert.pem
cp ../ca-tls.morgen.net/ca/client/crypto/ca-tls.morgen.net.cert.pem admin/ca
````

## (2.3) Enroll the admin - preparation
```bash
# we set needed environment vars
export FABRIC_CA_CLIENT_HOME=./admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca/ca-tls.morgen.net.cert.pem
export FABRIC_CA_CLIENT_MSPDIR=msp
````

## (2.4) Enrollment of the admin
```bash
fabric-ca-client enroll -d -u https://admin-orderer.morgen.net:org0adminpw@ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'
````

# (3) Setup the orderer

## (3.1) Preparetion
We create some assets folder for the orderer, these folders are used later at runtime
```bash
mkdir -p orderer/assets/ca
mkdir orderer/assets/ca-tls.morgen.net
````

## (3.2) Copy needed ca-certs
We copy two certificates to the assets folder. First the ca-cert.pem from the organization CA and second the ca-cert.pem from the TLS CA.
```bash
# ca-orderer ca-cert
cp ./ca/server/crypto/ca-cert.pem ./orderer/assets/ca/orderer.morgen.net-ca-cert.pem

# ca-tls ca-cert
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./orderer/assets/ca-tls.morgen.net/ca-tls.morgen.net.cert.pem

cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./admin/ca-tls.morgen.net.cert.pem
````

## (3.3) Preparation
We set two environment variables for the enrollment of the orderer.
```bash
export FABRIC_CA_CLIENT_HOME=./orderer
#export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca/orderer.morgen.net-ca-cert.pem
export FABRIC_CA_CLIENT_TLS_CERTFILES=./assets/ca-tls.morgen.net/ca-tls.morgen.net.cert.pem
````

## (3.4) Enroll the orderer
Since we have already registered the orderer as an identity, we can now enroll it (ca-orderer.morgen.net).

```bash
fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererpw@ca-orderer.morgen.net:7053 --csr.hosts 'orderer.morgen.net'
```

## (3.5) Enroll the orderer TLS
Since we have already registered the TLS for the orderer, we can now enroll it (ca-tls.morgen.net).

```bash
# set the required environment vars
export FABRIC_CA_CLIENT_MSPDIR=tls-msp
#export FABRIC_CA_CLIENT_TLS_CERTFILES=assets/ca-tls.morgen.net/tls-ca-cert.pem
export FABRIC_CA_CLIENT_TLS_CERTFILES=./assets/ca-tls.morgen.net/ca-tls.morgen.net.cert.pem

# enroll the tls profile of the orderer
fabric-ca-client enroll -d -u https://orderer.morgen.net:ordererPW@ca-tls.morgen.net:7052 --enrollment.profile tls --csr.hosts 'orderer.morgen.net'
````

## (3.6) Rename the orderers private key
We can rename the private key of the orderer for a possible later useage.
```bash
mv ./orderer/tls-msp/keystore/*_sk ./orderer/tls-msp/keystore/key.pem
````

# (4) Setup the MSP
The orderer as any other part of a fabric-network need a MSP.

## (4.1) Create base folder structure
```bash
mkdir -p msp/{admincerts,cacerts,tlscacerts,users}
````

## (4.2) Copy necessary certs
```bash
# organization ca-cert
cp ./ca/server/crypto/ca-cert.pem ./msp/cacerts/orderer.morgen.net-ca-cert.pem

# TLS ca-cert
#cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/tls-ca-cert.pem
cp ../ca-tls.morgen.net/ca/server/crypto/ca-cert.pem ./msp/tlscacerts/ca-tls.morgen.net.cert.pem

# organization admin cert
cp ./admin/msp/signcerts/cert.pem  ./msp/admincerts/orderer.morgen.net-admin-cert.pem
````

# (5) Create MSP config.yaml

```bash
cd orderer
vi msp/config.yaml
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
````
