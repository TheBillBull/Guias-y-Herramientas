# Capítulo 11 · Los permisos en la vida real: el sistema, los comandos de cada día y los enlaces

> 🎯 **Objetivo:** reconocer **por qué** los ficheros y carpetas de un Linux real tienen los permisos que tienen (`/etc/shadow`, `/home`, `/tmp`, `/var/mail`…), saber **qué permisos pide cada comando** (`cp`, `mv`, `rm`, `ln`…), entender cómo los **editores** y `sed -i` "se saltan" el `w` del fichero, y qué pasa con los permisos de los **enlaces**.
>
> 📘 **LPIC-1:** 104.5 · **104.6** (enlaces duros y simbólicos) · 107.1 · 110.1.
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`.

---

## 11.1 · El mapa de permisos de un Ubuntu

Si ahora mismo ejecutas `ls -ld` sobre las carpetas y ficheros clave de **tu** sistema, verás esto (este es el de **nuestro** laboratorio, un Ubuntu 24.04 real):

```text
$ ls -ld / /etc /home /root /tmp /usr/bin /var /var/log /var/mail /var/tmp
drwxr-xr-x 22 root root  4096 Oct 16 15:58 /
drwxr-xr-x 81 root root  4096 Oct 16 17:08 /etc
drwxr-xr-x  9 root root  4096 Oct 16 17:08 /home
drwx------ 16 root root  4096 Oct 16 16:02 /root
drwxrwxrwt 14 root root  4096 Oct 16 17:08 /tmp
drwxr-xr-x  2 root root 24576 Oct  3 05:42 /usr/bin
drwxr-xr-x 11 root root  4096 Sep 17 02:29 /var
drwxr-xr-x  7 root root  4096 Oct  3 05:36 /var/log
drwxrwsr-x  2 root mail  4096 Sep 17 02:20 /var/mail
drwxrwxrwt  3 root root  4096 Oct 16 17:06 /var/tmp
```

Y los ficheros de cuentas y de configuración:

```text
$ ls -l /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/sudoers /etc/hosts /etc/fstab /etc/login.defs
-rw-r--r-- 1 root root      37 Sep 17 02:20 /etc/fstab
-rw-r--r-- 1 root root    1062 Oct 16 17:08 /etc/group
-rw-r----- 1 root shadow   933 Oct 16 17:08 /etc/gshadow
-rw-r--r-- 1 root root      49 Oct 16 15:58 /etc/hosts
-rw-r--r-- 1 root root   12345 Feb 22  2024 /etc/login.defs
-rw-r--r-- 1 root root    3558 Oct 16 17:08 /etc/passwd
-rw-r----- 1 root shadow  1485 Oct 16 17:08 /etc/shadow
-r--r----- 1 root root    1831 Oct  3 05:42 /etc/sudoers
```

Cada uno responde a una **idea de seguridad**. Esta es la tabla que debes llevar en la cabeza:

| Ruta | Permisos | Dueño:grupo | Por qué es así |
|---|---|---|---|
| `/` | `drwxr-xr-x` (755) | root:root | cualquiera puede **ver** la raíz, solo `root` la modifica |
| `/etc` | `drwxr-xr-x` | root:root | la configuración se **lee** (todos) pero solo la cambia `root` |
| `/root` | `drwx------` (700) | root:root | la carpeta personal de `root` es **privada** |
| `/home/usuario` | `drwxr-x---` (750) | usuario:usuario | cada usuario protege la suya (Ubuntu 22.04+ → `HOME_MODE 0750`) |
| `/tmp`, `/var/tmp` | `drwxrwxrwt` (**1777**) | root:root | todos escriben, cada uno **solo borra lo suyo** (sticky) |
| `/var/mail` | `drwxrwsr-x` (**2775**) | root:**mail** | buzones: lo creado **hereda el grupo `mail`** (SGID) |
| `/var/log` | `drwxr-xr-x` | root:root | los **registros** se guardan aquí; los ficheros de dentro suelen ser `640` (`syslog:adm`) |
| `/etc/passwd` | `-rw-r--r--` (644) | root:root | hay que **leerlo** (convertir UID en nombre) |
| `/etc/shadow` | `-rw-r-----` (**640**) | root:**shadow** | **contraseñas cifradas**: solo `root` y el grupo `shadow` |
| `/etc/group` | `-rw-r--r--` | root:root | igual que `passwd` |
| `/etc/gshadow` | `-rw-r-----` | root:shadow | contraseñas de grupos |
| `/etc/sudoers` | `-r--r-----` (**440**) | root:root | ¡solo lectura **incluso para root**! Se edita con `visudo` |
| `/usr/bin/passwd`, `/usr/bin/sudo`, `/bin/su` | `-rwsr-xr-x` (**4755**) | root:root | **SUID** para poder actuar como root (capítulo 10) |
| `/dev/null` | `crw-rw-rw-` | root:root | tirar datos: cualquiera |
| `~/.ssh/` | `drwx------` (700) | usuario | claves SSH: **privado** |
| `~/.ssh/id_ed25519` (clave **privada**) | `-rw-------` (**600**) | usuario | si está abierta, **`ssh` la rechaza** |

> 🧠 **Pauta general que se repite:** *lo que se puede consultar → lectura para todos (644/755); lo que contiene secretos → 600/640/700; lo que todos usan para escribir → sticky.*

---

## 11.2 · `/home`: ¿por qué `ana` no puede ver tu carpeta?

Desde Ubuntu 21.04 las carpetas personales se crean `750`; el valor sale de `HOME_MODE` en `/etc/login.defs`:

```text
$ grep -n HOME_MODE /etc/login.defs
153:# HOME_MODE is used by useradd(8) and newusers(8) to set the mode for new
155:# If HOME_MODE is not set, the value of UMASK is used to create the mode.
156:HOME_MODE	0750
$ ls -ld /home/ana /home/beto /home/carla
drwxr-x--- 2 ana   ana   4096 Oct 16 17:08 /home/ana
drwxr-x--- 2 beto  beto  4096 Oct 16 17:08 /home/beto
drwxr-x--- 2 carla carla 4096 Oct 16 17:08 /home/carla
$ sudo -u carla ls /home/ana
ls: cannot open directory '/home/ana': Permission denied
```

`carla` no puede ni **listar** la carpeta de `ana` (`---` para otros). (Tu propia carpeta aparece con `751` porque el script del laboratorio le añadió `o+x`, como vimos en el capítulo 3.)

---

## 11.3 · Una carpeta con SGID de verdad: `/var/mail`

`/var/mail` es `drwxrwsr-x root mail`. **Está en el sistema desde siempre**: el correo de cada usuario es un fichero ahí; el grupo `mail` lo **hereda** cada fichero nuevo gracias al SGID, y así el programa de correo (con ese grupo) puede escribir en todos los buzones sin ser `root`.

```text
$ ls -ld /var/mail
drwxrwsr-x 2 root mail 4096 Sep 17 02:20 /var/mail
$ find / -xdev -type d -perm -2000 -path '/var/*' 2>/dev/null | sort
/var/local
/var/log/journal
/var/log/redis
/var/mail
```

(Cuántos aparecen depende de lo que tengas instalado: `/var/mail`, `/var/local`, los logs del diario del sistema…)

---

## 11.4 · ¿Qué permisos necesita cada comando? La **tabla maestra**

Resumimos todo lo aprendido (capítulos 2 y 3) en **una sola tabla**. `F` = el fichero afectado, `D` = su carpeta, `D2` = la carpeta destino:

| Quiero… | Comando | Permiso en el **fichero** | Permiso en la **carpeta** |
|---|---|---|---|
| Ver un fichero | `cat F` | `r` | `x` en `D` |
| Editar el contenido | `echo x >> F` | `w` | `x` en `D` |
| Ejecutarlo | `./F` | `x` (+ `r` si es script) | `x` en `D` |
| **Copiar** | `cp F D2/G` | `r` en `F` | `x` en `D`; `w`+`x` en `D2` |
| **Mover/renombrar** (misma carpeta) | `mv F G` | *ninguno* | `w`+`x` en `D` |
| **Mover** a otra carpeta | `mv F D2/` | *ninguno* | `w`+`x` en **`D` y `D2`** |
| **Borrar** | `rm F` | *ninguno* | `w`+`x` en `D` (y *sticky* si lo hay) |
| **Crear** | `touch G` | — | `w`+`x` en `D` |
| Crear un **enlace duro** | `ln F L` | ser dueño, o `r`+`w` (protección) | `w`+`x` en la carpeta de `L` |
| Crear un **enlace simbólico** | `ln -s F L` | *ninguno* | `w`+`x` en la carpeta de `L` |
| **Listar** | `ls D` | — | `r` (y `x` para `ls -l`) |
| **Entrar** | `cd D` | — | `x` |
| **Cambiar permisos** | `chmod …` | **ser el dueño** | `x` en `D` |
| **Cambiar dueño** | `chown …` | **ser `root`** | `x` en `D` |

Tres experimentos que lo confirman:

**① `cp` necesita poder LEER el origen:**

```text
$ sudo -u ana cp datos/secreto.txt /tmp/lab-copia-ana.txt
cp: cannot open 'datos/secreto.txt' for reading: Permission denied
$ sudo -u ana cp datos/agenda.txt /tmp/lab-copia-ana.txt
$ ls -l /tmp/lab-copia-ana.txt
-rw-r--r-- 1 ana ana 56 Oct 16 17:08 /tmp/lab-copia-ana.txt
$ rm -f /tmp/lab-copia-ana.txt
rm: cannot remove '/tmp/lab-copia-ana.txt': Operation not permitted
$ sudo rm -f /tmp/lab-copia-ana.txt
```

`secreto.txt` (`600`) no se puede leer → `cp` falla antes de crear nada. `agenda.txt` (`644`) sí. Fíjate en dos cosas: la copia pasa a ser de **`ana`** (quien la creó), aunque el original sea tuyo; y **tú no puedes borrarla** de `/tmp` (`Operation not permitted`): `/tmp` tiene el bit *sticky* y el fichero es de `ana`. Por eso hemos tenido que usar `sudo` para limpiar.

**② `mv` y `rm` mandan por la carpeta, no por el fichero:**

```text
$ sudo touch fichero-de-root.txt
$ ls -l fichero-de-root.txt
-rw-r--r-- 1 root root 0 Oct 16 17:08 fichero-de-root.txt
$ mv fichero-de-root.txt renombrado.txt
$ rm -f renombrado.txt
$ ls fichero-de-root.txt renombrado.txt
ls: cannot access 'fichero-de-root.txt': No such file or directory
ls: cannot access 'renombrado.txt': No such file or directory
```

Un fichero que es de **`root`** (¡y que no puedes ni modificar!) **lo renombras y lo borras sin problema**, porque la **carpeta** es tuya.

**③ Para crear en una carpeta hace falta `w` y `x`:**

```text
$ mkdir solo-lectura
$ chmod 555 solo-lectura
$ sudo -u ana touch solo-lectura/x
touch: cannot touch 'solo-lectura/x': Permission denied
$ touch solo-lectura/x
touch: cannot touch 'solo-lectura/x': Permission denied
$ chmod 755 solo-lectura
```

Sin `w`, **ni siquiera tú** (el dueño) puedes crear dentro.

---

## 11.5 · ⚠️ El `w` del fichero **no** te protege de `sed -i` ni de los editores

Esta es una de las cosas que más desconcierta. Un fichero `r--r--r--` (solo lectura) en una carpeta tuya:

```text
$ echo "hola" > soloplantilla.txt
$ chmod 444 soloplantilla.txt
$ echo "añado" >> soloplantilla.txt
bash: soloplantilla.txt: Permission denied
$ sed -i 's/hola/adiós/' soloplantilla.txt
$ cat soloplantilla.txt
adiós
$ ls -l soloplantilla.txt
-r--r--r-- 1 alumno alumno 7 Oct 16 17:08 soloplantilla.txt
```

- `echo … >>` → **`Permission denied`** (abre el fichero para escribir, y no hay `w`).
- `sed -i` → **funciona**: no abre el fichero para escribir; **crea uno nuevo, lo rellena, y lo renombra** encima del viejo. Eso depende de la **carpeta** (tienes `w`+`x`), no del fichero.

Lo mismo hacen **`vim`** y otros editores al guardar (escriben un fichero nuevo y lo renombran). Consecuencias:

> 🎓 **Para proteger de verdad un fichero**, `chmod 444` **no basta** si la carpeta es escribible por quien no debe. Hay que proteger **la carpeta**, o usar el atributo inmutable (`chattr +i`, capítulo 12).

Y el *efecto colateral*: el fichero nuevo es **tuyo**, aunque el viejo fuera de otro. Lo vemos con uno de `root`:

```text
$ sudo cp datos/agenda.txt de-root.txt
$ ls -l de-root.txt
-rw-r--r-- 1 root root 56 Oct 16 17:08 de-root.txt
$ sed -i 's/lunes/martes/' de-root.txt
$ ls -l de-root.txt
-rw-r--r-- 1 alumno alumno 57 Oct 16 17:08 de-root.txt
$ cat de-root.txt
Reunión el martes a las 10:00
Llevar el informe impreso
```

Un fichero de `root` (`644`) en una carpeta **tuya** puede acabar **siendo tuyo** tras un `sed -i`. (No es un fallo de seguridad: **la carpeta es tuya**, tú decides qué hay en ella.)

---

## 11.6 · Enlaces duros y simbólicos: ¿y sus permisos?

(LPIC-1 **104.6**.) Dos clases de "acceso directo", con reglas distintas:

| | **Enlace duro** (`ln f l`) | **Enlace simbólico** (`ln -s f l`) |
|---|---|---|
| Qué es | **otro nombre** para el **mismo** fichero (mismo *inodo*) | un **fichero pequeño** que contiene la **ruta** de otro |
| Permisos propios | **los mismos** (son el mismo fichero) | `lrwxrwxrwx` siempre, **no cuentan** |
| ¿Qué permisos manda? | los del **único fichero** | los del **destino** |
| Si borras el original | el dato sigue (queda otro nombre) | el enlace queda **roto** |

### Enlaces duros: son **el mismo** fichero

```text
$ echo "contenido compartido" > original.txt
$ ln original.txt segundo-nombre.txt
$ chmod 600 segundo-nombre.txt
$ ls -li original.txt segundo-nombre.txt
599865 -rw------- 2 alumno alumno 21 Oct 16 17:08 original.txt
599865 -rw------- 2 alumno alumno 21 Oct 16 17:08 segundo-nombre.txt
```

Mismo **número de inodo** (primera columna), mismos permisos (`600`) y el **2** (número de enlaces). Cambiar permisos por un nombre los cambia por **el otro**: es un solo fichero con dos nombres.

### 🛡️ Protección de enlaces duros

Si cualquiera pudiera hacer un enlace duro a `/etc/passwd`, podría **conservar el fichero** aunque se "actualizase" o hacer trampas con SUID. Por eso Linux moderno tiene `fs.protected_hardlinks = 1`: solo puedes enlazar ficheros que **son tuyos** o que puedes **leer y escribir**:

```text
$ cat /proc/sys/fs/protected_hardlinks
1
$ ln /etc/passwd mi-passwd
ln: failed to create hard link 'mi-passwd' => '/etc/passwd': Operation not permitted
$ sudo -u ana ln datos/agenda.txt /tmp/lab-enlace-ana
ln: failed to create hard link '/tmp/lab-enlace-ana' => 'datos/agenda.txt': Operation not permitted
```

### Enlaces simbólicos: **mandan los permisos del destino**

```text
$ ln -s datos/secreto.txt enlace-secreto
$ ls -l enlace-secreto
lrwxrwxrwx 1 alumno alumno 17 Oct 16 17:08 enlace-secreto -> datos/secreto.txt
$ cat enlace-secreto
La contraseña del wifi es: patata-frita-42
$ sudo -u carla cat enlace-secreto
cat: enlace-secreto: Permission denied
$ ln -s no-existe.txt enlace-roto
$ cat enlace-roto
cat: enlace-roto: No such file or directory
```

- El enlace es `lrwxrwxrwx` (¡777!): **no significa nada**.
- `carla` no puede leer `enlace-secreto` porque **el destino** (`secreto.txt`, `600`) no se lo permite.
- `enlace-roto` apunta a algo que no existe: `No such file or directory`.

---

## 11.7 · Las claves SSH: el caso donde los permisos "se hacen valer" 🔑

`ssh` **se niega a usar** una clave privada que otros puedan leer. Estas son las medidas habituales:

| Fichero | Permisos | Si no… |
|---|:-:|---|
| `~/.ssh/` | `700` | `ssh` o `sshd` pueden ignorar el contenido |
| `~/.ssh/id_ed25519` (clave **privada**) | **`600`** | *"UNPROTECTED PRIVATE KEY FILE"* |
| `~/.ssh/id_ed25519.pub` (clave **pública**) | `644` | — |
| `~/.ssh/authorized_keys` | `600` (o `644`) | el servidor **rechaza** las claves |
| `~/.ssh/config` | `600` | `ssh` puede quejarse |

Si dejas una clave privada con `644` (legible por el grupo y los demás), esto es lo que ocurre al usarla (salida **típica**; no se ejecutó en el laboratorio de la guía porque no lleva cliente `ssh`):

```text
$ ls -l ~/.ssh/id_ed25519
-rw-r--r-- 1 alumno alumno 411 oct 16 12:00 /home/alumno/.ssh/id_ed25519
$ ssh servidor
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/alumno/.ssh/id_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
```

La solución: `chmod 600 ~/.ssh/id_ed25519` y `chmod 700 ~/.ssh`. Es una de las situaciones en las que **más veces** te toparás con permisos "en la vida real".

---

## 11.8 · Servicios y usuarios "de sistema"

Los **programas que corren solos** (servidor web, base de datos, cron…) **no usan tu usuario**: cada uno tiene el suyo, **sin contraseña ni shell**, para limitar el daño si lo atacan:

| Servicio | Usuario típico | Los ficheros que escribe |
|---|---|---|
| Apache / Nginx | `www-data` | `/var/www`, `/var/log/apache2` |
| MySQL / MariaDB | `mysql` | `/var/lib/mysql` (modo `700`) |
| Registros (`rsyslog`) | `syslog` (grupo `adm`) | `/var/log/syslog` (`640`) |

Si un servicio **no puede leer o escribir** algo, el síntoma es "Permission denied" en su **log**, y el remedio es **darle a ese usuario** (con `chown`/`chgrp`/SGID) lo que necesite, **no** hacer `chmod 777`.

---

## 11.9 · 🏋️ Ejercicios

#### 🟢 Ejercicio 11.1 · Por qué `/etc/shadow` es 640

¿Quién puede leer `/etc/shadow`? ¿Quién puede escribirlo?

<details>
<summary>💡 Ver solución</summary>

```text
$ ls -l /etc/shadow
-rw-r----- 1 root shadow 1485 Oct 16 17:08 /etc/shadow
$ sudo -u carla cat /etc/shadow
cat: /etc/shadow: Permission denied
```

Dueño `root` (`rw-`): lee y escribe. Grupo `shadow` (`r--`): lee. Otros: nada. `carla` → `Permission denied`.
</details>

#### 🟢 Ejercicio 11.2 · Tu `/home`

¿Quién puede listar tu carpeta personal? ¿Por qué `ana` no puede?

<details>
<summary>💡 Ver solución</summary>

```text
$ ls -ld ~
drwxr-x--x 3 alumno alumno 4096 Oct 16 17:08 /home/alumno
$ sudo -u ana ls ~
ls: cannot open directory '/home/alumno': Permission denied
```

Tu carpeta es `drwxr-x--x`: `ana` es "otros" con solo `--x` (puede **atravesarla**, no **listarla**).
</details>

#### 🟡 Ejercicio 11.3 · Un `cp` que falla

`ana` quiere copiar `datos/secreto.txt` a `/tmp`. ¿Falla en la **lectura** o en la **escritura**? ¿Qué mensaje da?

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo -u ana cp datos/secreto.txt /tmp/lab-no.txt
cp: cannot open 'datos/secreto.txt' for reading: Permission denied
```

Falla en la **lectura** del origen (`cannot open … for reading`). Si fallara el destino diría `cannot create regular file`.
</details>

#### 🟡 Ejercicio 11.4 · Renombrar un fichero ajeno

Renombra `fichero-de-root.txt` (de `root`, no modificable) a `tuyo.txt`. ¿Por qué se puede?

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo touch fichero-de-root.txt
$ mv fichero-de-root.txt tuyo.txt
$ ls -l tuyo.txt
-rw-r--r-- 1 root root 0 Oct 16 17:08 tuyo.txt
```

Renombrar es modificar **la carpeta** (que es tuya). Siguen siendo de `root`.
</details>

#### 🟡 Ejercicio 11.5 · El mismo fichero, dos nombres

Haz un enlace duro de `datos/notas.txt` llamado `notas-bis.txt`. ¿Cuántos enlaces tiene? Cambia los permisos de uno y mira el otro.

<details>
<summary>💡 Ver solución</summary>

```text
$ ln datos/notas.txt notas-bis.txt
$ ls -li datos/notas.txt notas-bis.txt
599861 -rw-r--r-- 2 alumno alumno 39 Oct 12 09:30 datos/notas.txt
599861 -rw-r--r-- 2 alumno alumno 39 Oct 12 09:30 notas-bis.txt
$ chmod 600 notas-bis.txt
$ ls -li datos/notas.txt notas-bis.txt
599861 -rw------- 2 alumno alumno 39 Oct 12 09:30 datos/notas.txt
599861 -rw------- 2 alumno alumno 39 Oct 12 09:30 notas-bis.txt
```

Mismo inodo, `2` enlaces, y el cambio de permisos se ve en **ambos** nombres.
</details>

#### 🟡 Ejercicio 11.6 · ¿Quién manda en un enlace simbólico?

Crea `acceso-notas` → `datos/secreto.txt`. ¿Quién puede leerlo a través del enlace?

<details>
<summary>💡 Ver solución</summary>

```text
$ ln -s datos/secreto.txt acceso-notas
$ ls -l acceso-notas
lrwxrwxrwx 1 alumno alumno 17 Oct 16 17:08 acceso-notas -> datos/secreto.txt
$ cat acceso-notas
La contraseña del wifi es: patata-frita-42
$ sudo -u ana cat acceso-notas
cat: acceso-notas: Permission denied
```

Solo el que puede leer **el destino** (`600`): tú. El `lrwxrwxrwx` del enlace es decorativo.
</details>

#### 🔴 Ejercicio 11.7 · `chmod 444` no basta

Tienes `config.txt` `444` en una carpeta tuya. Demuestra que alguien con `w` en la **carpeta** puede cambiarlo igualmente. ¿Cómo protegerías el fichero de verdad?

<details>
<summary>💡 Ver solución</summary>

```text
$ echo "valor=1" > config.txt
$ chmod 444 config.txt
$ sed -i 's/1/2/' config.txt
$ cat config.txt
valor=2
```

Se cambia porque `sed -i` **reemplaza** el fichero (permiso de la **carpeta**). Para protegerlo: quitar la `w` de la **carpeta** a quien no deba, o (`root`) `chattr +i config.txt` (capítulo 12).
</details>

#### 🔴 Ejercicio 11.8 · Hard link a un fichero ajeno

¿Puede `ana` hacer un enlace duro (`ln`) a `datos/secreto.txt`? ¿Y a un fichero legible por todos como `datos/agenda.txt`? (`protected_hardlinks`)

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo -u ana ln datos/secreto.txt /tmp/lab-h1
ln: failed to create hard link '/tmp/lab-h1' => 'datos/secreto.txt': Operation not permitted
$ sudo -u ana ln datos/agenda.txt /tmp/lab-h2
ln: failed to create hard link '/tmp/lab-h2' => 'datos/agenda.txt': Operation not permitted
```

Ambos fallan: con `protected_hardlinks=1` solo puedes enlazar lo que **posees** o puedes **leer y escribir** a la vez. `agenda.txt` es de lectura para `ana`, pero no escritura.
</details>

#### ⚫ Ejercicio 11.9 · Examen: `/etc/shadow`

*¿Qué permisos tiene normalmente `/etc/shadow`?* a) `-rw-r--r--` b) `-rw-r-----` c) `-rw-------` d) `-rwxr-xr-x`

<details>
<summary>💡 Ver solución</summary>

**b)** `640`, con dueño `root` y grupo `shadow` en Debian/Ubuntu (en otras distribuciones es `000` o `600`).
</details>

#### ⚫ Ejercicio 11.10 · Examen: `/tmp`

*¿Por qué los permisos de `/tmp` son `drwxrwxrwt`?* a) Para que cualquiera pueda crear ficheros, pero solo el dueño pueda borrar los suyos b) Para que se ejecute como root c) Para heredar el grupo d) Para cifrar los ficheros

<details>
<summary>💡 Ver solución</summary>

**a)** `rwx` para todos + bit **sticky** (`t`).
</details>

#### ⚫ Ejercicio 11.11 · Examen: enlace simbólico

*¿Qué permisos aparecen siempre en un enlace simbólico en `ls -l`?* a) `lrwxrwxrwx` b) los mismos del destino c) `lrw-r--r--` d) `l---------`

<details>
<summary>💡 Ver solución</summary>

**a) `lrwxrwxrwx`**, y no sirven para nada: mandan los del destino.
</details>

---

⬅️ [Capítulo 10 · Permisos especiales: SUID, SGID y *sticky* (`s`, `S`, `t`, `T`, `4755`, `2775`, `1777`)](10-permisos-especiales.md) · [📚 Índice](README.md) · [Capítulo 12 · Más allá de `rwx`: atributos, ACL, *capabilities* y montajes](12-mas-alla-de-rwx.md) ➡️
