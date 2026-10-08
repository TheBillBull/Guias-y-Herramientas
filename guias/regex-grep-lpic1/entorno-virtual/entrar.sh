#!/bin/bash
# Abre una terminal DENTRO del ordenador virtual del libro.
#
#   bash entrar.sh            entra (cada vez, un laboratorio nuevo y limpio)
#   bash entrar.sh comprobar  comprueba que todo coincide con el libro
#
# Al salir (exit o Ctrl+D) el contenedor se borra: lo que hagas dentro desaparece,
# así que siempre puedes volver a empezar sin miedo a estropear nada.
if ! docker image inspect regex-lab >/dev/null 2>&1; then
    echo "Todavía no existe la imagen. Primero ejecuta:  bash construir.sh"
    exit 1
fi

if [ "$1" = "comprobar" ]; then
    exec docker run --rm --hostname ubuntu-pc regex-lab comprobar-entorno
fi

exec docker run -it --rm --hostname ubuntu-pc regex-lab "$@"
