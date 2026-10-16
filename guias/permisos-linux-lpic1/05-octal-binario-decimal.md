# Capítulo 5 · Octal, binario, decimal y letras: entender 755, 644 o 4755 de un vistazo

> 🎯 **Objetivo:** que **`755`**, **`644`**, **`4755`** y **`rwxr-xr-x`** dejen de ser códigos y pasen a ser la **misma cosa escrita de cuatro maneras**. Convertir entre octal, letras, binario, decimal y hexadecimal **de cabeza y rápido**.
>
> 📘 **LPIC-1:** 104.5 (`chmod` en modo octal) · 103.1.
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`. Además vamos a usar la herramienta **`permisos`** de este repositorio (se instala en el apartado 5.9).

---

## 5.1 · La idea en una frase

> **Cada trozo `rwx` son 3 interruptores (encendido/apagado). Tres interruptores = un número del 0 al 7. Tres trozos = tres cifras.**

Y eso es *todo*. `755` no es un número mágico: son **tres cifras** (dueño, grupo, otros) y cada cifra **resume** un trozo `rwx`.

```text
        dueño   grupo   otros
         rwx     r-x     r-x
          7       5       5       →   755
```

¿Por qué se usa el sistema **octal** (base 8, cifras 0-7)? Porque con **3 interruptores** hay exactamente **2³ = 8** combinaciones posibles: del 0 al 7. **Una cifra octal = un trozo `rwx`.** No es casualidad: se eligió justo por eso.

---

## 5.2 · El valor de cada letra: **4, 2, 1**

A cada interruptor se le asigna un **peso**:

```text
            r     w     x
peso:       4     2     1
binario:  100   010   001
```

Para sacar la cifra de un trozo, **suma los pesos de las letras que están encendidas** (las que no son raya):

```text
 r - x   →   4 + 0 + 1 = 5
 r w -   →   4 + 2 + 0 = 6
 r w x   →   4 + 2 + 1 = 7
 - - -   →   0 + 0 + 0 = 0
```

Los 8 casos posibles, completos:

| Cifra | Binario (`r w x`) | Letras | Se suma | Significa |
|:-:|:-:|:-:|:-:|---|
| **0** | `000` | `---` | 0 | nada |
| **1** | `001` | `--x` | 1 | ejecutar |
| **2** | `010` | `-w-` | 2 | escribir |
| **3** | `011` | `-wx` | 2 + 1 | escribir + ejecutar |
| **4** | `100` | `r--` | 4 | leer |
| **5** | `101` | `r-x` | 4 + 1 | leer + ejecutar |
| **6** | `110` | `rw-` | 4 + 2 | leer + escribir |
| **7** | `111` | `rwx` | 4 + 2 + 1 | todo (leer + escribir + ejecutar) |

> 🧠 **Memoriza solo estos cinco** y habrás aprendido el 95 %:
>
> | **7** | **6** | **5** | **4** | **0** |
> |:-:|:-:|:-:|:-:|:-:|
> | `rwx` todo | `rw-` leer y escribir | `r-x` leer y ejecutar | `r--` solo leer | `---` nada |
>
> (Los otros tres — `3`, `2`, `1` — son raros: escribir sin leer, o ejecutar sin leer.)

---

## 5.3 · De **letras a número** (receta de 3 pasos)

Tomamos `-rwxr-xr-x` (el típico de un programa):

1. **Quita el primer carácter** (el tipo): `rwxr-xr-x`.
2. **Corta de 3 en 3**: `rwx` · `r-x` · `r-x`.
3. **Suma los pesos de cada trozo** (4 la `r`, 2 la `w`, 1 la `x`): `4+2+1` · `4+0+1` · `4+0+1` = **7 · 5 · 5**.

→ **`755`**.

Ahora tú, con los de tu captura (los tienes resueltos, tápalos y comprueba):

| `ls -l` | Trozos | Cuentas | Octal |
|---|---|---|:-:|
| `-rwxr-x--x` (`saludos.sh`) | `rwx` `r-x` `--x` | 7 · 5 · 1 | **751** |
| `-rwxrwxr-x` (`salario.sh`, `cerve.sh`) | `rwx` `rwx` `r-x` | 7 · 7 · 5 | **775** |
| `-rw-r-----` (`/etc/shadow`) | `rw-` `r--` `---` | 6 · 4 · 0 | **640** |
| `-rw-r--r--` (`/etc/passwd`) | `rw-` `r--` `r--` | 6 · 4 · 4 | **644** |
| `drwxrwxrwt` (`/tmp`) | `rwx` `rwx` `rwt` | **1** · 7 · 7 · 7 | **1777** |
| `drwx-wx--T` (`crontabs`) | `rwx` `-wx` `--T` | **1** · 7 · 3 · 0 | **1730** |

(Las dos últimas llevan **cuatro cifras** por el bit *sticky*: se explica en el apartado 5.11 y en el capítulo 10.)

Compruébalo **con el sistema** (no te fíes de mí): `stat -c '%a'` imprime el octal.

```text
$ stat -c '%a  %A  %n' saludos.sh salario.sh cerve.sh /etc/shadow /etc/passwd /tmp
751  -rwxr-x--x  saludos.sh
775  -rwxrwxr-x  salario.sh
775  -rwxrwxr-x  cerve.sh
640  -rw-r-----  /etc/shadow
644  -rw-r--r--  /etc/passwd
1777  drwxrwxrwt  /tmp
```

---

## 5.4 · De **número a letras** (receta de 3 pasos)

Tomamos `640`:

1. **Separa las cifras**: `6` `4` `0`.
2. **Cada cifra → su trozo** (con la tabla de arriba, o restando: `6 = 4+2 = rw-`): `rw-` `r--` `---`.
3. **Júntalos** y pon delante el tipo (`-` si es fichero): `-rw-r-----`.

Para **adivinar el trozo de una cifra** sin tabla, pregúntate de arriba abajo:

```text
¿la cifra es ≥ 4?  → sí: pon "r" y réstale 4 · no: pon "-"
¿lo que queda es ≥ 2?  → sí: pon "w" y réstale 2 · no: pon "-"
¿lo que queda es ≥ 1?  → sí: pon "x" · no: pon "-"
```

Ejemplo con el **5**: `5 ≥ 4` → `r` (queda 1) · `1 < 2` → `-` · `1 ≥ 1` → `x` → **`r-x`**. ✔

---

## 5.5 · Atajos mentales para ir **rápido**

| Atajo | Ejemplo |
|---|---|
| **Los tres dígitos son siempre `dueño-grupo-otros`** | `750` → dueño todo, grupo lee y entra, otros nada |
| **`7` = todo; resta lo que falte** | `7 − 2 = 5` → falta la `w` → `r-x` |
| **Pares y trozos "pegados":** `6` = `r` + `w`; `5` = `r` + `x`; `3` = `w` + `x` | |
| **El `4` solo lee; el `2` solo escribe; el `1` solo ejecuta** | `644` = dueño lee y escribe (6), los demás **solo leen** (4) |
| **Los números "bonitos" que debes reconocer sin pensar** | `644` `755` `600` `700` `640` `750` `664` `775` `777` |
| **Un `x` sin `r` es raro:** si ves `1`, `3` o `2` en un script, sospecha | `--x` en un script no sirve (capítulo 2) |
| **Más cifra = más abierto** | `600` < `640` < `644` < `664` < `666` |

> 🏃 **Entrenamiento:** coge cualquier fichero de tu laboratorio, adivina su `chmod` en octal y comprueba con `stat -c '%a %n'`. En una semana lo harás sin pensar.

---

## 5.6 · El **binario**: cada letra es un interruptor

Un permiso son **9 interruptores** (3 trozos × 3). Cada letra presente es un `1` y cada raya es un `0`. Mira `rwxr-xr-x`:

```text
letras:    r w x   r - x   r - x
binario:   1 1 1   1 0 1   1 0 1      =  111 101 101
octal:      7       5       5         =  755
```

**Conversión directa, sin sumar:** letra = `1`, raya = `0`, y cada grupo de 3 bits **es** una cifra octal (porque 3 bits = 0…7).

| Letras | Binario | Octal |
|---|---|:-:|
| `rwx` | `111` | 7 |
| `r-x` | `101` | 5 |
| `r--` | `100` | 4 |
| `-w-` | `010` | 2 |
| `---` | `000` | 0 |

### Convertir binario ↔ octal ↔ letras

Si te dan `110100100`:

```text
110 100 100      ← agrupa de 3 en 3, empezando por la DERECHA
 6   4   4       ← cada grupo a decimal (4+2, 4, 4)     →  644
rw- r-- r--      ← o directamente: 1=letra, 0=raya
```

---

## 5.7 · El **decimal**: por qué *no* es "755" (y cuándo lo vas a ver)

Aquí viene la trampa. Si el número `755` lo lees **en base 10** (como siempre), vale *setecientos cincuenta y cinco*. Pero **en octal** (base 8) `755` es:

```text
7×8² + 5×8¹ + 5×8⁰  =  7×64 + 5×8 + 5  =  448 + 40 + 5  =  493 (en decimal)
```

O sea: **`755` (octal) = `493` (decimal)** y `chmod` **siempre** espera **octal**.

Lo comprobamos con la terminal (tres formas de convertir):

```text
$ echo $(( 8#755 ))
493
$ printf '%d\n' 0755
493
$ printf '%o\n' 493
755
$ echo "obase=8; 493" | bc
755
$ echo "obase=2; 493" | bc
111101101
$ echo $(( 2#111101101 ))
493
$ printf '%o\n' $(( 2#111101101 ))
755
```

| Quiero… | Truco |
|---|---|
| octal → decimal | `echo $(( 8#755 ))` o `printf '%d\n' 0755` |
| decimal → octal | `printf '%o\n' 493` |
| binario → octal | `printf '%o\n' $(( 2#111101101 ))` |
| decimal → binario | `echo "obase=2; 493" \| bc` |
| octal → binario | `echo "obase=2; $(( 8#755 ))" \| bc` |
| hexadecimal → octal | `printf '%o\n' 0x1ed` |

> ⚠️ En `bc`, **pon `obase` antes que `ibase`** si cambias los dos (`obase=8; ibase=2; 111101101`), porque una vez cambiada la base de entrada, el `8` ya no se lee como *ocho*.

### ❌ `chmod 493` no existe

```text
$ touch decimal.txt
$ chmod 493 decimal.txt
chmod: invalid mode: ‘493’
Try 'chmod --help' for more information.
$ chmod 755 decimal.txt
$ ls -l decimal.txt
-rwxr-xr-x 1 alumno alumno 0 Oct 16 17:09 decimal.txt
```

`493` no es un octal válido (¡tiene un 9!), por eso `chmod` protesta. **`chmod` solo entiende octal (o letras)**: si escribes `644`, lo lee como octal aunque tú pensaras en decimal.

### 💣 La trampa de los lenguajes de programación

En muchos lenguajes, una función como `os.chmod(fichero, modo)` espera un **número**. Si escribes `755` a secas, el lenguaje lo lee como **decimal** (755 = `1363` en octal), ¡y el fichero queda con unos permisos absurdos!

```text
$ touch trampa.txt
$ python3 -c "import os; os.chmod('trampa.txt', 755)"
$ ls -l trampa.txt
--wxrw--wt 1 alumno alumno 0 Oct 16 17:09 trampa.txt
$ stat -c '%a' trampa.txt
1363
$ python3 -c "import os; os.chmod('trampa.txt', 0o755)"
$ ls -l trampa.txt
-rwxr-xr-x 1 alumno alumno 0 Oct 16 17:09 trampa.txt
```

La primera vez quedó `--wxrw--wt` (¡ni siquiera puedes leerlo!). La forma correcta en Python es **`0o755`** (el prefijo `0o` dice "esto es octal"). En Bash y C sirve con un **0 delante** (`0755`). Es un fallo clásico: *"`chmod(path, 755)` me ha dejado el fichero roto"*.

| Prefijo | Base | Ejemplo | Vale |
|---|---|---|---|
| (nada) | decimal | `755` | setecientos cincuenta y cinco |
| `0` / `0o` | **octal** | `0755` / `0o755` | 493 |
| `0b` | binario | `0b111101101` | 493 |
| `0x` | hexadecimal | `0x1ed` | 493 |

---

## 5.8 · Una vuelta de tuerca: el modo "entero" y los tipos de fichero

Cuando un programa pide el modo **completo** de un fichero (como hace `stat`), el número incluye también **qué clase de cosa es** el fichero, en las cifras de más a la izquierda. Se ve con `%f`, que imprime el modo en **hexadecimal**:

```text
$ ln -s datos/notas.txt enlace
$ stat -c '%f  %n' cerve.sh datos /dev/null enlace
81fd  cerve.sh
41ed  datos
21b6  /dev/null
a1ff  enlace
$ printf '%o\n' 0x81fd
100775
$ printf '%o\n' 0x41ed
40755
```

`0x81fd` es `100775` en octal: las **tres cifras de la derecha son los permisos** (`775`) y el `100` de delante es el tipo (**fichero normal**). Del mismo modo, `0x41ed` es `40755`: `040` = **directorio** y `755` = los permisos de `datos`. Esta es la tabla de tipos:

| Octal (parte izquierda) | Tipo | `ls -l` |
|:-:|---|:-:|
| `100…` | fichero normal | `-` |
| `040…` | directorio | `d` |
| `120…` | enlace simbólico | `l` |
| `020…` | dispositivo de caracteres | `c` |
| `060…` | dispositivo de bloques | `b` |
| `010…` | tubería con nombre | `p` |
| `140…` | socket | `s` |

(Con `chmod` **nunca** tocas esa parte: es el *tipo*, fijo desde que se crea.)

---

## 5.9 · 🛠️ La herramienta `permisos`: tu calculadora de bolsillo

En este repositorio hay un pequeño programa (un script de Bash, sin dependencias) que **traduce** permisos entre todas las representaciones. Instálalo así:

```bash
# Opción A: para todos los usuarios
sudo install -m 755 ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/herramientas/permisos /usr/local/bin/permisos

# Opción B: solo para ti (sin sudo)
mkdir -p ~/bin
install -m 755 ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/herramientas/permisos ~/bin/permisos
# (en Ubuntu, ~/bin entra en el PATH al volver a abrir la terminal)
```

Se le puede dar **casi cualquier cosa**:

```text
$ permisos 755
755

  Octal     755
  Letras    rwxr-xr-x      (en ls -l: -rwxr-xr-x)
  Binario   111 101 101
  Decimal   493
  Hex       0x1ed

  dueño   rwx  (7)  leer, escribir, ejecutar
  grupo   r-x  (5)  leer, ejecutar
  otros   r-x  (5)  leer, ejecutar

  chmod 755 FICHERO
  chmod u=rwx,g=rx,o=rx FICHERO
```

```bash
for x in rwxr-xr-x -rwxr-xr-x 0b111101101 d:493 0x1ed; do
  printf '%-14s → ' "$x"; permisos "$x" | grep Octal
done
```

_Resultado:_

```text
rwxr-xr-x      →   Octal     755
-rwxr-xr-x     →   Octal     755
0b111101101    →   Octal     755
d:493          →   Octal     755
0x1ed          →   Octal     755
```

(Las cinco entradas dan el mismo `755`: son **cinco formas de escribir lo mismo**: letras, línea de `ls -l`, binario, decimal y hexadecimal.) También lee los **ficheros reales** y entiende las expresiones de `chmod`:

```text
$ permisos saludos.sh
regular file: saludos.sh   (dueño alumno, grupo alumno)

  Octal     751
  Letras    rwxr-x--x      (en ls -l: -rwxr-x--x)
  Binario   111 101 001
  Decimal   489
  Hex       0x1e9

  dueño   rwx  (7)  leer, escribir, ejecutar
  grupo   r-x  (5)  leer, ejecutar
  otros   --x  (1)  ejecutar

  chmod 751 FICHERO
  chmod u=rwx,g=rx,o=x FICHERO
$ permisos 644 g+w,o-r
Base 644  +  chmod g+w,o-r

Resultado:

  Octal     660
  Letras    rw-rw----      (en ls -l: -rw-rw----)
  Binario   110 110 000
  Decimal   432
  Hex       0x1b0

  dueño   rw-  (6)  leer, escribir
  grupo   rw-  (6)  leer, escribir
  otros   ---  (0)  nada

  chmod 660 FICHERO
  chmod u=rw,g=rw,o= FICHERO
$ permisos u=rwx,go=rx
chmod u=rwx,go=rx   aplicado a 000

Resultado:

  Octal     755
  Letras    rwxr-xr-x      (en ls -l: -rwxr-xr-x)
  Binario   111 101 101
  Decimal   493
  Hex       0x1ed

  dueño   rwx  (7)  leer, escribir, ejecutar
  grupo   r-x  (5)  leer, ejecutar
  otros   r-x  (5)  leer, ejecutar

  chmod 755 FICHERO
  chmod u=rwx,g=rx,o=rx FICHERO
```

Y los modos de 4 cifras (los verás a fondo en el capítulo 10):

```text
$ permisos 4755
4755

  Octal     4755
  Letras    rwsr-xr-x      (en ls -l: -rwsr-xr-x)
  Binario   100 111 101 101      (3 bits especiales + 3 × 3)
  Decimal   2541
  Hex       0x9ed

  dueño   rws  (7)  leer, escribir, ejecutar
  grupo   r-x  (5)  leer, ejecutar
  otros   r-x  (5)  leer, ejecutar

  Bits especiales:
    · SUID (4)    se ejecuta con los privilegios del DUEÑO

  chmod 4755 FICHERO
  chmod u=rwx,g=rx,o=rx,u+s FICHERO
```

> 🧪 Úsala para **comprobar tus propias conversiones**, no para sustituirlas: el examen LPIC-1 es sin ordenador.
>
> 🌐 También hay una **calculadora visual** en `herramientas/calculadora-chmod.html` (ábrela en el navegador: casillas para marcar `r`/`w`/`x` y ver el octal al instante).

---

## 5.10 · 📋 Los modos que debes reconocer al instante

| Octal | Letras | Para qué se usa |
|:-:|:-:|---|
| `000` | `---------` | nada para nadie (carpeta/fichero "cerrado") |
| `400` | `r--------` | solo lectura, solo el dueño (claves privadas muy protegidas) |
| `440` | `r--r-----` | solo lectura para dueño y grupo (`/etc/sudoers`: `-r--r-----`) |
| `444` | `r--r--r--` | solo lectura para todos |
| `600` | `rw-------` | **privado**: lee y escribe solo el dueño (clave SSH privada, `secreto.txt`) |
| `640` | `rw-r-----` | el dueño edita, el grupo lee (`/etc/shadow`, logs) |
| `644` | `rw-r--r--` | **el clásico de los ficheros**: todos leen, solo el dueño escribe (`/etc/passwd`) |
| `660` | `rw-rw----` | dueño y grupo editan (trabajo en equipo) |
| `664` | `rw-rw-r--` | como 660 pero todos leen (el que dan `umask 002` y Ubuntu) |
| `666` | `rw-rw-rw-` | todos leen y escriben (¡evítalo!) |
| `700` | `rwx------` | **privado**: script o carpeta solo del dueño (`~/.ssh`) |
| `711` | `rwx--x--x` | el dueño todo; los demás solo "atraviesan" (`--x`) |
| `750` | `rwxr-x---` | dueño todo; grupo lee y entra (**HOME en Ubuntu 24.04**) |
| `751` | `rwxr-x--x` | como 750 pero otros pueden ejecutar (`saludos.sh` de tu captura) |
| `755` | `rwxr-xr-x` | **el clásico de programas y carpetas**: todos leen/entran, solo el dueño escribe |
| `770` | `rwxrwx---` | dueño y grupo todo; otros nada |
| `775` | `rwxrwxr-x` | dueño y grupo todo; otros leen/ejecutan (`cerve.sh` y `salario.sh` de tu captura) |
| `777` | `rwxrwxrwx` | todo para todos (¡casi siempre un error!) |
| `1777` | `rwxrwxrwt` | **sticky**: carpeta pública donde cada uno borra lo suyo (`/tmp`) |
| `1730` | `rwx-wx--T` | buzón: el grupo deposita, nadie lista (`/var/spool/cron/crontabs`) |
| `2755` | `rwxr-sr-x` | **SGID** en programa: corre con el grupo del dueño (`/usr/bin/crontab`) |
| `2775` | `rwxrwsr-x` | **SGID** en carpeta de equipo: lo nuevo hereda el grupo |
| `4755` | `rwsr-xr-x` | **SUID**: corre con los privilegios del dueño (`/usr/bin/passwd`) |

(Las letras de esta tabla las genera un programa a partir del número, así que no hay erratas.)

---

## 5.11 · El cuarto dígito, de momento solo una pista

Hasta aquí, **tres cifras** (dueño, grupo, otros). A veces ves **cuatro**: `4755`, `2775`, `1777`. La cifra **de delante** son los **bits especiales** y vale igual de fácil:

```text
   4        7  5  5
   │        └──┴──┴── dueño · grupo · otros   (como siempre)
   └─ especiales:  4 = SUID   2 = SGID   1 = sticky     (se suman igual que r w x)
```

Por ejemplo, `1777` = `1` (sticky) + `777`. En letras, esos bits **sustituyen a la `x`**: `rwxrwxrwt`. El capítulo 10 los explica uno a uno.

---

## 5.12 · Tabla de conversión completa (la de cabecera)

| Octal | Letras | Binario | Decimal | Hex |
|:-:|:-:|:-:|:-:|:-:|
| `644` | `rw-r--r--` | `110 100 100` | 420 | `0x1a4` |
| `755` | `rwxr-xr-x` | `111 101 101` | 493 | `0x1ed` |
| `700` | `rwx------` | `111 000 000` | 448 | `0x1c0` |
| `777` | `rwxrwxrwx` | `111 111 111` | 511 | `0x1ff` |
| `640` | `rw-r-----` | `110 100 000` | 416 | `0x1a0` |
| `600` | `rw-------` | `110 000 000` | 384 | `0x180` |
| `4755` | `rwsr-xr-x` | `100 111 101 101` | 2541 | `0x9ed` |
| `1777` | `rwxrwxrwt` | `001 111 111 111` | 1023 | `0x3ff` |
| `2775` | `rwxrwsr-x` | `010 111 111 101` | 1533 | `0x5fd` |

Cómo leer la columna *Decimal*: es el **valor numérico** del modo completo (lo que devuelven `os.stat()` o `$((8#…))`). **No** se usa para `chmod`, solo para entender qué guarda el sistema por dentro.

---

## 5.13 · 🏋️ Entrenamiento de velocidad

Haz cada serie **cronometrándote**. Objetivo: **menos de 3 segundos por pregunta**. Tapa las respuestas hasta terminar. (🌐 Para entrenar **sin límite**, con preguntas aleatorias y pasos de cálculo, abre `herramientas/entrenador-conversion.html` en el navegador.)

#### 🟢 Serie 5.1 · Letras → octal

**Letras → octal**

1. `rwxr-xr-x`
2. `rw-r--r--`
3. `rwx------`
4. `r--r--r--`
5. `rw-rw----`
6. `rwxrwxrwx`
7. `rwxr-x---`
8. `rw-------`
9. `r-xr-xr-x`
10. `-wx-wx-wx`
11. `rwx--x--x`
12. `r--------`
13. `rw-rw-r--`
14. `---rwxrwx`
15. `r-x------`

<details>
<summary>💡 Ver respuestas</summary>

1. `rwxr-xr-x` → **755**
2. `rw-r--r--` → **644**
3. `rwx------` → **700**
4. `r--r--r--` → **444**
5. `rw-rw----` → **660**
6. `rwxrwxrwx` → **777**
7. `rwxr-x---` → **750**
8. `rw-------` → **600**
9. `r-xr-xr-x` → **555**
10. `-wx-wx-wx` → **333**
11. `rwx--x--x` → **711**
12. `r--------` → **400**
13. `rw-rw-r--` → **664**
14. `---rwxrwx` → **077**
15. `r-x------` → **500**

</details>

#### 🟢 Serie 5.2 · Octal → letras

**Octal → letras**

1. `640`
2. `755`
3. `700`
4. `444`
5. `664`
6. `750`
7. `711`
8. `600`
9. `777`
10. `005`
11. `111`
12. `520`
13. `372`
14. `000`
15. `421`

<details>
<summary>💡 Ver respuestas</summary>

1. `640` → **`rw-r-----`**
2. `755` → **`rwxr-xr-x`**
3. `700` → **`rwx------`**
4. `444` → **`r--r--r--`**
5. `664` → **`rw-rw-r--`**
6. `750` → **`rwxr-x---`**
7. `711` → **`rwx--x--x`**
8. `600` → **`rw-------`**
9. `777` → **`rwxrwxrwx`**
10. `005` → **`------r-x`**
11. `111` → **`--x--x--x`**
12. `520` → **`r-x-w----`**
13. `372` → **`-wxrwx-w-`**
14. `000` → **`---------`**
15. `421` → **`r---w---x`**

</details>

#### 🟡 Serie 5.3 · Binario → octal y letras

**Binario → octal y letras**

1. `111101101`
2. `110100100`
3. `111000000`
4. `100100100`
5. `110110000`
6. `111111111`
7. `101101101`
8. `011010001`

<details>
<summary>💡 Ver respuestas</summary>

1. `111101101` → octal **755** → `rwxr-xr-x`
2. `110100100` → octal **644** → `rw-r--r--`
3. `111000000` → octal **700** → `rwx------`
4. `100100100` → octal **444** → `r--r--r--`
5. `110110000` → octal **660** → `rw-rw----`
6. `111111111` → octal **777** → `rwxrwxrwx`
7. `101101101` → octal **555** → `r-xr-xr-x`
8. `011010001` → octal **321** → `-wx-w---x`

</details>

#### 🟡 Serie 5.4 · Decimal → octal y letras

(Pista: para pasar un decimal a octal, **divide entre 8** y apunta los restos de abajo arriba: `493 ÷ 8 = 61 resto 5`, `61 ÷ 8 = 7 resto 5`, `7` → **755**.)

**Decimal → octal y letras**

1. `493`
2. `420`
3. `448`
4. `511`
5. `384`
6. `292`
7. `488`
8. `438`

<details>
<summary>💡 Ver respuestas</summary>

1. `493` → octal **755** → `rwxr-xr-x`
2. `420` → octal **644** → `rw-r--r--`
3. `448` → octal **700** → `rwx------`
4. `511` → octal **777** → `rwxrwxrwx`
5. `384` → octal **600** → `rw-------`
6. `292` → octal **444** → `r--r--r--`
7. `488` → octal **750** → `rwxr-x---`
8. `438` → octal **666** → `rw-rw-rw-`

</details>

#### 🔴 Serie 5.5 · Cuatro cifras → letras

**Cuatro cifras → letras**

1. `4755`
2. `2755`
3. `1777`
4. `6755`
5. `1730`
6. `2770`
7. `4711`
8. `7777`
9. `2750`
10. `4000`

<details>
<summary>💡 Ver respuestas</summary>

1. `4755` → **`rwsr-xr-x`**
2. `2755` → **`rwxr-sr-x`**
3. `1777` → **`rwxrwxrwt`**
4. `6755` → **`rwsr-sr-x`**
5. `1730` → **`rwx-wx--T`**
6. `2770` → **`rwxrws---`**
7. `4711` → **`rws--x--x`**
8. `7777` → **`rwsrwsrwt`**
9. `2750` → **`rwxr-s---`**
10. `4000` → **`--S------`**

</details>

#### 🔴 Serie 5.6 · Letras con `s`/`t` → octal de 4 cifras

**Letras con `s`, `S`, `t`, `T` → octal de 4 cifras**

1. `rwsr-xr-x`
2. `rwxr-sr-x`
3. `rwxrwxrwt`
4. `rwx-wx--T`
5. `rwxrws---`
6. `rwSr--r--`
7. `rwxrwsr-x`
8. `rwx--S---`

<details>
<summary>💡 Ver respuestas</summary>

1. `rwsr-xr-x` → **4755**
2. `rwxr-sr-x` → **2755**
3. `rwxrwxrwt` → **1777**
4. `rwx-wx--T` → **1730**
5. `rwxrws---` → **2770**
6. `rwSr--r--` → **4644**
7. `rwxrwsr-x` → **2775**
8. `rwx--S---` → **2700**

</details>

---

## 5.14 · 🏋️ Ejercicios de pensar

#### 🟢 Ejercicio 5.7 · El número justo

¿Qué octal da: **dueño** lee y escribe, **grupo** solo lee, **otros** nada?

<details>
<summary>💡 Ver solución</summary>

`rw-` `r--` `---` → 6 · 4 · 0 → **640**. Compruébalo:

```text
$ permisos u=rw,g=r,o=
chmod u=rw,g=r,o=   aplicado a 000

Resultado:

  Octal     640
  Letras    rw-r-----      (en ls -l: -rw-r-----)
  Binario   110 100 000
  Decimal   416
  Hex       0x1a0

  dueño   rw-  (6)  leer, escribir
  grupo   r--  (4)  leer
  otros   ---  (0)  nada

  chmod 640 FICHERO
  chmod u=rw,g=r,o= FICHERO
```
</details>

#### 🟢 Ejercicio 5.8 · ¿Cuántos modos hay?

¿Cuántas combinaciones **distintas** de `rwxrwxrwx` existen? ¿Y contando los 3 bits especiales?

<details>
<summary>💡 Ver solución</summary>

9 interruptores → 2⁹ = **512** (de `000` a `777`). Con los 3 especiales: 12 interruptores → 2¹² = **4096** (de `0000` a `7777`).
</details>

#### 🟡 Ejercicio 5.9 · 755 frente a 775

¿En qué se diferencian exactamente `755` y `775`?

<details>
<summary>💡 Ver solución</summary>

El **grupo**: `r-x` (5) frente a `rwx` (7). Con `775` los miembros del grupo pueden además **crear y borrar** (en carpetas) o **modificar** (en ficheros). Es la diferencia entre "trabajo en equipo" y "solo el dueño edita".

```text
$ permisos 755 | grep -E 'dueño|grupo|otros'
  dueño   rwx  (7)  leer, escribir, ejecutar
  grupo   r-x  (5)  leer, ejecutar
  otros   r-x  (5)  leer, ejecutar
$ permisos 775 | grep -E 'dueño|grupo|otros'
  dueño   rwx  (7)  leer, escribir, ejecutar
  grupo   rwx  (7)  leer, escribir, ejecutar
  otros   r-x  (5)  leer, ejecutar
```
</details>

#### 🟡 Ejercicio 5.10 · ¿Cuál no es válido?

¿Cuál de estos **no** es un modo octal válido? `0644` · `1777` · `888` · `4755`

<details>
<summary>💡 Ver solución</summary>

**`888`**: el 8 no existe en octal (las cifras son 0-7). `0644` es válido (el `0` de delante son "sin bits especiales").

```text
$ touch valido.txt
$ chmod 888 valido.txt
chmod: invalid mode: ‘888’
Try 'chmod --help' for more information.
$ chmod 0644 valido.txt
$ ls -l valido.txt
-rw-r--r-- 1 alumno alumno 0 Oct 16 17:09 valido.txt
```
</details>

#### 🟡 Ejercicio 5.11 · Sin recalcular

Tienes un fichero `644` y quieres darle escritura al grupo. ¿Qué nuevo octal sale? ¿Y qué `chmod` cómodo lo hace sin pensar en números?

<details>
<summary>💡 Ver solución</summary>

El grupo pasa de `r--` (4) a `rw-` (6) → **664**. Con letras no hace falta recalcular nada: **`chmod g+w fichero`**.

```text
$ permisos 644 g+w
Base 644  +  chmod g+w

Resultado:

  Octal     664
  Letras    rw-rw-r--      (en ls -l: -rw-rw-r--)
  Binario   110 110 100
  Decimal   436
  Hex       0x1b4

  dueño   rw-  (6)  leer, escribir
  grupo   rw-  (6)  leer, escribir
  otros   r--  (4)  leer

  chmod 664 FICHERO
  chmod u=rw,g=rw,o=r FICHERO
```
</details>

#### 🔴 Ejercicio 5.12 · Dos números que se parecen mucho

`chmod 077` y `chmod 770` suenan parecido. ¿Qué hace cada uno?

<details>
<summary>💡 Ver solución</summary>

```text
$ permisos 077 | grep -E 'dueño|grupo|otros'
  dueño   ---  (0)  nada
  grupo   rwx  (7)  leer, escribir, ejecutar
  otros   rwx  (7)  leer, escribir, ejecutar
$ permisos 770 | grep -E 'dueño|grupo|otros'
  dueño   rwx  (7)  leer, escribir, ejecutar
  grupo   rwx  (7)  leer, escribir, ejecutar
  otros   ---  (0)  nada
```

`077` = dueño nada, **todos los demás todo** (¡absurdo y peligroso!). `770` = dueño y grupo todo, otros nada (muy normal en carpetas de equipo). Por eso la **posición** de cada cifra es sagrada.
</details>

#### 🔴 Ejercicio 5.13 · La trampa del decimal

Un compañero ejecuta `os.chmod("f", 644)` en Python y se queja de que "los permisos salen raros". ¿Qué modo ha puesto realmente? ¿Cómo se corrige?

<details>
<summary>💡 Ver solución</summary>

644 **decimal** = `1204` octal → `--w----r-T`. Se corrige con `0o644`.

```text
$ printf '%o\n' 644
1204
$ permisos 1204 | head -n 6
1204

  Octal     1204
  Letras    -w----r-T      (en ls -l: --w----r-T)
  Binario   001 010 000 100      (3 bits especiales + 3 × 3)
  Decimal   644
/var/tmp/permgen/bin/permisos: line 139: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 140: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 141: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 144: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 155: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 159: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 160: printf: write error: Broken pipe
```
</details>

#### ⚫ Ejercicio 5.14 · Examen: leer un número

*¿Qué significa `chmod 640 informe.txt`?* a) Dueño: leer/escribir; grupo: leer; otros: nada b) Dueño: todo; grupo: leer; otros: nada c) Dueño: leer; grupo: leer/escribir; otros: nada d) Todos: leer

<details>
<summary>💡 Ver solución</summary>

**a)**. 6 = `rw-`, 4 = `r--`, 0 = `---`.
</details>

#### ⚫ Ejercicio 5.15 · Examen: elegir el número

*Quieres que el dueño pueda leer/escribir/ejecutar un script, el grupo solo leer y ejecutar, y los demás nada. ¿Qué `chmod`?* a) 755 b) 750 c) 705 d) 570

<details>
<summary>💡 Ver solución</summary>

**b) 750.** `rwx` (7) · `r-x` (5) · `---` (0).

a) daría a "otros" lectura y ejecución; c) daría al grupo nada y a otros `r-x`; d) invierte dueño y grupo.
</details>

#### ⚫ Ejercicio 5.16 · Examen: dos formas de lo mismo

*¿Cuál de estas órdenes es equivalente a `chmod 644 f`?* a) `chmod u=rw,go=r f` b) `chmod u=rwx,go=r f` c) `chmod a=r f` d) `chmod +rw f`

<details>
<summary>💡 Ver solución</summary>

**a).** `u=rw` (6), `go=r` (4 y 4) → 644. Compruébalo:

```text
$ permisos u=rw,go=r | head -n 4
chmod u=rw,go=r   aplicado a 000

Resultado:

/var/tmp/permgen/bin/permisos: line 134: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 136: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 137: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 138: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 139: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 140: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 141: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 159: printf: write error: Broken pipe
/var/tmp/permgen/bin/permisos: line 160: printf: write error: Broken pipe
```
</details>

---

⬅️ [Capítulo 4 · ¿Quién decide qué? El algoritmo de los permisos](04-quien-decide.md) · [📚 Índice](README.md) · [Capítulo 6 · `chmod` en modo simbólico: `u+x`, `go-w`, `a=r`…](06-chmod-simbolico.md) ➡️
