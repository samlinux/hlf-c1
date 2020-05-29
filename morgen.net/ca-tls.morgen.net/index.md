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
### (1.3.1) What does the CA server init command do?
The init command does not actually start the server but generates the required metadata if it does not already exist for the server:

- Sets the default the CA Home directory (referred to as FABRIC_CA_HOME in these instructions) to where the fabric-ca-server init command is run.
- Generates the default configuration file fabric-ca-server-config.yaml that is used as a template for your server configuration in the FABRIC_CA_HOME directory. We refer to this file throughout these instructions as the “configuration .yaml” file.
- Creates the TLS CA root signed certificate file ca-cert.pem, if it does not already exist in the CA Home directory. This is the self-signed root certificate, meaning it is generated and signed by the TLS CA itself and does not come from another source. This certificate is the public key that must be shared with all clients that want to transact with any node in the organization. When any client or node submits a transaction to another node, it must include this certificate as part of the transaction.
- Generates the CA server private key and stores it in the FABRIC_CA_HOME directory under /msp/keystore.
- Initializes a default SQLite database for the server although you can modify the database setting in the configuration .yaml file to use the supported database of your choice. Every time the server is started, it loads the data from this database. If you later switch to a different database such as PostgreSQL or MySQL, and the identities defined in the registry.identites section of the configuration .yaml file don’t exist in that database, they will be registered.
- Bootstraps the CA server administrator, specified by the -b flag parameters <ADMIN_USER> and <ADMIN_PWD>, onto the server. When the CA server is subsequently started, the admin user is registered with the admin attributes provided in the configuration .yaml file registry section. If this CA will be used to register other users with any of those attributes, then the CA admin user needs to possess those attributes. In other words, the registrar must have the hf.Registrar.Roles attributes before it can register another identity with any of those attributes. Therefore, if this CA admin will be used to register the admin identity for an Intermediate CA, then this CA admin must have the hf.IntermediateCA set to true even though this may not be an intermediate CA server. The default settings already include these attributes.

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
Copy the TLS CA root certificate file ca-cert.pem, that was generated when the TLS CA server was started, to a new file name ca-tls.morgen.net.cert.pem. Notice the file name is changed to ca-tls.morgen.net.cert.pem to make it clear this is the root certificate from the TLS CA. Important: This TLS CA root certificate will need to be available on each client system that will run commands against the TLS CA.

```bash
cp ./ca/server/crypto/ca-cert.pem  ./ca/client/crypto/ca-tls.morgen.net.cert.pem
````

## (1.7) Enroll the ca admin - preparation
To enroll the root-tls-ca admin, we have to set the following evironment variables.

```bash
export FABRIC_CA_CLIENT_HOME=./ca/client
export FABRIC_CA_CLIENT_TLS_CERTFILES=crypto/ca-tls.morgen.net.cert.pem
````

## (1.8) Enroll ca-tls.morgen-net-admin
```bash
fabric-ca-client enroll -d -u https://ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw@ca-tls.morgen.net:7052 --csr.hosts 'ca-tls.morgen.net'
````

## (1.9) Register tls members of the network 
Based on the given network structure we register our network members (peers and orderer) to provide TLS communication between the single nodes.
```bash
# peer0
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://ca-tls.morgen.net:7052 --csr.hosts 'peer0.mars.morgen.net'

# peer 1
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://ca-tls.morgen.net:7052 --csr.hosts 'peer1.mars.morgen.net'

# orderer
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererPW --id.type orderer -u https://ca-tls.morgen.net:7052 --csr.hosts 'orderer.morgen.net'

# register ca-orderer.morgen.net organization CA bootstrap identity with the TLS-CA
fabric-ca-client register -d --id.name ca-orderer.morgen.net-admin --id.secret ca-orderer-adminpw -u https://ca-tls.morgen.net:7052 --csr.hosts 'ca-orderer.morgen.net'

# register ca-mars.morgen.net organization CA bootstrap identity with the TLS-CA
fabric-ca-client register -d --id.name ca-mars.morgen.net-admin --id.secret ca-mars-adminpw -u https://ca-tls.morgen.net:7052 --csr.hosts 'ca-mars.morgen.net'
````


IP SANs (IP subject alternative names).


openssl x509 -noout -text -in /etc/letsencrypt/live/careorganise.com/fullchain.pem



