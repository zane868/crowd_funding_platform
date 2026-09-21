// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./CrowdfundingCampaign.sol";

/**
 *
 * @title 众筹合约工厂
 * @author 用于创建和管理多个众筹合约
 * @notice 使用工厂模式
 */
contract CrowdfundingFactory {
    /// @dev 所有已创建的众筹合约
    CrowdfundingCampaign[] public campaigns;

    /// @dev 用户的合约地址的索引,campaigns数组的索引位
    mapping(address => uint[]) public userCampaigns;

    /// @dev 创建众筹合约时触发的事件
    event CampaignCreated(
        address indexed creator,
        address indexed campaign,
        string name,
        uint goal,
        uint durationInDays
    );

    /**
     *  创建一个众筹合约
     * @param _name  众筹名称
     * @param _goal  额度
     * @param _durationInDays 众筹时间
     */
    function createCampaign(
        string memory _name,
        uint _goal,
        uint _durationInDays
    ) external returns (address) {
        //创建众筹合约
        CrowdfundingCampaign campaign = new CrowdfundingCampaign(
            msg.sender,
            _name,
            _goal,
            _durationInDays
        );

        //添加到全量众筹
        campaigns.push(campaign);

        //将索引存起来
        uint[] storage cs = userCampaigns[msg.sender];
        cs.push(campaigns.length - 1);

        //触发创建事件
        emit CampaignCreated(
            msg.sender,
            address(campaign),
            _name,
            _goal,
            _durationInDays
        );

        return address(campaign);
    }
}
