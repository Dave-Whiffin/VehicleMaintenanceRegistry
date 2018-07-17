pragma solidity ^0.4.23;

library PGL1 {

    struct Member {
        uint256 memberNumber;
        bytes32 memberId;
    }

    struct MemberStorage {
        uint256 count;
        mapping(uint256 => Member) members;
    }

    function saveMember(MemberStorage storage _storage, bytes32 _memberName) internal returns (uint256) {

        _storage.count = _storage.count + 1;
        uint256 memberNumber = _storage.count;
        _storage.members[_storage.count] = Member(memberNumber, _memberName);
        return memberNumber;
    }

    function saveMember(MemberStorage storage _storage, Member storage _member) internal returns (uint256) {

        if(_member.memberNumber == 0){
            _storage.count = _storage.count + 1;
            _member.memberNumber = _storage.count;
        }
        _storage.members[_member.memberNumber] = _member;
        return _member.memberNumber;
    }    

    function getMember(MemberStorage storage _storage, uint _memberNumber) internal view returns (Member storage) {
        return _storage.members[_memberNumber];
    }

    function getMemberTest(uint256 _memberNumber) internal view returns (Member memory) {
        Member memory m = Member({memberNumber: _memberNumber, memberId: ""});
        return m;
        //return _storage.members[_memberNumber];
    }    
}

contract PGC1 {

    PGL1.MemberStorage members;

    function saveMember(bytes32 _memberId) public returns (uint256) {
        return PGL1.saveMember(members, _memberId);
    }

    function getMember() public view returns (uint256 memberNumber, bytes32 memberId) {
        PGL1.Member memory m = PGL1.getMemberTest(memberNumber);
        return (m.memberNumber, m.memberId);
    }
}

