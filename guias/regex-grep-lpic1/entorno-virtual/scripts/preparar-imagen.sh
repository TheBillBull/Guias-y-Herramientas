#!/bin/bash
# Se ejecuta UNA vez, como root, al construir la imagen.
# Deja el sistema con los mismos ficheros que usa el libro.
set -euo pipefail

S=/opt/lab/datos/sistema        # copia de ejemplo de /etc y /var/log
O=/opt/lab/datos/salidas        # salidas simuladas de ip, df, ps...

# ---------------------------------------------------------------- /etc ------
install -d -m 755 /etc/ssh /etc/default /etc/netplan
rm -f /etc/os-release                          # era un enlace a /usr/lib/os-release
for f in passwd group os-release fstab shells login.defs services crontab; do
    install -m 644 "$S/etc/$f" "/etc/$f"
done
install -m 644 "$S/etc/ssh/sshd_config"           /etc/ssh/sshd_config
install -m 644 "$S/etc/default/grub"              /etc/default/grub
install -m 644 "$S/etc/netplan/01-network.yaml"   /etc/netplan/01-network.yaml

# Las cuentas de arriba sustituyen a las del sistema base: se regeneran
# shadow/gshadow (contraseñas bloqueadas) y se borran las copias antiguas.
awk -F: '{printf "%s:*:19000:0:99999:7:::\n", $1}' /etc/passwd > /etc/shadow
awk -F: '{printf "%s:*::%s\n", $1, $4}'            /etc/group  > /etc/gshadow
chown root:shadow /etc/shadow /etc/gshadow
chmod 640 /etc/shadow /etc/gshadow
rm -f /etc/passwd- /etc/group- /etc/shadow- /etc/gshadow-
# plocate (setgid) necesita su grupo: el de /etc/group de ejemplo
chgrp plocate /usr/bin/plocate /var/lib/plocate /var/lib/plocate/plocate.db 2>/dev/null || true
chmod 2755 /usr/bin/plocate
pwck -r  >/dev/null || true
grpck -r >/dev/null || true

# El alumno puede usar sudo sin contraseña (es un laboratorio desechable)
echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/laboratorio
chmod 440 /etc/sudoers.d/laboratorio

# ------------------------------------------------------------ /home ---------
rm -rf /home/ubuntu
install -d -o 1000 -g 1000 -m 755 /home/alumno
cp /etc/skel/.bashrc /etc/skel/.profile /etc/skel/.bash_logout /home/alumno/ 2>/dev/null || true
chown -R 1000:1000 /home/alumno

# ------------------------------------------------------------ /var/log ------
find /var/log -mindepth 1 -delete
install -d -m 750 -o root -g 4 /var/log/apache2
for f in syslog auth.log kern.log ufw.log; do
    install -m 640 -o root -g 4 "$S/var/log/$f" "/var/log/$f"      # grupo 4 = adm
done
install -m 644 "$S/var/log/dpkg.log"   /var/log/dpkg.log
install -m 644 "$S/var/log/syslog-iso" /var/log/syslog-iso
install -m 640 -o root -g 4 "$S/var/log/apache2/access.log" /var/log/apache2/access.log
install -m 640 -o root -g 4 "$S/var/log/apache2/error.log"  /var/log/apache2/error.log

# ------------------------------------- comandos "del sistema" simulados -----
# Un contenedor no tiene la red, los discos ni el systemd de una máquina real.
# Estos scripts devuelven el texto de ejemplo del libro (SIMULAR=0 usa el real).
mk() {   # mk NOMBRE FICHERO
    cat > "/usr/local/bin/$1" <<EOF
#!/bin/sh
# Simulación para el libro. Con SIMULAR=0 se ejecuta el comando real.
if [ "\${SIMULAR:-1}" = 0 ]; then exec env PATH=/usr/sbin:/usr/bin:/sbin:/bin $1 "\$@"; fi
exec cat /opt/lab/datos/salidas/$2
EOF
    chmod 755 "/usr/local/bin/$1"
}
mk ip ip-a.txt;   mk df df-h.txt;   mk ps ps-aux.txt;    mk mount mount.txt
mk lsblk lsblk.txt; mk ss ss-tuln.txt; mk last last.txt; mk free free.txt; mk lscpu lscpu.txt

cat > /usr/local/bin/dmesg <<'EOF'
#!/bin/sh
# Simulación: los mensajes del kernel de ejemplo (SIMULAR=0 usa el real).
if [ "${SIMULAR:-1}" = 0 ]; then exec env PATH=/usr/sbin:/usr/bin:/sbin:/bin dmesg "$@"; fi
exec sed -E 's/^[A-Z][a-z]{2} +[0-9]+ [0-9:]+ [^ ]+ kernel: //' /var/log/kern.log
EOF
cat > /usr/local/bin/journalctl <<'EOF'
#!/bin/sh
# Simulación mínima de journalctl (no hay systemd en el contenedor):
#   journalctl            -> el syslog de ejemplo
#   journalctl -u X       -> solo las líneas que mencionan X
#   journalctl -p err     -> solo las líneas con error/failed
echo "-- Journal simulado a partir de /var/log/syslog --"
salida=$(cat /var/log/syslog)
while [ $# -gt 0 ]; do
    case "$1" in
        -u) salida=$(printf '%s\n' "$salida" | grep -F "$2"); shift ;;
        -p) salida=$(printf '%s\n' "$salida" | grep -iE 'error|failed|critical'); shift ;;
    esac
    shift
done
printf '%s\n' "$salida"
EOF
chmod 755 /usr/local/bin/dmesg /usr/local/bin/journalctl

# ---------------------- ficheros que Docker gestiona al arrancar (hosts...) --
install -d /opt/lab/vivos
install -m 644 "$S/etc/hosts" /opt/lab/vivos/hosts
cp /opt/lab/scripts/aplicar-ficheros-vivos /usr/local/sbin/aplicar-ficheros-vivos
cp /opt/lab/scripts/entrada-laboratorio     /usr/local/bin/entrada-laboratorio
cp /opt/lab/scripts/comprobar-entorno       /usr/local/bin/comprobar-entorno
chmod 755 /usr/local/sbin/aplicar-ficheros-vivos /usr/local/bin/entrada-laboratorio \
          /usr/local/bin/comprobar-entorno

# preparar-laboratorio disponible como comando (restablece ~/lab-regex)
cat > /usr/local/bin/preparar-laboratorio <<'EOF'
#!/bin/sh
# Restablece ~/lab-regex (o la carpeta que le indiques) como nuevo.
cd "$HOME" && exec bash /opt/lab/preparar-laboratorio.sh "$@"
EOF
chmod 755 /usr/local/bin/preparar-laboratorio
