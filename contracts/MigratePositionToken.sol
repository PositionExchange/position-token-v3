/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ITreasury.sol";

contract MigratePositionToken is Ownable, ReentrancyGuard {
    IERC20 public posiTokenV2 =
        IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
    IERC20 public posiTokenV3;

    ITreasury public treasury;
    uint256 public totalSupplyV2;
    bool public alreadyMint;
    mapping(address => bool) public counterParty;
    uint256 public totalMigrated;

    event Migrated(address recipient, uint256 amount);
    event RequestMigrated(address requestor, address recipient, uint256 amount);

    modifier onlyCounterParty() {
        require(counterParty[msg.sender], "Only counterParty");
        _;
    }

    constructor(ITreasury _treasury, IERC20 _positionTokenV3) {
        treasury = _treasury;
        posiTokenV3 = _positionTokenV3;
        /// Mint
        totalSupplyV2 = posiTokenV2.totalSupply();
    }



    function migrate() external nonReentrant {
        require(alreadyMint, "Minted");
        address migrator = msg.sender;
        uint256 balanceBefore = posiTokenV2.balanceOf(emptyAddress());
        uint256 balanceOfMigrator = posiTokenV2.balanceOf(migrator);
        posiTokenV2.transferFrom(migrator, emptyAddress(), balanceOfMigrator);
        uint256 balanceAfter = posiTokenV2.balanceOf(emptyAddress());
        uint256 amountMigrated = balanceAfter - balanceBefore;
        posiTokenV3.transfer(migrator, amountMigrated);
        totalMigrated += amountMigrated;

        emit Migrated(migrator, amountMigrated);
    }

    function requestMigrate(
        address recipient,
        uint256 amountRequest
    ) external onlyCounterParty {
        require(alreadyMint, "Minted");
        posiTokenV3.transfer(recipient, amountRequest);
        totalMigrated += amountRequest;

        emit RequestMigrated(msg.sender, recipient, amountRequest);
    }



    function mintTotalSupply() external onlyOwner {
        require(!alreadyMint, "Minted");
        alreadyMint = true;
        treasury.mint(address(this), totalSupplyV2);
        _burn();
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
        posiTokenV3.transfer(emptyAddress(), totalBurned);
        totalMigrated += totalBurned;
    }

}
