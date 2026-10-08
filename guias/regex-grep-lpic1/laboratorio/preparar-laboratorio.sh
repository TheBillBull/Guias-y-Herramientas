#!/usr/bin/env bash
# ============================================================================
#  preparar-laboratorio.sh
#  Crea la carpeta de prácticas  ~/lab-regex  con todos los ficheros que
#  usan los ejercicios de la guía de expresiones regulares y grep.
#
#  Uso:
#      bash preparar-laboratorio.sh              # crea  ~/lab-regex
#      bash preparar-laboratorio.sh /otra/ruta   # crea el laboratorio ahí
#
#  Es seguro ejecutarlo varias veces: vuelve a dejar los ficheros como nuevos
#  (útil si estropeas algo con sed -i, ¡para eso es el laboratorio!).
# ============================================================================
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTINO="${1:-$HOME/lab-regex}"

if [ ! -d "$AQUI/datos" ]; then
    echo "No encuentro la carpeta 'datos' junto a este script ($AQUI)." >&2
    exit 1
fi

mkdir -p "$DESTINO"
cp -a "$AQUI/datos/." "$DESTINO/"
cd "$DESTINO"

# --- Fichero con finales de línea de Windows (CRLF = \r\n) -------------------
printf 'hola\r\nmundo\r\nlinux\r\n' > windows.txt

# --- Fichero binario (contiene bytes NUL) ------------------------------------
printf 'cabecera\0\0datos binarios\0hola\nfin\n' > binario.bin

# --- Fichero separado por tabuladores ----------------------------------------
printf 'nombre\tedad\tciudad\n'  >  tabulado.tsv
printf 'Juan\t34\tMadrid\n'      >> tabulado.tsv
printf 'Ana\t28\tBarcelona\n'    >> tabulado.tsv
printf 'Luis\t45\tSevilla\n'     >> tabulado.tsv
printf 'Marta\t19\tMadrid\n'     >> tabulado.tsv

# --- Un fichero con una sola línea y SIN salto de línea final ----------------
printf 'ultima linea sin salto' > sin-salto-final.txt

# --- Un árbol de directorios para practicar con find y locate ----------------
rm -rf arbol
mkdir -p arbol/informes arbol/fotos arbol/scripts arbol/docs/antiguo \
         arbol/copias arbol/proyecto arbol/tmp
for f in informes/informe-2023-01.txt informes/informe-2023-02.txt \
         informes/informe-2024-01.txt informes/informe-2024-02.txt \
         informes/informe-2024-02.pdf informes/resumen-2024.PDF \
         fotos/IMG_0001.jpg fotos/IMG_0002.jpg fotos/IMG_0003.JPG \
         fotos/foto-vacaciones.png "fotos/captura de pantalla.png" \
         scripts/backup.sh scripts/deploy.sh scripts/limpiar.py scripts/test.PY \
         docs/README.md docs/manual.pdf docs/notas.txt docs/.oculto.txt \
         docs/antiguo/viejo.txt docs/antiguo/viejo.txt.bak \
         copias/datos.tar.gz copias/datos.tar.bz2 copias/backup-2024-10-01.zip \
         proyecto/main.c proyecto/main.h proyecto/util.c proyecto/Makefile \
         tmp/informe.txt~ "tmp/#autosave#" tmp/.fichero.swp \
         vacio.txt; do
    touch "arbol/$f"
done
chmod +x arbol/scripts/*.sh arbol/scripts/limpiar.py
printf 'contenido del informe de enero\n' > arbol/informes/informe-2024-01.txt
printf 'hola\n' > arbol/docs/notas.txt

echo
echo "Laboratorio listo en: $DESTINO"
echo
echo "Ahora entra en él con:"
echo "    cd $DESTINO"
echo "    ls"
