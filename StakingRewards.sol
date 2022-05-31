//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate = 100;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    // MAPPINGS
    mapping(address=>uint) public userRewardPerTokenPaid;
    mapping(address=>uint) public rewards;
    mapping(address=>uint) private _balances;

    uint private _totalSupply;

    // CONSTRUCTOR
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    // MODIFIER
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken(); //recalculate rewards
        lastUpdateTime = block.timestamp; //save current timestamp to use in next reward calculation
        rewards[account] = earned(account); //update accumulated rewards
        userRewardPerTokenPaid[account] = rewardPerTokenStored; //update last paid rewards for the given user
        _;
    }

    // Functions

    //this function returns summation of rewards per token
    //function modifier is 'view'because this function is not updating any state variables
    function rewardPerToken() public view returns(uint) {
        if (_totalSupply == 0) { //if there is no staked tokens in smart-contract, then reward don't change
            return rewardPerTokenStored;
        }
        //calculate additional rewards and add it to current accrued rewards
        //formula for calculating additional rewards: 
        //current rewards per staked token + (timestamp difference between last rewarding * reward rate 1e18 precision) / total supply 
        //*************
        //example:
        //rewardPerTokenStored = 0.1 eth
        //totalSupply = 10 eth
        //rewardRate = 100(eth)
        //timestamp difference = 1 day = 86,400,000 milliseconds
        //new reward per token = 0.1 eth + (86,400,000 * 100 eth)/ 10 eth = 0.1 eth + 0,000000000864 (wei) = 0,100000000864 eth
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    //this function returns summation of newly earned and pre-owned rewards
    //function modifier is 'view' because this function is not updating any state variables 
    function earned(address account) public view returns(uint) {
        //calculate earned rewards
        //formula for earned rewards:
        //(current user balance * accrued and yet unpaid rewards in ethers) + paid rewards to user in ethers
        //*************
        //example:
        //account rewards = 0 eth
        //account balance = 1 eth
        //paid rewards = 0 eth
        //new reward per token = 0,100000000864 eth
        //earned rewards = (1 eth * (0,100000000864 eth - 0 eth)) / 1 eth + 0 eth = 0,100000000864 eth
        return ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    //this function is externally called function for staking funds
    //it has 'updateReward' modifier which recalculates(increases) the rewards given to the user
    function stake(uint _amount) external updateReward(msg.sender) {
        //add the amount to total supply and personal account of the user. 
        //this is just updating state variables of smart contract
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        //transfer funds from the sender to the smart contract balance
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    //this function is externally called function for withdrawing funds from the account balance
    //it has 'updateReward' modifier which recalculates(decreases) the rewards given to the user
    function withdraw(uint _amount) external updateReward(msg.sender) {
        //this function is decrementing account balance of the user and total supply by the amount
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;   
        //transfer funds from the smart contract balance to the user balance    
        stakingToken.transfer(msg.sender, _amount);
    }

    //this function is externally called function for withdrawing only accrued rewards of the caller user
    function getReward() external updateReward(msg.sender) {
        //get the rewards for the caller user, make rewards 0 for this user for this period
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        //transfer funds equal to reward amount from the smart contract balance to the user balance
        rewardsToken.transfer(msg.sender, reward);
    }
}

interface IERC20 {
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns(uint);
    function approve(address spender, uint amount) external returns(bool);
    function transferFrom(address spender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}