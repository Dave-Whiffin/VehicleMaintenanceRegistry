Vehicle Maintenance Registry (VMR)
==================================

# An on-chain digital log book for all vehicle maintenance work

Instead of having a paper based log book which is stamped thoughout the life of the vehicle, on on-chain version provides:

* accessibility to anyone to view history
* immutable log records
* IPFS proof of work docs
* vehicle ownership checks
* protection against information loss
* protection from log tampering by bad actors
* protection against fraudelent claims of work done to the vehicle
* Small registration and transfer fees for the related registries

# The Primary dApp.

## User Stories

Actors:
 - Vehicle Owner
 - Maintainer
 - Anyone

### 1 - The Vehicle Owner Authorizes a maintainer to work on the vehicle
The owner opens up the web app.  They view the vehicle details and opens the maintenance log.  The web app recognises that they own the vin and provides an option to authorise a maintainer.  They specify a known id for the maintainer and submit. The app confirms success.  The maintainer is now able to log work against the vehicle.

### 2 - The Maintainer logs an entry in to the maintenance log
The maintainer opens up the web app, they find the vehicle and opens the maintenance log.  The app recognises that they are authorised to log work for the vin.  The maintainer adds a job id, title, description and a document to the log. The maintainer has added the log which the vehicle owner can then check and verify.

### 3 - The Vehicle Owner verifies the log entry
The owner opens the web app and finds their vehicle and opens the maintenance log.  The app recognises they own the vin and provides an option to verify against non-verified log entries. They click "verify" which verifies the log entry.  This allows anyone to see that they authorised the work and verified it was done.

### 4 - Anyone can view the maintenance log for a vehicle:
Anyone opens the web app and finds the vehicle.  The basic vehicle details are displayed including attributes.  Anyone can view the maintenance log and see the log entries and maintainers linked to it.  They are presented with each log entry and an option to view documents for each.  They can see whether or not a log was verified.

### Caveats and Assumptions:
* App tested against Chrome Version 67.0.3396.99 (Official Build) (64-bit)
* Manufacturer, Maintainer and Vehicle registry will be pre populated with static data.
* The vehicle owner will be one of the auto generated ganache-cli addresses.

Notes (for UI implementation):
* Get the maintenance log address from the vehicle registry.
* Get the log information from the maintenance log
    * To iterate through all logs:
        * Logs are numbered sequentially from 1
        * Get the log count and iterate the number to retrieve each log
        * The docs for each log are also sequentially numbered and can be iterated in the same way
    * The log number can be retrieved from a known log entry id.

# Registries
There are registries for maintainers, manufacturers and vehicles.  These are important as the maintenance log has dependencies on them. Their related contracts are fully tested. However the primary focus of the Dapp is the vehicle maintenance log which is not focussed on the process of membership and transferral.  The other registries will be populated with static data in order for the Dapp to run.  Separate Dapps could be built for each registry or using a combination of them for different use cases.

# Primary Solidity Contracts

## Eternal Storage
All the primary contracts store their state data in a seperate Eternal Storage contract.  This ensures contracts which use this storage can be upgraded easier and that extensible data can be stored without corruption.  Primarily the eternal storage contract is just a series of key value mappings for specific types which is easy to test and unlikely to require an upgrade. It is deliberately limited in scope in order to verify that it works and limit the chance of bugs.

Thanks to this article for providing the basis of this contract.
[Rocket Pool article on Medium](https://medium.com/rocket-pool/upgradable-solidity-contract-design-54789205276d)

Getters and Setters are available for:
* address
* bytes32
* bool
* uint256
* string

### Permissions
Whilst the storageInitialised flag is false - only the owner can change data (call set functions).
When it is true - only the contract address can change data (call set functions);

Binding the storage to a contract address:
* The owner of eternal storage:
    * Calls setContractAddress(<addres of contract>)
    * Calls setStorageInitialised(<true>)

Binding the storage to a contract address:
* The owner of eternal storage:
    * Calls setContractAddress(<addres of contract>)

## Maintenance Log
A maintenance log contract holds the complete maintenance history for a specific vehicle.

The first owner of a vehicle (the manufacturer) is expected to deploy a maintenance log contract and record it in the vehicle registry so that it can be seen by anybody with an interest in the vehicle.  This log is expected to live as long as the vehicle does. However, it can be upgraded if necessary.  This is because it's data is stored in a seperate eternal storage contract and it's address can be updated in the vehicle registry.

The log is tied to a specific VIN on construction.
The log can only be created by the owner of the VIN, this is verified by a Vehicle Registry Lookup.
The owner can add authorisation for a maintainer to log work on the VIN.
An authorised maintainer can add a log entry to describe what they did to the vehicle (maintainerid, date, title, description)
The vehicle owner can then add a verification to that log entry 
    (verified (true), verifer (address of VIN owner), verification date)

The list of authorised maintainers is cleared when the vehicle changes ownership to prevent old maintainers from being automatically authorised by the new vehicle owner.
It has a link to the maintainer registry so it can see which vehicle maintainers are registered and enabled and who their owner is.

When the vehicle is sold - the current owner must:
* Transfer ownership in the Vehicle Registry
     (sets the pending owner plus stores a specific key hash). The new owner must accept ownership in the Vehicle Registry by passing in the key.
* Transfer the ownership of the maintenance log to the new VIN owner.
    the new owner must claim ownership before ownership.

Data / State Storage
* EternalStorage contract.
* Data manipulation and querying is done via the MaintenanceLogStoragLib.

## Registry
This is a contract which provides the core registry functionality.  It's not an abstract contract, it can be used on it's own.  For VMR it provides a base contract for Maintainer, Manufacturer and Vehicle registry contracts.

It implements the IRegistyLookup which provides a loosely coupled option for other contracts to read from a registry.

The contract imposes a fee for each registration or transfer. On construction the registry is passed the address of a contract implementing IFeeChecker.  This contract is responsible for returning the fee amount. 

Each member of the registry 
* is registered with a user defined but unique reference (bytes32)
* is assigned a member number
* has an owner
* can have attributes added to it (type, name, value) 
* can be transferred to a different owner (transfer, accept using key exchange)

Data / State Storage
* EternalStorage contract.
* Data manipulation and querying is done via the MaintenanceLogStoragLib.

## Manufacturer Registry (inherits Registry)
A registry of manufacturers, primarily controlled by the owner of the registry contract.  

Member Id would likey to be a short version of the manufacturers name.

New members can only be added by the manufacturer registry contract owner.

For VMR it provides a trustworthy source of manufacturer verification and ownership.  

## Maintainer Registry (inherits Registry)
A registry of vehicle maintainers (garages, engineers, servicing organisations etc).

For VMR it provides a trustworthy source of maintainers which the maintenance log contract can reference.

New members can only be added by the manufacturer registry contract owner.

## Vehicle Registry (inherits Registry)
A registry of vehicles.  Only registered manufacturers can register new vehicles.  Manufacturers can transfer ownership to the purchaser later.

### registerVehicle (registerMember is disabled and will throw)
The function Registry.registerMember is overridden and disabled. The function registerVehicle should be used instead.  This accepts a VIN and the manufacturer id.  The manufacturer id is stored as an attribute against the vehicle which can not be changed.  The sender must be the owner of the manufacturer.  Only manufacturers can register cars.

### set and get maintenance Log Address
The maintenance log address can be stored by the vehicle owner in the vehicle registry.  This allows anyone to discover it.  It also allows the vehicle owner to upgrade the maintenance log contract and change the address in the future.

Member Id is the VIN (vehicle identification number).

For VMR it provides a trustworthy source of vehicle verification and ownership as it implements IRegistryLookup.  This allows the maintenance log to ensure the caller is the owner of the vehicle by calling the vehicle registry.

## Fee Checker
This is an oracle source of fees relied upon by the registries.  A seperate instance would be expected to support each registry.  It can be set to auto update using oraclize.  It supports looking up a single fee via an oraclize URL query.  For simplicity the registries use the same lookup for both registration and transfer fees.  However the registries could be changed to have a separate instance of the fee checker for each fee they need to monitor.

# Fees

Each registry charges a fee for every new registration and every transfer.  This rewards the owner of the registry.  In the case of manufacturer and maintainer registries the owner is only rewarded for transfer.  The owner is the only one allowed to add members and therefore they would have to pay the fee if one was set but ultimately the balance on the contract is owned by them anyway so they do not lose out.

There is no fee associated with the maintenance log.

## Main actors

### Manufacturer Registry Owner (ManuAuth)
This party deploys the registry and becomes the owner.  All new manufacturers can only be added by the ManuAuth and are initially owned by the ManuAuth.  It is likely that some human intervention and checks take place before a member is added to the registry and this is why initial membership is restricted to the MaintAuth.  As the number of manufacturers is relatively small then this is manageable. 

The ownership of a specific manufacturer can be transferred by the ManuAuth to another account and that account would need to accept ownership before the ownership actually changes.

### Maintainer Registry Owner (MaintAuth)
This party deploys the registry and becomes the owner.  All new maintainers can only be added by this party and are initially owned by this party.  It is likely that some human intervention and checks take place before a member is added to the registry and this is why initial membership is restricted to this party.

The ownership of a specific maintainer can be transferred by this party to another account and that account would need to accept ownership before the ownership actually changes.

### Vehicle Registry Owner
This party deploys the registry and becomes the owner. Unlike the other registries, this party has not got permission to add members automatically.  Only registered and enabled manufacturer owners can add vehicles for that manufacturer.

The ownership of a specific vehicle can be transferred by the current owner to another account and that account would need to accept ownership before the ownership actually changes.

# Mock Contracts For Testing
The following contracts were created to allow dependant contracts to be tested with mocked dependencies.

## MockRegistryLookup
Implements IRegistryLookup.

## MockFeeChecker
Implements IFeeChecker.