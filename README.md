# edge-setup

## prerequisites
- build polygon-edge binary from your machine using `make build` in the root directory of the repo.  copy this binary into the `step-1` folder
- build polygon-edge suitable for a linux environment using `GOOS=linux GOARCH=amd64 go build -o polygon-edge-linux main.go` in the root directory of the repo.  Copy this file to the test-l2 folder
- download geth for your local environment and also the linux environment (https://geth.ethereum.org/downloads), rename the linux variant geth-linux and copy both binaries into the `step-2` and `test-l1` folders
- jq will need to be installed
- you will need to download the cast tool from foundry (https://github.com/foundry-rs/foundry/releases) for testing the L2 to handle contract deployments - place this file into the test-l2 folder
- you will need node installed to get the private key for testing the L2

## how to use
once the prereqs have been installed run the following:
- create a file called password.txt at the root of this repo and entera random password, do not commit this.  This password will be used for Geth activities
- run `step-1/create-validators.sh`
- run `step-2/create-l1.sh`
- update ips in `test-l1/generate.sh` to be the ips of the machines
- run `test-l1/generate.sh`
- update ssh details in `test-l1/deploy.sh`
- run `test-l1/deploy.sh`
- update the rpc variable address in `test-l2/launch-supernet.sh` to be that of an L1 RPC node
- update the ips array in `test-l2/launch-supernet.sh` to be the internal ips of the L2 nodes
- run `test-l2/launch-supernet.sh`
- update the ssh details and ips in the arrays in `test-l2/deploy.sh`
- run `test-l2/deploy.sh`

## troubleshooting

when first deployed the L1 signer nodes (first 3) will need the systemd service stopping and restarting.  Unclear at the moment as to why this is
