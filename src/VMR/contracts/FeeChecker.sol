pragma solidity ^0.4.23;

import "./IFeeLookup.sol";
import "../installed_contracts/oraclize-api/contracts/usingOraclize.sol";
import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Claimable.sol";

contract FeeChecker is usingOraclize, IFeeLookup, Pausable, Claimable {

    event OraclizeCallBack(bytes32 queryId, string result);
    event NewOraclizeQuery(string description);
    event FeeChanged(uint256 fee);

    uint256 public feeInWei;
    uint public refreshSeconds;
    mapping(bytes32=>bool) public validIds;
    uint256 public oraclizeUrlQueryPrice;
    bool public autoRefresh;
    string public query;

    modifier isSenderAllowedToUpdateFee() {
        require(msg.sender == owner || msg.sender == oraclize_cbAddress(), "Sender is not allowed to update fees");
        _;
    }

    constructor (string _query, uint _refreshSeconds, uint256 _initialFeeInWei, bool _autoRefresh) public {
        query = _query;
        refreshSeconds = _refreshSeconds;
        feeInWei = _initialFeeInWei;
        autoRefresh = _autoRefresh;

        //from ethereum-bridge
        //ensure that the mnemonic used to start ganache is
        //ganache-cli --mnemonic "VMR Tests --accounts 50"
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

        emit NewOraclizeQuery(query);

        //oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        if(autoRefresh)
        {
            emit NewOraclizeQuery("Auto refresh is turned on, triggering updatePrices");
            updateFee();
        }
        else{
            emit NewOraclizeQuery("Auto refresh is off - call updatePrices to trigger an update");
        }
    }

    function getFeeInWei() external view whenNotPaused() returns (uint256) {
        return feeInWei;
    }

    function __callback(bytes32 _queryId, string _result) public whenNotPaused() {

        emit OraclizeCallBack(_queryId, _result);

        require(msg.sender == oraclize_cbAddress(), "the msg.sender for the callback was not the oraclize_cbAddress");
        require(validIds[_queryId], "the _queryId was not valid");

        uint newFee = parseInt(_result);

        if(newFee != feeInWei){
            feeInWei = newFee;
            emit FeeChanged(feeInWei);
        }
    
        delete validIds[_queryId];

        if(autoRefresh)
        {
            updateFee();
        }
    }

    function updateFee() public payable whenNotPaused() isSenderAllowedToUpdateFee() {

        oraclizeUrlQueryPrice = oraclize_getPrice("URL");

        if (oraclizeUrlQueryPrice > address(this).balance) {
            emit NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit NewOraclizeQuery("Oraclize query was sent - waiting for the answer");
            bytes32 queryId = oraclize_query(refreshSeconds, "URL", query);
            validIds[queryId] = true;
        }
    }
}