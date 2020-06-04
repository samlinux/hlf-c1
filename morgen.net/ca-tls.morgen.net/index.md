# Set up ca-tls.morgen.net

## (1.1) Create the base folders
Frist we switch into the organisation folder and create some base folders for the ca-tls.morgen.net organisation. This organisation provides all required TLS certificates for the whole network.

```bash
cd ca-tls.morgen.net

# this is the CA base folder
mkdir -p ca/server/crypto

# this is for the ca admin
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
    command: sh -c 'fabric-ca-server init -b ca-tls.morgen.net-admin:${ca-tls.morgen.net-adminpw} --port 7052'
    environment:
      - FABRIC_CA_SERVER_HOME=/tmp/hyperledger/fabric-ca/crypto
      - FABRIC_CA_SERVER_CSR_CN=ca-tls.morgen.net
      - FABRIC_CA_SERVER_CSR_HOSTS=ca-tls.morgen.net
      - FABRIC_CA_SERVER_DEBUG=true
    volumes:
      - ./ca/server:/tmp/hyperledger/fabric-ca
    networks:
      - morgen
    ports:
      - 7052:7052
```
The set up process of a fabric-ca is basically divided into three steps. 
1. We have to initialise the CA with the init command.
2. We have to modify the fabric-ca-client-config.yaml file to fit our needs.
3. Lastly we can start the CA with the start command.

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
If it is needed give the $USER the right to modify the config file.
```bash
sudo chown $USER ca/server/crypto/fabric-ca-server-config.yaml
```
The fabric-ca-server-config.yaml ist the main configuration file from the Fabric-CA Server. We have to pay particular attention to some points here. But for now we modify the ca.name attribute to ca-tls.morgen.net.
```bash
# modify the config file
vi ca/server/crypto/fabric-ca-server-config.yaml

# modify these config parameters
# tls:
#   Enable TLS (default: false)
#   enabled: true
# ca:
#   name: ca-tls.morgen.net
```

>If you modified any of the values in the CSR block of the configuration yaml file, you need to delete the fabric-ca-server-tls/ca-cert.pem file and the entire fabric-ca-server-tls/msp folder.  These certificates will be re-generated when you start the CA server in the next step.

After this modification we can adjust the docker-compose.yaml file for the final start. We have to change the docker start command from init to start.
```bash
command: sh -c 'fabric-ca-server start -b ca-tls.morgen.net-admin:${ca-tls.morgen.net-adminpw} --port 7052'
```

## (1.5) Start the CA
After we have made all the adjustments, we can start the TLS CA in the background with the following command. 
```bash
docker-compose up -d

# check the running container
docker-compose ps
      Name                     Command               State                Ports
---------------------------------------------------------------------------------------------
ca-tls.morgen.net   sh -c fabric-ca-server sta ...   Up      0.0.0.0:7052->7052/tcp, 7054/tcp
```
Now your TLS CA is up and running. As a next step we can enroll the admin user for this dedicated TLS-CA and do the registration of all TLS identities for this network.

## (1.6) Copy the TLS CA root certificate
Copy the TLS CA root certificate file ca-cert.pem, that was generated when the TLS CA server was started, to a new file name ca-tls.morgen.net.cert.pem. Notice the file name is changed to ca-tls.morgen.net.cert.pem to make it clear this is the root certificate from the TLS CA. Important: This TLS CA root certificate will need to be available on each client system that will run commands against the TLS CA.

```bash
cp ./ca/server/crypto/ca-cert.pem  ./ca/client/crypto/ca-tls.morgen.net.cert.pem
```

## (1.7) Enroll the TLS-CA admin - preparation
To enroll the TLS CA admin, we have to set the following evironment variables. With these variables we point out where the fabirc-ca-client-home is based and where the tls certificates is located under the fabric-ca-client-home directory.

```bash
export FABRIC_CA_CLIENT_HOME=./ca/client
export FABRIC_CA_CLIENT_TLS_CERTFILES=crypto/ca-tls.morgen.net.cert.pem
```

## (1.8) Enrollment of the ca-tls.morgen-net-admin

```bash
fabric-ca-client enroll -d -u https://ca-tls.morgen.net-admin:ca-tls.morgen.net-adminpw@ca-tls.morgen.net:7052 --csr.hosts 'ca-tls.morgen.net'
```

## (1.9) Register TLS members of the network 
Based on the given network structure we register our network members (peers and orderer) to provide TLS communication between the single nodes.

In a further step we are register all CA bootstrap identities for this network against this TLS CA.

```bash
# register network nodes
## peer0
fabric-ca-client register -d --id.name peer0.mars.morgen.net --id.secret peer0PW --id.type peer -u https://ca-tls.morgen.net:7052 --csr.hosts 'peer0.mars.morgen.net'

## peer1
fabric-ca-client register -d --id.name peer1.mars.morgen.net --id.secret peer1PW --id.type peer -u https://ca-tls.morgen.net:7052 --csr.hosts 'peer1.mars.morgen.net'

## orderer
fabric-ca-client register -d --id.name orderer.morgen.net --id.secret ordererPW --id.type orderer -u https://ca-tls.morgen.net:7052 --csr.hosts 'orderer.morgen.net'

# register CA bootstrap identiies
## register ca-orderer.morgen.net organization CA bootstrap identity with the TLS-CA
fabric-ca-client register -d --id.name ca-orderer.morgen.net-admin --id.secret ca-orderer-adminpw -u https://ca-tls.morgen.net:7052 --csr.hosts 'ca-orderer.morgen.net'

## register ca-mars.morgen.net organization CA bootstrap identity with the TLS-CA
fabric-ca-client register -d --id.name ca-mars.morgen.net-admin --id.secret ca-mars-adminpw -u https://ca-tls.morgen.net:7052 --csr.hosts 'ca-mars.morgen.net'
````

## Terms
- CSR (certificate signing request)
- IP SANs (IP subject alternative names)

## Helper
- openssl x509 -noout -text -in file.pem



