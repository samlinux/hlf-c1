# How to use the Hyperledger Fabric Node SDK

To explain how you can use the Hyperledger Fabric Node SDK we can study the following picture to get an conceptual overview. In the picture below you can see the general building blocks of a web application which is interacting with a fabric network.

![Node.js SDK](../../img/nodeJs_1.png "Node.js SDK")


## (1) General requirements
For this example, we assume the following general requirements:

- a running Hyperledger Fabric network, version 1.4.6
- installed and instantiated chaincode

The set up of a fabric network and the installation of chaincode is out of the scope of this example.

## (2) Development set up
For you local or remote development platform you need the following elements:

- an editor of your choice e.g. Visual Studio Code, Atom, Sublime, etc.
- a running node.js installation
  - Node.js, version 10 is supported from 10.15.3 and higher
  - Node.js, version 12 is supported from 12.13.1 and higher 
  - npm tool version 6 or higher

## (3) General steps
The general steps to develop a Node.js application for a fabric network can be summarized as:

1. Create your project set up.
2. Get your application client identity from the organization CA.
   1.  receive an admin itentify from the CA to register an application client user
   2.  receive an application client user from the CA
3. Create a connection profile of the network. This is an important part we will focus later.
4. Develop a Node.js application e.g. an REST API Service with express.js to build a bridge between the blockchain network and the frontend application. 
5. Develop a frontend application for your end users. For example with Angular or a framework of your choice. In our case we are going to use some mocha tests to interact with the REST API.

### (3.1) Project set up
We create a folder where your project lives and switch into that.
```bash
mkdir mars-client-app
cd mars-client-app
```

We create a npm project like in every Node.js project.
```bash
npm init 
```
A package.json file is created and we are good to go.

As a next step we can install needed npm packages. 

>Attention only by fabric related packages we should use a particular node_module version. This is because we are running a fabric 1.4.6 network and for that reason we should use the corresponding node_module versions.

```bash
# packages for the application
npm install express --save
npm install fabric-ca-client@1.4.8 --save
npm install fabric-network@1.4.8 --save

# packages for testing the REST API
npm install mocha --save-dev
npm install supertest --save-dev
```

For a better development workflow we use nodemon to restart the application if we make changes to the source-code.
```bash
npm install nodemon -g
```

With these steps you project set up is ready and you have all neccessary packages installed.


### (3.2) Get your application client identity
As we have mentioned earlier to get a valid application client identity we have to process two steps. First enroll an admin identity from your organization CA and second register (enroll) a new application itentity. If you register a new client, the enrollment process is included in that step.

#### (3.2.2) Enroll the application user
To interact with the blockchain network, we have to register and enroll an application user. The script below register the user user1 and enroll his identity to out local wallet.

To enroll the application user the following approch is used.

First we define some enviroment vars.

```bash
cd ca-mars.morgen.net
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=ca-tls.morgen.net.cert.pem
```

We register the new user.
```bash
fabric-ca-client register -d --id.name user4-mars.morgen.net --id.secret marsUserPW --id.type client -u https://0.0.0.0:7054
```

We enroll the Node.js Application from ca-mars.morgen.net.

```bash
export FABRIC_CA_CLIENT_MSPDIR=msp
export FABRIC_CA_CLIENT_HOME=./users/user1-mars.morgen.net/
export FABRIC_CA_CLIENT_TLS_CERTFILES=../../ca/client/admin/ca-tls.morgen.net.cert.pem
```

```bash
fabric-ca-client enroll -d -u https://user1-mars.morgen.net:marsUserPW@ca-mars.morgen.net:7054 --csr.hosts '*.mars.morgen.net'

```

Add the new user to the wallet
```bash
# switch into the projectfolder
cd mars-client-app

# modify the add file addToWallet.js
# call the script
node addtoWallet.js
User user4-mars.morgen.net successfully adding to wallet.
```

#### (3.2.3) Modify the application users affiliation setting
In case the user has wrong affiliation settings, because of the reason that the chaincode uses Attribute-Based Access Control (ABAC) to protect to ledger, we can modify the client identitity to fit this need.

To do this we can follow this steps:

1. delete users crypto directory under the users directory and into the wallet directory as well
2. modify the affiliation of the user
3. enroll the user again
4. add the user to the application wallet again


#### (3.2.3.1) Delete existing crypto material for the user
```bash
# we switch into the organization folder
cd ca-mars.morgen.net

# delete the user crypto material
rm -R users/user4-mars.morgen.net

# delete the wallet data for the user
rm -R ../app/wallet/user4-mars.morgen.net
```

#### (3.2.3.1) Modify the affiliation of the user
To access the CA we need some enviroment vars.

```bash
export FABRIC_CA_CLIENT_HOME=./ca/client/admin
export FABRIC_CA_CLIENT_TLS_CERTFILES=tls-ca-cert.pem
```

We can display the current affiliation setting with the following command.

```bash
# check certs
openssl x509 -noout -text -in ./users/user4-mars.morgen.net/msp/signcerts/cert.pem
```

According to our chaincode sacc-abac to have write privileges we have to member of org1.departement1.

We can modify the client identity with the following command.

```bash
fabric-ca-client identity modify user4-mars.morgen.net --affiliation org1.department1
```

#### (3.2.3.2) Enroll the user again
```bash
fabric-ca-client enroll -d -u https://user4-mars.morgen.net:marsUserPW@0.0.0.0:7054

# check certs
openssl x509 -noout -text -in ./users/user4-mars.morgen.net/msp/signcerts/cert.pem
```

#### (3.2.3.3) Add the user to the wallet
Modify the addToWallet.js script in terms of the two vars user and pkFileName.

```bash
# modify this variables
let user = 'user4-mars.morgen.net'
let pkFileName = 'the_new_pk_sk';
```

Finally call the script again.
```bash
node ../app/addtoWallet.js
```

### (3.3) Create REST API
For our REST API we create the following file structure:
```bash
.
├── addtoWallet.js
├── connection-mars.morgen.net.json
├── index-query.js
├── index-set.js
├── index.js
├── node_modules
├── package-lock.json
├── package.json
└── wallet
```

