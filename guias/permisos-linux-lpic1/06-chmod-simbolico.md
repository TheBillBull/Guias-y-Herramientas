# Capítulo 6 · `chmod` en modo simbólico: `u+x`, `go-w`, `a=r`…

> 🎯 **Objetivo:** cambiar permisos **diciendo lo que quieres con letras**: a **quién** (`u g o a`), **qué haces** (`+ - =`) y **con qué permisos** (`r w x X s t`). Dominar `-R`, `X`, copiar permisos y las trampas de `chmod +x` / `chmod -w`.
>
> 📘 **LPIC-1:** 104.5 (`chmod` simbólico, recursivo) · 103.3.
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`. Para ver el resultado cómodamente usaremos `stat -c '%a %A %n'` (octal, letras y nombre).

---

## 6.1 · La frase: *"a este **quién**, hazle esto **con** estos permisos"*

```text
chmod   g  +  w   informe.txt
        │  │  └─ QUÉ permisos:  r  w  x  X  s  t
        │  └──── QUÉ hago:      +  añadir   -  quitar   =  fijar exactamente
        └─────── A QUIÉN:       u dueño · g grupo · o otros · a todos
```

Se lee en voz alta: **"al grupo, añádele escritura"**. Es tan natural que se aprende en minutos.

| A quién | Letra |
|---|:-:|
| el **dueño** (*user*) | `u` |
| el **grupo** (*group*) | `g` |
| los **otros** (*others*) | `o` |
| **todos** (*all* = u+g+o) | `a` |

| Operación | Símbolo | Significa |
|---|:-:|---|
| añadir | `+` | **enciende** esos permisos y **no toca los demás** |
| quitar | `-` | **apaga** esos permisos y **no toca los demás** |
| fijar | `=` | pone **exactamente** esos permisos y **apaga el resto** de esa categoría |

Y los permisos: `r` leer · `w` escribir · `x` ejecutar · `X` (ejecutar "inteligente", 6.6) · `s` SUID/SGID (cap. 10) · `t` sticky (cap. 10).

---

## 6.2 · Primeros pasos: `+`, `-` y `=` con un fichero

Creamos un fichero y lo dejamos en `644` (`rw-r--r--`). Para ver el efecto de cada cambio usamos una función de ayuda que **ejecuta el `chmod` y muestra el resultado**:

```bash
cp datos/notas.txt prueba.txt
chmod 644 prueba.txt
v() { chmod "$@"; stat -c '%a %A' prueba.txt; }
```

Ahora experimenta (cada línea parte del resultado de la anterior):

```text
$ stat -c '%a %A' prueba.txt
644 -rw-r--r--
$ v g+w prueba.txt
664 -rw-rw-r--
$ v o-r prueba.txt
660 -rw-rw----
$ v u+x prueba.txt
760 -rwxrw----
$ v a+x prueba.txt
771 -rwxrwx--x
$ v go-x prueba.txt
760 -rwxrw----
```

Línea a línea:

- `g+w` → al **grupo** le **añado** `w`: `rw-` `rw-` `r--`.
- `o-r` → a **otros** les **quito** `r`: `rw-rw----`.
- `u+x` → al **dueño** le **añado** `x`: `rwxrw----`.
- `a+x` → **a todos** les añado `x`: `rwxrwx--x`.
- `go-x` → a **grupo y otros** (juntos) les quito `x`: `rwxrw----`.

### El `=` es el "borra y pon":

```text
$ v u=rw prueba.txt
660 -rw-rw----
$ v u=rwx,g=rx,o= prueba.txt
750 -rwxr-x---
$ v g=r prueba.txt
740 -rwxr-----
$ v o=r prueba.txt
744 -rwxr--r--
$ v a= prueba.txt
0 ----------
$ v a=rw prueba.txt
666 -rw-rw-rw-
```

`=` **sustituye** lo que hubiera: `g=r` deja al grupo con `r--` aunque antes tuviera `rwx`. `o=` (sin nada tras el `=`) **lo deja sin permisos**. `a=` los deja a todos sin nada: `---------`.

| Quiero… | Con `+` / `-` | Con `=` |
|---|---|---|
| Darle `w` al grupo **sin tocar lo demás** | `g+w` ✅ | — |
| Que el grupo tenga **exactamente** `r-x` | — | `g=rx` ✅ |
| Quitar **todo** a los demás | `o-rwx` | `o=` ✅ (más corto) |
| Poner **exactamente** `rw-r--r--` | — | `u=rw,go=r` ✅ |

---

## 6.3 · Varias órdenes a la vez: la coma, y varios "quién" juntos

Se pueden poner **varias órdenes separadas por comas (sin espacios)**, y **varias letras de "quién" juntas**:

```text
$ v u=rwx,g=rx,o=rx prueba.txt
755 -rwxr-xr-x
$ v ug+w,o-rwx prueba.txt
770 -rwxrwx---
$ v a=r,u+w prueba.txt
644 -rw-r--r--
```

- `ug+w,o-rwx` → (dueño y grupo) añaden `w` **y** (otros) pierden todo.
- `a=r,u+w` → todos `r--` y luego el dueño añade `w`: `rw-r--r--`. (Se aplican **de izquierda a derecha**.)

> ⚠️ **Sin espacios.** `chmod u+x, g+w f` (con espacio tras la coma) falla: `chmod` cree que `g+w` es un fichero.

---

## 6.4 · Copiar los permisos de otro: `g=u`, `o=g`

A la derecha del operador, en lugar de `r`, `w`, `x`, puedes poner **`u`, `g` u `o`**: *"copia lo que tiene el dueño/grupo/otros"*.

```text
$ v u=rwx,g=,o= prueba.txt
700 -rwx------
$ v g=u prueba.txt
770 -rwxrwx---
$ v o=g prueba.txt
777 -rwxrwxrwx
```

`g=u` → "que el **grupo** tenga **lo mismo que el dueño**"; `o=g` → "que **otros** tengan lo mismo que el grupo". Muy útil para **igualar** sin pensar en números: `chmod g=u f` es "dale al grupo lo que ya tengo yo".

---

## 6.5 · ⚠️ La trampa del "sin quién": `chmod +x` no es lo mismo que `chmod a+x`

Si **no pones quién** (`chmod +x f`, `chmod -w f`, `chmod =rw f`), `chmod` actúa como `a` **pero respetando tu `umask`**: *los bits que la umask bloquea, no se tocan*. Con una `umask 022` típica casi no se nota, pero con otra…

```bash
probar() {
  ( umask "$1"
    touch -- t; chmod 666 t; chmod +x t;   a=$(stat -c %a t)
    chmod 777 t; chmod -w t 2>/dev/null;   b=$(stat -c %a t)
    chmod 000 t; chmod =rw t;              c=$(stat -c %a t)
    chmod 777 t; chmod a-w t;              d=$(stat -c %a t)
    printf 'umask %s │ 666 +x → %s │ 777 -w → %s │ 000 =rw → %s │ 777 a-w → %s\n' "$1" "$a" "$b" "$c" "$d"
    rm -f t )
}
probar 022
probar 002
probar 077
probar 027
```

_Resultado:_

```text
umask 022 │ 666 +x → 777 │ 777 -w → 577 │ 000 =rw → 644 │ 777 a-w → 555
umask 002 │ 666 +x → 777 │ 777 -w → 557 │ 000 =rw → 664 │ 777 a-w → 555
umask 077 │ 666 +x → 766 │ 777 -w → 577 │ 000 =rw → 600 │ 777 a-w → 555
umask 027 │ 666 +x → 776 │ 777 -w → 577 │ 000 =rw → 640 │ 777 a-w → 555
```

Lee la **segunda columna** (`777 -w`): `chmod -w f` sobre un `777`:

- con `umask 022` → **`577`** (¡solo le quitó la `w` al dueño!)
- con `umask 077` → **`577`** también
- pero **`a-w`** (con la `a` explícita) → **`555`** siempre (última columna).

La razón: la `umask 022` "protege" (no toca) los bits de escritura de grupo y otros, y `chmod` obedece. Y `chmod` hasta **avisa**:

```text
$ touch aviso.txt
$ chmod 777 aviso.txt
$ chmod -w aviso.txt
chmod: aviso.txt: new permissions are r-xr-xrwx, not r-xr-xr-x
$ stat -c '%a %A' aviso.txt
557 -r-xr-xrwx
```

> 🎓 **Regla práctica:** cuando **quites** permisos, escribe siempre el *quién* (`a-w`, `go-w`, `u-x`…). Con `+x` sin quién no hay problema en la práctica (la umask casi nunca bloquea la `x`), pero `chmod -w` a secas **te engaña**. (Y `chmod =rw f` también: sobre un `000` con `umask 022` da `644`, **no** `666`.)

---

## 6.6 · `X` (mayúscula): "ejecuta, pero solo si tiene sentido"

La `X` mayúscula pone `x` **solo si** (a) es un **directorio**, o (b) el fichero **ya tenía `x`** para alguien. Es la solución a un problema muy típico: *dar acceso a todo un árbol sin convertir los ficheros de texto en ejecutables*.

```text
$ mkdir -p arbol/sub
$ echo "texto" > arbol/doc.txt
$ printf '#!/bin/bash\necho hola\n' > arbol/script.sh
$ chmod 744 arbol/script.sh
$ echo "otro" > arbol/sub/dato.txt
$ chmod -R go-rwx arbol
$ find arbol -exec stat -c '%a %A %n' {} +
700 drwx------ arbol
700 -rwx------ arbol/script.sh
700 drwx------ arbol/sub
600 -rw------- arbol/sub/dato.txt
600 -rw------- arbol/doc.txt
$ chmod -R go=rX arbol
$ find arbol -exec stat -c '%a %A %n' {} +
755 drwxr-xr-x arbol
755 -rwxr-xr-x arbol/script.sh
755 drwxr-xr-x arbol/sub
644 -rw-r--r-- arbol/sub/dato.txt
644 -rw-r--r-- arbol/doc.txt
```

Resultado de `go=rX`:

- **Directorios** (`arbol`, `arbol/sub`) → `r-x` para grupo y otros (entrar y listar).
- **`script.sh`** (que ya tenía `x` para el dueño) → `r-x`.
- **Ficheros de texto** (`doc.txt`, `dato.txt`) → solo `r--`: **¡sin `x`!** Eso no lo habríamos conseguido con `-R go=rx`.

> ⭐ **La receta más usada para "publicar" una carpeta:** `chmod -R u=rwX,go=rX carpeta` (dueño todo, los demás leen y entran, sin ejecutables por accidente). La estudiamos en el capítulo 7.

---

## 6.7 · Las opciones útiles de `chmod`

| Opción | Hace |
|---|---|
| `-R` | **recursivo**: entra en las subcarpetas |
| `-v` | **v**erbose: cuenta cada fichero procesado |
| `-c` | como `-v`, pero **solo los que cambian** |
| `-f` | **f**orce/silencio: calla los errores |
| `--reference=OTRO` | copia los permisos de **otro fichero** |
| `--preserve-root` | se niega a actuar sobre `/` con `-R` |

```text
$ touch a b c
$ chmod 600 a b
$ chmod 644 c
$ chmod -v 600 a b c
mode of 'a' retained as 0600 (rw-------)
mode of 'b' retained as 0600 (rw-------)
mode of 'c' changed from 0644 (rw-r--r--) to 0600 (rw-------)
$ chmod -c 640 a b
mode of 'a' changed from 0600 (rw-------) to 0640 (rw-r-----)
mode of 'b' changed from 0600 (rw-------) to 0640 (rw-r-----)
$ chmod -c 640 a b c
mode of 'c' changed from 0600 (rw-------) to 0640 (rw-r-----)
```

`-v` te dice **todo** (aunque no cambie nada: *"retained as"*); `-c` solo lo que **cambió** (*"changed from"*). Fíjate en la última orden: `a` y `b` **ya** estaban en `640`, así que solo informa de `c`.

```text
$ touch modelo.txt
$ chmod 604 modelo.txt
$ chmod --reference=modelo.txt a b
$ stat -c '%a %n' modelo.txt a b
604 modelo.txt
604 a
604 b
```

`--reference=modelo.txt` significa "ponles los permisos que tiene `modelo.txt`" (y **no** se escribe modo alguno). Es una forma elegante de **clonar** permisos sin saber el número.

> 🛑 **`chmod -R` es potente y peligroso.** Un `chmod -R 777 /` (o `-R 000 /`) destroza un sistema. Por eso `chmod` moderno trae `--preserve-root`. **Pregúntate siempre en qué carpeta estás antes de un `-R`** (`pwd`).

---

## 6.8 · Quién puede hacer `chmod`

**Solo el dueño del fichero (o `root`).** Aunque tengas `rwx` completo sobre un fichero ajeno, **no** puedes cambiarle los permisos:

```text
$ touch comun.txt
$ chmod 666 comun.txt
$ sudo -u carla sh -c 'echo "puedo escribir" >> comun.txt'
$ sudo -u carla chmod 600 comun.txt
chmod: changing permissions of 'comun.txt': Operation not permitted
$ cat comun.txt
puedo escribir
```

`carla` puede **modificar el contenido** (porque `666`), pero **no** `chmod`: `Operation not permitted`. Cambiar permisos es un derecho del **dueño**, no una consecuencia de `rwx`. (Fíjate en el **mensaje**: `Operation not permitted` ≠ `Permission denied`. El primero dice *"esta acción está reservada"*, el segundo *"te falta un permiso"*.)

---

## 6.9 · `chmod` y los enlaces simbólicos

`chmod` sobre un enlace simbólico cambia **el fichero al que apunta** (el enlace siempre es `lrwxrwxrwx`):

```text
$ touch real.txt
$ chmod 644 real.txt
$ ln -s real.txt acceso
$ chmod 600 acceso
$ stat -c '%a %A %n' real.txt acceso
600 -rw------- real.txt
777 lrwxrwxrwx acceso
$ mkdir -p arb2
$ ln -s ../real.txt arb2/otro-acceso
$ chmod 644 real.txt
$ chmod -R 700 arb2
$ stat -c '%a %A %n' real.txt arb2/otro-acceso
644 -rw-r--r-- real.txt
777 lrwxrwxrwx arb2/otro-acceso
```

Dos cosas:

- `chmod 600 acceso` **cambió `real.txt`** (a `600`), y el enlace sigue `lrwxrwxrwx`.
- Con **`-R`**, `chmod` **NO sigue** los enlaces de dentro (`real.txt` se quedó en `644`): evita que un enlace malintencionado te haga cambiar permisos fuera de la carpeta.

---

## 6.10 · Los permisos especiales con letras (adelanto)

Con letras los bits especiales se escriben fácil:

| Quiero… | Comando |
|---|---|
| poner **SUID** | `chmod u+s programa` |
| poner **SGID** | `chmod g+s carpeta` |
| poner **sticky** | `chmod +t carpeta` (o `o+t`) |
| quitarlos | `chmod u-s`, `g-s`, `-t` |

(El capítulo 10 les dedica su espacio.) Y una **diferencia importante** con el modo octal (capítulo 7): `g-s` quita el SGID de una carpeta; `chmod 755` **no** se lo quita.

---

## 6.11 · Recetas del día a día

| Quiero… | Receta |
|---|---|
| Hacer ejecutable un script | `chmod u+x script.sh` (o `+x`) |
| Quitar la escritura a todos | `chmod a-w f` |
| Hacer algo privado | `chmod go= f` (o `chmod 600 f`) |
| Que el grupo pueda editar | `chmod g+w f` |
| Dejar un fichero de solo lectura | `chmod a=r f` (o `chmod 444 f`) |
| Publicar una carpeta (no ejecutables por accidente) | `chmod -R u=rwX,go=rX carpeta` |
| Copiar permisos de otro | `chmod --reference=modelo f` |
| Igualar al grupo con el dueño | `chmod g=u f` |
| Quitar `x` solo a ficheros (no carpetas) | `find . -type f -exec chmod a-x {} +` |

---

## 6.12 · 🏋️ Ejercicios

Parte siempre de un fichero nuevo para que sea reproducible. `stat -c '%a %A %n'` es tu amigo.

#### 🟢 Ejercicio 6.1 · Hacer ejecutable

Crea `hola2.sh`, comprueba que no se puede ejecutar y hazlo ejecutable **solo para ti**.

<details>
<summary>💡 Ver solución</summary>

```text
$ printf '#!/bin/bash\necho "hola desde hola2"\n' > hola2.sh
$ ./hola2.sh
bash: ./hola2.sh: Permission denied
$ chmod u+x hola2.sh
$ ./hola2.sh
hola desde hola2
$ stat -c '%a %A' hola2.sh
764 -rwxrw-r--
```
</details>

#### 🟢 Ejercicio 6.2 · Quitar escritura a grupo y otros

Un fichero `rw-rw-rw-` debe quedar `rw-r--r--` **sin usar números**.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch ej.txt
$ chmod 666 ej.txt
$ chmod go-w ej.txt
$ stat -c '%a %A' ej.txt
644 -rw-r--r--
```
</details>

#### 🟢 Ejercicio 6.3 · Privado

Deja `ej.txt` accesible **solo para ti**, sin números.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod go= ej.txt
$ stat -c '%a %A' ej.txt
600 -rw-------
```

(Otra forma: `chmod go-rwx ej.txt`, o `chmod u=rw,go= ej.txt`.)
</details>

#### 🟡 Ejercicio 6.4 · Fijar exactamente

Deja `ej.txt` en **exactamente** `rwxr-x---` usando `=`.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod u=rwx,g=rx,o= ej.txt
$ stat -c '%a %A' ej.txt
750 -rwxr-x---
```

Ese es el `750`.
</details>

#### 🟡 Ejercicio 6.5 · Igualar con `g=u`

El dueño tiene `rwx`. Haz que el grupo tenga **lo mismo**, y que otros tengan **lo mismo que el grupo**, de un tirón.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod u=rwx,g=,o= ej.txt
$ chmod g=u,o=g ej.txt
$ stat -c '%a %A' ej.txt
777 -rwxrwxrwx
```

Resultado `777`. En la práctica: `chmod a=u` hace lo mismo.
</details>

#### 🟡 Ejercicio 6.6 · Un árbol sin ejecutables accidentales

Con `arbol/` (carpetas, textos y un script), deja: dueño `rwx` en todo lo que ya fuera ejecutable o carpeta, y el resto de gente solo `r-x` en eso, `r--` en los textos.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod -R u=rwX,go=rX arbol
$ find arbol -exec stat -c '%a %A %n' {} +
755 drwxr-xr-x arbol
755 -rwxr-xr-x arbol/script.sh
755 drwxr-xr-x arbol/sub
644 -rw-r--r-- arbol/sub/dato.txt
644 -rw-r--r-- arbol/doc.txt
```

La `X` ya sabe distinguir carpetas, ejecutables y textos.
</details>

#### 🟡 Ejercicio 6.7 · Ver lo que cambia

Pon `a`, `b` y `c` en `600`; luego usa `chmod -c` para que **solo te diga lo que cambió** al aplicar `644` a los tres, y repítelo.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod 600 a b c
$ chmod -c 644 a b c
mode of 'a' changed from 0600 (rw-------) to 0644 (rw-r--r--)
mode of 'b' changed from 0600 (rw-------) to 0644 (rw-r--r--)
mode of 'c' changed from 0600 (rw-------) to 0644 (rw-r--r--)
$ chmod -c 644 a b c
```

La primera vez dice los tres cambios; la segunda, **nada** (ya estaban en `644`). Con `-v` hubiera listado los tres las dos veces.
</details>

#### 🔴 Ejercicio 6.8 · El `chmod -w` que quitó de menos

Con `umask 022`, ¿qué obtienes de `chmod -w` sobre un `666`? ¿Y de `chmod a-w`? Explícalo.

<details>
<summary>💡 Ver solución</summary>

```text
$ ( umask 022; touch dos.txt; chmod 666 dos.txt; chmod -w dos.txt; stat -c '%a %A' dos.txt )
chmod: dos.txt: new permissions are r--rw-rw-, not r--r--r--
466 -r--rw-rw-
$ ( umask 022; chmod 666 dos.txt; chmod a-w dos.txt; stat -c '%a %A' dos.txt )
444 -r--r--r--
```

`chmod -w` (sin quién) respeta la `umask`: como la `022` "protege" la escritura de grupo y otros, **solo** se la quita al dueño (`466`). Con `a-w` (quién explícito) se la quita a **todos** (`444`).
</details>

#### 🔴 Ejercicio 6.9 · Dos órdenes equivalentes

¿`chmod u=rw,go=r f` y `chmod 644 f` hacen lo mismo? ¿Y qué da `chmod =rw f` sobre un fichero en `000` (con tu `umask`)?

<details>
<summary>💡 Ver solución</summary>

```text
$ touch eq.txt
$ chmod u=rw,go=r eq.txt; stat -c '%a' eq.txt
644
$ chmod 644 eq.txt;       stat -c '%a' eq.txt
644
$ chmod 000 eq.txt
$ umask
0002
$ chmod =rw eq.txt;       stat -c '%a' eq.txt
664
```

Las dos primeras: **sí**, ambas dan `644`. La tercera **depende de la umask** (no lleva "quién"): con la tuya (`0002`) obtienes `664`, **no** `666`, porque la `002` protege la `w` de *otros* y `chmod` la respeta.
</details>

#### 🔴 Ejercicio 6.10 · Solo el dueño hace `chmod`

`carla` tiene `rw-` sobre `compartido.txt`. ¿Puede hacerle `chmod 600`? ¿Y `sudo chmod`?

<details>
<summary>💡 Ver solución</summary>

```text
$ touch compartido.txt
$ chmod 666 compartido.txt
$ sudo -u carla chmod 600 compartido.txt
chmod: changing permissions of 'compartido.txt': Operation not permitted
$ sudo chmod 600 compartido.txt
$ stat -c '%a %A %U' compartido.txt
600 -rw------- alumno
```

`carla` no (no es dueña → `Operation not permitted`). `root` sí.
</details>

#### 🔴 Ejercicio 6.11 · ¿Qué mod queda?

Parte de `rw-r--r--` (644). Aplica **en este orden**: `chmod u+x,g-r,o+w f`. ¿Qué queda?

<details>
<summary>💡 Ver solución</summary>

```text
$ permisos 644 u+x,g-r,o+w | grep -E 'Octal|Letras'
  Octal     706
  Letras    rwx---rw-      (en ls -l: -rwx---rw-)
```

`u+x` → `rwx`; `g-r` → `---`; `o+w` → `rw-`. Queda **`rwx---rw-`** = **706**.
</details>

#### 🔴 Ejercicio 6.12 · Un solo comando para "publicar"

Deja `arbol/` (con carpetas y ficheros) listo para **servir por web**: carpetas `755`, ficheros `644`, **sin** perder la `x` de los scripts. Hazlo con **un solo `chmod -R`**.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod -R u=rwX,go=rX arbol
$ find arbol -exec stat -c '%a %n' {} +
755 arbol
755 arbol/script.sh
755 arbol/sub
644 arbol/sub/dato.txt
644 arbol/doc.txt
```

Carpetas → `755`; ficheros → `644`; el script que ya era ejecutable → `755`. (Si quisieras forzar `644` aun en los ejecutables, tendrías que usar `find`: capítulo 7.)
</details>

#### ⚫ Ejercicio 6.13 · Examen: `+x` frente a `a+x`

*¿En qué se diferencia `chmod +x f` de `chmod a+x f`?* a) En nada b) `+x` respeta la `umask`; `a+x` no c) `a+x` solo afecta al dueño d) `+x` quita la `x`

<details>
<summary>💡 Ver solución</summary>

**b).** Sin "quién", `chmod` actúa como `a` pero **no toca los bits bloqueados por la umask**. Con `a+x` (quién explícito) la `umask` no interviene.
</details>

#### ⚫ Ejercicio 6.14 · Examen: ¿qué queda?

*Un fichero tiene `-rw-r--r--`. Tras `chmod g=u,o= f`, ¿qué permisos tiene?* a) `-rw-rw----` b) `-rw-r-----` c) `-rw-rw-r--` d) `-rwxrwx---`

<details>
<summary>💡 Ver solución</summary>

**a).** `g=u` copia el `rw-` del dueño al grupo; `o=` borra los de otros.

```text
$ permisos 644 g=u,o= | grep -E 'Octal|Letras'
  Octal     660
  Letras    rw-rw----      (en ls -l: -rw-rw----)
```
</details>

#### ⚫ Ejercicio 6.15 · Examen: ¿cuál NO es válida?

*¿Cuál de estas órdenes `chmod` es sintácticamente incorrecta?* a) `chmod u+x,g-w f` b) `chmod ug=rw f` c) `chmod u + x f` d) `chmod a=u f`

<details>
<summary>💡 Ver solución</summary>

**c)**: los **espacios** separan argumentos (`u`, `+`, `x` serían tres argumentos distintos). Las demás son válidas.

```text
$ touch sint.txt
$ chmod u + x sint.txt
chmod: invalid mode: ‘u’
Try 'chmod --help' for more information.
```
</details>

---

⬅️ [Capítulo 5 · Octal, binario, decimal y letras: entender 755, 644 o 4755 de un vistazo](05-octal-binario-decimal.md) · [📚 Índice](README.md) · [Capítulo 7 · `chmod` en modo octal: `755`, `644`, `4755`… y cómo aplicarlos a un árbol](07-chmod-octal.md) ➡️
