# PBT-LP-Staking
Smart contract that rewards PBT for staking LP tokens

## How the core logic works (the mathematics)
At any point in time, the amount of PBTs entitled to a user, and are pending to be distributed is:

  `pending reward = (user.amount * pool.accPbtPerShare) - user.rewardDebt`
  Which translates to: 
    pending reward = (amount staked by user) * (proportional share of the user in pool) - (rewards already paid to user)

Whenever a user deposits or withdraws LP tokens (both PB and Uni), Here's what happens:
  1. The pool's `accPbtPerShare` (and `lastRewardBlock`) gets updated.
  2. User receives the pending reward sent to his/her address.
  3. User's `amount` gets updated.
  4. User's `rewardDebt` gets updated.

## Function Descriptions (only callable by Owner)

### Constructor
Deploys the contract
- `IERC20 _pbt` : address of the PBT token
- `IFPMM _lpToken` : address of the LP token
- `uint256 _pbtPerBlock` : number of PBT to be minted per block (scaled by 10^18)
- `uint256 _startBlock` : the block to start giving out rewards from (has to be a block in the future)
- `uint256 _totalRewards` : the total number of PBT to give out as rewards


## Function Descriptions (callable by anyone)

### pendingPbt
A read-only function to view the pending rewards of any user
- `_user` : the address of user whose pending rewards are to be viewed

### deposit
Deposit LP tokens to PBTStaking for PBT allocation
- `uint256 _amount` : the number of LP tokens to deposit

### withdraw
Withdraw LP tokens (and rewards) from PBTStaking
- `uint256 _amount` : the number of LP tokens to withdraw

### emergencyWithdraw
This function can be called by a user to withdraw their principal if there are not enough PBT tokens in the contract to pay out rewards.


## Entire Workflow

1. Owner(you) deploys the contract with the constructor arguments mentioned above
2. Owner(you) sends '_totalRewards' PBT tokens to the contract address. 
3. User approves the contract to spend their LP tokens
4. User calls `deposit` function with the amount of tokens to deposit.
5. At any time in the future, the user can call the `withdraw` function to withdraw their tokens (partially or wholely).
6. They can also call the `deposit` function with amount=0, to only claim their rewards, and not deposit/withdraw any principal tokens.


## Numerical Example

````
total : 25 PBT per block
We're calculating for 100 blocks

Pool gets 2500 PBT in total till now

Pool has staked 500 LP tokens in total
UserA has staked 50 LP tokens

accPbtPerShare = 0

uint256 multiplier = block.number.sub(pool.lastRewardBlock);
           = number of blocks since last reward block

uint256 pbtReward = multiplier.mul(pbtPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
          = 100 * 100 * 10 / 40
          = 2500
          = total PBT rewards

pool.accPbtPerShare = pool.accPbtPerShare.add(pbtReward.mul(1e12).div(lpSupply));
          = 0 + (2500/500)
          = 5
          = PBT tokens per LP token staked here

uint256 pending = user.amount.mul(pool.accPbtPerShare).div(1e12).sub(user.rewardDebt);
        = 50 * 5 - 0
        = 250 PBT

user.amount = user.amount.sub(_amount);
      = 50 - 25
      = 25

user.rewardDebt = user.amount.mul(pool.accPbtPerShare).div(1e12);
        = 25 * (5)
        = 125