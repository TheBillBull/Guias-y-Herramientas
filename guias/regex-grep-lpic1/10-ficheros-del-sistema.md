# Capítulo 10 · Los ficheros del sistema: `passwd`, `group`, `fstab`, `hosts`…

> 🎯 **Objetivo:** aplicar **todo** lo aprendido a los ficheros reales de configuración de Ubuntu. Ya sabes las herramientas; ahora toca **leer el sistema** con ellas.
>
> 📘 **LPIC-1:** 103.7 (regex) + 107.1 (usuarios y grupos) + 104.3 (`/etc/fstab`) + 109.1 (`/etc/hosts`, `/etc/services`) — son ficheros que **salen en el examen**.
>
> 🧪 Estos comandos trabajan sobre ficheros **reales** (`/etc/passwd`…). Las salidas del libro vienen de la copia de ejemplo; en tu máquina cambiarán nombres y números, pero **el filtro es el mismo**.

---

## 10.1 · `/etc/passwd`: la agenda de usuarios

Cada línea es **un usuario**, con **7 campos separados por `:`**:

```text
alumno : x : 1000 : 1000 : Alumno Linux,,, : /home/alumno : /bin/bash
   │     │    │      │          │                 │             │
   1     2    3      4          5                 6             7
 nombre  │   UID    GID    comentario (GECOS)   carpeta       shell
         └─ "x" = la contraseña está en /etc/shadow
```

| Campo | Contenido |
|---|---|
| 1 | **nombre** de usuario |
| 2 | contraseña (`x` = está cifrada en `/etc/shadow`) |
| 3 | **UID** (número de usuario). `0` = root; < 1000 = usuarios del sistema; ≥ 1000 = personas |
| 4 | **GID** (número del grupo **principal**) |
| 5 | comentario (nombre real, teléfono…, a menudo con `,,,`) |
| 6 | **carpeta personal** (*home*) |
| 7 | **shell** de inicio de sesión (`nologin` / `false` = no puede entrar) |

### La técnica universal: "saltar campos con `[^:]*:`"

Como los campos van separados por `:`, un campo es "**todo lo que no sea `:`**": `[^:]*`. Y para **llegar** al campo N saltas N−1 campos con `[^:]*:`:

```text
Campo 1  →  ^[^:]*
Campo 2  →  ^[^:]*:[^:]*
Campo 3  →  ^[^:]*:[^:]*:[^:]*
```

Y para **filtrar** el campo 3 con un patrón `P` (por ejemplo `P` = `0`), saltas los dos primeros campos y pones `P` seguido de `:`:

```text
^[^:]*:[^:]*:P:
```

Receta: **`^`** + **(N−1) veces `[^:]*:`** + el **patrón `P` del campo N** + **`:`** (o `$` si N es el último campo).

Para el campo 4 (el GID) con un filtro, por ejemplo "GID de 4 cifras":

```text
^[^:]*:[^:]*:[^:]*:[0-9]{4}:
 └─1──┘ └─2──┘ └─3──┘ └─4────┘
```

Y con ERE se abrevia con un grupo repetido: `^([^:]*:){3}[0-9]{4}:`.

```bash
grep -E '^([^:]*:){3}[0-9]{4}:' /etc/passwd | cut -d: -f1,4
```

_Resultado:_

```text
alumno:1000
ana:1001
luis:1002
marta:1100
pedro:1100
invitado:1005
```


Los usuarios cuyo **GID** tiene exactamente 4 cifras. ¡Mucho más corto con el grupo `([^:]*:){3}`!

---

## 10.2 · `/etc/group`: los grupos

```text
docentes : x : 1100 : ana,luis,marta,pedro
   │      │     │            │
   1      2     3            4
 grupo    │    GID    miembros (separados por comas)
```

El campo 4 tiene la lista de **miembros secundarios** separados por **comas** (¡la coma, otra vez, como letra normal!).

## 10.3 · Otros ficheros que vamos a exprimir

| Fichero | Formato |
|---|---|
| `/etc/os-release` | `CLAVE=valor` |
| `/etc/hosts` | `IP  nombre  alias…` |
| `/etc/fstab` | 6 campos separados por espacios: `dispositivo punto-de-montaje tipo opciones dump pass` |
| `/etc/services` | `servicio  puerto/protocolo  alias…` |
| `/etc/shells` | una shell válida por línea |
| `/etc/crontab` | `m h dom mon dow usuario comando` |
| `/etc/ssh/sshd_config` | `Directiva valor` (con `#` para comentarios) |
| `/etc/login.defs` | `CLAVE  valor` |

---

## 10.4 · 🏋️ Ejercicios: `/etc/passwd`

#### 🟢 Ejercicio 10.1 · El superusuario

Muestra las líneas de `/etc/passwd` cuyo **UID es 0** (tercer campo).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:0:' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root:x:0:»0:root:/root:/bin/bash
```


`[^:]*:[^:]*:` salta dos campos y `0:` exige que el tercero sea exactamente `0`. **Auditoría de seguridad clásica**: solo `root` debería tener UID 0. Si aparece otro usuario con UID 0, ¡alarma!
</details>


#### 🟢 Ejercicio 10.2 · Solo los nombres

Muestra **solo los nombres de usuario** de `/etc/passwd` (primer campo), con un solo `grep` (sin `cut`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '^[^:]*' /etc/passwd | head -8
```

_Resultado:_

```text
root
daemon
bin
sys
sync
games
man
lp
```


`^[^:]*` = desde el principio, todo lo que no sea `:`. `-o` imprime solo eso. (Un `grep` hace el trabajo de `cut -d: -f1`.)
</details>


#### 🟢 Ejercicio 10.3 · Solo las shells

Muestra **solo la shell** (último campo) de cada usuario, con un solo `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '[^:]*$' /etc/passwd | head -5
```

_Resultado:_

```text
/bin/bash
/usr/sbin/nologin
/usr/sbin/nologin
/usr/sbin/nologin
/bin/sync
```


`[^:]*$` = "lo que no sea `:` hasta el final de línea" = el último campo.
</details>


#### 🟢 Ejercicio 10.4 · Cuántos usuarios de cada shell

Cuenta cuántos usuarios usa cada shell, de más a menos usada.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '[^:]*$' /etc/passwd | sort | uniq -c | sort -rn
```

_Resultado:_

```text
     29 /usr/sbin/nologin
      5 /bin/bash
      4 /bin/false
      1 /bin/zsh
      1 /bin/sync
      1 /bin/sh
```


`grep -o` extrae la shell, `sort | uniq -c` cuenta cada valor y `sort -rn` ordena el resultado numéricamente de mayor a menor.
</details>


#### 🟢 Ejercicio 10.5 · Los usuarios "de verdad"

Muestra los usuarios que **sí pueden iniciar sesión**: los que **no** acaban en `nologin`, `false` ni `sync`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -vE '(nologin|false|sync)$' /etc/passwd | cut -d: -f1,7
```

_Resultado:_

```text
root:/bin/bash
postgres:/bin/bash
alumno:/bin/bash
ana:/bin/bash
luis:/bin/zsh
marta:/bin/sh
pedro:/bin/bash
```


`-v` invierte y la alternativa `(nologin|false|sync)$` agrupa las tres "shells sin sesión".
</details>


#### 🟢 Ejercicio 10.6 · Los usuarios con casa en /home

Muestra los usuarios cuya **carpeta personal** (6.º campo) empieza por `/home/`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^([^:]*:){5}/home/' /etc/passwd | cut -d: -f1,6
```

_Resultado:_

```text
alumno:/home/alumno
ana:/home/ana
luis:/home/luis
marta:/home/marta
pedro:/home/pedro
invitado:/home/invitado
```


`([^:]*:){5}` salta los 5 primeros campos; después, `/home/`.
</details>


#### 🟢 Ejercicio 10.7 · Usuarios de nombre largo

Muestra los usuarios cuyo **nombre** tiene **8 o más caracteres**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^[^:]{8,}' /etc/passwd
```

_Resultado:_

```text
www-data
systemd-network
systemd-timesync
systemd-resolve
messagebus
pollinate
landscape
fwupd-refresh
postgres
invitado
```


`^[^:]{8,}` = 8 o más caracteres que no sean `:` desde el principio. Con `-o` solo vemos el nombre.
</details>


#### 🟢 Ejercicio 10.8 · Nombres con guion o subrayado

Muestra los usuarios cuyo **nombre** (primer campo) contiene un guion `-` o un guion bajo `_`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^[^:]*[-_][^:]*' /etc/passwd
```

_Resultado:_

```text
www-data
_apt
systemd-network
systemd-timesync
systemd-resolve
fwupd-refresh
```


El corchete `[-_]` con el guion **al principio** (para que no sea un rango). Hay `_apt`, `www-data`, `systemd-network`…
</details>


#### 🟢 Ejercicio 10.9 · Empiezan por guion bajo

Muestra los usuarios cuyo nombre **empieza por `_`**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '^_[^:]*' /etc/passwd
```

_Resultado:_

```text
_apt
```

</details>


#### 🟡 Ejercicio 10.10 · Usuarios del sistema (UID de 1 a 3 cifras)

Muestra los usuarios cuyo **UID tiene 1, 2 o 3 cifras** (< 1000): los usuarios del sistema. Cuéntalos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^[^:]*:[^:]*:[0-9]{1,3}:' /etc/passwd
```

_Resultado:_

```text
33
```


`[0-9]{1,3}:` = entre 1 y 3 cifras (0–999) y luego el `:` que cierra el campo. Incluye a `root` (UID 0).
</details>


#### 🟡 Ejercicio 10.11 · UID con 4 o 5 cifras

Muestra `usuario:UID` de quienes tienen UID de **4 o más cifras**. Pregunta: ¿qué usuario "raro" aparece además de las personas?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[0-9]{4,}:' /etc/passwd | cut -d: -f1,3
```

_Resultado:_

```text
nobody:65534
alumno:1000
ana:1001
luis:1002
marta:1003
pedro:1004
invitado:1005
backup2:1006
```


Aparece `nobody` con UID 65534 (5 cifras). No es una persona: es el usuario "sin privilegios". Para una definición exacta de "persona" (UID de 1000 a 59999) vimos en el capítulo 6 que hace falta una alternativa: `([1-9][0-9]{3}|[1-5][0-9]{4})`.
</details>


#### 🟡 Ejercicio 10.12 · UID igual a GID

Muestra los usuarios cuyo **UID es igual a su GID** (por ejemplo `1000:1000`). *(Pista: referencia hacia atrás.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:([0-9]+):\1:' /etc/passwd | cut -d: -f1,3,4
```

_Resultado:_

```text
root:0:0
daemon:1:1
bin:2:2
sys:3:3
lp:7:7
mail:8:8
news:9:9
uucp:10:10
proxy:13:13
www-data:33:33
backup:34:34
list:38:38
irc:39:39
nobody:65534:65534
systemd-network:998:998
systemd-timesync:996:996
systemd-resolve:991:991
fwupd-refresh:990:990
polkitd:989:989
alumno:1000:1000
… (y 3 líneas más)
```


`([0-9]+)` **captura** el UID y `\1` exige que el siguiente campo sea **igual**. ¡Una referencia hacia atrás en el mundo real!
</details>


#### 🟡 Ejercicio 10.13 · UID distinto de GID

Muestra los usuarios cuyo UID **no** es igual al GID, mostrando nombre, UID y GID.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -vE '^[^:]*:[^:]*:([0-9]+):\1:' /etc/passwd | cut -d: -f1,3,4
```

_Resultado:_

```text
sync:4:65534
games:5:60
man:6:12
_apt:42:65534
messagebus:100:104
syslog:101:105
uuidd:102:106
usbmux:103:46
tss:104:107
sshd:105:65534
pollinate:106:1
tcpdump:107:108
landscape:108:109
mysql:110:112
postgres:111:113
marta:1003:1100
pedro:1004:1100
backup2:1006:34
```


Es el caso anterior con `-v`. Ahí salen, por ejemplo, `sync` (UID 4, GID 65534), `marta` y `pedro` (que pertenecen al grupo 1100).
</details>


#### 🟡 Ejercicio 10.14 · GECOS con espacios

Muestra los usuarios cuyo campo de comentario (5.º) contiene un **espacio**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^([^:]*:){4}[^:]* [^:]*:' /etc/passwd | cut -d: -f1,5
```

_Resultado:_

```text
list:Mailing List Manager
systemd-network:systemd Network Management
systemd-timesync:systemd Time Synchronization
systemd-resolve:systemd Resolver
usbmux:usbmux daemon,,,
tss:TPM software stack,,,
fwupd-refresh:Firmware update daemon
polkitd:User for polkitd
mysql:MySQL Server,,,
postgres:PostgreSQL administrator,,,
alumno:Alumno Linux,,,
ana:Ana Garcia,,,
luis:Luis Perez,,,
marta:Marta Ruiz,,,
pedro:Pedro Gomez,,,
backup2:Copias nocturnas
```


`([^:]*:){4}` salta 4 campos; luego `[^:]* [^:]*:` = texto, un espacio, texto y `:`.
</details>


#### 🟡 Ejercicio 10.15 · Comentario por defecto `,,,`

Cuenta los usuarios con `,,,` al final de su campo de comentario (señal de haberse creado con `adduser`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^([^:]*:){4}[^:]*,,,:' /etc/passwd
```

_Resultado:_

```text
9
```


Aquí las comas son letras normales. 9 usuarios.
</details>


#### 🟡 Ejercicio 10.16 · Casa fuera de /home

Muestra los usuarios cuya carpeta personal **no** empieza por `/home/` ni es `/nonexistent`, `/` ni `/root`. *(Es decir: casas "especiales" de servicios.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -vE '^([^:]*:){5}(/home/|/nonexistent:|/:|/root:)' /etc/passwd | cut -d: -f1,6
```

_Resultado:_

```text
daemon:/usr/sbin
bin:/bin
sys:/dev
sync:/bin
games:/usr/games
man:/var/cache/man
lp:/var/spool/lpd
mail:/var/mail
news:/var/spool/news
uucp:/var/spool/uucp
proxy:/bin
www-data:/var/www
backup:/var/backups
list:/var/list
irc:/run/ircd
uuidd:/run/uuidd
usbmux:/var/lib/usbmux
tss:/var/lib/tpm
sshd:/run/sshd
pollinate:/var/cache/pollinate
… (y 4 líneas más)
```


Se descartan (`-v`) las líneas cuyo 6.º campo coincida con alguna de las alternativas.
</details>


#### 🟡 Ejercicio 10.17 · Shell sh o zsh

Muestra los usuarios cuya shell sea `/bin/sh` **o** `/bin/zsh` (pero no `/bin/bash`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E ':/bin/z?sh$' /etc/passwd | cut -d: -f1,7
```

_Resultado:_

```text
luis:/bin/zsh
marta:/bin/sh
```


`z?sh` = una `z` opcional y luego `sh`: cubre `sh` y `zsh`, pero no `bash` (que no acaba en "sh" tras `/bin/`: la `b` lo impide).
</details>


#### 🟡 Ejercicio 10.18 · Contraseñas "raras"

**Auditoría:** muestra los usuarios cuyo **segundo campo** (la contraseña) **no** es `x`. (En un sistema sano no debería haber ninguno.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep -vE '^[^:]*:x:' /etc/passwd
```

_Resultado:_

```text
(no sale nada)
```


`-v` y `^[^:]*:x:` = "segundo campo igual a `x`". Si no sale nada, todo está bien: las contraseñas están en `/etc/shadow`.
</details>


#### 🟡 Ejercicio 10.19 · UIDs de sistema "intermedios"

Muestra los usuarios con **UID entre 100 y 999** (exactamente 3 cifras, sin ceros a la izquierda).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[1-9][0-9]{2}:' /etc/passwd | cut -d: -f1,3
```

_Resultado:_

```text
systemd-network:998
systemd-timesync:996
systemd-resolve:991
messagebus:100
syslog:101
uuidd:102
usbmux:103
tss:104
sshd:105
pollinate:106
tcpdump:107
landscape:108
fwupd-refresh:990
polkitd:989
mysql:110
postgres:111
```


`[1-9][0-9]{2}` = 3 cifras empezando por 1-9. Son los usuarios que los paquetes crean al instalar servicios (`messagebus`, `syslog`, `sshd`…).
</details>


#### 🔴 Ejercicio 10.20 · ⭐ El ejercicio de tu profe: Usuarios y GID (≥ 50)

**"Queremos un listado de `usuario:grupo` de aquellos usuarios cuyo GID sea ≥ 50."** Primera parte: sácalo **con `grupo` = número de GID**, con **un solo comando**.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -nE 's/^([^:]+):[^:]*:[^:]*:([5-9][0-9]|[0-9]{3,}):.*/\1:\2/p' /etc/passwd
```

_Resultado:_

```text
sync:65534
games:60
_apt:65534
nobody:65534
systemd-network:998
systemd-timesync:996
systemd-resolve:991
messagebus:104
syslog:105
uuidd:106
tss:107
sshd:65534
tcpdump:108
landscape:109
fwupd-refresh:990
polkitd:989
mysql:112
postgres:113
alumno:1000
ana:1001
… (y 4 líneas más)
```


Descomposición:

- `^([^:]+)` **captura el nombre** (grupo `\1`).
- `:[^:]*:[^:]*:` salta la contraseña y el UID.
- `([5-9][0-9]|[0-9]{3,})` **captura el GID** (grupo `\2`) y solo acepta **GID ≥ 50**: dos cifras del 50 al 99, **o** tres o más cifras.
- `:.*` se come el resto de la línea.
- En la sustitución `\1:\2` se escribe `nombre:gid`. `sed -n` + `p` imprime **solo** las líneas donde hubo cambio, o sea, las que cumplen el filtro.

Un único comando (`sed -nE`), una única regex. `grep` solo sabe **seleccionar líneas** (o con `-o` extraer trozos contiguos), pero no "reordenar" campos: para eso hace falta `sed` (capítulo 14).
</details>


#### 🔴 Ejercicio 10.21 · ⭐ Usuarios y **nombre** del grupo (GID ≥ 50)

Ahora, **de verdad lo que pide**: `usuario:nombre-del-grupo`, solo para los usuarios con **GID ≥ 50**. Necesitas "cruzar" `/etc/passwd` con `/etc/group` (el nombre del grupo está allí). Versión de **un solo comando**.

<details>
<summary>💡 Ver solución</summary>


```bash
awk -F: 'NR==FNR { g[$3]=$1; next } $4 >= 50 { print $1 ":" (g[$4] ? g[$4] : "?") }' /etc/group /etc/passwd
```

_Resultado:_

```text
sync:nogroup
games:games
_apt:nogroup
nobody:nogroup
systemd-network:systemd-network
systemd-timesync:systemd-timesync
systemd-resolve:systemd-resolve
messagebus:messagebus
syslog:syslog
uuidd:uuidd
tss:tss
sshd:nogroup
tcpdump:tcpdump
landscape:landscape
fwupd-refresh:fwupd-refresh
polkitd:?
mysql:mysql
postgres:postgres
alumno:alumno
ana:ana
… (y 4 líneas más)
```


`awk` (que se estudia más allá del LPIC-1, pero es el "cuchillo suizo" de los administradores) lee **primero** `/etc/group` y guarda en `g[GID] = nombre`; luego, al leer `/etc/passwd`, compara el GID (campo 4, **numéricamente**: `>= 50`) y escribe `usuario:nombre`. Si el grupo no existe (`polkitd`, GID 989, es un "huérfano"), pone `?`.

Con herramientas **puramente de LPIC-1** (`grep`, `sort`, `join`) también se puede (ver el siguiente ejercicio).
</details>


#### 🔴 Ejercicio 10.22 · ⭐ Lo mismo con las herramientas del examen (`grep` + `sort` + `join`)

Obtén `usuario:grupo` para GID ≥ 50 usando **`grep` (para filtrar) + `sort` + `join`** (los tres son de LPIC-1: 103.2).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[^:]*:([5-9][0-9]|[0-9]{3,}):' /etc/passwd | sort -t: -k4,4 | join -t: -1 4 -2 3 -o 1.1,2.1 - <(sort -t: -k3,3 /etc/group) | sort
```

_Resultado:_

```text
_apt:nogroup
alumno:alumno
ana:ana
fwupd-refresh:fwupd-refresh
games:games
invitado:invitado
landscape:landscape
luis:luis
marta:docentes
messagebus:messagebus
mysql:mysql
nobody:nogroup
pedro:docentes
postgres:postgres
sshd:nogroup
sync:nogroup
syslog:syslog
systemd-network:systemd-network
systemd-resolve:systemd-resolve
systemd-timesync:systemd-timesync
… (y 3 líneas más)
```


- `grep -E …` deja solo los usuarios con GID ≥ 50.
- `sort -t: -k4,4` ordena `passwd` por su 4.º campo (GID); `sort -t: -k3,3` ordena `group` por su 3.º (GID). **`join` exige las dos entradas ordenadas** por el campo de unión.
- `join -t: -1 4 -2 3` une `passwd` (campo 4) con `group` (campo 3), y `-o 1.1,2.1` muestra solo el campo 1 del primer fichero (nombre de usuario) y el campo 1 del segundo (nombre del grupo).
- `<( … )` es una *sustitución de procesos* de `bash`. El `sort` final lo deja ordenado.

El resultado omite al huérfano `polkitd` (su GID no existe en `/etc/group`; `join` solo escribe las parejas que encuentra).
</details>


#### 🔴 Ejercicio 10.23 · Usuarios cuyo grupo principal no existe

**Auditoría:** encuentra los usuarios cuyo GID **no aparece** en `/etc/group` (grupos "huérfanos").

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f4 /etc/passwd | sort -u | grep -vxFf <(cut -d: -f3 /etc/group)
```

_Resultado:_

```text
989
```


Se sacan los GID usados en `passwd`, sin repetir, y se descartan (`-v`) los que coinciden **exactamente** (`-x`) como texto fijo (`-F`) con algún GID listado en `group` (`-f`). Queda el `989` (el de `polkitd`).
</details>


---

## 10.5 · 🏋️ Ejercicios: `/etc/group`

#### 🟢 Ejercicio 10.24 · Los grupos del sistema

Muestra los grupos con **GID de 1 a 3 cifras** (< 1000).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^[^:]*:[^:]*:[0-9]{1,3}:' /etc/group
```

_Resultado:_

```text
50
```

</details>


#### 🟢 Ejercicio 10.25 · Grupos con miembros

Muestra los grupos que tienen **al menos un miembro** en el cuarto campo (que no está vacío).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[^:]*:.+' /etc/group
```

_Resultado:_

```text
adm:x:4:syslog,alumno
dialout:x:20:alumno
cdrom:x:24:alumno
floppy:x:25:alumno
sudo:x:27:alumno,ana
audio:x:29:alumno
dip:x:30:alumno
backup:x:34:backup2
video:x:44:alumno
plugdev:x:46:alumno,usbmux
docentes:x:1100:ana,luis,marta,pedro
```


`.+` tras el tercer `:` exige que el cuarto campo tenga al menos un carácter.
</details>


#### 🟢 Ejercicio 10.26 · Grupos sin miembros

Cuenta los grupos con el campo de miembros **vacío** (la línea acaba justo tras el último `:`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c ':$' /etc/group
```

_Resultado:_

```text
45
```

</details>


#### 🟡 Ejercicio 10.27 · ¿Dónde está `alumno`?

Muestra los **nombres de los grupos** a los que pertenece `alumno` como miembro secundario. *(Cuidado: `alumno` solo cuenta como palabra entera dentro de la lista.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '(:|,)alumno(,|$)' /etc/group | cut -d: -f1
```

_Resultado:_

```text
adm
dialout
cdrom
floppy
sudo
audio
dip
video
plugdev
```


`(:|,)alumno(,|$)` = `alumno` precedido por `:` o `,` y seguido por `,` o fin de línea. Así no confundimos `alumno` con `alumnos` ni con el grupo llamado `alumno` (cuyo nombre está al **principio**, sin `:` ni `,` delante).
</details>


#### 🟡 Ejercicio 10.28 · Grupos con más de un miembro

Muestra los grupos con **dos o más miembros** (hay al menos una coma en el 4.º campo).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[^:]*:[^:]*,' /etc/group
```

_Resultado:_

```text
adm:x:4:syslog,alumno
sudo:x:27:alumno,ana
plugdev:x:46:alumno,usbmux
docentes:x:1100:ana,luis,marta,pedro
```


Basta una coma en el último campo. Aquí la coma es una letra normal.
</details>


#### 🟡 Ejercicio 10.29 · Grupos con exactamente 4 miembros

Muestra los grupos con **exactamente 4 miembros** (4 nombres separados por 3 comas).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[^:]*:[^,:]+(,[^,:]+){3}$' /etc/group
```

_Resultado:_

```text
docentes:x:1100:ana,luis,marta,pedro
```


`[^,:]+` = un nombre; `(,[^,:]+){3}` = tres veces "coma y otro nombre". 4 nombres en total.
</details>


#### 🟡 Ejercicio 10.30 · Contar los miembros

Cuenta **cuántas comas** hay en el campo de miembros de todos los grupos (cada coma separa a dos miembros).

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f4 /etc/group | grep -o ',' | wc -l
```

_Resultado:_

```text
6
```


`cut` aísla el campo 4, `grep -o ','` saca cada coma en una línea, y `wc -l` las cuenta.
</details>


#### 🟡 Ejercicio 10.31 · GIDs "de persona"

Muestra los grupos con **GID de 1000 en adelante** (4 o más cifras) y excluye `nogroup` (65534) con un patrón preciso.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:([1-9][0-9]{3}|[1-5][0-9]{4}):' /etc/group
```

_Resultado:_

```text
alumno:x:1000:
ana:x:1001:
luis:x:1002:
invitado:x:1005:
docentes:x:1100:ana,luis,marta,pedro
```

</details>


#### 🟡 Ejercicio 10.32 · Grupos "systemd"

Muestra los grupos cuyo nombre **empieza por `systemd`**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^systemd' /etc/group
```

_Resultado:_

```text
systemd-journal:x:999:
systemd-network:x:998:
systemd-timesync:x:996:
systemd-resolve:x:991:
```

</details>


#### 🔴 Ejercicio 10.33 · Miembros de `sudo`

Muestra los usuarios que son miembros del grupo `sudo` (los "administradores"), **uno por línea**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^sudo:' /etc/group | cut -d: -f4 | tr ',' '\n'
```

_Resultado:_

```text
alumno
ana
```


`grep` localiza la línea del grupo, `cut -d: -f4` se queda con la lista de miembros y `tr ',' '\n'` cambia cada coma por un salto de línea (la coma, como separador de la lista). Solo `alumno` y `ana`. (En el capítulo 13 verás que `grep -oP` lo haría sin `cut` ni `tr`.)
</details>


---

## 10.6 · 🏋️ Ejercicios: `/etc/os-release`, `hosts`, `fstab`, `services`…

#### 🟢 Ejercicio 10.34 · Claves que empiezan por `VERSION`

Repite el ejercicio de tu profe con la **clave exacta**: muestra las líneas de `/etc/os-release` cuya **clave** empieza por `VERSION`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^VERSION' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
«VERSION»_ID="24.04"
«VERSION»="24.04.1 LTS (Noble Numbat)"
«VERSION»_CODENAME=noble
```

</details>


#### 🟢 Ejercicio 10.35 · Las URL

Muestra las líneas de `/etc/os-release` que contienen una URL (`http://` o `https://`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'https?://' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
HOME_URL="«https://»www.ubuntu.com/"
SUPPORT_URL="«https://»help.ubuntu.com/"
BUG_REPORT_URL="«https://»bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="«https://»www.ubuntu.com/legal/terms-and-policies/privacy-policy"
```

</details>


#### 🟢 Ejercicio 10.36 · Solo las claves `…_URL`

Muestra solo **el nombre de la clave** (sin valor) de las líneas cuya clave acaba en `_URL`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^[A-Z_]+_URL' /etc/os-release
```

_Resultado:_

```text
HOME_URL
SUPPORT_URL
BUG_REPORT_URL
PRIVACY_POLICY_URL
```

</details>


#### 🟢 Ejercicio 10.37 · Las IPv4 de /etc/hosts

Muestra las líneas **activas** de `/etc/hosts` que empiezan por una **dirección IPv4** (dígitos y puntos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]+(\.[0-9]+){3}[[:space:]]' /etc/hosts
```

_Resultado:_

```text
127.0.0.1 localhost
127.0.1.1 ubuntu-pc
192.168.1.10   servidor.miempresa.com   servidor
192.168.1.11   impresora.miempresa.com  impresora
192.168.1.20   nas.miempresa.com        nas
10.0.0.5       backup.miempresa.es      backup
```


`[0-9]+(\.[0-9]+){3}` = un número y tres veces ".número". Después, espacio en blanco. El `^` descarta la línea comentada.
</details>


#### 🟢 Ejercicio 10.38 · Las IPv6 de /etc/hosts

Muestra las líneas de `/etc/hosts` cuya dirección sea **IPv6** (empiezan por caracteres hexadecimales y dos puntos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9a-fA-F]*:' /etc/hosts
```

_Resultado:_

```text
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```


`[0-9a-fA-F]*:` = cero o más dígitos hex y un `:`: `::1`, `fe00::0`, `ff02::1`…
</details>


#### 🟡 Ejercicio 10.39 · Los nombres de miempresa

Extrae **todos los nombres de máquina** del dominio `miempresa.com` de `/etc/hosts` (sin las IP ni los alias), uno por línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '[a-z0-9-]+\.miempresa\.com' /etc/hosts
```

_Resultado:_

```text
servidor.miempresa.com
impresora.miempresa.com
nas.miempresa.com
antiguo.miempresa.com
```


`[a-z0-9-]+` (con el guion al final del corchete) + `\.miempresa\.com`. El `-o` imprime solo el nombre. Fíjate en que sale también `antiguo.miempresa.com`, que está en una línea **comentada**: `-o` no entiende de comentarios. Para evitarlo, filtra antes: `grep -v '^#' /etc/hosts | grep -oE '[a-z0-9-]+\.miempresa\.com'`.
</details>


#### 🟡 Ejercicio 10.40 · Hosts con alias

Muestra las líneas **activas** de `/etc/hosts` que tienen **tres o más campos** (IP, nombre y al menos un alias).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^#[:space:]]+([[:space:]]+[^[:space:]]+){2,}' /etc/hosts
```

_Resultado:_

```text
192.168.1.10   servidor.miempresa.com   servidor
192.168.1.11   impresora.miempresa.com  impresora
192.168.1.20   nas.miempresa.com        nas
10.0.0.5       backup.miempresa.es      backup
::1     ip6-localhost ip6-loopback
```


`^[^#[:space:]]+` = primer campo (no empieza por `#` ni es un espacio), seguido de **dos o más** grupos "espacios + campo".
</details>


#### 🟡 Ejercicio 10.41 · Discos ext4 o xfs

Muestra las entradas de `/etc/fstab` cuyo **tipo** de sistema de ficheros es `ext4` **o** `xfs`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '[[:space:]](ext4|xfs)[[:space:]]' /etc/fstab
```

_Resultado:_

```text
UUID=3f5a9c1e-7b2d-4e8a-9c01-5d6e7f8a9b0c /               ext4    errors=remount-ro 0       1
/dev/sdb1       /datos          ext4    defaults        0       2
/dev/sdc1       /backup         xfs     defaults,noatime 0      2
```


Con espacios a los lados para no coger la palabra en otros contextos.
</details>


#### 🟡 Ejercicio 10.42 · Montajes con UUID

Muestra las entradas de `/etc/fstab` que identifican el dispositivo con `UUID=`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^UUID=' /etc/fstab
```

_Resultado:_

```text
UUID=3f5a9c1e-7b2d-4e8a-9c01-5d6e7f8a9b0c /               ext4    errors=remount-ro 0       1
UUID=A1B2-C3D4  /boot/efi       vfat    umask=0077      0       1
```

</details>


#### 🟡 Ejercicio 10.43 · Montajes de red

Muestra las entradas de `/etc/fstab` que son **montajes de red** (empiezan por `//`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^//' /etc/fstab
```

_Resultado:_

```text
//nas/compartido /mnt/nas       cifs    credentials=/root/.cred,uid=1000 0 0
```

</details>


#### 🟡 Ejercicio 10.44 · Fsck en segundo lugar

Muestra las entradas de `/etc/fstab` cuyo último campo (`pass`) es `2`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '[[:space:]]2$' /etc/fstab
```

_Resultado:_

```text
/dev/sdb1       /datos          ext4    defaults        0       2
/dev/sdc1       /backup         xfs     defaults,noatime 0      2
```


Un espacio en blanco, el `2` y el final de línea.
</details>


#### 🟡 Ejercicio 10.45 · Puertos "altos"

Muestra los servicios de `/etc/services` cuyo **puerto tiene 4 o más cifras**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '[[:space:]][0-9]{4,}/(tcp|udp)' /etc/services
```

_Resultado:_

```text
mysql           3306/tcp
postgresql      5432/tcp        postgres        # PostgreSQL Database
http-alt        8080/tcp        webcache        # WWW caching service
```


`[[:space:]]` delante evita coger el final de otros números; `[0-9]{4,}` 4 o más cifras y `/(tcp|udp)`.
</details>


#### 🟡 Ejercicio 10.46 · Servicios UDP

Cuenta cuántos servicios de `/etc/services` usan UDP.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '/udp' /etc/services
```

_Resultado:_

```text
12
```

</details>


#### 🟡 Ejercicio 10.47 · El puerto del servicio ssh

Muestra **solo el número de puerto** del servicio `ssh` (22). *(Con dos `grep` en tubería; en el capítulo 13 lo harás con uno.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^ssh[[:space:]]+[0-9]+' /etc/services | grep -oE '[0-9]+$'
```

_Resultado:_

```text
22
```


Con un solo `grep` no basta aquí (necesitamos "mirar atrás" para quitar `ssh`): en el [capítulo 13](13-nivel-master.md), `grep -oP '^ssh\s+\K[0-9]+'` lo hará en uno.
</details>


#### 🟡 Ejercicio 10.48 · Tareas del crontab del sistema

Muestra las líneas de `/etc/crontab` que son **tareas programadas** (empiezan por un número) y se ejecutan como `root`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]+[[:space:]].*[[:space:]]root[[:space:]]' /etc/crontab | cut -c1-60
```

_Resultado:_

```text
17 *    * * *   root    cd / && run-parts --report /etc/cron
25 6    * * *   root    test -x /usr/sbin/anacron || { cd / 
47 6    * * 7   root    test -x /usr/sbin/anacron || { cd / 
52 6    1 * *   root    test -x /usr/sbin/anacron || { cd / 
```

</details>


#### 🟡 Ejercicio 10.49 · Valores numéricos de login.defs

Muestra las directivas **numéricas** activas de `/etc/login.defs` (clave y número, nada más).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[A-Z_]+[[:space:]]+[0-9]+$' /etc/login.defs
```

_Resultado:_

```text
TTYPERM         0600
ERASECHAR       0177
KILLCHAR        025
UMASK           022
PASS_MAX_DAYS   99999
PASS_MIN_DAYS   0
PASS_WARN_AGE   7
UID_MIN                  1000
UID_MAX                 60000
GID_MIN                  1000
GID_MAX                 60000
LOGIN_RETRIES           5
LOGIN_TIMEOUT           60
```

</details>


#### 🟡 Ejercicio 10.50 · UID_MIN, UID_MAX, GID_MIN, GID_MAX

Muestra de `/etc/login.defs` las cuatro líneas que definen el rango de IDs de usuarios y grupos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(UID|GID)_(MIN|MAX)' /etc/login.defs
```

_Resultado:_

```text
UID_MIN                  1000
UID_MAX                 60000
GID_MIN                  1000
GID_MAX                 60000
```


Una alternativa dentro de otra: `(UID|GID)` y `(MIN|MAX)`: 2 × 2 = 4 combinaciones.
</details>


#### 🟡 Ejercicio 10.51 · Opciones del kernel en GRUB

Muestra las líneas **activas** de `/etc/default/grub` que empiezan por `GRUB_CMDLINE`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^GRUB_CMDLINE' /etc/default/grub
```

_Resultado:_

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
```

</details>


#### 🔴 Ejercicio 10.52 · Directivas `yes` de sshd

Muestra las directivas **activas** de `/etc/ssh/sshd_config` cuyo valor sea `yes`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^#].*[[:space:]]yes$' /etc/ssh/sshd_config
```

_Resultado:_

```text
PubkeyAuthentication yes
UsePAM yes
X11Forwarding yes
```


`^[^#]` descarta los comentarios; `.*[[:space:]]yes$` exige que acabe en ` yes`.
</details>


#### 🔴 Ejercicio 10.53 · Directivas comentadas con valor por defecto

Muestra las directivas de `/etc/ssh/sshd_config` que están **comentadas** pero son una opción real (`#` seguido de una letra mayúscula, sin espacio), con su número de línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -nE '^#[A-Z]' /etc/ssh/sshd_config | head -8
```

_Resultado:_

```text
6:#Port 22
7:#AddressFamily any
8:#ListenAddress 0.0.0.0
9:#ListenAddress ::
11:#HostKey /etc/ssh/ssh_host_rsa_key
12:#HostKey /etc/ssh/ssh_host_ecdsa_key
13:#HostKey /etc/ssh/ssh_host_ed25519_key
16:#SyslogFacility AUTH
```


`^#[A-Z]` = comentario sin espacio seguido de mayúscula: así se escriben las opciones desactivadas. Los comentarios "de texto" suelen llevar un espacio tras la `#`.
</details>


#### 🔴 Ejercicio 10.54 · Quién se puede conectar

Muestra los **nombres de usuario** permitidos en `AllowUsers` de `/etc/ssh/sshd_config`, uno por línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^AllowUsers' /etc/ssh/sshd_config | cut -d' ' -f2- | tr ' ' '\n'
```

_Resultado:_

```text
alumno
ana
luis
```


`grep` localiza la línea, `cut -d' ' -f2-` quita la primera palabra y `tr` pone un nombre por línea. (Con `-P` y `\K` podría hacerse más corto: capítulo 13.)
</details>


---

## ✅ Resumen del capítulo 10

| Para… | Receta |
|---|---|
| Llegar al **campo N** de un fichero con `:` | `^([^:]*:){N-1}` + patrón del campo |
| Extraer el **primer campo** | `grep -o '^[^:]*'` |
| Extraer el **último campo** | `grep -o '[^:]*$'` |
| Dos campos iguales (UID = GID) | `^[^:]*:[^:]*:([0-9]+):\1:` |
| UID / GID **≥ 50** | `([5-9][0-9]\|[0-9]{3,})` |
| Un miembro dentro de una lista con comas | `(:\|,)nombre(,\|$)` |
| Limpiar comentarios y vacías | `grep -Ev '^[[:space:]]*(#\|$)'` |
| Reordenar campos | `sed -E 's/…/\1:\2/'` (capítulo 14) |

➡️ **Siguiente parada:** [Capítulo 11](11-logs.md): los registros del sistema: `syslog`, `auth.log`, `dpkg.log`… con fechas, horas, IPs y mucho más.

---
⬅️ [Capítulo 9 · Todas las opciones de `grep` (y los flujos de la terminal)](09-opciones-de-grep.md) · 🏠 [Índice](README.md)
