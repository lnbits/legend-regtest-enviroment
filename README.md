# setup
Install `jq`
```console 
sudo apt install jq
```

Make sure you have the [docker compose plugin](https://docs.docker.com/compose/install/compose-plugin/) installed. The old Python docker-compose *will not work*.

clone it into your lnbits-legend repository
```console
mkdir ~/repos/lnbits-legend/docker
git clone git@github.com:lnbits/legend-regtest-enviroment.git ~/repos/lnbits-legend/docker

```
# usage
```console
cd ~/repos/lnbits-legend/docker
source docker-scripts.sh

# start docker-compose with logs
lnbits-regtest-start-log
# start docker-compose in background
lnbits-regtest-start

# errors on startup are normal! wait at least 60 seconds
# for all services to come up before you start initializing
sleep 60

# initialize blockchain,
# fund lightning wallets
# connect peers
# create channels
# balance channels
lnbits-regtest-init

# use bitcoin core, mine a block
bitcoin-cli-sim -generate 1

# use c-lightning nodes
lightning-cli-sim 1 newaddr | jq -r '.bech32' # use node 1
lightning-cli-sim 2 getinfo # use node 2
lightning-cli-sim 3 getinfo # use node 3

# use lnd nodes
lncli-sim 1 newaddr p2wsh
lncli-sim 2 listpeers
```

# lnbits debug log
```console
docker logs lnbits-legend-lnbits-1 -f
```
