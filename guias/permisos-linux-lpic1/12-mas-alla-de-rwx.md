# Capítulo 12 · Más allá de `rwx`: atributos, ACL, *capabilities* y montajes

> 🎯 **Objetivo:** saber que **`rwx` no es la única barrera**. Conocer los **atributos de fichero** (`chattr +i` te protege hasta de `root`), las **opciones de montaje** (`nosuid`, `noexec`, `ro`), las **capabilities** (el poder de `root` troceado), las **ACL** (permisos para usuarios concretos) y el **MAC** (AppArmor/SELinux). Y tener un **mapa mental** de todas las capas.
>
> 📘 **LPIC-1:** 104.5 y 110.1 (conceptos); algunas partes (ACL, *capabilities*) son **extra** y se profundizan en LPIC-2, pero **las encontrarás en la vida real**.
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`.

---

## 12.1 · Los límites de `rwx`

Los permisos de usuario/grupo/otros son simples y potentes, pero tienen huecos:

| Problema | Solución |
|---|---|
| *"Quiero que **proteger un fichero hasta de `root`** (o de un `rm -rf` accidental)"* | **atributos** (`chattr +i`) |
| *"Quiero dar acceso a **un usuario concreto** que no es dueño ni del grupo"* | **ACL** (`setfacl`) |
| *"Quiero que un programa tenga **solo una parte** del poder de `root`"* | **capabilities** (`setcap`) |
| *"Quiero que **esta partición** no pueda ejecutar programas ni SUID"* | **opciones de montaje** (`noexec`, `nosuid`) |
| *"Quiero confinar a un servicio aunque tenga `rwx`"* | **MAC**: AppArmor / SELinux |

---

## 12.2 · Atributos de fichero: `lsattr` y `chattr` 🔒

En los sistemas de ficheros **ext2/3/4** (y otros), cada fichero tiene, además de los permisos, unos **atributos** (banderas). Se ven con `lsattr` y se cambian con `chattr`:

```text
$ echo "contenido" > importante.txt
$ lsattr importante.txt
--------------e------- importante.txt
```

Los 20 caracteres son banderas; la `e` (*extents*) es normal en ext4. Las **que debes conocer**:

| Flag | Nombre | Efecto |
|:-:|---|---|
| **`i`** | **inmutable** | el fichero **no se puede modificar, borrar, renombrar, enlazar ni cambiar de permisos**, **ni por `root`** |
| **`a`** | **solo-añadir** (*append only*) | solo se puede **añadir** al final (`>>`); nunca sobrescribir ni borrar |
| `A` | sin actualizar `atime` | menos escrituras en disco |
| `d` | no volcar | `dump` lo ignora |
| `s` | borrado seguro | rellena de ceros al borrar (no siempre soportado) |
| `S` | síncrono | las escrituras van directas al disco |

> 🛑 Solo **`root`** puede poner o quitar `i` y `a` (necesita la capacidad `CAP_LINUX_IMMUTABLE`). Un usuario normal: `Operation not permitted`.

### ① Inmutable (`+i`): protegido hasta de `root`

```text
$ chattr +i importante.txt
chattr: Operation not permitted while setting flags on importante.txt
$ sudo chattr +i importante.txt
$ lsattr importante.txt
----i---------e------- importante.txt
$ echo "cambio" >> importante.txt
bash: importante.txt: Operation not permitted
$ rm -f importante.txt
rm: cannot remove 'importante.txt': Operation not permitted
$ mv importante.txt otro.txt
mv: cannot move 'importante.txt' to 'otro.txt': Operation not permitted
$ chmod 777 importante.txt
chmod: changing permissions of 'importante.txt': Operation not permitted
$ ln importante.txt enlace-duro.txt
ln: failed to create hard link 'enlace-duro.txt' => 'importante.txt': Operation not permitted
$ sudo rm -f importante.txt
rm: cannot remove 'importante.txt': Operation not permitted
$ sudo sh -c 'echo "root tampoco" >> importante.txt'
sh: 1: cannot create importante.txt: Operation not permitted
```

Ni escribir, ni borrar, ni renombrar, ni cambiar permisos, ni hacer un enlace duro… **ni siquiera `root`** hasta que quite el atributo:

```text
$ sudo chattr -i importante.txt
$ lsattr importante.txt
--------------e------- importante.txt
$ rm -f importante.txt
$ ls importante.txt
ls: cannot access 'importante.txt': No such file or directory
```

> 🎓 **Usos reales:** proteger `/etc/resolv.conf`, `/etc/passwd` en servidores críticos o ficheros que un malware tocaría. Y **¡cuidado!** también es una trampa: *"no puedo borrar este fichero ni siendo `root`"* → `lsattr` y busca la `i`.

### ② Solo-añadir (`+a`): ideal para registros

```text
$ echo "línea 1" > registro.log
$ sudo chattr +a registro.log
$ lsattr registro.log
-----a--------e------- registro.log
$ echo "línea 2" >> registro.log
$ echo "sobrescribir" > registro.log
bash: registro.log: Operation not permitted
$ rm -f registro.log
rm: cannot remove 'registro.log': Operation not permitted
$ cat registro.log
línea 1
línea 2
$ sudo chattr -a registro.log
```

Se puede **añadir** (`>>`), pero ni **sobrescribir** (`>`) ni **borrar**. Un atacante con acceso no puede "limpiar" las huellas del log.

---

## 12.3 · Opciones de montaje: la barrera de la partición

Los permisos de un fichero **no valen** si la **partición** donde vive está montada con restricciones. Se declaran al montarla (en `/etc/fstab`) y mandan **por encima** de los permisos:

| Opción | Efecto sobre **todo** lo que hay en esa partición |
|---|---|
| **`ro`** | solo lectura: nadie escribe (ni `root`) |
| **`noexec`** | **no se puede ejecutar** nada (aunque tenga `x`) |
| **`nosuid`** | **se ignoran** SUID y SGID (¡un `4755` deja de funcionar!) |
| **`nodev`** | se ignoran los ficheros de dispositivos (`b`, `c`) |
| `noatime` | no actualiza la fecha de acceso |

Se miran con `findmnt` o `mount`. Esto es lo que tiene el sistema de ficheros del laboratorio:

```text
$ findmnt -no OPTIONS / | tr ',' '\n'
rw
relatime
discard
no_prefetch_block_bitmaps
resv_strict
resuid=65534
resgid=65534
```

Una **partición `/tmp` endurecida** es típica de un servidor: `tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0` en `/etc/fstab`. Con eso, aunque alguien consiga subir un programa a `/tmp`, **no se podrá ejecutar**.

> 🎓 **Examen:** un SUID `4755` en una partición montada con `nosuid` **no tiene efecto**. Y una unidad USB con ficheros `x` pero montada `noexec` **no deja** ejecutarlos (el famoso *"Permission denied"* al lanzar un script de un pendrive: ¡no es culpa de `chmod`!).

---

## 12.4 · *Capabilities*: el poder de `root` en trocitos 🧩

Históricamente "ser `root`" era **todo o nada**. Linux lo trocea en unas **40 capacidades** (*capabilities*), como `CAP_NET_BIND_SERVICE` (usar puertos < 1024), `CAP_CHOWN` (cambiar dueños), `CAP_DAC_OVERRIDE` (saltarse los permisos de lectura/escritura/ejecución) o `CAP_LINUX_IMMUTABLE` (usar `chattr`). Un programa puede recibir **solo las que necesita**, en vez de ser SUID `root`:

```text
$ cp /usr/bin/cat micat
$ getcap micat
$ cat /etc/shadow
cat: /etc/shadow: Permission denied
$ ./micat /etc/shadow
./micat: /etc/shadow: Permission denied
```

(Las dos fallan adrede: ni `cat` ni nuestra copia `micat` pueden leer `/etc/shadow`, que es `root:shadow 640`; `getcap` no muestra nada: aún no tiene ninguna capacidad.) Ahora **damos una capacidad concreta** al *programa* `micat`:

```text
$ sudo setcap cap_dac_read_search+ep micat
$ getcap micat
micat cap_dac_read_search=ep
$ ./micat /etc/shadow | head -n 1 | cut -c1-5
root:
$ sudo setcap -r micat
$ getcap micat
$ ./micat /etc/shadow
./micat: /etc/shadow: Permission denied
```

Con `cap_dac_read_search` el programa puede **leer** cualquier fichero aunque no tenga `r` (aquí solo imprimimos `root:` de la primera línea para no mostrar contraseñas ajenas). Con `setcap -r` se la quitamos y vuelve el `Permission denied`.

> ⚠️ **Es potente y peligroso** (¡un `cat` con esa capacidad lee `/etc/shadow`!). Por eso **auditar** capacidades es tan importante como auditar SUID: `getcap -r / 2>/dev/null`. Un ejemplo típico y legítimo: `ping` tiene `cap_net_raw=ep` en lugar de ser SUID.
>
> En un `ls -l` **no** se ven las capacidades (no hay ninguna marca): hay que preguntar con `getcap`.

---

## 12.5 · ACL: permisos "a la carta" por usuario *(extra, no ejecutado en el laboratorio)*

> 📝 **Nota honesta:** en el entorno donde se generaron las salidas de esta guía **no estaban instaladas** las herramientas `getfacl`/`setfacl`, así que **esta sección no se ejecutó**. Los comandos y la salida son los **habituales**; compruébalos en tu máquina (`sudo apt install acl` si te falta el paquete). Las ACL **no** son parte del examen LPIC-1.

Con `rwx` solo hay **un** dueño y **un** grupo. Una **ACL** (*Access Control List*) permite añadir **más usuarios y grupos con permisos propios**:

```bash
$ touch informe.txt
$ setfacl -m u:ana:rw informe.txt        # a ana, lectura y escritura
$ setfacl -m g:soporte:r informe.txt     # al grupo soporte, solo lectura
$ getfacl informe.txt
# file: informe.txt
# owner: alumno
# group: alumno
user::rw-
user:ana:rw-
group::r--
group:soporte:r--
mask::rw-
other::r--

$ ls -l informe.txt
-rw-rw-r--+ 1 alumno alumno 0 oct 16 12:00 informe.txt
```

Fíjate en el **`+`** al final de los permisos: es la señal de que el fichero tiene ACL. Qué significa cada línea de `getfacl`:

| Línea | Significa |
|---|---|
| `user::rw-` | permisos del **dueño** |
| `user:ana:rw-` | permisos de **ana** (entrada extra) |
| `group::r--` | permisos del **grupo propietario** |
| `group:soporte:r--` | permisos del **grupo `soporte`** (entrada extra) |
| **`mask::rw-`** | el **máximo** que pueden tener las entradas extra y el grupo |
| `other::r--` | los demás |

La **máscara** es el truco: `chmod` sobre un fichero con ACL **cambia la máscara** (y por eso `ls -l` muestra la máscara donde antes estaba el grupo).

Los comandos esenciales:

| Quiero… | Comando |
|---|---|
| Ver la ACL | `getfacl fichero` |
| Dar permisos a un usuario | `setfacl -m u:ana:rw fichero` |
| Dar permisos a un grupo | `setfacl -m g:soporte:rx fichero` |
| Quitar la entrada de ana | `setfacl -x u:ana fichero` |
| **Quitar toda la ACL** | `setfacl -b fichero` |
| Recursivo | `setfacl -R -m u:ana:rX carpeta` |
| **ACL por defecto** (hereda lo que se cree dentro de una carpeta) | `setfacl -d -m g:equipo:rwx carpeta` |

> 💡 Las ACL **por defecto** hacen en una carpeta lo que el SGID + `umask` pero **mucho mejor**: puedes decidir qué permisos reciben automáticamente **todos** los ficheros nuevos, para **cada** usuario/grupo.

---

## 12.6 · MAC: AppArmor y SELinux (cuando `rwx` no basta)

Todo lo anterior es **DAC** (*Discretionary Access Control*): **el dueño decide**. Linux añade **MAC** (*Mandatory Access Control*): **una política del sistema** que se aplica **aunque `rwx` diga que sí**:

| | **AppArmor** | **SELinux** |
|---|---|---|
| Distribuciones | **Ubuntu**, Debian, openSUSE | RHEL, Fedora, CentOS, Rocky |
| Cómo funciona | **perfiles por programa** (qué rutas puede tocar) | **etiquetas** en cada fichero/proceso |
| Estado | `sudo aa-status` | `getenforce` / `sestatus` |
| Se nota en `ls -l` | no | con `ls -lZ` (y un `.` al final de los permisos) |
| Dónde mirar los bloqueos | `journalctl -k \| grep -i apparmor` | `ausearch -m avc` / `/var/log/audit/audit.log` |

> 🧠 **Si un servicio tiene `rwx` correcto y aun así falla con *"Permission denied"*, sospecha del MAC** (AppArmor/SELinux). Es la causa clásica de *"he puesto 777 y sigue sin ir"*. La solución **no** es abrir permisos: es ajustar la política.

---

## 12.7 · 🗺️ El mapa completo: todas las "puertas" por las que pasa un acceso

Cuando un programa intenta abrir un fichero, el kernel pasa por **varias comprobaciones**. Si **cualquiera** dice que no, `Permission denied`:

```text
   ┌─ 1. RUTA ───────────────── ¿hay "x" en TODAS las carpetas del camino?        (cap. 3)
   │
   ├─ 2. MONTAJE ────────────── ¿partición "ro", "noexec", "nosuid"?              (12.3)
   │
   ├─ 3. ATRIBUTOS ──────────── ¿"i" inmutable, "a" solo-añadir?                  (12.2)
   │
   ├─ 4. PERMISOS DAC ──────── dueño / grupo / otros (+ ACL)                      (cap. 4)
   │        └─ y los bits especiales SUID / SGID / sticky                         (cap. 10)
   │
   ├─ 5. CAPABILITIES ───────── ¿el proceso tiene CAP_DAC_OVERRIDE, etc.?         (12.4)
   │
   └─ 6. MAC ───────────────── ¿AppArmor / SELinux lo permite?                    (12.6)
```

Este mapa será tu **lista de comprobación** en el capítulo 13, cuando toque diagnosticar un *"Permission denied"*.

---

## 12.8 · 🏋️ Ejercicios

#### 🟢 Ejercicio 12.1 · El fichero que ni `root` puede borrar

Crea `sagrado.txt`, hazlo inmutable y demuestra que `root` no lo puede borrar. Después recupéralo.

<details>
<summary>💡 Ver solución</summary>

```text
$ echo "no tocar" > sagrado.txt
$ sudo chattr +i sagrado.txt
$ lsattr sagrado.txt
----i---------e------- sagrado.txt
$ sudo rm -f sagrado.txt
rm: cannot remove 'sagrado.txt': Operation not permitted
$ sudo chattr -i sagrado.txt
$ rm -f sagrado.txt
$ ls sagrado.txt
ls: cannot access 'sagrado.txt': No such file or directory
```
</details>

#### 🟢 Ejercicio 12.2 · ¿Qué atributos tiene?

¿Cómo ves los atributos de `datos/agenda.txt`? ¿Qué significa la `e`?

<details>
<summary>💡 Ver solución</summary>

```text
$ lsattr datos/agenda.txt
--------------e------- datos/agenda.txt
```

La **`e`** quiere decir que usa *extents* (la forma moderna de almacenar ficheros en ext4). Es normal.
</details>

#### 🟡 Ejercicio 12.3 · Un log a prueba de manipulaciones

Crea `auditoria.log` de modo que se pueda **añadir** pero **no sobrescribir ni borrar**. Pruébalo.

<details>
<summary>💡 Ver solución</summary>

```text
$ echo "inicio" > auditoria.log
$ sudo chattr +a auditoria.log
$ echo "evento 1" >> auditoria.log
$ echo "borrado" > auditoria.log
bash: auditoria.log: Operation not permitted
$ rm -f auditoria.log
rm: cannot remove 'auditoria.log': Operation not permitted
$ cat auditoria.log
inicio
evento 1
$ sudo chattr -a auditoria.log
```
</details>

#### 🟡 Ejercicio 12.4 · No me deja borrar un fichero... ¡siendo root!

Un compañero dice que `sudo rm fichero` da `Operation not permitted`. ¿Cuál es tu primer comando para investigar?

<details>
<summary>💡 Ver solución</summary>

**`lsattr fichero`**: seguro que tiene la `i` (inmutable) o la `a`. Se quita con `sudo chattr -i fichero`. (Otras causas: partición montada `ro`; el fichero es el **punto de montaje**; un fichero "en uso" no impide borrar en Linux.)
</details>

#### 🟡 Ejercicio 12.5 · Un USB que no ejecuta

Copias un script a un USB, le haces `chmod +x`, y al lanzarlo: `Permission denied`. ¿Por qué? ¿Cómo lo compruebas?

<details>
<summary>💡 Ver solución</summary>

El pendrive probablemente está montado con **`noexec`**. Se comprueba con `findmnt /media/tu-usb` o `mount | grep usb`. Soluciones: ejecutarlo con `bash script.sh` (el intérprete sí se ejecuta) o copiarlo a tu carpeta.
</details>

#### 🔴 Ejercicio 12.6 · Una capacidad sin SUID

Explica por qué dar `cap_net_bind_service` a un servidor web es **mejor** que hacerlo SUID `root`.

<details>
<summary>💡 Ver solución</summary>

Con SUID `root`, el servidor tiene **todo** el poder de `root` mientras se ejecuta: un fallo → el atacante es `root`. Con `cap_net_bind_service` solo puede **abrir puertos bajos** y nada más (*principio de mínimo privilegio*). (`sudo setcap cap_net_bind_service=+ep /usr/bin/miservidor`.)
</details>

#### 🔴 Ejercicio 12.7 · El SUID que no funciona en `/media`

Un programa SUID `root` copiado a `/media/usb` no da privilegios. ¿Por qué?

<details>
<summary>💡 Ver solución</summary>

Porque los medios extraíbles suelen montarse **`nosuid`**: el kernel ignora SUID/SGID de **todos** los ficheros de esa partición.
</details>

#### ⚫ Ejercicio 12.8 · Examen: `chattr`

*¿Qué comando impide que un fichero sea modificado o borrado, **incluso por `root`**?* a) `chmod 000 f` b) `chown root f` c) `chattr +i f` d) `chmod +t f`

<details>
<summary>💡 Ver solución</summary>

**c) `chattr +i f`** (atributo **i**nmutable). `chmod 000` no detiene a `root`.
</details>

#### ⚫ Ejercicio 12.9 · Examen: `+` al final

*En `-rw-rw-r--+`, ¿qué indica el `+`?* a) Tiene el sticky b) Tiene **ACL** c) Es un enlace d) Es ejecutable

<details>
<summary>💡 Ver solución</summary>

**b)**: el fichero tiene una **ACL** (lista de control de acceso). Se ve con `getfacl`.
</details>

#### ⚫ Ejercicio 12.10 · Examen: la `nosuid`

*Un fichero `-rwsr-xr-x` de `root` no da privilegios a quien lo ejecuta. ¿Una posible causa?* a) El grupo es incorrecto b) La partición está montada con `nosuid` c) Falta la `x` de otros d) Está en `/tmp`

<details>
<summary>💡 Ver solución</summary>

**b)**. (Y recuerda: si fuera un **script**, también se ignoraría; capítulo 10.)
</details>

---

⬅️ [Capítulo 11 · Los permisos en la vida real: el sistema, los comandos de cada día y los enlaces](11-permisos-en-la-vida-real.md) · [📚 Índice](README.md) · [Capítulo 13 · Diagnóstico: "¡Permission denied!" y qué hacer · Recetas](13-diagnostico-y-recetas.md) ➡️
