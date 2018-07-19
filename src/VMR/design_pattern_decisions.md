
VMR - Design Decisions
======================

# Emergency Stop

# Contract Size

# Loose Coupling

# Upgradability

# Ownership

# Oracle


pre-commit 

ERC20Basic - TokenDestructable
Wraps self destruct
Returns all tokens to owner

Emergency Stop - Pausable
whenPaused
whenNotPaused

Transfer Ownership - (with accept) Claimable
ensure the pending owner exists and accepts

TransferKey - storing hash of transfer key to save space and keep the key secret
New owner must provide the unhashed key, the contract hashes and compares with stored hash.