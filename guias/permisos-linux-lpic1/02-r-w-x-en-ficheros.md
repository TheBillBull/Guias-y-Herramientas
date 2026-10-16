# Capítulo 2 · `r`, `w` y `x` en los ficheros: leer, modificar, ejecutar

> 🎯 **Objetivo:** saber, para un **fichero**, qué permite exactamente cada letra: **leer** el contenido, **escribirlo** (y qué *no* permite escribir: ¡no es borrar!) y **ejecutarlo** (con la sorpresa de los scripts).
>
> 📘 **LPIC-1:** 104.5 (permisos de ficheros normales) · 103.1.
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`. Cada práctica crea sus propios ficheros.

---

## 2.1 · La regla de oro

Para un **fichero normal**:

| Letra | Nombre | Permite… | Sin ella… |
|:-:|---|---|---|
| `r` | **read** | **ver el contenido**: `cat`, `less`, `grep`, `cp` (copiarlo), abrirlo en un editor | `Permission denied` al leerlo |
| `w` | **write** | **cambiar el contenido**: `echo > f`, `>>`, `nano`, `truncate`… | `Permission denied` al escribir |
| `x` | **execute** | **lanzarlo como programa**: `./f` | `Permission denied` al ejecutarlo |

Tres comprobaciones rápidas con un fichero de prueba. Creamos uno con permisos `rw-` para el dueño (`600`):

```text
$ echo "Hola mundo" > prueba.txt
$ chmod 600 prueba.txt
$ ls -l prueba.txt
-rw------- 1 alumno alumno 11 Oct 16 17:08 prueba.txt
$ cat prueba.txt
Hola mundo
```

Ahora vamos **quitándole** permisos uno a uno y viendo qué se rompe.

---

## 2.2 · Quitar la lectura (`r`)

```text
$ chmod u-r prueba.txt
$ ls -l prueba.txt
--w------- 1 alumno alumno 11 Oct 16 17:08 prueba.txt
$ cat prueba.txt
cat: prueba.txt: Permission denied
```

`-w-------`: con solo `w`, **no puedes leer**, pero **sí puedes escribir** (¡qué rareza!). Como en un buzón: se echa, no se mira.

```text
$ echo "Otra línea" >> prueba.txt
$ cat prueba.txt
cat: prueba.txt: Permission denied
```

Pudimos **añadir** (`>>`), pero no leer ni siquiera lo que acabamos de escribir. Para comprobar que se escribió, hay que devolverle la `r`:

```text
$ chmod u+r prueba.txt
$ cat prueba.txt
Hola mundo
Otra línea
```

> 🧪 **Un caso real** de "solo escritura": ficheros donde muchos usuarios *depositan* información sin poder verse entre sí.

---

## 2.3 · Quitar la escritura (`w`)

```text
$ chmod u-w prueba.txt
$ ls -l prueba.txt
-r-------- 1 alumno alumno 23 Oct 16 17:08 prueba.txt
$ echo "no me dejará" >> prueba.txt
bash: prueba.txt: Permission denied
$ echo "tampoco" > prueba.txt
bash: prueba.txt: Permission denied
$ cat prueba.txt
Hola mundo
Otra línea
```

Con `r--` **se puede leer, no escribir**: ni para **añadir** (`>>`) ni para **sobrescribir** (`>`). Y recuerda: el fichero queda **intacto** (la segunda orden no llegó a vaciarlo).

### ¿`w` permite borrar el fichero?

**No.** Esta es **la gran confusión**. Mira:

```text
$ ls -l prueba.txt
-r-------- 1 alumno alumno 23 Oct 16 17:08 prueba.txt
$ rm prueba.txt < /dev/null
$ ls prueba.txt
ls: cannot access 'prueba.txt': No such file or directory
```

Borramos un fichero **sin** permiso de escritura y *se borró*. ¿Por qué? Porque **borrar un fichero es modificar la carpeta que lo contiene** (le quitas su nombre de la lista), no tocar el fichero. Lo que cuenta es el permiso `w` **de la carpeta** (capítulo 3).

> 🗨️ Si pruebas `rm` en un fichero de solo lectura **directamente en la terminal**, `rm` te preguntará por precaución: `rm: remove write-protected regular file 'prueba.txt'?`. Contesta `y` y se borra igual. Es **solo un aviso amable**, no una prohibición. (Aquí lo hicimos con `< /dev/null` para no tener que contestar.)

---

## 2.4 · Quitar la ejecución (`x`) y los scripts

Creemos un script de verdad (un programa en texto que lanza `bash`):

```text
$ cat > hola.sh <<'EOF'
#!/bin/bash
echo "¡Hola desde un script! Soy $(whoami)"
EOF
$ ls -l hola.sh
-rw-rw-r-- 1 alumno alumno 57 Oct 16 17:08 hola.sh
$ ./hola.sh
bash: ./hola.sh: Permission denied
```

Falla. El fichero se acaba de crear **sin** `x` (los ficheros nuevos **nunca** nacen ejecutables, es una medida de seguridad; ya veremos por qué en el capítulo 8 con `umask`). Hay que dárselo:

```text
$ chmod u+x hola.sh
$ ls -l hola.sh
-rwxrw-r-- 1 alumno alumno 57 Oct 16 17:08 hola.sh
$ ./hola.sh
¡Hola desde un script! Soy alumno
```

La línea `#!/bin/bash` del principio (llamada ***shebang***) le dice al sistema: *"para ejecutar este fichero, usa el programa `/bin/bash`"*.

### 🎭 `./script` frente a `bash script`

Hay **dos formas** de lanzar un script, y piden permisos **distintos**:

| Forma | Quién lo lee | Necesita en el fichero… |
|---|---|---|
| `./hola.sh` | el **sistema** ejecuta el fichero | **`r` + `x`** |
| `bash hola.sh` | **tú** le pasas el texto a `bash` | solo **`r`** |

```text
$ chmod u-x hola.sh
$ ./hola.sh
bash: ./hola.sh: Permission denied
$ bash hola.sh
¡Hola desde un script! Soy alumno
```

Sin `x`, `./hola.sh` falla, pero **`bash hola.sh` funciona**: `bash` es el programa que se ejecuta (y él sí tiene `x`); el script es solo un **texto que lee**. Esto explica algo muy típico del examen: *"un script sin `x` se puede ejecutar pasándoselo al intérprete."*

### 🎭 Y al revés: `x` sin `r`

```text
$ chmod u=x hola.sh
$ ls -l hola.sh
---xrw-r-- 1 alumno alumno 57 Oct 16 17:08 hola.sh
$ ./hola.sh
/bin/bash: ./hola.sh: Permission denied
$ bash hola.sh
bash: hola.sh: Permission denied
```

Con solo `x`, el dueño **no puede ejecutarlo**, porque para un **script** hace falta que el intérprete **lea** el texto. **Un script necesita `r` y `x`.**

### 🎭 Pero un **programa compilado** (binario) es distinto

Un binario no es "texto que se lee": el sistema lo carga y lo ejecuta directamente. Para eso **basta `x`**. Probémoslo con una copia del programa `ls` (es un binario de verdad):

```text
$ cp /usr/bin/ls mi-ls
$ chmod 111 mi-ls
$ ls -l mi-ls
---x--x--x 1 alumno alumno 142312 Oct 16 17:08 mi-ls
$ ./mi-ls datos
agenda.txt  notas.txt  secreto.txt  ventas.csv
$ cat mi-ls | head -c 4
cat: mi-ls: Permission denied
```

`---x--x--x` (`111`): **ejecutable por todos, ilegible para todos**, y funciona. Es la técnica que usan programas que se quieren *dejar usar* pero no *copiar ni inspeccionar*.

| | ¿Script? | ¿Binario? |
|---|---|---|
| Ejecutar con `./f` | necesita `r` + `x` | basta **`x`** |
| Ejecutar con `intérprete f` | basta `r` | — |

> 💡 **Por eso `saludos.sh` de tu captura** (`-rwxr-x--x`) no podían usarlo "otros": tenían `--x` pero es un **script** y les faltaba la `r` (capítulo 1).

---

## 2.5 · Permisos que se aplican *al abrir*, no *en cada instante*

Un detalle sutil: Linux comprueba los permisos **cuando abres el fichero**. Si un programa ya lo tiene abierto y alguien le quita el permiso, **ese programa sigue pudiendo** usarlo hasta que lo cierre. Pero el **siguiente** que lo intente, no. (Este detalle explica por qué los *cambios de permisos* no "echan" a quien ya estaba dentro.)

---

## 2.6 · ¿Y el dueño? El dueño siempre puede `chmod`

Aunque un fichero tenga `---------` (`000`), **su dueño puede cambiarle los permisos** (y así recuperar el acceso). No depende de `rwx`: depende de **ser el dueño** (o `root`):

```text
$ echo "contenido" > cerrado.txt
$ chmod 000 cerrado.txt
$ ls -l cerrado.txt
---------- 1 alumno alumno 10 Oct 16 17:08 cerrado.txt
$ cat cerrado.txt
cat: cerrado.txt: Permission denied
$ chmod u+r cerrado.txt
$ cat cerrado.txt
contenido
```

---

## 2.7 · Las operaciones habituales y el permiso que piden

Una chuleta de lo que cada comando necesita **sobre el fichero** (lo de la carpeta, en el capítulo 3):

| Quiero… | Comando | Necesito en el **fichero** |
|---|---|---|
| Ver el contenido | `cat f`, `less f`, `head f` | `r` |
| Copiarlo | `cp f g` | `r` (y `w` en la carpeta destino) |
| Añadir al final | `echo x >> f` | `w` |
| Vaciarlo / sobrescribirlo | `echo x > f`, `truncate -s0 f` | `w` |
| Editarlo con `nano`/`vim` | `nano f` | `r` (para verlo) y `w` (para guardar) |
| Ejecutarlo (`./f`) | `./f` | `x` (y `r` si es script) |
| Cambiar su fecha | `touch f` | `w` **o** ser el dueño |
| Cambiarle los permisos | `chmod …` | **ser el dueño** (o root) |
| Cambiarle el nombre | `mv f g` | nada en el fichero (¡carpeta!) |
| Borrarlo | `rm f` | nada en el fichero (¡carpeta!) |
| Contarlo (`wc`), buscarlo (`grep`) | `wc -l f` | `r` |

> ⚠️ **Los editores a veces "burlan" el `w` del fichero.** `vim` y otros no modifican el fichero: escriben uno nuevo y lo renombran sobre el viejo. Si el **fichero** es de solo lectura pero la **carpeta** es tuya, `vim` (con `:w!`) puede acabar guardándolo igualmente. De nuevo: manda la carpeta. (Capítulo 11.)

---

## 2.8 · `root` y los permisos de los ficheros

`root` se salta **la lectura y la escritura** de cualquier fichero. Pero con la **ejecución** es más puntilloso: para ejecutar un fichero **necesita que tenga `x` para alguien** (si no tiene ninguna `x`, ni `root` lo ejecuta):

```text
$ printf '#!/bin/sh\necho "soy un script"\n' > prueba-root.sh
$ chmod 000 prueba-root.sh
$ sudo cat prueba-root.sh
#!/bin/sh
echo "soy un script"
$ sudo sh -c 'echo "echo root escribe donde nadie puede" >> prueba-root.sh'
$ sudo cat prueba-root.sh
#!/bin/sh
echo "soy un script"
echo root escribe donde nadie puede
$ sudo ./prueba-root.sh
sudo: ./prueba-root.sh: command not found
$ chmod 100 prueba-root.sh
$ sudo ./prueba-root.sh
soy un script
root escribe donde nadie puede
```

Con `000`, `root` **lee y escribe** sin problemas, pero **no puede ejecutarlo**. Cuando *alguien* tiene `x` (aquí `100`), `root` sí.

---

## 2.9 · 🏋️ Ejercicios

#### 🟢 Ejercicio 2.1 · Leer o no leer

Crea `nota.txt` con el texto `hola` y quítale **solo** el permiso de lectura al dueño. Comprueba que `cat` falla. Devuélvelo.

<details>
<summary>💡 Ver solución</summary>

```text
$ echo hola > nota.txt
$ chmod u-r nota.txt
$ ls -l nota.txt
--w-rw-r-- 1 alumno alumno 5 Oct 16 17:08 nota.txt
$ cat nota.txt
cat: nota.txt: Permission denied
$ chmod u+r nota.txt
$ cat nota.txt
hola
```
</details>

#### 🟢 Ejercicio 2.2 · Solo lectura

Deja `nota.txt` en `r--r--r--` (`444`) y prueba a escribirle. ¿Qué dice el error?

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod 444 nota.txt
$ ls -l nota.txt
-r--r--r-- 1 alumno alumno 5 Oct 16 17:08 nota.txt
$ echo "más" >> nota.txt
bash: nota.txt: Permission denied
```

`Permission denied` (en español: `Permiso denegado`).
</details>

#### 🟢 Ejercicio 2.3 · Tu primer script ejecutable

Crea `saluda.sh` que imprima `Hola` y consigue ejecutarlo con `./saluda.sh`.

<details>
<summary>💡 Ver solución</summary>

```text
$ printf '#!/bin/bash\necho Hola\n' > saluda.sh
$ ./saluda.sh
bash: ./saluda.sh: Permission denied
$ chmod +x saluda.sh
$ ./saluda.sh
Hola
```

El primer intento falla por falta de `x`; con `chmod +x` funciona.
</details>

#### 🟡 Ejercicio 2.4 · Ejecutar sin `x`

Quítale la `x` a `saluda.sh` y ejecútalo **sin** `./`, sin volver a ponérsela.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod -x saluda.sh
$ bash saluda.sh
Hola
```

`bash` lo **lee** (basta `r`) como un texto cualquiera.
</details>

#### 🟡 Ejercicio 2.5 · ¿Puede carla leerlo?

`datos/agenda.txt` es `rw-r--r--`. ¿Puede `carla` leerlo? ¿Y modificarlo?

<details>
<summary>💡 Ver solución</summary>

```text
$ ls -l datos/agenda.txt
-rw-r--r-- 1 alumno alumno 56 Oct 12 09:30 datos/agenda.txt
$ sudo -u carla cat datos/agenda.txt
Reunión el lunes a las 10:00
Llevar el informe impreso
$ sudo -u carla sh -c 'echo "hola" >> datos/agenda.txt'
sh: 1: cannot create datos/agenda.txt: Permission denied
```

Leer sí (`r--` para otros), escribir no.
</details>

#### 🟡 Ejercicio 2.6 · `w` no es borrar

Pon un fichero a `444` y bórralo **sin** forzarlo. Explica por qué se puede.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch inofensivo.txt
$ chmod 444 inofensivo.txt
$ rm -v inofensivo.txt < /dev/null
removed 'inofensivo.txt'
```

Se borra porque **tienes `w` en la carpeta** donde está. Los permisos del fichero no importan para borrar.
</details>

#### 🟡 Ejercicio 2.7 · Un programa que se deja usar pero no ver

Copia `/usr/bin/whoami` como `mi-whoami` con permisos `--x--x--x` y comprueba que `carla` puede **ejecutarlo** pero **no leerlo**.

<details>
<summary>💡 Ver solución</summary>

```text
$ cp /usr/bin/whoami mi-whoami
$ chmod 111 mi-whoami
$ ls -l mi-whoami
---x--x--x 1 alumno alumno 35336 Oct 16 17:08 mi-whoami
$ sudo -u carla ./mi-whoami
carla
$ sudo -u carla cat mi-whoami | head -c 4
cat: mi-whoami: Permission denied
```

Funciona porque es un **binario**. `cat` falla por la falta de `r`.
</details>

#### 🔴 Ejercicio 2.8 · El script que no se deja ejecutar

`./mi.sh` con permisos `---x------` (`100`) da `Permission denied` aunque sea del dueño. ¿Por qué? Arréglalo cambiando **un solo permiso**.

<details>
<summary>💡 Ver solución</summary>

```text
$ printf '#!/bin/bash\necho funciona\n' > mi.sh
$ chmod 100 mi.sh
$ ls -l mi.sh
---x------ 1 alumno alumno 26 Oct 16 17:08 mi.sh
$ ./mi.sh
/bin/bash: ./mi.sh: Permission denied
$ chmod u+r mi.sh
$ ./mi.sh
funciona
```

Porque un script necesita **leerse**: `r` + `x`.
</details>

#### 🔴 Ejercicio 2.9 · Solo escritura

Crea un fichero `buzon.txt` donde tú **puedas añadir** líneas pero **no verlas** (`-w-------`, es decir, `200`). Añade una línea y comprueba que no la puedes leer.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch buzon.txt
$ chmod 200 buzon.txt
$ ls -l buzon.txt
--w------- 1 alumno alumno 0 Oct 16 17:08 buzon.txt
$ echo "mensaje secreto" >> buzon.txt
$ cat buzon.txt
cat: buzon.txt: Permission denied
```
</details>

#### 🔴 Ejercicio 2.10 · Quitar todo a todos menos a ti

Haz que solo tú puedas leer y escribir `secreto2.txt`, y demuestra con `ana` que no puede ni leerlo.

<details>
<summary>💡 Ver solución</summary>

```text
$ echo "mi secreto" > secreto2.txt
$ chmod 600 secreto2.txt
$ ls -l secreto2.txt
-rw------- 1 alumno alumno 11 Oct 16 17:08 secreto2.txt
$ sudo -u ana cat secreto2.txt
cat: secreto2.txt: Permission denied
```

`600` = `rw-------`: dueño lee y escribe; grupo y otros, nada.
</details>

#### ⚫ Ejercicio 2.11 · Root y la `x`

`root` puede leer y escribir cualquier fichero. ¿Puede ejecutar un script con permisos `000`?

<details>
<summary>💡 Ver solución</summary>

**No.** Para ejecutar un fichero se necesita **al menos una `x`** en sus permisos (de alguien). Lo vimos en la sección 2.8: `sudo ./prueba-root.sh` con `000` falla, y con `100` funciona.
</details>

#### ⚫ Ejercicio 2.12 · Pregunta de examen

*Un usuario tiene un script con permisos `-r-xr-xr-x`. ¿Qué puede hacer su dueño?* a) Solo ejecutarlo b) Leerlo y ejecutarlo, pero no modificarlo c) Modificarlo, leerlo y ejecutarlo d) Nada

<details>
<summary>💡 Ver solución</summary>

**b)**. `r-x` para el dueño: lee y ejecuta; **no** tiene `w`, así que no puede **modificar el contenido** (aunque sí podría darse `w` con `chmod u+w`, porque es el dueño).
</details>

#### ⚫ Ejercicio 2.13 · ¿Cuál es la diferencia?

Explica, con un ejemplo, la diferencia entre `./f` y `bash f` en cuanto a permisos.

<details>
<summary>💡 Ver solución</summary>

- `./f` → el **sistema** debe poder **ejecutar** `f`: necesita `x` (y `r`, si es un script con *shebang*).
- `bash f` → es **`bash`** el que se ejecuta; `f` solo es un **texto de entrada** que tiene que poder **leer**: basta `r`.

Por eso un script **sin `x`** se puede lanzar con `bash script.sh`, pero **no** con `./script.sh`.
</details>

---

⬅️ [Capítulo 1 · Leer `ls -l` de un vistazo](01-leer-ls-l.md) · [📚 Índice](README.md) · [Capítulo 3 · `r`, `w` y `x` en los directorios: el capítulo que casi todos entienden mal](03-directorios.md) ➡️
