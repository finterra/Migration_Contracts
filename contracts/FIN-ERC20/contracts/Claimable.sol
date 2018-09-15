pragma solidity ^0.4.24;

import "../../FIN-POINT-RECORD/contracts/FINPointRecord.sol";
import "../../openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Claimable
 * @dev The Claimable contract accepts a claimable records contract address for reference to records and accounts the can claim tokens, and provides basic authorization control
 * for the minting functions, this simplifies the implementation of "minting permissions".
 */


contract Claimable is Ownable {
    // FINPointRecord var definition
    FINPointRecord public finPointRecordContract;

    // an address map used to store the mintAllowed flag, so we do not mint more than once
    mapping (address => bool) public isMinted;

    event RecordSourceTransferred(
        address indexed previousRecordContract,
        address indexed newRecordContract
    );


    /**
    * @dev The Claimable constructor sets the original `claimable record contract` to the provided _claimContract
    * address.
    */
    constructor(FINPointRecord _finPointRecordContract) public {
        finPointRecordContract = _finPointRecordContract;
    }


    /**
    * @dev Allows to change the record information source contract.
    * @param _newRecordContract The address of the new record contract
    */
    function transferRecordSource(FINPointRecord _newRecordContract) public onlyOwner {
        _transferRecordSource(_newRecordContract);
    }

    /**
    * @dev Transfers the reference of the record contract to a newRecordContract.
    * @param _newRecordContract The address of the new record contract
    */
    function _transferRecordSource(FINPointRecord _newRecordContract) internal {
        require(_newRecordContract != address(0));
        emit RecordSourceTransferred(finPointRecordContract, _newRecordContract);
        finPointRecordContract = _newRecordContract;
    }
}