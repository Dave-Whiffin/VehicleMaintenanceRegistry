Module 9 Lesson 3

# Favour Pull Over Push
The VMR system doesn't batch distribute payments or do anything of a batch nature.  

For ownership transfer it follows a transfer and claim/accept pattern.  The owner makes a transfer which sets a pending owner, the pending owner must then accept/claim the ownership.

Slighty abstract - but none of the contracts return arrays - the caller must enumerate using a client side counter and retrieve each record via it's number.

# On Chain Data is public
* Transfer member routine of registry only stores hash of transfer key. 

# Known Attacks

## Reentrancy

# Solidity

## Parties dropping off line

## Enforce invariants with assert

## Use assert and require properly

## Remember Ether can forcibly be sent to an account

## Be aware of the trade offs between abstract contracts and interfaces

## Keep fallback functions simple

## Check data length in fallback functions

## Explicity mark visibility in functions and state variables

## Lock pragmas to specific compiler version
// bad
pragma solidity ^0.4.4;
// good
pragma solidity 0.4.4;

## Differentiate functions from events

## Prefer newer Solidity constructs

Prefer constructs/aliases such as selfdestruct (over suicide) and keccak256 (over sha3). Patterns like require(msg.sender.send(1 ether)) can also be simplified to using transfer(), as in msg.sender.transfer(1 ether).

## Be aware that 'Built-ins' can be shadowed

## Avoid using tx.origin

## Timestamp Dependence


# Avoiding common attacks

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
The system does not send payments.  It does receive values.  The registries receive payment for registration and transfer.  This goes in to the balance on each registry contract.  There is no option to send it to another party.  There is a mechanism for killing the contracts and sending the balance back to the owner.  The contracts inherit TokenDestructable contract from open-zeppelin allowing tokens to be sent back to the owner when the contract is destructed.

## Reentry / Recursive Calls
Famously, the original DAO contract exhibited unintended behaviour where a "recursive split" technique was used to move Ether worth over US$ 100 Million out of the DAO. This was possible because when a contract sends payment to another contract, the receiving contract's fallback function can call back into the sending contract, which can often produce behaviour the developer of the sending contract developer had not anticipated.

Mitigation:

The system doesn't make calls where internal state is updated after an external call.  

External calls within contracts are only to verified/trusted addresses.

External calls are often used in pre execution validation modifiers (e.g. registry lookups).  Where these throw, the function will not proceed and state would not be modified.  External calls are made to a trusted contract storage address where state data is actually stored.  Protection is in place to prevent this address from being changed by anyone but the owner.

The contracts do not transfer Ether (msg.value) to other addresses.  Only the registries accept a msg.value for initial registration or transfer.  This value is held in the balance of the registry contract.  Only the owner of the contract can redeem it on self destruction.  


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

Deliberately minimising the number of functions in each contract 
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

The registries have little to gain for this system.  

## TODO! - Off-chain Safety  
Rather than attack the contract itself, an attacker may trick users into interacting with a different contract or into sending funds to her address instead of the real contract. This could be done by phishing, by taking control of the website hosting, or by attacking github or social media accounts. An attacker may also attempt to steal Ethereum account private keys from users (or from the contract administrators). For some contracts, accidental loss of private keys belonging to a user important to the contract's contuining operation (e.g. the creator) could prevent operation of the contract.

We have mitigated against this risk by:

Using HTTPS with strong security settings on websites related to the contract (including origin servers).
Using security measures such as strong passwords and two-factor authentication (where available) on hosting provider, DNS, email, reddit and github accounts.
Following OWASP guidelines for avoiding web vulnerabilities in websites related to the contract, and employing ISO-27001 controls (where applicable) internally.
Keeping sensitive data (e.g. passphrases, keys) in encrypted storage on physically separated hardware, with encrypted off-site backups.
Ensuring that the contract does not rely on the creator or external services to perform any actions.

## TODO! - Cross-chain Replay Attacks
Following the Ethereum hard-fork, activity has also continued on the Ethereum Classic Chain. Transactions on one chain can be replayed on the other.

We have mitigated against this risk by:

Including a warning about accidental ETC transfers in our instructions.
Creating these contracts from a hard-fork-only address, so they appear only on the Ethereum Foundation Hard-Fork chain. This does however mean that ETC sent to the addresses will likely be lost.

## Tx.Origin Problem

Mitigation:

tx.origin is not used at all.

##  TODO - Solidity Function Signatures and Fallback Data Collisions

This one is a little bit obscure - but it might catch someone out.

Under the hood, when you call a non-constant external function on a Solidity contract you are really just sending a transaction to the contract with some "magic" data. This works because the Solidity compiler has put some special bytecode at the start of the contract which checks the magic data and invokes the correct function.

Solidity contracts can also have a "fallback" function which is called if there is no data present in the transaction, or if the data does not match any of the contract functions. The fallback function can examine the data sent using the msg.data property.

This can lead to problems in two ways:

Phishing - A user might be tricked into calling a function on a contract - e.g. 'sendAllMyTokensTo(address)' - by being told by another user to send some special data to the contract.
Poisoning - There are some items of data that can never be sent to a fallback function, because they clash with a function signature. For example, if my contract has a function whose signature is foo(uint256), then I can never send data starting with 2FBEBD38 to the fallback function.
We have mitigated against this risk by:

The KingOfTheEther fallback function only accepts monarch names sent to it in msg.data if they are prefixed with 'NAME:' in ASCII, which does not clash with any Solidity function signatures.
However, in hindsight, we think having a fallback function read msg.data is a mistake - it makes things unnecessarily complicated. It is sometimes desirable to allow users to interact with the contract by sending simple transactions to it (e.g. from web wallets) without having to copy-and-paste an enormous ABI or run a native app. Perhaps it is better to provide some off-chain means (e.g. a Javascript converter) to generate the "magic" data needed to invoke the desired Solidity function? There is a risk of encouraging phishing attacks though by encouraging people to send mysterious data to contracts.

## Incorrect use of Cryptography
Cryptographic primitives are notoriously difficult to use correctly - see e.g. If you're typing the letters A-E-S into your code you're doing it wrong.

We have mitigated against this risk by:

No use of cryptography.

## Gas Limits
It's quite hard to calculate the maximum amount of gas a contract can use - famously Governmental got stuck due to this. To make matters worse, the maximum gas limit on the network can vary over time based on transaction fees.

We have mitigated against this risk by:

+ No looping over unbounded arrays.
+ Using bytes32 in favour of strings.
+ Ensuring tests pass.

## Stack Depth Exhaustion
The Ethereum Virtual Machine has a stack depth limit of 1024 - this can cause calls/sends between contracts to unexpectedly fail. An attacker can set things up so that her contract eats up nearly all the stack just before calling the victim contract.

Mitigation:

Running integration tests to ensure typical scenarios involving multiple contracts succeed.
