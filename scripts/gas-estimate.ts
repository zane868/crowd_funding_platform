import { network } from "hardhat";

const { ethers } = await network.create();

const [deployer] = await ethers.getSigners();
console.log("deployer:", deployer.address);
console.log("");

// 1. 部署工厂合约
const factory = await ethers.deployContract("CrowdfundingFactory");
const factoryReceipt = await factory.deploymentTransaction()!.wait();
console.log("CrowdfundingFactory 部署 gas :", factoryReceipt!.gasUsed.toString());

// 2. 通过工厂创建众筹(内部会 new 一个 CrowdfundingCampaign)
const tx = await factory.createCampaign("My Campaign", 10n ** 18n, 30);
const receipt = await tx.wait();
console.log("createCampaign gas           :", receipt!.gasUsed.toString());

// 3. 预估 gas(与上面实际消耗对比)
const estimate = await factory.createCampaign.estimateGas(
  "My Campaign",
  10n ** 18n,
  30,
);
console.log("createCampaign estimateGas   :", estimate.toString());
