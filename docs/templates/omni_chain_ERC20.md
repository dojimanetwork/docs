---
title: OmniChain ERC20 Template Documentation
---

[//]: # (---)

[//]: # (## Omnichain ERC20 Template)

# OmniChain ERC20 template Documentation

## Introduction

The OmniChain ERC20 template is a pivotal tool for Dojima Chain developers,
facilitating the seamless transfer and management of a token across different blockchain networks,
including Ethereum, Solana, and others.

### Key Features:
- **Cross-Chain Transfer**: Enables the transfer of tokens from the Dojima chain to other blockchains.
- **State Synchronization with Outbound State Sender**: Leverages outbound state sender for communicating from the Dojima Chain to other chains.
- **Multi-Chain Compatibility**: It allows user to transfer tokens from the Dojima chain to any other chain that is connected to the Dojima chain.

## Use Cases
- **Cross-Chain DApps Development**: Optimal for DApps that necessitate token fluidity across blockchain ecosystems.
- **Multi-Chain Token Management**: Ideal for platforms that require a single token to be used across multiple blockchains.

## Prerequisites
- **Primary Chain**: The primary chain refers to the Dojima Chain.
- **Secondary Chain**: The secondary chain refers to the chains other than the Dojima Chain. For example, Ethereum, Solana, Polkadot, etc.
- **Dojima Chain**: The Dojima chain is an EVM-based blockchain that stores all cross-chain data. Read more about the Dojima chain [here](../hermes/architecture/dojimachain.md).
- **Source Chain**: The source chain refers to the chain from which the cross-chain transfer originates. In the context of the OmniChainERC20Contract, the source chain is the Dojima chain.
- **Destination Chain**: A destination chain will refer to all the chains that are connected to the Dojima chain.
  The destination chain could be Ethereum, Solana, or any other chain that is connected to the Dojima chain.
  It doesn't represent the origin of transaction.
- **Hermes Client**: The Hermes client is essential for cross-chain communication between the destination and the Dojima Chain and vice versa. Read more about Hermes [here](../hermes/architecture/hermeschain.md).
- **Outbound State Sender**: The Outbound State Sender is a key component of the cross-chain data transfer.
  It will be deployed on the Dojima chain and will be responsible
  for facilitating the transmission of encoded state messages from the Dojima chain to destination chains.
  Read more about outbound state sender and how to use it [here](../hermes/architecture/contracts/outbound_state_sender.md).
- **XToken**: The XToken is an ERC20 token that will be used for cross-chain transfer.
  It will be deployed on the Dojima chain and will be used to track the token balance of users on the Dojima chain.
- **CrossChainERC20Contract**: This token contract will be deployed on the Ethereum chain.
  It will be used to manage the lifecycle of ERC20 tokens on the secondary chains (Ethereum, Solana, Polkadot, etc.).
  and will be able to communicate with OmniChainERC20Contract through the Hermes Client.

## Contract Overview
### OmniChainERC20Contract
Omni chain ERC20 contract is a standard ERC20 contract deployed on the Dojima chain.
It is responsible for the minting and burning of XToken on the Dojima chain.
It facilitates the transfer of XTokens from the Dojima chain to other chains.

#### Requirements
- **Outbound State Sender**: This is the contract address that is used to send updates from the primary chain (Dojima Chain) to the Secondary Chain (Ethereum, Solana, Polkadot etc.). 
- **OnStateReceive**: This is a function that needs to be implemented in the primary chain (Dojima Chain) to process the state updates received from the secondary chain contract.

**⚠️ Warning:** Only State Syncer Verifier is allowed to call `onStateReceive` function on dojima chain contracts. 
Syncer verifier is a system-controlled account with exclusive rights to mint tokens on the Dojima chain.

#### Key Functions:
- **transferToChain**: This function enables the transfer of tokens from the Dojima chain to other blockchains. 
  It involves burning tokens on the Source Chain (Dojima chain)
  and initiates a state sync process to mint destination chain token.
  ```solidity
      function transferToChain(
        bytes32 destinationChain,
        bytes memory user,
        uint256 amount,
        bytes memory destinationContractAddress
    ) external nonReentrant {
        _burn(msg.sender, amount); 
      outboundStateSender.transferPayload(
        destinationChain,
        destinationContractAddress,
        refundAddress,
        abi.encode(user, amount, depositID)
      );
    }
  ```
    The transferPayload function in the transferToChain method has the following parameters:
    - `destinationChain`: The destination chain will be either Ethereum, Polkadot, Solana etc. for the cross-chain transfer. Basically the name of the secondary chains where we want to send the state update.
    - `destinationContractAddress`: This is the address of the contract on the secondary chain (Ethereum, Polkadot, Solana etc.) that will receive, decode and process the payload. It's usually the address of a smart contract that has a function to handle such incoming payloads.
    - `refundAddress`: This is the address of the entity on the primary chain (Dojima Chain) `usually a user address or another contract` that will be receiving the refund if the state update fails.
    - `abi.encode(user, amount, depositID)`: This is the payload that is being transferred to the target blockchain. It's encoded using Ethereum's ABI (Application Binary Interface) encoding. The payload includes:
        - `user`: The address of the user who will receive the tokens on the destination chain
        - `amount`: The number of tokens to be transferred.
        - `depositID`: The `depositId` could be used to track or identify individual token transfer operations.
- **onStateReceive**:
  Executed by the `_stateVerifier` (Dojima system account),
  this function handles the minting of tokens on the Dojima chain based on the state received from other chains. 
  It decodes the user address, amount, and deposit ID from the received encoded data.

#### Roles and Security:
- **_stateVerifier Role**: A system-controlled account with exclusive rights to mint tokens on the Dojima chain, ensuring security in the token minting process.
- **Security Concerns**: Robust error handling and transaction monitoring are essential to maintain integrity in cross-chain communication and prevent unauthorized minting or burning of tokens.

### XERC20Contract
This contract represents the ERC20 tokens on the Dojima Chain,
detailing their properties and providing functions for their management within the Dojima ecosystem.

### CrossChainERC20Contract
Manages the lifecycle of ERC20 tokens on the secondary chains (Ethereum, Solana, Polkadot, etc.).
And links with OmniChainERC20Contract through the Hermes Client.
The total supply of the token will be minted on during the contract initialization.
- **Burn**: The Contract will burn user token on the secondary chain (Ethereum, Solana, Polkadot etc.)
  and will send the state update to the Dojima chain to mint the XERC20 token on the Dojima chain for the user.
- **Minting**: The Contract will mint the ERC20 on the secondary chain based on the payload received from the Dojima chain by the `executeState` function.

#### Requirements
- **Inbound State Sender**: This is the contract used to send updates from the secondary chain (Ethereum, Solana, Polkadot etc.) to the primary chain (Dojima Chain).
- **ExecuteState**: This is a function that needs to be implemented in the secondary chain contract to process the state updates received from the primary chain (Dojima Chain).

**⚠️ Warning:**
Only State Inbound State Sender contract address is allowed to call `executeState` function on secondary chains
(Ethereum, Solana, Polkadot etc.).

### Workflow

#### Transfer From OmniChainERC20Contract to CrossChainERC20Contract
  - **Source Chain**: The source chain here is Dojima Chain (Primary Chain).  
  - **Transfer From Source**: ERC20 token transfers are initiated on the Dojima Chain through the OmniChainNFTContract, specifying the token amount, user address and destination contract address (CrossChainERC20 contract address).
  - **State Synchronization**: The transfer's state is encoded and transmitted across chains via the Hermes Client, utilizing the outbound state sender for secure communication.
    - **Functionality**: The `OutboundStateSender`'s `transferPayload` function is crucial in cross-chain communication. It transmits the encoded state (user address, token amount, deposit ID) from the Dojima chain's OmniChainERC20Contract to destination chain contracts.
    - **Significance**: Ensures the synchronization of token states across chains, triggering corresponding actions (burn or mint) in the connected contracts.
    - **Usage in `transferToChain`**:
      ```solidity
          outboundStateSender.transferPayload(
              destinationChain,
              destinationContractAddress,
              msg.sender,
              abi.encode(user, amount, depositID)
          )
      ```
  
    **⚠️ Warning:**
  The `outboundStateSender` contract is very crucial for the cross-chain transfer make sure you follow the steps
  mentioned in the doc.
   
    - **After transfer payload**: Once above step is successfully executed on a primary chain (Dojima Chain) the state update will be sent to the secondary chains (Ethereum, Solana, Polkadot etc.).
    - **Minting on Destination Chain**: Upon receiving the state, the CrossChainERC20 contract on the secondary chain will mint the specified number of tokens for the intended recipient through `executeState` function, completing the cross-chain transfer.
      ```solidity
          function executeState(uint256 depositID, bytes calldata payload) external {
              // Decode the payload
              (address userAddress, uint256 amount, uint256 depositId) = abi.decode(
                  stateData, (address, uint256, uint256)
              );
              // Mint the ERC20 token for the user
              // Process the state update
          }
      ```
      
#### Transfer From CrossChainERC20Contract to OmniChainERC20Contract
  - **Destination Chain**: The destination chain here is Secondary Chains (Ethereum, Solana, Polkadot).
  - **Burn on Destination Chain**: The CrossChainERC20 contract will burn the specified number of tokens for the user on the secondary chain.
  - **Transfer From Destination Chain**: Encode the payload (user address, amount, depositID) and transfer from the secondary chains (Ethereum, Solana, Polkadot etc.) to the Dojima chain through the Inbound State Sender 
  to mint the same amount of XERC20 token on the Dojima chain for the specified user.
    - **Usage in `transferToOmniChain`**:
      ```solidity
         function transferToOmniChain(bytes memory user, uint256 amount) external nonReentrant {
              _burn(senderAddress, amount);
              inboundStateSender.transferPayload(
                omniChainContractAddress,
                abi.encode(user, amount, depositID)
              );
          }
      ```
  - **After transfer payload**: Once above step is successfully executed on secondary chains (Ethereum, Solana, Polkadot etc.) the state update will be sent to the Dojima chain.  
  - **State Receive on Source Chain**: Upon receiving the state,
    OmniChainERC20Contract which is on Dojima Chain will decode the user address, amount,
    deposit ID will mint the specified number of tokens for the intended recipient, completing the cross-chain transfer.
  and deposit IDand mints the XERC20 token for the user.

## Security and Best Practices

- **Audit Compliance**: Ensure all contracts undergo thorough security audits.
- **Transaction Monitoring**: Implement systems to monitor and verify cross-chain transactions regularly.
- **Role Management**: Strictly manage role assignments, especially for critical roles like `_stateVerifier`.
- **Gas Optimization**: Aim for efficiency in contract execution to minimize transaction costs.

## Conclusion
The OmniChainERC20Contract Suite represents a significant step towards seamless blockchain interoperability, with a focus on security, efficiency, and developer-friendliness. It is crucial for developers to understand the intricacies of the suite to leverage its full potential in their DApp development.