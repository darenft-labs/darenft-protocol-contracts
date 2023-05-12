import { deploy } from '@openzeppelin/hardhat-upgrades/dist/utils';
import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const code: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deployer, verifier } = await getNamedAccounts();

  const nft2Vault = await deployments.get("NFT2Vault");
  const nftFactory = await deployments.get("NFTFactory");

  // TRANSFERABLE ROLE
  const TRANSFERABLE_ROLE = await deployments.read("TokenTransferProxy", "TRANSFERABLE_ROLE");
  await deployments.execute("TokenTransferProxy", {
    from: deployer
  }, "grantRole",
    TRANSFERABLE_ROLE,
    nft2Vault.address,
  );

  // await deployments.execute("NFTFactory", {
  //   from: deployer,
  // }, "setNFT2Vault", nft2Vault.address);

  const VAULT_ROLE = '0x31e0210044b4f6757ce6aa31f9c6e8d4896d24a755014887391a926c5224d959'; // VAULT_ROLE
  await deployments.execute("NFT2Vault", {
    from: deployer
  }, "grantRole", VAULT_ROLE, nftFactory.address);

  // grant verifier
  const VERIFIER_ROLE = '0x0ce23c3e399818cfee81a7ab0880f714e53d7672b08df0fa62f2843416e1ea09';
  await deployments.execute('NFTFactory', {
    from: deployer,
  }, 'grantRole', VERIFIER_ROLE, verifier);
};

code.tags = ['grant-perm'];

code.dependencies = [
  "setup-NFTFactory",
  "TokenTransferProxy",
  "NFT2",
  "NFT2Vault",
  "NFT2AutoID"
];

export default code;
