#!/bin/bash

# ----- Variables -----------

# Nombre pais
NOMBRE=""
# Tiempo en segundos que se guarda la cache
TTL=""

# ---------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--nombre)
            NOMBRE="$2"
            shift 2
            ;;
        -t|--ttl)
            TTL="$2"
            shift 2
            ;;
        *)
            echo "Uso: $0 -n <nombre> -t <ttl>"
            exit 1
            ;;
        esac
done

# Comprobamos que se han pasado los argumentos necesarios

if [[ -z "$NOMBRE" || -z "$TTL" ]]; then
    echo "Uso: $0 -n <nombre> -t <ttl>"
    exit 1
fi

IFS=',' read -ra PAISES <<< "$NOMBRE"

# Temporal, mostrar las variables

for pais in "${PAISES[@]}"; do
    echo ""
    echo "Nombre del país: $pais"
    response=$(curl -s -w "%{http_code}" "https://restcountries.com/v3.1/name/$pais")

    status="${response: -3}"
    # echo "Código de estado: $status"
    body="${response::-3}"

    if [[ "$status" != "200" ]]; then
        echo "Error: País no encontrado"
        continue
    fi

    nombre=$(echo "$body" | jq -r '.[0].name.common')
    capital=$(echo "$body" | jq -r '.[0].capital[0]')
    region=$(echo "$body" | jq -r '.[0].region')
    poblacion=$(echo "$body" | jq -r '.[0].population')
    moneda_codigo=$(echo "$body" | jq -r '.[0].currencies | to_entries | map(.key) | .[]')
    moneda_nombre=$(echo "$body" | jq -r '.[0].currencies | to_entries | map(.value.name) | .[]')

    echo "País: $nombre"
    echo "Capital: $capital"
    echo "Región: $region"
    echo "Población: $poblacion"
    echo "Moneda: $moneda_nombre ($moneda_codigo)"
    echo ""

done

echo "Tiempo de caché: $TTL"