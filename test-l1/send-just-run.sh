#!/bin/bash

machines=( 
	"ec2-44-205-23-183.compute-1.amazonaws.com" 
	"ec2-34-239-111-56.compute-1.amazonaws.com" 
	"ec2-52-91-16-19.compute-1.amazonaws.com" 
	"ec2-44-213-248-203.compute-1.amazonaws.com" 
	"ec2-52-201-225-201.compute-1.amazonaws.com" 
	"ec2-54-90-157-211.compute-1.amazonaws.com" 
)

for i in "${!machines[@]}"; do

	scp -i /Users/scott/keys/gateway-scott.pem run-${i}.sh ubuntu@${machines[i]}:/home/ubuntu/run.sh
	scp -i /Users/scott/keys/gateway-scott.pem config.toml ubuntu@${machines[i]}:/home/ubuntu/config.toml

done