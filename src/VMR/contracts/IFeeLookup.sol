pragma solidity ^0.4.23;

/** @title Fee Lookup interface - indicates a contract can return a fee for a specific purpose. */
interface IFeeLookup {

    /** @dev Returns the fee in Wei.
      */
    function getFeeInWei() external view returns (uint256);
}