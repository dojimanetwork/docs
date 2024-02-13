The solana-state-sender program is named as solana-dojima-bridge.
This program maintains the mapping of registered programs on solana blockchain(Only registered programs can interact with state-sender program).
Solana programs should register and call this state-sender program to interact with other contracts on destination chains.

```rust
//admin will create the registry - (token mapping)
   pub fn create_registry(
ctx: Context<CreateRegistry>, 
solanaprogaddress: Pubkey,
dojimatoken: String, 
authority: Pubkey) -> Result<()> 
   {
       if ctx.accounts.user.key() != ctx.accounts.admin.admin {
           return  err!(MyError::NotOwner);
       }
       ctx.accounts.contract_mapping.dojimatokenaddress = dojimatoken;
       ctx.accounts.contract_mapping.authority = authority;
       Ok(())
   }
   //lock_program(eg;) => (dojimatoken+authority)
   #[account]
   pub struct ContractMapping {
   	dojimatokenaddress: String,
   	authority: Pubkey
   }


   #[derive(Accounts)]
   #[instruction(solanaprogaddress: Pubkey)]
   pub struct CreateRegistry<'info> {
   	//error handling
   	#[account(mut)]
   	pub user: Signer<'info>,
   	#[account(
       	init,
       	payer = user,
       	seeds = [solanaprogaddress.key().as_ref(), b"dojima_contract_mapping"],
      		bump,
       	space = 8 + 64 + 64,
   	)]
   	pub contract_mapping: Account<'info, ContractMapping>,
   	pub system_program: Program<'info, System>,
   	#[account(
       	seeds = [b"dojima_bridge_admin4"],
       	bump,
   	)]
   	pub admin: Account<'info, Admin>,
  }

```

- **Create_registry** - Admin will register the programs and create a contract mapping for every program.
- **dojimatoken** - This is the equivalent of solana token on dojima chain.
- **authority** - PDA of a program which signs to interact with the state-sender contract should be passed as an authority.

```rust
pub fn transfer_payload(
       ctx: Context<TransferPayload>,
       destination_contract: String,
       payload: String
   ) -> Result<()> {
       //only authority(ie; PDA of locking program) is allowed to call this function
       if ctx.accounts.contract_mapping.authority.key() != ctx.accounts.user.key() {
           return  err!(MyError::UnauthorizedContract);
       }
       if ctx.accounts.contract_mapping.dojimatokenaddress != destination_contract {
           return  err!(MyError::UnauthorizedContract);
       }
       let nonce =  ctx.accounts.counter.count;
       ctx.accounts.counter.count += 1;
       msg!(
           "{} {} {} {}",
           "TransferPayload",
           nonce,
           destination_contract,
           payload
       );
       Ok(())
   }

```

- **transfer_payload** - This function is used to transfer abi-encoded payload to dojima chain contracts.
- **destination_contract** - Which contract to call on the destination chain.
- **payload** - abi-encoded data that should be passed to the destination chain.
- A check will be made whether the calling program is registered in the registry or not.
- **destination_contract** should be the same as the registered dojima token address.
- Counter keeps track of the number of interactions happening with the state-sender program.
- It will increment the counter by one for everytime a **transfer_payload** (or) **token_transfer_from_solana** function is called.
- After incrementing the counter **TransferPayload** message(event) is emitted which is filtered by solana-client(narada) and submitted to hermes.

```rust
pub fn token_transfer_to_solana(
ctx: Context<TokenTransferToSolana>, 
destination_prog_data: Vec<u8>
) -> Result<()> {
       //check whether the signer is TSS


       //Define seeds for signing
       let seeds: &[&[u8]] = &[
           b"dojima_bridge_authority",
           &[254]
       ]; 
       let signer_seeds:&[&[&[u8]]] = &[&seeds[..]];


       //unpack accounts
       let destination_prog = &ctx.accounts.destination_program;
       let sender_ATA = &ctx.accounts.from_token_account;
       let receiver_ATA = &ctx.accounts.to_token_account;
       let tkn_prog = &ctx.accounts.token_program;
       let auth = &ctx.accounts.authority;
       let bridge_owner_pda = &ctx.accounts.bridge_owner_pda;


       //Construct accoount_metas for CPI invocation
       let account_metas = vec![
           AccountMeta::new(ctx.accounts.signing_pda.key(),true),
           AccountMeta::new(sender_ATA.key(), false),
           AccountMeta::new(receiver_ATA.key(), false),
           AccountMeta::new_readonly(tkn_prog.key(), false),
           AccountMeta::new_readonly(auth.key(), false),
           AccountMeta::new_readonly(bridge_owner_pda.key(), false),
       ];


       //Instruction identifier of global:execute_state
       let inst_identifier:Vec<u8> = vec![34, 26, 147, 217, 17, 18, 70, 124];


       //Prepare data for CPI
       let destination_prog_data_len = destination_prog_data.len() as u32;
       let destnation_prog_data_len_bytes = destination_prog_data_len.to_le_bytes();
       let mut data = inst_identifier.to_vec();
       data.extend(destnation_prog_data_len_bytes.to_vec());
       data.extend(destination_prog_data);


     


       let account_infos = vec![
           ctx.accounts.signing_pda.to_account_info(),
           sender_ATA.to_account_info(),
           receiver_ATA.to_account_info(),
           tkn_prog.to_account_info(),
           auth.to_account_info(),
           bridge_owner_pda.to_account_info(),
       ];


       //Construct instruction
        let inst = Instruction{
           program_id: destination_prog.key(),
           accounts: account_metas,
           data: data,
       };


       //Invoke CPI
       invoke_signed(&inst, &account_infos, signer_seeds);




       Ok(())
   }

```

- **token_transfer_to_solana** - This function will be used by cross-chain dapp developers to transfer (or) mint SPL tokens from the destination chain.
- **destination_prog_data** - Encoded byte data that is passed from destination chain(Developer can choose the way data gets encoded on destination chain.)
- All the accounts and encoded byte data passed from the destination chain are unpacked in this function and sent to a given destination contract on solana.
- The unpacked data will be passed to the **execute_state** function of the destination contract(Destination contract should implement **execute_state** function).
- Prepare the required data to construct instruction and CPI is done using **invoke_signed**.
- The instruction will be signed using a PDA derived from defined seeds.

