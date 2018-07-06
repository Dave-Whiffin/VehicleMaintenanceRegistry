pragma solidity ^0.4.23;

import "../installed_contracts/oraclize-api/contracts/usingOraclize.sol";

contract VehicleRegistryPriceChecker is usingOraclize {

    uint public RegistrationPriceEth;

    event newOraclizeQuery(string _description);
    event newRegistrationPrice(string price);

    constructor () public {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        updatePrices();
    }

    function __callback(bytes32 myid, string result) public {
        require(msg.sender == oraclize_cbAddress());
        emit newRegistrationPrice(result);
        RegistrationPriceEth = parseInt(result);
    }

    function updatePrices() public payable {

        if (oraclize_getPrice("URL") > address(this).balance) {
            //emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize query was sent - waiting for the answer");
            oraclize_query(60, "URL", "json(https://pricehost.com/vehicleregistration/prices).prices.registration.ETH");
        }
    }
}