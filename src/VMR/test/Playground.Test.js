import assertRevert from '../node_modules/openzeppelin-solidity/test/helpers/assertRevert';

var PG1C = artifacts.require('PG1C');

contract('PG1C', function (accounts) {

    let c;

    before(async function(){
        c = await PG1C.new();
    });
    
    it("test 1", async function() {
        
    });
});