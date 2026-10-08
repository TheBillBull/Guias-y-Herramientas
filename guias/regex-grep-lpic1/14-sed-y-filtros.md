# Capítulo 14 · `sed` y los filtros de texto: `cut`, `sort`, `uniq`, `tr`, `wc`…

> 🎯 **Objetivo:** `grep` solo **elige** líneas. Para **cambiarlas** (sustituir, borrar, reordenar campos) está **`sed`**. Y para **procesar** texto en tuberías, la familia de filtros de LPIC-1.
>
> 📘 **LPIC-1:** 103.2 (procesar flujos de texto: `sed`, `cut`, `sort`, `uniq`, `tr`, `wc`, `nl`, `paste`, `join`, `split`, `head`, `tail`…) y 103.7 (*"use regular expressions to delete, change and substitute text"*).
>
> 🧪 `cd ~/lab-regex`

---

## 14.1 · `sed`: el editor que trabaja por ti

`sed` significa ***s**tream **ed**itor*: un editor que **lee el texto línea a línea**, le aplica las órdenes que le des y **escribe el resultado por pantalla**. Como `grep`, **no toca el fichero original** (salvo que se lo pidas con `-i`).

```text
sed  [opciones]  'ORDEN'  fichero
```

La orden más famosa, **sustituir**:

```text
s / lo-que-busco / lo-que-pongo / banderas
│   └─ regex ──┘   └ reemplazo ┘   └ g, i, p, N…
└─ substitute
```

```bash
echo 'el gato y el perro' | sed 's/gato/pez/'
```

_Resultado:_

```text
el pez y el perro
```


### Las banderas de `s`

| Bandera | Significa |
|---|---|
| (nada) | sustituye **solo la primera** coincidencia **de cada línea** |
| `g` | **g**lobal: **todas** las de la línea |
| `2` | solo la **segunda** |
| `2g` | de la segunda en adelante |
| `I` (o `i`) | ignora mayúsculas |
| `p` | imprime la línea si hubo cambio (se usa con `-n`) |

```bash
echo 'a a a a' | sed 's/a/X/'
echo 'a a a a' | sed 's/a/X/g'
echo 'a a a a' | sed 's/a/X/2'
echo 'Hola hOLA' | sed 's/hola/X/Ig'
```

_Resultado:_

```text
X a a a
X X X X
a X a a
X X
```


### `-n` y `p`: solo lo que cambia (el `sed` que imita a `grep`)

Por defecto `sed` imprime **todas** las líneas. Con **`-n`** no imprime nada salvo lo que le pidas con **`p`**:

```bash
sed -n '/nologin/p' /etc/passwd | head -2
# Otra forma equivalente:
grep nologin /etc/passwd | head -2
```

_Resultado:_

```text
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
```


> 🧠 `sed -n '/regex/p'` **es** `grep regex`. Pero `sed` puede **además** modificar la línea antes de imprimirla.

### Cambiar el delimitador

Si el texto tiene muchas barras (`/`), usa otro delimitador (lo que va **justo tras la `s`** es el separador):

```bash
sed -n 's|/bin/bash$|/bin/zsh|p' /etc/passwd | head -2
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/zsh
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/zsh
```


### Los dialectos: BRE y ERE

`sed` usa **BRE** por defecto (los `\+ \? \( \) \{ \}` llevan barra). Con **`-E`** (o `-r`) usa **ERE** (sin barras). Todo lo del capítulo 8 vale igual.

```bash
echo 'tengo 3 gatos y 15 peces' | sed 's/[0-9]\+/<&>/g'
# Otra forma equivalente:
echo 'tengo 3 gatos y 15 peces' | sed -E 's/[0-9]+/<&>/g'
```

_Resultado:_

```text
tengo <3> gatos y <15> peces
```


---

## 14.2 · La magia del reemplazo: `&` y `\1`

En la parte de **reemplazo** (lo que se escribe), los símbolos tienen otro significado:

| En el reemplazo | Significa |
|---|---|
| `&` | **todo lo que coincidió** |
| `\1` … `\9` | lo que capturó el **grupo** n (los paréntesis de la regex) |
| `\n` | un salto de línea |
| `\U` `\L` `\u` `\l` `\E` | **mayúsculas/minúsculas** (extensión GNU): todo mayúsculas / todo minúsculas / la siguiente / la siguiente en minúscula / fin |
| `\&` | un `&` literal |

```bash
echo 'Juan Flores' | sed -E 's/(\w+) (\w+)/\2, \1/'
```

_Resultado:_

```text
Flores, Juan
```


`(\w+) (\w+)` captura nombre y apellido; `\2, \1` los escribe al revés con una coma. **Reordenar es justo lo que `grep` no puede hacer.**

```bash
echo 'hola mundo feliz' | sed -E 's/\b./\u&/g'
```

_Resultado:_

```text
Hola Mundo Feliz
```


`\b.` = primera letra de cada palabra; `\u&` = "pon en mayúscula lo que coincidió". Cada palabra con inicial mayúscula.

---

## 14.3 · Elegir **qué líneas** tocar: las direcciones

Antes de la orden puedes poner una **dirección** que limita las líneas afectadas:

| Dirección | Líneas afectadas |
|---|---|
| `5` | la línea 5 |
| `$` | la **última** |
| `3,5` | de la 3 a la 5 |
| `2,$` | de la 2 hasta el final |
| `/regex/` | las que **coinciden** con la regex |
| `/ini/,/fin/` | desde la que coincida con `ini` hasta la que coincida con `fin` |
| `1~2` | cada 2 líneas desde la 1 (impares) *(GNU)* |
| `DIR!` | **todas menos** las de esa dirección |

Y las órdenes más usadas:

| Orden | Hace |
|---|---|
| `s/…/…/` | sustituye |
| `d` | **d**elete: borra la línea |
| `p` | **p**rint: la imprime |
| `=` | imprime el **número** de línea |
| `i\texto` | **i**nserta una línea **antes** |
| `a\texto` | **a**ñade una línea **después** |
| `c\texto` | **c**ambia la línea entera por un texto |
| `y/abc/ABC/` | transcribe carácter a carácter |
| `q` | **q**uit: termina |
| `r fichero` | lee e inserta un fichero |
| `w fichero` | escribe las líneas en un fichero |
| `l` | muestra la línea con los invisibles (`\t`, `\r`…) |

```bash
seq 10 | sed '3,5d' | tr '\n' ' '
seq 10 | sed -n '3,5p' | tr '\n' ' '
seq 10 | sed -n '3,5!p' | tr '\n' ' '
echo
```

_Resultado:_

```text
1 2 6 7 8 9 10 3 4 5 1 2 6 7 8 9 10 
```


(`seq 10` escribe los números del 1 al 10.)

```bash
sed -n '/\[base_datos\]/,/^$/p' conf-ejemplo.conf
```

_Resultado:_

```text
[base_datos]
usuario = admin
clave = s3creta
host = 192.168.1.50
puerto=5432
```


Todo desde la línea `[base_datos]` hasta la primera línea vacía. **Rango entre dos regex** es una de las funciones más útiles de `sed`. (Cuidado: si el "fin" no aparece nunca después, `sed` sigue **hasta el final del fichero**.)

```bash
printf 'a\nb\nc\n' | sed -e '2i\antes de b' -e '2a\despues de b' -e '$c\ultima'
```

_Resultado:_

```text
a
antes de b
b
despues de b
ultima
```


---

## 14.4 · Modificar el fichero de verdad: `-i` (¡con cuidado!)

`sed -i` **reescribe el fichero**. Es muy peligroso si te equivocas. **Dos reglas de oro:**

1. 🛡️ **Haz siempre una copia de seguridad**: `sed -i.bak` guarda el original como `fichero.bak`.
2. 🧪 **Prueba primero sin `-i`** (mira el resultado por pantalla) y solo entonces añade `-i`.

```bash
cp /etc/ssh/sshd_config sshd_prueba
sed -i.bak 's/^PermitRootLogin.*/PermitRootLogin yes/' sshd_prueba
diff sshd_prueba.bak sshd_prueba
```

_Resultado:_

```text
22c22
< PermitRootLogin no
---
> PermitRootLogin yes
```


(Trabajamos en una **copia** (`sshd_prueba`) del fichero real. **Nunca practiques `-i` sobre `/etc/…` real.**) `diff` muestra las diferencias: la línea 22 cambió de `no` a `yes`.

---

## 14.5 · Los filtros del examen (LPIC 103.2)

Los comandos clásicos para **procesar texto en tuberías**. Cada uno hace **una cosa** y la hace bien:

| Comando | Para qué | Ejemplo |
|---|---|---|
| `cut` | cortar **columnas/campos** | `cut -d: -f1,7 /etc/passwd` |
| `sort` | **ordenar** | `sort -t: -k3 -n` |
| `uniq` | eliminar/contar **consecutivos repetidos** (¡necesita `sort`!) | `sort \| uniq -c` |
| `tr` | **transformar/borrar** caracteres | `tr 'a-z' 'A-Z'` |
| `wc` | **contar** líneas/palabras/bytes | `wc -l` |
| `head`/`tail` | primeras/últimas líneas | `tail -n +2` |
| `nl` | **numerar** líneas | `nl fichero` |
| `paste` | **pegar** ficheros en columnas, o juntar líneas | `paste -sd, fichero` |
| `join` | **unir** dos ficheros por un campo común | (ver capítulo 10) |
| `split` | **trocear** un fichero | `split -l 100 f` |
| `tac` / `rev` | invertir el **orden de líneas** / los **caracteres** de cada línea | |
| `column` | alinear en **columnas** | `column -t -s:` |
| `tee` | guardar **y** dejar pasar | `… \| tee f \| …` |
| `xargs` | **convertir** líneas en **argumentos** | `… \| xargs wc -l` |

Algunos con las regex a su lado:

```bash
tr 'a-z' 'A-Z' < /etc/hostname
echo 'a1b22c333' | tr -d '[:digit:]'
echo 'a    b     c' | tr -s ' '
echo 'a1b22c333' | tr -cd '[:digit:]' ; echo
```

_Resultado:_

```text
UBUNTU-PC
abc
a b c
122333
```


`tr` no usa regex "completas", sino **conjuntos de caracteres** (`a-z`, `[:digit:]`…): `-d` borra, `-s` comprime repeticiones, `-c` toma el **complemento** ("todo lo que NO es…").

```bash
sort -t: -k3 -n /etc/passwd | cut -d: -f1,3 | tail -3
```

_Resultado:_

```text
invitado:1005
backup2:1006
nobody:65534
```


`sort -t: -k3 -n` ordena por el 3.er campo (separador `:`) **numéricamente**; `cut` deja solo nombre y UID.

---

## 14.6 · 🏋️ Ejercicios: `sed`

#### 🟢 Ejercicio 14.1 · Cambiar una palabra

Escribe una orden que, para cada línea de `frases.txt` que contenga `gato`, **muestre la línea cambiando `gato` por `pez`**.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n 's/gato/pez/p' frases.txt
```

_Resultado:_

```text
El pez duerme en el sofá.
Tengo 3 pezs, 2 perros y 15 peces.
```


`-n` más la bandera `p`: solo se imprimen las líneas donde hubo sustitución (las otras se descartan). Fíjate en que `gatos` se queda en `pezs`: `sed` sustituye letras, no entiende de gramática 😄.
</details>


#### 🟢 Ejercicio 14.2 · Todas las apariciones

Cambia **todas** las `Linux` por `GNU/Linux` en la línea de `frases.txt` que las contenga.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n 's/Linux/GNU\/Linux/gp' frases.txt
# Otra forma equivalente:
sed -n 's|Linux|GNU/Linux|gp' frases.txt
```

_Resultado:_

```text
GNU/Linux es libre, GNU/Linux es gratis.
```


`g` = todas las de la línea. Como el reemplazo lleva una `/`, o la escapas (`\/`) o cambias de delimitador (`|`).
</details>


#### 🟢 Ejercicio 14.3 · Ignorar mayúsculas

Cambia `linux` (en cualquier mayúscula/minúscula) por `Tux` en `palabras.txt`, mostrando solo las líneas cambiadas.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n 's/linux/Tux/Ip' palabras.txt
```

_Resultado:_

```text
Tux
Tux
Tux
```


La bandera `I` ignora mayúsculas (`Linux`, `linux`, `LINUX`).
</details>


#### 🟢 Ejercicio 14.4 · Una shell distinta

Muestra `/etc/passwd` cambiando la shell `/bin/bash` por `/bin/zsh` **solo en las líneas donde ocurra** (sin tocar el fichero).

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n 's|/bin/bash$|/bin/zsh|p' /etc/passwd
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/zsh
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/zsh
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/zsh
ana:x:1001:1001:Ana Garcia,,,:/home/ana:/bin/zsh
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro:/bin/zsh
```


Con `|` como delimitador no hay que escapar las barras de la ruta.
</details>


#### 🟢 Ejercicio 14.5 · Entre corchetes

Escribe cada **número** de la frase `tengo 3 gatos y 15 peces` entre corchetes `[3]`, `[15]`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'tengo 3 gatos y 15 peces' | sed -E 's/[0-9]+/[&]/g'
```

_Resultado:_

```text
tengo [3] gatos y [15] peces
```


`&` representa "todo lo que ha coincidido".
</details>


#### 🟢 Ejercicio 14.6 · Borrar comentarios

Muestra `/etc/fstab` **sin** las líneas de comentario (`#…`) usando `sed`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed '/^#/d' /etc/fstab
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


`/^#/d` = "borra las líneas que empiezan por `#`". (`d` = delete.)
</details>


#### 🟢 Ejercicio 14.7 · Borrar comentarios y vacías

Muestra `/etc/ssh/sshd_config` **sin comentarios (aunque estén sangrados) ni líneas vacías o en blanco**, con `sed`. Comprueba que da lo mismo que `grep -Ev`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -E '/^[[:space:]]*(#|$)/d' /etc/ssh/sshd_config
# Otra forma equivalente:
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


`sed '/regex/d'` ≡ `grep -v regex`.
</details>


#### 🟢 Ejercicio 14.8 · Una línea concreta

Muestra solo la **línea 7** de `/etc/passwd`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '7p' /etc/passwd
```

_Resultado:_

```text
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
```


(Antes lo hacíamos con `head | tail`: dos comandos; ahora uno.)
</details>


#### 🟢 Ejercicio 14.9 · Un rango de líneas

Muestra las **líneas 3 a 5** de `/etc/passwd`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '3,5p' /etc/passwd
```

_Resultado:_

```text
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
```

</details>


#### 🟢 Ejercicio 14.10 · Contar líneas con sed

Cuenta las líneas de `palabras.txt` con `sed` (sin `wc`).

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '$=' palabras.txt
```

_Resultado:_

```text
71
```


`$` = última línea; `=` = imprime el número de línea. Es el total.
</details>


#### 🟢 Ejercicio 14.11 · Mayúsculas

Pasa a **mayúsculas** la frase `hola mundo` con `sed`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'hola mundo' | sed 's/.*/\U&/'
```

_Resultado:_

```text
HOLA MUNDO
```


`\U` pone en mayúsculas todo lo que sigue (hasta `\E`); `&` es la línea entera.
</details>


#### 🟡 Ejercicio 14.12 · Nombre y apellido al revés

Convierte `Juan Flores` en `Flores, Juan`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'Juan Flores' | sed -E 's/(\w+) (\w+)/\2, \1/'
```

_Resultado:_

```text
Flores, Juan
```

</details>


#### 🟡 Ejercicio 14.13 · Nombres propios de `nombres.txt`

Muestra `nombres.txt` con el formato **`Apellido, Nombre`** (solo los de **dos palabras**).

<details>
<summary>💡 Ver solución</summary>


```bash
sed -nE 's/^(\S+) (\S+)$/\2, \1/p' nombres.txt
```

_Resultado:_

```text
Flores, Juan
García, Ana
Pérez, Luis
Ruiz, Marta
Gómez, Pedro
Martín, Lucía
Sánchez, Carlos
Fernández, María
Núñez, Álvaro
Jiménez, Beatriz
Ramírez, Óscar
Ortega, Íñigo
Gil, Eva
```


`^(\S+) (\S+)$` = exactamente dos "palabras" separadas por un espacio (los nombres compuestos, como `José Luis Rodríguez`, no coinciden).
</details>


#### 🟡 Ejercicio 14.14 · Iniciales en mayúscula

Pon la **primera letra de cada palabra** en mayúscula en `la linea en minusculas sin punto final` (línea 15 de `frases.txt`).

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '15s/\b./\u&/gp' frases.txt
```

_Resultado:_

```text
La Linea En Minusculas Sin Punto Final
```


`15s/…/` limita la sustitución a la línea 15. `\b.` = una letra al principio de palabra.
</details>


#### 🟡 Ejercicio 14.15 · Fechas al revés

Convierte las fechas `dd/mm/aaaa` de `fechas.txt` a formato **`aaaa-mm-dd`**.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -nE 's|^([0-9]{2})/([0-9]{2})/([0-9]{4})$|\3-\2-\1|p' fechas.txt
```

_Resultado:_

```text
2024-03-15
1999-12-31
2000-01-01
2024-13-32
```


Tres grupos capturan día, mes y año; el reemplazo los reordena. (Fíjate: `32/13/2024` también se "convierte"; `sed` no valida fechas, solo recoloca.)
</details>


#### 🟡 Ejercicio 14.16 · Ocultar el último octeto

Sustituye el último número de cada IP de la frase `192.168.1.37 y 10.0.0.5` por `xxx`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo '192.168.1.37 y 10.0.0.5' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+\.)[0-9]+/\1xxx/g'
```

_Resultado:_

```text
192.168.1.xxx y 10.0.0.xxx
```


El grupo `\1` conserva "los tres primeros números con su punto" y cambiamos el último.
</details>


#### 🟡 Ejercicio 14.17 · Quitar las etiquetas HTML

Muestra `html.txt` **sin etiquetas** (solo el texto).

<details>
<summary>💡 Ver solución</summary>


```bash
sed -E 's/<[^>]*>//g' html.txt
```

_Resultado:_

```text


Titulo principal
Un parrafo con negrita y cursiva dentro.
Enlace uno y Enlace dos
```


`<[^>]*>` = una etiqueta entera (¡y no voraz!), sustituida por nada. (Quedan líneas vacías donde solo había etiquetas.)
</details>


#### 🟡 Ejercicio 14.18 · Teléfono con espacios

Convierte `612345678` en `612 345 678`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 612345678 | sed -E 's/^([0-9]{3})([0-9]{3})([0-9]{3})$/\1 \2 \3/'
```

_Resultado:_

```text
612 345 678
```

</details>


#### 🟡 Ejercicio 14.19 · Intercambiar dos columnas de un CSV

En `usuarios.csv`, intercambia las **dos primeras columnas** (id y nombre), sin tocar la cabecera.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -E '1!s/^([^,]*),([^,]*),/\2,\1,/' usuarios.csv | head -4
```

_Resultado:_

```text
id,nombre,apellido,email,edad,ciudad,salario
Juan,1,Flores,juan.flores@cas-training.com,34,Madrid,2450.50
Ana,2,García,ana.garcia@ejemplo.org,28,Barcelona,2100.00
Luis,3,Pérez,luis.perez@ejemplo.com,45,Sevilla,3200.75
```


`1!` = "en todas las líneas **menos** la 1".
</details>


#### 🟡 Ejercicio 14.20 · Quitar espacios sobrantes

Quita los espacios y tabuladores del **principio y del final** de la cadena `  hola  ` (comprueba con `cat -A`).

<details>
<summary>💡 Ver solución</summary>


```bash
printf '  hola  \n' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | cat -A
```

_Resultado:_

```text
hola$
```


La alternativa `^…|…$` ataca los dos extremos; `g` para que ejecute las dos.
</details>


#### 🟡 Ejercicio 14.21 · De Windows a Linux

Convierte los finales de línea de `windows.txt` (con `\r`) a finales de Linux y compruébalo con `cat -A`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed 's/\r$//' windows.txt | cat -A
```

_Resultado:_

```text
hola$
mundo$
linux$
```


GNU `sed` entiende `\r` (retorno de carro), a diferencia de `grep`. (En la práctica también existe el comando `dos2unix`.)
</details>


#### 🟡 Ejercicio 14.22 · Espacios alrededor del `=`

En `conf-ejemplo.conf`, convierte `clave = valor` en `clave=valor` (quita los espacios alrededor del primer `=`) y muestra las líneas 7 y 8 del resultado.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -E 's/[[:space:]]*=[[:space:]]*/=/' conf-ejemplo.conf | sed -n '7,8p'
```

_Resultado:_

```text
puerto=8080
host=localhost
```

</details>


#### 🟡 Ejercicio 14.23 · Desactivar una directiva

Muestra `sshd_config` con la línea `PermitRootLogin` **comentada** (añadiéndole `#` delante), y comprueba el resultado.

<details>
<summary>💡 Ver solución</summary>


```bash
sed '/PermitRootLogin/s/^/#/' /etc/ssh/sshd_config | grep -n PermitRootLogin
```

_Resultado:_

```text
22:#PermitRootLogin no
```


`/PermitRootLogin/` selecciona la línea y `s/^/#/` pone un `#` al principio (`^` = principio de línea, reemplazado por `#`).
</details>


#### 🟡 Ejercicio 14.24 · Cambiar y guardar copia

Haz una **copia** de `/etc/ssh/sshd_config` llamada `sshd_prueba`, cambia `PermitRootLogin no` por `PermitRootLogin yes` **en la copia**, guardando una copia de seguridad `.bak`, y muestra las diferencias.

<details>
<summary>💡 Ver solución</summary>


```bash
cp /etc/ssh/sshd_config sshd_prueba
sed -i.bak 's/^PermitRootLogin.*/PermitRootLogin yes/' sshd_prueba
diff sshd_prueba.bak sshd_prueba
```

_Resultado:_

```text
22c22
< PermitRootLogin no
---
> PermitRootLogin yes
```


`-i.bak` guarda el original como `sshd_prueba.bak`. `diff` enseña qué líneas cambiaron.
</details>


#### 🟡 Ejercicio 14.25 · Rango entre dos regex

Muestra la sección **`[servidor]`** de `conf-ejemplo.conf`, **desde su título hasta el título de la siguiente** sección (inclusive).

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '/^\[servidor\]/,/^\[base_datos\]/p' conf-ejemplo.conf
```

_Resultado:_

```text
[servidor]
puerto = 8080
host=localhost
    # comentario con sangria
debug = true

[base_datos]
```


`/inicio/,/fin/p` imprime desde la línea que coincide con `inicio` hasta la que coincide con `fin`.
</details>


#### 🟡 Ejercicio 14.26 · Solo la primera coincidencia

Muestra **solo la primera línea** de `/etc/passwd` que contiene `nologin`, usando `sed`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '/nologin/{p;q}' /etc/passwd
```

_Resultado:_

```text
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
```


`{p;q}` agrupa dos órdenes: **imprime** y **termina** (así no recorre el resto del fichero). El equivalente en `grep` es `grep -m1 nologin`.
</details>


#### 🟡 Ejercicio 14.27 · Líneas impares y pares

Muestra con `seq 10` solo los números **impares** (1, 3, 5…), y luego los **pares**.

<details>
<summary>💡 Ver solución</summary>


```bash
seq 10 | sed -n '1~2p' | tr '\n' ' '; echo
seq 10 | sed -n '2~2p' | tr '\n' ' '; echo
```

_Resultado:_

```text
1 3 5 7 9 
2 4 6 8 10 
```


`1~2` = "empezando en la 1, cada 2" (extensión GNU).
</details>


#### 🟡 Ejercicio 14.28 · Insertar y añadir

Con `printf 'a\nb\nc\n'`, **inserta** la línea `antes de b` antes de la 2, **añade** `despues de b` después de ella y **cambia** la última por `ultima`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a\nb\nc\n' | sed -e '2i\antes de b' -e '2a\despues de b' -e '$c\ultima'
```

_Resultado:_

```text
a
antes de b
b
despues de b
ultima
```


`i\` inserta antes, `a\` añade después, `c\` cambia. `-e` encadena varias órdenes.
</details>


#### 🟡 Ejercicio 14.29 · Transcribir

Cambia las vocales de `hola` por mayúsculas con `y///`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'hola' | sed 'y/aeiou/AEIOU/'
```

_Resultado:_

```text
hOlA
```


`y/ORIGEN/DESTINO/` sustituye **carácter a carácter** (el 1.º de ORIGEN por el 1.º de DESTINO…).
</details>


#### 🟡 Ejercicio 14.30 · Los números de línea de las coincidencias

Muestra **solo los números de línea** de las líneas de `palabras.txt` que contienen `gato`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '/gato/=' palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
1 6 70 
```


`=` imprime el número de línea. Con `grep -n gato palabras.txt | cut -d: -f1` obtendrías lo mismo.
</details>


#### 🔴 Ejercicio 14.31 · ⭐ Usuarios y GID (≥ 50) con un solo `sed`

Repite el ejercicio de tu profe: la lista **`usuario:GID`** de los usuarios con GID ≥ 50, con **un solo comando**, para ver cómo `sed` reordena y filtra a la vez.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -nE 's/^([^:]+):[^:]*:[^:]*:([5-9][0-9]|[0-9]{3,}):.*/\1:\2/p' /etc/passwd | head -6
```

_Resultado:_

```text
sync:65534
games:60
_apt:65534
nobody:65534
systemd-network:998
systemd-timesync:996
```


La regex describe **toda la línea**; los dos grupos capturan nombre y GID; `\1:\2` reescribe solo eso; `-n` + `p` solo muestran las líneas que cumplieron. Un `grep` no puede **construir** una salida distinta de la línea original.
</details>


#### 🔴 Ejercicio 14.32 · `UID:nombre`

Muestra `UID:nombre` (en vez de `nombre:…:UID`) para cada usuario.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -nE 's/^([^:]+):[^:]*:([^:]*):.*/\2:\1/p' /etc/passwd | head -4
```

_Resultado:_

```text
0:root
1:daemon
2:bin
3:sys
```

</details>


#### 🔴 Ejercicio 14.33 · Unir todas las líneas con comas

Muestra el fichero `/etc/shells` (sin la primera línea de comentario) **en una sola línea**, con las rutas separadas por comas.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '2,$p' /etc/shells | sed ':a;N;$!ba;s/\n/,/g'
# Otra forma equivalente:
sed -n '2,$p' /etc/shells | paste -sd,
```

_Resultado:_

```text
/bin/sh,/bin/bash,/usr/bin/bash,/bin/rbash,/usr/bin/rbash,/usr/bin/sh,/bin/dash,/usr/bin/dash,/bin/zsh,/usr/bin/zsh
```


El clásico `:a;N;$!ba;s/\n/,/g` va acumulando líneas (`N`) y al final sustituye los saltos de línea. `paste -sd,` hace exactamente lo mismo y es mucho más sencillo: **elige siempre la herramienta más simple**.
</details>


#### 🔴 Ejercicio 14.34 · El texto entre comillas

Extrae solo el texto entre comillas de `<a href="https://www.ejemplo.com">`, con `sed`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo '<a href="https://www.ejemplo.com">Enlace</a>' | sed 's/.*"\(.*\)".*/\1/'
```

_Resultado:_

```text
https://www.ejemplo.com
```


`.*"` se come hasta la **primera** comilla (voraz, pero retrocede), `\(.*\)` captura, `".*` el resto. Con `-P` y `\K` es más legible: `grep -oP 'href="\K[^"]*'`.
</details>


#### 🔴 Ejercicio 14.35 · Ver los invisibles

Muestra con `sed -n l` la línea `a<TAB>b<espacio>` (un tabulador y un espacio final) para ver los caracteres invisibles.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a\tb \n' | sed -n l
```

_Resultado:_

```text
a\tb $
```


`l` muestra la línea "sin ambigüedad": `\t` para el tabulador, `$` al final. Otra herramienta: `cat -A`.
</details>


#### 🔴 Ejercicio 14.36 · Guardar solo lo que interesa en un fichero

Con `sed`, guarda en `nologin.out` las líneas con `nologin` de `/etc/passwd` y cuenta cuántas son.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '/nologin/w nologin.out' /etc/passwd
wc -l < nologin.out
```

_Resultado:_

```text
29
```


La orden `w fichero` escribe en un fichero las líneas seleccionadas.
</details>


---

## 14.7 · 🏋️ Ejercicios: los filtros

#### 🟢 Ejercicio 14.37 · Dos columnas

Muestra el nombre y la shell (campos 1 y 7) de cada usuario, separados por `:`.

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f1,7 /etc/passwd | head -4
# Otra forma equivalente:
grep -oE '^[^:]*|[^:]*$' /etc/passwd | paste -d: - - | head -4
```

_Resultado:_

```text
root:/bin/bash
daemon:/usr/sbin/nologin
bin:/usr/sbin/nologin
sys:/usr/sbin/nologin
```


`cut` es lo más sencillo para campos; el `grep -o` con alternativa también funciona (extrae el primero y el último campo y `paste` los une de dos en dos).
</details>


#### 🟢 Ejercicio 14.38 · Los primeros caracteres

Muestra solo los **5 primeros caracteres** de cada línea de `/etc/hostname`… y de las 3 primeras líneas de `/etc/passwd`.

<details>
<summary>💡 Ver solución</summary>


```bash
head -3 /etc/passwd | cut -c1-5
```

_Resultado:_

```text
root:
daemo
bin:x
```


`cut -c1-5` = caracteres del 1 al 5.
</details>


#### 🟢 Ejercicio 14.39 · Ordenar por UID

Muestra los 5 usuarios con **UID más alto**, ordenados de mayor a menor, mostrando `UID nombre`.

<details>
<summary>💡 Ver solución</summary>


```bash
sort -t: -k3 -rn /etc/passwd | head -5 | cut -d: -f3,1
```

_Resultado:_

```text
nobody:65534
backup2:1006
invitado:1005
pedro:1004
marta:1003
```


`sort -t: -k3 -rn`: separador `:`, clave el campo 3, orden **numérico** (`-n`) e **inverso** (`-r`). `cut -d: -f3,1` conserva el orden original de los campos (1 antes de 3).
</details>


#### 🟢 Ejercicio 14.40 · Eliminar repetidos

De `palabras.txt`, muestra las palabras **repetidas** (que salen más de una vez).

<details>
<summary>💡 Ver solución</summary>


```bash
sort palabras.txt | uniq -d
```

_Resultado:_

```text
casa
gato
```


`uniq` solo detecta repetidas **consecutivas**, por eso se ordena antes. `-d` = solo las repetidas; `-u` = solo las únicas; `-c` = contar.
</details>


#### 🟢 Ejercicio 14.41 · Ranking de shells

Cuenta cuántos usuarios usan cada shell y ordena de más a menos.

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -rn
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


El patrón de siempre: `sort | uniq -c | sort -rn`.
</details>


#### 🟢 Ejercicio 14.42 · A mayúsculas con tr

Pasa `hola mundo` a mayúsculas con `tr`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'hola mundo' | tr 'a-z' 'A-Z'
# Otra forma equivalente:
echo 'hola mundo' | tr '[:lower:]' '[:upper:]'
```

_Resultado:_

```text
HOLA MUNDO
```


La segunda forma es la buena para letras con acentos y cualquier idioma.
</details>


#### 🟢 Ejercicio 14.43 · Quitar los números

Borra todos los dígitos de `a1b22c333` con `tr`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'a1b22c333' | tr -d '[:digit:]'
```

_Resultado:_

```text
abc
```

</details>


#### 🟢 Ejercicio 14.44 · Comprimir espacios

Convierte `a    b     c` en `a b c` (un solo espacio entre palabras).

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'a    b     c' | tr -s ' '
```

_Resultado:_

```text
a b c
```

</details>


#### 🟢 Ejercicio 14.45 · Dejar solo los dígitos

Deja solo los dígitos de `Tel: 612-345-678` (borrando todo lo demás).

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'Tel: 612-345-678' | tr -cd '[:digit:]'; echo
```

_Resultado:_

```text
612345678
```


`-c` = el **complemento** del conjunto; `-d` = borrar. Es decir: "borra todo lo que NO sea un dígito".
</details>


#### 🟢 Ejercicio 14.46 · Cuántas palabras y letras

Cuenta las **líneas, palabras y caracteres** de `poema.txt` (una sola orden).

<details>
<summary>💡 Ver solución</summary>


```bash
wc poema.txt
```

_Resultado:_

```text
 16  75 455 poema.txt
```


Salen tres números y el nombre del fichero: líneas, palabras y bytes. `-l`, `-w`, `-c` (bytes) o `-m` (caracteres) por separado.
</details>


#### 🟢 Ejercicio 14.47 · Saltar la cabecera

Muestra `usuarios.csv` **sin la primera línea** (la cabecera), las 3 primeras líneas del resto.

<details>
<summary>💡 Ver solución</summary>


```bash
tail -n +2 usuarios.csv | head -3
# Otra forma equivalente:
sed '1d' usuarios.csv | head -3
```

_Resultado:_

```text
1,Juan,Flores,juan.flores@cas-training.com,34,Madrid,2450.50
2,Ana,García,ana.garcia@ejemplo.org,28,Barcelona,2100.00
3,Luis,Pérez,luis.perez@ejemplo.com,45,Sevilla,3200.75
```


`tail -n +2` significa "desde la línea 2 en adelante".
</details>


#### 🟡 Ejercicio 14.48 · Numerar las líneas

Muestra las 5 primeras líneas de `poema.txt` **numeradas**.

<details>
<summary>💡 Ver solución</summary>


```bash
head -5 poema.txt | nl
```

_Resultado:_

```text
     1	¿Qué es poesía?, dices mientras clavas
     2	en mi pupila tu pupila azul.
     3	¿Qué es poesía? ¿Y tú me lo preguntas?
     4	Poesía... eres tú.
       
```


`nl` numera (por defecto solo las líneas no vacías). Con `-ba` numera todas.
</details>


#### 🟡 Ejercicio 14.49 · Juntar en una línea

Une las 5 primeras líneas de `palabras.txt` en una sola, separadas por comas.

<details>
<summary>💡 Ver solución</summary>


```bash
head -5 palabras.txt | paste -sd,
```

_Resultado:_

```text
gato,Gato,GATO,gata,gatito
```


`paste -s` pega todas las líneas en una; `-d,` usa la coma como separador.
</details>


#### 🟡 Ejercicio 14.50 · Cortar líneas largas

Muestra las dos primeras líneas de `poema.txt` **cortadas a 25 caracteres** de ancho, sin partir palabras.

<details>
<summary>💡 Ver solución</summary>


```bash
head -2 poema.txt | fold -s -w 25
```

_Resultado:_

```text
¿Qué es poesía?, 
dices mientras clavas
en mi pupila tu pupila 
azul.
```


`fold -w 25` corta a 25 columnas; `-s` lo hace en los **espacios** para no partir palabras. (Para **alinear en columnas** existe `column -t`, por ejemplo `column -t -s: /etc/passwd`.)
</details>


#### 🟡 Ejercicio 14.51 · Invertir

Muestra las 3 últimas líneas de `palabras.txt` en orden inverso (la última primero), y la palabra `Linux` al revés.

<details>
<summary>💡 Ver solución</summary>


```bash
tail -3 palabras.txt | tac
echo Linux | rev
```

_Resultado:_

```text
casa
gato
fgrep
xuniL
```


`tac` (cat al revés) invierte el **orden de las líneas**; `rev` invierte los **caracteres** de cada línea.
</details>


#### 🟡 Ejercicio 14.52 · `xargs`: de lista a argumentos

Cuenta las líneas de **cada uno** de los ficheros que contienen la palabra `alumno` en `/etc` (usa `grep -rl` + `xargs wc -l`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -rl alumno /etc | xargs wc -l
```

_Resultado:_

```text
  45 /etc/ssh/sshd_config
  56 /etc/group
  41 /etc/passwd
 142 total
```


`xargs` convierte la lista de nombres (una por línea) en **argumentos** de `wc -l`. (Si algún nombre tuviera espacios, usarías `grep -rlZ … | xargs -0`.)
</details>


#### 🟡 Ejercicio 14.53 · `cut` frente a `grep -o`

Obtén los **nombres de usuario** de `/etc/passwd` de **dos maneras** distintas (una con `cut`, otra con `grep -o`) y comprueba que coinciden.

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f1 /etc/passwd | head -4
# Otra forma equivalente:
grep -o '^[^:]*' /etc/passwd | head -4
```

_Resultado:_

```text
root
daemon
bin
sys
```

</details>


#### 🔴 Ejercicio 14.54 · Los usuarios que comparten GID

Muestra los **GID** de `/etc/passwd` que **usa más de un usuario**, con cuántos.

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f4 /etc/passwd | sort | uniq -c | grep -vE '^ +1 ' | sort -rn
```

_Resultado:_

```text
      4 65534
      2 34
      2 1100
      2 1
```


`cut` aísla el GID, `sort | uniq -c` cuenta y `grep -vE '^ +1 '` oculta los que solo salen una vez.
</details>


#### 🔴 Ejercicio 14.55 · ¿Qué día hubo más eventos?

Cuenta cuántas líneas de `syslog` hay **por día** y ordena de más a menos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^Nov +[0-9]+' /var/log/syslog | sort | uniq -c | sort -rn
```

_Resultado:_

```text
     63 Nov  5
     48 Nov  4
     11 Nov  6
```

</details>


#### 🔴 Ejercicio 14.56 · El "top 3" de procesos de syslog con `sed`

Obtén el ranking de **programas** que más escriben en `syslog` (el programa es la palabra tras el nombre de máquina), con **un solo `sed`** para extraerlo y la cadena habitual para contar.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -E 's/^[A-Z][a-z]{2} +[0-9]+ [0-9:]+ [^ ]+ ([^ :[]+).*/\1/' /var/log/syslog | sort | uniq -c | sort -rn | head -3
```

_Resultado:_

```text
     46 systemd
     28 CRON
     25 kernel
```


La regex describe **toda la línea** (fecha, hora, máquina, programa y resto) y el grupo `\1` se queda con el programa.
</details>


---

## ✅ Resumen del capítulo 14

| Quiero… | Herramienta |
|---|---|
| **Sustituir** texto | `sed 's/viejo/nuevo/g'` |
| **Borrar** líneas | `sed '/regex/d'` (≡ `grep -v`) |
| Imprimir solo ciertas líneas | `sed -n '5p'` · `'3,5p'` · `'/a/,/b/p'` |
| **Reordenar** campos | `sed -E 's/(…)(…)/\2\1/'` |
| Modificar el fichero | `sed -i.bak '…' fichero` (¡copia primero!) |
| Elegir **columnas** | `cut -d: -f1,7` |
| **Ordenar** | `sort` (`-n` numérico, `-r` inverso, `-t -k` campos, `-u` únicos) |
| **Contar** repetidos | `sort \| uniq -c \| sort -rn` |
| Cambiar/borrar **caracteres** | `tr` |
| Contar líneas, palabras, bytes | `wc` |
| Pasar de líneas a argumentos | `xargs` |

**Orden de elección:** `grep -c` / `grep -o` (un comando) → `grep -oP` con `\K` → `sed -E` → `cut`/`tr`/`sort`… en tubería.

➡️ **Siguiente parada:** [Capítulo 15](15-vi-find-locate.md): las regex fuera de `grep`: **`vi`, `less`, `find -regex`, `locate`** (¡y el examen 104.7!).

---
⬅️ [Capítulo 13 · Nivel master: `grep -P`, `\K` y mirar alrededor](13-nivel-master.md) · 🏠 [Índice](README.md) · [Capítulo 15 · Regex fuera de `grep`: `less`, `vi`, `find`, `locate`](15-vi-find-locate.md) ➡️
