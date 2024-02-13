---
title: Outbound State Sender
---

## The Outbound State Sender Contract

The Outbound State Sender Contract is a specialized smart contract. 
Its primary function is to assist developers of decentralized applications (dApps) in transmitting state updates and  
asset transfer from the Dojima Chain to the destination chain.
This contract operates on the dojima chain,
enabling transactions to be carried out from the Dojima Chain to the destination chain.

To utilize the State Sender Contract, follow these straightforward steps:
### Step 1: Copy the Inbound State Sender Contract interface from GitHub

* Get the Outbound State Sender Contract Interface from the GitHub repository [here](https://github.com/dojimanetwork/dojima-evm-contracts/blob/main/contracts/interfaces/IOutboundStateSender.sol).
* Copy the contract interface into its corresponding folder, typically located in, **'. /interfaces/'** or as per your project structure.

### Step 2: Obtain the Outbound State Sender Contract Address

* Retrieve the Outbound State Sender Contract address from the Dojima Chain Explorer.

### Step 3: Register the Destination Contract, Destination Asset and Destination Chain

Before you can send a state transaction or asset transaction to the destination chain,
you need to make sure that everything is registered.

* To use **transferPayload** function, you need to make sure that the following things are registered:
  - **Destination Contract**: This is the address of the contract that will receive the state update.
  - **Destination Chain**: This is the name chain that will receive the state update. 
  - Steps to register destination address and chain: 

!!! warning
    **NOTE:** The registration process involves certain steps that need to be followed on the Dojima Chain Block Explorer.

* To use **transferAsset** function, you need to make sure that the following things are registered:
  - **Destination Address**: This is the address of the user that will receive the transferred asset.
  - **Destination Asset**: This is the address of the asset that will be transferred to the destination chain.
  - **Destination Chain**: This is the name chain that will receive the asset update. 
  - Steps to register destination address, asset and chain:

!!! warning 
      **NOTE:** The registration process involves certain steps that need to be followed on the Dojima Chain Block Explorer. These steps will be added later.

### Step 4: Calling the functions to transfer payload and asset

* Once you have registered all the details, you can now send state updates or transfer asset to the destination chain. This is done using the `transferPayload` and `transferAsset` functions in the Outbound State Sender Contract.
* Fees for both function calls will be deducted from the caller's (in this case contract) account in the form of Dojima tokens. The caller needs to make sure that they have enough Dojima tokens in their account to pay the fees.
* `Transfer Payload` function takes four parameters:
  - **Destination Chain**: This is the name of the destination chain in `bytes32` format, that will receive the state update.
  - **Destination Contract**: This is the address of the contract in `bytes` format, that will receive the state update on a destination chain.
  - **Refund Address** : This is the address of the user in `ETH address format` that will receive the refund if the transaction fails.
  - **Payload**: This is the `abi encoded` contract call that in `bytes format` you want to send to the destination contract.
    - **Note**: The payload should be encoded as per the destination contract function.

* `Transfer Asset` function takes five parameters:
  - **Destination Chain**: This is the name of the destination chain in `bytes32` format, that will receive the asset.
  - **Destination Address**: This is the address of the user in `bytes` format, that will receive the asset on destination chain.
  - **Refund Address** : This is the address of the user in `ETH address format` that will receive the refund if the transaction fails.
  - **Destination Asset**: This is the address of the asset in `bytes` format that will be transferred to the destination chain.
  - **Asset Amount**: This is the amount of asset in `uint256` format that will be transferred to the destination chain.



!!! warning 
    **DISCLAIMER:**Below provided code examples is for educational purposes only. It is not intended for use in a production environment or with real assets. Please exercise caution and ensure proper testing and validation of your code before deploying it in a production environment.

* Example for how to use `transferPayload` function in contract-based chains:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Import the interface from the GitHub repository
import {IOutboundStateSender} from './interfaces/IOutboundStateSender.sol';
import {IERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ChildChain {

  // mapping for (withdraw ID => true/false)
  mapping(uint256 => bool) public withdraws;
  
  // outbound state sender contract
  IOutboundStateSender public outboundStateSender;

  constructor(address _outboundStateSender) {
    require(_outboundStateSender != address(0x0), 'Child Chain: Invalid OutboundStateSender address');

    // Create an instance of the IOutboundStateSender interface using the OutboundStateSender address
    outboundStateSender = IOutboundStateSender(_outboundStateSender);
  }
  /*
   * @notice withdrawTokens
   * @dev: amountOrTokenId: tokenId for ERC721 and amount for ERC20
   * @param user address for deposit
   * @param rootToken root token address
   * @param withdrawId
   */
  function withdrawTokens(
    address rootToken,
    address user,
    uint256 amountOrTokenId,
    uint256 withdrawId,
    bytes32 destinationChain,
    bytes memory destinationContract
  ) public onlyOwner {
    // check if withdrawal happens only once
    require(withdraws[withdrawId] == false, 'Child Chain: already withdrawal for the given Id');

    // set withdrawal flag
    withdraws[withdrawId] = true;

    // Create an instance of the ERC20Burnable contract
    IERC20Burnable erc20Token = IERC20Burnable(rootToken);

    // Burn the tokens from the user's account
    erc20Token.burn(amountOrTokenId);

    outboundStateSender.transferPayload(
      destinationChain,
      destinationContract,
      user,
      abi.encode(rootToken, user, amountOrTokenId, withdrawId)
    );
  }
}
```
* Example for how to use `transferAsset` function in account-based chains:
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
// Import the interface from the GitHub repository
import {IOutboundStateSender} from './interfaces/IOutboundStateSender.sol';
import {IERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ChildChain {
  // mapping for (withdraw ID => true/false)
  mapping(uint256 => bool) public withdraws;

  // outbound state sender contract
  IOutboundStateSender public outboundStateSender;

  constructor(address _outboundStateSender) {
    require(_outboundStateSender != address(0x0), 'Child Chain: Invalid OutboundStateSender address');

    // Create an instance of the IOutboundStateSender interface using the OutboundStateSender address
    outboundStateSender = IOutboundStateSender(_outboundStateSender);
  }
  /*
   * @notice withdrawTokens
   * @dev: amountOrTokenId: tokenId for ERC721 and amount for ERC20
   * @param user address for deposit
   * @param rootToken root token address
   * @param withdrawId
   */
  function withdrawTokens(
    bytes memory rootToken,
    address user,
    uint256 amountOrTokenId,
    uint256 withdrawId,
    bytes32 destinationChain,
    bytes memory destinationAddress,
    bytes memory destinationAsset
  ) public onlyOwner {
    // check if withdrawal happens only once
    require(withdraws[withdrawId] == false, 'Child Chain: already withdrawal for the given Id');

    // set withdrawal flag
    withdraws[withdrawId] = true;
  
      // Create an instance of the ERC20Burnable contract
      IERC20Burnable erc20Token = IERC20Burnable(address(rootToken));
  
      // Burn the tokens from the user's account
      erc20Token.burn(amountOrTokenId);
  
      outboundStateSender.transferAsset(
        destinationChain,
        destinationAddress,
        user,
        destinationAsset,
        amountOrTokenId
      );
  }
}
```