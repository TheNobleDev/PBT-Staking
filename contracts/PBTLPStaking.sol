// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PBTLPStaking is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that PBTs distribution occurs.
        uint256 endBlock; // The Last block number when PBT distribution ends.
        uint256 accPbtPerShare; // Accumulated PBTs per share, times 1e12. See below.
    }
    // The PBT TOKEN
    IERC20 public pbt;
    // PBT tokens minted per block.
    uint256 public pbtPerBlock;
    // Info of the pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    // The source of all PBT rewards
    uint256 public pbtForRewards;
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(IERC20 _pbt, IERC20 _lpToken, uint256 _pbtPerBlock, uint256 _startBlock, uint256 _totalRewards) {
        require(_startBlock > block.number, "StartBlock must be in the future");
        pbt = _pbt;
        pbtPerBlock = _pbtPerBlock;
        poolInfo = PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: _startBlock,
            endBlock: _startBlock + _totalRewards/_pbtPerBlock,
            accPbtPerShare: 0
        });
    }

    // View function to see pending PBTs on frontend.
    function pendingPbt(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accPbtPerShare = pool.accPbtPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 pbtReward = (block.number - pool.lastRewardBlock) * pbtPerBlock;
            accPbtPerShare = accPbtPerShare + ((pbtReward * 1e12)/lpSupply);
        }
        return ((user.amount * accPbtPerShare)/1e12) - user.rewardDebt;
    }

    // Deposit LP tokens to PBTStaking for PBT allocation.
    function deposit(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        _updatePool();
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accPbtPerShare)/1e12) - user.rewardDebt;
            _safePbtTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accPbtPerShare)/1e12;
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from PBTStaking.
    function withdraw(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        _updatePool();
        uint256 pending = ((user.amount * pool.accPbtPerShare)/1e12) - user.rewardDebt;
        _safePbtTransfer(msg.sender, pending);
        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accPbtPerShare)/1e12;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {
        PoolInfo storage pool = poolInfo;

        uint256 blockToUse = block.number;
        if (blockToUse <= pool.lastRewardBlock || pool.lastRewardBlock >= pool.endBlock) {
            return;
        }
        if(blockToUse >= pool.endBlock) {
            blockToUse = pool.endBlock;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = blockToUse;
            return;
        }

        uint256 pbtReward = (blockToUse - pool.lastRewardBlock) * pbtPerBlock;
        require(pbt.balanceOf(address(this)) - pbtForRewards >= pbtReward, "Insufficient PBT tokens for rewards");
        pbtForRewards += pbtReward;
        pool.accPbtPerShare += ((pbtReward * 1e12)/lpSupply);
        pool.lastRewardBlock = blockToUse;
    }

    // Safe pbt transfer function, just in case if rounding error causes pool to not have enough PBTs.
    function _safePbtTransfer(address _to, uint256 _amount) internal {
        uint256 pbtBal = pbt.balanceOf(address(this));
        if (_amount > pbtBal) {
            pbt.transfer(_to, pbtBal);
        } else {
            pbt.transfer(_to, _amount);
        }
    }
}
