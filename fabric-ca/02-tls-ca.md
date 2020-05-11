## Create the Network Artifacts
As a frist step we create the CA Service for the tls.universe.at organization. The TLS CA will be responsible for providing TLS Certificate to the Network for TLS Authentication.

### tls.universe.at
To create a TLS CA the following can follow to following steps:

1. create the home directories for the CA
2. create the corresponding docker-compose file
3. start the CA
4. enroll the tls-ca-admin
5. register the peer and orderer itentities 