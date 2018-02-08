#!/bin/bash -e
: ${BASE_URL:="http://guestbook:3000"}
: ${USER_COUNT:=1}
: ${READS_PER_WRITE:=1000}

curl -sS "${BASE_URL}/lrange/guestbook" > /dev/null

handle_exit() {
  trap 'exit 0' SIGTERM && kill -- -$$
}
trap handle_exit SIGINT SIGTERM EXIT
for j in $(seq 1 ${USER_COUNT}); do
    {
    while true; do
        for i in $(seq 1 ${READS_PER_WRITE}); do
            curl -sS "${BASE_URL}/lrange/guestbook" > /dev/null || true
            sleep 1
        done
        curl -sS "${BASE_URL}/rpush/guestbook/entry" > /dev/null || true
    done
    } &
done
wait
