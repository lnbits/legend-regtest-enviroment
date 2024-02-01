![TESTS](https://github.com/BoltzExchange/legend-regtest-enviroment/actions/workflows/ci.yml/badge.svg)

# nodes
* lnd-1: for locally testing
* lnd-2: used for boltz backend
* cln-1: for locally testing

# requirements
* docker compose v2: https://docs.docker.com/compose/install/compose-plugin/
* jq
* curl

# starting & validation
```console
  chmod +x ./regtest
  ./regtest
  # short answer :)
  ./regtest && echo "PASSED" || echo "FAILED" > /dev/null
```

# usage
get the regtest enviroment ready
```console
git clone git@github.com:BoltzExchange/legend-regtest-enviroment.git ~/repos/regtest
cd ~/repos/regtest
chmod +x ./regtest
./regtest # start the regtest and also run tests
```

usage of the `bitcoin-cli-sim`, `elements-cli-sim`, `lightning-cli-sim` and `lncli-sim` aliases
```console
source docker-scripts.sh
# use bitcoin core, mine a block
bitcoin-cli-sim -generate 1

# use elements, mine a liquid block
bitcoin-cli-sim -generate 1

# use c-lightning nodes
lightning-cli-sim 1 newaddr | jq -r '.bech32' # use node 1
lightning-cli-sim 2 getinfo # use node 2
lightning-cli-sim 3 getinfo # use node 3

# use lnd nodes
lncli-sim 1 newaddr p2wsh
lncli-sim 2 listpeers
```

# urls
* boltz api: http://localhost:9001/
* lnd-1 rest: http://localhost:8081/

# debugging docker logs
```console
docker logs regtest-boltz-1 -f
docker logs regtest-clightning-1-1 -f
docker logs regtest-lnd-2-1 -f
```
