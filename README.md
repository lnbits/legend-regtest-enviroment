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

# lnbits development
add this ENV variables to your `.env` file
```console
DEBUG=true
LNBITS_BACKEND_WALLET_CLASS="LndRestWallet"
LND_REST_ENDPOINT=https://127.0.0.1:8081/
LND_REST_CERT=/home/user/repos/lnbits-legend/docker/data/lnd-1/tls.cert
LND_REST_MACAROON=/home/user/repos/lnbits-legend/docker/data/lnd-1/data/chain/bitcoin/regtest/admin.macaroon
poetry run uvicorn --host 0.0.0.0 --port 5000 --reload
```

# usage
get the regtest enviroment ready
```console
git clone git@github.com:lnbits/lnbits-legend.git ~/repos/lnbits-legend
cd ~/repos/lnbits-legend
docker build -t lnbits-legend .
mkdir ~/repos/lnbits-legend/docker
git clone git@github.com:lnbits/legend-regtest-enviroment.git ~/repos/lnbits-legend/docker
cd ~/repos/lnbits-legend/docker
chmod +x ./tests
./tests # start the regtest and also run tests
```

usage of the `bitcoin-cli-sim`, `lightning-cli-sim` and `lncli-sim` aliases
```console
cd ~/repos/lnbits-legend/docker
source docker-scripts.sh
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

# urls
* mempool: http://localhost:8080/
* boltz api: http://localhost:9001/
* lnd-1 rest: http://localhost:8081/
* lnbits: http://localhost:5001/

## latest release version from docker hub
if you want to use the latest version of lnbits uncomment L#11 in docker-compose.yaml

# debugging docker logs
```console
docker logs lnbits-legend-lnbits-1 -f
docker logs lnbits-legend-boltz-1 -f
docker logs lnbits-legend-clightning-1-1 -f
docker logs lnbits-legend-lnd-2-1 -f
```
