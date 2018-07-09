pragma solidity ^0.4.23;

interface IVehicleRegistry {

    function register(bytes32 _VIN, bytes32 _licencePlate, bytes32 _manufacturerName) external payable;
    function isRegistered(bytes32 _VIN) external view returns (bool);

    function getVehicleManufacturerName(bytes32 _VIN) external view returns (bytes32 manufacturerName);
    function getVehicleLicencePlate(bytes32 _VIN) external view returns (bytes32 licencePlate);
    function getVehicleOwner(bytes32 _VIN) external view returns (address owner);
    function getVehicleMaintenanceLogAddress(bytes32 _VIN) external view returns (address maintenanceLogAddress);
    function getVehicleRegisteredDate(bytes32 _VIN) external view returns (uint256 registeredDate);

    function transferVehicleOwnership(bytes32 _VIN, address _newOwner, bytes32 _keyHash) external payable;
    function acceptVehicleOwnership(bytes32 _VIN, bytes32 _keyHash) external payable;
    function setVehicleMaintenanceLogAddress(bytes32 _VIN, address _serviceHistoryAddress) external payable;

    event Registered(bytes32 indexed _VIN);
    event VehicleOwnershipTransferRequest(bytes32 indexed _VIN, address indexed _from, address indexed _to);
    event VehicleOwnershipTransferAccepted(bytes32 indexed _VIN, address indexed _newOwner);
    event VehicleMaintenanceLogAddressChanged(bytes32 indexed _VIN, address indexed _from, address indexed _to);
}