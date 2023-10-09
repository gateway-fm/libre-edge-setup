#!/bin/bash

key=/Users/scott/keys/gateway-scott.pem

machines=(
	"ubuntu@ec2-44-213-119-125.compute-1.amazonaws.com"
	"ubuntu@ec2-3-92-74-53.compute-1.amazonaws.com"
	"ubuntu@ec2-34-207-159-165.compute-1.amazonaws.com"
	"ubuntu@ec2-3-85-9-181.compute-1.amazonaws.com"
	"ubuntu@ec2-34-235-129-84.compute-1.amazonaws.com"
	"ubuntu@ec2-54-224-232-186.compute-1.amazonaws.com"
)

for i in "${!machines[@]}"; do

	machine=${machines[i]}
	x=$((i + 1))

	runCmd="/home/ubuntu/polygon-edge server --data-dir /data --seal --chain /home/ubuntu/genesis.json --num-block-confirmations 128 --libp2p \"0.0.0.0:30301\" --devp2p \"0.0.0.0:30302\" --jsonrpc \"0.0.0.0:8545\" --grpc-address \"0.0.0.0:9632\" --prometheus \"0.0.0.0:6060\" --price-limit 0 --block-gas-target \"0x0\""

	if [ "${i}" -eq "0" ]; then
		runCmd="${runCmd} --relayer"
	fi

	rm -f run.sh
	echo "#!/bin/bash" > run.sh
	echo "" >> run.sh
	echo "${runCmd}" >> run.sh
	chmod +x run.sh

  scp -i ${key} run.sh ${machine}:/home/ubuntu/run.sh

done