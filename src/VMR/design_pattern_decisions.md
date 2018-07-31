
VMR - Design Decisions
======================

# Emergency Stop
To prevent changes to state data in emergency - the registries and maintenance log implement Pausable (open-zeppelin). All functions that change state are protected so that they will throw when paused.  Reading state while paused is allowed so all "getters" will continue to work.  It could be argued that there would be situations where reading data whilst paused is not desirable (where state has become corrupt) on the whole it makes sense to keep the contracts functional as far as possible for reading purposes.  The risk of corrupt data is mitigated by comprehensive input validation and rule enforcement.  One of the main benefits of this kind of system is the transparency and availability of data. 

# Minimising Storage Costs
The registries would be expected to continue to grow large and live for a long time.  Consequently the data is largely restricted to bytes32 values in favour of strings to minimise storage costs.  The data stored is restricted to mappings in favour of arrays.

# Minimising Deployment Byte Code
The data repository code is kept in a seperate library to minimise the size of the byte code in the main contracts.

# Loose Coupling
Interfaces have been used to allow loose coupling between the major contracts.   A few small, terse interfaces minimise the dependencies between the main contracts.  For instance the maintenance log has a dependency on a vehicle registry, but instead of referencing the vehicle registry contract, it references a simple IRegistryLookup interface and stores an address for the contract implementing that.  This provides an upgrade point where the vehicle registry contract instance could be swapped.  It also helps prevent spaghetti code and keeps contracts focussing on their core purpose.

# Upgradability
The main contracts (registries and maintenance log) store data in their own specific and separate Eternal Storage contract.  The Eternal Storage is fundamently just a series of key / value pairs (mappings).  Therefore the data it stores is extensible over time without the need to change the Eternal Storage contract itself. The address of the storage contract is stored in state on the main contract and can be updated.  Therefore if the main contract needs upgrading, the upgraded contract can use the same storage address.  If there is a bug in the storage itself, that can also be changed.  Eternal Storage is kept deliberately simple to mitigate the chance of bugs and mitigate the need to upgrade.

For registries - the upgradeability would come from using ENS for each registry.  It would makes sense to have an ENS name for things like vehicle registry, manufacturer registry etc.   Clients would use ENS to find the registry and therefore the registry contracts can be upgraded in the future with an ENS change.  Like all registry upgrade patterns - there is a risk that a client will continue to reference an old address instead of using ENS. 

For the maintenance log - the address of the maintenance log is stored in the vehicle registry.  It is expected that anybody wanting to view the log for a vehicle would get this address from the registry.  The address can be changed by the owner of the registry (or in some cases the owner of the member in the registry) which provides the upgrade point for the maintenance log.

Downsides: Calling other contracts costs more gas than calling internal functions.  The initial deployment of the main contract is more complicated as the eternal storage contract must be deployed first.   Additional security checks and rules are necessary to stop bad actors from accessing the storage contract directly.

# Ownership
All contracts ensure the owner of the contracts can be changed.  They all implement Claimable (open-zeppelin) which ensures that a transfer involves a transfer request from the current owner and a subsequent claim/accept from the pending owner before ownership changes.   In the case of the registries added protection was required to ensure that pending owners were verified.  This is because the owner of the member in the registry wasn't necessarily the owner of the registry itself (The registry owner is generally treat as a super user with elevated privileges).   Therefore transferral of member ownership requires the existing owner to generate a transfer key. It is expected that the transfer key is given to the pending owner by some other means (outside of the contract). The current owner must provide a hash of the transfer key which initiating a transfer.   This hash is stored in the contract.  When the pending owner accepts/claims ownership they must provide the transfer key (not a hash).  The contract then generates a hash of the transfer key provided by the pending owner and ensures it matches the hash of the key provided previously.  This mechanism provides increased confidence that the new owner is the intended owner and that they know a secret provided to them by the previous owner.

# Oracle
The registry contracts employ a fee for each member being registered or transferred.  It made sense not to bake this fee into the contract as it is likely to fluctuate over time.  Therefore the fee checker was abstracted into an interface (IFeeLookup).  A separate oraclize based contract is in charge of keeping the fee up to date and returning it to the registries.  This has security implications - as it really is just a URL lookup which could be the basis of a man in the middle attack.  It is important that the URL for the lookup would be a verifiable URL over SSL.  If it were a proteected URL then oraclize provides encryption and key exchange functionality which were beyond the scope of the requirements for VMR.  In any case, the system allows the fee checkers to be upgraded as the calling contracts store the address of the fee checkers and provide an owner restricted function to change the address.

# Libraries
All data access code was put in to a library - mainly to reduce complexity within the main contracts (registries and maintenance log) and reduce the deployment size.   The data storage libraries contain minimal logic and provide some specific get and set functions which abstract away the string literals involved in the Eternal Storage contract.  The assumption was that these libaries would be re-deployed if the core contract should require upgrading whether the bug was in the libary or the contract.   The contract itself would have an upgrade route via ENS (for registries)  or the vehicle registry (storing an upgradeable address for the maintenance log).

However - it be argued that putting the data storage code into contracts instead of libaries would be preferable.  The address of the storage contract (instead of a libary reference) could be held on the main contract (which could be changed by the owner) which would provide an easy upgrade point for fixing storage bugs.  It would also make the storage code terser as it could use some state variables instead of having to pass the same variables into every function.

# Push Pull and Elements of pre-commit
There was a need at some point to iterate over the members of a registry - or iterate over the entries in a maintenance log.  To minimise the storage and gas costs - all data is stored in mappings instead of unbounded arrays. These mappings can not be iterated.  Consequently there are no get functions to return arrays of values which also avoids EVM memory issues.  Instead each item is assigned a number (aka index) in storage which increments by one for each new item.  A get function returns the total number of items.  Another function returns the item by the number.   These two functions provide the basis for client enumeration.  It is slightly chatty in nature and could be a little slow if network speed is restriced.  However the stability and storage costs outweigh this consideration.


ERC20Basic - TokenDestructable
Wraps self destruct
Returns all tokens to owner
