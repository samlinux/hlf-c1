## Network
In this example we are going to build the following fabric network. As you can see in the picture below our network will have three organizations.

1. tls.universe.at; this organization is responsible for providing the tls-ca for the network
2. orderer.universe.at; this organization is responsible for the underlyling ordering-service. In this szenario we are goning to use a solo orderer.
3. mars.universe.at; this is the only organization which is using the blockchain.

Each organization has it's one CA (Certificate Authority) and one channel is used.

## Projekt setup
To create such a network we would like to use the following basic file structure in your workspace.

```bash
mkdir -p network/{tls.universe.at,orderer.universe.at,mars.universe.at}
tree .
.
└── network
    ├── mars.universe.at
    ├── orderer.universe.at
    └── tls.universe.at
````
