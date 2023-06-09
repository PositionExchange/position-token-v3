/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MigratePositionToken is Ownable, ReentrancyGuard {
    IERC20 public posiTokenV2 =
        IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
    IERC20 public posiTokenV3;

    uint256 public totalSupplyV2;
    bool public isAlreadyInit;
    mapping(address => bool) public counterParties;
    uint256 public totalMigrated;

    event Migrated(address recipient, uint256 amount);
    event RequestMigrated(address requestor, address recipient, uint256 amount);

    modifier onlyCounterParty() {
        require(counterParties[msg.sender], "Only counterParty");
        _;
    }


    function initMigrate(IERC20 positionTokenV3) external onlyOwner {
        require(!isAlreadyInit, "Initialized");
        isAlreadyInit = true;
        totalSupplyV2  = posiTokenV2.totalSupply();
        posiTokenV3 = positionTokenV3;
        _burn();
    }



    function migrate() external nonReentrant {
        require(isAlreadyInit, "Not initialized");
        address migrator = msg.sender;

        /// Get balanceBefore of Empty Address
        uint256 balanceBefore = posiTokenV2.balanceOf(emptyAddress());

        /// Get balance of Migrator and migrate
        uint256 balanceOfMigrator = posiTokenV2.balanceOf(migrator);

        /// Burn POSI v2 to empty address
        posiTokenV2.transferFrom(migrator, emptyAddress(), balanceOfMigrator);

        /// Get balanceBefore of Empty Address
        uint256 balanceAfter = posiTokenV2.balanceOf(emptyAddress());

        /// Get real balance migrated
        uint256 amountMigrated = balanceAfter - balanceBefore;

        /// Release token v3 already migrated
        posiTokenV3.transfer(migrator, amountMigrated);
        totalMigrated += amountMigrated;

        emit Migrated(migrator, amountMigrated);
    }

    function requestMigrate(
        address recipient,
        uint256 amountRequest
    ) external onlyCounterParty {
        require(isAlreadyInit, "Not initialized");
        posiTokenV3.transfer(recipient, amountRequest);
        totalMigrated += amountRequest;

        emit RequestMigrated(msg.sender, recipient, amountRequest);
    }



    function addCounterParty(address _counterParty) external onlyOwner {
        counterParties[_counterParty] = true;
    }

    function revokeCounterParty(address _counterParty) external onlyOwner {
        counterParties[_counterParty] = false;
    }


    function deadAddress() public pure returns (address) {
        return 0x000000000000000000000000000000000000dEaD;
    }

    function emptyAddress() public pure returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }


    function _burn() internal {
        uint256 balanceDead = posiTokenV2.balanceOf(deadAddress());
        uint256 balanceEmpty = posiTokenV2.balanceOf(emptyAddress());
        uint256 totalBurned = balanceDead + balanceEmpty;
        posiTokenV3.transfer(deadAddress(), totalBurned);
        totalMigrated += totalBurned;
    }

}
