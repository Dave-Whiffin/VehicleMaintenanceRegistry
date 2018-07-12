pragma solidity ^0.4.23;

import "./IRegistryFeeLookup.sol";
import "../installed_contracts/oraclize-api/contracts/usingOraclize.sol";

contract RegistryFeeChecker is usingOraclize, IRegistryFeeLookup {

    event OraclizeCallBack(bytes32 queryId, string result);
    event NewOraclizeQuery(string description);
    event NewRegistrationPrice(uint256 price);

    uint256 public registrationPriceWei;
    uint private refreshSeconds;
    mapping(bytes32=>bool) validIds;
    uint256 public oraclizeUrlQueryPrice;
    bool public autoRefresh;

    constructor (uint _refreshSeconds, uint256 _initialRegistrationPriceWei, bool _autoRefresh) public {
        refreshSeconds = _refreshSeconds;
        registrationPriceWei = _initialRegistrationPriceWei;
        autoRefresh = _autoRefresh;
        //oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        if(autoRefresh)
        {
            emit NewOraclizeQuery("Auto refresh is turned on, triggering updatePrices");
            updatePrices();
        }
        else{
            emit NewOraclizeQuery("Auto refresh is off - call updatePrices to trigger an update");
        }
    }

    function getRegistrationFeeWei() external view returns (uint256) {
        return registrationPriceWei;
    }

    function getTransferFeeWei() external view returns (uint256) {
        //for now tfr fee = reg fee (interface allows it to be different in the future)
        return registrationPriceWei;
    }       

    function __callback(bytes32 _queryId, string _result) public {

        emit OraclizeCallBack(_queryId, _result);

        require(msg.sender == oraclize_cbAddress(), "the msg.sender for the callback was not the oraclize_cbAddress");
        require(validIds[_queryId], "the _queryId was not valid");

        uint newFee = parseInt(_result);

        if(newFee != registrationPriceWei){
            registrationPriceWei = newFee;
            emit NewRegistrationPrice(registrationPriceWei);
        }
    
        delete validIds[_queryId];

        if(autoRefresh)
        {
            updatePrices();
        }
    }

    function updatePrices() public payable {
        //"json(https://www.dropbox.com/s/8hjew52p5b5p1tt/sample-fees.json?dl=1).prices.registration.wei"

        oraclizeUrlQueryPrice = oraclize_getPrice("URL");

        if (oraclizeUrlQueryPrice > address(this).balance) {
            emit NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit NewOraclizeQuery("Oraclize query was sent - waiting for the answer");
            bytes32 queryId = oraclize_query(refreshSeconds, "URL", "json(https://www.dropbox.com/s/8hjew52p5b5p1tt/sample-fees.json?dl=1).prices.registration.wei");
            validIds[queryId] = true;
        }
    }
}