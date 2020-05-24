# Set up ca-tls.morgen.net

## (1.1) Create the base folders
Frist we switch into the organisation folder and create the base folders, where our CA is living.
```bash
cd ca-tls.morgen.net
mkdir -p ca/server/crypto
mkdir -p ca/client/crypto
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
  ca-tls.morgen.net:
    container_name: ca-tls.morgen.net
    image: hyperledger/fabric-ca:1.4.6
    command: sh -c 'fabric-ca-server init -b ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw --port 7052'
    environment:
      - FABRIC_CA_SERVER_HOME=/tmp/hyperledger/fabric-ca/crypto
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_CSR_CN=ca-tls.morgen.net
      - FABRIC_CA_SERVER_CSR_HOSTS=0.0.0.0
      - FABRIC_CA_SERVER_DEBUG=true
    volumes:
      - ./ca/server:/tmp/hyperledger/fabric-ca
    networks:
      - morgen
    ports:
      - 7052:7052
```
The set up process of a fabric-ca is basicly divided into two step process. First we have to initialise the CA with the init command and second we have to start the CA with the start command.

The init command does not actually start the server but generates the required metadata if it does not already exist for the server.


## (1.3) Initialise the CA
```bash
docker-compose up
```

## (1.4) Modify the fabric-ca-server-config.yaml
First we have to give the $USER the right to change the config file.
```bash
sudo chown $USER ca/server/crypto/fabric-ca-server-config.yaml
```
The fabric-ca-server-config.yaml ist the main configuration file from the Fabric-CA Server. We have to pay particular attention to some points here. But for now we modify the ca.name attribute to ca-tls.morgen.net.
```bash
# modify the config file
vi ca/server/crypto/fabric-ca-server-config.yaml

# change this attribute
ca.name: ca-tls.morgen.net
```

>If you modified any of the values in the CSR block of the configuration yaml file, you need to delete the fabric-ca-server-tls/ca-cert.pem file and the entire fabric-ca-server-tls/msp folder.  These certificates will be re-generated when you start the CA server in the next step.

After this modification we can adjust the docker-compose.yaml file for the final start. We have to change the docker start command from init to start.
```bash
command: sh -c 'fabric-ca-server start -b ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw --port 7052'
```

## (1.5) Start the CA
After we have made all the adjustments, we can start the TLS-CA in the background with the following command. 
```bash
docker-compose up -d

# check the running container
docker-compose ps
      Name                     Command               State                Ports
---------------------------------------------------------------------------------------------
ca-tls.morgen.net   sh -c fabric-ca-server sta ...   Up      0.0.0.0:7052->7052/tcp, 7054/tcp
```
Now your TLS CA is up and running. The next step is to enroll the admin user for this CA and the registration of all TLS identities for this network.

## (1.6) Copy the ca-tls root certificate
We copy the ca-tls server root ceritficate to the tls-ca client folder for tls authentication.
This certificate is also known as the TLS CA’s signing certificate and it is going to be used to validate the TLS certificate of the CA.
```bash
cp ./ca/server/crypto/ca-cert.pem  ./ca/client/crypto/ca-tls.morgen.net.cert.pem
````

## (1.7) Enroll the ca admin - preparation
To enroll the ca admin, we have to set the following evironment variables.

```bash
export FABRIC_CA_CLIENT_HOME=./ca/client
export FABRIC_CA_CLIENT_TLS_CERTFILES=crypto/ca-tls.morgen.net.cert.pem
````
## (1.8) Enroll ca-tls.morgen-net-admin
```bash
fabric-ca-client enroll -d -u https://ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw@0.0.0.0:7052
````
## (1.9) Register tls members of the network 
Based on the given network structure we register our network members (peers and orderer) to provide TLS communication between the single nodes.
```bash
# peer0
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://0.0.0.0:7052

# peer 1
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://0.0.0.0:7052

# orderer
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7052
````





