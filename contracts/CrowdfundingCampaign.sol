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
}
