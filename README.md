![TESTS](https://github.com/lnbits/legend-regtest-enviroment/actions/workflows/ci.yml/badge.svg)

# nodes
* lnd-1: for locally testing your current lnbits
* lnd-2: used for boltz backend
* lnd-3: used for lnbits inside docker
* cln-1: for locally testing your current lnbits
* cln-2: used for clightning-REST
* eclair-1: for locally testing your current lnbits

# Installing regtest 
get the regtest enviroment ready
```console
# Install docker https://docs.docker.com/engine/install/
# Make sure your user has permission to use docker `sudo usermod -aG docker ${USER}` then reboot
# Stop/start docker `sudo systemctl stop docker` `sudo systemctl start docker`
sudo apt install jq
git clone https://github.com/lnbits/lnbits.git
cd lnbits
docker build -t lnbitsdocker/lnbits .
mkdir docker
git clone https://github.com/lnbits/legend-regtest-enviroment.git docker
cd docker
chmod +x ./tests
./tests # start the regtest and also run tests
sudo chown -R $USER ./data # Give the data file permissions for user
```

# Running LNbits on regtest
add this ENV variables to your `.env` file
```console
DEBUG=true

# LND
LNBITS_BACKEND_WALLET_CLASS="LndRestWallet"
LND_REST_ENDPOINT=https://127.0.0.1:8081/
LND_REST_CERT=/home/user/repos/lnbits-legend/docker/data/lnd-1/tls.cert
LND_REST_MACAROON=/home/user/repos/lnbits-legend/docker/data/lnd-1/data/chain/bitcoin/regtest/admin.macaroon

# CLN
LNBITS_BACKEND_WALLET_CLASS="CoreLightningWallet"
CORELIGHTNING_RPC=./docker/data/clightning-1/regtest/lightning-rpc 


# Run LNbits
poetry run lnbits

# Run LNbits with hot reload
make dev
```

# testing
```console
  chmod +x ./tests
  ./tests
  # short answer :)
  ./tests && echo "PASSED" || echo "FAILED" > /dev/null
```

usage of the `bitcoin-cli-sim`, `lightning-cli-sim` and `lncli-sim` aliases
```console
cd ~/lnbits/docker
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

# debugging docker logs
```console
docker logs lnbits-legend-lnbits-1 -f
docker logs lnbits-legend-boltz-1 -f
docker logs lnbits-legend-clightning-1-1 -f
docker logs lnbits-legend-lnd-2-1 -f
```
