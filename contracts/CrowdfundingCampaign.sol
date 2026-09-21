// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CrowdfundingCampaign {
    /// @dev 枚举类型：定义众筹活动所有可能的状态
    enum State {
        Preparing, // 准备中：活动已创建但尚未开始
        Active, // 进行中：活动正在接受资金贡献
        Success, // 成功：已达到筹款目标
        Failed, // 失败：截止时间已到但未达到目标
        Closed // 已关闭：资金已提取（仅适用于成功的活动）
    }

    /// @dev 当前活动
    State public state;

    /// @dev 活动创建者地址
    address public immutable owner;

    /// @dev 活动名称
    string public name;

    /// @dev 众筹目标金额
    uint public immutable goal;

    /// @dev 活动截止时间
    uint public immutable deadline;

    /// @dev 已经筹到的钱
    uint public totalRaised;

    /// @dev 贡献者名单和金额
    mapping(address => uint) public contributions;

    /// @dev 所有贡献者名单
    address[] public contributors;

    /// @dev 事件定义
    /// @notice 状态变更事件：当活动状态发生变化时触发
    event StateChanged(address indexed user, State oldState, State newState);

    /// @notice 贡献事件：当有用户贡献资金时触发
    event Contribution(address indexed contributor, uint256 amount);

    event Withdrawal(address indexed owner, uint256 amount);

    event Refund(address indexed user, uint256 amount);

    /// @dev 所有者
    modifier onlyOwner() {
        require(msg.sender == owner, "CrowdfundingCampaign not owner");
        _;
    }

    /// @dev 状态检查
    modifier inState(State _state) {
        require(state == _state, "CrowdfundingCampaign invalid state");
        _;
    }

    /// @dev 是否过期
    modifier notExpired() {
        require(block.timestamp < deadline, "CrowdfundingCampaign expired");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        uint _goal,
        uint _durationInDays
    ) {
        require(
            _owner != address(0),
            "CrowdfundingCampaign constructor invalid owner"
        );
        require(
            bytes(_name).length > 0,
            "CrowdfundingCampaign constructor invalid name"
        );
        require(
            _goal > 0,
            "CrowdfundingCampaign constructor goal must be positive"
        );
        // 验证持续时间必须在1-90天之间
        require(
            _durationInDays > 0 && _durationInDays <= 90,
            "CrowdfundingCampaign constructor invalid duration"
        );
        owner = _owner;
        name = _name;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        state = State.Preparing;
    }

    /**
     * 启动活动
     */
    function start() external onlyOwner inState(State.Preparing) {
        state = State.Active;
        emit StateChanged(msg.sender, State.Preparing, State.Active);
    }

    function contribute() external payable inState(State.Active) notExpired {
        require(
            msg.value > 0,
            "CrowdfundingCampaign: contribution must be positive"
        );

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }

        contributions[msg.sender] += msg.value;

        totalRaised += msg.value;

        emit Contribution(msg.sender, msg.value);
    }

    /**
     * @dev 完成活动函数（统一结算）
     * @notice 在截止时间后调用，根据是否达到目标确定最终状态（成功或失败）
     * @notice 只能在活动进行中状态时调用
     * @notice 一旦结算成功/失败后，将无法再次调用
     */
    function finalize() external inState(State.Active) {
        require(
            block.timestamp >= deadline,
            "CrowdfundingCampaign: campaign not ended"
        );
        _settle();
    }

    /**
     * 提前结算,不用等时间
     */
    function settle() external onlyOwner inState(State.Active) {
        _settle(); // owner 提前结算
    }

    function _settle() internal inState(State.Active) {
        State oldState = state;
        state = (totalRaised >= goal) ? State.Success : State.Failed;
        emit StateChanged(msg.sender, oldState, state);
    }

    /**
     * @dev 提取资金函数
     * @notice 只有创建者可以调用，且活动必须处于成功状态
     * @notice 将合约中的所有资金转移到创建者地址
     */
    function withdraw() external onlyOwner inState(State.Success) {
        // 将状态变更为已关闭
        state = State.Closed;
        // 获取合约当前余额
        uint256 amount = address(this).balance;

        // 将资金转移到创建者地址
        (bool success, ) = owner.call{value: amount}("");
        // 验证转账是否成功
        require(success, "CrowdfundingCampaign: withdrawal failed");

        // 触发提取事件
        emit Withdrawal(owner, amount);
        // 触发状态变更事件
        emit StateChanged(msg.sender, State.Success, State.Closed);
    }

    /**
     * @dev 退款函数
     * @notice 活动失败后，贡献者可以申请退款取回自己的资金
     * @notice 只能在活动失败状态时调用
     */
    function refund() external inState(State.Failed) {
        // 获取调用者的贡献金额
        uint256 amount = contributions[msg.sender];
        // 验证贡献金额必须大于0
        require(amount > 0, "CrowdfundingCampaign: no contribution to refund");

        // 防止重入攻击：先清零贡献记录
        contributions[msg.sender] = 0;

        // 将资金退还给贡献者
        (bool success, ) = msg.sender.call{value: amount}("");
        // 验证转账是否成功
        require(success, "CrowdfundingCampaign: refund failed");

        // 触发退款事件
        emit Refund(msg.sender, amount);
    }

    /**
     * @dev 获取所有贡献者地址
     * @return 贡献者地址数组
     */
    function getContributors() external view returns (address[] memory) {
        return contributors;
    }

    /**
     * @dev 获取贡献者总数
     * @return 唯一贡献者的数量
     */
    function getContributorCount() external view returns (uint256) {
        return contributors.length;
    }

    /**
     * @dev 检查活动是否正在进行中
     * @return 如果活动处于进行中状态则返回true，否则返回false
     */
    function isActive() external view returns (bool) {
        return state == State.Active;
    }

    /**
     * @dev 获取活动进度百分比
     * @return 进度百分比（0-100）
     * @notice 如果目标为0则返回0，如果超过100则返回100
     */
    function getProgress() external view returns (uint256) {
        // 如果目标为0，返回0
        if (goal == 0) return 0;
        // 计算进度百分比：已筹集金额 * 100 / 目标金额
        uint256 progress = (totalRaised * 100) / goal;
        // 如果超过100%，则返回100
        return progress > 100 ? 100 : progress;
    }
}
