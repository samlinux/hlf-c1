# Listen to HLF events with node.js
This article describes the different ways to listen to events emitted by a network using the fabric-sdk-node module release 1.4. In the course of this article we are going to develop a node.js application which deals with the different event types.


## Overview
Basicly there are three event types that can be subscribed to:

- **Contract events**; Those emitted explicitly by the chaincode developer within a transaction.
- **Transaction (Commit) events**; Those emitted automatically when a transaction is committed after an invoke.
- **Block events**; Those emitted automatically when a block is committed.

## Requirements
To follow this article you need two things: 
1. A running hyperledger-fabric network ready to install some chaincode and
2. a proper node.js installation.

Since we are building a node.js application, we need a few preparation steps. First we set up the project.

```bash 
mkdir app03 && cd app03
npm init
```

Add the following dependencies to your packages.json file.
```bash
"dependencies": {
  "express": "^4.17.1",
  "fabric-ca-client": "^1.4.8",
  "fabric-network": "^1.4.8"
}
``` 

Install needed dependencies.
```bash
npm install
```

Set up you connection profile according to you network. You can find <a href="https://github.com/samlinux/hsc-lte/blob/master/marsConnection.yaml" target="_blank">here</a> a demo connecting profile.

## Examples

- <a href="https://github.com/samlinux/hsc-lte/blob/master/index.js" target="_blank">Query the ledger</a>;<br>As a starter we can test your node.js application if it is running.
- <a href="https://github.com/samlinux/hsc-lte/blob/master/contractEvents.js" target="_blank">Listen to chaincode events</a><br>To implement a contract event we have to modify the chaincode to emit an event. After that we can listen to this event within the node.js application.
- <a href="https://github.com/samlinux/hsc-lte/blob/master/blockEvent.js" target="_blank">Listen to block events</a><br>If a new block is created we can listen to this event.
- <a href="https://github.com/samlinux/hsc-lte/blob/master/transactionEvent.js" target="_blank">Listen to transaction events</a><br>We can wait until a transaction is successfully submitted to the network.

