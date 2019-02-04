#!/bin/bash
set -e

unset http_proxy
unset https_proxy

# Shamelessly stolen from https://superuser.com/a/917112
wait_str() {
  local file="$1"; shift
  local search_term="$1"; shift
  local wait_time="${1:-2m}"; shift # 2 minutes as default timeout

  (timeout $wait_time tail -F -n+1 "$file" &) | grep -q "$search_term" && return 0

  echo "Timeout of $wait_time reached. Unable to find '$search_term' in '$file'"
  return 1
}

# Start InfluxDB
echo "Starting InfluxDB"
influxd > /var/log/influxdb.log 2>&1 &
sleep 3

# Create DBRPs
influx -execute 'CREATE DATABASE telegraf' || (cat /var/log/influxdb.log; echo "Influx failed"; exit 101)

# Start Kapactior
echo "Starting Kapactior"
kapacitord > /var/log/kapacitor.log 2>&1 &
sleep 2

pgrep "kapacitord" > /dev/null || (cat /var/log/kapacitor.log; echo "Kapactior failed (process exited)"; exit 102)

wait_str /var/log/kapacitor.log "listening for signals" || (cat /var/log/kapacitor.log; echo "Kapactior failed (timeout)"; exit 103)

echo "Startup done, injecting data"
/run_tests.sh || (echo "Injecting test data failed"; exit 104)

echo "Injecting done, waiting 15s before checking"; echo
sleep 15
/check_tests.py || (echo "One or more test checks failed"; exit 105)

exec "$@"