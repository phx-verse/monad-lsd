// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IcMon} from "./interfaces/IcMon.sol";
import {IMonadStaking} from "./interfaces/IMonadStaking.sol";
import {PoolAPY} from "./PoolAPY.sol";

contract MonLsdUpgradeable is Initializable, OwnableUpgradeable {
  using EnumerableMap for EnumerableMap.UintToUintMap;
  using PoolAPY for PoolAPY.ApyQueue;

  uint256 public constant RATIO_BASE = 1000_000_000;
  IMonadStaking constant monadStaking = IMonadStaking(0x0000000000000000000000000000000000001000);
  
  uint256 public COMMISSION = 50_000_000; // 5%
  uint256 public APY_PERIOD = 3 days;

  IcMon cMon;
  uint256 public totalAssets;
  
  uint256 public pendingStake; // amount waiting to be delegated
  uint256 public pendingUnstake; // amount waiting to be undelegated
  uint256 public pendingRewards; // rewards waiting to be delegated

  uint256 public interestFeeAccumulated; // total interest fee accumulated of the pool

  uint64 public currentValidatorId;

  mapping(address => uint256) public unwithdrawnAmounts; // user address to unwithdrawn amount

  mapping(uint64 => uint8) private validatorNextWithdrawId; // validatorId to next withdrawId

  // withdraw queue
  uint256 private startId = 0;
  uint256 private endId = 0; // points to the next empty slot
  mapping(uint256 => WithdrawInfo) private withdraws; // withdrawId to WithdrawInfo 

  // each validatorId to delegated amount
  mapping(uint64 => uint256) public pendingUndelegateAmounts; // validatorId to pending undelegate amount
  EnumerableMap.UintToUintMap private delegatedAmounts;

  PoolAPY.ApyQueue private apyQueue;
  Snapshot snapshot;

  struct Snapshot {
    uint256 time;
    uint256 asset;
  }

  struct WithdrawInfo {
    uint64 validatorId;
    uint8 withdrawId;
    uint256 amount;
  }

  event Deposit(
    address indexed user,
    uint256 monAmount,
    uint256 lsdAmount
  );

  event Unstake(
    address indexed user,
    uint256 lsdAmount,
    uint256 monAmount
  );

  event Withdraw(
    address indexed user,
    uint256 monAmount
  );

  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init(msg.sender);
    COMMISSION = 50_000_000; // 5%
    APY_PERIOD = 3 days;
  }

  function updateSnapshot() internal {
    snapshot.time = block.timestamp;
    snapshot.asset = totalAssets;
  }

  function withdrawQueueLen() public view returns (uint256) {
    return endId - startId;
  }

  function addApyNode(uint256 reward) internal {
    apyQueue.enqueueAndClearOutdated(PoolAPY.ApyNode({
      startTime: snapshot.time,
      endTime: block.timestamp,
      reward: reward,
      assets: snapshot.asset
    }), block.timestamp - APY_PERIOD);
  }

  function increaseDelegatedAmount(uint64 validatorId, uint256 amount) internal {
    (bool exists, uint256 prevAmount) = delegatedAmounts.tryGet(validatorId);
    if (exists) {
      delegatedAmounts.set(validatorId, prevAmount + amount);
    } else {
      delegatedAmounts.set(validatorId, amount);
    }
  }

  function decreaseDelegatedAmount(uint64 validatorId, uint256 amount) internal {
    (bool _exists, uint256 prevAmount) = delegatedAmounts.tryGet(validatorId);
    require(prevAmount >= amount, "Decrease exceeds delegated amount");
    delegatedAmounts.set(validatorId, prevAmount - amount);
  }

  function calFee(uint256 reward) public view returns (uint256) {
    return (reward * COMMISSION) / RATIO_BASE;
  }

  function enqueueWithdraw(uint64 validatorId, uint8 withdrawId, uint256 amount) internal {
    withdraws[endId] = WithdrawInfo({
      validatorId: validatorId,
      withdrawId: withdrawId,
      amount: amount
    });
    endId += 1;
  }

  function getNextWithdrawId(uint64 validatorId) internal returns (uint8) {
    uint8 nextId = validatorNextWithdrawId[validatorId];
    validatorNextWithdrawId[validatorId] = uint8((nextId + 1) % 256);
    return nextId;
  }

  function selfBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function lsdRatio() public view returns (uint256) {
    if (cMon.totalSupply() == 0) {
      return RATIO_BASE;
    }
    return (totalAssets * RATIO_BASE) / cMon.totalSupply();
  }

  function monToLsd(uint256 monAmount) public view returns (uint256) {
    require(monAmount > 0, "Must bigger than 0");
    return monAmount * RATIO_BASE / lsdRatio();
  }

  function lsdToMon(uint256 lsdAmount) public view returns (uint256) {
    require(lsdAmount > 0, "Must bigger than 0");
    return lsdAmount * lsdRatio() / RATIO_BASE;
  }

  // should be a view function
  function poolAPY() public returns (uint256) {
    if(apyQueue.start == apyQueue.end) return 0;
    
    uint256 totalReward = 0;
    uint256 totalWorkload = 0;
    for(uint256 i = apyQueue.start; i < apyQueue.end; i++) {
      PoolAPY.ApyNode memory node = apyQueue.items[i];
      totalReward = totalReward + node.reward;
      totalWorkload += node.assets * (node.endTime - node.startTime);
    }

    // consider the latest reward that is not yet recorded in apyQueue
    uint256 latestReward = totalUnclaimedReward();
    if (latestReward > 0) {
      totalReward += latestReward;
      totalWorkload += snapshot.asset * (block.timestamp - snapshot.time);
    }

    return totalReward * RATIO_BASE * 365 days / totalWorkload;
  }

  function convertPendingStakeToWithdrawn() internal {
    if (pendingStake == 0 || pendingUnstake == 0) return;

    if (pendingStake >= pendingUnstake) {
      pendingStake -= pendingUnstake;
      pendingUnstake = 0;
    } else {
      pendingUnstake -= pendingStake;
      pendingStake = 0;
    }
  }

  function convertPendingRewardToWithdrawn() internal {
    if (pendingRewards == 0 || pendingUnstake == 0) return;

    if (pendingRewards >= pendingUnstake) {
      pendingRewards -= pendingUnstake;
      pendingUnstake = 0;
    } else {
      pendingUnstake -= pendingRewards;
      pendingRewards = 0;
    }
  }

  // ====== user write functions ======
  function deposit() payable public {
    require(msg.value > 0, "Must send ETH to stake");
    
    addApyNode(0);

    pendingStake += msg.value;

    uint256 lsdAmount = monToLsd(msg.value);
    cMon.lsdmint(msg.sender, lsdAmount);
    totalAssets += msg.value;
    
    updateSnapshot();

    emit Deposit(msg.sender, msg.value, lsdAmount);

    convertPendingStakeToWithdrawn();
  }

  function unstake(uint256 lsdAmount) public {
    require(lsdAmount > 0, "Must unstake more than 0");
    require(cMon.balanceOf(msg.sender) >= lsdAmount, "Not enough cMon balance");
    
    addApyNode(0);

    uint256 monAmount = lsdToMon(lsdAmount);
    cMon.lsdburn(msg.sender, lsdAmount);
    totalAssets -= monAmount;

    updateSnapshot();

    unwithdrawnAmounts[msg.sender] += monAmount;
    pendingUnstake += monAmount;

    emit Unstake(msg.sender, lsdAmount, monAmount);

    convertPendingStakeToWithdrawn();
    convertPendingRewardToWithdrawn();
  }

  function withdraw(uint256 amount) public {
    require(amount > 0, "Must withdraw more than 0");
    require(selfBalance() >= amount, "Not enough ETH in contract");
    require(unwithdrawnAmounts[msg.sender] >= amount, "Withdraw amount exceeds unwithdrawn amount");
    
    unwithdrawnAmounts[msg.sender] -= amount;
    (bool sent, ) = payable(msg.sender).call{value: amount}("");
    require(sent, "Failed to send Ether");

    emit Withdraw(msg.sender, amount);
  }

  function withdrawAll() public {
    uint256 amount = unwithdrawnAmounts[msg.sender];
    withdraw(amount);
  }

  // ====== service functions ======
  function stakePending() public {
    handlePendingStake();
    handlePendingRewards();
  }

  function handlePendingStake() public {
    if (pendingStake == 0) {
      return;
    }
    stake(currentValidatorId, pendingStake);
    pendingStake = 0;
  }

  function handlePendingRewards() public {
    if (pendingRewards == 0) {
      return;
    }

    addApyNode(pendingRewards);

    totalAssets += pendingRewards;
    updateSnapshot();
    
    stake(currentValidatorId, pendingRewards);
    pendingRewards = 0;
  }

  function claimReward() public {
    uint256[] memory keys = delegatedAmounts.keys();
    for (uint i = 0; i < keys.length; i++) {
      uint64 validatorId = uint64(keys[i]);
      uint256 unclaimedReward = getUnclaimedReward(validatorId);
      if (unclaimedReward == 0) {
        continue;
      }
      bool success = monadStaking.claimRewards(validatorId);
      if (success) {
        uint256 fee = calFee(unclaimedReward);
        interestFeeAccumulated += fee;
        pendingRewards += (unclaimedReward - fee);

        convertPendingRewardToWithdrawn();
      }
    }
  }

  // should be a view function
  function totalUnclaimedReward() public returns (uint256) {
    uint256[] memory keys = delegatedAmounts.keys();
    uint256 totalReward = 0;
    for (uint i = 0; i < keys.length; i++) {
      uint64 validatorId = uint64(keys[i]);
      uint256 unclaimedReward = getUnclaimedReward(validatorId);
      totalReward += unclaimedReward;
    }
    return totalReward;
  }

  function handlePendingUndelegate() public {
    uint256[] memory keys = delegatedAmounts.keys();
    for (uint i = 0; i < keys.length; i++) {
      if (pendingUnstake == 0) {
        break;
      }

      uint64 validatorId = uint64(keys[i]);
      uint256 thisAmount = delegatedAmounts.get(keys[i]);
      uint256 pendingAmount = pendingUndelegateAmounts[validatorId];
      uint256 availableAmount = thisAmount - pendingAmount;

      uint256 unstakeAmount = pendingUnstake;
      if (unstakeAmount > availableAmount) {
        unstakeAmount = availableAmount;
      }
      if (unstakeAmount == 0) {
        continue;
      }

      uint8 withdrawId = getNextWithdrawId(validatorId);
      bool success = monadStaking.undelegate(validatorId, unstakeAmount, withdrawId);
      if (success) {
        pendingUndelegateAmounts[validatorId] += unstakeAmount;
        pendingUnstake -= unstakeAmount;
        enqueueWithdraw(validatorId, withdrawId, unstakeAmount);
      }
    }
  }

  // should be a view function
  function isFirstWithdrawItemReady() public returns (bool) {
    if (startId == endId) {
      return false;
    }

    uint64 epoch = currentEpoch();
    WithdrawInfo memory info = withdraws[startId];
    ( , , uint64 withdrawEpoch) = monadStaking.getWithdrawalRequest(info.validatorId, address(this), info.withdrawId);
    return withdrawEpoch <= epoch;
  }

  function handleWithdraws() public {
    if (startId == endId) {
      return;
    }

    uint64 epoch = currentEpoch();

    for (uint256 i = startId; i < endId; i++) {
      WithdrawInfo memory info = withdraws[i];
      (uint256 withdrawalAmount, , uint64 withdrawEpoch) = monadStaking.getWithdrawalRequest(info.validatorId, address(this), info.withdrawId);
      if (withdrawEpoch > epoch) {
        break;
      }
      bool success = monadStaking.withdraw(info.validatorId, info.withdrawId);
      if (success) {
        pendingUndelegateAmounts[info.validatorId] -= withdrawalAmount;
        decreaseDelegatedAmount(info.validatorId, withdrawalAmount);
        delete withdraws[i];
        startId += 1;
      } else {
        break;
      }
    }
  }

  // ====== owner functions ======
  function setCurrentValidatorId(uint64 validatorId) public onlyOwner {
    currentValidatorId = validatorId;
  }

  function withdrawInterestFee(address payable to, uint256 amount) public onlyOwner {
    require(amount > 0, "No interest fee accumulated");
    require(selfBalance() >= amount, "Not enough ETH in contract");
    require(amount <= interestFeeAccumulated, "Amount exceeds accumulated fee");
    interestFeeAccumulated -= amount;
    (bool sent, ) = to.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function withdrawAllInterestFee(address payable to) public onlyOwner {
    uint256 amount = interestFeeAccumulated;
    withdrawInterestFee(to, amount);
  }

  function setCommission(uint256 commission) public onlyOwner {
    require(commission <= RATIO_BASE, "Commission too high");
    COMMISSION = commission;
  }

  function setApyPeriod(uint256 apyPeriod) public onlyOwner {
    require(apyPeriod >= 1 days, "APY period too short");
    APY_PERIOD = apyPeriod;
  }

  function setCMonAddress(address cMonAddress) public onlyOwner {
    cMon = IcMon(cMonAddress);
  }

  function addInterestFeeAccumulated() public payable {
    interestFeeAccumulated += msg.value;
  }

  // ====== monad staking precompile helpers ======
  function currentEpoch() public returns (uint64) {
    (uint64 epoch, ) =  monadStaking.getEpoch();
    return epoch;
  }

  function getUnclaimedReward(uint64 validatorId) public returns (uint256) {
    ( , , uint256 unclaimedRewards, , , ,) = monadStaking.getDelegator(validatorId, address(this));
    return unclaimedRewards;
  }

  function stake(uint64 validatorId, uint256 amount) internal {
    require(selfBalance() >= amount, "Not enough ETH in contract");
    bool success = monadStaking.delegate{value: amount}(validatorId);
    require(success, "Stake failed");
    increaseDelegatedAmount(validatorId, amount);
  }
}
