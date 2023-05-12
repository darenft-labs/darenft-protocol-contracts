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

  await deployments.deploy('DerivativeNFT2', {
    from: deployer
  });
};

code.tags = ['DerivativeNFT2'];

code.dependencies = [];

export default code;
