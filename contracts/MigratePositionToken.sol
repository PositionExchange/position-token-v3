/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITreasury.sol";

contract MigratePositionToken is Ownable{

    IERC20 public posiTokenV2 = IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
    IERC20 public posiTokenV3;


    ITreasury public treasury;

    uint256 public totalSupplyV2;

    bool public alreadyMint;

    constructor(ITreasury _treasury,IERC20 _positionTokenV3) {
        treasury = _treasury;
        posiTokenV3 = _positionTokenV3;
        /// Mint
        totalSupplyV2 = posiTokenV2.totalSupply();

    }


    function mintTotalSupply() external onlyOwner {
        require(!alreadyMint, "Minted");
        alreadyMint = true;
        treasury.position(address(this), totalSupply);
        _burn();
    }



    function _burn() internal {
        uint256 balanceDead = posiTokenV2.balanceOf(0x000000000000000000000000000000000000dead);
        uint256 balanceEmpty =  posiTokenV2.balanceOf(0x0000000000000000000000000000000000000000);
        posiTokenV3.transfer(0x000000000000000000000000000000000000dead, balanceDead + balanceEmpty);
    }

    function migrate() external {
        require(alreadyMint, "Minted");

    }


}
