// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { ITournament } from "./interfaces/ITournament.sol";
import { IAave } from "./interfaces/IAave.sol";
import { Tournament } from "./Tournament.sol";
import "hardhat/console.sol";

contract TournamentFactory is ITournamentFactory, ERC721, Ownable {
    mapping(address => bool) public tournaments;
    /// @dev tournament => warriorID => claimedFlag
    mapping(address => mapping(uint256 => Status)) public history;
    /// @dev storing all warriors taking part in all tournaments
    mapping(uint256 => WarriorData) public warriors;
    uint256 public counter;
    uint256 public mintPrice;
    bool public transferrable;
    address public defaultBattleHandler;

    // Aave addresses on Polygon
    address public constant aave = 0x1e4b7A6b903680eab0c5dAbcb8fD429cD2a9598c;
    address public constant atoken = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;
    address public constant pool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    event NewTournamentCreated(address indexed tournament, uint256 duration);
    event PrizeWasRedeemed(address indexed tournament, uint256 indexed warriorID, uint256 score, uint256 prize);

    error Invalid_Duration();
    error Invalid_Value_Transferred();
    error Warrior_Not_Playing(address tournament, uint256 warriorID);
    error Warrior_Not_Eligible_For_A_Prize(address tournament, uint256 warriorID);
    error Already_Claimed(address tournament, uint256 warriorID);

    constructor(
        string memory name,
        string memory symbol,
        uint256 price,
        bool _transferrable,
        address _defaultBattleHandler
    ) ERC721(name, symbol) {
        counter = 0;
        mintPrice = price;
        transferrable = _transferrable;
        defaultBattleHandler = _defaultBattleHandler;

        // Approve aToken to be used by Aave
        IERC20(atoken).approve(aave, type(uint256).max);
    }

    modifier onlyTournament() {
        assert(tournaments[msg.sender]);
        _;
    }

    // -------- Admin functions --------

    function toggleTransferrability(bool val) external onlyOwner {
        transferrable = val;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setDefaultBattleHandler(address handler) external onlyOwner {
        defaultBattleHandler = handler;
    }

    function newTournament(
        uint256 price,
        uint256 duration,
        uint256 lifePoints
    ) external override onlyOwner {
        if (duration < 1 days) revert Invalid_Duration();

        address tournament = address(new Tournament(price, duration, lifePoints, defaultBattleHandler));
        //console.log(tournament);
        tournaments[tournament] = true;

        emit NewTournamentCreated(tournament, duration);
        //console.log(duration);
    }

    // -------- User-facing functions --------

    function mint(uint8 skill) external payable {
        if (msg.value != mintPrice) revert Invalid_Value_Transferred();

        _mint(msg.sender, counter++);

        warriors[counter] = WarriorData(0, ITournamentFactory.SkillType(skill));

        IAave(aave).depositETH{ value: msg.value }(pool, address(this), 0);
    }

    function getWarriorData(uint256 id) external view override returns (WarriorData memory) {
        return warriors[id];
    }

    function enlist(address _tournament, uint256 warriorID) external payable override {
        assert(ownerOf(warriorID) == msg.sender);

        ITournament tournament = ITournament(_tournament);
        if (msg.value != tournament.priceToJoin()) revert Invalid_Value_Transferred();
        tournament.enlist(warriorID);
    }

    function redeemPrize(address _tournament, uint256 warriorID) external {
        assert(ownerOf(warriorID) == msg.sender);

        if (history[_tournament][warriorID] != Status.WINNER)
            revert Warrior_Not_Eligible_For_A_Prize(_tournament, warriorID);
        if (history[_tournament][warriorID] == Status.PRIZE_REDEEMED) revert Already_Claimed(_tournament, warriorID);

        // we enforce a check-effect pattern to prevent reentrancy vulnerabilities
        history[_tournament][warriorID] = Status.PRIZE_REDEEMED;

        ITournament tournament = ITournament(_tournament);
        uint256 totalPax = tournament.totalPax();
        uint256 totalPrize = tournament.totalPrize();
        uint256 score = tournament.scores(warriorID);
        uint256 prize = (totalPax - score) / totalPrize;

        IAave(aave).withdrawETH(pool, prize, msg.sender);

        emit PrizeWasRedeemed(_tournament, warriorID, score, prize);
    }

    // -------- Hooks and internal functions --------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        assert(transferrable); // soulbound NFTs
        super._beforeTokenTransfer(from, to, tokenId,batchSize);
    }

    function deathHook(uint256 warriorID, bool winner) external override onlyTournament {
        history[msg.sender][warriorID] = winner ? Status.WINNER : Status.PARTICIPANT;
        // do something
    }
}
