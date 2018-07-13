pragma solidity ^0.4.23;

interface IFeeLookup {
    function getFeeInWei() external view returns (uint256);
}