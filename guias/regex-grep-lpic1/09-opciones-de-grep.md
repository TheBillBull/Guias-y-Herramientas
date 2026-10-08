# Capítulo 9 · Todas las opciones de `grep` (y los flujos de la terminal)

> 🎯 **Objetivo:** conocer **todas las opciones útiles** de `grep` para no necesitar casi nunca un segundo comando, y entender los **tres canales** (`stdin`, `stdout`, `stderr`) que explican `|`, `>` y `2>`.
>
> 📘 **LPIC-1:** 103.7 (`grep`) y 103.4 (flujos, tuberías y redirecciones).
>
> 🧪 `cd ~/lab-regex`

---

## 9.1 · El mapa de las opciones

`grep` tiene muchas opciones, pero se agrupan en familias:

| Familia | Opciones | Para qué |
|---|---|---|
| **Cómo interpretar el patrón** | `-E` `-F` `-G` `-P` `-i` `-w` `-x` `-e` `-f` | qué sabor, mayúsculas, palabra/línea entera, varios patrones |
| **Qué líneas mostrar** | `-v` `-m NUM` | invertir, limitar |
| **Qué enseñar de cada línea** | `-o` `-c` `-l` `-L` `-q` `-s` | solo lo coincidente, contar, nombres, silencio |
| **Prefijos** | `-n` `-b` `-H` `-h` `-T` `--label` | número de línea, byte, nombre de fichero |
| **Contexto** | `-A NUM` `-B NUM` `-C NUM` `-NUM` | líneas de alrededor |
| **Qué ficheros mirar** | `-r` `-R` `--include` `--exclude` `--exclude-dir` `-a` `-I` | carpetas, filtros por nombre, binarios |
| **Color** | `--color=auto/always/never` | resaltar coincidencias |

Las de la primera fila ya las conoces. Vamos a por el resto.

---

## 9.2 · `-o`: solo lo que coincide

Sin `-o`, `grep` imprime la **línea entera**. Con `-o` (*only-matching*) imprime **solo el trozo** que coincide, **uno por línea**. Es la opción clave para **extraer** datos:

```bash
grep -o 'root' /etc/passwd
```

_Resultado:_

```text
root
root
root
```


Tres veces `root` en la misma línea → tres líneas de salida. Extraer todas las IPv4 "con forma de IP" de un log:

```bash
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' /var/log/auth.log | head -5
```

_Resultado:_

```text
0.0.0.0
192.168.1.50
203.0.113.45
203.0.113.45
203.0.113.45
```


(`([0-9]{1,3}\.){3}` = tres veces "1 a 3 dígitos y un punto", luego un bloque más: ¡un grupo repetido, capítulo 6!)

> 🧮 **`-c` cuenta líneas, no coincidencias.** Para contar **apariciones**, usa `-o` y cuenta con `wc -l`:

```bash
grep -c root /etc/passwd
grep -o root /etc/passwd | wc -l
```

_Resultado:_

```text
1
3
```


Una línea contiene `root`; hay 3 apariciones.

---

## 9.3 · `-m`, `-q`, `-s`: limitar y silenciar

**`-m NUM`**: **para** después de `NUM` coincidencias (rápido en ficheros enormes).

```bash
grep -m2 nologin /etc/passwd | cut -d: -f1
```

_Resultado:_

```text
daemon
bin
```


**`-q`** (*quiet*): **no imprime nada**; solo deja el **código de salida**. Es lo que se usa en las condiciones de los scripts (`0` = encontrado):

```bash
grep -q alumno /etc/passwd && echo "El usuario alumno existe"
grep -q fantasma /etc/passwd || echo "El usuario fantasma NO existe"
```

_Resultado:_

```text
El usuario alumno existe
El usuario fantasma NO existe
```


`&&` = "si el anterior salió bien, haz esto"; `||` = "si salió mal (código ≠ 0)…". En un script:

```bash
if grep -q '^alumno:' /etc/passwd; then
    echo "existe"
else
    echo "no existe"
fi
```

**`-s`** (*silent*): oculta los **errores** de ficheros inexistentes o ilegibles (pero el código de salida sigue siendo 2).

```bash
grep root /no/existe
grep -s root /no/existe
echo "código: $?"
```

_Resultado:_

```text
grep: /no/existe: No such file or directory
código: 2
```


---

## 9.4 · Contexto: `-A`, `-B`, `-C`

A veces la línea importante **no es suficiente**: quieres ver qué pasó **justo antes o después**. Con el contexto se ven las líneas de **alrededor**:

| Opción | Muestra |
|---|---|
| `-A N` (*after*) | la coincidencia y las **N líneas siguientes** |
| `-B N` (*before*) | las **N líneas anteriores** y la coincidencia |
| `-C N` o `-N` (*context*) | **N antes y N después** |

```bash
grep -A1 PermitRootLogin /etc/ssh/sshd_config
```

_Resultado:_

```text
PermitRootLogin no
#StrictModes yes
```


```bash
grep -B2 'Failed password for root' /var/log/auth.log | cut -c1-100
```

_Resultado_ (coincidencias entre « »):

```text
Nov  4 13:58:40 ubuntu-pc sshd[4344]: Invalid user oracle from 198.51.100.23 port 51100
Nov  4 13:58:42 ubuntu-pc sshd[1934]: Failed password for invalid user oracle from 198.51.100.23 por
Nov  4 14:02:11 ubuntu-pc sshd[3805]: «Failed password for root» from 198.51.100.23 p
Nov  4 14:02:14 ubuntu-pc sshd[5256]: «Failed password for root» from 198.51.100.23 p
```


Cuando hay varios grupos separados, `grep` los separa con una línea `--`:

```bash
grep -C1 'Accepted' /var/log/auth.log | cut -c1-80 | head -12
```

_Resultado:_

```text
Nov  4 08:55:08 ubuntu-pc sshd[6036]: Server listening on :: port 22.
Nov  4 09:02:10 ubuntu-pc sshd[3990]: Accepted publickey for alumno from 192.168
Nov  4 09:02:10 ubuntu-pc sshd[2210]: pam_unix(sshd:session): session opened for
--
Nov  4 18:01:50 ubuntu-pc sshd[2210]: pam_unix(sshd:session): session closed for
Nov  5 08:30:08 ubuntu-pc sshd[8497]: Accepted password for alumno from 192.168.
Nov  5 08:30:08 ubuntu-pc sshd[3010]: pam_unix(sshd:session): session opened for
--
Nov  5 10:02:50 ubuntu-pc sudo: luis : user NOT in sudoers ; TTY=pts/1 ; PWD=/ho
Nov  5 10:55:31 ubuntu-pc sshd[9180]: Accepted password for luis from 192.168.1.
Nov  5 10:55:31 ubuntu-pc sshd[3120]: pam_unix(sshd:session): session opened for
Nov  5 11:10:03 ubuntu-pc sshd[7743]: Failed password for luis from 192.168.1.51
```


(Y se cambia el separador con `--group-separator=TEXTO`, o se quita con `--no-group-separator`.)

---

## 9.5 · Prefijos: `-n`, `-b`, `-H`, `-h`, `-T`, `--label`

```bash
grep -n root /etc/passwd
```

_Resultado:_

```text
1:root:x:0:0:root:/root:/bin/bash
```


```bash
grep -ob root /etc/passwd
```

_Resultado:_

```text
0:root
11:root
17:root
```


`-b` da el **desplazamiento en bytes** (con `-o`, el de cada coincidencia). `-T` alinea con un tabulador. `-H`/`-h` fuerzan/ocultan el nombre del fichero. Para dar un "nombre" a la entrada estándar: `--label`.

```bash
echo hola | grep -H --label=entrada hola
```

_Resultado:_

```text
entrada:hola
```


---

## 9.6 · Buscar en carpetas: `-r`, `-R`, `--include`, `--exclude`, `--exclude-dir`

`-r` (*recursive*) recorre carpetas. Su gemela **`-R`** también **sigue enlaces simbólicos** (`-r` solo los sigue si están en la línea de comandos). Y con los filtros por **nombre de fichero** (son **comodines**, no regex: ¡entre comillas!):

| Opción | Hace |
|---|---|
| `--include='*.conf'` | solo mira ficheros que casen con el comodín |
| `--exclude='*.log'` | se salta esos ficheros |
| `--exclude-dir=ssh` | se salta esas carpetas |

```bash
grep -rl --include='*.conf' . /etc
```

_Resultado:_

```text
/etc/resolv.conf
/etc/nsswitch.conf
```


(Todos los `.conf` de `/etc`. Usamos el patrón `.` = "cualquier línea" solo para que liste los ficheros.)

```bash
grep -rl --exclude-dir=ssh --exclude='*.yaml' alumno /etc
```

_Resultado:_

```text
/etc/group
/etc/passwd
```


Ficheros que mencionan `alumno`, **sin** mirar en la carpeta `ssh` ni en los `.yaml`. Y contando por fichero:

```bash
grep -rc alumno /etc | grep -v ':0$'
```

_Resultado:_

```text
/etc/ssh/sshd_config:1
/etc/group:10
/etc/passwd:1
```


(Un segundo `grep -v ':0$'` oculta los ficheros con cero coincidencias; también valdría `grep -rl` si solo quieres los nombres.)

---

## 9.7 · Ficheros binarios: `-a`, `-I`

Si `grep` se encuentra bytes "raros" (un `NUL`), asume que es un **binario** y no imprime las líneas:

```bash
grep hola binario.bin
```

_Resultado:_

```text
grep: binario.bin: binary file matches
```


Dice "binary file matches" y listo. Para **forzar** que lo trate como texto: `-a`. Para **ignorarlo** del todo: `-I`.

```bash
grep -a hola binario.bin | cat -v
```

_Resultado:_

```text
cabecera^@^@datos binarios^@hola
```


(`cat -v` hace visibles los `NUL` como `^@`.)

---

## 9.8 · Color: `--color`

`--color=auto` (el que viene configurado en Ubuntu mediante un *alias*) pinta de **rojo** la coincidencia **si la salida va a una pantalla**; si va a una tubería o fichero, no. `--color=always` lo pinta **siempre** (útil para `less -R`). Lo que hay "por debajo" son códigos especiales:

```bash
grep --color=always root /etc/passwd | cat -v
```

_Resultado:_

```text
^[[01;31m^[[Kroot^[[m^[[K:x:0:0:^[[01;31m^[[Kroot^[[m^[[K:/^[[01;31m^[[Kroot^[[m^[[K:/bin/bash
```


Esos `^[[01;31m… ^[[m` son las órdenes de "ponte en rojo" y "vuelve al color normal". Por eso en tuberías **no** conviene `--color=always` (ensucia los datos).

---

## 9.9 · Los tres canales: `stdin`, `stdout`, `stderr`

Todo comando de Linux tiene **tres "tuberías" de comunicación**:

```text
              ┌─────────────┐
 teclado ───▶ │ 0  stdin    │
 / tubería    │             │ ───▶ 1  stdout ───▶ pantalla  (lo que sale bien)
              │   COMANDO   │
              │             │ ───▶ 2  stderr ───▶ pantalla  (los errores)
              └─────────────┘
```

| Canal | Número | Qué es | Por defecto |
|---|---|---|---|
| `stdin` | 0 | **entrada** | el teclado |
| `stdout` | 1 | **salida normal** | la pantalla |
| `stderr` | 2 | **salida de errores** | la pantalla (¡también!) |

Como errores y resultados salen por la misma pantalla, a veces se **mezclan**. Pero son canales **distintos** y se pueden desviar por separado:

| Símbolo | Significa |
|---|---|
| `>` | guarda `stdout` en un fichero (¡**sobrescribe**!) |
| `>>` | **añade** `stdout` al final del fichero |
| `2>` | guarda `stderr` en un fichero |
| `2>/dev/null` | **tira** los errores (`/dev/null` es un agujero negro) |
| `&>` o `> f 2>&1` | `stdout` **y** `stderr` al mismo fichero |
| `<` | usa un fichero como `stdin` |
| `\|` | `stdout` del primero → `stdin` del segundo |

```bash
grep root /etc/passwd /no/existe 2> /dev/null
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
```


La línea de `root` sale (stdout); el error por `/no/existe` desaparece (stderr, tirado). Y para repartirlos en dos ficheros:

```bash
grep root /etc/passwd /no/existe > salida.txt 2> errores.txt
echo "--- salida.txt:"; cat salida.txt
echo "--- errores.txt:"; cat errores.txt
```

_Resultado:_

```text
--- salida.txt:
/etc/passwd:root:x:0:0:root:/root:/bin/bash
--- errores.txt:
grep: /no/existe: No such file or directory
```


> 💡 En la vida real, `grep -r algo /etc 2>/dev/null` es muy común: **esconde los "Permission denied"** de los ficheros que tu usuario no puede leer, y te deja solo los resultados.

Y `tee` (como una "T" de fontanería) **guarda y muestra a la vez**:

```bash
grep nologin /etc/passwd | tee nologin.txt | wc -l
head -2 nologin.txt
```

_Resultado:_

```text
29
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
```


---

## 9.10 · Comprimidos: `zgrep`

Los logs antiguos se comprimen (`auth.log.2.gz`). No hace falta descomprimir: **`zgrep`** funciona como `grep` pero **lee `.gz`** (y existen `bzgrep` para `.bz2` y `xzgrep` para `.xz`). Lo mismo con `zcat`, `bzcat`, `xzcat` (que listan el contenido):

```bash
gzip -kc /var/log/auth.log > auth.log.2.gz
zgrep -c Failed auth.log.2.gz
zcat auth.log.2.gz | wc -l
```

_Resultado:_

```text
12
68
```


---

## 9.11 · Patrones y sabores, repaso rápido

Todo esto se combina entre sí. Algunas "frases" clásicas:

| Quiero… | Escribo |
|---|---|
| lo contrario de lo que busco | `grep -v` |
| líneas de A que **no** están en B (completas) | `grep -vxFf B A` |
| contar apariciones, no líneas | `grep -o … \| wc -l` |
| saber si existe (para un `if`) | `grep -q` |
| solo el trozo que coincide | `grep -o` |
| ver 3 líneas antes y después | `grep -C3` |
| ficheros que contienen algo | `grep -rl` |
| ficheros que **no** lo contienen | `grep -rL` |
| esconder los errores de permisos | `grep -r … 2>/dev/null` o `-s` |

---

## 9.12 · 🏋️ Ejercicios

#### 🟢 Ejercicio 9.1 · Cuántas veces `root`

¿Cuántas veces aparece la palabra `root` en `/etc/passwd`? (Cuenta **apariciones**, no líneas.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o root /etc/passwd | wc -l
```

_Resultado:_

```text
3
```


`-o` saca cada coincidencia en una línea y `wc -l` las cuenta. Con `-c` saldría 1, porque cuenta líneas.
</details>


#### 🟢 Ejercicio 9.2 · Solo el nombre

De la línea de `/etc/os-release` que contiene `VERSION_CODENAME`, extrae **solo** `VERSION_CODENAME` (no la línea entera).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o 'VERSION_CODENAME' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
«VERSION_CODENAME»
```

</details>


#### 🟢 Ejercicio 9.3 · Las dos primeras

Muestra las **2 primeras** líneas de `/etc/passwd` que contengan `bash`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -m2 bash /etc/passwd
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/bash
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/bash
```

</details>


#### 🟢 Ejercicio 9.4 · Con contexto

Muestra la línea de `/etc/ssh/sshd_config` que contiene `MaxAuthTries` y **la anterior y la siguiente**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -C1 MaxAuthTries /etc/ssh/sshd_config
# Otra forma equivalente:
grep -1 MaxAuthTries /etc/ssh/sshd_config
```

_Resultado:_

```text
#StrictModes yes
MaxAuthTries 3
#MaxSessions 10
```


`-C1` y `-1` significan lo mismo.
</details>


#### 🟢 Ejercicio 9.5 · Dos líneas antes

Muestra las 2 líneas **anteriores** a la que contiene `Raw_Read_Error_Rate` en `/var/log/syslog`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -B2 Raw_Read_Error_Rate /var/log/syslog | cut -c1-100
```

_Resultado:_

```text
Nov  4 09:47:14 ubuntu-pc systemd[1]: Started fstrim.service - Discard unused blocks on filesystems 
Nov  4 10:15:44 ubuntu-pc kernel: [4844.015600] usb 1-1: USB disconnect, device number 2
Nov  4 11:03:12 ubuntu-pc smartd[701]: Device: /dev/sda [SAT], SMART Prefailure Attribute: 1 Raw_Rea
```


Salen 3 líneas: las dos de antes y la coincidencia.
</details>


#### 🟢 Ejercicio 9.6 · ¿Existe el usuario?

Escribe una orden que diga `existe` si el usuario `alumno` está en `/etc/passwd`, sin imprimir las líneas del fichero.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -q '^alumno:' /etc/passwd && echo "existe"
```

_Resultado:_

```text
existe
```


`-q` no imprime nada; `&&` ejecuta el `echo` solo si `grep` encontró algo (código 0). El `^alumno:` evita coincidencias con otros usuarios que contengan "alumno".
</details>


#### 🟢 Ejercicio 9.7 · ¿Y si no existe?

Escribe una orden que diga `fantasma no existe` si no hay ningún usuario `fantasma`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -q '^fantasma:' /etc/passwd || echo "fantasma no existe"
```

_Resultado:_

```text
fantasma no existe
```


`||` ejecuta el `echo` solo si `grep` **no** encontró nada.
</details>


#### 🟢 Ejercicio 9.8 · Sin ruido de errores

Busca `root` en `/etc/passwd` y en un fichero inexistente `/no/existe`, pero **sin mostrar el error**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep root /etc/passwd /no/existe 2> /dev/null
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
```


`2> /dev/null` descarta `stderr`. (O bien `-s`, que oculta los errores de fichero.)
</details>


#### 🟢 Ejercicio 9.9 · Nombres con `-H`

Busca `root` en `/etc/passwd` mostrando **siempre** el nombre del fichero delante, aunque sea un solo fichero.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -H root /etc/passwd
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
```

</details>


#### 🟢 Ejercicio 9.10 · Dónde empieza (bytes)

Muestra el **byte** exacto donde empieza cada `root` de `/etc/passwd`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -ob root /etc/passwd
```

_Resultado:_

```text
0:root
11:root
17:root
```


`-o` imprime cada coincidencia; `-b` antepone su desplazamiento en bytes desde el inicio del fichero.
</details>


#### 🟡 Ejercicio 9.11 · Ficheros .conf

Lista los ficheros acabados en `.conf` de `/etc` que contengan la palabra `localhost` o `files`. *(Pista: `--include`, `-r`, `-l`, `-E`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -rlE --include='*.conf' 'localhost|files' /etc
```

_Resultado:_

```text
/etc/nsswitch.conf
```


`--include='*.conf'` filtra por nombre (con comodín, entre comillas) y el patrón `localhost|files` es una regex ERE.
</details>


#### 🟡 Ejercicio 9.12 · Todo menos SSH

Lista los ficheros de `/etc` que mencionan `alumno`, **sin** mirar dentro de la carpeta `ssh`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -rl --exclude-dir=ssh alumno /etc
```

_Resultado:_

```text
/etc/group
/etc/passwd
```

</details>


#### 🟡 Ejercicio 9.13 · Los ficheros sin "alumno"

Lista los ficheros `.conf` de `/etc` en los que **no** aparece `alumno`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -rL --include='*.conf' alumno /etc
```

_Resultado:_

```text
/etc/resolv.conf
/etc/nsswitch.conf
```


`-L` es lo contrario de `-l`.
</details>


#### 🟡 Ejercicio 9.14 · Contar por fichero

Muestra cuántas líneas con `Failed` tiene cada fichero `.log` de `/var/log`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c Failed /var/log/*.log
```

_Resultado:_

```text
/var/log/auth.log:12
/var/log/dpkg.log:0
/var/log/kern.log:0
/var/log/ufw.log:0
```


La terminal expande `*.log` y `grep -c` da un recuento por fichero.
</details>


#### 🟡 Ejercicio 9.15 · ¿Qué log contiene "sshd"?

Averigua en qué ficheros de `/var/log` (incluidas subcarpetas) aparece `sshd`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -rl sshd /var/log
```

_Resultado:_

```text
/var/log/auth.log
```


Solo `auth.log`: en Ubuntu, los mensajes de autenticación van a `auth.log` y **no** a `syslog`.
</details>


#### 🟡 Ejercicio 9.16 · El binario traicionero

Busca `hola` en `binario.bin`. Explica el mensaje y muestra cómo ver la línea igualmente.

<details>
<summary>💡 Ver solución</summary>


```bash
grep hola binario.bin
grep -a hola binario.bin | cat -v
```

_Resultado:_

```text
grep: binario.bin: binary file matches
cabecera^@^@datos binarios^@hola
```


`grep` detecta bytes `NUL` y avisa de que es un fichero binario en vez de volcar basura a la pantalla. Con `-a` se fuerza a tratarlo como texto (y `cat -v` hace visibles los `NUL` como `^@`).
</details>


#### 🟡 Ejercicio 9.17 · Ignorar binarios

Busca `hola` en `binario.bin` y en `poema.txt`… pero sin que `grep` considere el binario.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -I hola binario.bin poema.txt
echo "código: $?"
```

_Resultado:_

```text
código: 1
```


`-I` descarta los ficheros binarios (código 1 si nada coincide en el resto).
</details>


#### 🟡 Ejercicio 9.18 · El color y las tuberías

Muestra los códigos de color que `grep` añade con `--color=always` a la línea de `root`, y explica por qué es mala idea ponerlo si luego vas a procesar la salida con otro comando.

<details>
<summary>💡 Ver solución</summary>


```bash
grep --color=always root /etc/passwd | cat -v
```

_Resultado:_

```text
^[[01;31m^[[Kroot^[[m^[[K:x:0:0:^[[01;31m^[[Kroot^[[m^[[K:/^[[01;31m^[[Kroot^[[m^[[K:/bin/bash
```


`^[[01;31m` y `^[[m` son secuencias de escape que encienden/apagan el rojo. Si pasas esa salida a otro comando (`sort`, `cut`…), esos caracteres se mezclan con los datos y los estropean.
</details>


#### 🟡 Ejercicio 9.19 · Stdout y stderr por separado

Ejecuta `grep root /etc/passwd /no/existe` guardando lo bueno en `ok.txt` y los errores en `err.txt`. Muestra los dos ficheros.

<details>
<summary>💡 Ver solución</summary>


```bash
grep root /etc/passwd /no/existe > ok.txt 2> err.txt
echo "--- ok.txt:"; cat ok.txt
echo "--- err.txt:"; cat err.txt
```

_Resultado:_

```text
--- ok.txt:
/etc/passwd:root:x:0:0:root:/root:/bin/bash
--- err.txt:
grep: /no/existe: No such file or directory
```

</details>


#### 🟡 Ejercicio 9.20 · Guardar y ver

Cuenta cuántos usuarios `nologin` hay, **guardando** también la lista en `nologin.txt`. Todo en una sola línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep nologin /etc/passwd | tee nologin.txt | wc -l
```

_Resultado:_

```text
29
```


`tee` copia la entrada a un fichero **y** la deja pasar al siguiente comando.
</details>


#### 🟡 Ejercicio 9.21 · Los comprimidos

Crea una copia comprimida de `auth.log` llamada `auth.log.2.gz` y cuenta cuántas líneas con `Failed` tiene, **sin descomprimirla** a disco.

<details>
<summary>💡 Ver solución</summary>


```bash
gzip -kc /var/log/auth.log > auth.log.2.gz
zgrep -c Failed auth.log.2.gz
```

_Resultado:_

```text
12
```


`gzip -kc` escribe el comprimido en la salida estándar (que redirigimos); `zgrep` lo lee comprimido.
</details>


#### 🟡 Ejercicio 9.22 · Varias pistas, un fichero de patrones

Crea `buscar.txt` con las líneas `Failed` y `Invalid` y muestra, acortadas, las líneas de `auth.log` que contengan **cualquiera**.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'Failed\nInvalid\n' > buscar.txt
grep -F -f buscar.txt /var/log/auth.log | cut -c1-80 | head -6
```

_Resultado:_

```text
Nov  4 13:44:02 ubuntu-pc sshd[1672]: Failed password for invalid user admin fro
Nov  4 13:44:05 ubuntu-pc sshd[2205]: Failed password for invalid user admin fro
Nov  4 13:44:09 ubuntu-pc sshd[3446]: Failed password for invalid user admin fro
Nov  4 13:51:17 ubuntu-pc sshd[7778]: Invalid user test from 203.0.113.45 port 4
Nov  4 13:51:19 ubuntu-pc sshd[4461]: Failed password for invalid user test from
Nov  4 13:58:40 ubuntu-pc sshd[4344]: Invalid user oracle from 198.51.100.23 por
```

</details>


#### 🟡 Ejercicio 9.23 · TODO y FIXME

Lista, con número de línea, los comentarios `TODO` y `FIXME` de `programa.py`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -nE 'TODO|FIXME' programa.py
```

_Resultado_ (coincidencias entre « »):

```text
6:# «TODO»: validar argumentos
13:        print("Uso: programa.py NOMBRE")   # «FIXME»: mejorar mensaje
17:    # «TODO»: guardar log
```

</details>


#### 🟡 Ejercicio 9.24 · Solo el comentario

Extrae solo el texto de los comentarios (desde el `#` hasta el final de línea) de `programa.py`, **sin** la línea `#!/usr/bin/env python3`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '[[:space:]]#[^!].*' programa.py
```

_Resultado:_

```text
 # saludo
 # FIXME: mejorar mensaje
 # TODO: guardar log
```


`[[:space:]]#[^!]` pide un espacio, luego `#`, luego un carácter que no sea `!` (para saltarse el *shebang*), y `.*` hasta el final. (Los comentarios que empiezan en la columna 1 —como `# Programa…`— no salen aquí porque necesitan un espacio previo; con `^#` o `(^|[[:space:]])#` se arreglaría.)
</details>


#### 🔴 Ejercicio 9.25 · Diferencia de conjuntos

Muestra las shells que aparecen en `/etc/passwd` (7.º campo) pero **no están listadas** en `/etc/shells`. *(Pista: `cut`, `sort -u`, y `grep -vxFf`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f7 /etc/passwd | sort -u | grep -vxFf /etc/shells
```

_Resultado:_

```text
/bin/false
/bin/sync
/usr/sbin/nologin
```


Se extraen las shells (`cut`), sin repetir (`sort -u`), y de ellas se descartan (`-v`) las que coinciden **exactamente** (`-x`), como texto fijo (`-F`), con alguna línea de `/etc/shells` (`-f`). Quedan las "shells" que no son de inicio de sesión: `/bin/false`, `/bin/sync` y `/usr/sbin/nologin`.
</details>


#### 🔴 Ejercicio 9.26 · Un solo fichero grande vs varios

Cuenta cuántas líneas **no vacías** tiene `/etc/ssh/sshd_config`, de dos formas: con `grep -c` y con `grep -v` + `wc`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c . /etc/ssh/sshd_config
# Otra forma equivalente:
grep -v '^$' /etc/ssh/sshd_config | wc -l
```

_Resultado:_

```text
31
```


Un solo `grep -c .` evita el segundo comando (`.` exige al menos un carácter).
</details>


#### 🔴 Ejercicio 9.27 · Tubería a medida

Muestra solo los **5 usuarios con shell `bash`** (la línea acaba en `bash`) **ordenados alfabéticamente por nombre**, mostrando solo el nombre. *(Pista: `grep`, `cut`, `sort`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'bash$' /etc/passwd | cut -d: -f1 | sort
```

_Resultado:_

```text
alumno
ana
pedro
postgres
root
```


`grep` filtra, `cut -d: -f1` se queda con el primer campo y `sort` ordena. Un clásico de las "tuberías" (LPIC 103.2).
</details>


#### ⚫ Ejercicio 9.28 · Cuántos "Failed" por IP

Escribe el **ranking de IPs** con más intentos fallidos de contraseña en `auth.log`: IP y número de intentos, de mayor a menor. *(Pista: `grep -o`, `sort`, `uniq -c`, `sort -rn`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'Failed password' /var/log/auth.log | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      5 203.0.113.45
      3 203.0.113.99
      3 198.51.100.23
      1 192.168.1.51
```


`grep 'Failed password'` selecciona las líneas; el 2.º `grep -o` extrae cada IP; `sort | uniq -c` las cuenta; `sort -rn` ordena de más a menos. (Un solo `grep` lo haría con `-P`; capítulo 13.)
</details>


---

## ✅ Resumen del capítulo 9

| Opción | Qué hace |
|---|---|
| `-o` | solo la parte que coincide (una por línea) |
| `-c` | cuenta **líneas** |
| `-l` / `-L` | solo nombres de ficheros con / sin coincidencias |
| `-q` | silencio; solo el código de salida |
| `-s` | oculta errores de ficheros |
| `-m N` | para tras N coincidencias |
| `-A N` `-B N` `-C N` | contexto después / antes / alrededor |
| `-n` `-b` `-H` `-h` `-T` | prefijos |
| `-r` `-R` | recursivo (sin / con enlaces simbólicos) |
| `--include` `--exclude` `--exclude-dir` | filtros por nombre (comodines) |
| `-a` / `-I` | tratar binarios como texto / ignorarlos |
| `--color=always` | color aunque no sea pantalla |

**Canales:** `stdin` (0), `stdout` (1), `stderr` (2). `>` sobrescribe, `>>` añade, `2>` errores, `2>/dev/null` tira los errores, `|` conecta, `tee` guarda y deja pasar.

➡️ **Siguiente parada:** [Capítulo 10](10-ficheros-del-sistema.md): ahora sí, a **trabajar con `/etc/passwd`, `/etc/group`** y otros ficheros del sistema con todo lo aprendido.

---
⬅️ [Capítulo 8 · BRE contra ERE: `grep`, `egrep`, `fgrep` (¡y `-P`!)](08-bre-vs-ere.md) · 🏠 [Índice](README.md) · [Capítulo 10 · Los ficheros del sistema: `passwd`, `group`, `fstab`, `hosts`…](10-ficheros-del-sistema.md) ➡️
