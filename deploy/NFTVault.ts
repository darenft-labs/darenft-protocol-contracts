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

  const ttp = await deployments.get("TokenTransferProxy");

  await deployments.deploy('NFT2Vault', {
    from: deployer,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [
            deployer,
            ttp.address
          ],
        },
      }
    }
  });
};

code.tags = ['next', 'NFT2Vault'];

code.dependencies = [
  'TokenTransferProxy'
];

export default code;
