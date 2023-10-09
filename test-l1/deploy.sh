#!/usr/bin/env bash

set -e

key=/Users/scott/keys/gateway-scott.pem

machines=( 
	"ubuntu@ec2-3-231-107-79.compute-1.amazonaws.com" 
	"ubuntu@ec2-52-54-249-54.compute-1.amazonaws.com" 
	"ubuntu@ec2-54-86-22-81.compute-1.amazonaws.com" 
	"ubuntu@ec2-44-195-2-96.compute-1.amazonaws.com" 
	"ubuntu@ec2-54-152-51-199.compute-1.amazonaws.com" 
	"ubuntu@ec2-3-90-219-149.compute-1.amazonaws.com" 
)

for i in "${!machines[@]}"; do

	machine=${machines[i]}
	echo "clearing machine ${machine}..."
	ssh -i "${key}" ${machine} "sudo systemctl stop geth.service || true"
	ssh -i ${key} ${machine} "sudo rm -rf /data"

done

for i in "${!machines[@]}"; do

	machine=${machines[i]}

	echo "deploying node ${i} to machine ${machine}...."

	scp -i ${key} -r node-${i} ${machine}:/home/ubuntu
	ssh -i ${key} ${machine} "sudo mv /home/ubuntu/node-${i} /data && sudo chown ubuntu /data"
	scp -i ${key} password.txt ${machine}:/data/password.txt
	scp -i ${key} run-${i}.sh ${machine}:/home/ubuntu/run.sh
	scp -i ${key} config.toml ${machine}:/home/ubuntu/config.toml
	scp -i ${key} geth-linux ${machine}:/home/ubuntu/geth
	scp -i ${key} geth.service ${machine}:/home/ubuntu/geth.service
	ssh -i ${key} ${machine} "sudo ufw allow 8545/tcp && sudo ufw allow 6060/tcp"
	ssh -i ${key} ${machine} "sudo cp /home/ubuntu/geth.service /etc/systemd/system/geth.service && sudo systemctl daemon-reload && sudo systemctl start geth.service && sudo systemctl enable geth.service"

	echo "finished node ${i}...."

done