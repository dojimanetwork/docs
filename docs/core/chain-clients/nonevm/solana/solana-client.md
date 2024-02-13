---
title: Solana Chain Client
---
## [Introduction](https://solana.com)


Solana is a layer-1 blockchain similar to Ethereum and Bitcoin meaning other layer-2 blockchains can build on Solana. Solana has a similar concept of smart contracts on Ethereum called as Programs which also facilitates in development of dApps. Solana follows a consensus mechanism of Proof-of-History, which can be understood as a type of cryptographic timeclock which manages to timestamp a blockchain transaction. This helps in order of the blocks and transactions. The advantages of this can be understood on comparing the Bitcoin block validation time (10 mins) which uses Proof of Work and Solana block validation time (800 milliseconds).

## Solana local test node

To build programs and test it on your local node, you need to run a local instance of Solana local validator. To run it, first install [Solana CLI](https://docs.solana.com/cli/install-solana-cli-tools). Then start your own local validator node by running the command `solana-test-validator` after successfully installing Solana CLI. Further steps can be found [here](https://docs.solana.com/developing/test-validator) if you find the need to dive in-depth.

##  Solana-Client Overview

Solana client listens and parses the transactions included in solana blocks.
It will parse the transaction’s inner instructions field to know which programs were part of the execution.
If we find our state-sender program address in the inner-instruction, It means that some other program had to use our state-sender program for some sort of cross-chain operation.
The logs of the above transaction are parsed to see what type of event is emitted.
The event is extracted(termed as payload) and posted to the Hermes chain as a TxIn item.
At regular block intervals dojima chain will fetch TxIn items stored on hermes chain.
Based on the received payload, the dojima chain will be sending the payload to a destined contract on the dojima chain.

### Filtering Transactions

```go
func isDOJStateSenderTxn(tx *rpc.GetParsedTransactionResult, stateSenderContract string) (bool, string) {
   log := tx.Meta.LogMessages
   prog_add := ""
   if len(tx.Meta.InnerInstructions) == 0 {
      return false, ""
   }
   for i := 0; i < len(tx.Meta.InnerInstructions[0].Instructions); i++ {
      prog_add += tx.Meta.InnerInstructions[0].Instructions[i].ProgramId.String()
      prog_add += " "
   }
   if !strings.Contains(prog_add, "<sol_state_sender_prog>") {
      return false, ""
   }
   log_str := fmt.Sprint(log)
   if strings.Contains(log_str, "TokenTransfer") {
      return true, "TokenTransfer"
   } else if strings.Contains(log_str, "TransferPayload") {
      return true, "TransferPayload"
   }
   return false, ""
}

```
!!! info
    The above code snippet allows the client to decide whether the picked transaction should be filtered and sent to hermes.

- **isDOJStateSenderTxn** - This function returns a boolean value stating whether the transaction is state-sender transaction or not.
- **tx.Meta.InnerInstructions[0].Instructions** - This consists of the programs that were part of the first instruction execution.
- **TokenTransfer** and  **TransferPayload** are the types of events which are to be filtered and stored in the Hermes chain.


```go
func GetUnpackedEvent(log []string, typ string) (StateSenderEvent, error) {
   sse := StateSenderEvent{}
   if typ == "TokenTransfer" {
     return sse, nil
   } else if typ == "TransferPayload" {
      log_str := fmt.Sprintln(log)
      log_str_arr := strings.Split(log_str, " ")
      indx := -1
      for i := 0; i < len(log_str_arr); i++ {
         if log_str_arr[i] == typ {
            indx = i
            break
         }
      }
	if indx == -1 {
   		return sse, fmt.Errorf("unable to parse TransferPayload event")
	}
      //Destination chain
      sse.DestChain = "DOJ"
      //Destination contract
      sse.SourceDestContract = log_str_arr[1]
      //destination chain destination contract
      sse.DestinationDestContract = log_str_arr[indx+2]
      //Destination counter nonce
      counter_in_u64, err := strconv.ParseUint(log_str_arr[indx+1], 10, 64)
      if err != nil {
         return sse, &StateSenderError{}
      }
      sse.CounterNonce = counter_in_u64
      //emitted data for child chain smart contract
      sse.DataInBytes = log_str_arr[indx+3]
      return sse, nil
   }
   return sse, nil
}

```

!!! info
    The above code snippet allows the client to parse log to extract payload .


### Scanning Blocks

The block scanner monitors fortuna addresses and looks for incoming transactions to those addresses. When it sees, it performs validations and witnesses to hermes chain.

```go
      client := rpc.NewClient("http://127.0.0.1:8899")
      address := os.Getenv("SOL_ADDRESS")

      txInfo, err := c.client.GetTransaction(
        context.TODO(), 
        txSig, 
        &rpc.GetTransactionOpts{Encoding: solana.EncodingBase64}
        )

      // If Transaction is not found.
      if err != nil {
        return types.TxInItem{}, err
      }

      decodedTx, err := solana.TransactionFromDecoder(bin.NewBinDecoder(txInfo.Transaction.GetBinary()))

      // If Transaction is not decoded. 
      if err != nil {
        return types.TxInItem{}, err
      }

      // Getting the transaction details from the decoded transaction.
      sender := decodedTx.AccountMetaList()[0].PublicKey.String()
      LamportQtyStr := cosmos.NewUint(txInfo.Meta.PostBalances[1] - txInfo.Meta.PreBalances[1])
      LamportFeeStr := cosmos.NewUint(txInfo.Meta.Fee)

      // Read memo from solana transaction.
      solmemo := ""
      if len(txInfo.Meta.LogMessages) > 4 {
        solmemo = txInfo.Meta.LogMessages[4]
        solmemo = strings.ReplaceAll(solmemo, "Program log: ", "")
      }

      gasFee := common.Gas{
        common.NewCoin(common.SOLAsset, LamportFeeStr),
      }
      toAddr := decodedTx.Message.AccountKeys[1].String()

      // update memory cache
      c.udpateSOLGasCache(LamportFeeStr)

      return types.TxInItem{
        BlockHeight: height,
        Tx:          tx,
        Sender:      sender,
        To:          toAddr,
        Coins: common.Coins{
          common.NewCoin(common.SOLAsset, LamportQtyStr),
        },
        Memo: solmemo,
        Gas:  gasFee,
      }, nil

```

### Solana Signer

Signer works on signing the outbound transactions received txout from hermes chain that needs to sent on solana chain. Signing transactions are done in two ways: using ed25519 tss signing algo and single wallet signing.

```go
    _, err := tx.VaultPubKey.GetAddress(c.GetChain())
  if err != nil {
  	return &solana.Transaction{}, fmt.Errorf("failed to convert solana address (%s): %w", tx.VaultPubKey.String(), err)
  }

  var coins = cosmos.NewUint(0)
  for _, coin := range tx.Coins {
  	// handle sors return, leave enough coin to pay for gas.
  	if strings.HasPrefix(tx.Memo, hermes.TxToStringMap[hermes.TxSorsReturn]) {
  		if coin.Asset == c.cfg.ChainID.GetGasAsset() {
  			substractFee := c.averageFee().Mul(cosmos.NewUint(3)).Quo(cosmos.NewUint(2))
  			if coin.Amount.LT(substractFee) {
  				return &solana.Transaction{}, fmt.Errorf("not enough to pay for transaction, Origal amount %d, Fee %d", coin.Amount.Uint64(), substractFee.Uint64())
  			}

  			coin.Amount = coin.Amount.Sub(substractFee)
  		}
  	}
  	coins = coins.Add(coin.Amount)
  }
  recent, err := c.GetRecentBlockhash()
  if err != nil {

  }

  amt := coins.String()
  instruction_data := []byte{0xaa, 0xbb}

  instruction := []solana.Instruction{
  	&TransactionInstructions{
  		accounts: []*solana.AccountMeta{
  			{PublicKey: solana.MustPublicKeyFromBase58(tx.fromAddress.PublicKey()), IsSigner: true, IsWritable: true},
  			{PublicKey: solana.MustPublicKeyFromBase58(tx.ToAddress.String()), IsSigner: false, IsWritable: true},
  			{PublicKey: solana.SystemProgramID, IsSigner: false, IsWritable: false},
  		},
  		data:      instruction_data,
  		programID: solana.MustPublicKeyFromBase58(os.Getenv("SOL_PROGRAM")),
  	},
  }

  solTx, err := solana.NewTransaction(
  	instruction,
  	recent.Value.Blockhash,
  	solana.TransactionPayer(c.SolKeysignWrapper.privateKey.PublicKey()),
  )
  return solTx, err
```