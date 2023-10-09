const keythereum = require("keythereum");
const fs = require("fs");
const path = require('path');

const password = fs.readFileSync("../password.txt");
const files = fs.readdirSync("../step-2/data-0/keystore");
let address = "";

for(var i in files) {
	const keyFile = fs.readFileSync("../step-2/data-0/keystore/" + files[i])
	address = "0x" + JSON.parse(keyFile).address;
}

const datadir = "../step-2/data-0";

const keyObject = keythereum.importFromFile(address, datadir);
const privateKey = keythereum.recover(password, keyObject);
console.log(privateKey.toString('hex'));