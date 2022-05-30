const {expect} = require("chai");
const {ethers} = require("hardhat");


describe("Payments", () => {
    let acc1;
    let acc2;

    let payments;

    beforeEach(async () => {
        [acc1, acc2] = await ethers.getSigners();
        const Payments = await ethers.getContractFactory("Payments", acc1);
        payments = await Payments.deploy();
        await payments.deployed();
    });

    it("should be deployed (address correct)", async () => {
        expect(payments.address).to.be.properAddress;
    });

    it("should have zero balance by default", async () => {
        const balance = await payments.currentBalance();
        expect(balance).to.eq(0);
    });

    
    it("should be possible to send ether", async () => {
        const totalTransactions = 4;

        for (let paymentNum = 0; paymentNum < totalTransactions; paymentNum++) {
            const amount = 333 * paymentNum + 1;
            const message = `It's ${paymentNum + 1} transaction`;
            
            const tx = await payments.connect(acc2).pay(message, {value: amount});
            await expect(() => tx).to.changeEtherBalances([acc2, payments], [-amount, amount]);
    
            const newPayment = await payments.getPayment(acc2.address, paymentNum);
            expect(newPayment.message).to.eq(message);
            expect(newPayment.amount).to.eq(amount);
            expect(newPayment.from).to.eq(acc2.address);
        }
        
    });

});