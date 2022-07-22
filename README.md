# test status
![TESTS](https://github.com/lnbits/legend-regtest-enviroment/actions/workflows/ci.yml/badge.svg)

# requirements
* docker compose v2: https://docs.docker.com/compose/install/compose-plugin/
* jq
* curl

# testing
```console
  chmod +x ./tests
  ./tests
  # short answer :)
  ./tests && echo "PASSED" || echo "FAILED" > /dev/null
```

# usage
```console
# build the lnbits docker image
cd ~/repos/lnbits-legend
docker build -t lnbits-legend .

# source the scripts
cd ~/repos/lnbits-legend/docker
source docker-scripts.sh

# start docker-compose with logs
lnbits-regtest-start-log
# start docker-compose in background
lnbits-regtest-start

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

# urls for lnbits and mempool
* lnbits: http://localhost:5000/
* mempool: http://localhost:8080/

# lnbits debug log
```console
docker logs lnbits-legend-lnbits-1 -f
```
