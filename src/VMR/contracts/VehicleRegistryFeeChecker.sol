pragma solidity ^0.4.23;

import "./IVehicleRegistryFeeChecker.sol";
import "../installed_contracts/oraclize-api/contracts/usingOraclize.sol";

contract VehicleRegistryFeeChecker is usingOraclize, IVehicleRegistryFeeChecker {

    uint256 public registrationPriceEth;
    string private oracleQuery;
    uint private refreshSeconds;

    function getRegistrationFeeEth() external view returns (uint256) {
        return registrationPriceEth;
    }

    function getTransferFeeEth() external view returns (uint256) {
        //for now tfr fee = reg fee (interface allows it to be different in the future)
        return registrationPriceEth;
    }    

    event NewOraclizeQuery(string _description);
    event NewRegistrationPrice(string price);

    constructor (string _oracleQuery, uint _refreshSeconds) public {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        updatePrices();
        oracleQuery = _oracleQuery;
        refreshSeconds = _refreshSeconds;
    }

    function __callback(bytes32 myid, string result) public {
        require(msg.sender == oraclize_cbAddress());
        registrationPriceEth = parseInt(result);
        emit NewRegistrationPrice(result);
    }

    function updatePrices() public payable {
        // "json(https://pricehost.com/vehicleregistration/prices).prices.registration.ETH"

        if (oraclize_getPrice("URL") > address(this).balance) {
            emit NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit NewOraclizeQuery("Oraclize query was sent - waiting for the answer");
            oraclize_query(refreshSeconds, "URL", oracleQuery);
        }
    }
}