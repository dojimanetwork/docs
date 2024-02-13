---
title: Transaction Memos
---
Transaction Memo Details

## Overview
A memo serves as additional data attached to a transaction, facilitating the communication of user intent to the Hermes Chain.
The memo field signifies the type of transaction being executed, such as SWAP, WITHDRAW, or RESERVE, among others.
Hermes Chain inspects the transaction object as well as the MEMO in order to process the transaction.
It is essential to ensure that both the memo and the transaction are valid; otherwise, Hermes Chain will automatically refund the assets.

Different chains employ various methods to include state information within a transaction. Long assets can be shortened using Asset abbreviations (below)
as well as Hermes Names to reduce the size of destination/affiliate addresses.

## Format

Memos follow the format:

`TYPE:PARAM1:PARAM2:PARAM3:PARAM4`

The type is invoked by a string, which in turn calls a particular handler in the state machine. The state machine parses the memo looking for the parameters which is simply decodes from human-readable strings. 

In addition, some parameters are optional. Simply leave them blank, but retain the `:` separator:

TYPE:PARAM1:::PARAM4

## Permitted Memos

The following memos are permitted:

1. **SWAP**
2. **ADD** Liquidity
3. **WITHDRAW** Liquidity
4. **BOND, UNBOND & LEAVE**
5. **DONATE & RESERVE**
6. **NOOP**

## Swap

Perform a swap.

**`SWAP:ASSET:DESTADDR:LIM:AFFILIATE:FEE`**

|Parameter  | Note           |Conditions   |
|---------- | -------------- |-------------|
|Payload    | Send the asset to swap. | Must be an active pool on Hermes Chain.|
|`SWAP`     | The swap handler | also `s,` `= `|
|`:ASSET` |  The asset identifier. | Can be shortened.|
| `:DESTADDR` | The destination address to send to.| Can use HERMESName.|
| `:LIM`    | The trade limit ie, set 100000000 to get a minimum of 1 full asset, else a refund. | Optional, 1e8 format |
| `:AFFILIATE` | The affiliate address. DOJ is sent to Affiliate.  | Optional. Must be HERMESName or HERMES Address. |
| `:FEE`  | The affiliate fee. Limited from 0 to 1000 Basis Points | Optional |

**Examples**

**`SWAP:ASSET:DESTADDR`** simply swap

**`=:ASSET:DESTADDR:LIM`** swap with limit

**`s:ASSET:DESTADDR:LIM:AFFILIATE:FEE`** swap with limit and affiliate

`=:DOJIMA.DOJ:dojima1el4ufmhll3yw7zxzszvfakrk66j7fx0tvcslym:19779138111`

`s:BNB/BUSD-BD1:dojima15s4apx9ap7lazpsct42nmvf0t6am4r3w0r64f2:628197586176 `

## Adding and Removing Liquidity

Entering and Leaving a Pool

To deposit assets on Hermes Chain, you need a compatible wallet with your assets connected to one of the many User Interfaces. 
Liquidity providers can add liquidity to any of the active or pending pools. There is no minimum deposit amount, however, 
your deposit will have to cover the deposit and later a withdrawal fee costs. The ability to manage and withdraw assets is completely noncustodial 
and does not require any KYC or permission process. Only the original depositor has the ability to withdraw them (based on the address used to deposit the assets).
Note, every time you add liquidity, Impermanent Loss Protection time resets.

While Symmetrically additions are recommended, Asymmetrical additions are supported, below are the rules:

If you add symmetrically first;

- You will be able to add asymmetrically with DOJ later 

- You will be able to add asymmetrically with ASSET later but it would create a new LP position 

- You will be able to add symmetrically later

If you add asymmetrically with ASSET first;

- You will be able to add asymmetrically with DOJ later but it would create a new LP position

- You will be able to add asymmetrically with ASSET later

- You will be able to add symmetrically later but it would create a new LP position

If you add asymmetrically with DOJ first:

- You will be able to add asymmetrically with DOJ later
- You will be able to add asymmetrically with ASSET later but it would create a new LP position
- You will not be able to add symmetrically later 

## ILP: How Hermes Chain protects its Liquidity Providers

Liquidity Providers will receive 100% Impermanent Loss Protection (ILP) after they have been in the pool for 100 days, getting 1% coverage for each day in the pool. Essentially this means you are adding 1% protection for every day that you provide liquidity. 49 days provided = 49% IL protection, 100 days = 100% IL protection.

Impermanent Loss Protection (ILP) ensures that you will not be worse off providing liquidity into Hermes Chain than just holding two assets, DOJ and ASSET, in your wallet. Protection is always recorded and applied symmetrically to both assets after the deposit is rebalanced to 50/50. Impermanent Loss Protection can also be thought of as deposit protection compared to holding both assets. Minimum withdrawal value will be the same as if you held both assets.

NOTE: The coverage will reset every time you add liquidity to the same pool and withdrawal fees will affect the withdrawal amount. Partial withdrawals do not reset the ILP counter.

## Add Liquidity

There are rules for adding liquidity, see the [rules here](/concepts/transaction.memos.md#adding-and-removing-liquidity) and regardless of how it is added, it is subject to Impermanent Loss Protection. 

`ADD:POOL:PAIREDADDR:AFFILIATE:FEE`

|Parameter  | Note           |Conditions   |
|---------- | -------------- |-------------|
|Payload    | The asset to add liquidity with.  | Must be supported by Hermes Chain.|
|`ADD`     | The Add Liquidity handler. | also `a,` `+`|
|`:POOL` |  The pool to add liquidity to. | Can be shortened.|
| `:PAIREDADDR` | The other address to link with. If on external chain, link to HERMES address. If on Hermes Chain, link to external address. If a paired address is found, the LP is matched and added. If none is found, the liquidity is put into pending.| Optional. If not specified, a single-sided add-liquidity action is created. |
| `:AFFILIATE` | The affiliate address. The affiliate is added in to the pool as an LP.   | Optional. Must be HERMESName or HERMES Address. |
| `:FEE`  | The affiliate fee. Fee is allocated to the affiliate.  | Optional. Limited from 0 to 1000 Basis Points. |

**Examples**

`ADD:POOL` single-sided add liquidity.  If this is a position's first add, liquidity can only be withdrawn to the same address.

**`+:POOL:PAIREDADDR`** add on both sides. 

**`a:POOL:PAIREDADDR:AFFILIATE:FEE`** add with affiliate

`+:BTC.BTC:`

## Withdraw Liquidity

Withdraw liquidity from a pool.

A withdrawal can be either dual-sided (wtihdrawn based on pool's price) or entirely single-sided (converted to one side and sent out).

**`WITHDRAW:POOL:BASISPOINTS:ASSET`**

|Parameter  | Note           |Conditions   |
|---------- | -------------- |-------------|
|Payload    | Send just enough of the asset to cause the transaction to be picked up by Hermes Chain.  | Caution Dust Limits: BTC,BCH,LTC chains 10k sats; DOGE 1m Sats; ETH 0 wei; HERMES 0 DOJ. |
|`WITHDRAW`     | The withdraw handler. | also `-,` `wd`|
|`:POOL` |  The pool to withdraw liquidity from | Can be shortened.|
| `:BASISPOINTS` |Basis points (0-10000, where 10000=100%)| |
| `:ASSET`  | Single-sided withdraw to one side. |  Optional. Can be shortened. Must be either DOJ or the ASSET. |

**Examples**

**`WITHDRAW:POOL:10000`** dual-sided 100% withdraw liquidity.  If a single-address position, this withdraws single-sidedly instead.

**`-:POOL:1000`** dual-sided 10% withdraw liquidity.

**`wd:POOL:5000:ASSET`** withdraw 50% liquidity as the asset specified while the rest stays in the pool, eg:
`wd:BTC.BTC:5000:BTC.BTC`

## DONATE & RESERVE

Donate to a pool or the RESERVE.

**`DONATE:POOL`**

| Parameter | Note                                        | Conditions                                              |
|-----------|---------------------------------------------|---------------------------------------------------------|
| Payload   | The asset to donate to a Hermes Chain pool. | Must be supported by Hermes Chain. Can be DOJ or ASSET. |
| `DONATE`  | The donate handler.                         | also `%`                                                |
| `:POOL`   | The pool to withdraw liquidity from.        | Can be shortened.                                       |

**`RESERVE`**

| Parameter | Note                 | Conditions                        |
|-----------|----------------------|-----------------------------------|
| Payload   | HERMES.DOJ           | The DOJ to credit to the RESERVE. |
| `RESERVE` | The reserve handler. |                                   |

## BOND, UNBOND & LEAVE

Perform node maintenance features. 

**`BOND:NODEADDR:PROVDER:FEE`**

| Parameter   | Note                                     | Conditions                                                                             |
|-------------|------------------------------------------|----------------------------------------------------------------------------------------|
| Payload     | The asset to bond to a  Node.            | Must be DOJ.                                                                           |
| `BOND`      | The bond handler.                        | Anytime                                                                                |
| `:NODEADDR` | The node to bond with.                   |                                                                                        |
| `:PROVIDER` | Whitelist in a provider.                 | Optional, add a provider                                                               |
| `:FEE`      | Specify an Operator Fee in Basis Points. | Optional, default will be the mimir value (2000 Basis Points). Can be changed anytime. |

**`UNBOND:NODEADDR:AMOUNT`**

| Parameter   | Note                     | Conditions                                                            |
|-------------|--------------------------|-----------------------------------------------------------------------|
| Payload     | None required            | Use `MsgDeposit`                                                      |
| `UNBOND`    | The unbond handler.      |                                                                       |
| `:NODEADDR` | The node to unbond from. | Must be in standby only.                                              |
| `:AMOUNT`   | The amount to unbond.    | In 1e8 format. If setting more than actual bond, then capped at bond. |

**`LEAVE:NODEADDR`**

| Parameter   | Note                        | Conditions                                                                                               |
|-------------|-----------------------------|----------------------------------------------------------------------------------------------------------|
| Payload     | None required               | Use `MsgDeposit`                                                                                         |
| `LEAVE`     | The leave handler.          |                                                                                                          |
| `:NODEADDR` | The node to force to leave. | If in Active, request a churn out to Standby for 1 churn cycle. If in Standby, forces a permanent leave. |

**Examples**

`BOND:hermes1xd4j3gk9frpxh8r22runntnqy34lwzrdkazldh`

`LEAVE:hermes18r8gnfm4qjak47qvpjdtw66ehsx49w99c5wewd`

## NOOP

Dev-centric type to fix Hermes Chain state. Caution: may cause loss of funds if not done exactly right at the right time. 

**NOOP**

| Parameter  | Note                            | Conditions                                               |
|------------|---------------------------------|----------------------------------------------------------|
| Payload    | The asset to credit to a vault. | Must be ASSET or DOJ.                                    |
| `NOOP`     | The  noop handler               | Adds to the vault balance, but does not add to the pool. |
| `:NOVAULT` | Do not credit the vault.        | Optional. Just fix the insolvency issue.                 |

## Refunds

The following are the conditions for refunds:

| Conditions            | Note                                                                                                         |
|-----------------------|--------------------------------------------------------------------------------------------------------------|
| Invalid `MEMO `       | If the `MEMO` is incorrect the user will be refunded.                                                        |
| Invalid Assets        | If the asset for the transaction is incorrect (adding an asset into a wrong pool) the user will be refunded. |
| Exceeding Price Limit | If the final value achieved in a trade differs to expected, they are refunded.                               |

Refunds cost fees to prevent Denial of Service attacks. The user will pay the correct outbound fee for that chain.

## Asset Notation

The following is the notation for Assets in Hermes Chain's system:

![medium](https://dojima-images.s3.ap-south-1.amazonaws.com/dojima-docs/img/doj_chain_system.svg)


**Note: CHAIN.ASSET denotes native asset. CHAIN/ASSET denotes a Synthetic Asset**

**Examples**

| Assets       | Notation                                            |
|--------------|-----------------------------------------------------|
| Bitcoin      | BTC.BTC (Native)                                    |
| Bitcoin      | BTC/BTC (Synth)                                     |
| Ethereum     | ETH.ETH                                             |
| USDT         | ETH.USDT-0xdac17f958d2ee523a2206206994597c13d831ec7 |
| BNB          | BNB.BNB (Native)                                    |
| BNB          | BNB/BNB (Synth)                                     |
| DOJ (BEP2)   | BNB.DOJ-B1A                                         |
| DOJ (NATIVE) | HERMES.DOJ                                          |

## Asset Abbreviations

Assets can be abbreviated using fuzzy logic. The following will all be matched appropriately. If there are conflicts then the deepest pool is matched. (To prevent attacks).

| Notation                                            |
|-----------------------------------------------------|
| ETH.USDT                                            |
| ETH.USDT-ec7                                        |
| ETH.USDT-6994597c13d831ec7                          |
| ETH.USDT-0xdac17f958d2ee523a2206206994597c13d831ec7 |

## Mechanism for Transaction Intent

| Chain         | Mechanism            | Notes                                                                      |
|---------------|----------------------|----------------------------------------------------------------------------|
| Bitcoin       | OP_RETURN            | Limited to 80 bytes.                                                       |
| Ethereum      | Smart Contract Input | Use `deposit(vault, asset, amount, memo) `function, where `memo` is string |
| Binance Chain | MEMO                 | Each transaction has an optional memo, limited to 128 bytes.               |
| Monero        | Extra Data           | Each transaction can have attached `extra data` field, that has no limits. |

Each chain will have a unique way of adding state to a transaction. Long assets can be shortened using Asset abbreviations (below) as well as HERMESNames to reduce the size of destination/affiliate addresses.​

