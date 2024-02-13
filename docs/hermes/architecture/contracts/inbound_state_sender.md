---
title: Inbound State Sender
---

## The Inbound State Sender Contract

The Inbound State Sender Contract is a specialized smart contract.
Its primary function is to assist developers of decentralized applications
(dApps) in transmitting state updates from the source chain to the Dojima Chain.
This contract operates on the source chain,
enabling transactions to be carried out from the source chain to the Dojima Chain.

To utilize the State Sender Contract, follow these straightforward steps:
### Step 1: Copy the Inbound State Sender Contract interface from GitHub

* Get the Inbound State Sender Contract Interface from the GitHub repository [here](https://github.com/dojimanetwork/dojima-evm-contracts/blob/main/contracts/interfaces/IInboundStateSender.sol).
* Copy the contract interface into its corresponding folder, typically located in, **'. /interfaces/'** or as per your project structure.

### Step 2: Obtain the Inbound State Sender Contract Address

* Retrieve the Inbound State Sender Contract address from the Dojima Chain Explorer.

**⚠️ Warning:** The Inbound State Sender Contract address may vary for different chains. Ensure that you select the appropriate chain i.e. (Ethereum, Avalanche) and the appropriate network i.e. (mainnet or testnet).

### Step 3: Register the Destination Contract
Before you can send state transaction to the Dojima Chain, you need to register the destination contract. This is done using the `register` function in the State Sender Contract. This function takes two parameters:

- `sender`: This is the address of the contract that is sending the state update. In most cases, this will be the address of your contract.
- `receiver`: This is the address of the contract that will receive the state update. This is what we call the destination contract.

> 
!!! warning

      **NOTE:** The registration process involves certain steps that need to be followed on the Dojima Chain Block Explorer. These steps will be added later.

### Step 4: Call the transferPayload function

* After registering the destination contract, you can now send state updates to it. This is done using the `transferPayload` function in the State Sender Contract. This function takes two parameters:

  - `destinationContract`: This is the address of the contract that will receive the state update. This is what we call the destination contract.
  - `payload`: This is the ABI-encoded contract call that you want to send to the destination contract.

> 
!!! warning 
    **DISCLAIMER:**Below provided code example is for educational purposes only. It is not intended for use in a production environment or with real assets. Please exercise caution and ensure proper testing and validation of your code before deploying it in a production environment.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Import the interface from the GitHub repository
import { IInboundStateSender } from './interfaces/IInboundStateSender.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract App {
    // Declare a variable to hold the address of the StateSender contract
    address public stateSender;
    uint256 public maxErc20Amount = 100 * (10**18);
    IInboundStateSender public stateSender;
    // Destination chain contract address (Polygon, Avalanche, etc.)
    address public destinationContract;
  
    constructor(address _stateSender, address _destContract) {
        // Create an instance of the IStateSender interface using the StateSender address
        stateSender = IInboundStateSender(_stateSender);
        require(_destContract != address(0), "Invalid destination contract address");
        destinationContract = _destContract;
    }
  
    function depositERC20(
        address _token,
        uint256 _amount
    ) public {
        require(_amount <= maxErc20Amount, "exceed maximum deposit amount");
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "TOKEN_TRANSFER_FAILED");
      
        // Call the transferPayload function
        stateSender.transferPayload(
          destinationContract, abi.encode(msg.sender, _token, _amount)
        );
    }
}
```

### Step 5: Event emitted by the State Sender Contract TokenTransferWithPayload
* Once the State Sender Contract executes the transferPayload function, it emits an event called DataTransfer. This event plays a vital role in the interaction with **Narada**.
* The DataTransfer event furnishes essential information in its parameters:
  * **depositID** - This identifier uniquely identifies deposits on the Dojima chain. It is relevant only when the destinationChain is **Dojima**.
  * **destinationContract** - It signifies the target contract to which the tokens and payload are delivered.
  * **payload** - This field holds the ABI-encoded contract call that was transmitted.