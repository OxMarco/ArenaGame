import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  
 
solidity: {
  version: '0.8.5',
  settings: {
    optimizer: { enabled: true, runs: 200 },
  },
},
//solidity: "0.8.5",
}
export default config;
