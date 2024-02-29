import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("hardhat-import-from-npm");

const config: HardhatUserConfig = {
  solidity: "0.8.24",
};

export default config;
