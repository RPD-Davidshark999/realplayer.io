// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
	function transfer(address receiver, uint amount) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
	function decimals() external returns(uint);
	function balanceOf(address _account) external view returns (uint);
}

interface IStaking {
    function balanceOf(address _account) external view returns(uint);
    function idoAmounts(address _account) external view returns(uint);
}

contract Ido is Ownable {

    uint public price;
    IToken public tokenReward;
    IToken public usdtToken;
    IStaking public stakeToken;
    uint public fundsRaisedTotal;
    uint public fundsFixedTotal;
    uint public rewardsTotal;
    uint public rewardsFixedTotal;
    address public beneficiary;
    bool public launch = false;
    bool public isFinish = false;
    bool public switchWithdraw = false;
    uint public minAmount = 200 ether;
    uint public maxAmount = 200 ether;

    mapping(address => uint) public rewards;
    mapping(address => bool) private whitelist;
    mapping(address => uint) public idoAmounts;

    constructor(
        uint _price,
        uint _rewardsFixedTotal,
        uint _fundsFixedTotal,
        address _tokenRewardAddress,
        address _usdtAdress,
        address _beneficiary,
        address _stakeToken
    ) {
        price = _price;
        rewardsFixedTotal = _rewardsFixedTotal;
        fundsFixedTotal = _fundsFixedTotal;
        tokenReward = IToken(_tokenRewardAddress);
        usdtToken = IToken(_usdtAdress);
        beneficiary = _beneficiary;
        stakeToken = IStaking(_stakeToken);
    }

    function donate(uint _amount) external {
        require(launch, "No launch");
        require(!isFinish, "Finished");
        require(getWhitelist(msg.sender), "Account is not already whitelist");
        require(_amount >= minAmount, "Transfer amount small");
        if(whitelist[msg.sender]){
            require(_amount <= idoAmounts[msg.sender], "Transfer amount big");
        }else{
            uint idoAmount = stakeIdoAmounts(msg.sender);
            require(_amount <= idoAmount, "Transfer amount big");

        }
        uint rewardAmount = getReward(_amount);
        require((rewardsFixedTotal - rewardsTotal) >= rewardAmount, "Token balance insufficient");
        rewards[msg.sender] += rewardAmount;
        fundsRaisedTotal += _amount;
        rewardsTotal += rewardAmount;
        idoAmounts[msg.sender] -= _amount;
        usdtToken.transferFrom(msg.sender, beneficiary, _amount);
        if((rewardsFixedTotal - rewardsTotal) < getReward(minAmount)) {
            isFinish = true;
        }
        emit Donate(msg.sender, beneficiary, _amount);
    }

    function getReward(uint _amount) private returns(uint){
        uint tokenDecimal = tokenReward.decimals();
        uint tokenNum = _amount * 10 ** tokenDecimal / price;
        return tokenNum;
    }

    function withdraw() external {
        require(switchWithdraw, "Disabled Withdraw");
        uint amount = rewards[msg.sender];
        require(amount > 0, "Cannot withdraw less 0");
        rewards[msg.sender] = 0;
        tokenReward.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function excludeWhitelist(address[] memory _accounts) external onlyOwner {
        for (uint i = 0; i < _accounts.length; i+=1) {
            whitelist[_accounts[i]] = false;
            idoAmounts[_accounts[i]] = 0;
        }
    }

    function includeWhitelist(address[] memory _accounts) external onlyOwner {
        for (uint i = 0; i < _accounts.length; i+=1) {
            whitelist[_accounts[i]] = true;
            idoAmounts[_accounts[i]] = maxAmount;
        }
    }

    function getWhitelist(address _account) public view returns(bool) {
        bool b = whitelist[_account];
        if(!b){
            uint idoAmount = stakeToken.idoAmounts(_account);
            if(idoAmount > 0)
                b = true;
        }
        return b;
    }

    function getIdoAmounts(address _account) public view returns(uint) {
        uint idoAmount = idoAmounts[_account];
        if(idoAmount <= 0){
            idoAmount = stakeToken.idoAmounts(_account);
        }
        return idoAmount;
    }

    function stakeIdoAmounts(address _account) private returns(uint) {
        uint idoAmount = idoAmounts[_account];
        if(idoAmount <= 0){
            idoAmount = stakeToken.idoAmounts(_account);
            if(idoAmount > 0)
                idoAmounts[_account] = idoAmount;
        }
        return idoAmount;
    }

    function setLaunch(bool _launch) external onlyOwner {
        launch = _launch;
    }

    function setIsFinish(bool _isFinish) external onlyOwner {
        isFinish = _isFinish;
    }

    function setMinMaxAmount(uint _minAmount, uint _maxAmount) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function setSwitchWithdraw(bool _switchWithdraw) external onlyOwner {
        switchWithdraw = _switchWithdraw;
    }

    receive() external payable {}

    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    /* ========== EVENTS ========== */
    event Withdrawn(address indexed user, uint256 indexed amount);
    event Donate(address indexed user, address indexed beneficiary, uint256 indexed amount);
}