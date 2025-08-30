#!/bin/bash

# https://labex.io/tutorials/shell-bash-getopt-391993
function help() {
    cat << EOF
Usage: $0 [-m|--matriz MAT] [-h|--hub HUB] [-c|--camino PATH] [-s|--separador FS] [-h|--help]

Options:
  -m, --matriz MAT       Ruta del archivo de la matriz de adyacencia.
  -h, --hub HUB          Determina qué estación es el "hub" de la red. No se puede usar junto con -c / -camino.
  -c, --camino PATH      Encuentra el camino más corto en tiempo. No se puede usar junto a -h / -hub.
  -s, --separador FS     Carácter para utilizarse como separador de columnas.

  -h, --help             Muestra este mensaje de ayuda
EOF
    exit 1
}
