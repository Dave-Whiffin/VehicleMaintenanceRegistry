pragma solidity ^0.4.23;

interface IVehicleRegistry {

    function register(bytes32 _VIN, bytes32 _licencePlate, bytes32 _manufacturerName) external payable;
    function isRegistered(bytes32 _VIN) external view returns (bool);

    function getVehicleManufacturerName(bytes32 _VIN) external view returns (bytes32 manufacturerName);
    function getVehicleLicencePlate(bytes32 _VIN) external view returns (bytes32 licencePlate);
    function getVehicleOwner(bytes32 _VIN) external view returns (address owner);
    function getVehicleServiceHistoryAddress(bytes32 _VIN) external view returns (address serviceHistoryAddress);
    function getVehicleRegisteredDate(bytes32 _VIN) external view returns (uint256 registeredDate);

    function transferVehicleOwnership(bytes32 _VIN, address _newOwner, bytes32 _keyHash) external payable;
    function acceptVehicleOwnership(bytes32 _VIN, bytes32 _keyHash) external payable;
    function setServiceHistoryAddress(bytes32 _VIN, address _serviceHistoryAddress) external payable;

    event Registered(bytes32 _VIN);
    event VehicleOwnershipTransferRequest(bytes32 _VIN, address _from, address _to);
    event VehicleOwnershipTransferAccepted(bytes32 _VIN, address _newOwner);
    event VehicleServiceHistoryAddressChanged(bytes32 _VIN, address _from, address _to);
}