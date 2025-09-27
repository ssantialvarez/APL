#!/bin/bash
# Demonios

function manejador() {
    echo "$1" > "prueba.txt"
    exit 0
}
CONTADOR=0

trap 'manejador "$CONTADOR"' SIGTERM
# trap - SIGTERM
# trap -p

sleep 5

while [ 1 -eq 1 ]
do
    (( CONTADOR+=1 ))
done