# Capítulo 4 · Los corchetes `[ ]`: elegir entre varios caracteres

> 🎯 **Objetivo:** dominar los **corchetes**, la herramienta más versátil de las expresiones regulares: listas, rangos, negaciones y clases POSIX. Y entender de una vez **qué pasa con cada símbolo cuando está dentro o fuera de un corchete**.
>
> 📘 **LPIC-1:** 103.7 — *"character classes"*, `[:alpha:]`, `[:digit:]`…
>
> 🧪 `cd ~/lab-regex`

---

## 4.1 · La lista de invitados

Imagina un portero de discoteca con una **lista de invitados**. Tú llegas y te dice: *"solo pasa quien se llame Ana, Luis o Marta"*. Te mira y solo hay **una** persona en la puerta cada vez: o está en la lista, o no.

Un **corchete** es exactamente eso: una **casilla** (un único carácter) con una **lista de los caracteres permitidos**:

```text
[abc]   →  UN carácter, que debe ser una a, o una b, o una c
```

```bash
grep 'c[ao]sa' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«casa»
«casa»s
«cosa»
«casa»
```


`c[ao]sa` = `c` + *(una `a` o una `o`)* + `sa`. Encajan `casa` y `cosa`.

### Las 4 reglas de oro del corchete

1. 🎯 **Ocupa SIEMPRE un solo carácter.** `[ao]` no encuentra `ao` seguido; encuentra **una** `a` **o una** `o`.
2. 🔀 **El orden da igual.** `[ao]` = `[oa]`.
3. ♻️ **Repetir no importa.** `[aaa]` = `[a]`.
4. 🧾 **Dentro, casi todo es "normal"** (ya lo veremos con detalle en 4.5).

```bash
grep '[Gg]ato' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«Gato»
«gato»s
«gato»
```


`[Gg]ato`: "G o g" y luego `ato`. Es una forma de ignorar mayúsculas **solo en una letra** (a diferencia de `-i`, que lo hace en todo el patrón).

Otro ejemplo: ¿qué palabras empiezan por una vocal?

```bash
grep '^[aeiou]' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«a»la
«o»so
«o»jo
«a»nilina
«a»aa
«a»a
«a»
«a»bc
«a»bcabc
«e»grep
```


Y ¿cuáles **no tienen** ninguna vocal? (`-v` + corchete):

```bash
grep -v '[aeiou]' palabras.txt
```

_Resultado:_

```text
GATO
LINUX
zsh
```


Solo salen `zsh` (sin vocales de verdad 😄) y `GATO`/`LINUX` (sus vocales son **mayúsculas**, y nuestro corchete solo contiene minúsculas).

---

## 4.2 · Rangos: `[a-z]`, `[0-9]`

Escribir `[0123456789]` es un rollo. Con un **guion** entre dos caracteres expresas un **rango**:

| Rango | Equivale a |
|---|---|
| `[0-9]` | cualquier dígito |
| `[a-z]` | cualquier letra minúscula |
| `[A-Z]` | cualquier letra mayúscula |
| `[a-zA-Z]` | cualquier letra (min. o mayús.) |
| `[a-zA-Z0-9]` | cualquier letra o número |
| `[0-9a-fA-F]` | un dígito **hexadecimal** |
| `[3-7]` | 3, 4, 5, 6 o 7 |

```bash
grep '[0-9]' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
Hoy es lunes, «1»«4» de octubre de «2»«0»«2»«4».
Tengo «3» gatos, «2» perros y «1»«5» peces.
El número de teléfono es «6»«1»«2»«3»«4»«5»«6»«7»«8».
```


Todas las líneas que **contienen al menos un número**. Se pueden encadenar casillas: dos dígitos seguidos son `[0-9][0-9]`:

```bash
grep '[0-9][0-9]' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
Hoy es lunes, «14» de octubre de «20»«24».
Tengo 3 gatos, 2 perros y «15» peces.
El número de teléfono es «61»«23»«45»«67»8.
```


Y mezclar con las anclas:

```bash
grep -c '^[0-9]' numeros.txt
```

_Resultado:_

```text
25
```


(¿Cuántas líneas **empiezan** por un dígito?)

> ⚠️ **El rango es por orden del alfabeto, no por "sentido común".** `[a-z]` significa "desde la `a` hasta la `z`" en un orden concreto. Un rango al revés (`[z-a]`) es un error:

```bash
grep '[z-a]' numeros.txt
```

_Resultado:_

```text
grep: Invalid range end
```


### 🌍 El problema de los idiomas (locale)

¿Qué letras hay "entre la a y la z"? Depende del **idioma/configuración regional** (*locale*) de tu sistema. Mira cómo cambia `[a-z]` en tres configuraciones sobre las letras `b B é ñ z Z`:

```bash
echo -n "C.UTF-8:     "; printf 'b\nB\né\nñ\nz\nZ\n' | LC_ALL=C.UTF-8 grep -o '[a-z]' | tr '\n' ' '; echo
echo -n "en_US.UTF-8: "; printf 'b\nB\né\nñ\nz\nZ\n' | LC_ALL=en_US.UTF-8 grep -o '[a-z]' | tr '\n' ' '; echo
echo -n "es_ES.UTF-8: "; printf 'b\nB\né\nñ\nz\nZ\n' | LC_ALL=es_ES.UTF-8 grep -o '[a-z]' | tr '\n' ' '; echo
```

_Resultado:_

```text
C.UTF-8:     b z 
en_US.UTF-8: b é ñ z 
es_ES.UTF-8: b é z 
```


(Dado que no todos los ordenadores tienen todos los idiomas instalados, a ti te puede salir distinto. Se ven con `locale -a`.)

- En `C.UTF-8`: `[a-z]` son **solo** las 26 letras del alfabeto inglés, tal cual.
- En `en_US.UTF-8` y `es_ES.UTF-8` (el tuyo seguramente): **también** casan letras con acentos (`é`, `ñ`).

Moraleja: si necesitas **"letras minúsculas de verdad"** y que funcione igual en todas partes, usa las **clases POSIX** (sección 4.6): `[[:lower:]]`. Y para forzar el modo "puro ASCII" en un comando concreto: `LC_ALL=C grep …`.

---

## 4.3 · Negación: `[^...]` — "cualquiera MENOS estos"

Si lo **primero** dentro del corchete es un **circunflejo `^`**, el corchete se invierte: *"un carácter que NO esté en la lista"*.

```text
[abc]   →  una a, b o c
[^abc]  →  cualquier carácter MENOS a, b y c
```

```bash
grep -c '[^0-9]' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
24
```


Líneas con **al menos un carácter que no es dígito**. ¿Y las líneas que son *solo* dígitos? Son las que **no** tienen ningún no-dígito (doble negación, un poco de gimnasia mental):

```bash
grep -v '[^0-9]' numeros.txt | tr '\n' ' '
```

_Resultado:_

```text
0 7 42 100 1000 12345 2024 007 612345678 
```


(Esto es "líneas formadas solo por dígitos"; en el capítulo 5 aprenderás la forma directa: `^[0-9]*$`.)

### ¡Arreglamos el intruso `lp`!

En el capítulo 3 buscábamos usuarios con nombre de **4 letras** y nos colaba `lp`, porque el `.` se comía los `:`. Con `[^:]` ("cualquier cosa que no sea `:`") queda resuelto:

```bash
grep '^[^:][^:][^:][^:]:' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root:»x:0:0:root:/root:/bin/bash
«sync:»x:4:65534:sync:/bin:/bin/sync
«mail:»x:8:8:mail:/var/mail:/usr/sbin/nologin
«news:»x:9:9:news:/var/spool/news:/usr/sbin/nologin
«uucp:»x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
«list:»x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
«_apt:»x:42:65534::/nonexistent:/usr/sbin/nologin
«sshd:»x:105:65534::/run/sshd:/usr/sbin/nologin
«luis:»x:1002:1002:Luis Perez,,,:/home/luis:/bin/zsh
```


Ahora sí: solo nombres de **exactamente 4 caracteres** (`root`, `sync`, `mail`, `news`, `uucp`, `list`, `_apt`, `sshd`, `luis`). Ni rastro de `lp`. *(En el capítulo 5, con `{4}`, lo escribiremos mucho más corto.)*

### Una pega sutil: `[^#]` necesita un carácter

```bash
grep -c '^[^#]' /etc/hosts
grep -vc '^#' /etc/hosts
```

_Resultado:_

```text
11
13
```


Dos cifras distintas (11 y 13). ¿Por qué? `^[^#]` exige que la línea **tenga un primer carácter que no sea `#`**; una línea **vacía** no tiene ningún primer carácter, así que no coincide. En cambio `-v '^#'` deja pasar las vacías. Así que `grep '^[^#]'` es, en **un solo patrón**, "líneas **no vacías** que no empiezan por `#`": ¡un limpiador de comentarios y vacías sin `-v` ni `-e`!

---

## 4.4 · El circunflejo `^` y sus 3 vidas 🎭

El `^` es de los símbolos que más confunden, porque **hace cosas distintas según dónde esté**:

| Dónde está el `^` | Qué significa | Ejemplo |
|---|---|---|
| **Fuera** de un corchete, al **principio** del patrón | **Ancla**: principio de línea | `^root` |
| **Dentro** del corchete, **justo después de `[`** | **Negación**: "todo menos…" | `[^0-9]` |
| **Dentro** del corchete, **no el primero** | Un `^` **normal** (el propio carácter) | `[a^b]` |
| **Fuera** de un corchete, en medio del patrón (regex básica) | Un `^` **normal** | `a^b` |

Pruébalo tú:

```bash
printf 'a\n^\nb\n' | grep '[a^]'
```

_Resultado_ (coincidencias entre « »):

```text
«a»
«^»
```


`[a^]` = "una `a` **o** un circunflejo" (el `^` no está primero, así que no niega nada). Salen `a` y `^`, no `b`.

> 🧠 Truco para recordarlo: **el `^` solo "manda" cuando está en una esquina**: la del patrón (`^…`) o la del corchete (`[^…`). En cualquier otro sitio es un carácter normal.

---

## 4.5 · Qué pasa con los demás símbolos dentro de un corchete

Aquí viene la sorpresa: **dentro de un corchete, casi todos los superpoderes se APAGAN**. El interior de un corchete es un "santuario" donde las reglas cambian:

| Símbolo | **Fuera** del corchete | **Dentro** del corchete |
|---|---|---|
| `.` | cualquier carácter | un **punto normal** |
| `*` | repetición | un **asterisco normal** |
| `$` | final de línea | un **dólar normal** |
| `?` `+` `(` `)` `{` `}` `\|` | (ya veremos) | **normales** |
| `\` | escapa | **¡una barra normal!** (⚠️) |
| `^` | principio de línea | negación si es **el primero**; si no, normal |
| `-` | normal | **rango** si va *entre* dos caracteres; normal si va **al principio o al final** |
| `]` | normal | **cierra** el corchete (salvo si es el **primero**) |
| `[` | abre un corchete | normal (pero `[:` `[.` `[=` tienen significado especial) |

### Consecuencia 1: `[.]` es otra forma de escapar el punto

Como dentro del corchete el `.` es solo un punto, **`[.]` = `\.`**:

```bash
grep '3[.]14' numeros.txt
# Otra forma equivalente:
grep '3\.14' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«3.14»
```


Muchos administradores prefieren `[.]`, `[*]`, `[$]` porque **no usan barras invertidas** y quedan más legibles.

### Consecuencia 2: la barra invertida NO escapa dentro del corchete

Mira esta trampa:

```bash
printf 'a\\b\na.b\nacb\n' | grep 'a[\.]b'
```

_Resultado_ (coincidencias entre « »):

```text
«a\b»
«a.b»
```


Se esperaría que `[\.]` fuera "un punto", pero ha coincidido con `a\b` (¡con barra!) y con `a.b`. Porque dentro del corchete **`\` y `.` son dos caracteres normales**: `[\.]` es "una barra **o** un punto". La regla: **dentro de un corchete no se escapa nada**. Para un punto: `[.]` y listo.

### Consecuencia 3: poner un `]` o un `-` literales

- Para meter un **`]`** en la lista: ponlo **el primero** (justo después de `[` o de `[^`):

```bash
printf 'x]y\nxay\nxby\n' | grep 'x[]a]y'
```

_Resultado_ (coincidencias entre « »):

```text
«x]y»
«xay»
```


`[]a]` = "un `]` o una `a`". Salen las dos primeras líneas.

- Para meter un **`-`**: ponlo **al principio o al final** (donde no puede ser rango):

```bash
printf 'a\n-\nb\n' | grep '[a-]'
```

_Resultado_ (coincidencias entre « »):

```text
«a»
«-»
```


- Para meter un **`[`**: va sin problemas: `[[]`.

```bash
printf 'a[b\nab\n' | grep 'a[[]b'
```

_Resultado_ (coincidencias entre « »):

```text
«a[b»
```


### Consecuencia 4: lo que sí funciona para "símbolos raros"

Quieres líneas que contengan **cualquiera** de estos símbolos: `$`, `%`, `€`, `#`:

```bash
grep '[$%€#]' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«#»123
50«%»
«$»99
99.99«€»
```


Todos van juntos, y el `$` aquí **no** es "final de línea": dentro de corchete es un dólar normal.

---

## 4.6 · Las clases POSIX: `[[:digit:]]` y compañía

En vez de rangos (`[0-9]`, `[a-z]`), existen **nombres de grupo**, que son más legibles y que **funcionan en cualquier idioma**:

| Clase | Equivale (más o menos) a | Significado |
|---|---|---|
| `[:digit:]` | `[0-9]` | un **dígito** |
| `[:alpha:]` | `[a-zA-Z]` + acentos, ñ… | una **letra** |
| `[:alnum:]` | `[a-zA-Z0-9]` + acentos | letra **o** dígito |
| `[:upper:]` | `[A-Z]` + acentos | letra **mayúscula** |
| `[:lower:]` | `[a-z]` + acentos | letra **minúscula** |
| `[:space:]` | espacio, tabulador, salto de línea… | cualquier **espacio en blanco** |
| `[:blank:]` | espacio y tabulador | solo "huecos" **horizontales** |
| `[:punct:]` | `! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ { \| } ~` | **signos de puntuación** |
| `[:xdigit:]` | `[0-9a-fA-F]` | dígito **hexadecimal** |
| `[:print:]` | | cualquier carácter **imprimible** (con espacio) |
| `[:graph:]` | | imprimible **sin espacio** |
| `[:cntrl:]` | | caracteres de **control** (tabulador, saltos…) |

> ⚠️ **¡Van DENTRO de otro corchete!** Son **dos pares de corchetes**: el exterior es el "corchete" de siempre y el interior (`[:digit:]`) es el *nombre* de la clase.
>
> ```text
> [[:digit:]]     ← ✅ correcto
>  [:digit:]      ← ❌ error: sin el corchete exterior
> ```

```bash
grep '[:digit:]' numeros.txt
```

_Resultado:_

```text
grep: character class syntax is [[:space:]], not [:space:]
```


`grep` es amable y te avisa del error típico. Ahora bien:

```bash
grep '[[:digit:]]' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
Hoy es lunes, «1»«4» de octubre de «2»«0»«2»«4».
Tengo «3» gatos, «2» perros y «1»«5» peces.
El número de teléfono es «6»«1»«2»«3»«4»«5»«6»«7»«8».
```


Y se pueden **combinar** con otros caracteres dentro del mismo corchete:

| Quiero… | Escribo |
|---|---|
| letra o guion bajo | `[[:alpha:]_]` |
| dígito, punto o coma | `[[:digit:].,]` |
| cualquier cosa **menos** espacios | `[^[:space:]]` |
| letra o dígito o guion | `[[:alnum:]-]` |

### La ventaja de las clases: los acentos

```bash
printf 'ñ\né\nz\n7\n' | grep -o '[[:alpha:]]' | tr '\n' ' '
```

_Resultado:_

```text
ñ é z 
```


`[[:alpha:]]` entiende que `ñ` y `é` son letras. `[A-Za-z]` no (en modo `C.UTF-8`).

Comparación con las mayúsculas:

```bash
grep '^[A-Z]' palabras.txt | tr '\n' ' '; echo
grep '^[[:upper:]]' palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
Gato GATO Perro Casa Linux LINUX Ubuntu Debian Fedora 
Gato GATO Perro Casa Árbol Linux LINUX Ubuntu Debian Fedora 
```


La segunda lista incluye `Árbol` (con A acentuada), que `[A-Z]` se deja fuera.

### Clases que casi nadie conoce (por si caen en el examen)

Además de `[:clase:]` existen `[=a=]` (clase de equivalencia: "todas las variantes de la `a`") y `[.espacio.]` (símbolos de ordenación). Son tan raros que en la práctica nunca los verás; basta con saber que existen y que se escriben también dentro de un corchete exterior: `[[=a=]]`.

---

## 4.7 · El truco del `ps aux | grep` 🕵️

¿Recuerdas la trampa del capítulo 1? Al hacer `ps aux | grep sshd`, la lista de procesos incluye **el propio comando `grep sshd`** y por eso sale una línea de más. Veámoslo con una lista simulada:

```bash
printf 'root 902 sshd: /usr/sbin/sshd\nalumno 4100 grep sshd\nalumno 4101 grep [s]shd\n' | grep sshd
```

_Resultado_ (coincidencias entre « »):

```text
root 902 «sshd»: /usr/sbin/«sshd»
alumno 4100 grep «sshd»
```


Salen **dos** líneas: el servidor `sshd` (la buena) y la del propio `grep sshd` (la intrusa). El truco: escribir la `s` **entre corchetes**:

```bash
printf 'root 902 sshd: /usr/sbin/sshd\nalumno 4100 grep sshd\nalumno 4101 grep [s]shd\n' | grep '[s]shd'
```

_Resultado_ (coincidencias entre « »):

```text
root 902 «sshd»: /usr/sbin/«sshd»
alumno 4100 grep «sshd»
```


¡Magia! `[s]shd` **como patrón** significa "una `s`, luego `shd`" = **`sshd`**, así que encuentra el proceso real. Pero el texto del *comando* `grep [s]shd` que aparece en la lista de procesos contiene los caracteres `[`, `s`, `]`, `s`, `h`, `d`, que **no contienen la secuencia `sshd`** y por tanto no coincide consigo mismo. 🤯

(En `ps aux | grep '[s]shd'`, el `grep` ya no se ve a sí mismo.)

---

## 4.8 · 🏋️ Ejercicios

#### 🟢 Ejercicio 4.1 · Dos opciones en una casilla

Muestra las líneas de `palabras.txt` que contengan `gat` seguido de `a` **o** `o`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'gat[ao]' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gata»
«gato»s
«gato»
```


`[ao]` es una casilla con dos opciones. (Fíjate que `gatos` y `gatito`… `gatito` no sale porque tras `gat` hay una `i`.)
</details>


#### 🟢 Ejercicio 4.2 · Mayúscula o minúscula

Muestra las palabras `Perro` y `perro` (cualquiera de las dos) de `palabras.txt`, pero que **no** salgan `perra` ni `perrito`. Línea exacta.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[Pp]erro$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«perro»
«Perro»
```


`[Pp]` = P o p. Con `^…$` exigimos la palabra completa.
</details>


#### 🟢 Ejercicio 4.3 · Empiezan por vocal

Muestra las palabras que empiezan por una vocal minúscula.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[aeiou]' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«a»la
«o»so
«o»jo
«a»nilina
«a»aa
«a»a
«a»
«a»bc
«a»bcabc
«e»grep
```

</details>


#### 🟢 Ejercicio 4.4 · Acaban en vocal

Cuenta cuántas palabras de `palabras.txt` **acaban** en vocal minúscula.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '[aeiou]$' palabras.txt
```

_Resultado:_

```text
37
```

</details>


#### 🟢 Ejercicio 4.5 · Sin ninguna vocal

Muestra las palabras que **no** contienen ninguna vocal minúscula.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v '[aeiou]' palabras.txt
```

_Resultado:_

```text
GATO
LINUX
zsh
```


`-v` invierte el corchete. Solo `zsh`… y las palabras en mayúsculas `GATO` y `LINUX`, porque ahí las vocales son `A`, `O`, `I`, `U` (el corchete solo pedía minúsculas). Pruébalo con `-i` y verás cómo cambia.
</details>


#### 🟢 Ejercicio 4.6 · Con dígitos

Muestra las líneas de `frases.txt` que contengan algún dígito.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '[0-9]' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
Hoy es lunes, «1»«4» de octubre de «2»«0»«2»«4».
Tengo «3» gatos, «2» perros y «1»«5» peces.
El número de teléfono es «6»«1»«2»«3»«4»«5»«6»«7»«8».
```

</details>


#### 🟢 Ejercicio 4.7 · Empiezan por dígito

Muestra las líneas de `/etc/hosts` que empiezan por un dígito.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[0-9]' /etc/hosts
```

_Resultado_ (coincidencias entre « »):

```text
«1»27.0.0.1 localhost
«1»27.0.1.1 ubuntu-pc
«1»92.168.1.10   servidor.miempresa.com   servidor
«1»92.168.1.11   impresora.miempresa.com  impresora
«1»92.168.1.20   nas.miempresa.com        nas
«1»0.0.0.5       backup.miempresa.es      backup
```


Son las direcciones IPv4 (las IPv6 empiezan por `:` o `f`).
</details>


#### 🟢 Ejercicio 4.8 · Dos dígitos seguidos

¿Cuántas líneas de `numeros.txt` contienen **dos dígitos seguidos**?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '[0-9][0-9]' numeros.txt
```

_Resultado:_

```text
23
```


Dos casillas `[0-9]` seguidas = dos dígitos consecutivos.
</details>


#### 🟢 Ejercicio 4.9 · Un solo dígito

Muestra las líneas de `numeros.txt` que sean **exactamente un dígito** (y nada más).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[0-9]$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«0»
«7»
```

</details>


#### 🟢 Ejercicio 4.10 · Líneas con mayúscula inicial

Muestra las palabras de `palabras.txt` que empiezan por mayúscula (A-Z).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[A-Z]' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«G»ato
«G»ATO
«P»erro
«C»asa
«L»inux
«L»INUX
«U»buntu
«D»ebian
«F»edora
```


`Árbol` no sale: la `Á` con tilde no está entre la `A` y la `Z` en este modo. Con `[[:upper:]]` sí saldría.
</details>


#### 🟢 Ejercicio 4.11 · Los DNI "extranjeros"

Muestra las líneas de `dni.txt` que **empiezan por X, Y o Z**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[XYZ]' dni.txt
```

_Resultado_ (coincidencias entre « »):

```text
«X»1234567L
«Y»7654321F
«Z»0000000M
```

</details>


#### 🟢 Ejercicio 4.12 · Teléfonos móviles

Muestra las líneas de `telefonos.txt` que empiezan por **6 o 7** (móviles españoles).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[67]' telefonos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«6»12345678
«7»12345678
«6»123456789
«6»1234567
«6»12 34 56 78
«6»12-345-678
```


También salen números de 8 o 10 cifras, que no son válidos: lo arreglaremos en el capítulo 5 con `{9}`.
</details>


#### 🟢 Ejercicio 4.13 · Discos sdb y sdc

Muestra las líneas de `/etc/fstab` que empiezan por `/dev/sdb` o `/dev/sdc`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^/dev/sd[bc]' /etc/fstab
```

_Resultado_ (coincidencias entre « »):

```text
«/dev/sdb»1       /datos          ext4    defaults        0       2
«/dev/sdc»1       /backup         xfs     defaults,noatime 0      2
```

</details>


#### 🟢 Ejercicio 4.14 · Shells bash o zsh

Muestra los usuarios de `/etc/passwd` cuya shell sea `/bin/bash` o `/bin/zsh`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep ':/bin/[bz]' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
root:x:0:0:root:/root«:/bin/b»ash
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql«:/bin/b»ash
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno«:/bin/b»ash
ana:x:1001:1001:Ana Garcia,,,:/home/ana«:/bin/b»ash
luis:x:1002:1002:Luis Perez,,,:/home/luis«:/bin/z»sh
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro«:/bin/b»ash
```


`[bz]` = `b` o `z`: salen los usuarios con `/bin/bash` y el de `/bin/zsh`. Ojo: `[bz]` mira solo la **primera** letra tras `/bin/`, así que también cogería un hipotético `/bin/bzip` o `/bin/zzz`.
</details>


#### 🟡 Ejercicio 4.15 · Todo menos dígitos

Muestra las líneas de `numeros.txt` que contengan **algún carácter que no sea un dígito**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '[^0-9]' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«-»5
«-»273
«+»8
3«.»14
0«.»5
«.»5
10«.»
1«,»5
… (y 16 líneas más)
```


`[^0-9]` = "cualquier carácter que no sea un dígito". Salen las que tienen signo, punto, coma, letras, etc.
</details>


#### 🟡 Ejercicio 4.16 · Solo dígitos

Muestra las líneas de `numeros.txt` formadas **solo por dígitos** (sin ningún otro carácter). Usa doble negación.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v '[^0-9]' numeros.txt
```

_Resultado:_

```text
0
7
42
100
1000
12345
2024
007
612345678
```


"Que no tengan ningún carácter no-dígito". En el capítulo 5 lo harás directamente con `^[0-9]*$`.
</details>


#### 🟡 Ejercicio 4.17 · Usuarios de 4 letras (bien hecho)

Muestra los usuarios de `/etc/passwd` cuyo **nombre tenga exactamente 4 caracteres**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[^:][^:][^:][^:]:' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root:»x:0:0:root:/root:/bin/bash
«sync:»x:4:65534:sync:/bin:/bin/sync
«mail:»x:8:8:mail:/var/mail:/usr/sbin/nologin
«news:»x:9:9:news:/var/spool/news:/usr/sbin/nologin
«uucp:»x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
«list:»x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
«_apt:»x:42:65534::/nonexistent:/usr/sbin/nologin
«sshd:»x:105:65534::/run/sshd:/usr/sbin/nologin
«luis:»x:1002:1002:Luis Perez,,,:/home/luis:/bin/zsh
```


Cuatro casillas "cualquier cosa menos `:`" y luego el `:` que acaba el nombre. A diferencia de `^....:`, esta no coincide con `lp`.
</details>


#### 🟡 Ejercicio 4.18 · Usuarios de 2 letras

Muestra los usuarios cuyo nombre tenga **exactamente 2 caracteres**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[^:][^:]:' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«lp:»x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
```


Aquí solo sale `lp`. ¿Y si uno tuviera 3 letras? `^[^:][^:]:` exige que a las 2 casillas le siga ya el `:`; un nombre de 3 letras tiene el `:` en tercer lugar y no coincidiría.
</details>


#### 🟡 Ejercicio 4.19 · Líneas activas con un solo patrón

Con un solo patrón (sin `-v` ni `-e`) muestra las líneas de `/etc/hosts` que **no estén vacías ni empiecen por `#`**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[^#]' /etc/hosts
```

_Resultado:_

```text
127.0.0.1 localhost
127.0.1.1 ubuntu-pc
192.168.1.10   servidor.miempresa.com   servidor
192.168.1.11   impresora.miempresa.com  impresora
192.168.1.20   nas.miempresa.com        nas
10.0.0.5       backup.miempresa.es      backup
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```


`^[^#]` = "al principio, un carácter que no sea `#`". Una línea vacía no tiene primer carácter, así que no coincide.
</details>


#### 🟡 Ejercicio 4.20 · El truco del corchete para el punto

Escribe sin barras invertidas una regex que encuentre `192.168` **con punto de verdad** en `ips.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '192[.]168' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168».1.1
«192.168».1.256
«192.168».1
«192.168»..1
«192.168».001.001
Gateway «192.168».0.254 activo
«192.168».0.1:8080
«192.168».1.0/24
```


Dentro de un corchete el `.` es un punto normal. Hay otras formas, como `192\.168`.
</details>


#### 🟡 Ejercicio 4.21 · Símbolos monetarios y porcentajes

Muestra las líneas de `numeros.txt` que contengan alguno de estos símbolos: `$`, `%`, `€`, `#`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '[$%€#]' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«#»123
50«%»
«$»99
99.99«€»
```


El `$` dentro del corchete es un dólar normal (no "fin de línea").
</details>


#### 🟡 Ejercicio 4.22 · Separadores de fecha

Muestra las líneas de `fechas.txt` que contengan alguno de estos separadores: `-`, `/` o `.`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '[-/.]' fechas.txt
```

_Resultado_ (coincidencias entre « »):

```text
2024«-»03«-»15
15«/»03«/»2024
15«-»03«-»2024
31«/»12«/»1999
01«/»01«/»2000
32«/»13«/»2024
2024«/»03«/»15
24«-»3«-»5
15«.»03«.»24
1999«-»12«-»31T23:59:59
Hoy es 2024«-»10«-»14 y son las 18:45:07 en punto
Nacio el 07«/»11«/»1985 en Sevilla
```


El `-` va **al principio** del corchete para que sea un guion normal y no un rango. El `.` y el `/` son normales dentro del corchete.
</details>


#### 🟡 Ejercicio 4.23 · La trampa de la barra

Predice y comprueba: ¿qué líneas encuentra `a[\.]b` entre `a\b`, `a.b` y `acb`?

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a\\b\na.b\nacb\n' | grep 'a[\.]b'
```

_Resultado_ (coincidencias entre « »):

```text
«a\b»
«a.b»
```


Encuentra `a\b` y `a.b`. Dentro del corchete `\` no escapa: `[\.]` es "barra o punto".
</details>


#### 🟡 Ejercicio 4.24 · Un `]` dentro de un corchete

Haz que `grep` encuentre las líneas que tengan un `]` **o** una `a` entre `x` e `y`, en `x]y`, `xay`, `xby`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'x]y\nxay\nxby\n' | grep 'x[]a]y'
```

_Resultado_ (coincidencias entre « »):

```text
«x]y»
«xay»
```


El `]` va **primero** en el corchete para que no lo cierre.
</details>


#### 🟡 Ejercicio 4.25 · Letras de verdad

Muestra con `-o` **solo las letras** de la cadena `canción 2024!` (una por línea, sin números ni signos).

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'canción 2024!' | grep -o '[[:alpha:]]'
```

_Resultado:_

```text
c
a
n
c
i
ó
n
```


`[[:alpha:]]` incluye la `ó`. `-o` imprime **solo la parte que coincide**, una por línea. (`-o` lo estudiamos a fondo en el capítulo 9.)
</details>


#### 🟡 Ejercicio 4.26 · Mayúsculas con acentos

Muestra las palabras que empiezan por **mayúscula**, incluyendo las que llevan tilde.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[[:upper:]]' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«G»ato
«G»ATO
«P»erro
«C»asa
«Á»rbol
«L»inux
«L»INUX
«U»buntu
«D»ebian
«F»edora
```


Con `[[:upper:]]` sale `Árbol`, que `[A-Z]` se dejaba fuera.
</details>


#### 🟡 Ejercicio 4.27 · Líneas que empiezan con espacio

Muestra, con número de línea, las líneas de `frases.txt` que **empiezan** por un espacio o un tabulador.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -n '^[[:blank:]]' frases.txt
```

_Resultado:_

```text
17:   Esta frase empieza con tres espacios.
19:	Esta empieza con un tabulador.
```


`[[:blank:]]` = espacio o tabulador (las dos líneas: una con tres espacios y otra con un tabulador).
</details>


#### 🟡 Ejercicio 4.28 · Contraseñas con signos de puntuación

Muestra las líneas de `contrasenas.txt` que contengan **algún signo de puntuación**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '[[:punct:]]' contrasenas.txt
```

_Resultado_ (coincidencias entre « »):

```text
Password1«!»
S3gura«!»2024
corta1A«!»
sinnumeros«!»A
SINMINUSCULAS1«!»
sinmayusculas1«!»
Mi«_»Clave«-»Segura«_»99
a b c 1 A «!»
```

</details>


#### 🟡 Ejercicio 4.29 · El error clásico

Escribe `grep '[:digit:]' numeros.txt` y explica el mensaje de error.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '[:digit:]' numeros.txt
```

_Resultado:_

```text
grep: character class syntax is [[:space:]], not [:space:]
```


Faltan los corchetes exteriores. Lo correcto es `[[:digit:]]`. (Sin ese segundo par, `[:digit:]` sería el conjunto de los caracteres `: d i g t`.)
</details>


#### 🟡 Ejercicio 4.30 · Sin ver el propio grep

Dada la lista simulada de procesos, muestra solo la línea de `sshd` real **sin** la del propio `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'root 902 sshd: /usr/sbin/sshd\nalumno 4100 grep sshd\n' | grep '[s]shd'
```

_Resultado_ (coincidencias entre « »):

```text
root 902 «sshd»: /usr/sbin/«sshd»
alumno 4100 grep «sshd»
```


Con `[s]shd` el propio comando `grep [s]shd` ya no coincide con el patrón.
</details>


#### 🟡 Ejercicio 4.31 · Matrículas, versión simple

Muestra las líneas de `matriculas.txt` formadas por **4 dígitos, un espacio y 3 letras mayúsculas**, y nada más.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[0-9][0-9][0-9][0-9] [A-Z][A-Z][A-Z]$' matriculas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«1234 BCD»
«0000 BBB»
«9999 ZZZ»
«1234 ABC»
```


Un patrón largo pero claro: 4 casillas de dígito, un espacio, 3 casillas de mayúscula. Salen 4 líneas (en el capítulo 5 verás cómo abreviarlo con `{4}` y `{3}`).
</details>


#### 🔴 Ejercicio 4.32 · Matrículas, versión realista

Las matrículas españolas actuales **no usan vocales ni `Ñ` ni `Q`**. Filtra `matriculas.txt` para quedarte solo con las válidas: 4 dígitos, espacio, 3 letras de `BCDFGHJKLMNPRSTVWXYZ`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[0-9][0-9][0-9][0-9] [BCDFGHJKLMNPRSTVWXYZ][BCDFGHJKLMNPRSTVWXYZ][BCDFGHJKLMNPRSTVWXYZ]$' matriculas.txt
```

_Resultado_ (coincidencias entre « »):

```text
«1234 BCD»
«0000 BBB»
«9999 ZZZ»
```


`1234 ABC` (que antes pasaba) ahora se descarta: la `A` es vocal y no está en la lista. Un clásico ejemplo de "lista blanca" con corchetes.
</details>


#### 🔴 Ejercicio 4.33 · Horas de la mañana en el syslog

Muestra las líneas de `/var/log/syslog` del **día 5 de noviembre** entre las **08:00 y las 09:59**. Fíjate en que el día tiene **dos espacios** (`Nov  5`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^Nov  5 0[89]:' /var/log/syslog | cut -c1-90
```

_Resultado:_

```text
Nov  5 08:17:01 ubuntu-pc CRON[8764]: (root) CMD (cd / && run-parts --report /etc/cron.hou
Nov  5 08:30:12 ubuntu-pc systemd-logind[610]: New session 2 of user alumno.
Nov  5 08:30:12 ubuntu-pc systemd[1]: Started session-2.scope - Session 2 of User alumno.
Nov  5 09:10:33 ubuntu-pc systemd[1]: Starting apt-daily-upgrade.service - Daily apt upgra
Nov  5 09:11:02 ubuntu-pc systemd[1]: Finished apt-daily-upgrade.service - Daily apt upgra
Nov  5 09:17:01 ubuntu-pc CRON[6402]: (root) CMD (cd / && run-parts --report /etc/cron.hou
Nov  5 09:35:48 ubuntu-pc kernel: [88848.019500] usb 1-1: new high-speed USB device number
Nov  5 09:35:48 ubuntu-pc kernel: [88848.020800] usb 1-1: Product: Cruzer Blade
Nov  5 09:35:49 ubuntu-pc kernel: [88849.022100] sd 3:0:0:0: [sdb] Attached SCSI removable
```


`0[89]` = hora `08` o `09`. (He añadido `cut -c1-90` solo para que las líneas largas no desborden la página.)
</details>


#### 🔴 Ejercicio 4.34 · Hasta mediodía: dos rangos

Lo mismo, pero entre las **08:00 y las 12:59**. Cuidado: ya no basta con un solo corchete.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -e '^Nov  5 0[89]:' -e '^Nov  5 1[0-2]:' /var/log/syslog | cut -c1-90
```

_Resultado:_

```text
Nov  5 08:17:01 ubuntu-pc CRON[8764]: (root) CMD (cd / && run-parts --report /etc/cron.hou
Nov  5 08:30:12 ubuntu-pc systemd-logind[610]: New session 2 of user alumno.
Nov  5 08:30:12 ubuntu-pc systemd[1]: Started session-2.scope - Session 2 of User alumno.
Nov  5 09:10:33 ubuntu-pc systemd[1]: Starting apt-daily-upgrade.service - Daily apt upgra
Nov  5 09:11:02 ubuntu-pc systemd[1]: Finished apt-daily-upgrade.service - Daily apt upgra
Nov  5 09:17:01 ubuntu-pc CRON[6402]: (root) CMD (cd / && run-parts --report /etc/cron.hou
Nov  5 09:35:48 ubuntu-pc kernel: [88848.019500] usb 1-1: new high-speed USB device number
Nov  5 09:35:48 ubuntu-pc kernel: [88848.020800] usb 1-1: Product: Cruzer Blade
Nov  5 09:35:49 ubuntu-pc kernel: [88849.022100] sd 3:0:0:0: [sdb] Attached SCSI removable
Nov  5 10:12:19 ubuntu-pc kernel: [91039.023400] Out of memory: Killed process 2345 (java)
Nov  5 10:12:19 ubuntu-pc systemd[1]: session-2.scope: A process of this unit has been kil
Nov  5 10:17:01 ubuntu-pc CRON[7413]: (root) CMD (cd / && run-parts --report /etc/cron.hou
Nov  5 10:22:50 ubuntu-pc systemd[1]: Started motd-news.service - Message of the Day.
Nov  5 11:08:12 ubuntu-pc systemd[1]: Started e2scrub_all.service - Online ext4 Metadata C
Nov  5 11:17:01 ubuntu-pc CRON[9239]: (root) CMD (cd / && run-parts --report /etc/cron.hou
Nov  5 11:40:02 ubuntu-pc kernel: [96302.024700] EXT4-fs error (device sdb1): ext4_find_en
Nov  5 11:40:02 ubuntu-pc kernel: [96302.026000] blk_update_request: I/O error, dev sdb, s
Nov  5 12:03:55 ubuntu-pc kernel: [97735.027300] python3[3321]: segfault at 0 ip 00007f3c1
Nov  5 12:17:01 ubuntu-pc CRON[4173]: (root) CMD (cd / && run-parts --report /etc/cron.hou
Nov  5 12:20:00 ubuntu-pc systemd[1]: Reloading.
… (y 1 líneas más)
```


"08, 09" se cubre con `0[89]` y "10, 11, 12" con `1[0-2]`; dos casos distintos, así que dos `-e` (O). En el [capítulo 6](06-grupos-alternancia.md) lo unirás en **un solo patrón** con `\(0[89]\|1[0-2]\)`.
</details>


#### 🔴 Ejercicio 4.35 · Puertos de 5 cifras

Muestra las líneas de `/var/log/auth.log` que contengan `port` seguido de un número de **5 cifras** (y que no sea más largo).

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'port [0-9][0-9][0-9][0-9][0-9] ' /var/log/auth.log | cut -c1-110
```

_Resultado:_

```text
Nov  4 09:02:10 ubuntu-pc sshd[3990]: Accepted publickey for alumno from 192.168.1.50 port 52144 ssh2: ED25519
Nov  4 13:44:02 ubuntu-pc sshd[1672]: Failed password for invalid user admin from 203.0.113.45 port 40022 ssh2
Nov  4 13:44:05 ubuntu-pc sshd[2205]: Failed password for invalid user admin from 203.0.113.45 port 40022 ssh2
Nov  4 13:44:09 ubuntu-pc sshd[3446]: Failed password for invalid user admin from 203.0.113.45 port 40022 ssh2
Nov  4 13:44:09 ubuntu-pc sshd[670]: error: maximum authentication attempts exceeded for invalid user admin fr
Nov  4 13:51:19 ubuntu-pc sshd[4461]: Failed password for invalid user test from 203.0.113.45 port 41333 ssh2
Nov  4 13:51:21 ubuntu-pc sshd[6339]: Connection closed by invalid user test 203.0.113.45 port 41333 [preauth]
Nov  4 13:58:42 ubuntu-pc sshd[1934]: Failed password for invalid user oracle from 198.51.100.23 port 51100 ss
Nov  4 14:02:11 ubuntu-pc sshd[3805]: Failed password for root from 198.51.100.23 port 51234 ssh2
Nov  4 14:02:14 ubuntu-pc sshd[5256]: Failed password for root from 198.51.100.23 port 51234 ssh2
Nov  4 14:02:16 ubuntu-pc sshd[4520]: Connection closed by authenticating user root 198.51.100.23 port 51234 [
Nov  5 08:30:08 ubuntu-pc sshd[8497]: Accepted password for alumno from 192.168.1.50 port 53871 ssh2
Nov  5 10:55:31 ubuntu-pc sshd[9180]: Accepted password for luis from 192.168.1.51 port 40960 ssh2
Nov  5 11:10:03 ubuntu-pc sshd[7743]: Failed password for luis from 192.168.1.51 port 40990 ssh2
Nov  5 11:10:07 ubuntu-pc sshd[7397]: Accepted password for luis from 192.168.1.51 port 40990 ssh2
Nov  5 15:12:33 ubuntu-pc sshd[5556]: Failed password for invalid user postgres from 203.0.113.99 port 33210 s
Nov  5 15:12:36 ubuntu-pc sshd[5161]: Failed password for invalid user postgres from 203.0.113.99 port 33210 s
Nov  5 15:12:38 ubuntu-pc sshd[2824]: Failed password for invalid user ubuntu from 203.0.113.99 port 33214 ssh
Nov  6 07:59:10 ubuntu-pc sshd[3801]: Accepted publickey for ana from 192.168.1.60 port 61004 ssh2: RSA SHA256
Nov  6 09:15:42 ubuntu-pc sshd[9239]: Failed password for invalid user admin from 203.0.113.45 port 42001 ssh2
```


Hay un espacio al final del patrón para asegurarnos de que el número termina ahí (no hay una sexta cifra). Con `{5}` (capítulo 5) quedará mucho más bonito.
</details>


#### 🔴 Ejercicio 4.36 · Contraseña "fuerte" con varias reglas

Muestra las líneas de `contrasenas.txt` que tengan **mayúscula, minúscula, dígito y signo de puntuación** a la vez. (Pista: una tubería de varios `grep`; en el capítulo 13 lo harás con uno solo.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep '[[:upper:]]' contrasenas.txt | grep '[[:lower:]]' | grep '[[:digit:]]' | grep '[[:punct:]]'
```

_Resultado:_

```text
Password1!
S3gura!2024
corta1A!
Mi_Clave-Segura_99
a b c 1 A !
```


Cada `grep` aplica **una regla** y pasa solo las líneas que la cumplen: la tubería funciona como un "Y".
</details>


#### ⚫ Ejercicio 4.37 · Sin mayúsculas ni números

Muestra las líneas de `palabras.txt` que contienen **solo letras minúsculas** (de la a a la z), sin mayúsculas, números ni símbolos. Pista: doble negación.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v '[^a-z]' palabras.txt | tr '\n' ' '
```

_Resultado:_

```text
gato gata gatito gatos perro perra perrito casa casas caso cosa cama camino ala oso ojo reconocer anilina radar rotor sol sal mar luz pan paz mesa silla libro libreta hola hoola hooola aaa aa a abc abcabc banana mississippi programa programador linux bash zsh python perl grep egrep fgrep gato casa 
```


"Líneas en las que no hay ningún carácter que no sea una minúscula" = líneas formadas solo por minúsculas `a-z`. Observa cómo `caña`, `árbol` y compañía **quedan fuera**: con `C.UTF-8` el `ñ` y la `á` no están en `a-z`. (Con un `LC_ALL=en_US.UTF-8` el resultado cambiaría: ¡prueba!)
</details>


---

## ✅ Resumen del capítulo 4

| Escribo | Significa |
|---|---|
| `[abc]` | **uno** de a, b, c |
| `[a-z]` `[0-9]` | un carácter del **rango** |
| `[^abc]` | un carácter que **no** sea a, b, c |
| `[[:digit:]]` `[[:alpha:]]`… | **clases POSIX** (¡doble corchete!) |
| `[.]` `[*]` `[$]` | los símbolos **pierden** su poder dentro del corchete |
| `[]a]` | un `]` se pone **el primero** |
| `[a-]` `[-a]` | un `-` se pone **al principio o al final** |
| `[\.]` | ¡Ojo!: aquí `\` es una barra normal, no un escudo |

**El `^`:** ancla fuera (`^a`), negación si va primero dentro (`[^a]`), normal en cualquier otro sitio (`[a^]`).

➡️ **Siguiente parada:** [Capítulo 5](05-repeticiones.md): cómo decir *"esto, repetido varias veces"* con `*`, `+`, `?` y `{n,m}`… y por fin, el misterio de **la coma**.

---
⬅️ [Capítulo 3 · El punto y las anclas: `.` `^` `$` `\`](03-punto-y-anclas.md) · 🏠 [Índice](README.md)
