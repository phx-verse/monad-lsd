// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import "../interfaces/IMonadStaking.sol";

contract MockMonadStaking is IMonadStaking {
    // Minimum stake required from validator's own account
    // to be eligible to join the valset, in Monad wei
    uint256 MIN_AUTH_ADDRESS_STAKE;

    // Min stake required (including delegation) for validator
    // to be eligible to join the valset, in Monad wei.
    // note that ACTIVE_VALIDATOR_STAKE > MIN_AUTH_ADDRESS_STAKE
    uint256 ACTIVE_VALIDATOR_STAKE;

    // Block Reward
    uint256 REWARD;

    // Accumulator unit multiplier. Chosen to preserve accuracy
    uint256 ACCUMULATOR_DENOMINATOR = 1e36;

    // Staking precompile address
    address STAKING_CONTRACT_ADDRESS =
        0x0000000000000000000000000000000000001000;

    // Withdrawal delay, needed to facilitate slashing
    uint8 WITHDRAWAL_DELAY = 1;

    // Controls the maximum number of results returned by individual
    // calls to valset-getters, get_delegators, and get_delegations
    uint64 PAGINATED_RESULTS_SIZE = 100;

    struct ValExecution { // Realtime execution state for one validator
        uint256 stake; // Upcoming stake pool balance
        uint256 acc; // Current accumulator value for validator
        uint256 commission; // Proportion of block reward charged as commission, times 1e18; 10% = 1e17
        bytes secp_pubkey; // Secp256k1 public key used by consensus
        bytes bls_pubkey; // Bls public key used by consensus
        uint256 address_flags; // Flags to represent validators' current state
        uint256 unclaimed_rewards; // Unclaimed rewards
        address auth_address; // Delegator address with authority over validator stake
    }

    struct ValConsensus { // A subset of validator state for the consensus system
        uint256 stake; // Current active stake
        uint256 commission; // Commission rate for current epoch
        bytes secp_pubkey; // Secp256k1 public key used by consensus
        bytes bls_pubkey; // Bls public key used by consensus
    }

    struct DelInfo {
        uint256 stake; // Current active stake
        uint256 acc; // Last checked accumulator
        uint256 rewards; // Last checked rewards
        uint256 delta_stake; // Stake to be activated next epoch
        uint256 next_delta_stake; // Stake to be activated in 2 epochs
        uint64 delta_epoch; // Epoch when delta_stake becomes active
        uint64 next_delta_epoch; // Epoch when next_delta_stake becomes active
    }

    struct WithdrawalRequest {
        uint256 amount; // Amount to undelegate from validator
        uint256 acc; // Validator accumulator when undelegate was called
        uint64 epoch; // Epoch when undelegate stake deactivates
    }

    struct Accumulator {
        uint256 val; // Current accumulator value
        uint256 refcount; // Reference count for this accumulator value
    }

    function addValidator(
        bytes calldata payload,
        bytes calldata signedSecpMessage,
        bytes calldata signedBlsMessage
    ) external payable returns (uint64 validatorId) {
        return 0;
    }

    // todo
    function delegate(
        uint64 validatorId
    ) external payable returns (bool success) {
        return true;
    }

    // todo
    function undelegate(
        uint64 validatorId,
        uint256 amount,
        uint8 withdrawId
    ) external returns (bool success) {
        return true;
    }

    // todo
    function compound(uint64 validatorId) external returns (bool success) {
        return true;
    }

    // todo
    function withdraw(
        uint64 validatorId,
        uint8 withdrawId
    ) external returns (bool success) {
        return true;
    }

    // todo
    function claimRewards(uint64 validatorId) external returns (bool success) {
        return true;
    }

    function changeCommission(
        uint64 validatorId,
        uint256 commission
    ) external returns (bool success) {
        return true;
    }

    function externalReward(
        uint64 validatorId
    ) external returns (bool success) {
        return true;
    }

    function getValidator(
        uint64 validatorId
    )
        external
        view
        returns (
            address authAddress,
            uint64 flags,
            uint256 stake,
            uint256 accRewardPerToken,
            uint256 commission,
            uint256 unclaimedRewards,
            uint256 consensusStake,
            uint256 consensusCommission,
            uint256 snapshotStake,
            uint256 snapshotCommission,
            bytes memory secpPubkey,
            bytes memory blsPubkey
        )
    {
        return (address(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, "", "");
    }

    // todo
    function getDelegator(
        uint64 validatorId,
        address delegator
    )
        external
        view
        returns (
            uint256 stake,
            uint256 accRewardPerToken,
            uint256 unclaimedRewards,
            uint256 deltaStake,
            uint256 nextDeltaStake,
            uint64 deltaEpoch,
            uint64 nextDeltaEpoch
        )
    {
        return (0, 0, 0, 0, 0, 0, 0);
    }

    // todo
    function getWithdrawalRequest(
        uint64 validatorId,
        address delegator,
        uint8 withdrawId
    )
        external
        view
        returns (
            uint256 withdrawalAmount,
            uint256 accRewardPerToken,
            uint64 withdrawEpoch
        )
    {
        return (0, 0, 0);
    }

    function getConsensusValidatorSet(
        uint32 startIndex
    )
        external
        view
        returns (bool isDone, uint32 nextIndex, uint64[] memory valIds)
    {
        return (true, 0, new uint64[](0));
    }

    function getSnapshotValidatorSet(
        uint32 startIndex
    )
        external
        view
        returns (bool isDone, uint32 nextIndex, uint64[] memory valIds)
    {
        return (true, 0, new uint64[](0));
    }

    function getExecutionValidatorSet(
        uint32 startIndex
    )
        external
        view
        returns (bool isDone, uint32 nextIndex, uint64[] memory valIds)
    {
        return (true, 0, new uint64[](0));
    }

    // todo
    function getDelegations(
        address delegator,
        uint64 startValId
    )
        external
        view
        returns (bool isDone, uint64 nextValId, uint64[] memory valIds)
    {
        return (true, 0, new uint64[](0));
    }

    function getDelegators(
        uint64 validatorId,
        address startDelegator
    )
        external
        view
        returns (
            bool isDone,
            address nextDelegator,
            address[] memory delegators
        )
    {
        return (true, address(0), new address[](0));
    }

    // todo
    function getEpoch()
        external
        view
        returns (uint64 epoch, bool inEpochDelayPeriod)
    {
        return (0, false);
    }

    function getProposerValId() external view returns (uint64 val_id) {
        return 0;
    }

    function syscallOnEpochChange(uint64 epoch) external {}

    function syscallReward(address blockAuthor) external {}

    function syscallSnapshot() external {}
}
