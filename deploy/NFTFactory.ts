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

  await deployments.deploy('NFTFactory', {
    from: deployer,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [deployer],
        },
      },
    }
  });
};

code.tags = ['NFTFactory'];

code.dependencies = [];

export default code;
