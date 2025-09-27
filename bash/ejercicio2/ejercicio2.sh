#!/bin/bash

# https://labex.io/tutorials/shell-bash-getopt-391993
function help() {
    cat << EOF
Usage: $0 [-m|--matriz MAT] [-h|--hub HUB] [-c|--camino PATH] [-s|--separador FS] [-h|--help]

Options:
  -m, --matriz MAT       Ruta del archivo de la matriz de adyacencia.
  -h, --hub HUB          Determina qué estación es el "hub" (estación con más conexiones) de la red. No se puede usar junto con -c / -camino.
  -c, --camino PATH      Encuentra el camino más corto en tiempo. No se puede usar junto a -h / -hub.
  -s, --separador FS     Carácter para utilizarse como separador de columnas.

  -h, --help             Muestra este mensaje de ayuda
EOF
    exit 1
}

declare -a RESULTADO
RESULTADO=()
MATRIZ=""
HUB=""
CAMINO=""
SEPARADOR=""



# Parseo de argumentos
options=$(getopt -o m:h:cs: --l help,matriz:,hub:,camino,separador: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo "$0: error en los argumentos." >&2
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
        -m|--matriz)
            MATRIZ="$2"
            shift 2
            ;;
        -h|--hub)
            HUB=1
            shift 1
            ;;
        -c|--camino)
            CAMINO=1
            shift 1
            ;;
        -s|--separador)
            SEPARADOR="$2"
            shift 2
            ;;
        --help)
            help
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "$0: opción no válida" >&2
            exit 1
            ;;
    esac
done

# Validación de argumentos
if [ -z "$MATRIZ" ]; then
    echo "Debe especificar el archivo de la matriz con -m o --matriz" >&2
    exit 1
fi
if [ -n "$HUB" ] && [ -n "$CAMINO" ]; then
    echo "No se puede usar -hub y -camino juntos" >&2
    exit 1
fi
if [ ! -f "$MATRIZ" ]; then
    echo "El archivo de matriz no existe: $MATRIZ" >&2
    exit 1
fi

# Definir separador (por defecto '|')
if [ -z "$SEPARADOR" ]; then
    SEPARADOR='|'
fi

# Leer la matriz en un array de Bash
declare -a matriz
num_filas=0
num_columnas=0

while IFS= read -r linea || [ -n "$linea" ]; do
    # Quitar espacios y saltos
    linea=$(echo "$linea" | tr -d '\r\n ')
    # Separar por el separador
    IFS="$SEPARADOR" read -ra valores <<< "$linea"
    # Validar que todos los valores sean numéricos
    for v in "${valores[@]}"; do
        if ! [[ $v =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            echo "Valor no numérico en la matriz: $v" >&2
            exit 1
        fi
    done
    # Guardar la fila
    matriz+=("${valores[@]}")
    # Contar columnas
    if [ $num_filas -eq 0 ]; then
        num_columnas=${#valores[@]}
    else
        if [ ${#valores[@]} -ne $num_columnas ]; then
            echo "La matriz no es cuadrada (filas de diferente longitud)" >&2
            exit 1
        fi
    fi
    ((num_filas++))
done < "$MATRIZ"

# Validar que la matriz sea cuadrada
if [ $num_filas -ne $num_columnas ]; then
    echo "La matriz no es cuadrada ($num_filas x $num_columnas)" >&2
    exit 1
fi

# Validar simetría
for ((i=0; i<num_filas; i++)); do
    for ((j=0; j<num_columnas; j++)); do
        idx1=$((i*num_columnas+j))
        idx2=$((j*num_columnas+i))
        if [ "${matriz[$idx1]}" != "${matriz[$idx2]}" ]; then
            echo "La matriz no es simétrica en ($i,$j) y ($j,$i)" >&2
            exit 1
        fi
    done
done

# Si llegamos aquí, la matriz es válida
echo "Matriz válida: $num_filas x $num_columnas"

# Lógica para encontrar el hub
if [ -n "$HUB" ]; then
    max_conexiones=0
    hub_estacion=0
    for ((i=0; i<num_filas; i++)); do
        conexiones=0
        for ((j=0; j<num_columnas; j++)); do
            idx=$((i*num_columnas+j))
            # No contar la diagonal y solo contar conexiones directas (valor > 0)
            if [ $i -ne $j ] && (( $(echo "${matriz[$idx]} > 0" | bc -l) )); then
                ((conexiones++))
            fi
        done
        if [ $conexiones -gt $max_conexiones ]; then
            max_conexiones=$conexiones
            hub_estacion=$((i+1))
        fi
    done
    echo "**Hub de la red:** Estación $hub_estacion ($max_conexiones conexiones)"
    # Aquí se puede guardar el resultado en el informe
    exit 0
fi

# Lógica para encontrar el camino más corto usando Dijkstra
if [ -n "$CAMINO" ]; then
    # Floyd-Warshall
    infinito=999999
    declare -a dist
    declare -a next
    # Inicializar distancias y matriz de "next" para reconstrucción de caminos
    for ((i=0; i<num_filas; i++)); do
        for ((j=0; j<num_columnas; j++)); do
            idx=$((i*num_columnas+j))
            if [ $i -eq $j ]; then
                dist[$idx]=0
                next[$idx]=-1
            elif (( $(echo "${matriz[$idx]} > 0" | bc -l) )); then
                dist[$idx]=${matriz[$idx]}
                next[$idx]=$j
            else
                dist[$idx]=$infinito
                next[$idx]=-1
            fi
        done
    done

    # Algoritmo principal
    for ((k=0; k<num_filas; k++)); do
        for ((i=0; i<num_filas; i++)); do
            for ((j=0; j<num_filas; j++)); do
                idx_ij=$((i*num_columnas+j))
                idx_ik=$((i*num_columnas+k))
                idx_kj=$((k*num_columnas+j))
                suma=$(echo "${dist[$idx_ik]} + ${dist[$idx_kj]}" | bc -l)
                if (( $(echo "$suma < ${dist[$idx_ij]}" | bc -l) )); then
                    dist[$idx_ij]=$suma
                    next[$idx_ij]=${next[$idx_ik]}
                fi
            done
        done
    done

    # Reconstruir el camino más corto entre estación 1 y estación N
    origen=0
    destino=$((num_filas-1))
    idx_od=$((origen*num_columnas+destino))
    if [ "${dist[$idx_od]}" == "$infinito" ]; then
        echo "No hay camino entre Estación 1 y Estación $((destino+1))"
        exit 1
    fi

    # Construir la ruta
    ruta=()
    u=$origen
    while [ $u -ne $destino ]; do
        ruta+=( $((u+1)) )
        idx=$((u*num_columnas+destino))
        u=${next[$idx]}
        if [ $u -eq -1 ]; then
            echo "No hay camino entre Estación 1 y Estación $((destino+1))"
            exit 1
        fi
    done
    ruta+=( $((destino+1)) )

    # Mostrar resultado
    echo "**Camino más corto: entre Estación 1 y Estación $((destino+1))**"
    echo "**Tiempo total:** ${dist[$idx_od]} minutos"
    echo -n "**Ruta:** "
    for ((i=0; i<${#ruta[@]}; i++)); do
        if [ $i -gt 0 ]; then echo -n " -> "; fi
        echo -n "${ruta[$i]}"
    done
    echo
    exit 0
fi