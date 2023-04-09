async function main() {
    const Tournaments = await ethers.getContractFactory("Tournaments");
 
    // Start deployment, returning a promise that resolves to a contract object
    const tournaments = await Tournaments.deploy();
    console.log("Contract deployed to address:", tournaments.address);
 }
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
});

//0xe1e2686265B84899DE9836cC645DbE919aDE5A27