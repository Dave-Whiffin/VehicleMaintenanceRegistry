# Favour Pull Over Push
The VMR system doesn't batch distribute payments or do anything of a batch nature.  

For ownership transfer it follows a transfer and claim/accept pattern.  The owner makes a transfer which sets a pending owner, the pending owner must then accept/claim the ownership.

The registry contract has a withdraw function which transfers an amount from the balance of the contract to the owner.  This uses the transfer function which would revert if there were insufficient funds or the transfer failed.  Internal state would not be corrupted.

Slighty abstract - but none of the contracts return arrays - the caller must enumerate using a client side counter and retrieve each record via it's number.  This means the contract isn't "pushing" out arrays - the caller must "pull" each item.

# On Chain Data is public
* Transfer member routine of registry only stores hash of transfer key. 

# Known Attacks

## Reentrancy
The contracts do not make external calls to untrusted parties before updating state.  Trusted parties are the eternal storage contracts and libraries which are pre verified to ensure they behave properly.

# Solidity

## Parties dropping off line
There is a risk that owners of the contracts drop off line. For registry contracts this could prevent new members from being added as the registry owner is required to perform this action.  However, the registry owner is seen as trusted account and whoever owns this would be expected to take extra precautions to ensure the registry is without an active owner.  The owner does have the ability to transfer to another owner should they need to.

For vehicles and maintenance logs - again yes, there is a risk that the owner would drop off line.  This would prevent the log entries from being verified and from new maintainers being authorised to log new entries.  The ownership of the vehicle could not be transferred.  There is no back door for another party to regain ownership of the vehicle.  For example if the vehicle owner died, the vehicle could be left in limbo.  In future, an option for the registry owner to take ownership could be made available but was not deemed essential at the moment.

## Use assert and require properly


## Remember Ether can forcibly be sent to an account
There is no functionality that would break.  None of the contracts attempt to correlate the balance on the contracts with anything else.

## Be aware of the trade offs between abstract contracts and interfaces

## Keep fallback functions simple
There is only one fallback function on the registry and it has no implementation code.  It is only there to allow ether to be sent to the contract for testing purposes.

## Explicity mark visibility in functions and state variables
All functions and variables have an explicitly marked visibility.

## Lock pragmas to specific compiler version
For flexibility during development the pragmas are not currently locked down (i.e. ^0.4.23).  However before deployment to a proper test net or main, the pragmas would be locked down (i.e. 0.4.23).

## Differentiate functions from events
Functions start with a lower case letter, events start with uppercase.

## Prefer newer Solidity constructs

All newer constructs are used VMR specific contracts: keccack256 over sha3 and selfdestruct over suicide.  Some referenced open-zeppelin and oraclize contracts may induce compiler warnings because of older constructs. 

## Be aware that 'Built-ins' can be shadowed
Only trusted contracts are involved.  All contracts are tested thoroughly.  The contents of contracts are checked to ensure that there is no shadowing of built ins that could be in any way harmful or odd.

# Avoiding common attacks
Credit for the description of some of the attacks goes to King Of Ether.  The mitigation steps are in reference to VMR.

## Logic Bugs
Simple programming mistakes can cause the contract to behave differently to its stated rules, especially on 'edge cases'.

Mitigation
* The contracts are heavily unit tested (100+ tests) with Solidity and Javascript tests.  
* Testing ensures expected inputs produce expected outputs.
* Testing ensures that bad inputs are rejected.
* Testing ensures that stated rules are followed.
* Solidity coding best practices are followed.
* Simple rules are favoured over complex rules.
* Storing minimal data, minimal iteration code and no recursive functions.
* Employed a registry model which allows contracts to be upgraded (they would be long running contracts)
* Not storing secret data on the block chain

## Failed Sends
The contracts in the does not send payments, except when a registry owner withdraws from the contract balance. The registries receive payment for registration and transfer.  This goes in to the balance on each registry contract.  The withdraw function is protected and tested to ensure only the owner can call it.  It does not attempt to change any other state, so if the transfer to the owner fails then state is not corrupted.  There is a mechanism for killing the contracts and sending the balance back to the owner.  The contracts inherit TokenDestructable contract from open-zeppelin allowing tokens to be sent back to the owner when the contract is destructed.

## Reentry / Recursive Calls
Famously, the original DAO contract exhibited unintended behaviour where a "recursive split" technique was used to move Ether worth over US$ 100 Million out of the DAO. This was possible because when a contract sends payment to another contract, the receiving contract's fallback function can call back into the sending contract, which can often produce behaviour the developer of the sending contract developer had not anticipated.

Mitigation:

The system doesn't make any calls where internal state is updated after an external call to an untrusted contract.

External calls within contracts are only to verified/trusted addresses.

External calls are often used in pre execution validation modifiers (e.g. registry lookups).  Where these throw, the function will not proceed and state would not be modified.  External calls are made to a trusted contract storage address where state data is actually stored.  Protection is in place to prevent this address from being changed by anyone but the owner.

The contracts do not transfer Ether (msg.value) to other addresses.  Only the registries accept a msg.value for initial registration or transfer.  This value is held in the balance of the registry contract.  Only the owner of the contract can withdraw from this balance or receive it on self destruction.  

## Integer Arithmetic Overflow
Numbers in Solidity code silently "wrap-around" if they become too large. This can lead to surprising behaviour - e.g. a check like "if (amountOne + amountTwo < myBalance) {...}" can appear to be true if one of the amounts is large enough to cause over-flow.

Mitigation:

The system doesn't allow integers to be passed by callers which would then be added or subtracted and cause a potential overflow.  Only internally controlled integers (like registry member count) are incremented and this is by a fixed value held in the contract so it will not overflow.   The member count will not reach the point at which an integer would overflow.

## Poison Data
Contracts that accept user input that is stored or exposed to other users are vulnerable to being supplied with unanticipated input that causes problems for the contract or for other users of the contract.

Mitigation:

Limiting the length of user-supplied data (names/ids are bytes32, not strings).
Running functional tests for these scenarios  (for instance VIN length verification)

## Exposed Functions
It is easy to accidentally expose a contract function which was meant to be internal, or to omit protection on a function which was meant to be called only by priviledged accounts (e.g. by the creator).

Mitigation:

Deliberately minimising the number of functions in each contract.
Ensuring only the owning contract can set data in the Eternal Storage contracts (unit tested).
Checking the ABI to ensure that no unexpected functions are present.

## Exposed Secrets
All code and data on the blockchain is visible by anyone, even if not marked as "public" in Solidity. Contracts that attempt to rely on keeping keys or behaviour secret are in for a surpsise.

Mitigation:

There is no secret data stored in the chain.
Storing only the hash of a secret in pre-commit scenarios (it will become public after commit but has no purpose for reuse).  The setter of the secret must ensure they do now follow a predictable pattern for generating secrets.  Knowing the secret alone is not enough to cause ownerhip to transfer.

## Denial of Service / Dust Spam
An attacker may cause inconvenience for other users by supplying the contract with data that is expensive to process, or by repeatedly carrying out actions that prevent others from interacting with the contract.

Mitigation:

Enforcing a fee for registry registration / transferral to discourage bad actors from making multiple calls.
Limiting the size of data (bytes32 in favour of string).
No loops over unbounded arrays e.g. a function costs more and more gas each time is used.

## Miner Vulnerabilities
Even without serious collusion, Ethereum miners have some limited ability to influence block timestamps and which transactions are chosen in a block (and hence block hashes). A miner or group of miners who control a majority of hashing power in the network can make almost any change they want to contract data or behaviour.

Mitigation:

Have not used block hashes.
Precision of better than fifteen minutes or so from block timestamps is not crucial (e.g vehicle registration date).

## Malicious Creator
If a contract gives the creator/owner of the contract too much power, they may take funds that should be owned by users of the contract, or change the behaviour of the contract in their favour.

We have mitigated against this risk by:

The registries have little to gain for this particular system.  

## Tx.Origin Problem

Mitigation:

tx.origin is not used at all.

##  Solidity Function Signatures and Fallback Data Collisions

The only fallback function implemented is on the registry contract.  It is only present to allow the balance of the contract to be increased via a simple transaction send. This was primarily for testing purposes. It does not have any implementation code other than the signature.

## Incorrect use of Cryptography
Cryptographic primitives are notoriously difficult to use correctly - see e.g. If you're typing the letters A-E-S into your code you're doing it wrong.

Mitigation:

No use of cryptography.

## Gas Limits
It's quite hard to calculate the maximum amount of gas a contract can use - famously Governmental got stuck due to this. To make matters worse, the maximum gas limit on the network can vary over time based on transaction fees.

Mitigation:

+ No looping over unbounded arrays.
+ Using bytes32 in favour of strings.
+ Ensuring tests pass.

## Stack Depth Exhaustion
The Ethereum Virtual Machine has a stack depth limit of 1024 - this can cause calls/sends between contracts to unexpectedly fail. An attacker can set things up so that her contract eats up nearly all the stack just before calling the victim contract.

Mitigation:

Running integration tests to ensure typical scenarios involving multiple contracts succeed.
