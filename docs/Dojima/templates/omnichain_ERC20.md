---
title: OmniChainERC20Contract Suite Documentation
---

[//]: # (---)

[//]: # (## Omnichain ERC20 Chain)

# OmniChainTokenContract Suite Documentation

## Overview

The OmniChainTokenContract Suite is an advanced toolkit designed for the Dojima chain, facilitating the seamless transfer and management of tokens across multiple blockchain networks, including Ethereum, Solana, and others.

## Components

### OmniChainTokenContract

Acts as the central hub within the Dojima chain, managing the lifecycle of cross-chain tokens.

#### Key Functions:

- **transferToChain**: This function enables the transfer of tokens from the Dojima chain to other blockchains. It involves burning tokens on the Dojima chain and initiating a state sync process to mint corresponding tokens on the target chain.
  ```solidity
    outboundStateSender.transferPayload(
      destinationChain,
      destinationContractAddress,
      msg.sender,
      abi.encode(user, amount, 0) // TODO: add depositId
    )
  ```
  The transferPayload function in the transferToChain method has the following parameters:
  - `destinationChain`: The target chain for the cross-chain transfer.
  - `destinationContractAddress`: This is the address of the contract on the target blockchain that will receive and process the payload. It's usually the address of a smart contract that has a function to handle such incoming payloads.
  - `msg.sender`: This is the address of the entity (usually a user or another contract) that initiated the token transfer on the Dojima chain.
  - `abi.encode(user, amount, 0)`: This is the payload that is being transferred to the target blockchain. It's encoded using Ethereum's ABI (Application Binary Interface) encoding. The payload includes:
    - `user`: The address of the user who will receive the tokens on the target blockchain
    - `amount`: The amount of tokens to be transferred.
    - `0`: This is a placeholder for the `depositId`. It's currently set to `0` as indicated by the `TODO` comment. The `depositId` could be used to track or identify individual token transfer operations.
- **onStateReceive**: Executed by the `_stateVerifier` (Dojima system account), this function handles the minting of tokens on the Dojima chain based on the state received from other chains. It decodes the user address, amount, and deposit ID from the received encoded data.

#### Roles and Security:

- **_stateVerifier Role**: A system-controlled account with exclusive rights to mint tokens on the Dojima chain, ensuring security in the token minting process.

- **Security Concerns**: Robust error handling and transaction monitoring are essential to maintain integrity in cross-chain communication and prevent unauthorized minting or burning of tokens.

### XTokenContract

An ERC20 token contract on the Dojima chain, foundational for the cross-chain functionalities.

### EthereumCrossChainTokenContract

Manages the lifecycle of tokens on the Ethereum network and links with OmniChainTokenContract through the Hermes bridge.

## System Integration

### OutboundStateSender

- **Functionality**: The `OutboundStateSender`'s `transferPayload` function is crucial in cross-chain communication. It transmits the encoded state (user address, token amount, deposit ID) from the Dojima chain's OmniChainTokenContract to destination chain contracts.

- **Significance**: Ensures the synchronization of token states across chains, triggering corresponding actions (burn or mint) in the connected contracts.
- 
- **Usage in `transferToChain`**:
  ```solidity
  outboundStateSender.transferPayload(
      destinationChain,
      destinationContractAddress,
      msg.sender,
      abi.encode(user, amount, 0)
  )

- Read More about how to interact with [outbound state sender](../hermes/architecture/contracts/outbound_state_sender.md)

!!! warning **Note**: The `outboundStateSender` contract is very crucial for the cross chain transfer make sure you follow the steps mentioned in the doc.

## Contract Interaction Flow

1. **Burning Tokens for Transfer**: In `transferToChain`, tokens are burned on the Dojima chain to initiate cross-chain transfer.
2. **State Synchronization**: The burning triggers a state sync process via the Hermes bridge, sending encoded data to the target chain.
3. **Minting Tokens on Dojima**: In `onStateReceive`, tokens are minted on the Dojima chain for the specified user, amount, and deposit ID.

## Security and Best Practices

- **Audit Compliance**: Ensure all contracts undergo thorough security audits.
- **Transaction Monitoring**: Implement systems to monitor and verify cross-chain transactions regularly.
- **Role Management**: Strictly manage role assignments, especially for critical roles like `_stateVerifier`.
- **Gas Optimization**: Aim for efficiency in contract execution to minimize transaction costs.

## Conclusion

The OmniChainTokenContract Suite represents a significant step towards seamless blockchain interoperability, with a focus on security, efficiency, and developer-friendliness. It is crucial for developers to understand the intricacies of the suite to leverage its full potential in their DApp development.