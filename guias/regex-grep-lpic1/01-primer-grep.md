# Capítulo 1 · Tu primer `grep`: encontrar agujas en pajares

> 🎯 **Objetivo:** usar `grep` con texto normal (sin "magia" todavía) y dominar sus opciones más básicas.
>
> 📘 **LPIC-1:** 103.7 (buscar en ficheros de texto) · 103.2 (procesar flujos de texto) · 103.4 (tuberías).
>
> 🧪 **Antes de empezar:** ten montado el laboratorio (`cd ~/lab-regex`). Si no, vuelve al [Capítulo 0](00-primeros-pasos.md#08--monta-tu-laboratorio-).

---

## 1.1 · ¿Qué es `grep`?

Imagina que tienes un libro de 5.000 páginas y alguien te dice: *"Búscame todas las veces que sale la palabra **dragón**"*. Tardarías un día entero.

`grep` es un **detective con una lupa superrápida**. Le das:

1. **Una pista** (lo que buscas), y
2. **Un sitio donde mirar** (un fichero),

y él lee el fichero **renglón a renglón** y te **enseña solo los renglones que contienen la pista**. En informática, "renglón" se dice **línea**.

```text
grep   [opciones]   PISTA   FICHERO
 │                    │        │
 │                    │        └─ dónde buscar
 │                    └────────── lo que buscas (el "patrón")
 └─────────────────────────────── el detective
```

### ¿De dónde sale el nombre?

Viene de un comando del viejo editor `ed`: **`g/re/p`**, que significa *"**g**lobal / **r**egular **e**xpression / **p**rint"*, o sea: *"en todo el fichero, busca esta expresión regular e imprime las líneas"*. Por eso a la pista se le llama **expresión regular**: es una pista tan potente que no solo puede ser una palabra, sino una *descripción* ("algo que empiece por mayúscula y acabe en número"). De eso va toda esta guía; pero hoy empezamos por lo fácil: **pistas que son palabras normales**.

> 🔒 **`grep` nunca modifica el fichero.** Solo lo lee. Puedes experimentar tranquilo.

---

## 1.2 · Tu primer `grep`

Busquemos los usuarios cuya línea contiene la palabra `root` en `/etc/passwd`:

```bash
grep root /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root»:x:0:0:«root»:/«root»:/bin/bash
```


Paso a paso:

1. `grep` lee `/etc/passwd` **línea por línea**.
2. En cada línea mira: *¿contiene `root`?*
3. Si **sí**, la imprime. Si **no**, pasa a la siguiente.
4. Entre `« »` ves la parte que coincidió (en tu terminal, saldría en **rojo**).

> 💡 Mira la línea de resultado: `root` sale **tres veces** en esa línea (`root:x:0:0:root:/root:/bin/bash`: el nombre, el campo del comentario y la carpeta `/root`). Aun así `grep` **imprime la línea una sola vez**. `grep` trabaja con *líneas*: o la línea vale, o no vale.

---

## 1.3 · Mayúsculas y minúsculas: `grep` es quisquilloso

Para `grep`, `gato`, `Gato` y `GATO` son **tres cosas distintas**:

```bash
grep gato palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gato»s
«gato»
```


Solo han salido las que tienen **exactamente** `gato` en minúsculas (`gato`, `gatos` y el `gato` que está repetido al final; `Gato` y `GATO` no).

La opción **`-i`** (*ignore case*) le dice: *"no te fijes en mayúsculas"*:

```bash
grep -i gato palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«Gato»
«GATO»
«gato»s
«gato»
```


---

## 1.4 · Pistas con espacios: ¡comillas!

Si tu pista tiene **dos palabras**, necesitas **comillas**. Si no, la terminal se equivoca:

```bash
grep Noble Numbat /etc/os-release
```

_Resultado:_

```text
grep: Numbat: No such file or directory
/etc/os-release:VERSION="24.04.1 LTS (Noble Numbat)"
```


¿Qué ha pasado? El **espacio** separa los argumentos, así que `grep` entendió:

- pista = `Noble`
- ficheros = `Numbat` **y** `/etc/os-release`

Y se quejó porque no existe ningún fichero llamado `Numbat` (en tu Ubuntu en español el mensaje dirá *"No existe el fichero o el directorio"*). Además, como ahora hay **dos ficheros**, delante de cada línea te ha puesto el nombre del fichero.

La forma correcta, con comillas:

```bash
grep 'Noble Numbat' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
VERSION="24.04.1 LTS («Noble Numbat»)"
```


### ¿Comillas simples o dobles?

Hay dos tipos y **no son iguales**:

| Comillas | Qué hace la terminal con lo de dentro |
|---|---|
| `'simples'` | **Nada.** Lo deja *tal cual* (como una caja fuerte) |
| `"dobles"` | **Interpreta** cosas como `$HOME`, `$USER`, `` ` `` y `\` |

```bash
echo '$HOME'
echo "$HOME"
```

_Resultado:_

```text
$HOME
/home/alumno
```


Con las dobles, la terminal sustituyó `$HOME` por tu carpeta personal. Con las simples no.

> 🏅 **Regla de oro nº 2:** **en esta guía, el patrón de `grep` va SIEMPRE entre comillas simples** (`'así'`). Las expresiones regulares están llenas de símbolos (`*`, `$`, `\`, `[`, `!`…) que la terminal también quiere interpretar. Las comillas simples la mantienen quieta.
>
> *(Para una palabra normal como `root` no hace falta, pero **acostúmbrate** desde el primer día.)*

---

## 1.5 · Cuando no encuentra nada: silencio

```bash
grep dragon palabras.txt
```

_Resultado:_

```text
(no sale nada)
```


No sale **nada**. En Linux, "silencio" significa *"no hay coincidencias"* (y no es un error). Pero `grep` sí que deja una **nota secreta** para quien lo haya lanzado, el **código de salida** (*exit status*). Se consulta con `echo $?` justo después:

| Código | Significa |
|---|---|
| `0` | ✅ Encontré **al menos una** línea |
| `1` | 🤷 **No** encontré ninguna |
| `2` | ❌ **Error** (fichero que no existe, patrón mal escrito…) |

```bash
grep root /etc/passwd > /dev/null ; echo "root  -> código $?"
grep dragon /etc/passwd > /dev/null ; echo "dragon -> código $?"
grep root /fichero/que/no/existe 2> /dev/null ; echo "error  -> código $?"
```

_Resultado:_

```text
root  -> código 0
dragon -> código 1
error  -> código 2
```


(Las redirecciones `> /dev/null` y `2> /dev/null` solo sirven para esconder lo que `grep` imprime y quedarnos con el código.)

Esto es **superútil** en scripts: *"si `grep` encuentra X, haz tal cosa"*.

---

## 1.6 · Las opciones básicas (tus primeras superpotencias)

Una **opción** cambia *cómo* trabaja `grep`. Se escribe con un guion antes del patrón:

| Opción | Nombre en inglés | Qué hace |
|---|---|---|
| `-i` | *ignore case* | Ignora mayúsculas/minúsculas |
| `-v` | *invert* | **Invierte**: enseña las líneas que **NO** coinciden |
| `-n` | *number* | Pone delante el **número de línea** |
| `-c` | *count* | No enseña líneas: **cuenta** cuántas coinciden |
| `-l` | *files with matches* | Solo dice **qué ficheros** contienen coincidencias |
| `-L` | *files without match* | Solo dice qué ficheros **no** contienen |

Vamos a probarlas con el fichero de palabras (71 líneas).

### `-n`: ¿en qué línea está?

```bash
grep -n perro palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
7:«perro»
```


### `-c`: ¿cuántas hay?

```bash
grep -c perro palabras.txt
```

_Resultado:_

```text
1
```


Ojo: cuenta **líneas**, no apariciones. Si `perro` aparece 3 veces en una línea, suma 1.

### `-v`: lo contrario

```bash
grep -v a palabras.txt
```

_Resultado:_

```text
GATO
perro
Perro
perrito
árbol
Árbol
oso
ojo
reconocer
rotor
… (y 15 líneas más)
```


Son las palabras **sin ninguna `a`**. (El `-v` es de *"invertir"*, como cuando le das la vuelta a un calcetín.) Puedes combinarlas: ¿cuántas líneas no tienen `a`?

```bash
grep -vc a palabras.txt
```

_Resultado:_

```text
25
```


### Las opciones se pueden juntar

`-i -n` es lo mismo que `-in`. Y el orden de las letras da igual:

```bash
grep -in linux frases.txt
# Otra forma equivalente:
grep -n -i linux frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
10:«Linux» es libre, «Linux» es gratis.
```


### `-l` y `-L`: ¿en qué ficheros?

Cuando buscas en **muchos ficheros** a la vez, a veces solo quieres saber *cuáles*:

```bash
grep -l perro *.txt
```

_Resultado:_

```text
frases.txt
palabras.txt
repetidas.txt
```


> 🪄 `*.txt` lo expande **la terminal** (no `grep`) a todos los ficheros acabados en `.txt`. De eso hablamos en el [Capítulo 2](02-comodines-vs-regex.md).

---

## 1.7 · Varios ficheros a la vez

Si le das más de un fichero, `grep` antepone el **nombre del fichero** a cada línea, para que sepas de dónde viene:

```bash
grep root /etc/passwd /etc/group
```

_Resultado_ (coincidencias entre « »):

```text
/etc/passwd:«root»:x:0:0:«root»:/«root»:/bin/bash
/etc/group:«root»:x:0:
```


Dos opciones para controlarlo:

- **`-h`** → oculta el nombre del fichero.
- **`-H`** → lo fuerza (aunque sea un solo fichero).

```bash
grep -h root /etc/passwd /etc/group
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/bash
root:x:0:
```


---

## 1.8 · `grep` con tuberías: filtrar la salida de otros comandos

Hasta ahora `grep` leía un fichero. Pero también puede leer lo que **le pasa otro comando por una tubería** (`|`). Es el uso más común en la vida real: *"ejecuta algo que escupe mucho texto y quédate solo con lo que me interesa"*.

```text
comando_que_escupe_mucho  |  grep 'lo-que-busco'
```

Algunos clásicos:

```bash
ip a | grep inet
```

_Resultado_ (coincidencias entre « »):

```text
    «inet» 127.0.0.1/8 scope host lo
    «inet»6 ::1/128 scope host noprefixroute 
    «inet» 192.168.1.37/24 brd 192.168.1.255 scope global dynamic noprefixroute enp0s3
    «inet»6 2001:db8:abcd:12::37/64 scope global dynamic noprefixroute 
    «inet»6 fe80::a00:27ff:fe4e:66a1/64 scope link noprefixroute 
    «inet» 172.17.0.1/16 brd 172.17.255.255 scope global docker0
```


```bash
dmesg | grep -i usb
```

_Resultado_ (coincidencias entre « »):

```text
[  4.007800] «usb» 1-1: new high-speed «USB» device number 2 using ehci-pci
[  4.009100] «usb» 1-1: New «USB» device found, idVendor=0781, idProduct=5567, bcdDevice= 1.27
[  4.010400] «usb» 1-1: Product: Cruzer Blade
[4844.015600] «usb» 1-1: «USB» disconnect, device number 2
[88848.019500] «usb» 1-1: new high-speed «USB» device number 3 using ehci-pci
[88848.020800] «usb» 1-1: Product: Cruzer Blade
```


```bash
ps aux | grep sshd
```

_Resultado_ (coincidencias entre « »):

```text
root         902  0.0  0.1  15440  8832 ?        Ss   14:22   0:00 «sshd»: /usr/sbin/«sshd» -D [listener] 0 of 10-100 startups
```


```bash
ls | grep csv
```

_Resultado_ (coincidencias entre « »):

```text
«csv»-dificil.«csv»
usuarios.«csv»
```


> 🪤 **La trampa del `ps aux | grep`:** en un ordenador real, ese último comando suele devolver **una línea de más: la del propio `grep`** (porque en la lista de procesos aparece el comando `grep sshd` que acabas de lanzar). Hay un truco muy elegante para evitarlo con una expresión regular. ¡Lo aprenderás en el capítulo de los corchetes!

---

## 1.9 · Buscar en carpetas enteras: `-r`

¿Y si no sabes en **qué** fichero está lo que buscas? Con **`-r`** (*recursive*), `grep` mira dentro de **todos los ficheros de una carpeta y de sus subcarpetas**:

```bash
grep -rl alumno /etc 2>/dev/null | sort
```

_Resultado:_

```text
/etc/group
/etc/passwd
/etc/ssh/sshd_config
```


(Con `-l` solo nos da la lista de ficheros que contienen `alumno`. Lo de después del `grep` son dos trucos que aprenderás enseguida: **`2>/dev/null`** esconde los errores y **`| sort`** ordena la lista. Más abajo te explico por qué hacen falta.) Sin `-l`:

```bash
grep -r alumno /etc 2>/dev/null | sort
```

_Resultado_ (coincidencias entre « »):

```text
/etc/group:«alumno»:x:1000:
/etc/group:adm:x:4:syslog,«alumno»
/etc/group:audio:x:29:«alumno»
/etc/group:cdrom:x:24:«alumno»
/etc/group:dialout:x:20:«alumno»
/etc/group:dip:x:30:«alumno»
/etc/group:floppy:x:25:«alumno»
/etc/group:plugdev:x:46:«alumno»,usbmux
/etc/group:sudo:x:27:«alumno»,ana
/etc/group:video:x:44:«alumno»
/etc/passwd:«alumno»:x:1000:1000:Alumno Linux,,,:/home/«alumno»:/bin/bash
/etc/ssh/sshd_config:AllowUsers «alumno» ana luis
```


> ⚠️ **¿Y por qué `2>/dev/null`?** Porque `/etc` tiene ficheros que solo puede leer `root` (como `/etc/shadow`, donde se guardan las contraseñas cifradas). Si pruebas a leerlos como usuario normal, `grep` protesta con un error *"Permission denied"* (en un Ubuntu en español, *"Permiso denegado"*) **por cada uno**. Mira el mismo comando *sin* esconderlos (aquí `2>&1` pega los errores a la salida normal, solo para que podamos verlos y ordenarlos junto con los resultados):

```bash
grep -rl alumno /etc 2>&1 | sort
```

_Resultado:_

```text
/etc/group
/etc/passwd
/etc/ssh/sshd_config
grep: /etc/.pwd.lock: Permission denied
grep: /etc/gshadow: Permission denied
grep: /etc/security/opasswd: Permission denied
grep: /etc/shadow: Permission denied
grep: /etc/ssl/private: Permission denied
grep: /etc/sudoers.d/README: Permission denied
grep: /etc/sudoers.d/laboratorio: Permission denied
grep: /etc/sudoers: Permission denied
```


Las tres primeras líneas (las que empiezan por `/etc/`) son **resultados**; las que empiezan por `grep:` son **errores**. Los errores no son resultados: por eso los mandamos a `/dev/null` (el "agujero negro" de Linux: lo que entra ahí desaparece). La opción **`-s`** hace algo parecido. Todo esto, con calma, en el capítulo 9 y en el capítulo 17.

> 💡 **¿Y `| sort`?** `-r` recorre las carpetas en el orden en que el disco las guarda, y ese orden **no está garantizado**: puede cambiar de un ordenador a otro. `sort` lo ordena alfabéticamente para que a ti te salga igual que en el libro.

---

## 1.10 · Un par de curiosidades

### `grep ''` (pista vacía) coincide con **todo**

```bash
grep -c '' frases.txt
```

_Resultado:_

```text
20
```


Una pista vacía coincide con cualquier línea, así que `grep -c ''` **cuenta todas las líneas**. ¿Y `wc -l`?

```bash
wc -l sin-salto-final.txt ; grep -c '' sin-salto-final.txt
```

_Resultado:_

```text
0 sin-salto-final.txt
1
```


`sin-salto-final.txt` tiene **una** línea de texto, pero su última línea **no acaba en "salto de línea"**. `wc -l` cuenta *saltos de línea* (da 0), pero `grep` cuenta *líneas de texto* (da 1). Un detalle que sorprende a mucha gente.

### Pistas que empiezan por guion

¿Y si la pista que buscas **empieza por un guion**? `grep` pensará que es una opción. Hay dos remedios:

Mira qué pasa si busco `-generic` (que aparece en `versiones.txt`) sin más:

```bash
grep -generic versiones.txt
```

_Resultado:_

```text
grep: invalid option -- 'g'
Usage: grep [OPTION]... PATTERNS [FILE]...
Try 'grep --help' for more information.
```


`grep` leyó `-g` como una opción (¡que no existe!) y se quejó. Las dos formas de arreglarlo:

```bash
grep -e -generic versiones.txt
# Otra forma equivalente:
grep -- -generic versiones.txt
```

_Resultado_ (coincidencias entre « »):

```text
Linux version 6.8.0-45«-generic»
kernel 5.15.0-91«-generic» #101-Ubuntu SMP
```


- **`-e PATRÓN`** → "lo que viene ahora es el patrón".
- **`--`** → "aquí terminan las opciones; todo lo demás son patrones y ficheros".

---

## 1.11 · "O" con `-e`

Con **`-e`** puedes dar **varias pistas** y `grep` enseña las líneas que cumplan **cualquiera** (un **O**):

```bash
grep -e gato -e perro palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gato»s
«perro»
«gato»
```


> 🧠 *"O" se hace con `-e` repetido. "Y" (que cumpla las dos) se hace encadenando con una tubería: `grep a fichero | grep b`.* Más adelante verás cómo hacerlo todo con **un solo `grep`** usando expresiones regulares.

---

## 1.12 · 🏋️ Ejercicios

> Recuerda: `cd ~/lab-regex` y trabaja desde ahí. Intenta cada uno **antes** de abrir la solución.

#### 🟢 Ejercicio 1.1 · Las líneas con "gato"

Muestra las líneas de `palabras.txt` que contengan `gato` (en minúscula).

<details>
<summary>💡 Ver solución</summary>


```bash
grep gato palabras.txt
```

_Resultado:_

```text
gato
gatos
gato
```


Salen `gato`, `gatos` y el `gato` repetido del final. No salen `gata` ni `gatito` (no contienen la secuencia exacta `g-a-t-o`), ni `Gato`/`GATO` (mayúsculas).
</details>


#### 🟢 Ejercicio 1.2 · Sin importar mayúsculas

Igual, pero que también valgan `Gato` y `GATO`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -i gato palabras.txt
```

_Resultado:_

```text
gato
Gato
GATO
gatos
gato
```


La opción `-i` ignora mayúsculas y minúsculas.
</details>


#### 🟢 Ejercicio 1.3 · ¿Cuántas?

¿Cuántas líneas de `palabras.txt` contienen `casa`?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c casa palabras.txt
```

_Resultado:_

```text
3
```


`-c` devuelve el **número** de líneas que coinciden (`casa`, `casas`, y la `casa` repetida del final: 3; `Casa` no cuenta por la mayúscula).
</details>


#### 🟢 Ejercicio 1.4 · Con número de línea

Muestra las líneas de `frases.txt` que contengan `perro`, indicando el **número** de línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -n perro frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
1:El «perro» come carne.
8:El el «perro» ladra mucho.
12:Tengo 3 gatos, 2 «perro»s y 15 peces.
```


La línea 12 contiene `perros` (que también contiene `perro`).
</details>


#### 🟢 Ejercicio 1.5 · Linux, venga como venga

Muestra, con números de línea, las líneas de `frases.txt` que mencionen `linux` sin importar mayúsculas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -in linux frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
10:«Linux» es libre, «Linux» es gratis.
```


Una sola línea… que contiene `Linux` **dos veces**; sale una vez.
</details>


#### 🟢 Ejercicio 1.6 · Los que usan bash

¿Qué usuarios de `/etc/passwd` tienen `bash` como intérprete de comandos?

<details>
<summary>💡 Ver solución</summary>


```bash
grep bash /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
root:x:0:0:root:/root:/bin/«bash»
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/«bash»
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/«bash»
ana:x:1001:1001:Ana Garcia,,,:/home/ana:/bin/«bash»
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro:/bin/«bash»
```


Cada línea de `/etc/passwd` acaba con la *shell* del usuario (`/bin/bash`, `/usr/sbin/nologin`…). Así que buscar `bash` da los usuarios que pueden iniciar sesión con `bash`.
</details>


#### 🟢 Ejercicio 1.7 · Cuántos no pueden entrar

¿Cuántos usuarios de `/etc/passwd` tienen `nologin` (los que **no pueden** iniciar sesión)?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c nologin /etc/passwd
```

_Resultado:_

```text
29
```


Con `-c` no hace falta encadenar `grep … | wc -l`: **un solo comando**.
</details>


#### 🟢 Ejercicio 1.8 · La versión de tu Ubuntu

Muestra las líneas de `/etc/os-release` que contengan la palabra `Ubuntu`, sin importar mayúsculas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -i ubuntu /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
PRETTY_NAME="«Ubuntu» 24.04.1 LTS"
NAME="«Ubuntu»"
ID=«ubuntu»
HOME_URL="https://www.«ubuntu».com/"
SUPPORT_URL="https://help.«ubuntu».com/"
BUG_REPORT_URL="https://bugs.launchpad.net/«ubuntu»/"
PRIVACY_POLICY_URL="https://www.«ubuntu».com/legal/terms-and-policies/privacy-policy"
«UBUNTU»_CODENAME=noble
LOGO=«ubuntu»-logo
```

</details>


#### 🟢 Ejercicio 1.9 · Las IP "192.168"

¿Cuántas líneas de `/etc/hosts` contienen `192.168`?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 192.168 /etc/hosts
```

_Resultado:_

```text
4
```


Son 4: tres servidores activos y **una línea comentada** (`#192.168.1.99 …`) que `grep` también cuenta, porque no sabe que `#` significa "comentario". Otra cosa a la que volveremos: el `.` de `192.168` es un **comodín** (cualquier carácter), no un punto literal. Aquí coincide igualmente, pero en el [capítulo 3](03-punto-y-anclas.md) verás por qué hay que tener cuidado.
</details>


#### 🟢 Ejercicio 1.10 · En dos ficheros a la vez

Busca `root` en `/etc/passwd` y `/etc/group` mostrando de qué fichero viene cada línea.

<details>
<summary>💡 Ver solución</summary>


```bash
grep root /etc/passwd /etc/group
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
/etc/group:root:x:0:
```


Con más de un fichero, `grep` pone automáticamente el nombre delante.
</details>


#### 🟢 Ejercicio 1.11 · Sin el nombre del fichero

Lo mismo, pero **sin** que aparezca el nombre del fichero.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -h root /etc/passwd /etc/group
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/bash
root:x:0:
```

</details>


#### 🟢 Ejercicio 1.12 · ¿Qué ficheros hablan de "perro"?

De todos los `.txt` del laboratorio, ¿cuáles contienen `perro`?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -l perro *.txt
```

_Resultado:_

```text
frases.txt
palabras.txt
repetidas.txt
```

</details>


#### 🟢 Ejercicio 1.13 · ¿Y cuáles NO?

Ahora al revés: ¿qué ficheros `.txt` **no** contienen la palabra `perro`?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -L perro *.txt
```

_Resultado:_

```text
agenda.txt
colores.txt
contrasenas.txt
correos.txt
dni.txt
dominios.txt
fechas.txt
html.txt
ips.txt
ipv6.txt
macs.txt
matriculas.txt
nombres.txt
numeros.txt
poema.txt
sin-salto-final.txt
telefonos.txt
urls.txt
versiones.txt
windows.txt
```


`-L` (mayúscula) es lo contrario de `-l`.
</details>


#### 🟢 Ejercicio 1.14 · Los servicios TCP

¿Cuántas líneas de `/etc/services` mencionan `tcp`?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c tcp /etc/services
```

_Resultado:_

```text
30
```

</details>


#### 🟢 Ejercicio 1.15 · El año 2024

Muestra las líneas de `frases.txt` que contengan `2024`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 2024 frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
Hoy es lunes, 14 de octubre de «2024».
```


Para `grep` los números son texto como otro cualquiera.
</details>


#### 🟢 Ejercicio 1.16 · Las líneas "Permit…"

Muestra, con su número de línea, las líneas de `/etc/ssh/sshd_config` que contengan `Permit`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -n Permit /etc/ssh/sshd_config
```

_Resultado_ (coincidencias entre « »):

```text
22:«Permit»RootLogin no
30:#«Permit»EmptyPasswords no
```


Fíjate que hay líneas que empiezan por `#` (están **comentadas**, o sea, desactivadas). Más adelante aprenderás a quedarte solo con las activas.
</details>


#### 🟢 Ejercicio 1.17 · Todo menos comentarios (primer intento)

Muestra las líneas de `/etc/ssh/sshd_config` que **no** contengan el símbolo `#`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v '#' /etc/ssh/sshd_config
```

_Resultado:_

```text

Include /etc/ssh/sshd_config.d/*.conf





PermitRootLogin no
MaxAuthTries 3

PubkeyAuthentication yes

… (y 13 líneas más)
```


`-v` invierte. Hemos quitado las líneas con `#`, pero **siguen saliendo líneas vacías** (y también se perderían líneas con un `#` al final, tras un valor). Lo haremos bien en el siguiente capítulo con `^` y `$`.
</details>


#### 🟢 Ejercicio 1.18 · Una pista con dos palabras

Muestra la línea de `/etc/os-release` que contiene `Noble Numbat`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'Noble Numbat' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
VERSION="24.04.1 LTS («Noble Numbat»)"
```


Las comillas son imprescindibles porque hay un espacio.
</details>


#### 🟢 Ejercicio 1.19 · Direcciones inet

Muestra solo las líneas de `ip a` que contengan `inet` (direcciones IPv4 e IPv6).

<details>
<summary>💡 Ver solución</summary>


```bash
ip a | grep inet
```

_Resultado_ (coincidencias entre « »):

```text
    «inet» 127.0.0.1/8 scope host lo
    «inet»6 ::1/128 scope host noprefixroute 
    «inet» 192.168.1.37/24 brd 192.168.1.255 scope global dynamic noprefixroute enp0s3
    «inet»6 2001:db8:abcd:12::37/64 scope global dynamic noprefixroute 
    «inet»6 fe80::a00:27ff:fe4e:66a1/64 scope link noprefixroute 
    «inet» 172.17.0.1/16 brd 172.17.255.255 scope global docker0
```


Aquí `grep` filtra la **salida de otro comando**. (En el laboratorio, `ip a` es una salida de ejemplo.)
</details>


#### 🟡 Ejercicio 1.20 · Solo las IPv6

De la salida de `ip a`, muestra solo las líneas de direcciones **IPv6** (las que contienen `inet6`).

<details>
<summary>💡 Ver solución</summary>


```bash
ip a | grep inet6
```

_Resultado_ (coincidencias entre « »):

```text
    «inet6» ::1/128 scope host noprefixroute 
    «inet6» 2001:db8:abcd:12::37/64 scope global dynamic noprefixroute 
    «inet6» fe80::a00:27ff:fe4e:66a1/64 scope link noprefixroute 
```


`inet6` contiene `inet`, pero `inet` no contiene `inet6`: por eso `grep inet6` es más específico y filtra mejor.
</details>


#### 🟡 Ejercicio 1.21 · Los errores del sistema

Cuenta cuántas líneas de `/var/log/syslog` contienen `error`, sin distinguir mayúsculas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -ic error /var/log/syslog
```

_Resultado:_

```text
5
```


`-i` y `-c` combinados: `-ic` (o `-ci`, da igual).

En tu Ubuntu real puede que necesites `sudo` o pertenecer al grupo `adm` para leer `/var/log/syslog` (en el ordenador virtual ya puedes). Para practicar con calma usa la copia: `~/lab-regex/sistema/var/log/syslog`.
</details>


#### 🟡 Ejercicio 1.22 · Contraseñas fallidas

¿Cuántas veces aparece `Failed password` en `/var/log/auth.log`? (Cuenta **líneas**.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'Failed password' /var/log/auth.log
```

_Resultado:_

```text
12
```


Lleva comillas porque la pista tiene un espacio.
</details>


#### 🟡 Ejercicio 1.23 · Dos pistas con "O"

Muestra las líneas de `palabras.txt` que contengan `gato` **o** `perro`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -e gato -e perro palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gato»s
«perro»
«gato»
```


Cada `-e` añade una pista. La línea vale si cumple **cualquiera**.
</details>


#### 🟡 Ejercicio 1.24 · Dos pistas con "Y"

Muestra las líneas de `/var/log/auth.log` que contengan **a la vez** `Failed` y `root`. (Pista: dos `grep` en tubería.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep Failed /var/log/auth.log | grep root
```

_Resultado:_

```text
Nov  4 14:02:11 ubuntu-pc sshd[3805]: Failed password for root from 198.51.100.23 port 51234 ssh2
Nov  4 14:02:14 ubuntu-pc sshd[5256]: Failed password for root from 198.51.100.23 port 51234 ssh2
```


El primer `grep` se queda con las líneas con `Failed`; el segundo, de esas, con las que además tienen `root`. En capítulos posteriores verás cómo hacerlo con **un único** `grep`.
</details>


#### 🟡 Ejercicio 1.25 · Contar todas las líneas sin `wc`

Cuenta cuántas líneas tiene `/etc/hosts` usando **solo `grep`** (sin `wc`). Pista: una pista vacía coincide con todo.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '' /etc/hosts
```

_Resultado:_

```text
16
```


La pista vacía `''` coincide con cualquier línea, y `-c` las cuenta: es lo mismo que `wc -l < /etc/hosts` pero con `grep`.

> 🧪 Curiosidad: si le añades `-v` (`grep -vc ''`) en `grep` 3.11 **no imprime nada** (ni siquiera `0`): `grep` sabe que invertir "todo" no deja nada y sale antes de contar. Es una rareza de optimización, no te fíes de ese truco.
</details>


#### 🟡 Ejercicio 1.26 · El número de línea justo

Averigua en **qué número de línea** de `/etc/passwd` está el usuario `alumno`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -n alumno /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
35:«alumno»:x:1000:1000:Alumno Linux,,,:/home/«alumno»:/bin/bash
```


El número antes del primer `:` es el número de línea (la 35). Coincide dos veces en la misma línea (el nombre de usuario y la carpeta `/home/alumno`), pero solo hay **una** línea. Ojo con las pistas cortas: en el siguiente ejercicio verás que `ana` aparece en más líneas de las que esperas.
</details>


#### 🟡 Ejercicio 1.27 · ¿Quién contiene "ana"?

Muestra las líneas de `/etc/passwd` que contengan `ana`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep ana /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
list:x:38:38:Mailing List M«ana»ger:/var/list:/usr/sbin/nologin
systemd-network:x:998:998:systemd Network M«ana»gement:/:/usr/sbin/nologin
«ana»:x:1001:1001:Ana Garcia,,,:/home/«ana»:/bin/bash
```


Sale el usuario `ana`, pero también `Manager` y `Management`: contienen `ana` **dentro** de otra palabra (M-**ana**-ger). `grep` no distingue palabras completas… todavía. Para eso existe `-w` (capítulo 7).
</details>


#### 🟡 Ejercicio 1.28 · Los ficheros de /etc que mencionan a "alumno"

Lista **solo los nombres** de los ficheros de `/etc` (y subcarpetas) que contienen la palabra `alumno`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -rl alumno /etc 2>/dev/null | sort
```

_Resultado:_

```text
/etc/group
/etc/passwd
/etc/ssh/sshd_config
```


`-r` entra en las subcarpetas y `-l` solo da los nombres. (`2>/dev/null` esconde los "Permission denied" y `sort` ordena la lista.)
</details>


#### 🟡 Ejercicio 1.29 · Buscar un guion

Busca la cadena `-45-` (con los guiones) en `versiones.txt`. Cuidado: ¡empieza por guion!

<details>
<summary>💡 Ver solución</summary>


```bash
grep -e -45- versiones.txt
# Otra forma equivalente:
grep -- -45- versiones.txt
```

_Resultado_ (coincidencias entre « »):

```text
Linux version 6.8.0«-45-»generic
```


Sin `-e` o `--`, `grep` creería que `-45-` es una opción y fallaría.
</details>


#### 🟡 Ejercicio 1.30 · La línea que `wc` no cuenta

Demuestra que `sin-salto-final.txt` tiene "0 líneas" para `wc -l` pero **1** para `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
wc -l < sin-salto-final.txt
grep -c '' sin-salto-final.txt
```

_Resultado:_

```text
0
1
```


`wc -l` cuenta caracteres de salto de línea (`\n`). El fichero no tiene ninguno, así que da 0; `grep` ve una línea de texto aunque no termine en `\n`.
</details>


---

## ✅ Resumen del capítulo 1

| Quiero… | Comando |
|---|---|
| Buscar una palabra | `grep palabra fichero` |
| Ignorar mayúsculas | `grep -i …` |
| Ver el número de línea | `grep -n …` |
| Contar coincidencias (líneas) | `grep -c …` |
| Lo contrario (líneas que **no** la contienen) | `grep -v …` |
| Solo nombres de ficheros que coinciden / no coinciden | `grep -l …` / `grep -L …` |
| Varios patrones con **O** | `grep -e uno -e dos …` |
| Buscar en una carpeta entera | `grep -r …` |
| Filtrar la salida de otro comando | `comando \| grep …` |
| Pista con espacios o símbolos | **comillas simples** `'así'` |
| Saber si encontró algo | `echo $?` → 0 sí, 1 no, 2 error |

➡️ **Siguiente parada:** [Capítulo 2](02-comodines-vs-regex.md): la gran confusión entre los comodines de la terminal y las expresiones regulares.

---
⬅️ [Capítulo 0 · Tu primera vez frente a una terminal](00-primeros-pasos.md) · 🏠 [Índice](README.md) · [Capítulo 2 · Comodines de la terminal ≠ expresiones regulares](02-comodines-vs-regex.md) ➡️
