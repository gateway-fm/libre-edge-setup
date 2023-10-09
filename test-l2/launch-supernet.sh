#!/bin/sh

set -e

rm -f genesis.json

rpc=http://44.213.248.203:8545

privateKey="$(node ../keys/get-key.js)"
mainAddr="0x$(cat ../step-2/data-0/keystore/UTC* | jq -r '.address')"
primaryAcc=$(jq -r '.[0].address' ../step-1/validators.json)

echo "launcing erc-20 staking token..."

./cast send --from ${mainAddr} \
	--legacy \
	--private-key ${privateKey} \
	--rpc-url ${rpc} -j --create \
	"$(jq -r '.bytecode' ./MockERC20.json)" > MockStakeTokenERC20.json

stakeToken="$(jq -r '.contractAddress' ./MockStakeTokenERC20.json)"

addresses=""
for i in {0..5}; do
 echo "minting erc-20 to validator ${i}..."
	addr=$(jq -r ".[${i}].address" ../step-1/validators.json)
	addresses="${addresses}${addr},"

	./cast send --legacy ${stakeToken} "function mint(address to, uint256 amount) returns()" ${addr} 1000000000000000000 \
	--rpc-url ${rpc} \
	--private-key ${privateKey}
done

addresses="${addresses::-1}"

./polygon-edge genesis \
--chain-id 123456 \
--name "libre" \
--block-gas-limit 18800000 \
--epoch-size 3600 \
--epoch-reward "0xa" \
--consensus polybft \
--min-validator-count 4 \
--sprint-size 1800 \
--block-time 1s \
--reward-wallet ${primaryAcc} \
--native-token-config "Libre Token:LIBR:18:true:${primaryAcc}" \
--premine ${primaryAcc}:1000000000000000000000000000 \
--premine 0x0:1000000000000000000000000000 \
--validators-path ../step-1 \
--validators-prefix validator-


./polygon-edge polybft stake-manager-deploy \
--private-key ${privateKey} \
--genesis ./genesis.json \
--jsonrpc ${rpc} \
--stake-token ${stakeToken}

stakeManagerAddr=$(jq -r '.params.engine.polybft.bridge.stakeManagerAddr' genesis.json)

./polygon-edge rootchain deploy \
--deployer-key ${privateKey} \
--genesis ./genesis.json \
--json-rpc ${rpc} \
--stake-manager ${stakeManagerAddr} \
--stake-token ${stakeToken}

customSupernetManagerAddr=$(jq -r '.params.engine.polybft.bridge.customSupernetManagerAddr' genesis.json)
supernetID=$(jq -r '.params.engine.polybft.supernetID' genesis.json)

./polygon-edge polybft whitelist-validators \
--addresses "${addresses}" \
--supernet-manager ${customSupernetManagerAddr} \
--private-key ${privateKey} \
--jsonrpc ${rpc}

counter=1
while [ $counter -le 6 ]; do
	echo "Registering validator: ${counter}"

	./polygon-edge polybft register-validator \
		--supernet-manager ${customSupernetManagerAddr} \
		--data-dir ../step-1/validator-${counter} \
		--jsonrpc ${rpc}

	./polygon-edge polybft stake \
		--data-dir ../step-1/validator-${counter} \
		--amount 1000000000000000000 \
		--supernet-id ${supernetID} \
		--stake-manager ${stakeManagerAddr} \
		--stake-token ${stakeToken} \
		--jsonrpc ${rpc}

	((counter++))
done

./polygon-edge polybft supernet \
--private-key ${privateKey} \
--jsonrpc ${rpc} \
--genesis ./genesis.json \
--supernet-manager ${customSupernetManagerAddr} \
--stake-manager ${stakeManagerAddr} \
--finalize-genesis-set \
--enable-staking


ips=(
	"172.31.3.11"
	"172.31.0.218"
	"172.31.80.203"
	"172.31.91.73"
	"172.31.31.111"
	"172.31.18.247"
)

wip=$(cat genesis.json)

for i in "${!ips[@]}"; do

	multiAddr=$(echo ${wip} | jq -r ".params.engine.polybft.initialValidatorSet[${i}].multiAddr")
	multiAddr=$(echo ${multiAddr} | sed "s/127.0.0.1/${ips[i]}/g" | sed 's/3030[0-9]/30301/g')
	echo ${multiAddr}
	wip=$(echo ${wip} | jq ".params.engine.polybft.initialValidatorSet[${i}].multiAddr = \"${multiAddr}\"")
	wip=$(echo ${wip} | jq ".bootnodes[${i}] = \"${multiAddr}\"")

done

rm -f genesis.json

echo ${wip} > genesis.json