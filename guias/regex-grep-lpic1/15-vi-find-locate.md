# Capítulo 15 · Regex fuera de `grep`: `less`, `vi`, `find`, `locate`

> 🎯 **Objetivo:** usar las expresiones regulares **en los demás programas** que las aceptan: buscar dentro de `less`/`man`, editar con `vi`, localizar ficheros con `find` y `locate`, y comprobar condiciones en `bash`.
>
> 📘 **LPIC-1:** 103.8 (editar con `vi`), 104.7 (buscar ficheros: `find`, `locate`, `updatedb`, `whereis`, `which`, `type`) y 103.7.
>
> 🧪 `cd ~/lab-regex` · El laboratorio trae una carpeta `arbol/` con ficheros de prueba para practicar `find`.

---

## 15.1 · Regex dentro de `less` y `man`

Cuando lees un fichero largo con `less` (o una página de `man`, que usa `less`), **la búsqueda acepta expresiones regulares**:

| Tecla | Hace |
|---|---|
| `/regex` + Enter | busca **hacia delante** |
| `?regex` + Enter | busca **hacia atrás** |
| `n` / `N` | siguiente / anterior coincidencia |
| `&regex` + Enter | **filtra**: muestra **solo** las líneas que coinciden (¡un `grep` dentro de `less`! vacía el filtro con `&` + Enter) |
| `-i` | alterna ignorar mayúsculas |
| `g` / `G` | principio / final |
| `q` | salir |

```bash
less /var/log/syslog        # dentro: /Failed|error   (+ Enter: busca "Failed" o "error")
less +/ssh /etc/services    # abre ya posicionado en la primera coincidencia de "ssh"
man grep                    # dentro: /^OPTIONS  ,  /-v  ,  /\<regexp\>
```

> 🧠 **¿Qué dialecto usa `less`?** Depende de cómo esté compilado. Lo hemos comprobado en Ubuntu 24.04 (`less 590`, *GNU regular expressions*) y acepta sintaxis **extendida**: `|`, `+`, `?`, `{n}` y `( )` **sin barras**, y además `\<`, `\>` y `\b`. En otros sistemas puede usar otra librería (POSIX o PCRE) con pequeñas diferencias. Si dudas, **pruébalo** con un patrón sencillo.

---

## 15.2 · `vi` / `vim` (LPIC 103.8)

`vi` es el editor que **siempre** está en cualquier Linux. Tiene **modos**:

| Modo | Cómo se entra | Para qué |
|---|---|---|
| **Normal** (al abrir) | `Esc` | moverte y dar órdenes |
| **Inserción** | `i` `a` `o` | escribir texto |
| **Última línea / ex** | `:` | órdenes como guardar, salir, **sustituir** |

Las imprescindibles del examen:

| Orden | Hace |
|---|---|
| `:w` · `:q` · `:wq` (o `ZZ`) · `:q!` | guardar · salir · guardar y salir · **salir sin guardar** |
| `i` · `a` · `o` · `Esc` | insertar · añadir · nueva línea · volver al modo normal |
| `dd` · `yy` · `p` · `u` · `x` | borrar línea · copiar línea · pegar · deshacer · borrar carácter |
| **`/regex`** · `?regex` · `n` · `N` | **buscar** adelante / atrás · siguiente / anterior |
| **`:s/viejo/nuevo/`** | sustituir en la **línea actual** |
| **`:%s/viejo/nuevo/g`** | sustituir en **todo el fichero** (`%` = todas las líneas, `g` = todas las veces) |
| `:%s/viejo/nuevo/gc` | igual, pero **preguntando** (`c` = confirmar) |
| `:3,7s/viejo/nuevo/g` | solo de la línea 3 a la 7 |
| **`:g/regex/d`** | **borra** todas las líneas que coinciden |
| `:v/regex/d` | borra todas las líneas que **NO** coinciden |
| `:set ic` · `:set nu` · `:set hls` | ignorar mayúsculas · numerar · resaltar búsquedas |

### La clave: **lo que escribes tras `:` es `sed`**

La orden `:%s/viejo/nuevo/g` de `vi` es **la misma** que `sed 's/viejo/nuevo/g'`. De hecho `vi` nació de un editor de línea llamado `ex`, y `sed` copió su sintaxis. Y la regex de `vi` es **BRE-like**: `\(…\)`, `\1`, `\<`, `\>`, `.`, `*`, `^`, `$`, `[…]`; los `\+ \? \|` se escriben con barra; `&` en el reemplazo = lo coincidido.

Para **demostrártelo sin abrir un editor interactivo**, podemos ejecutar esas mismas órdenes con **`ex -s`** (el modo "línea de comandos" de `vi`), que las lee de la entrada:

> 📦 `ex` viene con `vim`. Si tu Ubuntu es una instalación mínima y no lo tienes: `sudo apt install vim`.

```bash
cp palabras.txt p.txt
ex -s p.txt <<'EOF'
%s/^gato$/pez/
g/^[A-Z]/d
wq
EOF
grep -c . p.txt
grep -n 'pez' p.txt
```

_Resultado:_

```text
62
1:pez
61:pez
```


Esas dos órdenes (`%s/^gato$/pez/` y `g/^[A-Z]/d`) son lo que escribirías en `vi` tras `:`. La primera cambia las líneas que son exactamente `gato` por `pez` (las líneas 1 y 61 del **resultado**: como la segunda orden borra líneas, las demás suben de posición); la segunda **borra** todas las líneas que empiezan por mayúscula, así que el fichero queda más corto.

---

## 15.3 · `find`: buscar ficheros por nombre (con comodines o con regex)

`find` recorre un árbol de carpetas y **filtra ficheros** por nombre, tipo, tamaño, fecha, permisos… y puede ejecutar acciones sobre ellos.

```text
find  DÓNDE  CONDICIONES  ACCIÓN
```

### Por nombre: `-name` (**comodines**) vs `-regex` (**regex**)

| Opción | Usa | Mira… |
|---|---|---|
| `-name 'patrón'` | **comodines** (`*` `?` `[ ]`) | solo el **nombre** del fichero |
| `-iname 'patrón'` | comodines, **sin** distinguir mayúsculas | el nombre |
| `-regex 'regex'` | **expresión regular** | **toda la ruta** (¡anclada!) |
| `-iregex` | regex sin mayúsculas | toda la ruta |

```bash
find arbol -name '*.txt' | sort | head -5
```

_Resultado:_

```text
arbol/docs/.oculto.txt
arbol/docs/antiguo/viejo.txt
arbol/docs/notas.txt
arbol/informes/informe-2023-01.txt
arbol/informes/informe-2023-02.txt
```


Los comodines van **entre comillas** para que los interprete `find` y no la terminal (capítulo 2).

```bash
find arbol -iname '*.jpg' | sort
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/IMG_0003.JPG
```


`-iname` encuentra `IMG_0003.JPG` (con mayúsculas).

### ⚠️ `-regex` coincide con **TODA la ruta**

Con `grep`, la regex puede encajar en cualquier trozo. Con `find -regex` **tiene que encajar la ruta completa** (desde el principio hasta el final), así que casi siempre empieza con `.*`:

```bash
find arbol -regex '.*informe-2024-0[12]\.txt' | sort
```

_Resultado:_

```text
arbol/informes/informe-2024-01.txt
arbol/informes/informe-2024-02.txt
```


`.*` (el principio de la ruta, `arbol/informes/`) + el nombre. Sin ese `.*` no encontraría nada, porque la ruta empieza por `arbol/…`.

### El dialecto de `find -regex`: ni BRE ni ERE

Por defecto, `find -regex` usa la sintaxis **emacs**: `+` y `?` son operadores **sin barra**, los grupos y alternativas llevan barra (`\(…\)`, `\|`), y **no existen las llaves** `\{n,m\}`.

```bash
find arbol -regex '.*IMG_[0-9]+\..*' | sort
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/IMG_0003.JPG
```


`[0-9]+` funciona (el `+` es operador en emacs). Pero **las llaves no**:

```bash
find arbol -regex '.*IMG_[0-9]\{4\}\..*'
```

_Resultado:_

```text
(no sale nada)
```


No sale nada (¡sin error!): `\{4\}` no se interpreta como repetición. La solución: cambiar el **tipo de regex**:

```bash
find arbol -regextype posix-extended -regex '.*/IMG_[0-9]{4}\.(jpg|JPG)' | sort
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/IMG_0003.JPG
```


`-regextype posix-extended` = **ERE** (como `grep -E`). Otros tipos: `posix-basic` (BRE), `emacs` (por defecto), `grep`, `egrep`…

### Otras condiciones muy usadas

| Condición | Significa |
|---|---|
| `-type f` / `-type d` / `-type l` | solo ficheros / carpetas / enlaces simbólicos |
| `-maxdepth N` / `-mindepth N` | límites de profundidad |
| `-empty` | ficheros o carpetas **vacíos** |
| `-size +1M` / `-size -10k` | mayores de 1 MB / menores de 10 KB |
| `-mtime -7` / `-mmin -30` | modificados hace menos de 7 días / 30 minutos |
| `-newer fichero` | más recientes que ese fichero |
| `-perm -u+x` | con permiso de ejecución para el dueño |
| `-user ana` / `-group docentes` | del usuario / grupo |
| `-not` o `!` | **negación** |
| `-o` / `-a` | **O** / **Y** (entre paréntesis escapados: `\( … -o … \)`) |
| `-path 'patrón'` + `-prune` | **saltarse** carpetas |

### Las acciones

| Acción | Hace |
|---|---|
| (ninguna) / `-print` | escribe la ruta |
| `-print0` | las separa por `NUL` (para `xargs -0`) |
| `-exec CMD {} \;` | ejecuta `CMD` **una vez por fichero** |
| `-exec CMD {} +` | ejecuta `CMD` **una vez con todos** los ficheros |
| `-delete` | los borra (**¡cuidado!**) |

```bash
find arbol -type f -name '*.txt' -exec grep -l 'informe' {} +
```

_Resultado:_

```text
arbol/informes/informe-2024-01.txt
```


Los `.txt` que **contienen** la palabra "informe" (aquí solo el que escribimos al preparar el laboratorio). Esto es `find` + `grep`: **buscar por nombre y por contenido**.

```bash
find arbol -name '*.png' -print0 | xargs -0 ls -1
```

_Resultado:_

```text
arbol/fotos/captura de pantalla.png
arbol/fotos/foto-vacaciones.png
```


`-print0` + `xargs -0` manejan sin problemas los nombres con **espacios** (`captura de pantalla.png`).

---

## 15.4 · `locate` y los demás buscadores (LPIC 104.7)

`find` recorre el disco **en vivo** (lento pero siempre al día). **`locate`** consulta una **base de datos** (rápido, pero puede estar desactualizada):

| Comando | Qué hace |
|---|---|
| `locate nombre` | busca en la base de datos los ficheros cuyo nombre/ruta **contiene** `nombre` |
| `locate -i nombre` | sin distinguir mayúsculas |
| `locate -c nombre` | solo **cuenta** |
| `locate -b nombre` | solo en el **nombre base** (sin la ruta) |
| `locate -r 'regex'` (o `--regexp`) | **regex básica** |
| `locate --regex 'regex'` | **regex extendida** |
| `sudo updatedb` | **actualiza** la base de datos (la lanza `cron` a diario) |

```text
locate -r '/informe-2024-0[12]\.txt$'        # BRE; la regex va sobre la ruta completa
locate --regex '/informe-(2023|2024)-0[1-6]\.(txt|pdf)$'     # ERE
```

*(No se ejecutan en el laboratorio porque necesitan la base de datos de `updatedb`. En tu Ubuntu real, prueba `locate passwd`.)*

Y los buscadores de **programas** (104.7):

| Comando | Para qué | Ejemplo |
|---|---|---|
| `which prog` | ruta del ejecutable que se lanzaría (busca en `$PATH`) | `which grep` |
| `type prog` | si es **alias**, función, *builtin* o fichero | `type -a ls` |
| `whereis prog` | binario, **manual** y fuentes | `whereis grep` |

---

## 15.5 · Regex dentro de `bash`: `[[ … =~ … ]]`

`bash` entiende **ERE** en las comparaciones `[[ texto =~ regex ]]`. Y guarda lo capturado en el array **`BASH_REMATCH`** (`[0]` = todo, `[1]` = grupo 1…). La regex va **sin comillas**:

```bash
f="2024-10-14"
[[ $f =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]] && echo "año=${BASH_REMATCH[1]} mes=${BASH_REMATCH[2]} día=${BASH_REMATCH[3]}"
```

_Resultado:_

```text
año=2024 mes=10 día=14
```


```bash
[[ "hola" =~ ^[0-9]+$ ]] || echo "no es un número"
```

_Resultado:_

```text
no es un número
```


(Útil en scripts: validar entradas del usuario.)

---

## 15.6 · 🏋️ Ejercicios: `less` y `vi`

*(Los de `less` y `vi` interactivo se hacen en el teclado; las soluciones indican las teclas. Los de `ex` se ejecutan y comprueban aquí.)*

#### 🟢 Ejercicio 15.1 · Buscar en `man`

Abre el manual de `grep` y salta a la primera aparición de la opción `-v`. ¿Cómo pasas a la siguiente?

<details>
<summary>💡 Ver solución</summary>


```text
man grep
/-v        ← y Enter: salta a la primera coincidencia
n          ← siguiente coincidencia
N          ← anterior
q          ← salir
```
</details>


#### 🟢 Ejercicio 15.2 · Filtrar dentro de `less`

Abre `/var/log/syslog` con `less` y **muestra solo las líneas** que contienen `error` o `Failed`.

<details>
<summary>💡 Ver solución</summary>


```text
less /var/log/syslog
&error|Failed         ← y Enter (la alternativa se escribe con una barra vertical, sin barra invertida)
&                     ← y Enter: quita el filtro
q
```

`&regex` oculta todo lo que no coincide: un `grep` interactivo dentro de `less`.
</details>


#### 🟢 Ejercicio 15.3 · Salir de `vi`

Has abierto un fichero con `vi`, has escrito sin querer, y quieres **salir sin guardar**. ¿Qué escribes? ¿Y si quieres guardar y salir?

<details>
<summary>💡 Ver solución</summary>


```text
Esc         (por si estás en modo inserción)
:q!         ← salir SIN guardar
:wq         ← guardar y salir   (o ZZ)
```
</details>


#### 🟢 Ejercicio 15.4 · Sustituir en todo el fichero

En `vi`, ¿cómo cambias **todas** las apariciones de `gato` por `pez` en todo el fichero? Compruébalo con `ex`.

<details>
<summary>💡 Ver solución</summary>


```bash
cp palabras.txt p.txt
ex -s p.txt <<'EOF'
%s/gato/pez/g
wq
EOF
grep -n 'pez' p.txt
```

_Resultado:_

```text
1:pez
6:pezs
70:pez
```


En `vi` escribirías `:%s/gato/pez/g` y Enter. `%` = todas las líneas; `g` = todas las veces en cada línea.
</details>


#### 🟢 Ejercicio 15.5 · Borrar las líneas vacías

En `vi`, ¿cómo **borras todas las líneas vacías**? Compruébalo con `ex` sobre `conf-ejemplo.conf`.

<details>
<summary>💡 Ver solución</summary>


```bash
cp conf-ejemplo.conf c.conf
ex -s c.conf <<'EOF'
g/^$/d
wq
EOF
grep -c '^$' c.conf
```

_Resultado:_

```text
0
```


`:g/^$/d` = "en las líneas que coinciden con `^$`, aplica `d` (delete)". Quedan 0 líneas vacías (la de los 3 espacios no era vacía y sigue ahí).
</details>


#### 🟢 Ejercicio 15.6 · Borrar los comentarios

En `vi`, borra todas las líneas que **empiezan por `#`**.

<details>
<summary>💡 Ver solución</summary>


```bash
cp /etc/fstab f.txt
ex -s f.txt <<'EOF'
g/^#/d
wq
EOF
cat f.txt
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


`:g/^#/d`. Es el equivalente de `grep -v '^#'` o `sed '/^#/d'`.
</details>


#### 🟡 Ejercicio 15.7 · Dejar solo lo que coincide

En `vi`, **borra todas las líneas que NO** contienen un dígito. (Pista: `:v`.) Pruébalo con `ex` sobre `frases.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
cp frases.txt f.txt
ex -s f.txt <<'EOF'
v/[0-9]/d
wq
EOF
cat f.txt
```

_Resultado:_

```text
Hoy es lunes, 14 de octubre de 2024.
Tengo 3 gatos, 2 perros y 15 peces.
El número de teléfono es 612345678.
```


`:v/regex/d` (de *"inVerse"*) = borra las que **no** coinciden. Es `grep '[0-9]'`.
</details>


#### 🟡 Ejercicio 15.8 · Palabra completa

En `vi`, cambia la **palabra** `casa` (sin tocar `casas` ni `Casa`) por `CASA`, con `\<` y `\>`.

<details>
<summary>💡 Ver solución</summary>


```bash
cp palabras.txt p.txt
ex -s p.txt <<'EOF'
%s/\<casa\>/CASA/g
wq
EOF
grep -n 'CASA' p.txt
```

_Resultado:_

```text
11:CASA
71:CASA
```


`\<casa\>` = la palabra `casa` completa. (`casas` no encaja porque tras `casa` hay una `s` y no un límite de palabra.)
</details>


#### 🟡 Ejercicio 15.9 · Intercambiar dos palabras

En `vi`, cambia `Juan Flores` por `Flores Juan` con grupos (`\( \)` y `\1`, `\2`).

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'Juan Flores' > n.txt
ex -s n.txt <<'EOF'
%s/\(\w\+\) \(\w\+\)/\2 \1/
wq
EOF
cat n.txt
```

_Resultado:_

```text
Flores Juan
```


Las **mismas** BRE que en `sed`: los paréntesis y el `\+` llevan barra.
</details>


#### 🟡 Ejercicio 15.10 · El `+` en vi

En `vi`, el `+` **no** es "uno o más" a menos que lleve barra. Demuéstralo con las líneas `a+b` y `aab`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a+b\naab\n' > m.txt
ex -s m.txt <<'EOF'
%s/a+b/X/
%s/a\+b/Y/
wq
EOF
cat m.txt
```

_Resultado:_

```text
X
Y
```


`a+b` (sin barra) sustituyó la línea con un `+` **literal**; `a\+b` (con barra) la que tiene "una o más `a`" y después una `b`. Exactamente igual que en BRE (capítulo 8).
</details>


#### 🟡 Ejercicio 15.11 · Sustituir con confirmación

En `vi`, quieres cambiar `error` por `ERROR` pero **revisando cada cambio**. ¿Cómo?

<details>
<summary>💡 Ver solución</summary>


```text
:%s/error/ERROR/gc
```

Con la bandera `c` (*confirm*), `vi` pregunta en cada coincidencia: `y` (sí), `n` (no), `a` (todas las que quedan), `q` (salir), `l` (esta y salir).
</details>


#### 🟡 Ejercicio 15.12 · Solo un rango de líneas

En `vi`, cambia `a` por `A` **solo entre las líneas 3 y 5**.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a\na\na\na\na\na\n' > r.txt
ex -s r.txt <<'EOF'
3,5s/a/A/
wq
EOF
cat r.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
a a A A A a 
```


`3,5s/a/A/` = "en las líneas 3 a 5". (Es la misma sintaxis de direcciones que en `sed`.)
</details>


---

## 15.7 · 🏋️ Ejercicios: `find`

#### 🟢 Ejercicio 15.13 · Por extensión

Lista **todos los `.txt`** del árbol `arbol/` (ordenados).

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -name '*.txt' | sort
```

_Resultado:_

```text
arbol/docs/.oculto.txt
arbol/docs/antiguo/viejo.txt
arbol/docs/notas.txt
arbol/informes/informe-2023-01.txt
arbol/informes/informe-2023-02.txt
arbol/informes/informe-2024-01.txt
arbol/informes/informe-2024-02.txt
arbol/vacio.txt
```

</details>


#### 🟢 Ejercicio 15.14 · Sin mayúsculas

Lista las fotos `.jpg` de `arbol/` **sin importar mayúsculas** (`.jpg` y `.JPG`).

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -iname '*.jpg' | sort
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/IMG_0003.JPG
```

</details>


#### 🟢 Ejercicio 15.15 · Solo carpetas

Lista las **carpetas** de `arbol/`, solo el primer nivel.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -maxdepth 1 -type d | sort
```

_Resultado:_

```text
arbol
arbol/copias
arbol/docs
arbol/fotos
arbol/informes
arbol/proyecto
arbol/scripts
arbol/tmp
```


`-maxdepth 1` = solo `arbol` y sus hijos directos.
</details>


#### 🟢 Ejercicio 15.16 · Los ficheros vacíos

Cuenta los **ficheros vacíos** (0 bytes) de `arbol/`.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f -empty | wc -l
```

_Resultado:_

```text
30
```

</details>


#### 🟢 Ejercicio 15.17 · Los que no están vacíos

Lista los ficheros de `arbol/` que **sí** tienen contenido.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f -size +0 | sort
```

_Resultado:_

```text
arbol/docs/notas.txt
arbol/informes/informe-2024-01.txt
```


`-size +0` = más de 0 bloques. (Solo `notas.txt` e `informe-2024-01.txt` tienen texto.)
</details>


#### 🟢 Ejercicio 15.18 · Los ejecutables

Lista los ficheros de `arbol/` con **permiso de ejecución** para el dueño.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f -perm -u+x | sort
```

_Resultado:_

```text
arbol/scripts/backup.sh
arbol/scripts/deploy.sh
arbol/scripts/limpiar.py
```

</details>


#### 🟡 Ejercicio 15.19 · Todo menos los `.txt`

Lista los ficheros de `arbol/` que **no** acaban en `.txt` (las 5 primeras líneas).

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f -not -name '*.txt' | sort | head -5
```

_Resultado:_

```text
arbol/copias/backup-2024-10-01.zip
arbol/copias/datos.tar.bz2
arbol/copias/datos.tar.gz
arbol/docs/README.md
arbol/docs/antiguo/viejo.txt.bak
```

</details>


#### 🟡 Ejercicio 15.20 · Dos extensiones

Lista los ficheros `.jpg` **o** `.png` de `arbol/`.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f \( -name '*.jpg' -o -name '*.png' \) | sort
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/captura de pantalla.png
arbol/fotos/foto-vacaciones.png
```


Los paréntesis se **escapan** (`\(` `\)`) para que la terminal no los interprete, y `-o` es "O".
</details>


#### 🟡 Ejercicio 15.21 · Regex sobre la ruta

Lista los informes `informe-2024-01.txt` y `informe-2024-02.txt` con **`-regex`** (un solo patrón).

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -regex '.*informe-2024-0[12]\.txt' | sort
```

_Resultado:_

```text
arbol/informes/informe-2024-01.txt
arbol/informes/informe-2024-02.txt
```


`.*` al principio porque `-regex` ha de encajar **toda la ruta**.
</details>


#### 🟡 Ejercicio 15.22 · Regex extendida con alternativas

Lista los `informe-AAAA-MM` de **2023 o 2024**, meses 01 a 02, con extensión `.txt` o `.pdf`, usando regex **extendida**.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -regextype posix-extended -regex '.*/informe-(2023|2024)-0[12]\.(txt|pdf)' | sort
```

_Resultado:_

```text
arbol/informes/informe-2023-01.txt
arbol/informes/informe-2023-02.txt
arbol/informes/informe-2024-01.txt
arbol/informes/informe-2024-02.pdf
arbol/informes/informe-2024-02.txt
```


`-regextype posix-extended` activa las alternativas `( | )` sin barras.
</details>


#### 🟡 Ejercicio 15.23 · Las llaves en find

Lista las fotos `IMG_####.jpg|JPG` con **exactamente 4 dígitos** usando `{4}`. ¿Por qué falla con `\{4\}` en el tipo por defecto?

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -regextype posix-extended -regex '.*/IMG_[0-9]{4}\.(jpg|JPG)' | sort
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/IMG_0003.JPG
```


El tipo por defecto (`emacs`) **no admite llaves**; hay que pedir `posix-extended` (o `posix-basic` con `\{4\}`). Con `emacs` puedes escribir `[0-9]+`, pero no `{4}`.
</details>


#### 🟡 Ejercicio 15.24 · Por contenido y por nombre

Lista los ficheros `.txt` de `arbol/` **que contengan** la palabra `informe` (busca por nombre con `find` y por contenido con `grep`).

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f -name '*.txt' -exec grep -l informe {} +
```

_Resultado:_

```text
arbol/informes/informe-2024-01.txt
```


`-exec grep -l informe {} +` ejecuta `grep` una vez con todos los `.txt` encontrados (`{}` = la lista de ficheros).
</details>


#### 🟡 Ejercicio 15.25 · Nombres con espacios

Lista, uno por línea y con `ls -1`, los `.png` de `arbol/fotos`, incluyendo el que tiene **espacios** en el nombre.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol/fotos -name '*.png' -print0 | xargs -0 ls -1
```

_Resultado:_

```text
arbol/fotos/captura de pantalla.png
arbol/fotos/foto-vacaciones.png
```


`-print0` separa con `NUL` y `xargs -0` lo respeta: el nombre `captura de pantalla.png` llega **entero**. Sin `-print0`/`-0`, `xargs` lo partiría en tres.
</details>


#### 🟡 Ejercicio 15.26 · Los ficheros ocultos

Lista los **ficheros ocultos** (nombre que empieza por punto) de `arbol/`.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f -name '.*'
```

_Resultado:_

```text
arbol/tmp/.fichero.swp
arbol/docs/.oculto.txt
```

</details>


#### 🔴 Ejercicio 15.27 · Saltarse una carpeta

Lista los ficheros con extensión de `arbol/` **sin entrar en `arbol/copias`**.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -path arbol/copias -prune -o -type f -name '*.*' -print | sort | head -5
```

_Resultado:_

```text
arbol/docs/.oculto.txt
arbol/docs/README.md
arbol/docs/antiguo/viejo.txt
arbol/docs/antiguo/viejo.txt.bak
arbol/docs/manual.pdf
```


`-path … -prune` evita entrar; `-o … -print` dice "si no, imprime". (Sin el `-print` final, `find` también imprimiría la carpeta podada.)
</details>


#### 🔴 Ejercicio 15.28 · `find` más `grep` sobre los nombres

Lista los ficheros de `arbol/` cuyo **nombre** (solo el nombre, no la ruta) empieza por `informe-2024`, usando `find` y una regex de `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol -type f | grep -E '/informe-2024[^/]*$' | sort
```

_Resultado:_

```text
arbol/informes/informe-2024-01.txt
arbol/informes/informe-2024-02.pdf
arbol/informes/informe-2024-02.txt
```


`/informe-2024[^/]*$` = una `/`, `informe-2024`, y luego **sin más barras** hasta el final: así el filtro actúa solo sobre el **último componente** de la ruta (el nombre del fichero).
</details>


#### 🔴 Ejercicio 15.29 · Nombres que cumplen un patrón y contenido

Lista los ficheros `.sh` de `arbol/scripts` y muestra cuáles son **ejecutables**, con `-perm`.

<details>
<summary>💡 Ver solución</summary>


```bash
find arbol/scripts -name '*.sh' -perm -u+x | sort
```

_Resultado:_

```text
arbol/scripts/backup.sh
arbol/scripts/deploy.sh
```

</details>


---

## 15.8 · 🏋️ Ejercicios: `locate`, `which`, `bash`

#### 🟢 Ejercicio 15.30 · `locate` con regex

Escribe (sin ejecutarlo) la orden de `locate` que muestre las rutas que **acaben en `.conf`**, con regex **básica**, y otra con regex **extendida**.

<details>
<summary>💡 Ver solución</summary>


```text
locate -r '\.conf$'
locate --regex '\.conf$'
```

`-r` = regex básica (BRE); `--regex` = extendida (ERE). Como `locate` mira la **ruta completa**, el `$` ancla el final.
</details>


#### 🟢 Ejercicio 15.31 · Actualizar la base de datos

Acabas de crear un fichero y `locate` no lo encuentra. ¿Qué haces?

<details>
<summary>💡 Ver solución</summary>


```text
sudo updatedb
locate nombre-del-fichero
```

`locate` usa una base de datos que se actualiza con `updatedb` (normalmente una vez al día, por `cron`). `find` no tiene ese problema porque mira el disco en vivo.
</details>


#### 🟢 Ejercicio 15.32 · Dónde está `grep`

Explica la diferencia entre `which grep`, `type grep` y `whereis grep`.

<details>
<summary>💡 Ver solución</summary>


```text
which grep      →  /usr/bin/grep                          (el ejecutable que se lanzaría)
type grep       →  grep is aliased to `grep --color=auto'  (alias, función, builtin o fichero)
whereis grep    →  grep: /usr/bin/grep /usr/share/man/man1/grep.1.gz   (binario + manual)
```

`type` es de la shell y conoce **alias y funciones**; `which` solo mira `$PATH`; `whereis` también localiza el **manual**.
</details>


#### 🟡 Ejercicio 15.33 · Validar una fecha en `bash`

Con `[[ … =~ … ]]`, comprueba si `2024-10-14` tiene formato `AAAA-MM-DD` y **muestra solo el mes** (grupo 2).

<details>
<summary>💡 Ver solución</summary>


```bash
f="2024-10-14"
[[ $f =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]] && echo "mes=${BASH_REMATCH[2]}"
```

_Resultado:_

```text
mes=10
```


Los grupos entre paréntesis quedan en `BASH_REMATCH`. La regex es **ERE** y **no lleva comillas**.
</details>


#### 🟡 Ejercicio 15.34 · Validar un número en `bash`

Escribe una orden que diga `número` si `$x` son solo dígitos y `no es un número` en otro caso, para `x=42` y `x=4a`.

<details>
<summary>💡 Ver solución</summary>


```bash
for x in 42 4a; do
  if [[ $x =~ ^[0-9]+$ ]]; then echo "$x: número"; else echo "$x: no es un número"; fi
done
```

_Resultado:_

```text
42: número
4a: no es un número
```

</details>


---

## ✅ Resumen del capítulo 15

| Programa | Regex | Notas |
|---|---|---|
| `less`, `man` | `/regex` · `?regex` · `&regex` | en Ubuntu, sintaxis **extendida** (`\|`, `+`, `?`, `( )`) |
| `vi` | `/regex` · `:%s/…/…/g` · `:g/…/d` · `:v/…/d` | BRE-like; el `:` es `ex` ≡ `sed` |
| `find -name` | **comodines** (no regex) | solo el nombre |
| `find -regex` | **regex sobre toda la ruta** | tipo `emacs` por defecto; `-regextype posix-extended` = ERE |
| `locate -r` / `--regex` | BRE / ERE | usa la base de datos de `updatedb` |
| `bash [[ =~ ]]` | **ERE** sin comillas; resultados en `BASH_REMATCH` | |

**LPIC-1 104.7:** `find`, `locate`, `updatedb`, `whereis`, `which`, `type`.

➡️ **Siguiente parada:** [Capítulo 16](16-retos-finales.md): **el jefe final** 🏆 con retos mixtos y un mini-examen tipo test.

---
⬅️ [Capítulo 14 · `sed` y los filtros de texto: `cut`, `sort`, `uniq`, `tr`, `wc`…](14-sed-y-filtros.md) · 🏠 [Índice](README.md) · [Capítulo 16 · 🏆 El jefe final: misiones, retos y mini-examen](16-retos-finales.md) ➡️
