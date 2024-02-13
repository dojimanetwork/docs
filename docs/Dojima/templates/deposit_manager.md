---
title: Deposit Manager Template Documentation
---

[//]: # (---)

[//]: # (## Desposit Manager Template)

# Deposit Manager Template Documentation

## Introduction

The Deposit Manager contract template is a pivotal tool for Dojima Chain developers,
designed to facilitate cross-chain functionalities within decentralized applications (DApps).
It emphasizes the management of token deposits across different blockchain networks.

### Key Features:
- **Cross-Chain Token Management**: Efficiently tracks ERC20 tokens (or their equivalents) across multiple chains.
- **Deposit Tracking**: Employs unique IDs for each token deposit, alongside the token amount and address.
- **State Synchronization with Inbound State Sender**: Leverages inbound state sender for communicating from other chains to the Dojima Chain. 
- **Multi-Chain Compatibility**: While primarily designed for Ethereum, it's adaptable for additional blockchain integrations.

## Use Cases
- **Cross-Chain DApps Development**: Optimal for DApps that necessitate token fluidity across blockchain ecosystems.
- **Token Deposit Ledger**: Ideal for platforms that require an accurate and detailed record of token deposits.

## Prerequisites
- **Dojima Chain**: The Dojima chain is an EVM-based blockchain that stores all the cross-chain data. Read more about the Dojima chain [here](../hermes/architecture/dojimachain.md).
- **Destination Chain**: A destination chain will refer to all the chains that are connected to the Dojima chain.
The destination chain could be Ethereum, Solana, or any other chain that is connected to the Dojima chain.
  But it doesn't represent the origin of transaction. 
Transaction can originate either from Dojima chain or destination chain (Ethereum, Solana).
- **Hermes Client**: The Hermes client is essential for cross-chain communication between Destination and the Dojima Chain and vice versa. Read more about Hermes [here](../hermes/architecture/hermeschain.md).
- **Inbound State Sender**: The Inbound State Sender is a key component of the cross-chain data transfer.
It will be deployed on all the destination chains and will be responsible for facilitating the reception of encoded state
messages from destination chains to the Dojima Chain. Read more about inbound state sender and how to use it [here](../hermes/architecture/contracts/inbound_state_sender.md).
- **Root Token**: In the context of deposit manager contract, root token refers to any token on the destination chains.
- **Child Token**: In the context of deposit manager contract, child token refers to the root-tokens counterpart on the Dojima chain.
- **Child Chain**: The child chain refers to the contract that is deployed on the Dojima chain. It manages all the root token counterparts (child tokens) on the Dojima chain.

## Contract Overview
### ChildChain Contract (Dojima Chain)
Child chain contract will be deployed on the Dojima chain.
It is responsible for creating and managing child tokens on the Dojima chain. 
Each Root Token will have a corresponding child token on the Dojima chain.
The child token will be used to track the token balance of users on the Dojima chain.
The child token will be minted when a user deposits tokens on the Ethereum chain.
The child token will be burned when a user withdraws tokens from the Ethereum chain.

#### Key Functionalities
- **addToken**: Creates and maps a child token on the Dojima chain for a specific root token for the specified chain.
- **onStateReceive**: Executes the state sync process, minting tokens on the Dojima chain based on the incoming state information from the destination chains.
- **withdrawTokens**: Manages tokens' withdrawal requests, facilitating transfers back to the Destination chain.
- **_depositTokens**: Credits tokens on the Dojima chain based on the incoming state information.

### ChildERC20 and ChildToken Contracts
- Support ERC20 token functionalities on the Dojima chain, including standard and cross-chain transactions.

### DepositManager Contract (Destination Chains)
Deposit manager contract will be deployed on the destination chains (Ethereum, Solana, etc.).
It is responsible for managing the deposit of tokens on the destination chains.

#### Constructor
- Set up the contract with a specific chain name, establishing a cross-chain context.

#### Key Functions
- **updateChildChainAndStateSender**: Modifies the child chain and inbound state sender contract addresses.
- **deposit**: Facilitates the deposit of ERC20 tokens by users, accurately recording each transaction. It involves locking tokens 
in deposit manager and initiate a state sync process to deposit tokens in child chain contract.
  ```solidity
  inboundStateSender.transferPayload(
   _childChain,
   abi.encode(_chainName, _user, _token, _amount, _depositId)
  )
  ```
The transferPayload function in the depositBlock method has the following parameters:
  - **childChain**: The target child chain contract address on the dojima chain for the cross-chain transfer.
  - **balanceOf**: Retrieves the specific token balance for an account.
  - **abi.encode(_chainName, _user, _token, _amount, _depositId)**: This is the payload that is being transferred to the target blockchain. It's encoded using Ethereum's ABI (Application Binary Interface) encoding. The payload includes:
    - **_chainName**: The name of the chain where the tokens will be deposited.
      This will be same as the chain name passed to the constructor. 
      Basically the name of the chain where the deposit manager contract is deployed.
      In this case `Ethereum`.
    - **_user**: The address of the user who will receive the tokens on the target blockchain
    - **_token**: The address of the token contract(root token) on the destination blockchain.
    - **_amount**: The number of tokens to be transferred.
    - **_depositId**: This is a unique identifier for the deposit operation. The `depositId` could be used to track or identify individual deposit operations.

### Events
- **Deposit**: Announced upon a successful token deposit.
- **Withdrawal**: Announced during token withdrawal (yet to be implemented).

## System Integration

### InboundStateSender

- **Functionality**: The `InboundStateSender`'s `transferPayload` function is crucial in cross-chain communication. 
  It transmits the encoded state (chain name,user address, token amount, deposit ID) to the Dojima chain.
- **Usage in `transferToChain`**:

```solidity
  inboundStateSender.transferPayload(
   _childChain,
   abi.encode(_chainName, _user, _token, _amount, _depositId)
  )
```  

**Note**: Read more about inbound state sender and how to use it [here](../hermes/architecture/contracts/inbound_state_sender.md).

## Workflow
1. **Token Registration**: Utilizes `ChildChain.addToken` for mapping tokens on the Dojima chain.
2. **Token Deposit (Ethereum)**: Users make token deposits into the `DepositManager`.
3. **State Synchronization**: Encoded deposit data is sent to the Dojima chain for synchronization.
4. **Token Deposit (Dojima)**: `ChildChain` decodes the data, allocating tokens correspondingly.

## Interaction with Child Chain

The Deposit Manager ensures tokens deposited on Ethereum are mirrored on the Dojima Chain through:

- **Inbound State Sender**: Facilitates the reception of encoded state messages from Ethereum and other chains to the Dojima Chain, ensuring that deposit data is accurately transmitted for processing.
- **Token Minting on Dojima**: Upon receiving deposit data, the Child Chain mints equivalent child tokens, crediting them to the respective user's account on the Dojima Chain, maintaining consistency across chains.
- **Security and Verification**: The State Syncer Verifier, exclusive to the Dojima Chain, authenticates the incoming state messages, permitting the Child Chain to mint tokens securely.

## Security and Cautions
- **Accurate State Sender Address**: Essential verification of the state sender address for security.
- **Cross-Chain Protocol Security**: Evaluate the security measures of the Hermes bridge and related platforms.
- **Comprehensive Smart Contract Audits**: Essential to identify and mitigate potential vulnerabilities.
- **Robust User Authentication**: Critical for ensuring secure user interaction with the DApp.

## Conclusion
This template, alongside the Child Chain, establishes a foundational framework for developing cross-chain DApps, particularly for token transfers between Ethereum and the Dojima Chain. By leveraging this template, developers are equipped to enable streamlined and secure cross-chain token transfers, broadening the interoperability and utility of their applications.
