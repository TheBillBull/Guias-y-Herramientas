#!/bin/bash
# Construye la imagen Docker "regex-lab" (el ordenador virtual del libro).
# Solo hay que hacerlo UNA vez (tarda unos minutos y necesita internet).
#
#   bash construir.sh
#
set -e
cd "$(dirname "$0")/.."          # → guias/regex-grep-lpic1  (contexto de la imagen)

if ! command -v docker >/dev/null 2>&1; then
    echo "No encuentro 'docker'. Instálalo primero (mira entorno-virtual/README.md)."
    exit 1
fi

# (EXTRA_BUILD_ARGS: opciones adicionales para "docker build", p. ej. "--network host")
construir() {   # construir IMAGEN_BASE
    # shellcheck disable=SC2086
    docker build $EXTRA_BUILD_ARGS --build-arg BASE="$1" -f entorno-virtual/Dockerfile -t regex-lab .
}

echo ">> Construyendo la imagen regex-lab (Ubuntu 24.04)..."
if construir ubuntu:24.04; then
    :
else
    echo
    echo ">> Falló con Docker Hub (a veces limita las descargas anónimas)."
    echo ">> Reintento con una copia de la misma imagen en mirror.gcr.io ..."
    construir mirror.gcr.io/library/ubuntu:24.04
fi

echo
echo ">> Listo. Ahora entra con:  bash entrar.sh"
