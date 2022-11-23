// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITournament {
    function isActive() external view returns (bool);

    function enlist(uint256 warriorID) external;

    function start() external;

    //function dailyCombat() external;
    function battle(uint256 attackerID, uint256 defenderID) external;

    function randomBattle(uint256 attackerID, uint256 defenderID) external;

    function priceToJoin() external view returns (uint256);

    function totalPax() external view returns (uint256);

    function totalPrize() external view returns (uint256);

    function hasPlayed(uint256 warriorID) external view returns (bool);

    function scores(uint256 warriorID) external view returns (uint256);
}