const {ethers, network} = require("hardhat");
const materialIdList = require("../_file/materialIdList.json");

async function deployRevenueShare() {
    const [deployer] = await ethers.getSigners(network.config.accounts);
    const RevenueShare = await ethers.getContractFactory("RevenueShare");
    const revenueShare = await RevenueShare.connect(deployer).deploy();
    await revenueShare.deployed();

    console.log("revenueShare deployed to:", revenueShare.address, "from ", deployer.address);
}
/**
 * material type to order convertion:
 */
  // Diamond => 1,
  // Fire => 2,
  // Fluffy => 3, 
  // Glow => 4,
  // Liquid => 5,
  // Matte => 6,
  // Metal => 7

async function deployRevenueShareForDonation() {
  const [deployer] = await ethers.getSigners(network.config.accounts);
  const RevenueShareForDonation = await ethers.getContractFactory("RevenueShareForDonation");
  const revenueShareForDonation = await RevenueShareForDonation.connect(deployer).deploy();
  console.log('run')
  await revenueShareForDonation.deployed();

  console.log("revenueShareForDonation deployed to:", revenueShareForDonation.address, "from ", deployer.address);
  for (let i = 0; i < 18; i++) {
    setTimeout(async () => {
      await revenueShareForDonation.setTokenToMaterial(materialIdList.slice(i * 500, (i + 1) * 500), 0, 500);
      console.log('done: ', i++)
    }, i * 1000)
  }
}

async function main() {
  try {
  // await deployRevenueShare();
  await deployRevenueShareForDonation();
  } catch(e) {
    console.error(e)
  }

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

module.exports = materialIdList

/*
 * Recent contract address on Goerli
 **/
// RevenueShare: 0xB595a5bF216b9E185037ABe884A8bBe48c78d478
// RevenueShareForDonation: 0x14B71a54DF5007de2bEe3c16892D6da7f0D459B8