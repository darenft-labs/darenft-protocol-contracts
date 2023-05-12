import { deploy } from '@openzeppelin/hardhat-upgrades/dist/utils';
import { constants } from 'ethers';
import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const code: DeployFunction = async ({
  deployments,
  getNamedAccounts,
  ethers,
  upgrades,
}: HardhatRuntimeEnvironment) => {
  const { deployer } = await getNamedAccounts();

  let router, token;
  try {
    router = await deployments.readDotFile('.AMM_ROUTER');
    token = await deployments.readDotFile('.DARENFT_TOKEN');
  } catch (e) {
    // no file ?
    router = constants.AddressZero;
    token = constants.AddressZero;
  }

  await deployments.deploy('FeeController', {
    from: deployer,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [router, token, deployer],
        },
      },
    }
  });

  const result = await deployments.get("FeeController");

  await deployments.execute("NFTFactory", {
    from: deployer
  }, "setFeeController", result.address);
};

code.tags = ['next', 'FeeController'];

code.dependencies = [
  'NFTFactory'
];

export default code;
