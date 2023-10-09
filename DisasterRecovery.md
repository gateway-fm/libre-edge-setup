# Edge

# Disaster Recovery

## Procedures

### Complete network shutdown for 1 hour

**Findings**

1. When the L1 and L2 came back online the public IPs of the machines had changed, any config related to these needed updating to restore peer discovery on the L1 side.  The L2 was already configured this way so had no problems resuming activity.

**Resolutions**

1. Use internal IPs for node discovery as these would have remained unchanged

### Shutdown of nodes on L2 in a single AZ and removal of data directory, temporary shutdown of node in another AZ.

**Findings**

1. On restarting the network the two nodes with a wiped data directory were slow to catch up to the tip so needed swapping to running as just a syncing node to speed this process up.  Whilst the node was running as a validator the relayer attempted sending checkpoints to the L1 which caused the networks to lose sync, they will catch up over a 4 day period.

**Resolutions**

1. Ensure in a DR scenario that nodes which lost their data and act as validators only run as a syncing node until at the tip of the chain at which point they can resume validator tasks.  This is achieved by swapping out of keys and is detailed in the playbook steps further below

## Playbook

### Validators - No disk backup, full failure

1. Backup keys securely if you have no already done so
2. On the problem node follow these steps
    1. Run `polygon-edge polybft-secrets --insecure --data-dir ./temp` to generate a set of new temporary keys.  These will be used for syncing the node back to the tip as a standard RPC node which is much quicker than as a validator.
    2. Setup a new datadir, in this example we will use `/data` as the directory.
    3. Copy the backed up `libp2p.key` into the datadir at `/data/libp2p/libp2p.key` you need to use the correct libp2p key otherwise other validators will fail the handshake with your node and cause more problems in the network
    4. Copy the temporary validator keys to `/data/consensus/validator.key` and `/data/consensus/validator-bls.key`
    5. Remove the following flags from the service definition `--seal` `--num-block-confirmations` `--relayer`.  **Only one validator will have the `--relayer` flag so if it is not there on the failed node it does not need removing, but be aware not to add this back in later steps.**
    6. Start the node up and let it sync to the tip of the chain.
    7. Stop the node
    8. Replace the backed up / original validator keys into the data dir in the `/data/consensus` folder.
    9. Replace the removed flags from the service definition.  **Be aware to only add the `--relayer` flag if it was there originally.  The network only has one relayer node.**
    10. Start the node back up again.  At this point it will quickly catch back up to the tip of the chain and start validating again

The node will then become an active validator again.  Whilst the validator is down the network will have slower block production whilst the other nodes choose the downed validator as the current block producer and will need to move to another round whilst this happens.

The relayer is programmed to send any missed checkpoints that might have occurred whilst the node was down.

## Things to avoid

- Do not run validator nodes with the validator flags whilst they are not at the current chain tip, especially the relayer node.  This will cause the relayer to send checkpoints to the L1 that are incorrect and cause the two chains to lose sync with each other.

## Tips

Sometimes the network can have a hard time producing blocks once a node has needed this length of time to recover.  If you notice that the block production hasn’t started again within a couple of minutes then one by one restart the nodes in the network.  This will reset their `round` for the block and help them to reach consensus again quickly.