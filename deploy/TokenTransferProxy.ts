import { deploy } from '@openzeppelin/hardhat-upgrades/dist/utils';
import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const code: DeployFunction = async ({
  deployments,
  getNamedAccounts,
  ethers,
  upgrades,
}: HardhatRuntimeEnvironment) => {
  const { deployer } = await getNamedAccounts();

  await deployments.deploy('TokenTransferProxy', {
    proxy: {
      execute: {
        init: {
          methodName: 'initialize',
          args: [deployer],
        },
      }
    },
    from: deployer
  });
};

code.tags = ['TokenTransferProxy'];

code.dependencies = [];

export default code;
