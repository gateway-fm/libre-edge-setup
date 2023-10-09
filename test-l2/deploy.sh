#!/bin/bash

set -e

key=/Users/scott/keys/gateway-scott.pem

machines=(
	"ubuntu@ec2-44-213-119-125.compute-1.amazonaws.com"
	"ubuntu@ec2-3-92-74-53.compute-1.amazonaws.com"
	"ubuntu@ec2-34-207-159-165.compute-1.amazonaws.com"
	"ubuntu@ec2-3-85-9-181.compute-1.amazonaws.com"
	"ubuntu@ec2-34-235-129-84.compute-1.amazonaws.com"
	"ubuntu@ec2-54-224-232-186.compute-1.amazonaws.com"
)

ips=(
	"3.230.126.141"
	"44.192.85.43"
	"52.90.41.8"
	"35.174.5.103"
	"54.221.166.142"
	"54.209.50.21"
)

for i in "${!machines[@]}"; do
	
	machine=${machines[i]}

	echo "clearing machine ${machine}..."
	ssh -i ${key} ${machine} "sudo systemctl stop edge.service || true"
	ssh -i ${key} ${machine} "sudo rm -rf /data && sudo rm -rf /home/ubuntu/validator-${i} && rm -f /home/ubuntu/genesis.json"

done

for i in "${!machines[@]}"; do

	machine=${machines[i]}
	x=$((i + 1))

	rm -rf validator-${i}
	cp -r ../step-1/validator-${x} validator-${i}

	scp -i ${key} -r validator-${i} ${machine}:/home/ubuntu
	ssh -i ${key} ${machine} "sudo mv /home/ubuntu/validator-${i} /data && sudo chown ubuntu /data"

	runCmd="/home/ubuntu/polygon-edge server --data-dir /data --seal --chain /home/ubuntu/genesis.json --num-block-confirmations 128 --libp2p \"0.0.0.0:30301\" --devp2p \"0.0.0.0:30302\" --jsonrpc \"0.0.0.0:8545\" --grpc-address \"0.0.0.0:9632\" --prometheus \"0.0.0.0:6060\" --price-limit 0 --block-gas-target \"0x0\""
	# runCmd="${runCmd} --nat=\"${ips[i]}\""

	if [ "${i}" -eq "0" ]; then
		runCmd="${runCmd} --relayer"
	fi

	rm -f run.sh
	echo "#!/bin/bash" > run.sh
	echo "" >> run.sh
	echo "${runCmd}" >> run.sh
	chmod +x run.sh

  scp -i ${key} run.sh ${machine}:/home/ubuntu/run.sh
	scp -i ${key} polygon-edge-linux ${machine}:/home/ubuntu/polygon-edge
	scp -i ${key} genesis.json ${machine}:/home/ubuntu/genesis.json
	scp -i ${key} edge.service ${machine}:/home/ubuntu/edge.service
	ssh -i ${key} ${machine} "sudo ufw allow 8545/tcp && sudo ufw allow 6060/tcp && sudo ufw allow 30301/tcp && sudo ufw allow 9632/tcp"
	ssh -i ${key} ${machine} "sudo cp /home/ubuntu/edge.service /etc/systemd/system/edge.service && sudo systemctl daemon-reload && sudo systemctl start edge.service && sudo systemctl enable edge.service"

done