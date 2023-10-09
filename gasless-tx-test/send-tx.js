const ethers = require('ethers');
const luxon = require('luxon');

const { DateTime } = luxon;

async function main() {
  const provider = new ethers.JsonRpcProvider('http://gateway-l2-791417635.us-east-1.elb.amazonaws.com:8545');

  const senderPrivateKey = '05e53746494c56955ef0df46ae63b3fc8796ce12d8b3299589a27d8e3731ceae';
  const recipientAddress = '0x75eD5451Ec4045fDb91faA5AAf96dDFf62bE4697'; 

  const senderWallet = new ethers.Wallet(senderPrivateKey, provider);

  const tx = {
    to: recipientAddress,
		value: ethers.parseEther('0.1'),
		gasPrice: ethers.parseUnits('0', 'gwei') 
  };

  const beforeSend = DateTime.now();
  const txResponse = await senderWallet.sendTransaction(tx);
  const afterSend = DateTime.now();
  const diff = afterSend.diff(beforeSend, 'milliseconds').toObject();
  console.log(`Transaction sent in ${diff.milliseconds} ms`);
  
  const txReceipt = await txResponse.wait();
  const afterReceipt = DateTime.now();
  const diffReceipt = afterReceipt.diff(afterSend, 'milliseconds').toObject();
  console.log(`Transaction confirmed in ${diffReceipt.milliseconds} ms`);

  console.log(`Transaction hash: ${txResponse.hash}`);
  console.log(`Transaction confirmed in block: ${txReceipt.blockNumber}`);
}

main().catch(console.error);