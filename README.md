![TESTS](https://github.com/lnbits/legend-regtest-enviroment/actions/workflows/ci.yml/badge.svg)
![Docker Image](https://github.com/callebtc/cashu-regtest-environment/actions/workflows/publish-image.yml/badge.svg)

# nodes
* lnd-1: for testing your software
* lnd-2: used for boltz backend
* lnd-3: used for lnbits inside docker
* cln-1: for testing your software
* cln-2: used for clightning-REST

# Installing regtest 
get the regtest environment ready
```sh
# Install docker https://docs.docker.com/engine/install/
# Make sure your user has permission to use docker 'sudo usermod -aG docker ${USER}' then reboot
# Stop/start docker 'sudo systemctl stop docker' 'sudo systemctl start docker'

git clone https://github.com/callebtc/cashu-regtest.git
cd cashu-regtest
./start.sh  # start the regtest and also run tests
```

# Running Nutshell on regtest
add this ENV variables to your `.env` file (assuming that the `cashu-regtest` directory is in `../` from the `nutshell` directory)
```sh
# LND
MINT_BACKEND_BOLT11_SAT=LndRestWallet
MINT_LND_REST_ENDPOINT=https://localhost:8081
MINT_LND_REST_CERT="../cashu-regtest/data/lnd-3/tls.cert"
MINT_LND_REST_MACAROON="../cashu-regtest/data/lnd-3/data/chain/bitcoin/regtest/admin.macaroon"

# CLN
MINT_BACKEND_BOLT11_SAT=CoreLightningRestWallet
MINT_CORELIGHTNING_REST_URL=https://localhost:3001
MINT_CORELIGHTNING_REST_MACAROON=../cashu-regtest-enviroment/data/clightning-2-rest/access.macaroon
MINT_CORELIGHTNING_REST_CERT=../cashu-regtest-enviroment/data/clightning-2-rest/certificate.pem
```

# Regtest nodes

You can interact with the software running in the container using the `bitcoin-cli-sim`, `lightning-cli-sim` and `lncli-sim` aliases. You can bind these aliases by sourcing the `docker-scripts.sh` file:
```sh
source docker-scripts.sh

# LND
lncli-sim 1 addinvoice <amount> # create an invoice
lncli-sim 1 payinvoice -f <invoice> # pay an invoice

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
```sh
docker logs cashu-lnbits-1 -f
docker logs cashu-boltz-1 -f
docker logs cashu-clightning-1-1 -f
docker logs cashu-lnd-2-1 -f
```

# Docker Image

The regtest environment is available as a Docker image on GitHub Container Registry (GHCR). You can use it in your GitHub Actions workflows or locally.

## Using the Docker Image

### In GitHub Actions

To use the Docker image in your workflows:

```yaml
services:
  regtest:
    image: ghcr.io/callebtc/cashu-regtest-environment:latest
    ports:
      - 5001:5001  # LNbits
      - 8081:8081  # LND REST
      - 10009:10009  # LND RPC
      - 3001:3001  # CoreLightning REST
      - 3010:3010  # CLN REST
```

### Running Locally

To run the image locally, you need to mount the Docker socket:

```sh
docker run -d \
  --name cashu-regtest \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 5001:5001 -p 8081:8081 -p 10009:10009 -p 3001:3001 -p 3010:3010 \
  ghcr.io/callebtc/cashu-regtest-environment:latest
```

Note: The container needs access to the host's Docker daemon to start the regtest environment.

## Releasing a New Version

To release a new version of the Docker image:

1. Make your changes to the codebase
2. Create a new release in GitHub:
   - Go to the repository on GitHub
   - Click on "Releases" in the right sidebar
   - Click "Create a new release"
   - Enter a tag version (e.g., `v1.0.0`)
   - Add a title and description
   - Click "Publish release"

3. The GitHub Action will automatically:
   - Build the Docker image
   - Tag it with the version number and 'latest'
   - Push it to ghcr.io/callebtc/cashu-regtest-environment

The image will be available at `ghcr.io/callebtc/cashu-regtest-environment:latest` and `ghcr.io/callebtc/cashu-regtest-environment:v1.0.0` (or whatever version you tagged).

### Required Repository Permissions

To allow GitHub Actions to publish packages to the GitHub Container Registry:

1. Go to your repository settings
2. Navigate to "Actions > General"
3. Under "Workflow permissions", select "Read and write permissions"
4. Save the changes

For more details, see the [GitHub documentation on package permissions](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions).

## Manually Building and Pushing the Image

If you need to manually build and push the image:

```sh
# Build the image
docker build -t ghcr.io/callebtc/cashu-regtest-environment:latest .

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push the image
docker push ghcr.io/callebtc/cashu-regtest-environment:latest
```

Replace `USERNAME` with your GitHub username and `$GITHUB_TOKEN` with a GitHub token with the `write:packages` scope.
