# Capítulo 11 · Los logs: `syslog`, `auth.log`, `ufw.log`, `dpkg.log`, Apache…

> 🎯 **Objetivo:** convertirte en **detective de registros**. Los *logs* son el diario de tu máquina; aprenderás a encontrar errores, intentos de intrusión, paquetes instalados y peticiones web con un par de comandos.
>
> 📘 **LPIC-1:** 103.7 + 103.2 (filtros) + 108.2 (registros del sistema).
>
> 🧪 Estos ficheros viven en `/var/log`. En tu Ubuntu real algunos necesitan `sudo` o pertenecer al grupo `adm` para leerse, y su contenido será el de **tu** máquina. Para practicar con calma (y que te salga igual que en el libro) tienes copias de ejemplo en `~/lab-regex/sistema/var/log/`; los comandos del libro usan las rutas reales `/var/log/...`.

---

## 11.1 · ¿Qué es un log y dónde está?

Un **log** es un fichero de texto donde el sistema (y los programas) van **apuntando lo que pasa**, una línea por suceso. Todos viven en **`/var/log`**:

| Fichero | Qué contiene |
|---|---|
| `/var/log/syslog` | **Casi todo**: mensajes generales del sistema (menos los de autenticación) |
| `/var/log/auth.log` | **Autenticación**: `sshd`, `sudo`, `su`, altas de usuarios, `cron` (sesiones) |
| `/var/log/kern.log` | Mensajes del **kernel** (hardware, USB, discos, memoria…) |
| `/var/log/dpkg.log` | **Paquetes** instalados, actualizados o borrados (`dpkg`/`apt`) |
| `/var/log/ufw.log` | Paquetes bloqueados por el **cortafuegos** UFW |
| `/var/log/apache2/access.log` | **Peticiones web** (si hay servidor Apache) |
| `/var/log/apache2/error.log` | **Errores** de Apache |
| `/var/log/*.1`, `*.2.gz` | Logs **rotados** (antiguos): los `.gz` se leen con `zgrep` |

Además, `systemd` guarda un **diario binario** que se consulta con `journalctl` (no es texto, pero su salida sí se puede filtrar con `grep`):

```bash
journalctl -u ssh                 # mensajes del servicio ssh
journalctl -p err                 # solo errores (prioridad err o peor)
journalctl --since "1 hour ago"   # la última hora
journalctl | grep -i 'failed'     # ¡y grep como siempre!
```

*(Estos comandos no se muestran con salida: el diario de `systemd` es binario y depende de cada máquina.)*

> 🧠 **Para el examen:** `dmesg` muestra los mensajes del **kernel**; `last` los inicios de sesión; `lastb` los **fallidos** (requiere root).

### Anatomía de una línea de `syslog`

```text
Nov  5 10:17:01 ubuntu-pc CRON[7413]: (root) CMD (cd / && run-parts --report /etc/cron.hourly)
└─────┬───────┘ └───┬───┘ └──┬──────┘ └─────────────────────┬──────────────────────────────────┘
    fecha y hora   máquina  programa[PID]                   mensaje
```

⚠️ **Dos espacios** en `Nov  5`: cuando el día es de **una** cifra, el formato añade un espacio de relleno (`Nov  5`, pero `Nov 15`). Por eso hay que escribir `Nov  5` con dos espacios, o `Nov +5`, o `Nov [ 0-9][0-9]`… (¡trampa clásica!).

En Ubuntu **24.04**, el formato por defecto es otro, tipo ISO:

```bash
head -2 /var/log/syslog-iso | cut -c1-90
```

_Resultado:_

```text
2024-11-05T07:17:01.891470+01:00 ubuntu-pc CRON[4616]: (root) CMD (cd / && run-parts --rep
2024-11-05T07:45:15.234080+01:00 ubuntu-pc NetworkManager[655]: <info>  [1730790315.4411] 
```


Ahí la fecha es `2024-11-05T07:17:01.851948+01:00`, sin el relleno raro. Eso simplifica las regex: `^[0-9]{4}-[0-9]{2}-[0-9]{2}T`.

---

## 11.2 · Recetas básicas de detective

### Contar eventos por hora

```bash
grep -oE '^Nov  5 [0-9]{2}' /var/log/syslog | sort | uniq -c | head -6
```

_Resultado:_

```text
      1 Nov  5 00
      1 Nov  5 01
      3 Nov  5 02
      1 Nov  5 03
      1 Nov  5 04
      1 Nov  5 05
```


`grep -o` extrae "Nov  5 HH", `sort | uniq -c` cuenta cuántas veces sale cada una.

### El patrón "extraer → ordenar → contar → ranking"

Es **la tubería más importante** del análisis de logs:

```text
grep -o 'LO-QUE-QUIERO-CONTAR'  |  sort  |  uniq -c  |  sort -rn
  └ extrae solo el dato          └ ordena └ cuenta     └ ranking (más repetido primero)
```

Ejemplo: **¿qué usuarios inválidos han intentado entrar por SSH?**

```bash
grep -oE 'Invalid user [^ ]+' /var/log/auth.log | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      1 Invalid user test
      1 Invalid user oracle
      1 Invalid user guest
      1 Invalid user admin
```


### Detectar fuerza bruta: IPs con 3 o más fallos

Sacamos las IPs de los intentos fallidos, las contamos y filtramos con **otra regex** sobre la salida de `uniq -c` (que empieza con espacios, el número, un espacio y el dato):

```bash
grep 'Failed password' /var/log/auth.log | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | grep -E '^ *([3-9]|[0-9]{2,}) '
```

_Resultado:_

```text
      3 198.51.100.23
      5 203.0.113.45
      3 203.0.113.99
```


`^ *([3-9]|[0-9]{2,}) ` = "espacios, un número de **3 a 9** o de **dos o más cifras** (o sea, ≥ 3) y un espacio". Aparecen las 3 IPs que merecen vigilancia.

---

## 11.3 · 🏋️ Ejercicios: `syslog` y `kern.log`

#### 🟢 Ejercicio 11.1 · ¿Cuántos eventos el día 5?

Cuenta las líneas de `/var/log/syslog` del **5 de noviembre** (`Nov  5`, con dos espacios).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '^Nov  5' /var/log/syslog
```

_Resultado:_

```text
63
```


Con dos espacios literales. (Otra forma que no depende de cuántos espacios haya: `'^Nov  *5 '`, esto es, "Nov, uno o más espacios, 5".)
</details>


#### 🟢 Ejercicio 11.2 · Los días que aparecen

Averigua qué **días** aparecen en `syslog`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^Nov +[0-9]+' /var/log/syslog | sort -u
```

_Resultado:_

```text
Nov  4
Nov  5
Nov  6
```


`Nov +[0-9]+` admite uno o más espacios (sirve igual con `Nov  5` que con `Nov 15`). `sort -u` quita repetidos.
</details>


#### 🟢 Ejercicio 11.3 · Servicios arrancados

Cuenta cuántos servicios se han **arrancado** (`Started`) según `syslog`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'Started' /var/log/syslog
```

_Resultado:_

```text
20
```

</details>


#### 🟢 Ejercicio 11.4 · Servicios que han fallado

Muestra (acortadas) las líneas de `syslog` que indican que **algo ha fallado** (`Failed` o `failed`), sin importar mayúsculas. ¡Ojo con los falsos positivos!

<details>
<summary>💡 Ver solución</summary>


```bash
grep -i 'failed' /var/log/syslog | cut -c1-110
```

_Resultado:_

```text
Nov  4 14:45:22 ubuntu-pc systemd[1]: apache2.service: Failed with result 'exit-code'.
Nov  4 14:45:22 ubuntu-pc systemd[1]: Failed to start apache2.service - The Apache HTTP Server.
Nov  5 13:26:20 ubuntu-pc systemd[1]: Started update-notifier-download.service - Download data for packages th
Nov  5 16:20:49 ubuntu-pc systemd[1]: Started update-notifier-download.service - Download data for packages th
Nov  5 22:13:41 ubuntu-pc systemd[1]: postgresql@16-main.service: Failed with result 'timeout'.
Nov  5 22:13:41 ubuntu-pc systemd[1]: Failed to start postgresql@16-main.service - PostgreSQL Cluster 16-main.
```


`-i` cubre `Failed`, `failed` y `FAILED`. Pero mira las dos líneas de `update-notifier-download.service`: dicen *"Started …Download data for packages that **failed** at package install time"*. ¡No es un fallo! Es la **descripción** del servicio, que contiene la palabra `failed`. Es un falso positivo clásico. Si lo que quieres son los fallos de verdad, afina con el contexto:

```bash
grep -E 'Failed (to|with)' /var/log/syslog | cut -c1-110
```

_Resultado:_

```text
Nov  4 14:45:22 ubuntu-pc systemd[1]: apache2.service: Failed with result 'exit-code'.
Nov  4 14:45:22 ubuntu-pc systemd[1]: Failed to start apache2.service - The Apache HTTP Server.
Nov  5 22:13:41 ubuntu-pc systemd[1]: postgresql@16-main.service: Failed with result 'timeout'.
Nov  5 22:13:41 ubuntu-pc systemd[1]: Failed to start postgresql@16-main.service - PostgreSQL Cluster 16-main.
```


`Failed (to|with)` exige que tras `Failed` venga `to` (*Failed to start…*) o `with` (*Failed with result…*). Moraleja: **comprueba siempre lo que te devuelve el filtro**.
</details>


#### 🟢 Ejercicio 11.5 · Un corchete literal

Muestra las líneas de `syslog` del proceso `systemd` con su PID entre corchetes (`systemd[1]:`). Cuenta cuántas son.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'systemd\[1\]:' /var/log/syslog
```

_Resultado:_

```text
46
```


Los corchetes hay que **escaparlos** (`\[` y `\]`); si no, `[1]` sería "un carácter que sea 1".
</details>


#### 🟢 Ejercicio 11.6 · El cron de cada hora

Muestra, acortadas, las líneas de `CRON` que lanzan `cron.hourly`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'CRON.*cron\.hourly' /var/log/syslog | cut -c1-80 | head -5
```

_Resultado:_

```text
Nov  5 00:17:01 ubuntu-pc CRON[8301]: (root) CMD (cd / && run-parts --report /et
Nov  5 01:17:01 ubuntu-pc CRON[3577]: (root) CMD (cd / && run-parts --report /et
Nov  5 02:17:01 ubuntu-pc CRON[5576]: (root) CMD (cd / && run-parts --report /et
Nov  5 03:17:01 ubuntu-pc CRON[3880]: (root) CMD (cd / && run-parts --report /et
Nov  5 04:17:01 ubuntu-pc CRON[7318]: (root) CMD (cd / && run-parts --report /et
```


`CRON.*cron\.hourly`: `CRON`, lo que sea, y `cron.hourly` (con el punto escapado).
</details>


#### 🟢 Ejercicio 11.7 · Hardware USB

Muestra las líneas del **kernel** relacionadas con USB (sin importar mayúsculas) en `kern.log`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -i usb /var/log/kern.log | cut -c1-100
```

_Resultado:_

```text
Nov  4 08:55:04 ubuntu-pc kernel: [  4.007800] usb 1-1: new high-speed USB device number 2 using ehc
Nov  4 08:55:04 ubuntu-pc kernel: [  4.009100] usb 1-1: New USB device found, idVendor=0781, idProdu
Nov  4 08:55:04 ubuntu-pc kernel: [  4.010400] usb 1-1: Product: Cruzer Blade
Nov  4 10:15:44 ubuntu-pc kernel: [4844.015600] usb 1-1: USB disconnect, device number 2
Nov  5 09:35:48 ubuntu-pc kernel: [88848.019500] usb 1-1: new high-speed USB device number 3 using e
Nov  5 09:35:48 ubuntu-pc kernel: [88848.020800] usb 1-1: Product: Cruzer Blade
```

</details>


#### 🟢 Ejercicio 11.8 · Sin memoria

Busca los avisos de **falta de memoria** del kernel y muestra qué proceso fue "matado".

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'Killed process [0-9]+ \([^)]+\)' /var/log/syslog
```

_Resultado:_

```text
Killed process 2345 (java)
```


`Killed process 2345 (java)`: `[0-9]+` el PID, y `\([^)]+\)` el nombre entre paréntesis literales (`\(` `\)`), con `[^)]+` = "lo que no sea `)`".
</details>


#### 🟡 Ejercicio 11.9 · Errores de disco

Muestra (acortadas) las líneas de `kern.log` que indican errores de entrada/salida o del sistema de ficheros: `I/O error` o `EXT4-fs error`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'I/O error|EXT4-fs error' /var/log/kern.log | cut -c1-110
```

_Resultado:_

```text
Nov  5 11:40:02 ubuntu-pc kernel: [96302.024700] EXT4-fs error (device sdb1): ext4_find_entry:1455: inode #2: 
Nov  5 11:40:02 ubuntu-pc kernel: [96302.026000] blk_update_request: I/O error, dev sdb, sector 2048 op 0x0:(R
```

</details>


#### 🟡 Ejercicio 11.10 · Procesos que se cuelgan

Extrae `proceso[PID]` de los mensajes `segfault` (fallos de segmentación) del kernel.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '[a-z0-9]+\[[0-9]+\]: segfault' /var/log/syslog
```

_Resultado:_

```text
python3[3321]: segfault
```

</details>


#### 🟡 Ejercicio 11.11 · Direcciones que repartió el DHCP

Extrae **solo las direcciones IPv4 asignadas** por DHCP a `enp0s3` (las que aparecen tras `address`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'address[= ][0-9.]+' /var/log/syslog
```

_Resultado:_

```text
address 192.168.1.37
address=192.168.1.37
address=192.168.1.38
```


`[= ]` = un `=` o un espacio (hay dos formatos de mensaje). `[0-9.]+` = dígitos y puntos (el punto dentro del corchete es literal).
</details>


#### 🟡 Ejercicio 11.12 · Dos horas concretas

Muestra las líneas de `syslog` del día 4 entre las **13:00 y las 14:59**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^Nov  4 1[34]:' /var/log/syslog | cut -c1-80
```

_Resultado:_

```text
Nov  4 14:45:21 ubuntu-pc systemd[1]: Starting apache2.service - The Apache HTTP
Nov  4 14:45:22 ubuntu-pc apachectl[3144]: AH00526: Syntax error on line 12 of /
Nov  4 14:45:22 ubuntu-pc systemd[1]: apache2.service: Control process exited, c
Nov  4 14:45:22 ubuntu-pc systemd[1]: apache2.service: Failed with result 'exit-
Nov  4 14:45:22 ubuntu-pc systemd[1]: Failed to start apache2.service - The Apac
Nov  4 14:58:03 ubuntu-pc systemd[1]: Starting apache2.service - The Apache HTTP
Nov  4 14:58:03 ubuntu-pc systemd[1]: Started apache2.service - The Apache HTTP 
```


`1[34]` = 13 o 14.
</details>


#### 🟡 Ejercicio 11.13 · La última hora del día

Cuenta las líneas del **día 4** entre las 23:00 y las 23:59.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '^Nov  4 23:' /var/log/syslog
```

_Resultado:_

```text
2
```

</details>


#### 🟡 Ejercicio 11.14 · Quién genera más mensajes

Muestra el **ranking de programas** que más escriben en `syslog` (el programa es la palabra tras el nombre de la máquina `ubuntu-pc`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'ubuntu-pc [^ :[]+' /var/log/syslog | cut -d' ' -f2 | sort | uniq -c | sort -rn | head -6
```

_Resultado:_

```text
     46 systemd
     28 CRON
     25 kernel
      8 systemd-logind
      8 NetworkManager
      2 rsyslogd
```


`ubuntu-pc [^ :[]+` extrae "ubuntu-pc" y el nombre del programa (todo lo que no sea espacio, `:` ni `[`); `cut -d' ' -f2` se queda con el nombre; luego ranking.
</details>


#### 🔴 Ejercicio 11.15 · Los eventos en el formato ISO

En `syslog-iso` (formato Ubuntu 24.04), muestra **solo la fecha y hora** (sin microsegundos ni zona) de cada línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^[0-9]{4}(-[0-9]{2}){2}T[0-9:]{8}' /var/log/syslog-iso | head -5
```

_Resultado:_

```text
2024-11-05T07:17:01
2024-11-05T07:45:15
2024-11-05T08:17:01
2024-11-05T08:30:12
2024-11-05T08:30:12
```


`[0-9]{4}(-[0-9]{2}){2}` = año y dos grupos "-dd"; `T`; `[0-9:]{8}` = 8 caracteres entre dígitos y `:` (la hora).
</details>


#### 🔴 Ejercicio 11.16 · Entre dos horas, formato ISO

En `syslog-iso`, cuenta las líneas entre las **08:00 y las 09:59**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^[0-9-]{10}T0[89]:' /var/log/syslog-iso
```

_Resultado:_

```text
6
```


`[0-9-]{10}` = los 10 caracteres de la fecha (dígitos y guiones). `T0[89]:` = hora 08 o 09.
</details>


---

## 11.4 · 🏋️ Ejercicios: `auth.log`

#### 🟢 Ejercicio 11.17 · Entradas aceptadas

Cuenta cuántos inicios de sesión **aceptados** por SSH hay (`Accepted`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'sshd.*Accepted' /var/log/auth.log
```

_Resultado:_

```text
5
```

</details>


#### 🟢 Ejercicio 11.18 · ¿Quién ha entrado?

Muestra, con el recuento, **qué usuarios** han iniciado sesión con éxito por SSH.

<details>
<summary>💡 Ver solución</summary>


```bash
grep Accepted /var/log/auth.log | grep -oE 'for [a-z]+' | sort | uniq -c
```

_Resultado:_

```text
      2 for alumno
      1 for ana
      2 for luis
```


`for [a-z]+` extrae "for alumno", "for luis"… (segunda búsqueda sobre las líneas ya filtradas).
</details>


#### 🟢 Ejercicio 11.19 · Contraseñas fallidas

Cuenta cuántos intentos de contraseña **fallidos** hay.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'Failed password' /var/log/auth.log
```

_Resultado:_

```text
12
```

</details>


#### 🟢 Ejercicio 11.20 · Usuarios inexistentes

Muestra los **nombres de usuario inexistentes** que han probado (los de `Invalid user NOMBRE`), con recuento.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'Invalid user [^ ]+' /var/log/auth.log | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      1 Invalid user test
      1 Invalid user oracle
      1 Invalid user guest
      1 Invalid user admin
```

</details>


#### 🟢 Ejercicio 11.21 · Los comandos de sudo

Muestra **solo el comando** que se ejecutó con `sudo` cada vez (desde `COMMAND=`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'COMMAND=.*' /var/log/auth.log
```

_Resultado:_

```text
COMMAND=/usr/bin/apt update
COMMAND=/usr/bin/apt install -y nano vim curl git
COMMAND=/usr/bin/systemctl restart ssh
COMMAND=/usr/bin/cat /etc/shadow
COMMAND=/usr/sbin/useradd -m -s /bin/bash pedro
```

</details>


#### 🟢 Ejercicio 11.22 · Intentos de sudo no autorizados

Muestra (acortadas) las líneas de `sudo` que indiquen que **un usuario no está autorizado** o falló la autenticación.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'sudo: .*(NOT in sudoers|authentication failure)' /var/log/auth.log | cut -c1-100
```

_Resultado:_

```text
Nov  5 10:02:44 ubuntu-pc sudo: pam_unix(sudo:auth): authentication failure; logname=luis uid=1002 e
Nov  5 10:02:50 ubuntu-pc sudo: luis : user NOT in sudoers ; TTY=pts/1 ; PWD=/home/luis ; USER=root 
```


La alternativa agrupada se aplica **después** de `sudo: .*`.
</details>


#### 🟢 Ejercicio 11.23 · Altas de usuarios y grupos

Muestra **solo los textos** `new user: name=…` y `new group: name=…`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'new (user|group): name=[^,]+' /var/log/auth.log
```

_Resultado:_

```text
new group: name=invitado
new user: name=invitado
new group: name=pedro
new user: name=pedro
```


`new (user|group)` + `: name=` + `[^,]+` (hasta la coma). Se ve cuándo se crearon `invitado` y `pedro`.
</details>


#### 🟡 Ejercicio 11.24 · Los ataques desde fuera

Muestra las IPs de **contraseñas fallidas**, **excluyendo** las de la red interna (`192.168.…`), con su recuento.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'Failed password' /var/log/auth.log | grep -v '192\.168\.' | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      5 203.0.113.45
      3 203.0.113.99
      3 198.51.100.23
```


Primero se seleccionan los fallos, `-v '192\.168\.'` descarta los internos y el último `grep -o` extrae las IPs. (Con `-P` habría formas más cortas; capítulo 13.)
</details>


#### 🟡 Ejercicio 11.25 · Fuerza bruta: 3 o más intentos

Muestra solo las IPs con **3 o más** contraseñas fallidas, y cuántas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'Failed password' /var/log/auth.log | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | grep -E '^ *([3-9]|[0-9]{2,}) '
```

_Resultado:_

```text
      3 198.51.100.23
      5 203.0.113.45
      3 203.0.113.99
```


El último filtro mira la **cuenta** de `uniq -c`: ` 5 203.0.113.45`. `([3-9]|[0-9]{2,})` = ≥ 3.
</details>


#### 🟡 Ejercicio 11.26 · Contraseña o clave pública

Cuenta los accesos aceptados **por contraseña** y los **por clave pública**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'Accepted password' /var/log/auth.log
grep -c 'Accepted publickey' /var/log/auth.log
```

_Resultado:_

```text
3
2
```

</details>


#### 🟡 Ejercicio 11.27 · Intentos contra `root`

Muestra los intentos fallidos contra la cuenta `root` (en las dos formas: contra `root`, no contra "invalid user root").

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'Failed password for root ' /var/log/auth.log | cut -c1-100
```

_Resultado:_

```text
Nov  4 14:02:11 ubuntu-pc sshd[3805]: Failed password for root from 198.51.100.23 port 51234 ssh2
Nov  4 14:02:14 ubuntu-pc sshd[5256]: Failed password for root from 198.51.100.23 port 51234 ssh2
```


El espacio final evita coger `rootfs` o similares. Compara con `Failed password for invalid user …`.
</details>


#### 🟡 Ejercicio 11.28 · Puertos de origen

Muestra, para las IPs `203.0.113.45`, **los puertos de origen** usados (`port NNNNN`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '203\.0\.113\.45' /var/log/auth.log | grep -oE 'port [0-9]+' | sort | uniq -c
```

_Resultado:_

```text
      5 port 40022
      3 port 41333
      2 port 42001
```

</details>


#### 🟡 Ejercicio 11.29 · Sesiones de root abiertas por alguien

Muestra las líneas donde se **abrió una sesión de `root`** desde un usuario normal (`session opened for user root … by alumno`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'session opened for user root.*by [a-z]+\(' /var/log/auth.log | cut -c1-100
```

_Resultado:_

```text
Nov  4 09:05:21 ubuntu-pc sudo: pam_unix(sudo:session): session opened for user root(uid=0) by alumn
Nov  4 09:12:00 ubuntu-pc sudo: pam_unix(sudo:session): session opened for user root(uid=0) by alumn
Nov  5 08:41:19 ubuntu-pc sudo: pam_unix(sudo:session): session opened for user root(uid=0) by alumn
Nov  5 18:30:00 ubuntu-pc su[3555]: pam_unix(su:session): session opened for user root(uid=0) by alu
```

</details>


#### 🟡 Ejercicio 11.30 · Las IP de un mismo bloque

Cuenta las líneas de `auth.log` que mencionan **cualquier IP del bloque `198.51.100.x`**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '198\.51\.100\.[0-9]{1,3}' /var/log/auth.log
```

_Resultado:_

```text
6
```

</details>


#### 🔴 Ejercicio 11.31 · Quién ha fallado y quién ha entrado después

Muestra los usuarios (**con cuenta real**) que **fallaron** una vez y después **entraron bien**: busca `Failed password for luis` y `Accepted password for luis`. Muéstralas seguidas con `-n`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -nE '(Failed|Accepted) password for luis ' /var/log/auth.log | cut -c1-90
```

_Resultado:_

```text
39:Nov  5 10:55:31 ubuntu-pc sshd[9180]: Accepted password for luis from 192.168.1.51 port
41:Nov  5 11:10:03 ubuntu-pc sshd[7743]: Failed password for luis from 192.168.1.51 port 4
42:Nov  5 11:10:07 ubuntu-pc sshd[7397]: Accepted password for luis from 192.168.1.51 port
```


La alternativa `(Failed|Accepted)` ordena las dos en la misma búsqueda; `-n` te deja ver el orden.
</details>


#### 🔴 Ejercicio 11.32 · Usuarios con sesión de SSH

Lista los **usuarios únicos** que abrieron una sesión SSH (`pam_unix(sshd:session): session opened for user NOMBRE`), sin repeticiones.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'sshd:session\): session opened for user [a-z]+' /var/log/auth.log | grep -oE '[a-z]+$' | sort -u
```

_Resultado:_

```text
alumno
ana
luis
```


El primer `grep -o` aísla la frase y el segundo `[a-z]+$` se queda con el último "palabra" (el usuario).
</details>


---

## 11.5 · 🏋️ Ejercicios: `ufw.log` (el cortafuegos)

Una línea de `ufw.log` tiene muchos campos `CLAVE=valor`:

```text
... [UFW BLOCK] IN=enp0s3 OUT= MAC=08:00:27:... SRC=203.0.113.45 DST=192.168.1.37 LEN=60 ... PROTO=TCP SPT=40022 DPT=22 ...
```

`SRC` = IP de origen, `DST` = destino, `SPT` = puerto de origen, `DPT` = **puerto de destino** (el que intentaban atacar).

#### 🟢 Ejercicio 11.33 · Los orígenes

Muestra el **ranking de IPs de origen** bloqueadas por el cortafuegos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'SRC=[0-9.]+' /var/log/ufw.log | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      8 SRC=45.33.32.156
      8 SRC=203.0.113.99
      7 SRC=198.51.100.23
      5 SRC=203.0.113.45
      4 SRC=192.0.2.77
```

</details>


#### 🟢 Ejercicio 11.34 · Los puertos atacados

Muestra el **ranking de puertos de destino** atacados.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'DPT=[0-9]+' /var/log/ufw.log | sort | uniq -c | sort -rn | head -5
```

_Resultado:_

```text
     13 DPT=22
      5 DPT=23
      3 DPT=8080
      3 DPT=443
      2 DPT=80
```

</details>


#### 🟢 Ejercicio 11.35 · SSH atacado

Cuenta los paquetes bloqueados que iban al **puerto 22**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'DPT=22 ' /var/log/ufw.log
```

_Resultado:_

```text
13
```


El espacio final evita contar `DPT=2222` o `DPT=22000`.
</details>


#### 🟢 Ejercicio 11.36 · TCP contra UDP

Cuenta los bloqueos de cada protocolo.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'PROTO=TCP' /var/log/ufw.log
grep -c 'PROTO=UDP' /var/log/ufw.log
```

_Resultado:_

```text
23
9
```

</details>


#### 🟡 Ejercicio 11.37 · Un bloque de IPs

Muestra los bloqueos cuyo origen está en `203.0.113.0/24` (cualquier `203.0.113.x`), acortados.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'SRC=203\.0\.113\.[0-9]{1,3} ' /var/log/ufw.log | cut -c1-70 | head -4
```

_Resultado:_

```text
Nov  6 09:01:09 ubuntu-pc kernel: [173169.033800] [UFW BLOCK] IN=enp0s
Nov  6 09:06:43 ubuntu-pc kernel: [173503.042900] [UFW BLOCK] IN=enp0s
Nov  6 09:07:15 ubuntu-pc kernel: [173535.045500] [UFW BLOCK] IN=enp0s
Nov  6 09:08:01 ubuntu-pc kernel: [173581.046800] [UFW BLOCK] IN=enp0s
```

</details>


#### 🟡 Ejercicio 11.38 · Telnet, SSH y RDP

Cuenta los bloqueos que iban a los puertos **22**, **23** (telnet) o **3389** (RDP).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE 'DPT=(22|23|3389) ' /var/log/ufw.log
```

_Resultado:_

```text
19
```

</details>


#### 🟡 Ejercicio 11.39 · La dirección MAC

Extrae la dirección **MAC** (14 bloques, porque UFW pone la MAC de destino + origen + tipo) que aparece en los bloqueos, sin repeticiones.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'MAC=([0-9a-f]{2}:){13}[0-9a-f]{2}' /var/log/ufw.log | sort -u
```

_Resultado:_

```text
MAC=08:00:27:4e:66:a1:52:54:00:12:35:02:08:00
```


`([0-9a-f]{2}:){13}` = 13 veces "dos hex y dos puntos", más un bloque final de dos hex: 14 bloques.
</details>


#### 🔴 Ejercicio 11.40 · Un ranking limpio

Muestra el ranking de puertos atacados, pero **solo los puertos de 2 o 3 cifras** (excluye 8080, 3389…).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'DPT=[0-9]{2,3} ' /var/log/ufw.log | sort | uniq -c | sort -rn
```

_Resultado:_

```text
     13 DPT=22 
      5 DPT=23 
      3 DPT=443 
      2 DPT=80 
      2 DPT=445 
      2 DPT=25 
      1 DPT=21 
```


`DPT=[0-9]{2,3} ` con el espacio final para que no coja los primeros 3 dígitos de uno más largo.
</details>


---

## 11.6 · 🏋️ Ejercicios: `dpkg.log` (paquetes)

#### 🟢 Ejercicio 11.41 · Paquetes instalados

Muestra, **solo los nombres**, de los paquetes que se instalaron (acción `install`), en una sola línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep ' install ' /var/log/dpkg.log | grep -oE 'install [^ :]+' | cut -d' ' -f2 | tr '\n' ' '; echo
```

_Resultado:_

```text
nano vim curl git tree htop openssh-server apache2 net-tools ufw 
```


`install [^ :]+` extrae "install nombre" (el nombre acaba en `:` o espacio) y `cut` quita la palabra `install`.
</details>


#### 🟢 Ejercicio 11.42 · Actualizaciones

Muestra las líneas de `dpkg.log` que son **actualizaciones** (`upgrade`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep ' upgrade ' /var/log/dpkg.log
```

_Resultado:_

```text
2024-11-05 09:10:41 upgrade libssl3t64:amd64 3.0.13-0ubuntu3.1 3.0.13-0ubuntu3.4
2024-11-05 09:10:44 upgrade openssh-client:amd64 1:9.6p1-3ubuntu13.4 1:9.6p1-3ubuntu13.5
2024-11-05 09:10:49 upgrade python3.12:amd64 3.12.3-1ubuntu0.1 3.12.3-1ubuntu0.3
2024-11-05 09:10:58 upgrade linux-image-6.8.0-45-generic:amd64 6.8.0-44.44 6.8.0-45.45
```

</details>


#### 🟢 Ejercicio 11.43 · Eliminaciones

Muestra las líneas de **eliminación** (`remove` o `purge`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E ' (remove|purge) ' /var/log/dpkg.log
```

_Resultado:_

```text
2024-11-05 09:11:14 remove cups-browsed:amd64 2.4.7-1.2ubuntu7.3 <none>
2024-11-05 09:11:16 purge cups-browsed:amd64 2.4.7-1.2ubuntu7.3 <none>
```

</details>


#### 🟡 Ejercicio 11.44 · Un solo día

Cuenta cuántas líneas de `dpkg.log` son del **4 de noviembre**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '^2024-11-04' /var/log/dpkg.log
```

_Resultado:_

```text
83
```

</details>


#### 🟡 Ejercicio 11.45 · Versiones con "epoch"

Muestra las líneas con una versión de paquete que tenga **epoch** (un número y `:` antes de la versión, como `1:2.43.0`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E ' [0-9]+:[0-9]+\.[0-9]+' /var/log/dpkg.log | head -3
```

_Resultado:_

```text
2024-11-04 09:12:05 install vim:amd64 <none> 2:9.1.0016-1ubuntu7.3
2024-11-04 09:12:07 status half-installed vim:amd64 2:9.1.0016-1ubuntu7.3
2024-11-04 09:12:08 status unpacked vim:amd64 2:9.1.0016-1ubuntu7.3
```


` [0-9]+:[0-9]+\.[0-9]+` = un espacio, el epoch, `:`, y una versión con punto. (Así se distingue de las **horas** como `09:12:01`, que no llevan un punto tras los dos primeros números.)
</details>


#### 🟡 Ejercicio 11.46 · Paquetes de nombre compuesto

Muestra los nombres de paquete (sin repetir) que acaban en `-client` o `-server`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '[a-z0-9-]+-(client|server)' /var/log/dpkg.log | sort -u
```

_Resultado:_

```text
openssh-client
openssh-server
```

</details>


#### 🟡 Ejercicio 11.47 · Versiones de Ubuntu

Extrae las versiones que contienen `ubuntu` seguido de número (como `13ubuntu7.1` o `0ubuntu3.4`), sin repetir.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '[0-9]ubuntu[0-9.]+' /var/log/dpkg.log | sort -u | head -8
```

_Resultado:_

```text
0ubuntu3.1
0ubuntu3.4
1ubuntu0.1
1ubuntu0.3
1ubuntu4
1ubuntu7.1
1ubuntu7.3
1ubuntu8.4
```

</details>


#### 🔴 Ejercicio 11.48 · Tipos de acción de dpkg

Cuenta cuántas veces aparece **cada tipo de acción** en `dpkg.log` (`install`, `upgrade`, `status`, `configure`…): es la tercera palabra de cada línea (tras la fecha y la hora).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^[0-9-]+ [0-9:]+ [a-z-]+' /var/log/dpkg.log | cut -d' ' -f3 | sort | uniq -c | sort -rn
```

_Resultado:_

```text
     83 status
     14 configure
     10 install
      4 upgrade
      4 startup
      1 trigproc
      1 remove
      1 purge
```


`^[0-9-]+ [0-9:]+ [a-z-]+` = fecha, hora y la palabra de la acción; `cut -d' ' -f3` se queda con la acción; y la cadena habitual de **contar y ordenar**.
</details>


#### 🔴 Ejercicio 11.49 · De la versión anterior a la nueva

En las líneas `upgrade`, extrae **paquete, versión vieja y versión nueva** (los tres campos tras `upgrade`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE 'upgrade [^ ]+ [^ ]+ [^ ]+' /var/log/dpkg.log
```

_Resultado:_

```text
upgrade libssl3t64:amd64 3.0.13-0ubuntu3.1 3.0.13-0ubuntu3.4
upgrade openssh-client:amd64 1:9.6p1-3ubuntu13.4 1:9.6p1-3ubuntu13.5
upgrade python3.12:amd64 3.12.3-1ubuntu0.1 3.12.3-1ubuntu0.3
upgrade linux-image-6.8.0-45-generic:amd64 6.8.0-44.44 6.8.0-45.45
```


`[^ ]+` = "un campo cualquiera sin espacios", tres veces separadas por espacios.
</details>


---

## 11.7 · 🏋️ Ejercicios: Apache (`access.log` y `error.log`)

Una línea de `access.log` tiene este formato (el *Combined Log Format*):

```text
203.0.113.45 - - [14/Oct/2024:10:31:01 +0200] "GET /wp-login.php HTTP/1.1" 404 276 "-" "Mozilla/5.0 zgrab/0.x"
 └─ IP ─────┘     └──── fecha ─────────────┘  └──── petición ──────────┘ └estado┘ └tamaño┘ └ referer ┘ └─ navegador ─┘
```

#### 🟢 Ejercicio 11.50 · Visitantes

Muestra el **ranking de IPs** que más visitan la web (las 5 primeras).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^[0-9.]+' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -5
```

_Resultado:_

```text
     18 203.0.113.11
     13 203.0.113.10
     12 192.168.1.51
     12 192.0.2.15
     10 8.8.4.4
```


`^[0-9.]+` = la IP al principio de la línea.
</details>


#### 🟢 Ejercicio 11.51 · Reparto de estados

Muestra cuántas peticiones hay de **cada código de estado** HTTP (200, 404…).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '" [0-9]{3} ' /var/log/apache2/access.log | sort | uniq -c
```

_Resultado:_

```text
     80 " 200 
      3 " 301 
      2 " 302 
      6 " 304 
      2 " 400 
      2 " 401 
      3 " 403 
     18 " 404 
      5 " 500 
```


El patrón `" [0-9]{3} ` es una comilla (cierre de la petición), un espacio, 3 dígitos y otro espacio. Así no se confunde con tamaños o fechas.
</details>


#### 🟢 Ejercicio 11.52 · Páginas no encontradas

Muestra el **ranking de URLs** que dieron **404**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '" 404 ' /var/log/apache2/access.log | grep -oE '"(GET|POST|HEAD) [^ ]+' | sort | uniq -c | sort -rn | head -4
```

_Resultado:_

```text
      7 "GET /no-existe.html
      3 "GET /favicon.ico
      1 "GET /xmlrpc.php
      1 "GET /wp-login.php
```

</details>


#### 🟢 Ejercicio 11.53 · Errores del servidor

Cuenta las peticiones que acabaron en **500**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '" 500 ' /var/log/apache2/access.log
```

_Resultado:_

```text
5
```

</details>


#### 🟢 Ejercicio 11.54 · Robots

Cuenta las peticiones de **Googlebot o bingbot**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE 'Googlebot|bingbot' /var/log/apache2/access.log
```

_Resultado:_

```text
12
```

</details>


#### 🟡 Ejercicio 11.55 · Escáneres de vulnerabilidades

Cuenta las peticiones a rutas sospechosas: `wp-login`, `.env`, `phpmyadmin`, `.git` o `../`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE 'wp-login|\.env|phpmyadmin|\.git|\.\./' /var/log/apache2/access.log
```

_Resultado:_

```text
5
```


Los puntos se escapan (`\.`) para que sean puntos de verdad.
</details>


#### 🟡 Ejercicio 11.56 · Descargas pesadas

Muestra (acortadas) las respuestas `200` con un **tamaño de 7 o más cifras** (≥ 1 MB).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '" 200 [0-9]{7,} ' /var/log/apache2/access.log | cut -c1-110
```

_Resultado:_

```text
198.51.100.8 - - [14/Oct/2024:10:02:45 +0200] "GET /descargas/guia.pdf HTTP/1.1" 200 1048576 "https://www.ejem
192.168.1.51 - - [14/Oct/2024:10:16:32 +0200] "GET /descargas/guia.pdf HTTP/1.1" 200 1048576 "-" "Mozilla/5.0 
192.168.1.50 - - [14/Oct/2024:10:21:22 +0200] "GET /descargas/guia.pdf HTTP/1.1" 200 1048576 "-" "curl/8.5.0"
198.51.100.7 - - [14/Oct/2024:10:27:31 +0200] "GET /descargas/guia.pdf HTTP/1.1" 200 1048576 "https://www.ejem
198.51.100.7 - - [14/Oct/2024:10:28:34 +0200] "GET /descargas/guia.pdf HTTP/1.1" 200 1048576 "https://www.ejem
203.0.113.11 - - [14/Oct/2024:10:29:18 +0200] "GET /descargas/guia.pdf HTTP/1.1" 200 1048576 "https://www.goog
```

</details>


#### 🟡 Ejercicio 11.57 · Tráfico por minuto del día

Cuenta las peticiones entre las **10:00:00 y las 10:29:59** del 14 de octubre.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '14/Oct/2024:10:[0-2][0-9]:[0-9]{2} ' /var/log/apache2/access.log
```

_Resultado:_

```text
95
```


`10:[0-2][0-9]` = hora 10 y minutos 00 a 29.
</details>


#### 🟡 Ejercicio 11.58 · Solo los POST

Muestra el ranking de URLs de las peticiones **POST** (y su estado).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '"POST [^ ]+ HTTP/[0-9.]+" [0-9]{3}' /var/log/apache2/access.log | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      2 "POST /login HTTP/1.1" 401
      2 "POST /login HTTP/1.1" 302
      1 "POST /login HTTP/1.1" 200
```

</details>


#### 🟡 Ejercicio 11.59 · Intentos de inyección SQL

Muestra las líneas con un patrón de **inyección SQL** del tipo `' OR '1'='1`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -F "' OR '1'='1" /var/log/apache2/access.log | cut -c1-110
```

_Resultado:_

```text
203.0.113.45 - - [14/Oct/2024:10:31:08 +0200] "GET /index.php?id=1' OR '1'='1 HTTP/1.1" 400 226 "-" "sqlmap/1.
```


`-F` hace que todos los símbolos sean literales; usamos comillas **dobles** para poder meter las simples dentro.
</details>


#### 🔴 Ejercicio 11.60 · Qué navegadores nos visitan

Muestra el **ranking de "User-Agent"** (el último campo entre comillas de cada línea de `access.log`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '"[^"]*"$' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -5
```

_Resultado:_

```text
     33 "curl/8.5.0"
     23 "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
     23 "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:131.0) Gecko/20100101 Firefox/131.0"
     20 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
      8 "Mozilla/5.0 zgrab/0.x"
```


`"[^"]*"$` = una comilla, todo lo que no sea comilla, otra comilla y fin de línea: el **último** campo entre comillas. Es el truco `"[^"]*"` de extraer lo que va entre comillas.
</details>


#### 🔴 Ejercicio 11.61 · Errores de Apache por módulo y nivel

En `error.log`, cuenta cuántas veces aparece cada combinación `[módulo:nivel]` (como `[core:error]`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '\[[a-z_]+:(error|warn|notice)\]' /var/log/apache2/error.log | sort | uniq -c
```

_Resultado:_

```text
      1 [authz_core:error]
      1 [autoindex:error]
      2 [core:error]
      1 [core:notice]
      1 [mpm_prefork:error]
      1 [mpm_prefork:notice]
      1 [php:error]
      1 [proxy_fcgi:error]
      1 [ssl:warn]
```


`\[` y `\]` literales; `[a-z_]+` el módulo; `(error|warn|notice)` el nivel.
</details>


---

## ✅ Resumen del capítulo 11

| Quiero… | Receta |
|---|---|
| Ranking de lo que más se repite | `grep -o 'DATO' f \| sort \| uniq -c \| sort -rn` |
| Extraer IPs | `grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}'` |
| Un día/hora concreta | `grep '^Nov  5 10:'` (¡dos espacios!) |
| Rango de horas | `grep -E '^Nov  5 (0[89]\|1[0-2]):'` |
| Los que se repiten ≥ 3 veces | `… \| uniq -c \| grep -E '^ *([3-9]\|[0-9]{2,}) '` |
| Logs rotados `.gz` | `zgrep` |
| Seguir un log en vivo | `tail -f /var/log/syslog \| grep --line-buffered ssh` |
| Mensajes del kernel | `dmesg \| grep -i usb` |

➡️ **Siguiente parada:** [Capítulo 12](12-formatos.md): **IPs, IPv6, correos, dominios, teléfonos, fechas…** con regex a prueba de bombas. Los ejercicios que hizo tu profe, uno por uno.

---
⬅️ [Capítulo 10 · Los ficheros del sistema: `passwd`, `group`, `fstab`, `hosts`…](10-ficheros-del-sistema.md) · 🏠 [Índice](README.md) · [Capítulo 12 · Reconocer formatos: IPv4, IPv6, correos, dominios, MAC…](12-formatos.md) ➡️
