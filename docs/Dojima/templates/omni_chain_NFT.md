---
title: OmniChain NFT Template Documentation
---

[//]: # (---)

[//]: # (## Omnichain NFT Template)

# OmniChain NFT Template Documentation
## Introduction
The OmniChainNFT template provides a comprehensive framework for Dojima Chain developers to facilitate the cross-chain transfer of Non-Fungible Tokens (NFTs),
enabling seamless interoperability and utilization across various blockchain ecosystems.

### Key Features
 - **Cross-Chain NFT Transfers**: Allows for the seamless transfer of NFTs across different blockchain networks.
 - **State Synchronization** : Utilizes the outbound state sender for robust cross-chain communication. 
 - **Multi-Chain Compatibility**: Ensures NFTs are accessible and transferable across a wide range of blockchain networks.

## Use Cases
  - **Cross-Chain NFT Marketplaces**: Allows NFTs to be listed, bought, and sold across different blockchain marketplaces.
  - **NFT Collections**: Enables collectors to move their NFTs across chains, broadening the exposure and utility of their collections.

## Prerequisites
  - **Primary Chain**: The primary chain refers to the Dojima Chain.
  - **Secondary Chain**: The secondary chain refers to the chains other than the Dojima Chain. For example, Ethereum, Solana, Polkadot, etc.
  - **Source Chain**: The source chain refers to the chain from which the cross-chain transfer originates.
  - **Destination Chain**: A destination chain will refer to the chains where the cross-chain transfer will be received.
  - **Hermes Client**: Proficiency with the Hermes Client, a crucial component for enabling the communication between the Dojima Chain and other blockchains. The Hermes Client facilitates the secure and efficient transfer of state information across chains.
  - **Dojima Chain**: The Dojima chain is an EVM-based blockchain that stores all cross-chain data. Read more about the Dojima chain [here](../hermes/architecture/dojimachain.md).
  - **OutboundStateSender**: The OutboundStateSender contract will be used to send state updates from the primary chain (Dojima Chain) to the secondary chain (Ethereum, Solana, Polkadot).
  - **InboundStateSender**: The InboundStateSender contract will be used to send state updates from the secondary chain (Ethereum, Solana, Polkadot) to the primary chain (Dojima Chain).
  - **XNFTContract**: The XNFTContract is an ERC721 standard token contract that will be used for cross-chain NFT transfer.
    It will be deployed on the Dojima chain and will be used to track the NFTs' of users on the Dojima chain.
  - **CrossChainNFTContract**: This NFT contract will be deployed on the secondary chains (Ethereum, Solana, Polkadot, etc.).
    It will be used to manage the lifecycle of NFTs' on the secondary chain (Ethereum, Solana, Polkadot, etc.) network
    and will be able to communicate with OmniChainNFTContract through the Hermes Client.

## Contract Overview

### OmniChainNFTContract  
A pivotal contract deployed on the primary chain (Dojima Chain) to manage the lifecycle of NFTs during the cross-chain transfer process,
  including functionalities for burning and minting NFTs across chains.

#### Requirements
- **Outbound State Sender**: This is the contract address used to send updates from the primary chain (Dojima Chain) to the secondary chain (Ethereum, Solana, Polkadot).
- **OnStateReceive**: This function is responsible for receiving the state updates from the secondary chain and processing them on the Dojima Chain.

**⚠️ Warning:** Only State Syncer Verifier is allowed to call `onStateReceive` function on dojima chain contracts.
Syncer verifier is a system-controlled account with exclusive rights to mint tokens on the Dojima chain.

#### Key Functions:
- **transferToChain**: This function enables the transfer of NFT from the Dojima chain to other blockchains.
  It involves burning specified NFT on the Source Chain (Dojima chain)
  and initiates a state sync process to mint the same NFT on the destination chain.
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
    - `abi.encode(user, amount, depositId)`: This is the payload that is being transferred to the target blockchain. It's encoded using Ethereum's ABI (Application Binary Interface) encoding. The payload includes:
      - `user`: The address of the user who will receive the tokens on the destination chain
      - `amount`: The number of tokens to be transferred.
      - `depositID`: The `depositId` could be used to track or identify individual token transfer operations.
- **onStateReceive**:
  Executed by the `_stateVerifier` (Dojima system account),
  this function handles the minting of tokens on the primary chain (Dojima chain) based on the state received from other chains.
  It decodes the user address, amount, and deposit ID from the received encoded data.

#### Roles and Security:
- **_stateVerifier Role**: A system-controlled account with exclusive rights to mint NFTs' on the Dojima chain, ensuring security in the token minting process.
- **Security Concerns**: Robust error handling and transaction monitoring are essential to maintain integrity in cross-chain communication and prevent unauthorized minting or burning of tokens.

### XNFTContract
This contract represents the NFTs on the Dojima Chain, detailing their properties and providing functions for their management within the Dojima ecosystem.

### CrossChainNFT
Manages the lifecycle of NFTs' on the secondary chains (Ethereum, Solana, Polkadot, etc.).
And links with OmniChainNFTContract through the Hermes Client.
- **Burn**: The Contract will burn user NFT on the secondary chain (Ethereum, Solana, Polkadot etc.)
and will send the state update to the Dojima chain to mint the same NFT on the Dojima chain for the same user.
- **Minting**: The Contract will mint the NFT on the secondary chain based on the payload received from the Dojima chain by the `executeState` function.

#### Requirements
- **Inbound State Sender**: This is the contract address that is used to send updates from the secondary chain (Ethereum, Solana, Polkadot) to the primary chain (Dojima Chain).
- **ExecuteState**: This is a function that needs to be implemented in the secondary chain contract to process the state updates received from the primary chain (Dojima Chain).

**⚠️ Warning:** Only State Syncer Verifier is allowed to call `onStateReceive` function on dojima chain contracts.
Syncer verifier is a system-controlled account with exclusive rights to mint tokens on the Dojima chain.

### Workflow

#### Transfer From OmniChainERC20Contract to CrossChainERC20Contract
  - **Source Chain**: The source chain here is Dojima Chain (Primary Chain).
  - **Burning NFT for Transfer**: In `transferToChain`, NFT for the user are burned on the primary chain (Dojima chain) to initiate cross-chain transfer.
  - **Transfer Initiation**: NFT transfers are initiated on the Dojima Chain through the OmniChainNFTContract, specifying the NFT and its destination.
  - **State Synchronization**: The transfer's state is encoded and transmitted across chains via the Hermes Client, utilizing the outbound state sender for secure communication.
  - **Functionality**: The `OutboundStateSender`'s `transferPayload` function is crucial in cross-chain communication. It transmits the encoded state (user address, token amount, deposit ID) from the Dojima chain's OmniChainERC20Contract to the secondary chain (Ethereum, Solana, Polkadot, etc.) CrossChainNFT contracts.
    - **Usage in `transferToChain`**:
        ```solidity
        outboundStateSender.transferPayload(
            destinationChain,
            destinationContractAddress,
            msg.sender,
            abi.encode(user, tokenId, depositID)
        )
        ```

  **⚠️ Warning:**
    The `outboundStateSender` contract is very crucial for the cross-chain transfer make sure you follow the steps
    mentioned in the doc.

  - **After transfer payload**: Once above step is successfully executed on a primary chain (Dojima Chain) the state update will be sent to the secondary chains (Ethereum, Solana, Polkadot etc.).
  - **Minting on Destination Chain**: Upon receiving the state, the CrossChainNFT contract on the secondary chain will mint the NFT for the intended recipient, completing the cross-chain transfer.
    ```solidity
        function executeState(uint256 depositID, bytes calldata payload) external {
            // Decode the payload
            (address userAddress, uint256 tokenId, uint256 depositId) = abi.decode(
                stateData, (address, uint256, uint256)
            );
            // Mint the NFT for the user
            // Process the state update
        }
    ```
#### Transfer From CrossChainERC20Contract to OmniChainERC20Contract
    
  - **Destination Chain**: The destination chain here is Secondary Chains (Ethereum, Solana, Polkadot).
  - **Burn on Destination Chain**: The CrossChainNFT contract will burn the specified NFT for the user on the secondary chain.
  - **Transfer From Destination Chain**: Encode the payload (user address, tokenID, depositID) and transfer from the secondary chains (Ethereum, Solana, Polkadot etc.) to the Dojima chain through the Inbound State Sender
      - **Usage in `transferToOmniChain`**:
        ```solidity
           function transferToOmniChain(bytes memory user, uint256 amount) external nonReentrant {
                _burn(tokenId);
                inboundStateSender.transferPayload(
                  omniChainContractAddress,
                  abi.encode(user, tokenId, depositID)
                );
            }
        ```
  - **After transfer payload**: Once above step is successfully executed on secondary chains (Ethereum, Solana, Polkadot etc.) the state update will be sent to the Dojima chain.
  - **State Receive on Source Chain**: Upon receiving the state,
    OmniChainERC20Contract which is on Dojima Chain will decode the user address, amount,
    deposit ID will mint the specified number of tokens for the intended recipient, completing the cross-chain transfer.
    and deposit IDand mints the XERC20 token for the user.

## Security and Best Practices
- **Smart Contract Audits**: Ensure comprehensive audits of all contracts involved in the NFT transfer process to identify and mitigate potential security risks.
- **Secure Communication Channels**: Utilize secure and verified communication channels for the transmission of state information between chains.
- **Role-Based Access Control**: Implement and strictly enforce role-based access control within contracts to prevent unauthorized actions.

## Conclusion
The OmniChainNFT Suite marks a significant advancement towards achieving seamless NFT interoperability across blockchain networks. By providing a standardized framework for cross-chain NFT transfers, it opens up new possibilities for NFT utilization and enhances the overall blockchain ecosystem's connectivity.




