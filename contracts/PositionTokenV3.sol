/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PositionTokenV3 is ERC20Votes, Ownable, Pausable {
    address public botKeeper;
    uint256 public constant MAX_SUPPLY = 100_000_000 ether;

    event BotKeeperChanged(
        address indexed previousKeeper,
        address indexed newKeeper
    );
    event TreasuryContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    modifier onlyTreasury() {
        require(msg.sender == treasuryContract, "Only treasury");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address migrateContract,
        IERC20 positionTokenV2
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        uint256 totoSupply = positionTokenV2.totalSupply();
        _mint(migrateContract, totoSupply);
    }


    function _maxSupply() internal view virtual override returns (uint224) {
        return uint224(MAX_SUPPLY);
    }

    function setTransferStatus(bool _isPaused) public {
        require(msg.sender == botKeeper, "Caller is not bot keeper");
        if (_isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setBotKeeper(address _newKeeper) public onlyOwner {
        emit BotKeeperChanged(botKeeper, _newKeeper);
        botKeeper = _newKeeper;
    }

}
