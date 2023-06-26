#!/bin/sh
export COMPOSE_PROJECT_NAME=regtest

bitcoin-cli-sim() {
  docker exec regtest-bitcoind-1 bitcoin-cli -rpcuser=regtest -rpcpassword=regtest -regtest "$@"
}

elements-cli-sim() {
  docker exec -it regtest-elementsd-1 elements-cli "$@"
}

# args(i, cmd)
lightning-cli-sim() {
  i=$1
  shift # shift first argument so we can use $@
  docker exec regtest-clightning-$i-1 lightning-cli --network regtest "$@"
}

# args(i, cmd)
lncli-sim() {
  i=$1
  shift # shift first argument so we can use $@
  docker exec regtest-lnd-$i-1 lncli --network regtest --rpcserver=lnd-$i:10009 "$@"
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
  lightning-cli-sim $1 connect $pubkey@regtest-clightning-$2-1:9735 | jq -r '.id'
}

regtest-start(){
  regtest-stop
  docker compose up -d --remove-orphans
  regtest-init
}

regtest-start-log(){
  regtest-stop
  docker compose up --remove-orphans
  regtest-init
}

regtest-stop(){
  docker compose down --volumes
  # clean up lightning node data
  sudo rm -rf ./data/clightning-1 ./data/lnd-1  ./data/lnd-2 ./data/boltz/boltz.db ./data/elements/liquidregtest
  # recreate lightning node data folders preventing permission errors
  mkdir ./data/clightning-1 ./data/lnd-1 ./data/lnd-2
}

regtest-restart(){
  regtest-stop
  regtest-start
}

bitcoin-init(){
  echo "init_bitcoin_wallet..."
  bitcoin-cli-sim createwallet regtest || bitcoin-cli-sim loadwallet regtest
  echo "mining 150 bitcoin blocks..."
  bitcoin-cli-sim -generate 150 > /dev/null
}

elements-init(){
  elements-cli-sim createwallet regtest || elements-cli-sim loadwallet regtest
  elements-cli-sim -generate 150
  echo "mining 150 liquid blocks..."
  elements-cli-sim rescanblockchain 0 > /dev/null
}

regtest-init(){
  bitcoin-init
  elements-init
  lightning-sync
  lightning-init
}

lightning-sync(){
  wait-for-clightning-sync 1
  wait-for-lnd-sync 1
  wait-for-lnd-sync 2
}

lightning-init(){
  # create 10 UTXOs for each node
  for i in 0 1 2 3 4; do
    fund_clightning_node 1
    fund_lnd_node 1
    fund_lnd_node 2
  done

  echo "mining 3 blocks..."
  bitcoin-cli-sim -generate 3 > /dev/null

  lightning-sync

  channel_confirms=6
  channel_size=24000000 # 0.024 btc
  balance_size=12000000 # 0.12 btc
  balance_size_msat=12000000000 # 0.12 btc

  # lnd-1 -> lnd-2
  lncli-sim 1 connect $(lncli-sim 2 getinfo | jq -r '.identity_pubkey')@regtest-lnd-2-1 > /dev/null
  echo "open channel from lnd-1 to lnd-2"
  lncli-sim 1 openchannel $(lncli-sim 2 getinfo | jq -r '.identity_pubkey') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1

  # lnd-1 -> cln-1
  lncli-sim 1 connect $(lightning-cli-sim 1 getinfo | jq -r '.id')@regtest-clightning-1-1 > /dev/null
  echo "open channel from lnd-1 to cln-1"
  lncli-sim 1 openchannel $(lightning-cli-sim 1 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1

  # lnd-2 -> cln-1
  lncli-sim 2 connect $(lightning-cli-sim 1 getinfo | jq -r '.id')@regtest-clightning-1-1 > /dev/null
  echo "open channel from lnd-2 to cln-1"
  lncli-sim 2 openchannel $(lightning-cli-sim 1 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 2
  wait-for-clightning-channel 1

  lightning-sync

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
    if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_bitcoind_sync' 2> /dev/null)" == "null" ]]; then
      if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_lightningd_sync' 2> /dev/null)" == "null" ]]; then
        echo "cln-$1 is synced!"
        break
      fi
    fi
    echo "waiting for cln-$1 to sync..."
    sleep 1
  done
}
