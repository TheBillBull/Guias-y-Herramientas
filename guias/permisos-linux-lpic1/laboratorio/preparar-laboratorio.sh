#!/usr/bin/env bash
# =============================================================================
#  preparar-laboratorio.sh  ·  Laboratorio de la guía "Permisos en Linux (LPIC-1)"
#
#  Qué hace (y SOLO esto):
#    1. Crea la carpeta  ~/lab-permisos  con unos ficheros de ejemplo.
#    2. Crea 3 usuarios de práctica (ana, beto, carla) y 2 grupos (equipo, soporte)
#       para poder probar "qué pasa cuando OTRA persona intenta leer mi fichero".
#       Esto necesita sudo (te pedirá tu contraseña).
#    3. Le da a tu carpeta personal el permiso "x" para los demás (chmod o+x ~),
#       porque en Ubuntu 24.04 tu carpeta personal es 750 y ana/beto/carla no
#       podrían ni entrar. (Lo explica el capítulo 3.)
#
#  Uso:
#    bash preparar-laboratorio.sh              crea el laboratorio completo
#    bash preparar-laboratorio.sh --sin-usuarios   solo la carpeta (sin sudo)
#    bash preparar-laboratorio.sh --solo-usuarios  solo los usuarios y grupos
#    bash preparar-laboratorio.sh --limpiar        BORRA todo lo que creó el script
#    bash preparar-laboratorio.sh --si             no pregunta antes de crear usuarios
#
#  Es seguro repetirlo: cada vez deja el laboratorio como nuevo.
#  Los usuarios que crea llevan en su "comentario" la marca "lab-permisos-lpic1";
#  --limpiar SOLO borra usuarios que tengan esa marca (nunca toca los tuyos).
# =============================================================================

set -u

LAB="${LAB_DIR:-$HOME/lab-permisos}"
MARCA="lab-permisos-lpic1"
USUARIOS=(ana beto carla)
GRUPOS=(equipo soporte)
FICHERO_MODO_HOME="$HOME/.lab-permisos-modo-home"

# Seguridad: nunca trabajamos sobre "/", sobre tu carpeta personal ni sobre una ruta vacía
case "$LAB" in
  ""|/|"$HOME"|"$HOME"/) echo "Ruta de laboratorio peligrosa ('$LAB'): me niego a seguir."; exit 1 ;;
esac

SUD=()
[ "$(id -u)" -eq 0 ] || SUD=(sudo)

OPCION_USUARIOS=1
OPCION_LAB=1
OPCION_LIMPIAR=0
PREGUNTAR=1

for arg in "$@"; do
  case "$arg" in
    --sin-usuarios)  OPCION_USUARIOS=0 ;;
    --solo-usuarios) OPCION_LAB=0 ;;
    --limpiar)       OPCION_LIMPIAR=1 ;;
    --si)            PREGUNTAR=0 ;;
    -h|--ayuda|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Opción desconocida: $arg (prueba --ayuda)"; exit 1 ;;
  esac
done

aviso() { printf '\033[1;33m%s\033[0m\n' "$*"; }

# ¿Es el grupo "nuestro"? Sí si NO existe, o si existe y TODOS sus miembros son usuarios de la guía
# (un grupo que ya tuvieras tú, vacío o con otras personas, no se toca nunca).
grupo_es_nuestro() {
  local g=$1 miembros m u ok
  getent group "$g" >/dev/null || return 0
  miembros=$(getent group "$g" | cut -d: -f4)
  [ -n "$miembros" ] || return 1
  IFS=',' read -ra arr <<<"$miembros"
  for m in "${arr[@]}"; do
    ok=0
    for u in "${USUARIOS[@]}"; do [ "$m" = "$u" ] && ok=1; done
    [ "$ok" -eq 1 ] || return 1
  done
  return 0
}
ok()    { printf '\033[1;32m✔\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- limpiar ----
limpiar() {
  echo "Limpiando el laboratorio…"
  if [ -e "$LAB" ]; then
    chmod -R u+rwX "$LAB" 2>/dev/null
    rm -rf "$LAB" 2>/dev/null || "${SUD[@]}" rm -rf "$LAB"
    ok "Borrada la carpeta $LAB"
  fi
  # (decidimos qué grupos son nuestros ANTES de borrar a sus miembros)
  borrar_grupos=()
  for g in "${GRUPOS[@]}"; do
    if getent group "$g" >/dev/null; then
      if grupo_es_nuestro "$g"; then borrar_grupos+=("$g"); else aviso "El grupo '$g' no es de la guía (tiene otros miembros o ya existía): no lo toco."; fi
    fi
  done
  for u in "${USUARIOS[@]}"; do
    if getent passwd "$u" >/dev/null && getent passwd "$u" | grep -q ":$MARCA"; then
      "${SUD[@]}" userdel -r "$u" 2>/dev/null
      ok "Borrado el usuario $u"
    fi
  done
  for g in "${borrar_grupos[@]}"; do
    "${SUD[@]}" groupdel "$g" 2>/dev/null && ok "Borrado el grupo $g"
  done
  if [ -f "$FICHERO_MODO_HOME" ]; then
    chmod "$(cat "$FICHERO_MODO_HOME")" "$HOME" && ok "Restaurado el permiso original de $HOME ($(cat "$FICHERO_MODO_HOME"))"
    rm -f "$FICHERO_MODO_HOME"
  fi
}

# --------------------------------------------------------------- usuarios ----
crear_usuarios() {
  if ! command -v sudo >/dev/null && [ "$(id -u)" -ne 0 ]; then
    aviso "No encuentro sudo: sin él no puedo crear los usuarios de práctica."
    return 1
  fi
  if [ "$PREGUNTAR" -eq 1 ]; then
    echo "Voy a crear (con sudo) los usuarios ana, beto y carla y los grupos equipo y soporte."
    echo "Se pueden borrar después con:  bash $0 --limpiar"
    read -r -p "¿Continuar? [s/N] " r
    case "$r" in s|S|si|SI|sí|Sí) ;; *) echo "Vale, no creo los usuarios."; return 1 ;; esac
  fi

  # 1) VALIDAR todo antes de tocar nada (así nunca queda un estado a medias)
  for g in "${GRUPOS[@]}"; do
    if ! grupo_es_nuestro "$g"; then
      aviso "Ya existe un grupo '$g' que NO es de la guía. No lo toco; sin él los ejercicios de grupos no funcionarán."
      return 1
    fi
  done
  for u in "${USUARIOS[@]}"; do
    if getent passwd "$u" >/dev/null && ! getent passwd "$u" | grep -q ":$MARCA"; then
      aviso "Ya existe un usuario '$u' que NO es del laboratorio. No lo toco, pero los ejercicios esperan otro 'ana/beto/carla'."
      return 1
    fi
  done

  # 2) CREAR
  for u in "${USUARIOS[@]}"; do
    getent passwd "$u" >/dev/null || "${SUD[@]}" useradd -m -s /bin/bash -c "$MARCA" "$u"
  done
  for g in "${GRUPOS[@]}"; do
    getent group "$g" >/dev/null || "${SUD[@]}" groupadd "$g"
  done
  "${SUD[@]}" usermod -aG equipo ana
  "${SUD[@]}" usermod -aG equipo beto
  "${SUD[@]}" usermod -aG soporte beto
  "${SUD[@]}" usermod -aG soporte carla
  ok "Usuarios: ana (equipo) · beto (equipo, soporte) · carla (soporte)"
}

# ------------------------------------------------------------ laboratorio ----
crear_lab() {
  if [ "$(id -u)" -eq 0 ]; then
    echo "No ejecutes la creación de ~/lab-permisos como root: hazlo con tu usuario normal."
    exit 1
  fi
  if [ -e "$LAB" ]; then
    chmod -R u+rwX "$LAB" 2>/dev/null
    rm -rf "$LAB" 2>/dev/null || { aviso "Hay ficheros de otros usuarios; uso sudo para borrarlos"; sudo rm -rf "$LAB"; }
  fi
  mkdir -p "$LAB/datos" && cd "$LAB" || exit 1

  # --- los tres scripts de la captura de pantalla (mismos permisos) ----------
  # (Los tres miden EXACTAMENTE 1015, 93 y 419 bytes, como en la captura.)
  cat > cerve.sh <<'EOF'
#!/bin/bash
# cerve.sh · el menú de la cervecería (script de prueba para practicar permisos)
#
# Cada línea que empieza por # es un comentario: bash la ignora.
# Este fichero necesita permiso de EJECUCIÓN (x) para poder lanzarlo con ./cerve.sh
# y permiso de LECTURA (r) para que bash pueda leer lo que hay dentro.

# Ojo: el menu es de broma; lo importante son los permisos, no la cerveza.
nombre=$(whoami)
dia=$(date +%A)

echo "=============================="
echo "  CERVECERÍA «EL PERMISO»"
echo "=============================="
echo "Bienvenido, $nombre. Hoy es $dia."
echo

case "$1" in
  rubia)  echo "Una rubia bien fría. ¡Salud!" ;;
  negra)  echo "Una negra cremosa. ¡Salud!" ;;
  tostada) echo "Una tostada de abadía. ¡Salud!" ;;
  sin)    echo "Una sin alcohol, que mañana hay clase." ;;
  *)      echo "Uso: ./cerve.sh rubia|negra|tostada|sin" ;;
esac

# Fin del script. Cuando termines de leerlo, prueba a quitarle el permiso x
# con:  chmod -x cerve.sh   y mira qué pasa al lanzarlo.
EOF
  cat > saludos.sh <<'EOF'
#!/bin/bash
# saludos.sh · dice hola y te cuenta quién eres, amigo.
echo "Hola, $(whoami)"
EOF
  cat > salario.sh <<'EOF'
#!/bin/bash
# salario.sh · calcula un sueldo anual (ficticio) con 14 pagas
# Uso:  ./salario.sh 1800     (si no das nada, usa 1800 al mes)

# Ojo: los numeros son inventados, aqui solo practicamos con chmod y umask
mensual=${1:-1800}
pagas=14

anual=$((mensual * pagas))
mes_neto=$((mensual * 80 / 100))

echo "Bruto mensual : $mensual euros"
echo "Bruto anual   : $anual euros"
echo "Neto aprox/mes: $mes_neto euros"
EOF
  chmod 775 cerve.sh;  touch -d '2026-10-09 16:16' cerve.sh
  chmod 751 saludos.sh; touch -d '2026-10-13 08:07' saludos.sh
  chmod 775 salario.sh; touch -d '2026-10-14 08:43' salario.sh

  # --- ficheros de datos con permisos variados -------------------------------
  printf 'Reunión el lunes a las 10:00\nLlevar el informe impreso\n' > datos/agenda.txt
  printf 'Cliente;Importe\nAcme;1200\nGlobex;860\n'                 > datos/ventas.csv
  printf 'La contraseña del wifi es: patata-frita-42\n'              > datos/secreto.txt
  printf 'Notas de clase: chmod, chown, umask…\n'                    > datos/notas.txt
  chmod 644 datos/agenda.txt datos/ventas.csv datos/notas.txt
  chmod 600 datos/secreto.txt
  touch -d '2026-10-12 09:30' datos/*.txt datos/ventas.csv

  # --- carpeta personal: que ana/beto/carla puedan "pasar" hasta el laboratorio
  modo_home=$(stat -c %a "$HOME")
  if [ "$(( 8#$modo_home & 8#001 ))" -eq 0 ]; then
    echo "$modo_home" > "$FICHERO_MODO_HOME"
    chmod o+x "$HOME"
    aviso "Tu carpeta personal era $modo_home; ahora es $(stat -c %a "$HOME") (los demás pueden atravesarla, no listarla). Se explica en el capítulo 3."
  fi
  ok "Laboratorio creado en $LAB"
}

# ------------------------------------------------------------------- main ----
if [ "$OPCION_LIMPIAR" -eq 1 ]; then limpiar; exit 0; fi
[ "$OPCION_USUARIOS" -eq 1 ] || [ "$OPCION_LAB" -eq 1 ] || exit 0

if [ "$OPCION_LAB" -eq 1 ];      then crear_lab; fi
if [ "$OPCION_USUARIOS" -eq 1 ]; then crear_usuarios || aviso "Seguimos sin usuarios de práctica (los capítulos que los usan te lo dirán)."; fi
echo
echo "Listo. Ahora:  cd ~/lab-permisos"
