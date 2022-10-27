// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingRewards is Ownable {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate = 20;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    bool public rewardsEnabled = false;
    uint public lockDuration = 7 days;
    uint public maxLevel = 30;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint) public lockTimes;
    mapping(address => uint) public levels;
    mapping(address => uint) public idoAmounts;
    mapping(uint => uint) public levelsIdoAmounts;
    mapping(uint => uint) public levelsStakeAmounts;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        if(rewardsEnabled){
            rewardPerTokenStored = rewardPerToken();
            lastUpdateTime = block.timestamp;

            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier updateLevel(address account) {
        _;
        for(uint i=maxLevel;i>0;i--){
            if(_balances[account] >= levelsStakeAmounts[i]) {
                levels[account] = i;
                idoAmounts[account] = levelsIdoAmounts[i];
                return;
            }
        }
        levels[account] = 0;
        idoAmounts[account] = 0;
    }

    function stake(uint _amount) external updateReward(msg.sender) updateLevel(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        lockTimes[msg.sender] = block.timestamp + lockDuration;
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint _amount) public updateReward(msg.sender) updateLevel(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        require(_balances[msg.sender] >= _amount);
        require(block.timestamp > lockTimes[msg.sender], "The lock time cannot be withdraw");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    receive() external payable {}

    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setLevelsIdoAmounts(uint _level, uint _amount) public onlyOwner {
        levelsIdoAmounts[_level] = _amount;
    }

    function setLevelsStakeAmounts(uint _level, uint _amount) public onlyOwner {
        levelsStakeAmounts[_level] = _amount;
    }

    function setRewardRate(uint _rewardRate) public onlyOwner {
        rewardRate = _rewardRate;
    }

    function setRewardsEnabled(bool _rewardsEnabled) public onlyOwner {
        rewardsEnabled = _rewardsEnabled;
    }

    function setLockDuration(uint _lockDuration) public onlyOwner {
        lockDuration = _lockDuration;
    }

    function setMaxLevel(uint _maxLevel) public onlyOwner {
        maxLevel = _maxLevel;
    }

    function getTotalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns(uint) {
        return _balances[_account];
    }

     /* ========== EVENTS ========== */
    event Staked(address indexed user, uint256 indexed amount);
    event Withdrawn(address indexed user, uint256 indexed amount);
    event RewardPaid(address indexed user, uint256 indexed reward);
    event Recovered(address indexed token, uint256 indexed amount);
}
