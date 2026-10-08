# Capítulo 17 · 🚰 La fontanería de Linux: entradas, salidas y tuberías

> 🎯 **Objetivo:** dominar de verdad los **flujos de datos**: de dónde lee un comando, adónde escribe, adónde van sus errores, cómo se encadenan los comandos con **tuberías** (`|`) y cómo se **redirige** todo (`>`, `>>`, `<`, `2>`, `2>&1`, `<<`, `<<<`, `tee`, `xargs`, `$( )`, `<( )`…).
>
> 📘 **LPIC-1:** **103.4** (*Usar flujos, tuberías y redirecciones*), con trozos de 103.1 (listas de órdenes, `$( )`) y 103.2 (filtros).
>
> 🧪 `cd ~/lab-regex`
>
> 🗺️ **¿Cuándo leerlo?** Cuando termines el [capítulo 9](09-opciones-de-grep.md) (allí viste lo básico). Es un capítulo **"de fontanería"**: no es regex pura, pero **todos** los capítulos que siguen (10 a 16) usan tuberías sin parar. Si te atascas con alguna `|` o `2>&1` más adelante, vuelve aquí.

---

## 17.1 · La casa de las tuberías

Imagina cada comando como una **máquina** con tres conexiones:

```text
                  ┌───────────────────┐
  0  stdin  ────▶ │                   │ ────▶  1  stdout   (lo que sale BIEN)
  (entrada)       │      COMANDO      │
                  │                   │ ────▶  2  stderr   (los ERRORES)
                  └───────────────────┘
```

| Nº | Nombre | Qué es | ¿Adónde va **por defecto**? |
|---:|---|---|---|
| **0** | `stdin` (*standard input*) | lo que el comando **lee** | el **teclado** |
| **1** | `stdout` (*standard output*) | el resultado **normal** | la **pantalla** |
| **2** | `stderr` (*standard error*) | los **mensajes de error** | la **pantalla** (¡también!) |

Esos números (**0, 1, 2**) se llaman *descriptores de fichero*. Cuando haces `>`, `2>`, `<` … lo único que haces es **cambiar adónde apunta** una de esas tres conexiones: en vez de la pantalla, un fichero; en vez del teclado, otro comando.

Como `stdout` y `stderr` salen **por la misma pantalla**, a simple vista parecen lo mismo. Pero no lo son. Prueba con dos ficheros, uno que existe y otro que no:

```bash
ls /etc/hostname /no/existe
```

_Resultado:_

```text
ls: cannot access '/no/existe': No such file or directory
/etc/hostname
```


Salen **dos cosas**: el nombre del fichero que existe (por `stdout`) y una queja por el que no existe (por `stderr`). *(El mensaje sale en inglés porque el laboratorio usa el idioma neutro `C`; en un Ubuntu en español dirá «No existe el fichero o el directorio». Y `ls` termina con código 2, que es lo normal cuando algún argumento falla.)* Vamos a separarlas. Primero **tiramos la salida normal** (a `/dev/null`, el agujero negro de Linux):

```bash
ls /etc/hostname /no/existe > /dev/null
```

_Resultado:_

```text
ls: cannot access '/no/existe': No such file or directory
```


Solo queda el error. Y ahora al revés, **tiramos los errores**:

```bash
ls /etc/hostname /no/existe 2> /dev/null
```

_Resultado:_

```text
/etc/hostname
```


Solo queda el resultado normal. ¡Ya sabes distinguir los dos canales!

> 💡 `>` es una abreviatura de `1>`. Es decir: **`ls > f`** y **`ls 1> f`** son lo mismo. Y `<` es una abreviatura de `0<`.

---

## 17.2 · Guardar la salida: `>` y `>>`

| Símbolo | Qué hace | Si el fichero ya existe… |
|---|---|---|
| `comando > fichero` | manda `stdout` al fichero | lo **vacía** y lo escribe de nuevo ⚠️ |
| `comando >> fichero` | **añade** `stdout` al final | conserva lo anterior y añade |
| `> fichero` (solo) | no ejecuta nada, pero **crea o vacía** el fichero | lo vacía |

Si el fichero no existe, los dos lo **crean**.

```bash
grep ':/bin/bash$' /etc/passwd > usuarios-bash.txt
echo "(No ha salido nada por pantalla: todo ha ido al fichero.)"
cat usuarios-bash.txt
```

_Resultado:_

```text
(No ha salido nada por pantalla: todo ha ido al fichero.)
root:x:0:0:root:/root:/bin/bash
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/bash
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/bash
ana:x:1001:1001:Ana Garcia,,,:/home/ana:/bin/bash
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro:/bin/bash
```


Y para añadir:

```bash
echo "== Usuarios con bash ==" > lista.txt
grep ':/bin/bash$' /etc/passwd | cut -d: -f1 >> lista.txt
echo "== fin ==" >> lista.txt
cat lista.txt
```

_Resultado:_

```text
== Usuarios con bash ==
root
postgres
alumno
ana
pedro
== fin ==
```


(La primera línea usa `>` para **empezar** el fichero de cero; las demás, `>>`, para **añadir**.)

### ⚠️ La trampa más famosa: leer y escribir el mismo fichero

El shell prepara la redirección **antes** de arrancar el comando. Así que `>` **vacía el fichero antes de que el comando lo lea**:

```bash
printf 'b\na\nc\n' > letras.txt
sort letras.txt > letras.txt
echo "Contenido de letras.txt: [$(cat letras.txt)]"
```

_Resultado:_

```text
Contenido de letras.txt: []
```


¡El fichero ha quedado **vacío**! `sort` abrió `letras.txt`… ya vacío. La forma correcta es dejar que el comando escriba él mismo (`sort -o`), o usar un fichero intermedio:

```bash
printf 'b\na\nc\n' > letras.txt
sort -o letras.txt letras.txt
cat letras.txt
```

_Resultado:_

```text
a
b
c
```


### 🛡️ El cinturón de seguridad: `noclobber`

Si no te fías de ti, bash puede **negarse a pisar** ficheros que ya existen:

```bash
echo uno > nc.txt
set -o noclobber
echo dos > nc.txt
echo "código de salida: $?"
echo dos >| nc.txt        # '>|' = "sí, pisa, sé lo que hago"
cat nc.txt
```

_Resultado:_

```text
bash: nc.txt: cannot overwrite existing file
código de salida: 1
dos
```


(`set +o noclobber` lo desactiva.)

---

## 17.3 · Guardar los errores: `2>` y `2>>`

```bash
grep root /etc/passwd /no/existe 2> errores.txt
echo "--- errores.txt:"
cat errores.txt
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
--- errores.txt:
grep: /no/existe: No such file or directory
```


Por pantalla solo salió la línea de `root` (`stdout`); el error se fue al fichero. Y `2>>` **añade** en vez de pisar. Y se pueden repartir **los dos canales en dos ficheros a la vez**:

```bash
grep root /etc/passwd /no/existe > salida.txt 2> errores.txt
echo "--- salida.txt:";  cat salida.txt
echo "--- errores.txt:"; cat errores.txt
```

_Resultado:_

```text
--- salida.txt:
/etc/passwd:root:x:0:0:root:/root:/bin/bash
--- errores.txt:
grep: /no/existe: No such file or directory
```


### `2>/dev/null` frente a `grep -s`

Ya conoces `-s` (capítulo 9): "silencio con los errores de fichero". ¿Es lo mismo que `2>/dev/null`? **No del todo**:

- `-s` solo oculta los errores de **fichero** (no existe, sin permiso…).
- `2>/dev/null` oculta **todo lo que salga por `stderr`**, incluso un error de sintaxis en tu regex.

```bash
grep -s '[' /etc/passwd ; echo "código: $?"
grep    '[' /etc/passwd 2>/dev/null ; echo "código: $?"
```

_Resultado:_

```text
grep: Invalid regular expression
código: 2
código: 2
```


El primero **sigue quejándose** de la regex inválida (`-s` no lo oculta); el segundo la ha escondido… y por eso es **más peligroso**: puedes pasarte media hora sin saber por qué no sale nada. Fíjate también en el **código de salida: `2`** (error), no `1` (sin coincidencias).

> 🧠 **Regla de oro:** mientras depuras, **no uses `2>/dev/null`**. Ponlo al final, cuando ya sepas que el comando funciona.

---

## 17.4 · Juntar los canales: `2>&1`, `&>` y `>&2`

Para meter **salida y errores en el mismo sitio** (un fichero, una tubería):

| Forma | Significa |
|---|---|
| `comando > f 2>&1` | `stdout` a `f`, y `stderr` **adonde apunte ahora `stdout`** (o sea, también a `f`) |
| `comando &> f` | lo mismo, abreviado (bash) |
| `comando &>> f` | lo mismo, **añadiendo** |
| `comando >&2` o `1>&2` | manda **mi salida normal por el canal de errores** (útil en scripts: avisos) |

```bash
grep root /etc/passwd /no/existe > todo.txt 2>&1
cat todo.txt
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
grep: /no/existe: No such file or directory
```


### 🔥 ¡El orden importa!

`2>&1` significa "haz que el canal 2 apunte **a donde apunta el 1 en este momento**". Se procesa **de izquierda a derecha**. Mira lo que pasa si lo pones **antes** de la redirección del `1`:

```bash
grep root /etc/passwd /no/existe 2>&1 > solo-salida.txt
echo "--- solo-salida.txt:"
cat solo-salida.txt
```

_Resultado:_

```text
grep: /no/existe: No such file or directory
--- solo-salida.txt:
/etc/passwd:root:x:0:0:root:/root:/bin/bash
```


Ahora el **error salió por pantalla** (y no al fichero). Razón: cuando se ejecutó `2>&1`, el canal 1 todavía apuntaba a la pantalla, así que el 2 se pegó a la pantalla; después el 1 se movió al fichero, pero el 2 ya no lo siguió.

```text
 > f 2>&1   →  1 va a f;        luego 2 copia a 1 (f)         → TODO en f   ✅
 2>&1 > f   →  2 copia a 1 (pantalla); luego 1 va a f         → errores en pantalla
```

> 🧠 **Truco para recordarlo:** léelo como *"el 2 copia el destino que tiene el 1 **en ese instante**"*. Primero pon el destino del 1 y luego copia.

---

## 17.5 · Leer de un fichero: `<`

`<` hace que el comando **lea de un fichero** en vez del teclado. Muchos comandos (`grep`, `wc`, `sort`…) aceptan además el fichero como argumento. ¿Qué diferencia hay?

```bash
wc -l /etc/passwd
wc -l < /etc/passwd
```

_Resultado:_

```text
41 /etc/passwd
41
```


Con el fichero como argumento, `wc` **sabe su nombre** y lo imprime. Con `<`, `wc` solo ve un chorro de datos anónimo ("**estoy leyendo de `stdin`**") y no tiene nombre que imprimir. Es la forma de que te salga **solo el número**.

Con `grep` pasa igual: con `<` no hay nombre de fichero. Si lo quieres, `-H` imprime el nombre que `grep` conoce… que es `(standard input)`:

```bash
grep -H root < /etc/passwd
```

_Resultado:_

```text
(standard input):root:x:0:0:root:/root:/bin/bash
```


> 💡 Muchos comandos usan **`-`** como nombre del fichero para decir "mi `stdin`": `grep root -`, `cat -`, `diff - fichero`. Y existe el fichero especial `/dev/stdin`.

### 🐱 El `cat` inútil (*useless use of cat*)

```text
cat /etc/passwd | grep root       ← un proceso de más
grep root /etc/passwd             ← lo mismo, mejor
grep root < /etc/passwd           ← también
```

Con tu filosofía de **"mínimo número de comandos"**: si el segundo comando sabe leer un fichero, no hace falta `cat |`. (El `cat` sí tiene sentido para **juntar** varios ficheros: `cat a b | grep x`.)

---

## 17.6 · Texto "pegado" en la orden: `<<` (here-doc) y `<<<` (here-string)

A veces quieres alimentar a un comando **con un texto escrito ahí mismo**, sin crear un fichero.

### `<<<` — una cadena (*here-string*)

```bash
grep -E '^[0-9]{3}$' <<< '123'
echo "código: $?"
grep -E '^[0-9]{3}$' <<< '12'
echo "código: $?"
```

_Resultado:_

```text
123
código: 0
código: 1
```


¡Es **el mejor aliado para aprender regex**! Pruebas una expresión contra un texto sin crear ficheros. `grep` sale con `0` si casó y con `1` si no.

### `<<FIN` — varias líneas (*here-document*)

```bash
grep -n 'b' <<'FIN'
abc
xyz
bbb
FIN
```

_Resultado:_

```text
1:abc
3:bbb
```


Todo lo que hay entre `<<'FIN'` y la línea que contiene solo `FIN` se convierte en el `stdin` del comando. La palabra `FIN` la eliges tú. **Las comillas `'FIN'` importan**:

```bash
nombre=Ana
cat <<FIN
Hola $nombre, hoy es un buen día.
FIN
cat <<'FIN'
Hola $nombre, hoy es un buen día.
FIN
```

_Resultado:_

```text
Hola Ana, hoy es un buen día.
Hola $nombre, hoy es un buen día.
```


- Sin comillas (`<<FIN`): el shell **sustituye** variables y `$( )` dentro del texto.
- Con comillas (`<<'FIN'`): el texto sale **literal** (lo normal cuando pegas código o regex con `$`).

Y `<<-FIN` permite **sangrar** el texto con tabuladores (se quitan al leer).

---

## 17.7 · La tubería `|`

```text
comando1 │ comando2
   stdout ──▶ stdin
```

La tubería conecta el **`stdout` del primero** con el **`stdin` del segundo**. Cosas que debes saber (y que se preguntan en el examen):

1. 🔀 **Los dos comandos arrancan a la vez** y trabajan en paralelo: no espera uno a que acabe el otro. Los datos fluyen como el agua.
2. 🚫 **Solo pasa `stdout`.** Los errores (`stderr`) **no entran** en la tubería: siguen saliendo por pantalla.
3. 🔚 Si el segundo comando termina antes (por ejemplo, `head`), el primero recibe una señal `SIGPIPE` y **se detiene**.
4. 🔢 El **código de salida** de la tubería es el del **último** comando.

Compruébalo. Los errores **se escapan** de la tubería:

```bash
grep root /etc/passwd /no/existe | wc -l
```

_Resultado:_

```text
grep: /no/existe: No such file or directory
1
```


`wc` contó **1** línea (la de `root`); el error salió directo a la pantalla. Para meter **también** los errores en la tubería: `2>&1 |` o su abreviatura **`|&`**:

```bash
grep root /etc/passwd /no/existe 2>&1 | wc -l
grep root /etc/passwd /no/existe |& wc -l
```

_Resultado:_

```text
2
2
```


### El código de salida de una tubería

```bash
grep -c zzz /etc/passwd | wc -l
echo "Código de la tubería: $?"
```

_Resultado:_

```text
1
Código de la tubería: 0
```


`$?` dice `0` aunque el `grep` **no encontró nada** (su código era 1). ¿Por qué? Porque `$?` es el del **último** (`wc`, que funcionó). Para ver **el de todos** existe el *array* `PIPESTATUS`:

```bash
grep -c zzz /etc/passwd | wc -l
echo "Códigos de cada comando: ${PIPESTATUS[@]}"
```

_Resultado:_

```text
1
Códigos de cada comando: 1 0
```


(`1 0`: el `grep` devolvió 1; el `wc`, 0.) Y con `set -o pipefail` la tubería entera falla si **cualquiera** de sus comandos falla:

```bash
set -o pipefail
grep -c zzz /etc/passwd | wc -l
echo "Código con pipefail: $?"
```

_Resultado:_

```text
1
Código con pipefail: 1
```


### `head` corta el grifo: SIGPIPE

```bash
yes | head -3
echo "códigos: ${PIPESTATUS[@]}"
```

_Resultado:_

```text
y
y
y
códigos: 141 0
```


`yes` escribe "y" **eternamente**… y aun así el comando termina enseguida: cuando `head` ha leído sus 3 líneas se cierra, y `yes` recibe `SIGPIPE` y muere (**141 = 128 + 13**, el número de esa señal).

> 💡 **Búfer de línea.** Cuando un comando escribe en una tubería, acumula datos antes de enviarlos (*búfer*). Si encadenas `grep` con `tail -f` verás que "tarda en salir". La solución: **`grep --line-buffered`** (envía cada línea al momento). Ejemplo típico: `tail -f /var/log/auth.log | grep --line-buffered Failed | cut -d' ' -f1-3` (no se puede ejecutar aquí: no termina nunca).

---

## 17.8 · `tee`: guardar **y** seguir

`tee` es una "T" de fontanería: **copia** lo que le llega a un fichero **y lo deja seguir** por la tubería.

| Forma | Hace |
|---|---|
| `... \| tee f \| ...` | guarda en `f` (**pisa**) y deja pasar |
| `... \| tee -a f \| ...` | guarda **añadiendo** |
| `... \| tee f1 f2` | guarda en varios ficheros |

```bash
grep ':/bin/bash$' /etc/passwd | tee con-bash.txt | cut -d: -f1
echo "--- y en el fichero quedaron las líneas completas:"
cat con-bash.txt
```

_Resultado:_

```text
root
postgres
alumno
ana
pedro
--- y en el fichero quedaron las líneas completas:
root:x:0:0:root:/root:/bin/bash
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/bash
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/bash
ana:x:1001:1001:Ana Garcia,,,:/home/ana:/bin/bash
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro:/bin/bash
```


Muy útil para **depurar** una tubería larga: pones un `tee paso1.txt` a medio camino y miras qué iba por ahí.

### `sudo` y las redirecciones: el truco del `tee`

Esto confunde a todo el mundo. Las redirecciones (`>`) las hace **tu shell**, **antes** de ejecutar `sudo`, así que **no tienen privilegios**:

> ⚠️ Este ejemplo usa `sudo` para escribir en `/opt`, una carpeta de `root`. En el contenedor de prácticas es inocuo. En tu Ubuntu real puedes leerlo sin ejecutarlo (se crea y se borra un fichero de prueba).

```bash
sudo echo hola > /opt/prueba.txt
echo "código: $?"
echo hola | sudo tee /opt/prueba.txt > /dev/null
cat /opt/prueba.txt
sudo rm /opt/prueba.txt
```

_Resultado:_

```text
bash: /opt/prueba.txt: Permission denied
código: 1
hola
```


El primero falla (`Permission denied`): `sudo echo` funcionó, pero el `>` lo hizo tu shell sin permisos. El segundo funciona porque **`tee` corre con `sudo`** y es `tee` quien abre el fichero. (Se añade `> /dev/null` solo para que `tee` no repita el texto por pantalla.) Variante para añadir: `sudo tee -a`.

---

## 17.9 · `xargs`: convertir una lista en argumentos

¡Cuidado, esto es un clásico de examen! **Tubería** y **argumentos** son cosas distintas:

- la tubería envía **datos por `stdin`**;
- pero muchos comandos (`rm`, `cp`, `ls`, `cat`, `wc`, `grep fichero`…) esperan los nombres de fichero **como argumentos**, no por `stdin`.

```bash
echo /etc/hostname | cat
echo /etc/hostname | xargs cat
```

_Resultado:_

```text
/etc/hostname
ubuntu-pc
```


El primero **imprime el texto** `/etc/hostname` (cat lee su `stdin`, que es ese texto). El segundo hace que `xargs` construya la orden **`cat /etc/hostname`**: el texto pasa a ser el **argumento**. Eso es `xargs`.

Opciones que debes conocer:

| Opción | Hace |
|---|---|
| `-n N` | máximo **N argumentos** por ejecución |
| `-I{}` | sustituye `{}` en la orden por **cada** elemento (uno por ejecución) |
| `-0` | los elementos se separan por **byte NUL** (se combina con `find -print0` o `grep -Z`) |
| `-r` | **no ejecuta** si no llega nada (GNU) |
| `-d '\n'` | separador personalizado (GNU) |

```bash
cut -d: -f1 /etc/passwd | head -6 | xargs
cut -d: -f1 /etc/passwd | head -6 | xargs -n 2
```

_Resultado:_

```text
root daemon bin sys sync games
root daemon
bin sys
sync games
```


(Sin más, `xargs` mete **todo en una fila**: el `echo` por defecto. Con `-n 2`, de dos en dos.)

### ¿Y si los nombres tienen espacios?

`xargs` separa por espacios y saltos de línea. Un nombre como `mi informe.txt` se rompería en dos. La solución: separar con el carácter **NUL** (imposible en un nombre de fichero):

```bash
mkdir -p tmp
echo hola > "tmp/mi informe.txt"
echo hola > "tmp/otro.txt"
echo "--- sin -0:"
find tmp -name '*.txt' | xargs grep -l hola 2>&1 | sort
echo "--- con -print0 / -0:"
find tmp -name '*.txt' -print0 | xargs -0 grep -l hola | sort
```

_Resultado:_

```text
--- sin -0:
grep: informe.txt: No such file or directory
grep: tmp/mi: No such file or directory
tmp/otro.txt
--- con -print0 / -0:
tmp/mi informe.txt
tmp/otro.txt
```


Sin `-0`, `xargs` intentó abrir `tmp/mi` e `informe.txt`, que no existen (esos son los dos avisos de `grep:`). Con `-print0 … -0` funciona. (El `| sort` del final solo sirve para que el orden salga siempre igual: `find` lista los ficheros en el orden en que el disco los guarda.) Para `grep` existe el equivalente `grep -rlZ` + `xargs -0`.

### La alternativa: sustitución de comandos `$( )`

`$( comando )` se **sustituye por la salida** del comando, ahí mismo, antes de ejecutar la orden. Sirve para lo mismo que `xargs` cuando la lista es corta y sin espacios:

```bash
wc -l $(grep -rl root sistema/etc | sort)
```

_Resultado:_

```text
   9 sistema/etc/crontab
  12 sistema/etc/fstab
  57 sistema/etc/group
  41 sistema/etc/passwd
 119 total
```


Y para **construir patrones** al vuelo:

```bash
grep "^$(id -un):" /etc/passwd
```

_Resultado:_

```text
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/bash
```


(`id -un` es tu nombre de usuario; el patrón queda `^alumno:`. Fíjate: **comillas dobles**, porque las simples impedirían la sustitución.) Existe la forma antigua con acentos graves `` `comando` ``: hace lo mismo, pero **no se puede anidar** bien. Usa siempre `$( )`.

---

## 17.10 · Dos trucos de maestro: `<( )` y `{ …; }`

### Sustitución de procesos `<( comando )`

Hace que la **salida de un comando parezca un fichero**. Útil cuando un comando necesita **ficheros**, no `stdin`. Por ejemplo, `comm` compara dos listas ya ordenadas:

```bash
comm -12 <(grep ':/bin/bash$' /etc/passwd | cut -d: -f1 | sort) <(grep -oP '^sudo:.*:\K.*' /etc/group | tr ',' '\n' | sort)
```

_Resultado:_

```text
alumno
ana
```


`comm -12` muestra solo lo **común** (usuarios con bash **y** que están en el grupo `sudo`). Todo con una sola línea y sin ficheros temporales.

Con `grep -f` se puede usar para que **los patrones salgan de otro comando**:

```bash
grep -owFf <(cut -d: -f1 /etc/passwd) /var/log/auth.log | sort | uniq -c | sort -rn | head -5
```

_Resultado:_

```text
     45 sshd
     25 root
     20 alumno
     10 luis
      6 bin
```


`-F` (texto fijo) `-w` (palabra entera) `-f` (patrones desde un "fichero", que aquí es la lista de usuarios del sistema) `-o` (solo lo coincidente): "cuántas veces aparece cada usuario del sistema en `auth.log`".

### Agrupar con `{ …; }` y `( … )`

Las llaves **agrupan comandos** para redirigir todos juntos. (Ojo: `{` y `}` van **separadas por espacios** y la última orden acaba en `;`.)

```bash
{ echo "Usuarios:"; cut -d: -f1 /etc/passwd | head -3; echo "Fin."; } > informe.txt
cat informe.txt
```

_Resultado:_

```text
Usuarios:
root
daemon
bin
Fin.
```


```bash
{ echo uno; echo "esto es un error" >&2; } 2>/dev/null
echo "---"
{ echo uno; echo "esto es un error" >&2; } 2>&1 | wc -l
```

_Resultado:_

```text
uno
---
2
```


Las llaves los ejecutan en el shell actual; los paréntesis `( … )`, en un **subshell** (copia aparte: las variables que cambies dentro **no** afectan al exterior).

---

## 17.11 · Encadenar órdenes: `;` `&&` `||`

| Símbolo | Significa |
|---|---|
| `a ; b` | ejecuta `a` y **después** `b`, pase lo que pase |
| `a && b` | ejecuta `b` **solo si `a` salió bien** (código 0) |
| `a \|\| b` | ejecuta `b` **solo si `a` falló** (código ≠ 0) |

Y `grep` encaja perfecto: **0 = encontró**, **1 = no encontró**, **2 = error**:

```bash
grep -q '^alumno:' /etc/passwd && echo "alumno existe"
grep -q '^fantasma:' /etc/passwd || echo "fantasma no existe"
```

_Resultado:_

```text
alumno existe
fantasma no existe
```


(`-q` = silencio: solo interesa el código.) Y con `if`, más claro:

```bash
if grep -q '^root:' /etc/passwd; then echo "root existe"; else echo "root no existe"; fi
```

_Resultado:_

```text
root existe
```


> 🪤 **Cuidado:** `a && b || c` **no** es un `if…else`. Si `a` sale bien pero **`b` falla**, ¡también se ejecuta `c`! Lo verás en un ejercicio.

---

## 17.12 · Ficheros especiales y descriptores a mano

| Fichero | Qué es |
|---|---|
| `/dev/null` | **agujero negro**: todo lo que se escribe desaparece; al leerlo está vacío |
| `/dev/zero` | un chorro infinito de bytes `0` |
| `/dev/stdin` `/dev/stdout` `/dev/stderr` | tus canales 0, 1 y 2 **como ficheros** |
| `/dev/tty` | tu terminal |

```bash
head -c 4 /dev/zero | od -An -tx1
```

_Resultado:_

```text
 00 00 00 00
```


(`od` muestra los bytes en hexadecimal: cuatro bytes `00` salidos de `/dev/zero`.)

El 0, 1 y 2 vienen "de serie", pero tú puedes abrir **más descriptores** (del 3 al 9) con `exec`:

```bash
exec 3< /etc/passwd
read -u 3 linea1
read -u 3 linea2
echo "$linea1"
echo "$linea2"
exec 3<&-
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
```


(Se abre el 3 para **leer** `/etc/passwd`, se leen dos líneas seguidas —cada `read` **continúa** donde lo dejó el anterior—, y `3<&-` lo **cierra**.)

Y los **tubos con nombre** (*FIFO*): una tubería que vive como fichero.

```bash
mkfifo tuberia
(echo "hola por la tubería" > tuberia &)
cat tuberia
rm tuberia
```

_Resultado:_

```text
hola por la tubería
```


---

## 17.13 · 🏋️ Ejercicios

> 🔧 Todos estos ejercicios se ejecutaron en el [entorno virtual](entorno-virtual/README.md) del libro. Cada comando ocupa **una sola línea larga** cuando se puede (¡el mínimo de comandos!) y, cuando hay que encadenar varios con `|`, el ejercicio te dice por qué.

#### 🟢 Ejercicio 17.1 · Guardar usuarios con bash

Guarda en `bash.txt` solo los **nombres** (primer campo) de los usuarios de `/etc/passwd` cuyo intérprete es `/bin/bash`, y muéstralos con `cat`. *(Una pista: `grep -oP` te da el nombre en un solo comando.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^[^:]+(?=:.*:/bin/bash$)' /etc/passwd > bash.txt ; cat bash.txt
```

_Resultado:_

```text
root
postgres
alumno
ana
pedro
```


`grep -oP` extrae el nombre y `>` lo guarda. (Con `;` ejecutamos después el `cat` para ver el resultado.)
</details>


#### 🟢 Ejercicio 17.2 · Una cabecera y un pie

Crea `lista.txt` con tres cosas, en este orden: la línea `== Usuarios ==`, los nombres de usuario que usan `/bin/bash` y la línea `== Fin ==`. Hazlo (a) con `>` y `>>` y (b) con un grupo `{ …; }`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo '== Usuarios ==' > lista.txt ; grep -oP '^[^:]+(?=:.*:/bin/bash$)' /etc/passwd >> lista.txt ; echo '== Fin ==' >> lista.txt ; cat lista.txt
# Otra forma equivalente:
{ echo '== Usuarios =='; grep -oP '^[^:]+(?=:.*:/bin/bash$)' /etc/passwd; echo '== Fin =='; } > lista.txt ; cat lista.txt
```

_Resultado:_

```text
== Usuarios ==
root
postgres
alumno
ana
pedro
== Fin ==
```


En (a) el primer `>` crea el fichero y los `>>` añaden. En (b) las llaves hacen que **un solo** `>` recoja la salida de los tres comandos (y no hay riesgo de pisar nada a medias).
</details>


#### 🟢 Ejercicio 17.3 · Contar sin nombre

Muestra **solo el número** de líneas de `/etc/passwd` (sin el nombre del fichero a su lado).

<details>
<summary>💡 Ver solución</summary>


```bash
wc -l < /etc/passwd
```

_Resultado:_

```text
41
```


Con `<`, `wc` lee de `stdin` y no conoce ningún nombre de fichero que imprimir.
</details>


#### 🟢 Ejercicio 17.4 · ¿Salida o error?

`ls /etc/hostname /no/existe` produce una salida normal y un error. Haz que **solo se vea el error**.

<details>
<summary>💡 Ver solución</summary>


```bash
ls /etc/hostname /no/existe > /dev/null
```

_Resultado:_

```text
ls: cannot access '/no/existe': No such file or directory
```


`> /dev/null` tira el canal 1 (la salida normal). El canal 2 sigue yendo a la pantalla.
</details>


#### 🟡 Ejercicio 17.5 · Dos ficheros a la vez

Ejecuta `grep -r root /etc` guardando los **resultados** en `resultados.txt` y los **errores** en `errores.txt`, todo en el mismo comando. Luego cuenta las líneas de cada fichero. *(Hay ficheros de `/etc` que tu usuario no puede leer.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -r root /etc > resultados.txt 2> errores.txt ; wc -l resultados.txt errores.txt
```

_Resultado:_

```text
  79 resultados.txt
   8 errores.txt
  87 total
```


`> resultados.txt` recoge el canal 1 y `2> errores.txt`, el 2. Las líneas de `errores.txt` son todos los "Permission denied".
</details>


#### 🟡 Ejercicio 17.6 · El orden de `2>&1`

Explica (ejecutándolos) la diferencia entre estos dos comandos: `grep root /etc/passwd /no/existe > a.txt 2>&1` y `grep root /etc/passwd /no/existe 2>&1 > b.txt`. ¿Qué queda en cada fichero y qué sale por pantalla?

<details>
<summary>💡 Ver solución</summary>


```bash
echo "=== (a) > a.txt 2>&1 : por pantalla no debería salir nada ==="
grep root /etc/passwd /no/existe > a.txt 2>&1
echo "--- contenido de a.txt:"; cat a.txt
echo "=== (b) 2>&1 > b.txt : lo que salga aquí debajo es PANTALLA ==="
grep root /etc/passwd /no/existe 2>&1 > b.txt
echo "--- contenido de b.txt:"; cat b.txt
```

_Resultado:_

```text
=== (a) > a.txt 2>&1 : por pantalla no debería salir nada ===
--- contenido de a.txt:
/etc/passwd:root:x:0:0:root:/root:/bin/bash
grep: /no/existe: No such file or directory
=== (b) 2>&1 > b.txt : lo que salga aquí debajo es PANTALLA ===
grep: /no/existe: No such file or directory
--- contenido de b.txt:
/etc/passwd:root:x:0:0:root:/root:/bin/bash
```


En el primero, `a.txt` recibe **todo**. En el segundo, el error **salió por pantalla** y solo la línea de `root` fue a `b.txt`: el `2>&1` copió el destino del canal 1 cuando todavía era la pantalla.
</details>


#### 🟡 Ejercicio 17.7 · `&>` es lo mismo

Comprueba que `> f 2>&1` y `&> f` guardan exactamente lo mismo.

<details>
<summary>💡 Ver solución</summary>


```bash
grep root /etc/passwd /no/existe > t.txt 2>&1 ; cat t.txt
# Otra forma equivalente:
grep root /etc/passwd /no/existe &> t.txt ; cat t.txt
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
grep: /no/existe: No such file or directory
```


Las dos formas dan la misma salida (el libro lo comprueba automáticamente). `&>` es una abreviatura de bash.
</details>


#### 🟡 Ejercicio 17.8 · `-H` con `stdin`

Haz que `grep root < /etc/passwd` muestre un prefijo que diga `passwd:` delante de la línea, aunque lea de `stdin`. *(Pista: `--label`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -H --label=passwd root < /etc/passwd
```

_Resultado:_

```text
passwd:root:x:0:0:root:/root:/bin/bash
```


`-H` fuerza a mostrar el nombre de fichero y `--label=NOMBRE` cambia el `(standard input)` por el texto que quieras.
</details>


#### 🟡 Ejercicio 17.9 · Probar una regex sin ficheros

Comprueba, **con una here-string** y en un solo comando, si `ana@ejemplo.org` es un correo válido según `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`, imprimiendo `válido` o `inválido`. Pruébalo también con `ana@ejemplo`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -qE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' <<< 'ana@ejemplo.org' && echo válido || echo inválido
grep -qE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' <<< 'ana@ejemplo' && echo válido || echo inválido
```

_Resultado:_

```text
válido
inválido
```


`<<<` alimenta a `grep` con un texto, `-q` lo deja mudo y `&& … ||` decide qué imprimir según el código de salida. (Aquí `&& … ||` funciona bien porque `echo` nunca falla.)
</details>


#### 🟡 Ejercicio 17.10 · Filtro de candidatos

Dadas las cuatro cadenas `192.168.1.1`, `256.1.1.1`, `10.0.0` y `8.8.8.8`, muestra **solo las que son IPv4 válidas**, con un solo `grep` (usa `printf '%s\n'` para dárselas). La regex del octeto es `(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf '%s\n' 192.168.1.1 256.1.1.1 10.0.0 8.8.8.8 | grep -Ex '((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
```

_Resultado:_

```text
192.168.1.1
8.8.8.8
```


`printf '%s\n'` imprime cada argumento en su propia línea; la tubería se las pasa a `grep -Ex` (ERE + línea entera). `256.1.1.1` se descarta porque 256 no cabe en un octeto, y `10.0.0` porque solo tiene 3 grupos.
</details>


#### 🟡 Ejercicio 17.11 · Texto en la propia orden

Con un here-doc, busca **con número de línea** las que empiezan por `ERROR` o `WARN` en este texto, sin crear ningún fichero:

```text
INFO arranque
WARN disco al 90%
INFO usuario alumno
ERROR no se puede abrir el fichero
```

<details>
<summary>💡 Ver solución</summary>


```bash
grep -nE '^(ERROR|WARN)' <<'FIN'
INFO arranque
WARN disco al 90%
INFO usuario alumno
ERROR no se puede abrir el fichero
FIN
```

_Resultado:_

```text
2:WARN disco al 90%
4:ERROR no se puede abrir el fichero
```


Ponemos `'FIN'` entre comillas para que el `%` y cualquier `$` queden literales.
</details>


#### 🟡 Ejercicio 17.12 · El `cat` inútil

Reescribe `cat /etc/passwd | grep root | wc -l` con **un solo comando**.

<details>
<summary>💡 Ver solución</summary>


```bash
cat /etc/passwd | grep root | wc -l
# Otra forma equivalente:
grep -c root /etc/passwd
```

_Resultado:_

```text
1
```


`grep` ya sabe leer el fichero (así que sobra `cat`) y ya sabe contar (`-c`, así que sobra `wc`). Mínimo número de comandos.
</details>


#### 🔴 Ejercicio 17.13 · Usuarios con shell de verdad

Muestra, **ordenados**, los nombres de los usuarios cuyo intérprete **no** es `/usr/sbin/nologin` ni `/bin/false`. Pensado en tubería: `grep` + `cut` + `sort`. Después, hazlo con **un solo `grep -P`** (y `sort`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ev ':(/usr/sbin/nologin|/bin/false)$' /etc/passwd | cut -d: -f1 | sort
# Otra forma equivalente:
grep -oP '^[^:]+(?=(:[^:]*){5}:(?!(/usr/sbin/nologin|/bin/false)$))' /etc/passwd | sort
```

_Resultado:_

```text
alumno
ana
luis
marta
pedro
postgres
root
sync
```


La primera es la tubería "natural": filtrar, quedarse con el campo 1, ordenar. La segunda usa `-o` y una *lookahead* para ahorrarnos `cut`. El `sort` sigue haciendo falta: ningún `grep` ordena.
</details>


#### 🔴 Ejercicio 17.14 · Ranking de atacantes

Escribe el **top 3 de IPs** con más intentos `Failed password` en `/var/log/auth.log`: IP y número de intentos, de más a menos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'Failed password.* from \K[0-9.]+' /var/log/auth.log | sort | uniq -c | sort -rn | head -3
```

_Resultado:_

```text
      5 203.0.113.45
      3 203.0.113.99
      3 198.51.100.23
```


Aquí **sí** hacen falta cinco comandos, y cada uno hace una cosa: `grep -oP` extrae solo la IP (una por intento); `sort` las agrupa; `uniq -c` cuenta los grupos; `sort -rn` ordena de mayor a menor; `head -3` se queda con tres.
</details>


#### 🟡 Ejercicio 17.15 · `tee` a medio camino

Muestra por pantalla solo los **nombres** de los usuarios con `/bin/bash`, pero guarda las **líneas completas** en `con-bash.txt`. Después cuenta las líneas del fichero.

<details>
<summary>💡 Ver solución</summary>


```bash
grep ':/bin/bash$' /etc/passwd | tee con-bash.txt | cut -d: -f1 ; wc -l < con-bash.txt
```

_Resultado:_

```text
root
postgres
alumno
ana
pedro
5
```


`tee` guarda lo que le llega y lo deja pasar a `cut`.
</details>


#### 🟡 Ejercicio 17.16 · Pipe frente a argumentos

¿Qué hacen estos dos comandos y por qué difieren?

```text
echo /etc/hostname | cat
echo /etc/hostname | xargs cat
```

<details>
<summary>💡 Ver solución</summary>


```bash
echo /etc/hostname | cat
echo /etc/hostname | xargs cat
```

_Resultado:_

```text
/etc/hostname
ubuntu-pc
```


El primero imprime **el texto** `/etc/hostname` (`cat` copia su `stdin`). El segundo ejecuta `cat /etc/hostname` y por eso muestra el **contenido** del fichero. `xargs` convierte `stdin` en **argumentos**.
</details>


#### 🔴 Ejercicio 17.17 · Nombres con espacios

En una carpeta `tmp` hay dos ficheros: `mi informe.txt` y `otro.txt`. Los dos contienen la palabra `hola`. Lista los que la contienen **sin que se rompa por el espacio**.

<details>
<summary>💡 Ver solución</summary>


```bash
mkdir -p tmp ; echo hola > "tmp/mi informe.txt" ; echo hola > tmp/otro.txt
find tmp -name '*.txt' -print0 | xargs -0 grep -l hola | sort
```

_Resultado:_

```text
tmp/mi informe.txt
tmp/otro.txt
```


`-print0` separa los nombres con un NUL y `-0` le dice a `xargs` que use ese separador (el `| sort` final solo ordena el resultado). Una alternativa de **un solo comando**: `grep -rl hola tmp` (sin `find` ni `xargs`).
</details>


#### 🔴 Ejercicio 17.18 · Una orden por elemento: `-I{}`

Para cada nombre de la lista `root`, `alumno`, `ana`, muestra **qué línea de `/etc/passwd`** lo tiene como usuario, con el nombre del usuario por delante. *(Usa `xargs -I{}`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
printf '%s\n' root alumno ana | xargs -I{} grep '^{}:' /etc/passwd
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/bash
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/bash
ana:x:1001:1001:Ana Garcia,,,:/home/ana:/bin/bash
```


`xargs` ejecuta `grep '^root:' /etc/passwd`, luego `grep '^alumno:' …`, etc.: una vez por elemento, con `{}` sustituido.
</details>


#### 🟡 Ejercicio 17.19 · De columna a fila

Muestra los 6 primeros nombres de usuario de `/etc/passwd` **en una sola línea separados por espacios**.

<details>
<summary>💡 Ver solución</summary>


```bash
cut -d: -f1 /etc/passwd | head -6 | xargs
# Otra forma equivalente:
cut -d: -f1 /etc/passwd | head -6 | paste -sd' '
# Otra forma equivalente:
echo $(cut -d: -f1 /etc/passwd | head -6)
```

_Resultado:_

```text
root daemon bin sys sync games
```


Tres formas equivalentes: `xargs` (que por defecto junta todo con `echo`), `paste -s` (serializa con el delimitador `-d`), o la sustitución `$( )` dentro de un `echo`.
</details>


#### 🟡 Ejercicio 17.20 · `$( )` o `xargs`

Cuenta las líneas de cada fichero de `sistema/etc` que mencione `root`, de dos formas: con `xargs` y con `$( )`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -rl root sistema/etc | sort | xargs wc -l
# Otra forma equivalente:
wc -l $(grep -rl root sistema/etc | sort)
```

_Resultado:_

```text
   9 sistema/etc/crontab
  12 sistema/etc/fstab
  57 sistema/etc/group
  41 sistema/etc/passwd
 119 total
```


Aquí son equivalentes. `xargs` es más robusto con listas enormes (parte la orden en varias si no cabe) y `$( )` es más corto.
</details>


#### 🟡 Ejercicio 17.21 · El usuario soy yo

Muestra la línea de `/etc/passwd` **de tu propio usuario** sin escribir tu nombre a mano. *(Pista: `id -un` da tu nombre.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep "^$(id -un):" /etc/passwd
```

_Resultado:_

```text
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/bash
```


Las **comillas dobles** son imprescindibles: dentro de simples, `$(…)` no se sustituiría.
</details>


#### 🔴 Ejercicio 17.22 · ¿Quién es bash **y** sudo?

Lista los usuarios que **a la vez** usan `/bin/bash` y pertenecen al grupo `sudo` (tienen su nombre en la última columna de la línea de `sudo` en `/etc/group`).

<details>
<summary>💡 Ver solución</summary>


```bash
comm -12 <(grep -oP '^[^:]+(?=:.*:/bin/bash$)' /etc/passwd | sort) <(grep -oP '^sudo:.*:\K.*' /etc/group | tr ',' '\n' | sort)
```

_Resultado:_

```text
alumno
ana
```


`<( … )` da a `comm` dos "ficheros" ordenados. `comm -12` suprime las líneas exclusivas de cada uno y deja las comunes. Sin `<( )` habrías necesitado dos ficheros temporales.
</details>


#### 🔴 Ejercicio 17.23 · Shells en uso que no están en `/etc/shells`

Muestra los intérpretes que **se usan** en `/etc/passwd` pero **no** están en la lista oficial de `/etc/shells`.

<details>
<summary>💡 Ver solución</summary>


```bash
comm -13 <(grep -v '^#' /etc/shells | sort) <(cut -d: -f7 /etc/passwd | sort -u)
```

_Resultado:_

```text
/bin/false
/bin/sync
/usr/sbin/nologin
```


`comm -13` deja solo lo exclusivo del **segundo** conjunto. Son los "shells" de usuarios de sistema (`nologin`, `false`, `sync`): no son shells de verdad, por eso no están en la lista.
</details>


#### ⚫ Ejercicio 17.24 · Usuarios del sistema en `auth.log`

¿Cuántas veces aparece en `/var/log/auth.log` **cada nombre de usuario de `/etc/passwd`** como palabra entera? Muestra los 5 más frecuentes.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -owFf <(cut -d: -f1 /etc/passwd) /var/log/auth.log | sort | uniq -c | sort -rn | head -5
```

_Resultado:_

```text
     45 sshd
     25 root
     20 alumno
     10 luis
      6 bin
```


`-f` lee los patrones de un "fichero" que en realidad es la salida de `cut`; `-F` los toma como texto fijo, `-w` exige palabra entera (así `ana` no casa con `Manager`) y `-o` imprime solo lo coincidente. Después, el ranking de siempre.
</details>


#### 🟡 Ejercicio 17.25 · `&&` y `||`

Escribe en **una línea** un comando que imprima `existe` si el usuario `alumno` está en `/etc/passwd` y `no existe` si no. Pruébalo con `alumno` y con `fantasma`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -q '^alumno:' /etc/passwd && echo existe || echo "no existe"
grep -q '^fantasma:' /etc/passwd && echo existe || echo "no existe"
```

_Resultado:_

```text
existe
no existe
```


`grep -q` solo deja el código de salida: 0 (encontrado) activa el `&&`; 1 (no encontrado) salta al `||`.
</details>


#### 🔴 Ejercicio 17.26 · La trampa de `a && b || c`

Predice qué imprime `grep -q root /etc/passwd && grep -q zzz /etc/group || echo "no existe root"`. ¿Es correcto lo que dice?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -q root /etc/passwd && grep -q zzz /etc/group || echo "no existe root"
```

_Resultado:_

```text
no existe root
```


¡Imprime "no existe root" **aunque `root` sí exista**! Porque el `||` reacciona al fallo de **cualquier** cosa anterior: `root` existe (el primero sale bien), pero el segundo `grep` (que busca `zzz`) falla, y entonces se ejecuta la parte del `||`. Para hacer un verdadero "si… entonces… si no…" usa `if … then … else … fi`.
</details>


#### 🔴 Ejercicio 17.27 · Los códigos de una tubería

Haz una tubería `grep -c zzz /etc/passwd | wc -l` y muestra **los códigos de salida de cada uno de sus comandos**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c zzz /etc/passwd | wc -l ; echo "${PIPESTATUS[@]}"
```

_Resultado:_

```text
1
1 0
```


`PIPESTATUS` guarda el código de **cada** comando de la última tubería: `1 0` (`grep` no encontró nada; `wc` terminó bien). Pero **ojo**: hay que leerlo en la orden **inmediatamente siguiente**.
</details>


#### 🔴 Ejercicio 17.28 · `pipefail`

Haz que la misma tubería (`grep -c zzz /etc/passwd | wc -l`) tenga código de salida distinto de 0 si **cualquiera** de sus comandos falla.

<details>
<summary>💡 Ver solución</summary>


```bash
set -o pipefail
grep -c zzz /etc/passwd | wc -l ; echo "código: $?"
```

_Resultado:_

```text
1
código: 1
```


Con `pipefail`, el código de la tubería es el del **último comando que falló** (aquí el `grep`: 1).
</details>


#### ⚫ Ejercicio 17.29 · Quedarse solo con los errores

Cuenta **cuántos "Permission denied"** produce `grep -r root /etc`. No quieres ver los resultados normales: solo contar los errores. En **una** tubería, sin ficheros temporales.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -r root /etc 2>&1 > /dev/null | grep -c 'Permission denied'
```

_Resultado:_

```text
8
```


Truco de maestro: `2>&1` copia el destino del canal 1 **mientras todavía es la tubería** (el `|` se prepara antes que las redirecciones); y luego `> /dev/null` manda el canal 1 al agujero negro. El resultado: por la tubería solo viajan los **errores**, y el segundo `grep -c` los cuenta. Es el orden **inverso** al de antes: aquí `2>&1 > /dev/null` es exactamente lo que quieres.
</details>


#### 🔴 Ejercicio 17.30 · Con `sudo` no basta

`sudo echo hola > /opt/prueba.txt` falla con `Permission denied`. Consigue escribir `hola` en ese fichero, comprueba su contenido y bórralo. *(Es seguro: en este laboratorio `sudo` no pide contraseña.)*

<details>
<summary>💡 Ver solución</summary>


```bash
echo hola | sudo tee /opt/prueba.txt > /dev/null ; cat /opt/prueba.txt ; sudo rm /opt/prueba.txt
```

_Resultado:_

```text
hola
```


El `>` lo abre **tu** shell (sin permisos). Con `| sudo tee` es `tee`, ya con privilegios, quien abre el fichero.
</details>


#### 🟡 Ejercicio 17.31 · Un `for` con una sola redirección

Para los ficheros `/etc/passwd`, `/etc/group` y `/etc/hosts`, escribe en `resumen.txt` una línea `fichero: N líneas` por cada uno, con **un solo `>`** al final del bucle.

<details>
<summary>💡 Ver solución</summary>


```bash
for f in /etc/passwd /etc/group /etc/hosts; do echo "$f: $(wc -l < $f) líneas"; done > resumen.txt ; cat resumen.txt
```

_Resultado:_

```text
/etc/passwd: 41 líneas
/etc/group: 57 líneas
/etc/hosts: 16 líneas
```


La redirección después de `done` recoge **toda** la salida del bucle (si pusieras `>` dentro, pisarías el fichero en cada vuelta).
</details>


#### 🟡 Ejercicio 17.32 · `/dev/null` como fichero

Haz que `grep root /etc/passwd` muestre el **nombre del fichero** delante de la línea, **sin usar `-H`**. *(Truco clásico: dale un segundo fichero.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep root /etc/passwd /dev/null
```

_Resultado:_

```text
/etc/passwd:root:x:0:0:root:/root:/bin/bash
```


Con **dos o más ficheros**, `grep` antepone el nombre. `/dev/null` no tiene nada, así que no añade líneas. (Es el truco que se usaba antes de que existiera `-H`.)
</details>


#### 🔴 Ejercicio 17.33 · `-s` frente a `2>/dev/null`

Ejecuta `grep -s '[' /etc/passwd` y `grep '[' /etc/passwd 2>/dev/null`. ¿Cuál oculta el error de la regex inválida? ¿Qué código de salida devuelven?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -s '[' /etc/passwd ; echo "código: $?"
grep '[' /etc/passwd 2>/dev/null ; echo "código: $?"
```

_Resultado:_

```text
grep: Invalid regular expression
código: 2
código: 2
```


Solo el segundo oculta el error (`-s` solo calla los errores de **fichero**, no los de la regex). Los dos devuelven `2`: el código de un **error**, distinto del `1` de "sin coincidencias".
</details>


#### 🔴 Ejercicio 17.34 · Un informe con `tee` y regex

En **un solo comando encadenado**: extrae los nombres de usuario de los `Failed password` de `/var/log/auth.log`, cuenta cuántos intentos tiene cada uno, **guarda en `informe.txt` solo los que tienen 3 o más intentos** y muestra por pantalla **cuántos usuarios** son.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'Failed password for (invalid user )?\K\S+' /var/log/auth.log | sort | uniq -c | grep -E '^ +([3-9]|[1-9][0-9]+) ' | tee informe.txt | wc -l ; cat informe.txt
```

_Resultado:_

```text
1
      4 admin
```


Tubería de seis comandos: `grep -oP` extrae el usuario; `sort | uniq -c` los cuenta; un **segundo `grep -E`** filtra por el número con regex (`^ +([3-9]|[1-9][0-9]+) `: 3 a 9, o 10 o más); `tee` guarda esas líneas y las deja pasar a `wc -l`, que cuenta los usuarios. Mezcla de regex + tuberías + redirecciones.
</details>


#### ⚫ Ejercicio 17.35 · `while read` en una tubería

Cuenta las líneas de `cut -d: -f1 /etc/passwd` **con un bucle `while read`** (sumando 1 a una variable) de dos formas: leyendo de una **tubería** y leyendo con `< <( … )`. Verás una sorpresa.

<details>
<summary>💡 Ver solución</summary>


```bash
n=0 ; cut -d: -f1 /etc/passwd | while read -r u; do n=$((n+1)); done ; echo "con tubería: n=$n"
n=0 ; while read -r u; do n=$((n+1)); done < <(cut -d: -f1 /etc/passwd) ; echo "con < <( ): n=$n"
```

_Resultado:_

```text
con tubería: n=0
con < <( ): n=41
```


Con la tubería, el `while` corre en un **subshell** (cada lado de un `|` es un proceso aparte), y la `n` que incrementa es una **copia**: al salir del bucle, la `n` original sigue en 0. Con `< <( … )` el bucle corre en el shell actual y la variable sí se conserva. Una trampa que pilla a casi todo el mundo.
</details>


#### ⚫ Ejercicio 17.36 · Un `stdin` compartido

`{ head -1; grep -c .; } < /etc/passwd` agrupa dos comandos con **el mismo** `stdin`. ¿Qué imprime y por qué sale ese número?

<details>
<summary>💡 Ver solución</summary>


```bash
{ head -1; grep -c . ; } < /etc/passwd
echo "--- ahora con una tubería en vez de <:"
cat /etc/passwd | { head -1; grep -c . ; }
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/bash
40
--- ahora con una tubería en vez de <:
root:x:0:0:root:/root:/bin/bash
0
```


Con `<`, la primera línea la imprime `head -1` y `grep -c .` cuenta **las restantes**: 40 (en total hay 41). Porque `head`, al ser el `stdin` un **fichero normal**, deja el "marcador de lectura" justo después de su primera línea, y `grep` continúa desde ahí. Con una **tubería** no se puede "rebobinar": `head` lee un bloque entero de golpe, se queda solo con la primera línea, y a `grep` no le llega nada (cuenta 0).
</details>


#### ⚫ Ejercicio 17.37 · Una tubería con nombre

Con `mkfifo`, crea una tubería `tuberia`, escribe en ella `hola por la tubería` **en segundo plano** y léela con `cat`. Después bórrala.

<details>
<summary>💡 Ver solución</summary>


```bash
mkfifo tuberia ; (echo "hola por la tubería" > tuberia &) ; cat tuberia ; rm tuberia
```

_Resultado:_

```text
hola por la tubería
```


Una FIFO es una tubería que vive como fichero. El `echo` se queda **bloqueado** esperando a que alguien lea; por eso va en segundo plano (`&`). `cat` la lee y entonces ambos terminan.
</details>


---

## 17.14 · 📝 Mini-test de 103.4

**1.** ¿Qué comando guarda **salida y errores** de `ls /etc /nada` en `todo.txt`?

a) `ls /etc /nada > todo.txt`  b) `ls /etc /nada 2>&1 > todo.txt`  c) `ls /etc /nada > todo.txt 2>&1`  d) `ls /etc /nada 2> todo.txt`

<details><summary>Respuesta</summary>

**c)**. `> todo.txt` primero y después `2>&1` (que copia el destino del 1). En b) el error sale por pantalla; a) no recoge los errores; d) no recoge la salida.
</details>

**2.** ¿Qué hace `comando >> registro.log 2>> errores.log`?

a) Pisa los dos ficheros  b) Añade la salida a `registro.log` y los errores a `errores.log`  c) Manda todo a `registro.log`  d) Da error de sintaxis

<details><summary>Respuesta</summary>

**b)**. `>>` añade `stdout`, `2>>` añade `stderr`.
</details>

**3.** En `a | b`, ¿qué recibe `b` por su entrada?

a) La salida normal y los errores de `a`  b) Solo la salida normal (`stdout`) de `a`  c) Solo los errores de `a`  d) Los argumentos de `a`

<details><summary>Respuesta</summary>

**b)**. Los errores no entran en la tubería, salvo que uses `2>&1 |` o `|&`.
</details>

**4.** ¿Cuál es el efecto de `sort datos.txt > datos.txt`?

a) Ordena el fichero  b) Lo deja vacío  c) Da un error  d) Lo ordena y duplica

<details><summary>Respuesta</summary>

**b)**. El shell vacía `datos.txt` al preparar la redirección, **antes** de que `sort` lo lea. Usa `sort -o datos.txt datos.txt`.
</details>

**5.** ¿Qué hace `find . -name '*.tmp' | xargs rm` y qué problema puede tener?

a) Borra los `.tmp`; falla con nombres con espacios  b) Borra todo  c) Lista los `.tmp`  d) No hace nada

<details><summary>Respuesta</summary>

**a)**. Borra los `.tmp`, pero los nombres con espacios se parten en dos argumentos. La versión segura: `find . -name '*.tmp' -print0 | xargs -0 rm` (o `find … -delete`).
</details>

**6.** ¿Para qué sirve `tee -a log.txt` en una tubería?

a) Para leer de `log.txt`  b) Para copiar el flujo **añadiéndolo** a `log.txt` y dejarlo seguir  c) Para sobrescribir `log.txt`  d) Para ordenar

<details><summary>Respuesta</summary>

**b)**. `tee` copia a fichero y a `stdout`; `-a` añade en vez de sobrescribir.
</details>

**7.** ¿Qué imprime `grep -c zzz /etc/passwd | wc -l; echo $?`?

a) `0` y luego `1`  b) `1` y luego `0`  c) `0` y luego `0`  d) `1` y luego `1`

<details><summary>Respuesta</summary>

**b)**. `grep -c` imprime `0` (recuento), `wc -l` cuenta **1 línea**, y `$?` es el código del **último** comando (`wc`): `0`. Salida: `1` y `0`.
</details>

**8.** ¿Qué hace `grep -E '^[0-9]+$' <<< "2024"`?

a) Lee el fichero llamado `2024`  b) Usa la cadena `2024` como `stdin`; casa e imprime `2024`  c) Da error  d) Redirige la salida a `2024`

<details><summary>Respuesta</summary>

**b)**. `<<<` es una *here-string*: la cadena se entrega como `stdin`.
</details>

---

## ✅ Resumen del capítulo 17

| Quiero… | Escribo |
|---|---|
| guardar la salida (pisando) / añadiendo | `> f` / `>> f` |
| guardar los errores | `2> f` / `2>> f` |
| tirar la salida / los errores | `> /dev/null` / `2> /dev/null` |
| todo al mismo sitio | `> f 2>&1` o `&> f` |
| leer de un fichero | `< f` |
| texto en la propia orden | `<<< 'cadena'` / `<<'FIN' … FIN` |
| encadenar | `a \| b` (solo `stdout`) · `a \|& b` (también `stderr`) |
| guardar y seguir | `\| tee f` / `\| tee -a f` |
| de lista a argumentos | `\| xargs` (`-n`, `-I{}`, `-0`) o `$( )` |
| una salida como si fuera un fichero | `<( comando )` |
| solo si salió bien / mal | `a && b` / `a \|\| b` |
| códigos de cada comando de una tubería | `${PIPESTATUS[@]}` · `set -o pipefail` |

**Reglas de oro:** `2>&1` se lee **de izquierda a derecha** · `>` vacía el fichero **antes** de ejecutar · la tubería solo lleva `stdout` · cada lado de una `|` es un proceso aparte (las variables no «vuelven») · `sudo` no cubre las redirecciones: usa `| sudo tee`.

➡️ **Siguiente parada:** vuelve al [capítulo 10](10-ficheros-del-sistema.md) (o al [16](16-retos-finales.md) si ya lo has hecho todo) y **busca las tuberías**: ahora las entenderás una a una.

---
⬅️ [Capítulo 16 · 🏆 El jefe final: misiones, retos y mini-examen](16-retos-finales.md) · 🏠 [Índice](README.md)
