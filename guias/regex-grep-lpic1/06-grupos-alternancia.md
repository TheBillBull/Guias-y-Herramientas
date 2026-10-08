# Capítulo 6 · Grupos, alternativas y memoria: `( )` `|` `\1`

> 🎯 **Objetivo:** agrupar trozos del patrón, elegir entre alternativas ("esto **o** aquello") y hacer que `grep` **recuerde** lo que acaba de encontrar para volver a buscarlo ("la misma letra otra vez").
>
> 📘 **LPIC-1:** 103.7 — *grouping, alternation, back-references*; diferencia entre BRE y ERE.
>
> 🧪 `cd ~/lab-regex`

---

## 6.1 · Los paréntesis: meter cosas en una bolsa

En el capítulo 5 aprendiste que un cuantificador (`*`, `+`, `{n}`) se aplica **solo al elemento anterior**: `ab*` es una `a` seguida de cero o más `b`.

Pero ¿y si quieres repetir **dos letras juntas**? Los **paréntesis** agrupan varios elementos en **una sola "bolsa"**, y así el cuantificador afecta a **toda la bolsa**:

```text
ab*      →  a  +  (b repetida)             →  a, ab, abb, abbb…
(ab)*    →  (ab repetido)                  →  nada, ab, abab, ababab…
(ab)+    →  ab  una o más veces            →  ab, abab, ababab…
(ha){3}  →  ha  tres veces                 →  hahaha
```

```bash
printf 'ab\nabab\nabb\nhahaha\nhaha\n' | grep -E '^(ab)+$'
```

_Resultado_ (coincidencias entre « »):

```text
«ab»
«abab»
```


Solo `ab` y `abab` (el patrón pide el bloque `ab` repetido y nada más; `abb` no es `ab` repetido).

```bash
printf 'hahaha\nhaha\nhahahaha\n' | grep -E '^(ha){3}$'
```

_Resultado_ (coincidencias entre « »):

```text
«hahaha»
```


### ¡Cuidado con las barras! (BRE vs ERE, otra vez)

| | **BRE** (`grep` normal) | **ERE** (`grep -E`) |
|---|---|---|
| agrupar | `\(` `\)` | `(` `)` |

```bash
printf 'ab\nabab\nabb\n' | grep '^\(ab\)\+$'
# Otra forma equivalente:
printf 'ab\nabab\nabb\n' | grep -E '^(ab)+$'
```

_Resultado_ (coincidencias entre « »):

```text
«ab»
«abab»
```


Mismo resultado, escritura distinta. Verás que **en ERE se lee mucho mejor**, por eso el resto del capítulo usa `-E`. Pero **el examen LPIC-1 pregunta las dos**.

> 🧠 Los paréntesis tienen **dos trabajos**: **(1) agrupar** para aplicar un cuantificador o una alternativa, y **(2) capturar** (guardar en memoria) lo que han encontrado, para usarlo con `\1`, `\2`… (sección 6.4).

---

## 6.2 · La alternativa `|`: "esto O aquello"

La **barra vertical** `|` (tecla `AltGr` + `1` en teclado español) significa **"O"**:

```text
gato|perro    →  "gato" o "perro"
```

| | BRE | ERE |
|---|---|---|
| alternativa | `\|` (extensión GNU) | `|` |

```bash
grep -E 'gato|perro' palabras.txt
# Otra forma equivalente:
grep 'gato\|perro' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gato»s
«perro»
«gato»
```


*(Ya vimos otra forma de "O": `-e gato -e perro`. Todas son equivalentes; la ventaja de `|` es que puede ir **dentro** de un patrón más grande.)*

### ⚠️ Trampa: la alternativa es lo que **menos manda**

`|` tiene la **menor prioridad** de todo: parte el patrón completo en dos. Mira:

```text
^gato|perro$     NO significa  "la línea es gato o perro"
                 SINO:         "(empieza por gato)  O  (acaba en perro)"
```

Lo comprobamos con cinco líneas de prueba. Queremos que solo pasen las líneas que **son exactamente** `gato` o `perro`:

```bash
printf 'gato\nperro\ngatos\nxperro\ngatoperro\n' | grep -E '^gato|perro$'
```

_Resultado:_

```text
gato
perro
gatos
xperro
gatoperro
```


¡Han pasado **todas**! `gatos` pasa porque empieza por `gato`; `xperro` porque acaba en `perro`; `gatoperro` por las dos cosas. Lo que queríamos ("la línea ENTERA es `gato` o `perro`") exige **paréntesis**:

```bash
printf 'gato\nperro\ngatos\nxperro\ngatoperro\n' | grep -E '^(gato|perro)$'
```

_Resultado:_

```text
gato
perro
```


Ahora solo pasan `gato` y `perro`, que es lo correcto: `^( … )$` pone el "o" **dentro** de las anclas.

**Regla:** si usas `|` dentro de un patrón más grande, **ponlo entre paréntesis**.

### Alternativas con `-v`, anclas y todo junto

Con lo que sabes ya puedes **limpiar un fichero de configuración en un solo patrón**: quitar líneas vacías, con espacios, y comentarios con `#` o `;` (aunque estén sangrados):

```bash
grep -Ev '^[[:space:]]*(#|;|$)' conf-ejemplo.conf
```

_Resultado:_

```text
[servidor]
puerto = 8080
host=localhost
debug = true
[base_datos]
usuario = admin
clave = s3creta
host = 192.168.1.50
puerto=5432
[correo]
smtp = smtp.ejemplo.com
puerto = 587
remitente = noreply@ejemplo.com
```


Desmontamos el patrón:

- `^` → principio de línea.
- `[[:space:]]*` → cero o más espacios/tabuladores.
- `(#|;|$)` → …y a continuación **o** un `#`, **o** un `;`, **o** el final de línea (línea vacía o de solo espacios).
- `-v` → quédate con las que **no** cumplan eso.

> 🏅 **Esta es la versión "master" de la limpieza de ficheros de configuración.** Es el clásico para quitar ruido a `sshd_config`, `/etc/fstab`, etc.

---

## 6.3 · Alternativas para rangos de números

Los corchetes solo valen para **un carácter**. Para describir números con varios dígitos y rangos irregulares hay que **combinar alternativas**. Un ejemplo muy típico: **las horas de 00 a 23**:

```text
([01][0-9]|2[0-3])
```

- `[01][0-9]` → 00 a 19.
- `2[0-3]` → 20 a 23.

Y los **minutos** (00 a 59): `[0-5][0-9]`. Una hora completa:

```bash
grep -E '^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$' fechas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«23:59:59»
«00:00»
```


Salen `23:59:59` y `00:00`. Quedan fuera `24:00`, `12:60`, `9:05` (le falta el 0). Fíjate en el `(:[0-5][0-9])?`: un **grupo opcional** para los segundos.

### El número del 0 al 255 (la pieza clave de las IPv4)

Cada trozo de una IPv4 vale de 0 a 255. Hay que partirlo por casos:

| Rango | Patrón |
|---|---|
| 250–255 | `25[0-5]` |
| 200–249 | `2[0-4][0-9]` |
| 100–199 | `1[0-9]{2}` |
| 0–99 | `[1-9]?[0-9]` |

Todo junto: `(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])`. ¿Funciona? Vamos a **demostrarlo** generando los números 0 a 300 con `seq` y contando cuántos pasan:

```bash
seq 0 300 | grep -cE '^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'
```

_Resultado:_

```text
256
```


**256** (justo los números 0, 1, …, 255). Perfecto. Y el último que pasa:

```bash
seq 0 300 | grep -E '^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$' | tail -1
```

_Resultado:_

```text
255
```


Este patrón lo usaremos en el capítulo 12 para validar IPs de verdad.

---

## 6.4 · La memoria: referencias hacia atrás `\1`, `\2`…

Esta es la parte más "mágica" de este capítulo.

Cuando escribes un grupo `(…)`, `grep` **apunta en su libreta** lo que ese grupo ha encontrado. Y luego puedes **pedirle que lo repita**:

| Escribo | Significa |
|---|---|
| `\1` | "lo mismo que encontró el **primer** grupo" |
| `\2` | "lo mismo que el **segundo** grupo" |
| … hasta `\9` | |

(Los grupos se numeran por la **posición del paréntesis de apertura**, de izquierda a derecha.)

### Ejemplo: letras dobles

`(.)\1` = "un carácter cualquiera, **y luego ese mismo carácter otra vez**":

```bash
grep -E '(.)\1' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
pe«rr»o
Pe«rr»o
pe«rr»a
pe«rr»ito
si«ll»a
si«ll»ón
h«oo»la
h«oo»ola
«aa»a
«aa»
mi«ss»i«ss»i«pp»i
```


Palabras con **dos letras iguales seguidas**: `perro` (rr), `silla` (ll), `hoola` (oo), `aaa`, `mississippi` (ss, ss, pp)… Sin `\1`, `(.).` valdría para cualquier par.

Y tres iguales seguidas:

```bash
grep -E '(.)\1\1' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
h«ooo»la
«aaa»
```


### Ejemplo: palíndromos (¡se leen igual al revés!)

- De 4 letras: `^(.)(.)\2\1$` → `a b b a`.
- De 5 letras: `^(.)(.).\2\1$` → `r a d a r`.

```bash
grep -hE '^(.)(.)\2\1$' repetidas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«anna»
«abba»
«otto»
```


```bash
grep -hE '^(.)(.).\2\1$' palabras.txt repetidas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«radar»
«rotor»
«abcba»
«radar»
```


Y para jugar en serio, el palíndromo de 9 letras (`reconocer`):

```bash
grep -E '^(.)(.)(.)(.).\4\3\2\1$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«reconocer»
```


### Ejemplo: algo repetido dos veces

`^(.+)\1$` = "la línea entera es un trozo repetido dos veces":

```bash
grep -hE '^(.+)\1$' repetidas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«abcabc»
«123123»
```


`abcabc` (`abc`+`abc`) y `123123` (`123`+`123`).

### Ejemplo: empieza y acaba con la misma letra

```bash
grep -E '^(.).*\1$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ala»
«oso»
«ojo»
«reconocer»
«anilina»
«radar»
«rotor»
«aaa»
«aa»
```


### Ejemplo: etiquetas HTML que abren y cierran **igual**

```bash
grep -E '<([a-z0-9]+)[^>]*>.*</\1>' html.txt
```

_Resultado_ (coincidencias entre « »):

```text
«<h1>Titulo principal</h1>»
«<p>Un parrafo con <b>negrita</b> y <i>cursiva</i> dentro.</p>»
«<a href="https://www.ejemplo.com">Enlace uno</a> y <a href="http://otro.org/pagina">Enlace dos</a>»
```


`<h1>…</h1>`, `<p>…</p>`, `<a …>…</a>`: la etiqueta de cierre coincide con la de apertura. (Si fuera `<b>…</i>` no valdría.)

### 🪤 Trampa: palabras repetidas ("el el")

Parece fácil: `([a-z]+) \1` = "una palabra, un espacio y la misma palabra". Pero…

```bash
grep -inE '([a-z]+) \1' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
2:El gato duerm«e e»n el sofá.
4:¿Dónd«e e»stá la biblioteca?
8:«El el» perro ladra mucho.
9:Voy «a a» la playa.
15:la linea en minuscula«s s»in punto final
17:   Esta fras«e e»mpieza con tr«es es»pacios.
```


¡Ha cazado 6 líneas, y solo 2 tienen palabras repetidas de verdad (`El el`, `a a`)! Las demás son falsos positivos: en "duerme **e**n **e**l" el trozo `e e` aparece **a medio camino entre dos palabras**. Para exigir "palabra completa" necesitamos **límites de palabra** (`\b`, capítulo 7), donde lo arreglaremos.

> 🧠 Las referencias hacia atrás `\1` son muy potentes, pero **no existen en todos los sabores** de regex y las definiciones POSIX para *extendidas* no las incluyen (GNU `grep -E` sí las acepta). Las **básicas** (`BRE`) siempre las incluyen.

---

## 6.5 · 🏋️ Ejercicios

#### 🟢 Ejercicio 6.1 · Gato o perro

Muestra las líneas de `palabras.txt` que contengan `gato` o `perro` usando una sola alternativa (`|`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'gato|perro' palabras.txt
# Otra forma equivalente:
grep 'gato\|perro' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gato»s
«perro»
«gato»
```


La primera es ERE (`|`), la segunda BRE (`\|`).
</details>


#### 🟢 Ejercicio 6.2 · Tres opciones, línea completa

Muestra las líneas de `palabras.txt` que sean **exactamente** `ala`, `oso` u `ojo`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(ala|oso|ojo)$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ala»
«oso»
«ojo»
```


Paréntesis imprescindibles: sin ellos `^ala|oso|ojo$` significaría "empieza por ala, o contiene oso, o acaba en ojo".
</details>


#### 🟢 Ejercicio 6.3 · Las tres Linux

Muestra las líneas de `palabras.txt` que sean exactamente `Linux`, `linux` o `LINUX`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(Linux|linux|LINUX)$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«Linux»
«linux»
«LINUX»
```


(Para esto también bastaba `grep -ix linux palabras.txt`, pero así practicas la alternativa.)
</details>


#### 🟢 Ejercicio 6.4 · Bloque que se repite

Muestra las líneas de `printf 'hahaha\nhaha\nhahahaha\nha\n'` formadas **solo** por `ha` repetido **tres o más veces**.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'hahaha\nhaha\nhahahaha\nha\n' | grep -E '^(ha){3,}$'
```

_Resultado_ (coincidencias entre « »):

```text
«hahaha»
«hahahaha»
```


`(ha){3,}` = el bloque `ha` repetido 3 veces o más (la coma sin máximo = "sin tope").
</details>


#### 🟢 Ejercicio 6.5 · Shells bash o zsh

Muestra los usuarios de `/etc/passwd` cuya shell sea `/bin/bash` **o** `/bin/zsh` (línea acabada en cualquiera de ellas).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E ':/bin/(bash|zsh)$' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
root:x:0:0:root:/root«:/bin/bash»
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql«:/bin/bash»
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno«:/bin/bash»
ana:x:1001:1001:Ana Garcia,,,:/home/ana«:/bin/bash»
luis:x:1002:1002:Luis Perez,,,:/home/luis«:/bin/zsh»
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro«:/bin/bash»
```

</details>


#### 🟢 Ejercicio 6.6 · Shells que no dejan entrar

Cuenta los usuarios de `/etc/passwd` cuya shell acaba en `nologin` **o** en `false`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '(nologin|false)$' /etc/passwd
```

_Resultado:_

```text
33
```


La barra `|` está dentro del paréntesis para que el `$` afecte a las dos opciones.
</details>


#### 🟢 Ejercicio 6.7 · Sesiones y sudo

Cuenta las líneas de `auth.log` que mencionan `sshd` **o** `sudo`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE 'sshd|sudo' /var/log/auth.log
```

_Resultado:_

```text
51
```

</details>


#### 🟢 Ejercicio 6.8 · Aceptado o fallido

Muestra, sin los PIDs (con `cut -c1-80`), las líneas de `auth.log` con `Accepted` o `Failed`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'Accepted|Failed' /var/log/auth.log | cut -c1-80
```

_Resultado:_

```text
Nov  4 09:02:10 ubuntu-pc sshd[3990]: Accepted publickey for alumno from 192.168
Nov  4 13:44:02 ubuntu-pc sshd[1672]: Failed password for invalid user admin fro
Nov  4 13:44:05 ubuntu-pc sshd[2205]: Failed password for invalid user admin fro
Nov  4 13:44:09 ubuntu-pc sshd[3446]: Failed password for invalid user admin fro
Nov  4 13:51:19 ubuntu-pc sshd[4461]: Failed password for invalid user test from
Nov  4 13:58:42 ubuntu-pc sshd[1934]: Failed password for invalid user oracle fr
Nov  4 14:02:11 ubuntu-pc sshd[3805]: Failed password for root from 198.51.100.2
Nov  4 14:02:14 ubuntu-pc sshd[5256]: Failed password for root from 198.51.100.2
Nov  5 08:30:08 ubuntu-pc sshd[8497]: Accepted password for alumno from 192.168.
Nov  5 10:55:31 ubuntu-pc sshd[9180]: Accepted password for luis from 192.168.1.
Nov  5 11:10:03 ubuntu-pc sshd[7743]: Failed password for luis from 192.168.1.51
Nov  5 11:10:07 ubuntu-pc sshd[7397]: Accepted password for luis from 192.168.1.
Nov  5 15:12:33 ubuntu-pc sshd[5556]: Failed password for invalid user postgres 
Nov  5 15:12:36 ubuntu-pc sshd[5161]: Failed password for invalid user postgres 
Nov  5 15:12:38 ubuntu-pc sshd[2824]: Failed password for invalid user ubuntu fr
Nov  6 07:59:10 ubuntu-pc sshd[3801]: Accepted publickey for ana from 192.168.1.
Nov  6 09:15:42 ubuntu-pc sshd[9239]: Failed password for invalid user admin fro
```

</details>


#### 🟢 Ejercicio 6.9 · Protocolos

Muestra las URLs de `urls.txt` que empiecen por `ftp://`, `http://` **o** `https://`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(ftp|https?)://' urls.txt
```

_Resultado_ (coincidencias entre « »):

```text
«http://»www.ejemplo.com
«https://»www.ejemplo.com/
«https://»cas-training.com/cursos/linux?id=5&lang=es
«ftp://»ftp.ubuntu.com/pub/
«http://»localhost:8080/index.html
«https://»192.168.1.10:8443/admin
«https://»ejemplo.com/ruta con espacios
```


`https?` = http + una s opcional; el grupo permite combinarlo con `ftp`.
</details>


#### 🟢 Ejercicio 6.10 · Peticiones POST o HEAD

Muestra (acortadas) las peticiones **POST o HEAD** de `access.log`. *(Pista: el método va entre comillas, justo después de `"`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '"(POST|HEAD) ' /var/log/apache2/access.log | cut -c1-100
```

_Resultado:_

```text
192.0.2.15 - - [14/Oct/2024:10:05:36 +0200] "POST /login HTTP/1.1" 200 1234 "https://www.ejemplo.com
198.51.100.7 - - [14/Oct/2024:10:06:08 +0200] "POST /login HTTP/1.1" 302 1234 "https://www.ejemplo.c
203.0.113.10 - - [14/Oct/2024:10:06:38 +0200] "POST /login HTTP/1.1" 401 1234 "https://www.ejemplo.c
192.168.1.51 - - [14/Oct/2024:10:09:16 +0200] "HEAD / HTTP/1.1" 200 - "-" "curl/8.5.0"
203.0.113.10 - - [14/Oct/2024:10:10:02 +0200] "POST /login HTTP/1.1" 302 1234 "https://www.ejemplo.c
198.51.100.7 - - [14/Oct/2024:10:11:32 +0200] "HEAD / HTTP/1.1" 200 - "-" "curl/8.5.0"
203.0.113.10 - - [14/Oct/2024:10:16:20 +0200] "HEAD / HTTP/1.1" 200 - "-" "curl/8.5.0"
192.168.1.50 - - [14/Oct/2024:10:16:50 +0200] "HEAD / HTTP/1.1" 200 - "-" "curl/8.5.0"
203.0.113.45 - - [14/Oct/2024:10:31:08 +0200] "POST /login HTTP/1.1" 401 1234 "-" "python-requests/2
```


La comilla `"` evita coger la palabra `POST` o `HEAD` en cualquier otro sitio.
</details>


#### 🟡 Ejercicio 6.11 · Config limpia en un solo comando

Muestra `/etc/ssh/sshd_config` sin comentarios (también los sangrados) y sin líneas vacías ni en blanco, con **un solo** `grep` y **un solo** patrón.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ev '^[[:space:]]*(#|$)' /etc/ssh/sshd_config
```

_Resultado:_

```text
Include /etc/ssh/sshd_config.d/*.conf
PermitRootLogin no
MaxAuthTries 3
PubkeyAuthentication yes
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
AllowUsers alumno ana luis
```


`^[[:space:]]*(#|$)` = "principio, espacios opcionales y luego un `#` o el final". Y `-v` descarta eso.
</details>


#### 🟡 Ejercicio 6.12 · Limpiando /etc/fstab

Muestra las entradas **reales** de `/etc/fstab` (sin comentarios ni vacías).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ev '^[[:space:]]*(#|$)' /etc/fstab
```

_Resultado:_

```text
UUID=3f5a9c1e-7b2d-4e8a-9c01-5d6e7f8a9b0c /               ext4    errors=remount-ro 0       1
UUID=A1B2-C3D4  /boot/efi       vfat    umask=0077      0       1
/swapfile                                 none            swap    sw              0       0
/dev/sdb1       /datos          ext4    defaults        0       2
/dev/sdc1       /backup         xfs     defaults,noatime 0      2
//nas/compartido /mnt/nas       cifs    credentials=/root/.cred,uid=1000 0 0
tmpfs           /tmp            tmpfs   defaults,size=2G 0      0
```

</details>


#### 🟡 Ejercicio 6.13 · Config con `;` y `#`

Cuenta las líneas "de verdad" de `conf-ejemplo.conf` (sin comentarios `#` ni `;`, sin vacías ni en blanco).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cEv '^[[:space:]]*(#|;|$)' conf-ejemplo.conf
```

_Resultado:_

```text
13
```


13 líneas de configuración. Las opciones `-c`, `-E` y `-v` se pueden juntar (`-cEv`).
</details>


#### 🟡 Ejercicio 6.14 · Trampa de la prioridad

Predice y comprueba qué líneas de `gato`, `perro`, `gatos`, `xperro`, `gatoperro` coinciden con `^gato|perro$`, y con `^(gato|perro)$`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'gato\nperro\ngatos\nxperro\ngatoperro\n' | grep -E '^gato|perro$'
echo ---
printf 'gato\nperro\ngatos\nxperro\ngatoperro\n' | grep -E '^(gato|perro)$'
```

_Resultado:_

```text
gato
perro
gatos
xperro
gatoperro
---
gato
perro
```


Sin paréntesis el patrón es **(`^gato`) O (`perro$`)**: pasan todas (`gatos` empieza por gato, `xperro` acaba en perro…). Con paréntesis es "(`gato` o `perro`) ocupando toda la línea": solo `gato` y `perro`. La alternativa tiene la **prioridad más baja**.
</details>


#### 🟡 Ejercicio 6.15 · Horas de la mañana en una sola línea

Muestra las líneas de `/var/log/syslog` del 5 de noviembre entre las 08:00 y las 12:59, con **un solo patrón**, y cuéntalas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^Nov  5 (0[89]|1[0-2]):' /var/log/syslog
```

_Resultado:_

```text
21
```


Sale 21 (las mismas que el ejercicio 4.34, pero ahora con un solo patrón en vez de dos `-e`).
</details>


#### 🟡 Ejercicio 6.16 · Fecha con formato correcto (nivel 1)

En `fechas.txt` muestra las fechas con forma `dd/mm/aaaa` donde `dd` esté entre 00 y 39, `mm` entre 00 y 19 y `aaaa` sean 4 dígitos. *(Este patrón es "flojo" a propósito.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-3][0-9]/[01][0-9]/[0-9]{4}$' fechas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«15/03/2024»
«31/12/1999»
«01/01/2000»
«32/13/2024»
```


Se cuela `32/13/2024`, que no es una fecha real. Veamos cómo arreglarlo.
</details>


#### 🟡 Ejercicio 6.17 · Fecha con formato correcto (nivel 2)

Afina el ejercicio anterior: día entre `01` y `31`, mes entre `01` y `12`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/[0-9]{4}$' fechas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«15/03/2024»
«31/12/1999»
«01/01/2000»
```


- Día: `0[1-9]` (01–09) | `[12][0-9]` (10–29) | `3[01]` (30–31).
- Mes: `0[1-9]` (01–09) | `1[0-2]` (10–12).

Ya no pasa `32/13/2024`. (Tampoco comprueba que febrero tenga 28 días: eso excede a las regex.)
</details>


#### 🟡 Ejercicio 6.18 · Horas válidas

Muestra las horas válidas de `fechas.txt` en formato `hh:mm` o `hh:mm:ss` (00:00 a 23:59, con segundos opcionales).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$' fechas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«23:59:59»
«00:00»
```

</details>


#### 🟡 Ejercicio 6.19 · Colores hexadecimales

Muestra los colores de `colores.txt` con formato `#` + **3 o 6** dígitos hexadecimales (línea completa).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$' colores.txt
```

_Resultado_ (coincidencias entre « »):

```text
«#FFF»
«#ffffff»
«#1a2B3c»
```


Quedan fuera `#12345G` (la `G` no es hex), `#12345` (5 cifras) y `#1234567` (7).
</details>


#### 🟡 Ejercicio 6.20 · DNI y NIE

Muestra los documentos de `dni.txt` que sean un **DNI** (8 dígitos + letra) **o** un **NIE** (X, Y o Z + 7 dígitos + letra).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^([0-9]{8}|[XYZ][0-9]{7})[A-Z]$' dni.txt
```

_Resultado_ (coincidencias entre « »):

```text
«12345678Z»
«00000000T»
«X1234567L»
«Y7654321F»
«Z0000000M»
```


La alternativa `([0-9]{8}|[XYZ][0-9]{7})` cubre los dos comienzos y luego, común a ambos, la letra final.
</details>


#### 🟡 Ejercicio 6.21 · Teléfonos con formato libre

Muestra los teléfonos de `telefonos.txt` con formato `+34 ` o `0034 ` opcional, luego 9 cifras que empiezan por 6-9, agrupadas **en tres bloques de 3** (con espacio o guion opcional entre ellos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(\+34|0034)? ?[6-9][0-9]{2}[ -]?[0-9]{3}[ -]?[0-9]{3}$' telefonos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«612345678»
«712345678»
«912345678»
«+34 612 345 678»
«+34612345678»
«0034 612345678»
«900123456»
«812345678»
«612-345-678»
```


- `(\+34|0034)?` prefijo opcional (el `+` hay que escaparlo en ERE).
- ` ?` espacio opcional.
- `[6-9][0-9]{2}` + `[ -]?` + `[0-9]{3}` + `[ -]?` + `[0-9]{3}` tres bloques.
</details>


#### 🟡 Ejercicio 6.22 · UIDs "normales"

Muestra los usuarios de `/etc/passwd` con **UID entre 1000 y 59999** (los usuarios normales; sin `nobody`, cuyo UID es 65534).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:([1-9][0-9]{3}|[1-5][0-9]{4}):' /etc/passwd | cut -d: -f1,3
```

_Resultado:_

```text
alumno:1000
ana:1001
luis:1002
marta:1003
pedro:1004
invitado:1005
backup2:1006
```


`([1-9][0-9]{3}|[1-5][0-9]{4})` = 4 cifras (1000–9999) **o** 5 cifras que empiezan por 1–5 (10000–59999). `nobody` (65534) empieza por 6 y queda fuera.
</details>


#### 🟡 Ejercicio 6.23 · Grupos con GID ≥ 50

Muestra los usuarios de `/etc/passwd` cuyo **GID** (4.º campo) sea **mayor o igual que 50**. Un solo `grep`, y muestra solo usuario y GID con `cut`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[^:]*:([5-9][0-9]|[0-9]{3,}):' /etc/passwd | cut -d: -f1,4
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


El GID ≥ 50 son: **dos cifras del 50 al 99** (`[5-9][0-9]`) **o tres o más cifras** (`[0-9]{3,}`). Es la pregunta de tu profe: *"usuarios cuyo GID sea ≥ 50"*. En el [capítulo 10](10-ficheros-del-sistema.md) la dejamos redonda (con el nombre del grupo).
</details>


#### 🟡 Ejercicio 6.24 · Errores de cliente y servidor

Cuenta las peticiones de `access.log` con estado **4xx o 5xx**. (El estado va tras la comilla de cierre de la petición: `" 404 `.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '" [45][0-9]{2} ' /var/log/apache2/access.log
```

_Resultado:_

```text
30
```


`" ` + `[45]` + dos dígitos + ` `. `[45]` es más corto que `(4|5)` y hace lo mismo con un carácter.
</details>


#### 🟡 Ejercicio 6.25 · Letras dobles

Cuenta las palabras de `palabras.txt` que tienen **dos letras iguales seguidas**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '(.)\1' palabras.txt
```

_Resultado:_

```text
11
```


El grupo `(.)` captura un carácter y `\1` exige otro igual justo detrás.
</details>


#### 🟡 Ejercicio 6.26 · Tres iguales seguidas

Muestra las palabras con **tres letras iguales** seguidas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '(.)\1\1' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
h«ooo»la
«aaa»
```

</details>


#### 🟡 Ejercicio 6.27 · Palíndromos de 3 letras

Muestra las palabras de 3 letras de `palabras.txt` que se lean igual al revés.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(.).\1$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ala»
«oso»
«ojo»
«aaa»
```


Primera letra = última letra, la del medio, la que sea. Salen `ala`, `oso`, `ojo` y `aaa`.
</details>


#### 🟡 Ejercicio 6.28 · Palíndromos de 4 y 5 letras

En `repetidas.txt` y `palabras.txt`, encuentra los palíndromos de 4 letras (`anna`, `abba`, `otto`) y de 5 (`radar`, `rotor`, `abcba`) con **dos patrones**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -hE '^(.)(.)\2\1$' repetidas.txt palabras.txt | tr '\n' ' '; echo
grep -hE '^(.)(.).\2\1$' repetidas.txt palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
anna abba otto 
abcba radar radar rotor 
```


Numeración de grupos: el primer `(` es `\1`, el segundo `(` es `\2`. Cada `\n` repite lo que capturó su grupo. (`radar` sale dos veces porque está en los dos ficheros.)
</details>


#### 🟡 Ejercicio 6.29 · Dos veces lo mismo

Muestra las líneas de `repetidas.txt` formadas por **un bloque repetido dos veces** (como `abcabc` o `123123`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(.+)\1$' repetidas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«abcabc»
«123123»
```


`(.+)` captura un trozo de 1 o más caracteres y `\1` lo repite hasta el final. Tampoco sale `aabbcc`: serían tres bloques distintos, no uno repetido.
</details>


#### 🔴 Ejercicio 6.30 · Primera igual que última

Muestra las palabras de `palabras.txt` que **empiezan y acaban con la misma letra**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(.).*\1$' palabras.txt | tr '\n' ' '
```

_Resultado:_

```text
ala oso ojo reconocer anilina radar rotor aaa aa 
```


`^(.)` captura la primera letra, `.*` es el medio (cualquier cosa) y `\1$` exige que el final sea ese mismo carácter. No sale la palabra `a` (de una sola letra): necesita al menos dos caracteres para cumplir `(.)` y `\1`.
</details>


#### 🔴 Ejercicio 6.31 · Reconocer el palíndromo largo

Escribe un patrón que encuentre **solo** `reconocer` entre los palíndromos de 9 letras de `palabras.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(.)(.)(.)(.).\4\3\2\1$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«reconocer»
```


Cuatro grupos capturan `r e c o`; la `n` central es "cualquier cosa" (`.`); y luego se repiten en orden inverso `\4\3\2\1`: `o c e r`.
</details>


#### 🔴 Ejercicio 6.32 · Etiquetas HTML bien cerradas

Muestra las líneas de `html.txt` con una etiqueta que se **abre y se cierra con el mismo nombre** (`<b>…</b>`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '<([a-z0-9]+)[^>]*>.*</\1>' html.txt
```

_Resultado:_

```text
<h1>Titulo principal</h1>
<p>Un parrafo con <b>negrita</b> y <i>cursiva</i> dentro.</p>
<a href="https://www.ejemplo.com">Enlace uno</a> y <a href="http://otro.org/pagina">Enlace dos</a>
```


`<([a-z0-9]+)` captura el nombre de la etiqueta; `[^>]*>` termina de abrirla (con atributos); `.*` es el contenido; `</\1>` cierra con el **mismo** nombre.
</details>


#### 🔴 Ejercicio 6.33 · Comillas que casan

Muestra los textos entre comillas **iguales** (simples `'…'` o dobles `"…"`) de la cadena `dijo 'hola' y "adios" y 'mal"`. La última cadena no debe salir (abre con `'` y cierra con `"`).

<details>
<summary>💡 Ver solución</summary>


```bash
echo "dijo 'hola' y \"adios\" y 'mal\"" | grep -oE "(['\"])[^'\"]*\1"
```

_Resultado:_

```text
'hola'
"adios"
```


`(['\"])` captura la comilla de apertura (simple o doble) y `\1` exige la **misma** al cerrar. Como la cadena entera está entre comillas dobles, escapamos las internas con `\"`.
</details>


#### 🔴 Ejercicio 6.34 · La trampa de las palabras repetidas

Comprueba por qué `([a-z]+) \1` da falsos positivos en `frases.txt` (con `-i` y `-n`) y señala cuáles son las **dos** líneas verdaderas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -inE '([a-z]+) \1' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
2:El gato duerm«e e»n el sofá.
4:¿Dónd«e e»stá la biblioteca?
8:«El el» perro ladra mucho.
9:Voy «a a» la playa.
15:la linea en minuscula«s s»in punto final
17:   Esta fras«e e»mpieza con tr«es es»pacios.
```


Las dos buenas: la línea 8 (`El el perro…`) y la 9 (`Voy a a la playa.`). Las demás coinciden por trozos entre palabras: en `duerme en el` aparece `e e` (fin de `duerme` + inicio de `en`)… El capítulo 7 lo soluciona con `\b`.
</details>


#### ⚫ Ejercicio 6.35 · ¿Quién coincide con quién?

Para cada línea de `gato`, `gatos`, `gatoperro`, `xgato`, ¿cuáles pasan estos patrones? (1) `gatos?` (2) `^gatos?$` (3) `gato|perro` (4) `^gato|perro$`. Compruébalo con `printf`.

<details>
<summary>💡 Ver solución</summary>


```bash
for p in 'gatos?' '^gatos?$' 'gato|perro' '^gato|perro$'; do
  echo "patrón $p:"; printf 'gato\ngatos\ngatoperro\nxgato\n' | grep -E "$p" | tr '\n' ' '; echo
done
```

_Resultado:_

```text
patrón gatos?:
gato gatos gatoperro xgato 
patrón ^gatos?$:
gato gatos 
patrón gato|perro:
gato gatos gatoperro xgato 
patrón ^gato|perro$:
gato gatos gatoperro 
```


Observa cómo `^gato|perro$` (sin paréntesis) deja pasar `gatoperro`/`gato`/`gatos` (empiezan por gato) pero **no** `xgato`.
</details>


---

## ✅ Resumen del capítulo 6

| Quiero… | ERE (`grep -E`) | BRE (`grep`) |
|---|---|---|
| **agrupar** | `(ab)` | `\(ab\)` |
| repetir un grupo | `(ab)+` `(ab){3}` | `\(ab\)\+` `\(ab\)\{3\}` |
| **recordar** lo capturado | `\1` … `\9` | `\1` … `\9` |

**La alternativa ("O")**, que no cabe bien en una tabla de Markdown porque usa la barra vertical: en **ERE** se escribe `a|b` y en **BRE** (extensión GNU) `a\|b`.

**Reglas de oro:**
- La alternativa tiene la **prioridad más baja**: encierra siempre `|` entre `( )`.
- Los grupos se numeran por el **paréntesis de apertura**, de izquierda a derecha.
- `\1` repite **lo que se encontró**, no el patrón del grupo (`(a|b)\1` = `aa` o `bb`, nunca `ab`).

➡️ **Siguiente parada:** [Capítulo 7](07-palabras-y-fronteras.md): `\b`, `\<`, `\>`, `\w` y las opciones `-w` y `-x`.

---
⬅️ [Capítulo 5 · Repetir: `*` `+` `?` `{n,m}` y el misterio de la coma](05-repeticiones.md) · 🏠 [Índice](README.md) · [Capítulo 7 · Palabras y fronteras: `-w` `-x` `\b` `\<` `\>` `\w`](07-palabras-y-fronteras.md) ➡️
