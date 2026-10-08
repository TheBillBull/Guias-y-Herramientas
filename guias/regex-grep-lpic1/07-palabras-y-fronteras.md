# Capítulo 7 · Palabras y fronteras: `-w` `-x` `\b` `\<` `\>` `\w`

> 🎯 **Objetivo:** buscar **palabras completas** (no trozos de palabras), y conocer las "vallas invisibles" `\b`, `\<` y `\>` y los atajos `\w` y `\s`.
>
> 📘 **LPIC-1:** 103.7. (Las extensiones `\b`, `\<`, `\>`, `\w` son de GNU; el examen suele preguntar por `\<` y `\>`.)
>
> 🧪 `cd ~/lab-regex`

---

## 7.1 · El problema: buscar `ana` y encontrar `Manager`

En el capítulo 1 buscamos `ana` en `/etc/passwd` y salieron líneas indeseadas: `Manager`, `Management`… porque ahí las letras `a-n-a` aparecen **dentro** de otra palabra (M-**ana**-ger).

Lo que queríamos era **la palabra `ana`**, sola. Y Linux nos da herramientas para eso.

### Opción 1: `grep -w` ("palabra completa")

```bash
grep -w ana /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«ana»:x:1001:1001:Ana Garcia,,,:/home/«ana»:/bin/bash
```


Ahora solo sale el usuario `ana`. La opción `-w` (*word-regexp*) dice: *"la coincidencia solo vale si está **rodeada de caracteres que no son de palabra**, o pegada al principio/final de la línea"*.

### ¿Y qué es un "carácter de palabra"?

Para `grep`, una **palabra** está hecha de:

- **letras** (incluidas las acentuadas, en UTF-8),
- **números**,
- el **guion bajo** `_`.

Todo lo demás (espacios, `-`, `.`, `,`, `:`, `/`…) **separa** palabras.

> 🪤 **¡El guion bajo es de palabra!** Y el guion normal (`-`) **no**. Por eso:

```bash
grep -w apt /etc/passwd
```

_Resultado:_

```text
(no sale nada)
```


No encuentra al usuario `_apt`: para `grep`, `_apt` es **una sola palabra** (el `_` pertenece a ella), y no es `apt`. En cambio, `systemd` **sí** es una palabra suelta dentro de `systemd-network` (el `-` separa):

```bash
grep -w systemd /etc/passwd | cut -d: -f1
```

_Resultado:_

```text
systemd-network
systemd-timesync
systemd-resolve
```


### La diferencia visible con el capítulo 1

```bash
grep -c el frases.txt
grep -cw el frases.txt
grep -ciw el frases.txt
```

_Resultado:_

```text
5
4
6
```


- `el` suelto en minúscula: 5 líneas contienen esas dos letras (¡en cualquier sitio!).
- `-w`: 4 líneas tienen `el` como **palabra**.
- `-iw`: 6 líneas, contando también `El` con mayúscula.

---

## 7.2 · `-x`: la línea entera

`-x` (*line-regexp*) exige que **toda la línea** sea la coincidencia. Equivale a rodear el patrón con `^…$`:

| Opción | La coincidencia debe ser… |
|---|---|
| (ninguna) | **cualquier trozo** de la línea |
| `-w` | una **palabra completa** |
| `-x` | la **línea entera** |

```bash
grep -c gato palabras.txt
grep -cw gato palabras.txt
grep -cx gato palabras.txt
```

_Resultado:_

```text
3
2
2
```


En `palabras.txt` cada línea es una sola palabra, así que `-w` y `-x` coinciden en este caso; pero en una frase cambiarían mucho.

---

## 7.3 · Las vallas invisibles: `\b`, `\<`, `\>`

`-w` es una opción **de todo el comando**. Si quieres controlar los límites **dentro del patrón**, usas estos símbolos. Son de ancho **cero**: no "comen" ningún carácter, solo comprueban *dónde estás*.

Imagina que entre cada letra y su vecina hay una **valla invisible** y el patrón puede pedir *"aquí tiene que haber valla"*:

```text
 g a t o   g a t o s
┃       ┃ ┃         ┃
\<     \> \<       \>        ← \< = valla de inicio de palabra, \> = valla de fin
 ←──\b──→                    ← \b = cualquiera de las dos vallas
```

| Símbolo | Significa | Ejemplo |
|---|---|---|
| `\<` | **principio** de palabra | `\<gat` → palabras que **empiezan** por gat |
| `\>` | **fin** de palabra | `os\>` → palabras que **acaban** en os |
| `\b` | **límite** de palabra (el principio o el fin) | `\bgato\b` → la palabra `gato` |
| `\B` | **NO** es límite (estás en medio de una palabra) | `\Bato` → `ato` dentro de otra palabra |

```bash
grep -o '\<ga[[:alpha:]]*' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gatos»
```


Palabras que **empiezan** por `ga` (`-o` imprime solo el trozo que coincide).

```bash
grep -o '[[:alpha:]]*os\>' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gatos»
«perros»
«espacios»
«espacios»
```


Palabras que **acaban** en `os`.

```bash
echo 'gato gatos Gato' | grep -o '\bgato\b'
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
```


Solo la palabra `gato` exacta (no `gatos`, no `Gato`).

```bash
echo 'gato ato' | grep -o '\Bato'
```

_Resultado_ (coincidencias entre « »):

```text
«ato»
```


`\Bato` encuentra el `ato` que está **dentro** de `gato` (no el de la palabra `ato` sola, porque ahí antes hay una valla).

> 🧠 `-w` ≈ `\<…\>`: `grep -w gato` es casi igual que `grep '\<gato\>'`.

---

## 7.4 · Los atajos: `\w`, `\W`, `\s`, `\S`

Son abreviaturas de clases de caracteres (extensión GNU):

| Atajo | Equivale a | Significa |
|---|---|---|
| `\w` | `[_[:alnum:]]` | un carácter de **palabra** (letra, número o `_`) |
| `\W` | `[^_[:alnum:]]` | un carácter que **no** es de palabra |
| `\s` | `[[:space:]]` | un **espacio en blanco** |
| `\S` | `[^[:space:]]` | **no** es un espacio en blanco |

```bash
echo 'canción ñandú x_1' | grep -o '\w\+'
```

_Resultado:_

```text
canción
ñandú
x_1
```


Cada "palabra" (con tildes y ñ incluidas) sale en su línea. Contar **todas las palabras** de un fichero es ahora fácil:

```bash
grep -o '\w\+' frases.txt | wc -l
```

_Resultado:_

```text
116
```


```bash
echo 'a  b	c' | grep -o '\S\+' | tr '\n' '|'; echo
```

_Resultado:_

```text
a|b|c|
```


> ⚠️ **`\d` NO existe en `grep` normal.** Si vienes de otros lenguajes (Python, JavaScript) donde `\d` significa "dígito": aquí usa `[0-9]` o `[[:digit:]]`. (Solo `grep -P` lo entiende; capítulo 13.)

```bash
echo 'a1' | grep -o '\d'
```

_Resultado:_

```text
(no sale nada)
```


No sale nada: `\d` **no** ha encontrado el dígito `1`. En `grep` una `\d` no reconocida se lee simplemente como la **letra `d`** (y según la versión puede avisarte con un `stray \ before d`):

```bash
echo 'abc d 1' | grep -o '\d'
```

_Resultado:_

```text
d
```


---

## 7.5 · Arreglamos las trampas anteriores

### Las palabras repetidas, bien hechas

En el capítulo 6, `([a-z]+) \1` daba falsos positivos. Con **límites de palabra** (`\b`) a ambos lados:

```bash
grep -inE '\b([a-z]+) \1\b' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
8:«El el» perro ladra mucho.
9:Voy «a a» la playa.
```


Ahora sí: solo las líneas 8 (`El el`) y 9 (`a a`).

### La IP exacta (no `192.168.1.100`)

En el capítulo 3 buscábamos `192.168.1.1` y se colaba `192.168.1.100`:

```bash
grep -w '192\.168\.1\.1' ips.txt
# Otra forma equivalente:
grep '192\.168\.1\.1\b' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168.1.1»
```


Con `-w` (o `\b` al final), `192.168.1.1` solo coincide si **termina ahí**. Pero ojo: el punto **separa** palabras, así que `192.168.1.1.5` también pasaría. Para IPs "de verdad" necesitamos algo más fino (capítulo 12).

---

## 7.6 · 🏋️ Ejercicios

#### 🟢 Ejercicio 7.1 · Solo la palabra `ana`

Muestra los usuarios de `/etc/passwd` donde `ana` aparezca como **palabra completa**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -w ana /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«ana»:x:1001:1001:Ana Garcia,,,:/home/«ana»:/bin/bash
```


`-w` descarta `Manager` y `Management`. Compárala con `grep ana /etc/passwd`.
</details>


#### 🟢 Ejercicio 7.2 · Cuántas veces "el"

Cuenta las líneas de `frases.txt` que contengan la **palabra** `el`, sin distinguir mayúsculas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -ciw el frases.txt
```

_Resultado:_

```text
6
```


`-i` (mayúsculas), `-w` (palabra), `-c` (cuenta): se juntan las tres.
</details>


#### 🟢 Ejercicio 7.3 · Palabras que empiezan por "ga"

Muestra, una por línea, las palabras de `frases.txt` que **empiezan** por `ga`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '\<ga[[:alpha:]]*' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gatos»
```


`\<` = inicio de palabra; `[[:alpha:]]*` se come el resto de las letras de la palabra. `-o` muestra solo ese trozo.
</details>


#### 🟢 Ejercicio 7.4 · Palabras que acaban en "os"

Muestra las palabras de `frases.txt` que **acaban** en `os`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '[[:alpha:]]*os\>' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gatos»
«perros»
«espacios»
«espacios»
```


`\>` = fin de palabra.
</details>


#### 🟢 Ejercicio 7.5 · Solo la palabra exacta

De la cadena `gato gatos Gato gatito`, extrae solo la palabra `gato` (minúscula, sola).

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'gato gatos Gato gatito' | grep -o '\bgato\b'
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
```


`\b` a ambos lados convierte `gato` en "palabra completa".
</details>


#### 🟢 Ejercicio 7.6 · Línea entera con -x

Muestra las líneas de `palabras.txt` que sean **exactamente** `hola`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -x hola palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«hola»
```


`-x` obliga a que la línea completa coincida (no `hoola` ni `hooola`).
</details>


#### 🟢 Ejercicio 7.7 · La palabra "a" suelta

Cuenta las líneas de `frases.txt` que contienen la **palabra** `a` (la preposición).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cw a frases.txt
```

_Resultado:_

```text
1
```


Solo sale **1** línea: `Voy a a la playa.` (la `a` suelta, como palabra). Sin `-w`, `grep -c a` contaría 16 de las 20 líneas del fichero, porque casi todas tienen una `a` **dentro** de alguna palabra.
</details>


#### 🟢 Ejercicio 7.8 · Cuántas palabras tiene el fichero

Cuenta el **número total de palabras** de `frases.txt` (con `\w`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '\w\+' frases.txt | wc -l
```

_Resultado:_

```text
116
```


`-o '\w\+'` saca cada palabra en una línea, y `wc -l` cuenta las líneas. (No vale solo `grep -c`: contaría líneas, no palabras.)
</details>


#### 🟢 Ejercicio 7.9 · La trampa del guion bajo

¿Por qué `grep -w apt /etc/passwd` no encuentra al usuario `_apt`, pero `grep -w systemd /etc/passwd` sí encuentra `systemd-network`?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -w apt /etc/passwd
```

_Resultado:_

```text
(no sale nada)
```


```bash
grep -cw systemd /etc/passwd
```

_Resultado:_

```text
3
```


Porque el guion bajo (`_`) es un **carácter de palabra** (`\w`), y el guion normal (`-`) no. Para `grep`, `_apt` es una sola palabra; `systemd-network` son dos (`systemd` y `network`).
</details>


#### 🟡 Ejercicio 7.10 · Palabras de 4 letras

Muestra las palabras de **exactamente 4 letras** de `frases.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '\<[[:alpha:]]{4}\>' frases.txt | tr '\n' ' '
```

_Resultado:_

```text
come gato sofá casa está será café juan tuyo Esta tres Esta Esta 
```


`\<…\>` rodean `[[:alpha:]]{4}` para exigir que la palabra completa tenga 4 letras. Sin las vallas saldrían trozos de 4 letras de palabras más largas.
</details>


#### 🟡 Ejercicio 7.11 · Palabras con Mayúscula inicial

Muestra las palabras de `frases.txt` que empiezan por mayúscula y continúan con minúsculas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '\<[A-Z][a-z]*\>' frases.txt | tr '\n' ' '
```

_Resultado:_

```text
El El La Hoy El Voy Linux Linux Me Tengo El Mi Y Esta Esta Esta Fin 
```


Fíjate en que **`Mañana` no sale**: la `ñ` no está en `[a-z]` (en este modo), así que la palabra no encaja entera. Con `[[:lower:]]` en vez de `[a-z]` sí saldría.
</details>


#### 🟡 Ejercicio 7.12 · Palabras largas

Muestra las palabras de **8 o más letras** de `frases.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '\<[[:alpha:]]{8,}\>' frases.txt | tr '\n' ' '
```

_Resultado:_

```text
biblioteca chocolate teléfono minusculas MAYUSCULAS espacios espacios tabulador 
```


`{8,}` = 8 o más (la coma sin máximo).
</details>


#### 🟡 Ejercicio 7.13 · Palabras repetidas de verdad

Muestra, con número de línea, las líneas de `frases.txt` con una **palabra repetida** seguida (como `el el`), sin falsos positivos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -inE '\b([a-z]+) \1\b' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
8:«El el» perro ladra mucho.
9:Voy «a a» la playa.
```


`\b…\b` evita que `e e` (fin de una palabra + inicio de otra) se cuente como repetición.
</details>


#### 🟡 Ejercicio 7.14 · La IP exacta

De `ips.txt`, muestra las líneas con la IP `192.168.1.1` y **no** `192.168.1.100`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -w '192\.168\.1\.1' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168.1.1»
```


`-w` fuerza que tras `.1` no siga una letra, número o `_`.
</details>


#### 🟡 Ejercicio 7.15 · Errores como palabra

Cuenta las líneas de `syslog` con la palabra `error` (sin importar mayúsculas), y compara con las que contienen la secuencia `error` en cualquier sitio.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -ciw error /var/log/syslog
grep -ci error /var/log/syslog
```

_Resultado:_

```text
4
5
```


Con `-w` salen 4; sin `-w`, 5. La línea de más es la de `Raw_Read_Error_Rate`: ahí `Error` va pegado a otras palabras por guiones bajos, y como el `_` es un carácter de palabra, **no** es la palabra `error` suelta.
</details>


#### 🟡 Ejercicio 7.16 · Paquetes `git`

Muestra las 3 primeras líneas de `dpkg.log` con el paquete `git` **exacto** (no `libgit2`…).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -w git /var/log/dpkg.log | head -3
```

_Resultado:_

```text
2024-11-04 09:12:13 install git:amd64 <none> 1:2.43.0-1ubuntu7.1
2024-11-04 09:12:15 status half-installed git:amd64 1:2.43.0-1ubuntu7.1
2024-11-04 09:12:17 status unpacked git:amd64 1:2.43.0-1ubuntu7.1
```


`:` separa palabras, así que `git:amd64` contiene la palabra `git`.
</details>


#### 🟡 Ejercicio 7.17 · Dentro de la palabra

De la cadena `gato ato`, muestra los `ato` que estén **dentro** de otra palabra (no al principio).

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'gato ato' | grep -o '\Bato'
```

_Resultado_ (coincidencias entre « »):

```text
«ato»
```


`\B` = "aquí NO hay límite de palabra". El `ato` de `gato` está a mitad de palabra; el segundo `ato` tiene valla delante, así que no vale (pero el patrón no lo mira).
</details>


#### 🟡 Ejercicio 7.18 · Los que no son espacio

Separa en "trozos" (secuencias de caracteres que no son espacios) la cadena `a  b<TAB>c` (con espacio doble y tabulador) mostrando uno por línea.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a  b\tc\n' | grep -o '\S\+'
```

_Resultado:_

```text
a
b
c
```


`\S\+` = "uno o más caracteres que no son espacio en blanco": separa por espacios y tabuladores.
</details>


#### 🔴 Ejercicio 7.19 · Misma letra al empezar y acabar (palabras)

Muestra, de `poema.txt`, las **palabras** que empiezan y acaban con la misma letra (de 2 o más letras).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -ohE '\b(\w)\w*\1\b' poema.txt | tr '\n' ' '
```

_Resultado:_

```text
sus ala sus 
```


`\b(\w)` captura la primera letra; `\w*` el medio; `\1\b` exige que acabe igual. Salen `sus`, `ala`, `sus` (hay 2 `sus`).
</details>


#### 🔴 Ejercicio 7.20 · Valla doble

Escribe un patrón que encuentre la palabra `gato` solo cuando esté **entre espacios** en `el gato duerme`, pero sin usar `-w` ni `\b`. (Pista: `[[:space:]]`.)

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'el gato duerme' | grep -o '[[:space:]]gato[[:space:]]'
```

_Resultado_ (coincidencias entre « »):

```text
« gato »
```


El problema de este enfoque es que **consume** los espacios (aparecen en el resultado) y falla al principio o final de línea. Por eso `\b` y `-w` son mejores: son de ancho cero.
</details>


#### 🔴 Ejercicio 7.21 · La lista de palabras únicas

Obtén la lista de **palabras distintas**, en minúsculas y ordenadas, de `frases.txt` que tengan más de 6 letras. *(Pista: tubería `grep -o` → `tr` → `sort -u`.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '\<[[:alpha:]]{7,}\>' frases.txt | tr 'A-Z' 'a-z' | sort -u
```

_Resultado:_

```text
biblioteca
chocolate
ejemplo
empieza
espacios
mayusculas
minusculas
octubre
tabulador
teléfono
termina
```


`grep -o` extrae, `tr 'A-Z' 'a-z'` pasa a minúsculas y `sort -u` ordena y elimina repetidas. (Los comandos `tr`, `sort`, `uniq`… son de LPIC 103.2.)
</details>


#### ⚫ Ejercicio 7.22 · Cuatro formas de "palabra"

Para la cadena `x_1 foo-bar 123`, di cuántas "palabras" ve `\w\+` y cuáles son. Explica el papel del `_` y del `-`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'x_1 foo-bar 123' | grep -o '\w\+'
```

_Resultado:_

```text
x_1
foo
bar
123
```


Sale: `x_1` (el `_` es de palabra), `foo`, `bar` (el `-` **separa**), `123`. En total 4.
</details>


---

## ✅ Resumen del capítulo 7

| Quiero… | Escribo |
|---|---|
| palabra completa (todo el comando) | `grep -w palabra` |
| línea completa (todo el comando) | `grep -x línea` |
| **principio** de palabra | `\<` |
| **fin** de palabra | `\>` |
| **límite** de palabra | `\b` |
| **dentro** de una palabra | `\B` |
| carácter de palabra / no palabra | `\w` / `\W` |
| espacio en blanco / no espacio | `\s` / `\S` |

**Palabra** = letras + números + `_`. El guion `-` **no** forma parte de la palabra. `\d` **no existe** (solo `-P`).

➡️ **Siguiente parada:** [Capítulo 8](08-bre-vs-ere.md): BRE contra ERE; `grep`, `egrep` y `fgrep`, y las diferencias que preguntan en el examen.

---
⬅️ [Capítulo 6 · Grupos, alternativas y memoria: `( )` `|` `\1`](06-grupos-alternancia.md) · 🏠 [Índice](README.md) · [Capítulo 8 · BRE contra ERE: `grep`, `egrep`, `fgrep` (¡y `-P`!)](08-bre-vs-ere.md) ➡️
