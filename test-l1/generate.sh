#!/usr/bin/env bash
rm -f genesis.json
cp ../Step-2/genesis.json .
rm -f config.toml
rm -f password.txt

cp ../password.txt .

ips=("44.205.23.183" "34.239.111.56" "52.91.16.19")
nodes=()
bootnodes=""

# first handle disk concerns and get the details of the 3 bootnodes
for i in {0..5}; do
	# rm -rf node-${i}
	./geth init --datadir node-${i} genesis.json
	rm -rf node-${i}/keystore
	cp -r ../step-2/data-${i}/keystore ./node-${i}/keystore
	if [ "${i}" -eq "0" ] || [ "${i}" -eq "1" ] || [ "${i}" -eq "2" ]; then
		key="$(cat node-${i}/geth/nodekey)"
		node="\"enode://$(./bootnode -nodekeyhex ${key} -writeaddress)@${ips[i]}:30301\""
		bootnodes="${bootnodes}${node},"
	fi
done

bootnodes="${bootnodes::-1}"

# now output the commands to run
for i in {0..5};
do
	cmd="/home/ubuntu/geth --datadir /data --config /home/ubuntu/config.toml --port 30301 --authrpc.port 8560 --nodiscover --state.scheme=hash"

	if [ "${i}" -eq "0" ] || [ "${i}" -eq "1" ] || [ "${i}" -eq "2" ]; then
		addr=$(cat ../step-2/data-${i}/keystore/UTC* | jq -r '.address')
		cmd="${cmd} --unlock 0x${addr} --password /data/password.txt --mine --miner.etherbase 0x${addr}"
	else
		cmd="${cmd} --http --http.port 8545 --http.addr \"0.0.0.0\" --http.vhosts=* --syncmode full --gcmode archive --metrics --metrics.addr \"0.0.0.0\""
	fi
	cmd="${cmd} --bootnodes $(echo ${bootnodes} | sed 's/"//g')"
	rm -f run-${i}.sh
	echo "#!/bin/bash" >> run-${i}.sh
	echo "" >> run-${i}.sh
	echo ${cmd} >> run-${i}.sh
	chmod +x "run-${i}.sh"
done

# now create the config file with the static nodes for the cluster
echo "[Node.P2P]" >> config.toml
echo "StaticNodes = [${bootnodes}]" >> config.toml
