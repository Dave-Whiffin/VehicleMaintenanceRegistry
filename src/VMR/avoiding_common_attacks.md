Module 9 Lesson 3

# Favour Pull Over Push
* Transfer of ownership in registry is transfer and accept model
* To avoid the registry returning unlimited arrays
    * It assigns a number to each member
    * It keeps a total count which the caller can read
    * The caller can iterate through members using an incrementing number

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


King Of The Ether
C1. Logic Bugs
Simple programming mistakes can cause the contract to behave differently to its stated rules, especially on 'edge cases'.

We have mitigated against this risk by:

Running over forty on-chain functional tests against the contract - see our on-chain test report.
Performing "fuzz testing" by generating random method calls and applying them to both the real Solidity contract and a Javascript simulation of intended behaviour, then looking for differences.
Following Solidity coding standards and general coding best practices for safety-critical software.
Avoiding overly complex rules (even at the cost of some functionality) or complicated implementation (even at the cost of some gas).
Note that we have chosen not to include a mechanism for fixing bugs during the life of the contract due to concern that this mechanism would itself be a serious vulnerability.

C2. Failed Sends
An earlier version of King of the Ether suffered from failure to send compensation payments to wallet contracts created by older versions of the Mist Ethereum Wallet.

We have mitigated against this risk by:

Including a reasonable amount of gas with each payment sent.
If sending a compensation payment still fails, we detect this and ring-fence the funds for the recipient to withdraw.
Running several functional tests for this scenario - see e.g. "Compensation payment failure detected when sending to a very expensive wallet contract" and "Successfully resend failed compensation payment" in our on-chain test report.
C3. Recursive Calls
Famously, the original DAO contract exhibited unintended behaviour where a "recursive split" technique was used to move Ether worth over US$ 100 Million out of the DAO. This was possible because when a contract sends payment to another contract, the receiving contract's fallback function can call back into the sending contract, which can often produce behaviour the developer of the sending contract developer had not anticipated.

We have mitigated against this risk by:

Using a 'reentry' flag to prevent recursive calls to all external non-constant functions in the contract - see the "ReentryProtectorMixin" in our contract code.
Running functional tests for this scenario - see e.g. "Recursive call attack (nested withdraw)" in our on-chain test report.
C4. Integer Arithmetic Overflow
Numbers in Solidity code silently "wrap-around" if they become too large. This can lead to surprising behaviour - e.g. a check like "if (amountOne + amountTwo < myBalance) {...}" can appear to be true if one of the amounts is large enough to cause over-flow.

We have mitigated against this risk by:

Auditing every use of arithmetic operations involving user-supplied data.
Checking pre-conditions before performing arithmetic where practical.
C5. Poison Data
Contracts that accept user input that is stored or exposed to other users are vulnerable to being supplied with unanticipated input that causes problems for the contract or for other users of the contract.

We have mitigated against this risk by:

Limiting the length of user-supplied data such as monarch names.
If sending a compensation payment to a user-supplied address fails, we detect this and ring-fence the funds for the recipient to withdraw later, rather than preventing other monarchs claiming the throne.
We disallow characters in names that often have special meaning in computer systems such as <, > and ' to avoid causing problems for poorly-written software that reads contract data.
Running functional tests for these scenarios - see e.g. "Name Validation" and "Compensation payment failure detected when sending to a very expensive wallet contract" in our on-chain test report.
C6. Exposed Functions
It is easy to accidentally expose a contract function which was meant to be internal, or to omit protection on a function which was meant to be called only by priviledged accounts (e.g. by the creator).

We have mitigated against this risk by:

Auditing the compiler-generated ABI to ensure no unexpected functions appear.
Auditing every external function to ensure it is intended to be exposed and has suitable protection.
C7. Exposed Secrets
All code and data on the blockchain is visible by anyone, even if not marked as "public" in Solidity. Contracts that attempt to rely on keeping keys or behaviour secret are in for a surpsise.

We have mitigated against this risk by:

Ensuring our contracts do not rely on any secret information.
C8. Denial of Service / Dust Spam
An attacker may cause inconvenience for other users by supplying the contract with data that is expensive to process, or by repeatedly carrying out actions that prevent others from interacting with the contract.

We have mitigated against this risk by:

Limiting the length of user-supplied data such as monarch names.
Avoiding looping behaviour where e.g. a function costs more and more gas each time is used.
Ensuring that a non-trivial payment is required by a user to make a change that would affect other users' transactions.
Using DDOS protection on websites related to the contract.
Hosting websites and services related to the contract in multiple redundant datacentres with automated hot failover.
C9. Miner Vulnerabilities
Even without serious collusion, Ethereum miners have some limited ability to influence block timestamps and which transactions are chosen in a block (and hence block hashes). A miner or group of miners who control a majority of hashing power in the network can make almost any change they want to contract data or behaviour.

We have mitigated against this risk by:

Not using block hashes.
Not expecting a precision of better than fifteen minutes or so from block timestamps.
Capping the maximum claim price at a level well below that for which a rational miner would take the risk of "cheating".
C10. Malicious Creator
If a contract gives the creator/owner of the contract too much power, they may take funds that should be owned by users of the contract, or change the behaviour of the contract in their favour.

We have mitigated against this risk by:

Other than compensation payments that failed to be sent, the contract does not hold user funds.
Not allowing the rules of a throne (commission, claim price) to be changed after creation by anyone.
Only allowing the creator to withdraw funds from the contract that have been ring-fenced for them - that is, their commission.
Not allowing the creator to upgrade or change the behaviour of a Kingdom contract once created. Unfortunately this prevents the creator fixing bugs, though we have a mechanism to replace the contract used for future kingdoms.
C11. Off-chain Safety
Rather than attack the contract itself, an attacker may trick users into interacting with a different contract or into sending funds to her address instead of the real contract. This could be done by phishing, by taking control of the website hosting, or by attacking github or social media accounts. An attacker may also attempt to steal Ethereum account private keys from users (or from the contract administrators). For some contracts, accidental loss of private keys belonging to a user important to the contract's contuining operation (e.g. the creator) could prevent operation of the contract.

We have mitigated against this risk by:

Using HTTPS with strong security settings on websites related to the contract (including origin servers).
Using security measures such as strong passwords and two-factor authentication (where available) on hosting provider, DNS, email, reddit and github accounts.
Following OWASP guidelines for avoiding web vulnerabilities in websites related to the contract, and employing ISO-27001 controls (where applicable) internally.
Keeping sensitive data (e.g. passphrases, keys) in encrypted storage on physically separated hardware, with encrypted off-site backups.
Ensuring that the contract does not rely on the creator or external services to perform any actions.
C12. Cross-chain Replay Attacks
Following the Ethereum hard-fork, activity has also continued on the Ethereum Classic Chain. Transactions on one chain can be replayed on the other.

We have mitigated against this risk by:

Including a warning about accidental ETC transfers in our instructions.
Creating these contracts from a hard-fork-only address, so they appear only on the Ethereum Foundation Hard-Fork chain. This does however mean that ETC sent to the addresses will likely be lost.
C13. Tx.Origin Problem
This is kind of a "confused depty" problem. If a contract relies on Solidity 'tx.origin' to decide who the caller is (e.g. to see if they're allowed to withdraw their funds), there's a danger that a malicious intermediary contract could make calls to the contract on behalf of the user (who presumably thought the malicious intermediary contract would do something else). See vessenes.com - Tx.Origin And Ethereum Oh My! for a better description.

We have mitigated against this risk by:

Not using tx.origin for authentication (or indeed, at all).
C14. Solidity Function Signatures and Fallback Data Collisions

This one is a little bit obscure - but it might catch someone out.

Under the hood, when you call a non-constant external function on a Solidity contract you are really just sending a transaction to the contract with some "magic" data. This works because the Solidity compiler has put some special bytecode at the start of the contract which checks the magic data and invokes the correct function.

Solidity contracts can also have a "fallback" function which is called if there is no data present in the transaction, or if the data does not match any of the contract functions. The fallback function can examine the data sent using the msg.data property.

This can lead to problems in two ways:

Phishing - A user might be tricked into calling a function on a contract - e.g. 'sendAllMyTokensTo(address)' - by being told by another user to send some special data to the contract.
Poisoning - There are some items of data that can never be sent to a fallback function, because they clash with a function signature. For example, if my contract has a function whose signature is foo(uint256), then I can never send data starting with 2FBEBD38 to the fallback function.
We have mitigated against this risk by:

The KingOfTheEther fallback function only accepts monarch names sent to it in msg.data if they are prefixed with 'NAME:' in ASCII, which does not clash with any Solidity function signatures.
However, in hindsight, we think having a fallback function read msg.data is a mistake - it makes things unnecessarily complicated. It is sometimes desirable to allow users to interact with the contract by sending simple transactions to it (e.g. from web wallets) without having to copy-and-paste an enormous ABI or run a native app. Perhaps it is better to provide some off-chain means (e.g. a Javascript converter) to generate the "magic" data needed to invoke the desired Solidity function? There is a risk of encouraging phishing attacks though by encouraging people to send mysterious data to contracts.

C15. Incorrect use of Cryptography
Cryptographic primitives are notoriously difficult to use correctly - see e.g. If you're typing the letters A-E-S into your code you're doing it wrong.

We have mitigated against this risk by:

We do not make use of any cryptography.
C16. Gas Limits
It's quite hard to calculate the maximum amount of gas a contract can use - famously Governmental got stuck due to this. To make matters worse, the maximum gas limit on the network can vary over time based on transaction fees.

We have mitigated against this risk by:

Being careful not to loop over (or delete) arrays that can grow as a result of user input.
Limiting the length of user-supplied data such as monarch names.
Running automated functional tests for gas usage.
Performing "fuzz testing" by generating random method calls and applying them to both the real Solidity contract and a Javascript simulation of intended behaviour, then looking for differences.
Note that we inadvertently deployed our first contract versions to production using a slightly different version of the Solidity compiler than we tested with - this caused gas costs on the real contract to be slightly higher than expected.

C17. Stack Depth Exhaustion
The Ethereum Virtual Machine has a stack depth limit of 1024 - this can cause calls/sends between contracts to unexpectedly fail. An attacker can set things up so that her contract eats up nearly all the stack just before calling the victim contract.

We omitted to test for this risk originally, but luckily the mitigations we put in place for 'C2. Failed Sends' apply here also. However, it's worth pointing out that it's not just explicit send() calls that can fail - any external call between contracts could fail due to this, though luckily the latter will throw an exception.
