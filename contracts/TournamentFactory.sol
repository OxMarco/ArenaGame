// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { ITournament } from "./interfaces/ITournament.sol";
import { Tournament } from "./Tournament.sol";

contract TournamentFactory is ITournamentFactory, ERC721, Ownable {
    mapping(address => bool) public tournaments;
    /// @dev tournament => warriorID => claimedFlag
    mapping(address => mapping(uint256 => Status)) public history;
    /// @dev storing all warriors taking part in all tournaments
    mapping(uint256 => WarriorData) public warriors;
    uint256 public counter;
    uint256 public mintPrice;
    bool public transferrable;

    event NewTournamentHasStarted(address indexed tournament, uint256 duration);
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
        bool _transferrable
    ) ERC721(name, symbol) {
        counter = 0;
        mintPrice = price;
        transferrable = _transferrable;
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

    function newTournament(
        uint256 price,
        uint256 duration,
        uint256 lifePoints
    ) external override onlyOwner {
        if (duration < 1 days) revert Invalid_Duration();

        address tournament = address(new Tournament(price, duration, lifePoints));
        tournaments[tournament] = true;

        emit NewTournamentHasStarted(tournament, duration);
    }

    // -------- User-facing functions --------

    function mint() external payable {
        if (msg.value != mintPrice) revert Invalid_Value_Transferred();

        _mint(msg.sender, counter++);
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
        if (history[_tournament][warriorID] == Status.PRIZE_REDEEMED)
            revert Already_Claimed(_tournament, warriorID);
        history[_tournament][warriorID] = Status.PRIZE_REDEEMED;

        ITournament tournament = ITournament(_tournament);
        uint256 totalPax = tournament.totalPax();
        uint256 totalPrize = tournament.totalPrize();
        uint256 score = tournament.scores(warriorID);
        uint256 prize = (totalPax - score) / totalPrize;

        // we enforce a check-effect pattern to prevent reentrancy vulnerabilities
        payable(msg.sender).transfer(prize);

        emit PrizeWasRedeemed(_tournament, warriorID, score, prize);
    }

    // -------- Hooks and internal functions --------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        assert(transferrable); // soulbound NFTs
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function deathHook(uint256 warriorID, bool winner) external override onlyTournament {
        history[msg.sender][warriorID] = winner ? Status.WINNER : Status.PARTICIPANT;

        // do something
    }
}
