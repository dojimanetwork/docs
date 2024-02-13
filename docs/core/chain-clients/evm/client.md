---
title: Client
---

### Introduction
The EVM (Ethereum Virtual Machine) client is a crucial component designed to facilitate interactions between EVM-compatible chains and the Dojima chain. It is responsible for processing transactions initiated by users and forwarding them to the Dojima chain. Additionally, it receives state updates from the Dojima chain and relays them to the destination chain.  The EVM client is particularly useful for handling all interactions that occur on EVM-related chains, such as transactions from AVAX C-chain to Dojima or vice versa.  

### Architecture
The EVM client is composed of two main services: 
 - Listener service
 - Parser service.  

## Listener Service
The Listener service is responsible for monitoring all events emitted by EVM-related contracts, including the State Sender contract, Outbound State Sender contract, and Router contract. It filters out the relevant events and forwards them to the Parser service for further processing.  

## Parser Service
The Parser service takes the events forwarded by the Listener service, parses these events, and sends them in batches to the Observer. The Observer then processes these batches further.  This architecture allows the EVM client to efficiently handle a large volume of transactions and state updates, ensuring that all relevant data is accurately relayed between the source chain, the Dojima chain, and the destination chain.

### Usage
To use the EVM client, you need to initiate a transaction or a state update on an EVM-compatible chain. The Listener service of the EVM client will automatically detect the event emitted by the transaction or state update. It will filter out the relevant events and forward them to the Parser service.  The Parser service will then parse these events and send them in batches to the Observer. The Observer will process these batches and update the state of the Dojima chain or the destination chain accordingly.  By using the EVM client, you can ensure that all interactions between EVM-compatible chains and the Dojima chain are handled efficiently and accurately.