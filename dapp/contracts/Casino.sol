pragma solidity ^0.5.0;

import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./games/Game.sol";
import "./games/Dice.sol";
import "./games/Roulette.sol";
import "./Utility.sol";

contract Casino is Ownable{ //Ownable allows using onlyOwner modifier so we can make admin functions

	using SafeMath for uint256; //Using SafeMath lib to avoid overflow errors
	using SafeMath for uint8;

	//Variables
	// uint256 casinoBalance = 0;
	Game[] games;
	// bool gameSet = false;
	// struct PlayerInfo{
	// 	string name;
	// 	bool gameSet;
	// }
	mapping (address => Game) public gamesMap; //address : currentPlayer ; Game : Dice or Roulette contract
	// mapping (address => PlayerInfo) public playerInfoMap; //address : currentPlayer ; PlayerInfo : player infos structure

	//Events
	//the player is playing to the game
	event EventGameSet(address player, uint gameType);
	//the player has bet
	event EventBet(address player , string betInfo, uint8 bet, uint256 money);
	//the player has played and got this result
	event EventResult(address player, uint8 result);
	//current player's bet has been canceled, this amount of money has been sent back
	event EventCancelBet(address player, uint256 amount);
	//player earned the amount of money
	event EventPlayerReceives(address player, uint256 amount);

	//Constructor
	constructor() public{
		games.push(new Dice());
		games.push(new Roulette());
	}

	//Modifiers
	modifier isGameSet(){
		require(address(gamesMap[msg.sender]) != address(0), "There is no current game set");
		_;
	}

	//Game type setter
	function setGameType(uint8 gameType) external returns(bool){
		// bool _success = false;
		require(uint(gameType) <= games.length, "This game doesn't exist");
		gamesMap[msg.sender] = games[gameType.sub(1)];
		// playerInfoMap[msg.sender].gameSet = true;
		// _success = true;
		emit EventGameSet(msg.sender, gameType);
		return (true);
	}

	//Playing game
	function isBetSetGame() external view isGameSet returns(bool){
		return gamesMap[msg.sender].isBetSet(msg.sender);
	}

	function betGame(string calldata betInfo, uint8 betData) external payable isGameSet returns(bool){
		bool _success = gamesMap[msg.sender].bet(msg.sender, betInfo, betData, msg.value);
		if(_success){
			// increaseCasinoBalance(moneyBet);
			emit EventBet(msg.sender, betInfo, betData, msg.value);
			return _success;
		}else{
			revert("Incorrect bet");
		}
	}

	function cancelBetGame() external isGameSet returns(bool){
		uint256 _moneyBack = gamesMap[msg.sender].cancelBet(msg.sender);
		if(_moneyBack > 0){
			msg.sender.transfer(_moneyBack);
			emit EventCancelBet(msg.sender, _moneyBack);
			return true;
		}else{
			return false;		
		}
			
	}	

	function playGame() external isGameSet returns(uint8 , uint256){
		(uint8 result, uint256 moneyEarned) = gamesMap[msg.sender].play(msg.sender);
		emit EventResult(msg.sender, result);
		if(moneyEarned > 0){
			msg.sender.transfer(moneyEarned);
			emit EventPlayerReceives(msg.sender, moneyEarned);
		}
		return (result, moneyEarned);
	}

	// function playerWithdrawMoney() isGameSet external returns(uint256){
	// 	uint256 moneyWin = gamesMap[msg.sender].playerMoneyWin();
	// 	decreaseCasinoBalance(moneyWin);
	// 	msg.sender.transfer(moneyWin);
	// 	emit EventPlayerReceives(msg.sender, moneyWin);
	// 	return moneyWin;
	// }

    //Admin functions with onlyOwner
    function addFundsCasinoBalance() external payable onlyOwner{
    	require(msg.value > 0, "No funds transfered");
		// increaseCasinoBalance(msg.value);
	}

    function withdrawCasinoBalance(uint amount) external onlyOwner{
    	address payable casino = address(uint160(address(this))); // conversion trick
    	require(casino.balance >= amount, "Not enough balance");
		msg.sender.transfer(amount);
	}

	function getCasinoBalance() external view onlyOwner returns(uint){
		address payable casino = address(uint160(address(this))); // conversion trick
		return casino.balance;
	}

	// function increaseCasinoBalance(uint amount) internal{
	// 	casinoBalance += casinoBalance.sub(amount);
	// }

	// function decreaseCasinoBalance(uint amount) internal{
	// 	casinoBalance = casinoBalance.sub(amount);
	// }

}
