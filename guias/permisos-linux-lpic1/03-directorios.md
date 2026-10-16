# Capítulo 3 · `r`, `w` y `x` en los directorios: el capítulo que casi todos entienden mal

> 🎯 **Objetivo:** entender qué significan **listar**, **entrar** y **crear/borrar** en una carpeta, por qué **para borrar un fichero manda la carpeta (no el fichero)**, y por qué hace falta `x` en **todas** las carpetas del camino.
>
> 📘 **LPIC-1:** 104.5 (permisos de directorios) · 103.3.
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`.

---

## 3.1 · Una carpeta es una **lista de nombres**

Primero, un cambio de mentalidad. Una carpeta **no "contiene" ficheros** como una caja contiene objetos. Una carpeta es, en realidad, **un fichero especial que contiene una lista**: *"el nombre `agenda.txt` corresponde al fichero número 598620; el nombre `notas.txt`, al 598622…"*. Los ficheros viven **en otro sitio**; la carpeta solo **apunta** a ellos.

Imagina el **portal de un edificio** con un listado de vecinos y su número de puerta:

```text
        ┌─────────── PORTAL (la carpeta) ───────────┐
        │  Listado:   "López"   → puerta 3º A       │
        │             "Ruiz"    → puerta 1º B       │
        └───────────────────────────────────────────┘
```

Con esa imagen, los tres permisos de una **carpeta** cobran sentido:

| Letra | En una carpeta permite… | En el portal sería… |
|:-:|---|---|
| **`r`** | **leer la lista de nombres** (`ls`) | **leer el listado** de vecinos en la pared |
| **`x`** | **entrar / "pasar por"** la carpeta (`cd`) y **acceder a algo por su nombre** | **cruzar el portal** y llamar a una puerta concreta |
| **`w`** | **modificar la lista**: crear, borrar o renombrar entradas | **cambiar el listado**: añadir o quitar vecinos |

Y dos reglas que lo cambian todo:

> 🔑 **Regla 1:** `w` **sin `x` no sirve de nada**. Para cambiar la lista tienes primero que poder *pasar* por la carpeta.
>
> 🔑 **Regla 2:** **borrar o renombrar un fichero es modificar la lista de la carpeta**, así que lo que importa es **`w` + `x` de la carpeta**, no los permisos del fichero.

---

## 3.2 · Las 8 combinaciones, **medidas de verdad**

Hay 8 combinaciones de `rwx` posibles (`---`, `--x`, `-w-`, `-wx`, `r--`, `r-x`, `rw-`, `rwx`). En lugar de contártelas, las **medimos**. Este pequeño programa crea una carpeta `d` con un fichero `f` dentro, le pone cada una de las 8 combinaciones **al dueño** (tú) y prueba 6 operaciones. Un `✔` es que funcionó; un `✘`, que dio `Permission denied`:

```bash
ok() { "$@" >/dev/null 2>&1 && printf '  ✔      ' || printf '  ✘      '; }
printf 'dueño   ls d    ls -l d  cat d/f  cd d    touch   rm d/f\n'
for m in 0 1 2 3 4 5 6 7; do
  chmod 700 d 2>/dev/null; rm -rf d; mkdir d; echo hola > d/f; chmod ${m}00 d
  printf ' %s ' "$(stat -c %A d | cut -c2-4)"
  ok ls d; ok ls -l d; ok cat d/f; ok sh -c 'cd d'; ok touch d/nuevo; ok rm d/f
  echo
done
chmod 700 d; rm -rf d
```

_Resultado:_

```text
dueño   ls d    ls -l d  cat d/f  cd d    touch   rm d/f
 ---   ✘        ✘        ✘        ✘        ✘        ✘      
 --x   ✘        ✘        ✔        ✔        ✘        ✘      
 -w-   ✘        ✘        ✘        ✘        ✘        ✘      
 -wx   ✘        ✘        ✔        ✔        ✔        ✔      
 r--   ✔        ✘        ✘        ✘        ✘        ✘      
 r-x   ✔        ✔        ✔        ✔        ✘        ✘      
 rw-   ✔        ✘        ✘        ✘        ✘        ✘      
 rwx   ✔        ✔        ✔        ✔        ✔        ✔      
```

Tienes el mapa completo de las carpetas en una tabla. Léela **por filas**:

| Permisos | Qué se puede hacer | Cómo se llama en la práctica |
|:-:|---|---|
| `---` | nada | carpeta **cerrada** |
| `--x` | **entrar y acceder a lo que ya sabes cómo se llama** (`cat d/f`, `cd d`), pero **no ver qué hay** | **pasillo a oscuras** |
| `-w-` | **nada** (la `w` sin `x` no funciona) | inútil |
| `-wx` | entrar, **crear y borrar**, pero no ver la lista | **buzón** (se deposita sin ver qué hay dentro) |
| `r--` | ver los **nombres** (`ls`), pero ni `ls -l`, ni `cat`, ni `cd` | **listado sin acceso** |
| `r-x` | ver, entrar, leer ficheros; **no crear ni borrar** | carpeta **de solo lectura** (la más común: `755`) |
| `rw-` | ver nombres… y nada más (la `w` sin `x` no funciona) | casi inútil |
| `rwx` | **todo** | carpeta **normal** del dueño (`755`, `700`…) |

> ⭐ **La combinación útil por excelencia: `r-x`** (leer, entrar). Y la de trabajo: **`rwx`**.

---

## 3.3 · Casos raros, uno a uno

### 🔍 `r` sin `x`: ves los nombres pero nada más

```text
$ mkdir ra
$ touch ra/a ra/b
$ chmod 400 ra
$ ls ra
a  b
$ ls -l ra
ls: cannot access 'ra/b': Permission denied
ls: cannot access 'ra/a': Permission denied
total 0
-????????? ? ? ? ?            ? a
-????????? ? ? ? ?            ? b
$ cat ra/a
cat: ra/a: Permission denied
$ chmod 700 ra
```

Con `r--`, **`ls` te enseña los nombres** (ese es el listado) pero, para mostrar tamaño, dueño y fecha (`ls -l`), tendría que **consultar cada fichero**, y eso requiere pasar por la carpeta (`x`). Por eso sale `?????????` y errores.

### 🔦 `x` sin `r`: pasillo a oscuras

```text
$ mkdir oscuro
$ echo "contenido secreto" > oscuro/secreto.txt
$ chmod 100 oscuro
$ ls oscuro
ls: cannot open directory 'oscuro': Permission denied
$ cat oscuro/secreto.txt
contenido secreto
$ cat oscuro/otro.txt
cat: oscuro/otro.txt: No such file or directory
$ chmod 700 oscuro
```

Con `--x`: **no puedes listar**, pero **si sabes el nombre exacto** (`secreto.txt`) puedes leerlo. Y fíjate en un detalle: si pruebas con un nombre que **no existe** (`otro.txt`), el error cambia a `No such file or directory`. O sea: **puedes comprobar si un nombre existe**. Esa es la razón de que "esconder" cosas con `--x` solo funcione si el nombre es difícil de adivinar.

### 📮 `-wx`: el buzón (¡tu captura!)

Esto es justo lo que tiene `/var/spool/cron/crontabs`: `drwx-wx--T root crontab`. El grupo `crontab` puede **entrar y escribir, pero no listar**. Lo simulamos con el grupo `equipo` (`ana` y `beto` son de `equipo`; `carla` no):

```text
$ mkdir buzon
$ sudo chgrp equipo buzon
$ chmod 730 buzon
$ ls -ld buzon
drwx-wx--- 2 alumno equipo 4096 Oct 16 17:08 buzon
$ sudo -u ana touch buzon/carta-de-ana.txt
$ sudo -u beto touch buzon/carta-de-beto.txt
$ sudo -u ana ls buzon
ls: cannot open directory 'buzon': Permission denied
$ sudo -u carla touch buzon/intruso.txt
touch: cannot touch 'buzon/intruso.txt': Permission denied
$ ls buzon
carta-de-ana.txt  carta-de-beto.txt
```

- 👩 `ana` **puede depositar** un fichero (`-wx` del grupo), pero **no ver qué hay** (`ls` falla).
- 👩‍🔧 `carla` es "otros" (`---`): ni entra.
- 🧑‍🎓 Tú (dueño, `rwx`) **ves todo**.

Y ahora la pregunta que debería preocuparte: **`beto` tiene `w` en la carpeta, ¿puede borrar la carta de `ana`?** ¡Sí!, porque borrar manda la carpeta. (Usamos `rm -f` para que no pregunte "¿borrar fichero protegido contra escritura?"; sin `-f` te lo preguntaría, pero tras decir `y` lo borraría igual.)

```text
$ sudo -u beto rm -f buzon/carta-de-ana.txt
$ ls buzon
carta-de-beto.txt
```

Por eso `crontabs` lleva **además** el bit **sticky** (`T` al final): *"solo el dueño de un fichero (o de la carpeta) puede borrarlo"*. Se estudia en el [capítulo 10](10-permisos-especiales.md).

---

## 3.4 · 🔑 Regla 2 en acción: borrar manda la carpeta

Dos casos que confirman la regla:

**① Fichero "blindado" (`000`), carpeta mía → lo puedo borrar:**

```text
$ mkdir mia
$ echo "blindado" > mia/f
$ chmod 000 mia/f
$ ls -l mia/f
---------- 1 alumno alumno 9 Oct 16 17:08 mia/f
$ rm -f mia/f
$ ls mia
```

**② Fichero "abierto de par en par" (`777`), carpeta sin `w` → no lo puedo borrar ni renombrar ni crear nada:**

```text
$ mkdir ajena
$ echo "hola" > ajena/f
$ chmod 777 ajena/f
$ chmod 555 ajena
$ ls -l ajena/f
-rwxrwxrwx 1 alumno alumno 5 Oct 16 17:08 ajena/f
$ rm ajena/f
rm: cannot remove 'ajena/f': Permission denied
$ mv ajena/f ajena/g
mv: cannot move 'ajena/f' to 'ajena/g': Permission denied
$ touch ajena/nuevo
touch: cannot touch 'ajena/nuevo': Permission denied
$ echo "pero el CONTENIDO sí lo puedo cambiar" >> ajena/f
$ cat ajena/f
hola
pero el CONTENIDO sí lo puedo cambiar
$ chmod 755 ajena
```

El contenido de `f` **sí** se puede modificar (el fichero tiene `w`); pero **su nombre y su existencia** dependen de la carpeta (`r-x`, sin `w`).

| Quiero… | Lo decide… |
|---|---|
| Cambiar el **contenido** de `f` | los permisos de **`f`** (`w`) + `x` en la carpeta |
| **Crear** un fichero nuevo | `w` + `x` de la **carpeta** |
| **Borrar** `f` | `w` + `x` de la **carpeta** (+ *sticky*, capítulo 10) |
| **Renombrar** `f` | `w` + `x` de la **carpeta** |
| **Mover** `f` a otra carpeta | `w` + `x` en las **dos** carpetas |

---

## 3.5 · La ruta entera: `x` en **todas** las carpetas del camino

Para llegar a `/home/alumno/lab-permisos/datos/secreto.txt`, el sistema atraviesa `/`, `/home`, `/home/alumno`, `/home/alumno/lab-permisos`, `/home/alumno/lab-permisos/datos`. Necesitas **`x` en TODAS** esas carpetas, y después el permiso que corresponda en el fichero.

La herramienta para verlo es **`namei -l`**: recorre la ruta y te enseña los permisos de **cada tramo**:

```text
$ namei -l /home/alumno/lab-permisos/datos/agenda.txt
f: /home/alumno/lab-permisos/datos/agenda.txt
drwxr-xr-x root   root   /
drwxr-xr-x root   root   home
drwxr-x--x alumno alumno alumno
drwxr-xr-x alumno alumno lab-permisos
drwxr-xr-x alumno alumno datos
-rw-r--r-- alumno alumno agenda.txt
```

Fíjate: tu carpeta personal `alumno` aparece como **`drwxr-x--x`**. Ese `x` final (para *otros*) es el que el script del laboratorio le añadió con `chmod o+x ~`. Sin él, `ana`, `beto` y `carla` **no podrían atravesar tu carpeta personal**, y todos los experimentos con ellos fallarían **por esa razón y no por la del fichero**. ¡Comprobémoslo!

```text
$ sudo -u ana cat /home/alumno/lab-permisos/datos/agenda.txt
Reunión el lunes a las 10:00
Llevar el informe impreso
$ chmod o-x ~
$ ls -ld ~
drwxr-x--- 3 alumno alumno 4096 Oct 16 17:08 /home/alumno
$ sudo -u ana cat /home/alumno/lab-permisos/datos/agenda.txt
cat: /home/alumno/lab-permisos/datos/agenda.txt: Permission denied
$ chmod o+x ~
$ sudo -u ana cat /home/alumno/lab-permisos/datos/agenda.txt
Reunión el lunes a las 10:00
Llevar el informe impreso
```

El **mismo fichero** (legible para todos: `rw-r--r--`) pasa a ser **inaccesible** cuando se cierra una carpeta **por encima**. Así es como Ubuntu protege las carpetas personales: `drwxr-x---` (`750`): ni los demás **entran**, ni **ven** qué hay.

### 🧪 Otro ejemplo, con un tramo cerrado en medio

```text
$ mkdir -p a/b/c
$ echo hola > a/b/c/f
$ chmod 000 a/b
$ cat a/b/c/f
cat: a/b/c/f: Permission denied
$ namei -l a/b/c/f
f: a/b/c/f
drwxrwxr-x alumno alumno a
d--------- alumno alumno b
                          c - Permission denied
$ chmod 755 a/b
$ cat a/b/c/f
hola
```

`namei` te señala el culpable: la carpeta `b` con `d---------`. (Y como el error siempre dice solo `Permission denied`, **`namei -l` es tu mejor amigo para diagnosticar**. Lo recomiendo hasta el cansancio en el capítulo 13.)

---

## 3.6 · Una trampa curiosa: dentro de la carpeta, lo relativo sigue funcionando

Cuando estás **dentro** de una carpeta (`cd a/b/c`), tu terminal ya "está dentro" y las rutas **relativas** no vuelven a comprobar las carpetas de arriba. Mira:

```text
$ mkdir -p zz/yy
$ echo "estoy dentro" > zz/yy/f
$ cd zz/yy
$ chmod 000 ..
$ cat f
estoy dentro
$ ls ..
ls: cannot open directory '..': Permission denied
$ cd ..
bash: cd: ..: Permission denied
$ cd ~/lab-permisos
$ chmod 755 zz
```

Mientras sigues dentro de `yy`, `cat f` funciona (ruta relativa) aunque `zz` esté cerrada con `000`. Pero `ls ..` y `cd ..` fallan. Es una **rareza** del sistema, importante para entender por qué a veces un proceso "ya dentro" sigue funcionando después de cambiar permisos de carpetas superiores.

---

## 3.7 · Cuadro de operaciones y permisos de carpeta

| Quiero… | Comando | Permisos que necesito en la carpeta |
|---|---|---|
| Ver los **nombres** | `ls d` | `r` |
| Ver detalles (tamaños, dueños…) | `ls -l d` | `r` **y** `x` |
| **Entrar** | `cd d` | `x` |
| Leer / ejecutar un fichero de dentro | `cat d/f`, `./d/f` | `x` (+ permiso del fichero) |
| **Crear** un fichero | `touch d/n`, `mkdir d/n` | `w` **y** `x` |
| **Borrar** un fichero | `rm d/f` | `w` **y** `x` |
| **Renombrar** dentro | `mv d/a d/b` | `w` **y** `x` |
| **Copiar** *a* la carpeta | `cp f d/` | `w` **y** `x` |
| **Mover** *de una a otra* | `mv d1/f d2/` | `w`+`x` en **las dos** |
| Borrar la carpeta (vacía) | `rmdir d` | `w`+`x` en su **carpeta padre** |
| Borrar con contenido | `rm -r d` | `rwx` en `d` y en cada subcarpeta, + `w`+`x` en el padre |
| **Buscar** dentro | `find d` | `r` y `x` en cada nivel |
| Autocompletar con `Tab` | | `r` (para listar candidatos) |

> 🧠 **Resumen en una línea:** `r` = *ver la lista*; `x` = *pasar y tocar por nombre*; `w` = *modificar la lista* (siempre con `x`).

---

## 3.8 · Permisos de carpeta típicos

| Octal | Letras | Uso típico |
|:-:|---|---|
| `755` | `drwxr-xr-x` | carpeta **pública** (otros ven y entran, pero no tocan) |
| `700` | `drwx------` | carpeta **privada** (tu `~/.ssh`) |
| `750` | `drwxr-x---` | solo el dueño y su grupo (**HOME en Ubuntu 24.04**) |
| `775` | `drwxrwxr-x` | de trabajo en equipo (dueño y grupo escriben) |
| `711` | `drwx--x--x` | "pasillo": otros **atraviesan** sin ver (típico de `~` si compartes `public_html`) |
| `1777` | `drwxrwxrwt` | pública y compartida **con *sticky*** (`/tmp`) |
| `2775` | `drwxrwsr-x` | de equipo con **SGID** (los ficheros heredan el grupo) |
| `1730` | `drwx-wx--T` | **buzón** protegido (`crontabs`) |

---

## 3.9 · 🏋️ Ejercicios

#### 🟢 Ejercicio 3.1 · Cerrar una carpeta a los demás

Crea `privada` y haz que **solo tú** puedas entrar y listar. Demuestra con `ana` que no puede ni listarla.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir privada
$ chmod 700 privada
$ ls -ld privada
drwx------ 2 alumno alumno 4096 Oct 16 17:08 privada
$ sudo -u ana ls privada
ls: cannot open directory 'privada': Permission denied
```

`700` = `rwx------`.
</details>

#### 🟢 Ejercicio 3.2 · Carpeta pública de solo lectura

Crea `publica` con un fichero dentro. Que cualquiera pueda **ver y entrar** pero **no crear**. Pruébalo con `carla`.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir publica
$ echo "hola a todos" > publica/leeme.txt
$ chmod 755 publica
$ sudo -u carla ls publica
leeme.txt
$ sudo -u carla cat publica/leeme.txt
hola a todos
$ sudo -u carla touch publica/mio.txt
touch: cannot touch 'publica/mio.txt': Permission denied
```

`r-x` para otros: leer y entrar, **no** crear.
</details>

#### 🟢 Ejercicio 3.3 · ¿`ls` o `cd`?

¿Con qué permiso **de carpeta** funciona `cd` pero no `ls`?

<details>
<summary>💡 Ver solución</summary>

Con **`--x`** (solo ejecución). Lo probamos arriba en la carpeta `oscuro`: `cd` y `cat` por nombre funcionan, `ls` no.
</details>

#### 🟡 Ejercicio 3.4 · Crear sin poder borrar

Prepara una carpeta `entrada` donde **tú** puedas todo y **el grupo `equipo`** pueda **entrar y listar** pero **no crear**.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir entrada
$ sudo chgrp equipo entrada
$ chmod 750 entrada
$ ls -ld entrada
drwxr-x--- 2 alumno equipo 4096 Oct 16 17:08 entrada
$ sudo -u ana ls entrada
$ sudo -u ana touch entrada/x
touch: cannot touch 'entrada/x': Permission denied
$ sudo -u carla ls entrada
ls: cannot open directory 'entrada': Permission denied
```

`750` = `rwxr-x---`: dueño todo; grupo `r-x` (listar y entrar); otros nada.
</details>

#### 🟡 Ejercicio 3.5 · El buzón compartido

Crea `buzon2` para que `ana` y `beto` (grupo `equipo`) puedan **dejar ficheros** pero no listar la carpeta, y `carla` no pueda ni entrar.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir buzon2
$ sudo chgrp equipo buzon2
$ chmod 730 buzon2
$ ls -ld buzon2
drwx-wx--- 2 alumno equipo 4096 Oct 16 17:08 buzon2
$ sudo -u ana sh -c 'echo "de ana" > buzon2/ana.txt'
$ sudo -u ana ls buzon2
ls: cannot open directory 'buzon2': Permission denied
$ sudo -u carla sh -c 'echo x > buzon2/carla.txt'
sh: 1: cannot create buzon2/carla.txt: Permission denied
```

`730` = `rwx-wx---`.
</details>

#### 🟡 Ejercicio 3.6 · ¿Quién puede borrar?

En una carpeta `rwxrwxrwx` hay un fichero tuyo `rw-------`. ¿Puede `carla` borrarlo?

<details>
<summary>💡 Ver solución</summary>

**Sí**, porque borrar manda la carpeta (`w` para todos). Comprobémoslo:

```text
$ mkdir abierta
$ chmod 777 abierta
$ echo mio > abierta/mio.txt
$ chmod 600 abierta/mio.txt
$ sudo -u carla rm -f abierta/mio.txt
$ ls abierta
```

Por eso existe el bit *sticky* (capítulo 10): en `/tmp` (`1777`) esto **no** pasa.
</details>

#### 🔴 Ejercicio 3.7 · El tramo cerrado

Con la estructura `p/q/r/dato.txt`, quita **un solo permiso** para que `ana` no pueda leer `dato.txt` aunque el fichero sea legible para todos, y demuéstralo con `namei -l`.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir -p p/q/r
$ echo "dato" > p/q/r/dato.txt
$ chmod 644 p/q/r/dato.txt
$ sudo -u ana cat p/q/r/dato.txt
dato
$ chmod o-x p/q
$ sudo -u ana cat /home/alumno/lab-permisos/p/q/r/dato.txt
cat: /home/alumno/lab-permisos/p/q/r/dato.txt: Permission denied
$ namei -l /home/alumno/lab-permisos/p/q/r/dato.txt
f: /home/alumno/lab-permisos/p/q/r/dato.txt
drwxr-xr-x root   root   /
drwxr-xr-x root   root   home
drwxr-x--x alumno alumno alumno
drwxr-xr-x alumno alumno lab-permisos
drwxrwxr-x alumno alumno p
drwxrwxr-- alumno alumno q
drwxrwxr-x alumno alumno r
-rw-r--r-- alumno alumno dato.txt
```

(Usamos la ruta **absoluta** porque con una relativa se "salta" el control en algunos tramos, como vimos en 3.6.) `namei` muestra `drwxrwxr--` en `q`: a "otros" les falta la `x`.
</details>

#### 🔴 Ejercicio 3.8 · Borrar con contenido

`rm -rf` de una carpeta que contiene una subcarpeta **sin** permisos. ¿Qué pasa y cómo se arregla?

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir -p gran/pequena
$ touch gran/pequena/f
$ chmod 000 gran/pequena
$ rm -rf gran
rm: cannot remove 'gran/pequena': Permission denied
$ chmod 700 gran/pequena
$ rm -rf gran
$ ls
a	 ajena	buzon2	  datos    mia	   p	    publica  salario.sh  zz
abierta  buzon	cerve.sh  entrada  oscuro  privada  ra	     saludos.sh
```

`rm -r` no puede **entrar** en `pequena` (falta `x`) ni **listarla** (falta `r`), así que no puede vaciarla. Hay que devolverle permisos primero (`chmod -R u+rwX gran` es la forma rápida).
</details>

#### 🔴 Ejercicio 3.9 · Mover una carpeta exige `w` sobre ella

Intenta mover una **carpeta** `origen/sub` a `destino/`, con `sub` en `r-x`. Compara con mover un **fichero** con permiso `r--`.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir -p origen/sub destino
$ touch origen/fichero
$ chmod 444 origen/fichero
$ chmod 555 origen/sub
$ mv origen/fichero destino/
$ mv origen/sub destino/
mv: cannot move 'origen/sub' to 'destino/sub': Permission denied
$ chmod 755 origen/sub
$ mv origen/sub destino/
$ ls destino
fichero  sub
```

El **fichero** se mueve aunque sea `r--` (solo se toca la lista de las dos carpetas). Pero mover una **carpeta a otro padre** exige `w` **sobre ella misma**: hay que actualizar su entrada `..` (que apunta a su nuevo padre).
</details>

#### ⚫ Ejercicio 3.10 · Lo de dentro sigue funcionando

Explica por qué, estando dentro de `zz/yy`, `cat f` sigue funcionando después de `chmod 000 ..`.

<details>
<summary>💡 Ver solución</summary>

Porque una ruta **relativa** (`f`) parte de tu directorio actual, que ya está "abierto" por tu terminal. Linux **no vuelve a comprobar `x` en las carpetas superiores** para esa búsqueda: solo en `yy` (que sí tienes) y en el fichero. Para subir (`..`) sí tendría que atravesar `zz` otra vez, y ahí falla.
</details>

#### ⚫ Ejercicio 3.11 · Preguntas de examen

**A.** *¿Qué permisos mínimos hacen falta sobre un directorio para poder ejecutar `ls -l` dentro de él?* a) `r` b) `x` c) `r` y `x` d) `w` y `x`

**B.** *¿Qué permisos mínimos hacen falta sobre un directorio para poder **borrar un fichero** que contiene (suponiendo que el fichero tiene permisos `000`)?* a) `r` b) `w` y `x` del directorio c) `w` del fichero d) `rwx` del fichero

**C.** *Un usuario tiene `r--` sobre un directorio. ¿Qué puede hacer?* a) Entrar b) Ver los **nombres** de lo que contiene c) Crear ficheros d) Nada

<details>
<summary>💡 Ver solución</summary>

**A → c).** `r` para listar y `x` para consultar los metadatos de cada entrada.
**B → b).** Borrar depende de `w` + `x` del **directorio**; los permisos del fichero no cuentan (salvo *sticky*).
**C → b).** Con `r--` solo se ven los nombres (sin `x` no se puede ni `ls -l` ni acceder).
</details>

---

⬅️ [Capítulo 2 · `r`, `w` y `x` en los ficheros: leer, modificar, ejecutar](02-r-w-x-en-ficheros.md) · [📚 Índice](README.md) · [Capítulo 4 · ¿Quién decide qué? El algoritmo de los permisos](04-quien-decide.md) ➡️
