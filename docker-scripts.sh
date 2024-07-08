#!/bin/sh
export COMPOSE_PROJECT_NAME=cashu

bitcoin-cli-sim() {
  docker exec cashu-bitcoind-1 bitcoin-cli -rpcuser=cashu -rpcpassword=cashu -regtest "$@"
}

# args(i, cmd)
lightning-cli-sim() {
  i=$1
  shift # shift first argument so we can use $@
  docker exec cashu-clightning-$i-1 lightning-cli --network regtest "$@"
}

# args(i, cmd)
lncli-sim() {
  i=$1
  shift # shift first argument so we can use $@
  docker exec cashu-lnd-$i-1 lncli --network regtest --rpcserver=lnd-$i:10009 "$@"
}

# args(i)
fund_clightning_node() {
  address=$(lightning-cli-sim $1 newaddr | jq -r .bech32)
  echo "funding: $address on clightning-node: $1"
  bitcoin-cli-sim -named sendtoaddress address=$address amount=30 fee_rate=100 > /dev/null
}

# args(i)
fund_lnd_node() {
  address=$(lncli-sim $1 newaddress p2wkh | jq -r .address)
  echo "funding: $address on lnd-node: $1"
  bitcoin-cli-sim -named sendtoaddress address=$address amount=30 fee_rate=100 > /dev/null
}

# args(i, j)
connect_clightning_node() {
  pubkey=$(lightning-cli-sim $2 getinfo | jq -r '.id')
  lightning-cli-sim $1 connect $pubkey@cashu-clightning-$2-1:9735 | jq -r '.id'
}

# args(i)
clightning_create_rune() {
  lightning-cli-sim $1 createrune | jq -r '.rune' > ./data/clightning-$1/rune
}

cashu-regtest-start(){
  if ! command -v jq &> /dev/null
  then
      echo "jq is not installed"
      exit
  fi
  if ! command -v docker &> /dev/null
  then
      echo "docker is not installed"
      exit
  fi
  if ! command -v docker version &> /dev/null
  then
      echo "dockerd is not running"
      exit
  fi
  cashu-regtest-stop
  docker compose up -d --remove-orphans
  cashu-regtest-init
}

cashu-regtest-start-log(){
  cashu-regtest-stop
  docker compose up --remove-orphans
  cashu-regtest-init
}

cashu-regtest-stop(){
  docker compose down --volumes
  # clean up lightning node data
  sudo rm -rf ./data/clightning-1 ./data/clightning-2 ./data/clightning-3 ./data/lnd-1  ./data/lnd-2 ./data/lnd-3 ./data/boltz/boltz.db
  # recreate lightning node data folders preventing permission errors
  mkdir ./data/clightning-1 ./data/clightning-2 ./data/clightning-3 ./data/lnd-1 ./data/lnd-2 ./data/lnd-3
}

cashu-regtest-restart(){
  cashu-regtest-stop
  cashu-regtest-start
}

cashu-bitcoin-init(){
  echo "init_bitcoin_wallet..."
  for i in $(seq 1 10); do
    bitcoin-cli-sim createwallet cashu && break  || sleep 1
  done
  bitcoin-cli-sim loadwallet cashu
  echo "mining 150 blocks..."
  bitcoin-cli-sim -generate 150 > /dev/null
}

cashu-regtest-init(){
  cashu-bitcoin-init
  cashu-lightning-sync
  cashu-lightning-init
}

cashu-lightning-sync(){
  wait-for-clightning-sync 1
  wait-for-clightning-sync 2
  wait-for-clightning-sync 3
  wait-for-lnd-sync 1
  wait-for-lnd-sync 2
  wait-for-lnd-sync 3
}

cashu-lightning-init(){

  # create 10 UTXOs for each node
  for i in 0 1 2; do
    fund_clightning_node 1
    fund_clightning_node 2
    fund_clightning_node 3
    fund_lnd_node 1
    fund_lnd_node 2
    fund_lnd_node 3
  done

  echo "mining 3 blocks..."
  bitcoin-cli-sim -generate 3 > /dev/null

  cashu-lightning-sync

  channel_confirms=6
  channel_size=24000000 # 0.024 btc
  balance_size=12000000 # 0.12 btc
  balance_size_msat=12000000000 # 0.12 btc

  # lnd-1 -> lnd-2
  lncli-sim 1 connect $(lncli-sim 2 getinfo | jq -r '.identity_pubkey')@cashu-lnd-2-1 > /dev/null
  echo "open channel from lnd-1 to lnd-2"
  lncli-sim 1 openchannel $(lncli-sim 2 getinfo | jq -r '.identity_pubkey') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1

  # lnd-1 -> lnd-3
  lncli-sim 1 connect $(lncli-sim 3 getinfo | jq -r '.identity_pubkey')@cashu-lnd-3-1 > /dev/null
  echo "open channel from lnd-1 to lnd-3"
  lncli-sim 1 openchannel $(lncli-sim 3 getinfo | jq -r '.identity_pubkey') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1

  # lnd-1 -> cln-1
  lncli-sim 1 connect $(lightning-cli-sim 1 getinfo | jq -r '.id')@cashu-clightning-1-1 > /dev/null
  echo "open channel from lnd-1 to cln-1"
  lncli-sim 1 openchannel $(lightning-cli-sim 1 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1

  # lnd-1 -> cln-2
  lncli-sim 1 connect $(lightning-cli-sim 2 getinfo | jq -r '.id')@cashu-clightning-2-1 > /dev/null
  echo "open channel from lnd-1 to cln-2"
  lncli-sim 1 openchannel $(lightning-cli-sim 2 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1

  # lnd-1 -> cln-3
  lncli-sim 1 connect $(lightning-cli-sim 3 getinfo | jq -r '.id')@cashu-clightning-3-1 > /dev/null
  echo "open channel from lnd-1 to cln-3"
  lncli-sim 1 openchannel $(lightning-cli-sim 3 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1

  # lnd-2 -> cln-2
  lncli-sim 2 connect $(lightning-cli-sim 2 getinfo | jq -r '.id')@cashu-clightning-2-1 > /dev/null
  echo "open channel from lnd-2 to cln-2"
  lncli-sim 2 openchannel $(lightning-cli-sim 2 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 2

  # lnd-3 -> cln-3
  lncli-sim 3 connect $(lightning-cli-sim 3 getinfo | jq -r '.id')@cashu-clightning-3-1 > /dev/null
  echo "open channel from lnd-3 to cln-1"
  lncli-sim 3 openchannel $(lightning-cli-sim 3 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 3

  # lnd-3 -> cln-1
  lncli-sim 3 connect $(lightning-cli-sim 1 getinfo | jq -r '.id')@cashu-clightning-1-1 > /dev/null
  echo "open channel from lnd-3 to cln-1"
  lncli-sim 3 openchannel $(lightning-cli-sim 1 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 3

  wait-for-clightning-channel 1
  wait-for-clightning-channel 2
  wait-for-clightning-channel 3

  # create rune for each clightning node
  clightning_create_rune 1
  clightning_create_rune 2
  clightning_create_rune 3

  cashu-lightning-sync

}

wait-for-lnd-channel(){
  while true; do
    pending=$(lncli-sim $1 pendingchannels | jq -r '.pending_open_channels | length')
    echo "lnd-$1 pendingchannels: $pending"
    if [[ "$pending" == "0" ]]; then
      break
    fi
    sleep 1
  done
}

wait-for-lnd-sync(){
  while true; do
    if [[ "$(lncli-sim $1 getinfo 2>&1 | jq -r '.synced_to_chain' 2> /dev/null)" == "true" ]]; then
      echo "lnd-$1 is synced!"
      break
    fi
    echo "waiting for lnd-$1 to sync..."
    sleep 1
  done
}

wait-for-clightning-channel(){
  while true; do
    pending=$(lightning-cli-sim $1 getinfo | jq -r '.num_pending_channels | length')
    echo "cln-$1 pendingchannels: $pending"
    if [[ "$pending" == "0" ]]; then
      if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_bitcoind_sync' 2> /dev/null)" == "null" ]]; then
        if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_lightningd_sync' 2> /dev/null)" == "null" ]]; then
          break
        fi
      fi
    fi
    sleep 1
  done
}

wait-for-clightning-sync(){
  while true; do
    if [[ ! "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.id' 2> /dev/null)" == "null" ]]; then
      if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_bitcoind_sync' 2> /dev/null)" == "null" ]]; then
        if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_lightningd_sync' 2> /dev/null)" == "null" ]]; then
          echo "cln-$1 is synced!"
          break
        fi
      fi
    fi
    echo "waiting for cln-$1 to sync..."
    sleep 1
  done
}
