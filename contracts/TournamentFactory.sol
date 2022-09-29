// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { Tournament } from "./Tournament.sol";

contract TournamentFactory is ITournamentFactory, ERC721 {
    address[] public tournaments;
    mapping(uint256 => WarriorData) public warriors;

    event NewTournamentHasStarted(address indexed tournament, uint256 duration);
    error Invalid_Duration();

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function newTournament(
        uint256 price,
        uint256 duration,
        uint256 lifePoints
    ) external override {
        if (duration < 1 days) revert Invalid_Duration();

        address tournament = address(new Tournament(price, duration, lifePoints));
        tournaments.push(tournament);

        emit NewTournamentHasStarted(tournament, duration);
    }

    function deathHook(uint256 warriorID) external override {
        address tournament = msg.sender;

        // do something
    }

    function getWarriorData(uint256 id) external view override returns (WarriorData memory) {
        return warriors[id];
    }
}
