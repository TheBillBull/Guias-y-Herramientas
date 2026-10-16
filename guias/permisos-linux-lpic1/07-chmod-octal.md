# Capítulo 7 · `chmod` en modo octal: `755`, `644`, `4755`… y cómo aplicarlos a un árbol

> 🎯 **Objetivo:** usar `chmod` con **números** con total soltura, saber **cuándo conviene** el modo octal y cuándo el simbólico, aplicar permisos a **árboles enteros sin estropear nada** (`find`, `X`) y entender las sutilezas de los **bits especiales** con `chmod` numérico.
>
> 📘 **LPIC-1:** 104.5 (`chmod` octal, `find` para aplicar permisos).
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`. Si no tienes la herramienta `permisos` instalada, repasa el [capítulo 5](05-octal-binario-decimal.md).

---

## 7.1 · Lo básico: `chmod NNN fichero`

En modo octal el modo se escribe como **un número de 3 o 4 cifras** y `chmod` **fija exactamente** esos permisos (no suma ni resta: **sustituye**):

```text
chmod  7 5 5  script.sh
       │ │ └─ OTROS  (5 = r-x)
       │ └─── GRUPO  (5 = r-x)
       └───── DUEÑO  (7 = rwx)
```

```text
$ touch f1
$ chmod 755 f1
$ stat -c '%a %A' f1
755 -rwxr-xr-x
$ chmod 640 f1
$ stat -c '%a %A' f1
640 -rw-r-----
$ chmod 000 f1
$ stat -c '%a %A' f1
0 ----------
$ chmod 0644 f1
$ stat -c '%a %A' f1
644 -rw-r--r--
$ chmod 5 f1
$ stat -c '%a %A' f1
5 -------r-x
$ chmod 75 f1
$ stat -c '%a %A' f1
75 ----rwxr-x
```

Cosas que enseña este ejemplo:

- `chmod 755 f` y `chmod 0755 f` **son lo mismo**: el `0` de delante significa "sin bits especiales".
- Si das **menos de 3 cifras**, se rellenan **por la izquierda con ceros**: `chmod 5 f` = `005` (solo "otros", `r-x`... ¡y el dueño y el grupo sin nada!) y `chmod 75 f` = `075`. Es una forma típica de **cometer errores**: no abrevies nunca.
- `chmod` **no pregunta, no suma**: lo que escribes es **el estado final**.
- `stat -c '%a'` **no escribe los ceros de la izquierda**: donde ves `0`, `5` o `75` hay que leer `000`, `005` y `075`.

---

## 7.2 · Octal ⇄ simbólico: la tabla de equivalencias

Casi todo lo que se hace con números se puede decir con letras (y viceversa). Los más habituales:

| Octal | Simbólico equivalente (desde cero) | Se lee… |
|:-:|---|---|
| `755` | `u=rwx,go=rx` | el dueño todo; los demás leen y ejecutan |
| `644` | `u=rw,go=r` | el dueño lee/escribe; los demás leen |
| `700` | `u=rwx,go=` | solo el dueño, todo |
| `600` | `u=rw,go=` | solo el dueño, leer/escribir |
| `750` | `u=rwx,g=rx,o=` | el grupo lee y ejecuta; otros nada |
| `640` | `u=rw,g=r,o=` | el grupo lee; otros nada |
| `664` | `ug=rw,o=r` | dueño y grupo escriben; otros leen |
| `775` | `ug=rwx,o=rx` | dueño y grupo todo; otros leen/ejecutan |
| `444` | `a=r` | todos solo lectura |
| `777` | `a=rwx` | **todo para todos** |
| `000` | `a=` | nada para nadie |

Los comprobamos con la herramienta (la columna izquierda y la derecha deben dar **lo mismo**):

```text
$ permisos 755 | grep -E 'Octal'
  Octal     755
$ permisos 'u=rwx,go=rx' | grep -E 'Octal'
  Octal     755
$ permisos 664 | grep -E 'Octal'
  Octal     664
$ permisos 'ug=rw,o=r' | grep -E 'Octal'
  Octal     664
```

---

## 7.3 · ¿Octal o simbólico? Cómo elegir

| Situación | Mejor | Por qué |
|---|:-:|---|
| Quiero un **estado final concreto** (`rw-r-----`) | **octal** | corto, exacto, no depende de cómo estuviera antes |
| Quiero **ajustar una cosa** y no tocar el resto (`+x`) | **simbólico** | no tienes que saber el valor actual |
| Aplicar permisos **a un árbol** con ficheros y carpetas mezclados | **simbólico con `X`** o **`find`** | el octal trata igual carpetas y ficheros (¡problema!) |
| Escribir en **un script / documentación** | **octal** | no hay ambigüedad |
| "Quitar" un permiso | **simbólico** | `a-x` es obvio; en octal hay que recalcular |
| Probar a mano | el que te sea más cómodo | ¡los dos llevan al mismo sitio! |

> 🎓 En el examen LPIC-1 aparecen **los dos**: tienes que saber leer `chmod 750` y `chmod u=rwx,g=rx,o=`.

---

## 7.4 · Recalcular el octal tras un cambio (y entender el *porqué*)

Para sumar o restar un permiso a un modo octal **sin pasar por letras**, mira esas tres cifras como **bits**:

| Quiero… | Qué hago con los bits | Octal | Ejemplo |
|---|---|---|---|
| **añadir** `w` al grupo | **O** (`\|`) con `020` | `\| 020` | `644 → 664` |
| **quitar** `x` a todos | **Y NO** (`& ~`) con `111` | `& ~111` | `755 → 644` |
| **quitar** todo a otros | `& ~007` | `& ~007` | `755 → 750` |
| **añadir** `x` al dueño | `\| 100` | `\| 100` | `644 → 744` |

Lo comprobamos con la aritmética de Bash (`8#` = "en octal"):

```text
$ printf '%o\n' $(( 8#644 | 8#020 ))
664
$ printf '%o\n' $(( 8#755 & ~8#111 ))
644
$ printf '%o\n' $(( 8#755 & ~8#007 ))
750
$ printf '%o\n' $(( 8#644 | 8#100 ))
744
```

- **`+`** en simbólico = **O** (`|`): enciende bits.
- **`-`** en simbólico = **Y NO** (`& ~`): apaga bits.
- **`=`** en simbólico = **sustituir** esa categoría.

> 🧠 **¿Por qué no se "suma" a pelo (`644 + 020`)?** Porque si el permiso **ya estaba**, sumarías dos veces y te saldría otra cosa (`664 + 020 = 704`, ¡no `664`!). Con **O** (`|`) añadir algo que ya existe **no cambia nada**. Esta idea de "bits que se encienden o se apagan" es **justo** lo que hace la `umask` (capítulo 8).

---

## 7.5 · El gran problema: `chmod -R` con números en un árbol

Cuando aplicas `chmod -R 755 carpeta`, **todo** recibe `755`: carpetas (*bien*) **y ficheros de texto** (*mal*: no deberían ser ejecutables). Preparamos un "sitio web" de prueba con una carpeta pública mal configurada:

```text
$ mkdir -p sitio/css sitio/img
$ echo "<html></html>" > sitio/index.html
$ echo "body{}" > sitio/css/estilo.css
$ echo "PNG" > sitio/img/logo.png
$ printf '#!/bin/bash\necho desplegando\n' > sitio/despliegue.sh
$ chmod 700 sitio/despliegue.sh
$ chmod -R go-rwx sitio
$ find sitio | sort | xargs stat -c '%a %n'
700 sitio
700 sitio/css
600 sitio/css/estilo.css
700 sitio/despliegue.sh
700 sitio/img
600 sitio/img/logo.png
600 sitio/index.html
```

### ❌ Intento 1: `chmod -R 755`

```text
$ chmod -R 755 sitio
$ find sitio -type f | sort | xargs stat -c '%a %n'
755 sitio/css/estilo.css
755 sitio/despliegue.sh
755 sitio/img/logo.png
755 sitio/index.html
```

¡Los HTML, CSS y PNG quedaron **ejecutables** (`755`)! Es inofensivo aquí, pero (1) es **desordenado**, (2) en un servidor, un fichero subido que sea ejecutable puede ser peligroso, y (3) ensucia `ls --color` (todo en verde).

### ✅ Solución A: **`find` separando carpetas y ficheros**

```text
$ chmod -R go-rwx sitio
$ find sitio -type d -exec chmod 755 {} +
$ find sitio -type f -exec chmod 644 {} +
$ find sitio | sort | xargs stat -c '%a %n'
755 sitio
755 sitio/css
644 sitio/css/estilo.css
644 sitio/despliegue.sh
755 sitio/img
644 sitio/img/logo.png
644 sitio/index.html
```

- `find … -type d` → solo **directorios** → `755`.
- `find … -type f` → solo **ficheros** → `644`.
- `-exec chmod 755 {} +` = "ejecuta `chmod 755` sobre **lo que encuentres** (agrupando muchos por llamada)".

Pero **`despliegue.sh` perdió su `x`** (ahora es `644`). Para el script ejecutable hay que repetir `chmod 755 sitio/despliegue.sh`, o usar una solución mejor:

### ✅ Solución B: **`X` mayúscula** (conserva la `x` que ya existía)

```text
$ find sitio -type f -exec chmod 600 {} +
$ find sitio -type d -exec chmod 700 {} +
$ chmod 700 sitio/despliegue.sh
$ find sitio | sort | xargs stat -c '%a %n'
700 sitio
700 sitio/css
600 sitio/css/estilo.css
700 sitio/despliegue.sh
700 sitio/img
600 sitio/img/logo.png
600 sitio/index.html
$ chmod -R u=rwX,go=rX sitio
$ find sitio | sort | xargs stat -c '%a %n'
755 sitio
755 sitio/css
644 sitio/css/estilo.css
755 sitio/despliegue.sh
755 sitio/img
644 sitio/img/logo.png
644 sitio/index.html
```

(Las cuatro primeras órdenes solo **restauran el estado inicial**: ficheros `600`, carpetas `700` y el script `700`. Después viene la orden que importa.)

`u=rwX,go=rX`: el dueño `rw` + `x` si procede; grupo/otros `r` + `x` si procede. **Carpetas → `755`; ficheros normales → `644`; el script, que ya tenía `x`, → `755`**. Es la receta más usada por los administradores.

### ✅ Solución C: **dos modos distintos con `find`** (cuando quieres forzar)

```text
$ find sitio -type f -name '*.sh' -exec chmod 755 {} +
$ find sitio -type f ! -name '*.sh' -exec chmod 644 {} +
$ find sitio -type d -exec chmod 755 {} +
$ find sitio | sort | xargs stat -c '%a %n'
755 sitio
755 sitio/css
644 sitio/css/estilo.css
755 sitio/despliegue.sh
755 sitio/img
644 sitio/img/logo.png
644 sitio/index.html
```

Aquí **tú decides** qué es ejecutable (los `*.sh`) y qué no.

| Método | Resultado para ficheros normales | Para scripts ya ejecutables | Para carpetas |
|---|:-:|:-:|:-:|
| `chmod -R 755` | **755** 😬 | 755 | 755 |
| `find -type f` / `-type d` | 644 | **644** (pierde `x`) | 755 |
| `chmod -R u=rwX,go=rX` | 644 | **755** (conserva) | 755 |

> 🛑 **Nunca** hagas `chmod -R 777` para "arreglar" un problema de permisos. Convierte todo en escribible por cualquiera. Si algo "no funciona", averigua **quién** debe poder hacer **qué** (capítulo 13) en lugar de abrirlo todo.

---

## 7.6 · Las cuatro cifras: los bits especiales también se ponen con números

El cuarto dígito, el de la izquierda, se suma igual que `r w x`: **4 = SUID**, **2 = SGID**, **1 = sticky**. (Los explica el capítulo 10; aquí solo vemos cómo se escriben.)

```text
$ touch programa programa-sgid
$ chmod 4755 programa
$ chmod 2755 programa-sgid
$ stat -c '%a %A %n' programa programa-sgid
4755 -rwsr-xr-x programa
2755 -rwxr-sr-x programa-sgid
$ mkdir publica
$ chmod 1777 publica
$ stat -c '%a %A %n' publica
1777 drwxrwxrwt publica
```

- `4755` → `rwsr-xr-x`: la **`s`** del dueño es el SUID.
- `2755` → `rwxr-sr-x`: la **`s`** del grupo es el SGID.
- `1777` → `rwxrwxrwt`: la **`t`** final es el sticky.

---

## 7.7 · Una sutileza muy de examen: ¿`chmod 755` quita los bits especiales?

Depende de **qué** sea el objeto. Lo verificamos:

```text
$ touch fichero-suid
$ chmod 4755 fichero-suid
$ stat -c 'fichero:  %a %A' fichero-suid
fichero:  4755 -rwsr-xr-x
$ chmod 755 fichero-suid
$ stat -c 'tras 755: %a %A' fichero-suid
tras 755: 755 -rwxr-xr-x
$ echo ---
---
$ mkdir carpeta-sgid
$ chmod 2775 carpeta-sgid
$ stat -c 'carpeta:  %a %A' carpeta-sgid
carpeta:  2775 drwxrwsr-x
$ chmod 755 carpeta-sgid
$ stat -c 'tras 755: %a %A' carpeta-sgid
tras 755: 2755 drwxr-sr-x
$ chmod 0755 carpeta-sgid
$ stat -c 'tras 0755: %a %A' carpeta-sgid
tras 0755: 2755 drwxr-sr-x
$ chmod 00755 carpeta-sgid
$ stat -c 'tras 00755: %a %A' carpeta-sgid
tras 00755: 755 drwxr-xr-x
```

La regla (la de **GNU `chmod`**):

| Objeto | `chmod 755` (3 cifras) | `chmod 0755` (4 cifras) | `chmod 00755` (5 cifras) | `chmod g-s` |
|---|:-:|:-:|:-:|:-:|
| **Fichero** con SUID/SGID | **los quita** | los quita | los quita | los quita |
| **Carpeta** con SUID/SGID | **los conserva** 😮 | **los conserva** | **los quita** | los quita |

Es decir: **en una carpeta, `chmod 755` NO le quita el SGID** (ni el SUID). Para quitarlo hay que usar `chmod g-s` o escribir el modo con **cinco** cifras (`00755`). Es una protección para que un `chmod` casual no rompa una carpeta de equipo.

---

## 7.8 · 📋 Recetas con números: ¿qué `chmod` poner?

| Qué es | Modo | Por qué |
|---|:-:|---|
| Fichero de texto / documento / configuración normal | **644** | todos leen, solo tú escribes |
| Script o programa que otros pueden ejecutar | **755** | todos leen y ejecutan |
| Carpeta normal | **755** | todos entran y listan |
| Fichero **privado** (notas, contraseñas, claves SSH privadas) | **600** | solo tú |
| Carpeta **privada** (`~/.ssh`, `~/privado`) | **700** | solo tú |
| Fichero de **configuración con secretos** | **640** o **600** | el grupo o nadie más |
| Documento **compartido en equipo** | **664** | dueño y grupo escriben |
| Carpeta **compartida en equipo** | **2775** (con SGID) | lo nuevo hereda el grupo (cap. 10) |
| Carpeta **pública con sticky** (`/tmp`) | **1777** | todos crean, cada uno borra lo suyo |
| Clave pública SSH (`~/.ssh/id_rsa.pub`) | **644** | se puede compartir |
| `~/.ssh/authorized_keys` | **600** | solo tú |

> ⚠️ **SSH es muy estricto:** si tu clave privada (`~/.ssh/id_rsa`) tiene permisos demasiado abiertos (digamos `644`), `ssh` **se niega a usarla** con *"WARNING: UNPROTECTED PRIVATE KEY FILE!"* y *"Permissions 0644 for 'id_rsa' are too open"*. La solución: `chmod 600 ~/.ssh/id_rsa` y `chmod 700 ~/.ssh`.

---

## 7.9 · 🏋️ Ejercicios

#### 🟢 Ejercicio 7.1 · Tres números

Deja `n1` en `644`, `n2` en `755` y `n3` en `600`. Comprueba con `stat`.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch n1 n2 n3
$ chmod 644 n1
$ chmod 755 n2
$ chmod 600 n3
$ stat -c '%a %A %n' n1 n2 n3
644 -rw-r--r-- n1
755 -rwxr-xr-x n2
600 -rw------- n3
```
</details>

#### 🟢 Ejercicio 7.2 · Un script ejecutable

Crea `s.sh` (un script) y déjalo **ejecutable por todos pero editable solo por ti**, con un solo número.

<details>
<summary>💡 Ver solución</summary>

```text
$ printf '#!/bin/bash\necho hola\n' > s.sh
$ chmod 755 s.sh
$ ./s.sh
hola
$ stat -c '%a %A' s.sh
755 -rwxr-xr-x
```
</details>

#### 🟢 Ejercicio 7.3 · Carpeta privada

Crea `mis-cosas` accesible **solo para ti** (con un número) y prueba con `ana`.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir mis-cosas
$ chmod 700 mis-cosas
$ sudo -u ana ls mis-cosas
ls: cannot open directory 'mis-cosas': Permission denied
```
</details>

#### 🟡 Ejercicio 7.4 · Del octal a las letras

Sin ejecutar: ¿qué permisos en letras tiene un fichero con `chmod 640`? ¿Y con `chmod 751`? Después compruébalo.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch q1 q2
$ chmod 640 q1; chmod 751 q2
$ stat -c '%a %A %n' q1 q2
640 -rw-r----- q1
751 -rwxr-x--x q2
```

`640` = `rw-r-----`; `751` = `rwxr-x--x`.
</details>

#### 🟡 Ejercicio 7.5 · El número que falta

Un fichero está en `644` y quieres **darle escritura al grupo** y **quitar toda lectura a otros**. ¿Qué número y qué `chmod` simbólico?

<details>
<summary>💡 Ver solución</summary>

`rw-` `rw-` `---` → **660**. En símbolos: `chmod g+w,o-r f`. Compruébalo:

```text
$ permisos 644 g+w,o-r | grep Octal
  Octal     660
```
</details>

#### 🟡 Ejercicio 7.6 · Calcular con bits

Sin usar `chmod`, calcula con aritmética qué sale al **quitar la `x` a todos** de un `755`, y al **añadir `w` al grupo** de un `644`.

<details>
<summary>💡 Ver solución</summary>

```text
$ printf '%o\n' $(( 8#755 & ~8#111 ))
644
$ printf '%o\n' $(( 8#644 | 8#020 ))
664
```

`755 → 644` y `644 → 664`.
</details>

#### 🔴 Ejercicio 7.7 · Publicar una web sin ejecutables accidentales

Con el árbol `web/` (carpetas, textos y un script `.sh`), deja: **carpetas `755`**, **textos `644`**, **scripts `.sh` `755`**, usando `find`.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir -p web/js web/img
$ echo "<html>" > web/index.html
$ echo "x=1" > web/js/app.js
$ echo "PNG" > web/img/logo.png
$ printf '#!/bin/bash\necho ok\n' > web/publicar.sh
$ chmod -R 700 web
$ find web -type d -exec chmod 755 {} +
$ find web -type f -name '*.sh' -exec chmod 755 {} +
$ find web -type f ! -name '*.sh' -exec chmod 644 {} +
$ find web | sort | xargs stat -c '%a %n'
755 web
755 web/img
644 web/img/logo.png
644 web/index.html
755 web/js
644 web/js/app.js
755 web/publicar.sh
```
</details>

#### 🔴 Ejercicio 7.8 · Lo mismo con un solo `chmod`

Consigue el mismo resultado que el ejercicio anterior (suponiendo que el script ya tuviera `x`) con **un único `chmod -R`**.

<details>
<summary>💡 Ver solución</summary>

```text
$ find web -type f -exec chmod 600 {} +
$ find web -type d -exec chmod 700 {} +
$ chmod 700 web/publicar.sh
$ chmod -R u=rwX,go=rX web
$ find web | sort | xargs stat -c '%a %n'
755 web
755 web/img
644 web/img/logo.png
644 web/index.html
755 web/js
644 web/js/app.js
755 web/publicar.sh
```

`X` pone `x` a las carpetas y al script (que ya la tenía), pero no a los textos.
</details>

#### 🔴 Ejercicio 7.9 · Detectar ejecutables que sobran

Tras un `chmod -R 755` descuidado, lista **solo los ficheros normales** que tengan `x` para el dueño y **no** terminen en `.sh`.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod -R 755 web
$ find web -type f -perm -u+x ! -name '*.sh'
web/img/logo.png
web/index.html
web/js/app.js
```

`-perm -u+x` = "con `x` para el dueño"; `!` niega la condición siguiente. (El apartado 10.7 explica `-perm` con detalle.)
</details>

#### 🔴 Ejercicio 7.10 · `chmod 755` sobre una carpeta con SGID

Tienes `equipo-dir` con `2775`. Haces `chmod 755 equipo-dir`. ¿Pierde el SGID? Si quieres quitárselo a propósito, ¿cómo?

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir equipo-dir
$ chmod 2775 equipo-dir
$ chmod 755 equipo-dir
$ stat -c '%a %A' equipo-dir
2755 drwxr-sr-x
$ chmod g-s equipo-dir
$ stat -c '%a %A' equipo-dir
755 drwxr-xr-x
```

**No lo pierde** (sigue `2755`). Para quitarlo: `chmod g-s` (o `chmod 00755`, con cinco cifras).
</details>

#### 🔴 Ejercicio 7.11 · El `chmod` con menos cifras de la cuenta

Un compañero escribe `chmod 75 informe.txt`. ¿Qué permisos deja? ¿Puede leerlo él?

<details>
<summary>💡 Ver solución</summary>

```text
$ touch informe.txt
$ chmod 75 informe.txt
$ stat -c '%a %A' informe.txt
75 ----rwxr-x
$ cat informe.txt
cat: informe.txt: Permission denied
```

`75` se lee como **`075`**: dueño `---`, grupo `rwx`, otros `r-x`. ¡El propio dueño no puede ni leerlo! Lección: **escribe siempre tres cifras**.
</details>

#### ⚫ Ejercicio 7.12 · Examen: leer el número

*¿Qué hace `chmod 4750 programa`?* a) SUID, dueño todo, grupo leer/ejecutar, otros nada b) SUID, dueño todo, grupo todo, otros nada c) SGID, dueño todo, grupo leer/ejecutar d) Sticky

<details>
<summary>💡 Ver solución</summary>

**a).** `4` = SUID; `7` = `rwx` dueño; `5` = `r-x` grupo; `0` = otros nada.

```text
$ permisos 4750 | grep -E 'Letras|SUID'
  Letras    rwsr-x---      (en ls -l: -rwsr-x---)
    · SUID (4)    se ejecuta con los privilegios del DUEÑO
```
</details>

#### ⚫ Ejercicio 7.13 · Examen: ¿cuál es válido?

*Elige el `chmod` **válido** para dejar un fichero `rw-r-----`:* a) `chmod 650 f` b) `chmod 640 f` c) `chmod 460 f` d) `chmod 064 f`

<details>
<summary>💡 Ver solución</summary>

**b).** `rw-` = 6, `r--` = 4, `---` = 0 → **640**.
</details>

#### ⚫ Ejercicio 7.14 · Examen: el `chmod -R`

*Quieres que todos los **directorios** de un árbol sean `755` y todos los **ficheros** `644`. ¿Cuál es la mejor solución?* a) `chmod -R 755 .` b) `chmod -R 644 .` c) `find . -type d -exec chmod 755 {} +` y `find . -type f -exec chmod 644 {} +` d) `chmod -R 777 .`

<details>
<summary>💡 Ver solución</summary>

**c).** `a)` hace ejecutables los ficheros; `b)` quita la `x` a las **carpetas** y ya no se puede entrar en ellas (¡pruébalo y luego arréglalo!); `d)` es un desastre de seguridad.
</details>

---

⬅️ [Capítulo 6 · `chmod` en modo simbólico: `u+x`, `go-w`, `a=r`…](06-chmod-simbolico.md) · [📚 Índice](README.md) · [Capítulo 8 · `umask`: por qué tus ficheros nuevos nacen con esos permisos](08-umask.md) ➡️
