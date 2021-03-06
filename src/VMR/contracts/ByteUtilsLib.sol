pragma solidity ^0.4.23;

/** @title Byte Utils Lib.
  * @dev Utils library for bytes32.
 */
library ByteUtilsLib {

    /** @dev creates a string from a bytes32.
      * @param x the bytes32 input value.
      */
    function bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /** @dev converts the bytes32 parameter to a string and returns the length.
      * @param x the bytes32 input value.
      */
    function getStringLength(bytes32 x) public pure returns (uint) {
        string memory s = bytes32ToString(x);
        return bytes(s).length;        
    }
}