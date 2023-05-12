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

  const nft2Vault = await deployments.get("NFT2Vault");
  // const nftFactory = await deployments.get("NFTFactory");
  const nft2Impl = await deployments.get("NFT2");
  const dnft2Impl = await deployments.get("DerivativeNFT2");
  const dnft2AutoImpl = await deployments.get("NFT2AutoID");

  // TRANSFERABLE ROLE
  const TRANSFERABLE_ROLE = await deployments.read("TokenTransferProxy", "TRANSFERABLE_ROLE");
  await deployments.execute("TokenTransferProxy", {
    from: deployer
  }, "grantRole",
    TRANSFERABLE_ROLE,
    nft2Vault.address,
  );

  await deployments.execute("NFTFactory", {
    from: deployer,
  }, "setNFT2Vault", nft2Vault.address);

  await deployments.execute("NFTFactory", {
    from: deployer
  }, "setNFT2Implementation", nft2Impl.address);

  await deployments.execute("NFTFactory", {
    from: deployer
  }, "setNFT2DerivativeImplementation", dnft2Impl.address);

  await deployments.execute("NFTFactory", {
    from: deployer
  }, "setNFT2AutoIdImplementation", dnft2AutoImpl.address);
};

code.tags = ['setup-NFTFactory'];

code.dependencies = [
  "TokenTransferProxy",
  "NFT2",
  "DerivativeNFT2",
  "NFT2Vault",
  "NFTFactory",
  "NFT2AutoID"
];

export default code;
