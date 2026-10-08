# Capítulo 5 · Repetir: `*` `+` `?` `{n,m}` y el misterio de la coma

> 🎯 **Objetivo:** decir *"esto, repetido varias veces"*. Con los **cuantificadores** pasas de patrones de 3 letras a patrones que describen números de teléfono, DNI, fechas… Y descubrirás **para qué sirve la coma**.
>
> 📘 **LPIC-1:** 103.7 — *"quantifiers"*, regex básicas vs. extendidas.
>
> 🧪 `cd ~/lab-regex`

---

## 5.1 · La pegatina de "cuántas veces"

Hasta ahora, cada trocito del patrón significaba **un** carácter: `a` = una `a`, `.` = un carácter, `[0-9]` = un dígito. Para buscar un número de 8 cifras tenías que escribir `[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]`. ¡Una paliza!

Un **cuantificador** es una **pegatina** que pegas **detrás** de un trozo del patrón para decir *cuántas veces* se repite:

```text
[0-9]      →  un dígito
[0-9]*     →  dígitos, cero o más veces
[0-9]+     →  dígitos, una o más veces
[0-9]?     →  un dígito, opcional (0 o 1 vez)
[0-9]{8}   →  exactamente 8 dígitos
```

> 🎯 **Regla de oro:** el cuantificador se aplica **solo al elemento inmediatamente anterior**. Ese "elemento" puede ser un **carácter** (`a`), un **punto** (`.`), un **corchete** (`[0-9]`) o —en el capítulo 6— un **grupo** `(…)`.
>
> `ab*` = una `a` seguida de **cero o más `b`** (¡no "cero o más `ab`"!).

---

## 5.2 · El asterisco `*`: cero o más

`*` significa **"el elemento anterior, cero o más veces"**.

```text
ab*c
```

| Línea | ¿Coincide con `ab*c`? | Motivo |
|---|---|---|
| `ac` | ✅ | cero `b` |
| `abc` | ✅ | una `b` |
| `abbbbc` | ✅ | cuatro `b` |
| `adc` | ❌ | hay una `d` en medio |

```bash
printf 'ac\nabc\nabbbbc\nadc\n' | grep 'ab*c'
```

_Resultado_ (coincidencias entre « »):

```text
«ac»
«abc»
«abbbbc»
```


> ⚠️ **"Cero" también cuenta.** Por eso `a*` coincide con **cualquier línea** (aunque no tenga ninguna `a`: tiene "cero `a`", y vale). Ya lo vimos en el capítulo 2. Para exigir **al menos una**, usa `aa*` (una `a` seguida de cero o más `a`) o el `+` de más abajo.

### Con la `o` alargada

```bash
grep 'ho*la' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«hola»
«hoola»
«hooola»
```


`h` + (ninguna, una o muchas `o`) + `la`: `hola`, `hoola`, `hooola`.

### El rey de los comodines: `.*`

Combinando `.` ("cualquier carácter") con `*` ("cero o más veces") obtenemos **`.*` = "cualquier cosa, de cualquier longitud (incluso nada)"**. Es el comodín más usado de todas las regex:

```bash
grep 'El.*perro' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
«El perro» come carne.
«El el perro» ladra mucho.
```


"`El`, luego lo que sea, y luego `perro`". Con `.*` entre dos pistas haces un **"Y en orden"** con **un solo `grep`**:

```bash
grep 'Failed.*root' /var/log/auth.log | cut -c1-100
```

_Resultado:_

```text
Nov  4 14:02:11 ubuntu-pc sshd[3805]: Failed password for root from 198.51.100.23 port 51234 ssh2
Nov  4 14:02:14 ubuntu-pc sshd[5256]: Failed password for root from 198.51.100.23 port 51234 ssh2
```


(¡Y esto es lo que en el capítulo 1 hacíamos con dos `grep` en tubería!)

> ⚠️ **No confundas** `.*` de las regex con el `*` de los ficheros. En la terminal `*` = "cualquier cosa". En una regex el `*` **necesita** algo delante a quien repetir; `.*` es `.` (un carácter cualquiera) repetido.

### El `*` con corchetes: números y espacios

```bash
printf '12\n\nab\n' | grep -c '^[0-9]*$'
printf '12\n\nab\n' | grep -c '^[0-9][0-9]*$'
```

_Resultado:_

```text
2
1
```


- `^[0-9]*$` = línea formada solo por dígitos **o vacía** (2 líneas: `12` y la vacía).
- `^[0-9][0-9]*$` = al menos **un** dígito (solo `12`).

Y con espacios, ¡por fin cazamos la línea que "parecía vacía"!

```bash
grep -n '^ *$' conf-ejemplo.conf
```

_Resultado:_

```text
3:
5:
11:
17:
18:   
```


Las líneas 3, 5, 11, 17 (vacías) **y la 18** (tres espacios): `^ *$` = "desde el principio, cero o más espacios, hasta el final". Mejor aún con la clase POSIX, que también cubre tabuladores:

```bash
grep -n '^[[:space:]]*$' conf-ejemplo.conf
```

_Resultado:_

```text
3:
5:
11:
17:
18:   
```


---

## 5.3 · `+` y `?` — y la guerra de las barras

| Cuantificador | Significado | Ejemplo |
|---|---|---|
| `*` | **0 o más** | `ab*c` → ac, abc, abbc… |
| `+` | **1 o más** | `ab+c` → abc, abbc… (no `ac`) |
| `?` | **0 o 1** (opcional) | `colou?r` → color, colour |

Pero atención, que aquí viene **la complicación más famosa del examen**. Existen dos "sabores" de expresiones regulares:

| | **BRE** (*Basic*) → `grep` normal | **ERE** (*Extended*) → `grep -E` |
|---|---|---|
| `*` | `*` | `*` |
| uno o más | `\+` | `+` |
| opcional | `\?` | `?` |
| repetición | `\{n,m\}` | `{n,m}` |
| grupo | `\(…\)` | `(…)` |

*(La "alternativa" —el "o" con la barra vertical— y los grupos los vemos en el [capítulo 6](06-grupos-alternancia.md); la comparación completa BRE/ERE, en el [capítulo 8](08-bre-vs-ere.md).)*

La regla de oro, **al revés** en cada sabor:

- En **BRE** (`grep` normal): `+ ? { } ( ) |` son **letras normales**. Para darles superpoder hay que ponerles **barra**: `\+ \? \{ \} \( \) \|`.
- En **ERE** (`grep -E`): esos mismos símbolos **ya tienen superpoder**. Para tratarlos como letras normales hay que ponerles barra.

```bash
printf 'hla\nhola\nhoola\n' | grep 'ho\+la'
# Otra forma equivalente:
printf 'hla\nhola\nhoola\n' | grep -E 'ho+la'
```

_Resultado_ (coincidencias entre « »):

```text
«hola»
«hoola»
```


Las dos formas dan lo mismo: `ho\+la` (básica) = `ho+la` (extendida). Y en BRE, un `+` sin barra es solo un más:

```bash
printf 'a+b\naab\n' | grep 'a+b'
```

_Resultado_ (coincidencias entre « »):

```text
«a+b»
```


> 🧠 **Truco mental:** *en el modo básico, "lo básico" (letras) es normal y lo avanzado necesita barra; en el modo extendido todo lo avanzado funciona sin barra.* A partir de aquí, **en las soluciones usaré casi siempre `grep -E`** porque se lee mucho mejor. Pero tienes que saber las dos.

### El `?` — "opcional"

```bash
printf 'color\ncolour\ncolouur\n' | grep -E 'colou?r'
```

_Resultado_ (coincidencias entre « »):

```text
«color»
«colour»
```


`u?` = una `u` opcional (0 o 1): salen `color` y `colour`, pero no `colouur`.

Aplicación real:

```bash
grep -E 'https?://' urls.txt
```

_Resultado_ (coincidencias entre « »):

```text
«http://»www.ejemplo.com
«https://»www.ejemplo.com/
«https://»cas-training.com/cursos/linux?id=5&lang=es
«http://»localhost:8080/index.html
«https://»192.168.1.10:8443/admin
«https://»ejemplo.com/ruta con espacios
Visita «https://»github.com/TheBillBull y «http://»ejemplo.org/pagina.html hoy
```


`https?://` = `http` + una `s` opcional + `://`. Cubre `http://` y `https://`.

---

## 5.4 · Las llaves `{n,m}`: contar con precisión (¡y la coma!)

Las llaves dicen **exactamente cuántas veces**:

| Escribo (ERE) | Escribo (BRE) | Significa |
|---|---|---|
| `a{3}` | `a\{3\}` | **exactamente** 3 veces |
| `a{2,}` | `a\{2,\}` | **2 o más** veces |
| `a{2,5}` | `a\{2,5\}` | **de 2 a 5** veces |
| `a{,5}` | `a\{,5\}` | **hasta 5** veces (0 a 5) *(extensión de GNU)* |

```bash
grep -E 'ho{2,3}la' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«hoola»
«hooola»
```


`hoola` (2 `o`) y `hooola` (3 `o`), no `hola` (1 `o`).

```bash
grep -E 'ho{3,}la' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«hooola»
```


Solo `hooola` (3 o más `o`).

### 🕵️ El misterio de la coma

Has visto que dentro de las llaves hay una coma, y antes dije que una coma es "una letra normal". ¿Qué pasa? Pues que **la coma tiene un papel distinto según DÓNDE esté**:

| Dónde está la coma | Qué es |
|---|---|
| En texto normal: `a,b` | Una **coma normal** (busca una coma) |
| Dentro de un corchete: `[a,b]` | Una **coma normal** (la lista es: `a`, `,` o `b`) |
| **Dentro de unas llaves** `{2,5}` | Un **separador** entre *mínimo* y *máximo* |

Y **dentro de las llaves** (donde la coma es separador) hay tres casos, según qué pongas a cada lado:

```text
{3}      sin coma         → exactamente 3
{3,}     coma, sin máximo → 3 o más
{3,5}    coma con ambos   → de 3 a 5
{,5}     coma, sin mínimo → de 0 a 5 (GNU)
```

> ⚠️ **¡Sin espacios dentro de las llaves!** `{2, 5}` (con espacio) **no es una repetición**: `grep` la toma como texto literal.

```bash
printf 'aaa\naa\na{2, 5}\n' | grep -E 'a{2, 5}'
```

_Resultado_ (coincidencias entre « »):

```text
«a{2, 5}»
```


Mira: solo ha coincidido la línea que **contenía literalmente** `a{2, 5}`. Un espacio y la repetición desaparece.

Y recuerda que **fuera** de las llaves, la coma es una coma de verdad. Por ejemplo, una cifra con **coma decimal** (a la española):

```bash
grep -E '^[0-9]+,[0-9]+$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«1,5»
«3,14»
```


`[0-9]+` + coma + `[0-9]+`. ¡La coma aquí no tiene nada de especial!

Y con punto **o** coma (el corchete `[.,]` contiene las dos opciones, ambas "normales" dentro del corchete):

```bash
grep -E '^[0-9]+[.,][0-9]+$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«3.14»
«0.5»
«1,5»
«3,14»
```


---

## 5.5 · Voraz (*greedy*): los cuantificadores se comen todo lo que pueden

Los cuantificadores son **golosos**: intentan coger **lo máximo posible**. Mira este ejemplo con HTML, donde queremos extraer las **etiquetas** (`<b>`, `</b>`…):

```bash
sed -n 4,5p html.txt
```

_Resultado:_

```text
<p>Un parrafo con <b>negrita</b> y <i>cursiva</i> dentro.</p>
<a href="https://www.ejemplo.com">Enlace uno</a> y <a href="http://otro.org/pagina">Enlace dos</a>
```


Esas son las líneas 4 y 5 de `html.txt` (con `sed -n 4,5p` mostramos solo esas dos). Ahora intentamos sacar las etiquetas con `<.*>` ("un `<`, lo que sea, un `>`"); la opción `-o` imprime **solo lo que coincide**:

```bash
sed -n 4,5p html.txt | grep -o '<.*>'
```

_Resultado:_

```text
<p>Un parrafo con <b>negrita</b> y <i>cursiva</i> dentro.</p>
<a href="https://www.ejemplo.com">Enlace uno</a> y <a href="http://otro.org/pagina">Enlace dos</a>
```


¡Ha devuelto **las líneas enteras**! Porque `.*` es voraz: se comió **todo desde el primer `<` hasta el último `>`** de cada línea, en vez de parar en el primer `>`.

La solución de siempre: en lugar de "cualquier cosa" (`.*`), decir **"cualquier cosa que no sea `>`"** (`[^>]*`):

```bash
sed -n 4,5p html.txt | grep -o '<[^>]*>'
```

_Resultado:_

```text
<p>
<b>
</b>
<i>
</i>
</p>
<a href="https://www.ejemplo.com">
</a>
<a href="http://otro.org/pagina">
</a>
```


Ahora cada etiqueta sale por separado, porque `[^>]*` **no puede cruzar** un `>`. Este patrón —`<[^>]*>`, `"[^"]*"`, `\([^)]*\)`— es una de las armas más importantes de la caja de herramientas.

---

## 5.6 · Recetas de la vida real

Con lo que sabes puedes describir formatos muy típicos:

| Formato | Regex (ERE) |
|---|---|
| DNI (8 dígitos + letra) | `^[0-9]{8}[A-Z]$` |
| Móvil español (9 dígitos, 6 o 7 al inicio) | `^[67][0-9]{8}$` |
| Matrícula (4 números + 3 consonantes) | `^[0-9]{4} [BCDFGHJKLMNPRSTVWXYZ]{3}$` |
| Hora `hh:mm:ss` | `[0-9]{2}:[0-9]{2}:[0-9]{2}` |
| Color hexadecimal de 6 cifras | `#[0-9a-fA-F]{6}` |
| Año de cuatro cifras | `[0-9]{4}` |
| Línea con comentario con sangría | `^[[:space:]]*#` |
| Línea vacía o solo con espacios | `^[[:space:]]*$` |

---

## 5.7 · Arreglamos las trampas del capítulo 3

**Trampa 2: espacios invisibles al final.** Ya sabes cómo cazarlos (¡y quitarlos de la ecuación!):

```bash
grep -nE '[[:space:]]+$' frases.txt | cat -A
```

_Resultado:_

```text
18:Esta frase termina con espacios.   $
```


`[[:space:]]+$` = "uno o más espacios en blanco justo antes del final". Solo la línea 18 los tiene. Y para aceptar frases acabadas en punto **con o sin espacios detrás**:

```bash
grep -n 'espacios\.[[:space:]]*$' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
17:   Esta frase empieza con tres «espacios.»
18:Esta frase termina con «espacios.   »
```


**Trampa 3: finales de línea de Windows.**

```bash
grep -c 'mundo$' windows.txt
grep -c 'mundo[[:space:]]*$' windows.txt
```

_Resultado:_

```text
0
1
```


`[[:space:]]*` absorbe el `\r` invisible (el retorno de carro cuenta como "espacio en blanco"), y ahora `mundo$` sí coincide. También puedes localizar los `\r` directamente con la sintaxis de bash `$'\r'`:

```bash
grep -c $'\r$' windows.txt
```

_Resultado:_

```text
3
```


> ⚠️ En `grep`, **`\r` no significa "retorno de carro"** (esa escritura solo la entiende `bash` en `$'\r'`, o `grep -P`).

---

## 5.8 · 🏋️ Ejercicios

#### 🟢 Ejercicio 5.1 · Ceros, unos o muchos

Muestra las palabras de `palabras.txt` que empiecen por `h`, luego **una o más** `o`, y acaben en `la`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^ho+la$' palabras.txt
# Otra forma equivalente:
grep '^ho\+la$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«hola»
«hoola»
«hooola»
```


`o+` = "una o más". Con `+` descartamos una hipotética `hla` (cero `o`). Las dos escrituras (ERE y BRE) son equivalentes.
</details>


#### 🟢 Ejercicio 5.2 · El plural opcional

Muestra las líneas de `palabras.txt` que sean **exactamente** `gato` o `gatos`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex 'gatos?' palabras.txt
# Otra forma equivalente:
grep -x 'gatos\?' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gatos»
«gato»
```


`s?` = una `s` opcional, y `-x` exige que la línea entera encaje. (Salen `gato`, `gatos` y el `gato` repetido.)
</details>


#### 🟢 Ejercicio 5.3 · Dígitos o vacío

Cuenta las líneas de `numeros.txt` formadas **solo por dígitos** (ni una más).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^[0-9]+$' numeros.txt
# Otra forma equivalente:
grep -c '^[0-9][0-9]*$' numeros.txt
```

_Resultado:_

```text
9
```


`^[0-9]+$`: desde el principio, uno o más dígitos, hasta el final. Salen 9: `0 7 42 100 1000 12345 2024 007 612345678`.
</details>


#### 🟢 Ejercicio 5.4 · Líneas "en blanco" de verdad

Cuenta cuántas líneas de `conf-ejemplo.conf` son **vacías o solo contienen espacios/tabuladores**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '^[[:space:]]*$' conf-ejemplo.conf
```

_Resultado:_

```text
5
```


5: las 4 vacías y la de los tres espacios.
</details>


#### 🟢 Ejercicio 5.5 · Todas las líneas

Demuestra que `^.*$` coincide con todas las líneas de `frases.txt` (comparando con `grep -c ''`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '^.*$' frases.txt
grep -c '' frases.txt
```

_Resultado:_

```text
20
20
```


`.*` admite cero caracteres, así que incluso una línea vacía encaja.
</details>


#### 🟢 Ejercicio 5.6 · Tres dígitos justos

Muestra las líneas de `numeros.txt` que sean **exactamente tres dígitos**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]{3}$' numeros.txt
# Otra forma equivalente:
grep '^[0-9]\{3\}$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«100»
«007»
```


`100` y `007`.
</details>


#### 🟢 Ejercicio 5.7 · Cuatro dígitos justos

Muestra las líneas de `numeros.txt` que sean **exactamente cuatro dígitos**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]{4}$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«1000»
«2024»
```

</details>


#### 🟢 Ejercicio 5.8 · Entre 2 y 3 dígitos

Muestra las líneas de `numeros.txt` formadas por **2 o 3 dígitos**. Explica para qué sirve la coma.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]{2,3}$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«42»
«100»
«007»
```


En `{2,3}` la coma separa el mínimo (2) del máximo (3). Salen `42`, `100`, `007`.
</details>


#### 🟢 Ejercicio 5.9 · Los DNI

Muestra los DNI de `dni.txt` con formato **8 dígitos + 1 letra mayúscula** (sin nada más).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]{8}[A-Z]$' dni.txt
```

_Resultado_ (coincidencias entre « »):

```text
«12345678Z»
«00000000T»
```


Salen `12345678Z` y `00000000T`. No sale `12345678z` (letra minúscula), ni `1234567Z` (7 dígitos) ni `123456789Z` (9 dígitos).
</details>


#### 🟢 Ejercicio 5.10 · Móviles de verdad

Muestra solo los móviles válidos de `telefonos.txt`: **exactamente 9 dígitos** y que empiecen por 6 o 7.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[67][0-9]{8}$' telefonos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«612345678»
«712345678»
```


`[67]` (primera cifra) + 8 dígitos más = 9. Ya no se cuelan los números de 8 o 10 cifras (compara con el ejercicio 4.12).
</details>


#### 🟢 Ejercicio 5.11 · Nombres de usuario de 4 letras

Muestra los usuarios de `/etc/passwd` cuyo nombre tenga **exactamente 4 caracteres**, usando `{4}`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]{4}:' /etc/passwd
# Otra forma equivalente:
grep '^[^:]\{4\}:' /etc/passwd
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


`[^:]{4}` = "cuatro caracteres que no sean `:`". ¡Mucho más corto que `^[^:][^:][^:][^:]:` del capítulo 4!
</details>


#### 🟢 Ejercicio 5.12 · Color o colour

Con `?`, haz que `grep` encuentre `color` y `colour` pero no `colouur` en `color`, `colour`, `colouur`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'color\ncolour\ncolouur\n' | grep -Ex 'colou?r'
```

_Resultado_ (coincidencias entre « »):

```text
«color»
«colour»
```

</details>


#### 🟢 Ejercicio 5.13 · Con o sin "s"

Muestra las URLs de `urls.txt` que empiecen por `http://` **o** `https://`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^https?://' urls.txt
```

_Resultado_ (coincidencias entre « »):

```text
«http://»www.ejemplo.com
«https://»www.ejemplo.com/
«https://»cas-training.com/cursos/linux?id=5&lang=es
«http://»localhost:8080/index.html
«https://»192.168.1.10:8443/admin
«https://»ejemplo.com/ruta con espacios
```


`s?` = "s" opcional. Quedan fuera `ftp://`, `htp://` (mal escrita), `https//` (le faltan los dos puntos)…
</details>


#### 🟡 Ejercicio 5.14 · Frases largas

Muestra las líneas de `frases.txt` con **40 caracteres o más**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^.{40,}$' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
«Mi correo es juan@ejemplo.com y el tuyo es ana@ejemplo.org.»
«   Esta frase empieza con tres espacios.»
```


`.{40,}` = "40 o más caracteres cualquiera". La coma sin máximo significa "sin tope".
</details>


#### 🟡 Ejercicio 5.15 · Palabras cortitas

Muestra las palabras de `palabras.txt` con **3 caracteres o menos** (incluso vacías).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^.{0,3}$' palabras.txt | tr '\n' ' '
# Otra forma equivalente:
grep -E '^.{,3}$' palabras.txt | tr '\n' ' '
```

_Resultado:_

```text
ala oso ojo sol sal mar luz pan paz aaa aa a abc zsh 
```


`{0,3}` = de 0 a 3. `{,3}` es la abreviatura (extensión de GNU).
</details>


#### 🟡 Ejercicio 5.16 · Entre 5 y 6 caracteres

Cuenta las líneas de `palabras.txt` con **entre 5 y 6** caracteres.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^.{5,6}$' palabras.txt
```

_Resultado:_

```text
30
```

</details>


#### 🟡 Ejercicio 5.17 · Decimales a la española

Muestra los números de `numeros.txt` con **coma decimal** (dígitos, coma, dígitos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]+,[0-9]+$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«1,5»
«3,14»
```


Salen `1,5` y el señuelo `3,14`. En `[0-9]+,[0-9]+` la coma es una coma normal.
</details>


#### 🟡 Ejercicio 5.18 · Decimales con punto o coma

Muestra los números decimales con punto **o** coma (dígitos, `.` o `,`, dígitos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]+[.,][0-9]+$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«3.14»
«0.5»
«1,5»
«3,14»
```


Dentro del corchete, `.` y `,` son letras normales: `[.,]` = "un punto o una coma".
</details>


#### 🟡 Ejercicio 5.19 · Sueldos altos

En `usuarios.csv` (la última columna es el salario) muestra los empleados con salario **de 3000.00 a 9999.99**: acaban en `,` + 4 dígitos que empiezan por 3-9 + `.` + 2 decimales.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E ',[3-9][0-9]{3}\.[0-9]{2}$' usuarios.csv
```

_Resultado_ (coincidencias entre « »):

```text
3,Luis,Pérez,luis.perez@ejemplo.com,45,Sevilla«,3200.75»
5,Pedro,Gómez,pedro.gomez@ejemplo.net,52,Valencia«,3900.00»
8,María,Fernández,maria.fernandez@empresa.com,40,Barcelona«,3100.00»
9,José,Rodríguez,jose.rodriguez@ejemplo.com,61,Sevilla«,4100.50»
```


`,[3-9][0-9]{3}\.[0-9]{2}$`: una coma, un dígito del 3 al 9, tres dígitos más, un **punto de verdad** (`\.`) y dos decimales.
</details>


#### 🟡 Ejercicio 5.20 · Treinta y tantos

En `usuarios.csv`, muestra a las personas cuya **edad** (columna entre dos comas) esté entre 30 y 39.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E ',3[0-9],' usuarios.csv
```

_Resultado_ (coincidencias entre « »):

```text
1,Juan,Flores,juan.flores@cas-training.com«,34,»Madrid,2450.50
6,Lucía,Martín,lucia.martin@ejemplo.org«,31,»Bilbao,2650.25
11,Álvaro,Núñez,alvaro.nunez@ejemplo.net«,36,»Madrid,2750.00
```


`,3[0-9],` = coma, un 3, un dígito, coma. El segundo `,` evita coger `,350` o salarios.
</details>


#### 🟡 Ejercicio 5.21 · Años de cuatro cifras

Muestra las líneas de `frases.txt` que contengan un **año** (cuatro dígitos seguidos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '[0-9]{4}' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
Hoy es lunes, 14 de octubre de «2024».
El número de teléfono es «6123»«4567»8.
```


Sin anclas, vale cualquier secuencia de 4 dígitos (por eso también cogería los 4 primeros de un teléfono de 9 cifras: sale también la línea del teléfono).
</details>


#### 🟡 Ejercicio 5.22 · Horas

Cuenta las líneas de `/var/log/syslog` que contienen una **hora** con formato `hh:mm:ss`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '[0-9]{2}:[0-9]{2}:[0-9]{2}' /var/log/syslog
```

_Resultado:_

```text
122
```


Todas las del laboratorio (122): todas empiezan por fecha y hora.
</details>


#### 🟡 Ejercicio 5.23 · Puertos de 5 cifras (versión corta)

Repite el ejercicio 4.35 con `{5}`: líneas de `auth.log` con `port` + **exactamente 5 cifras** + espacio. Cuéntalas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE 'port [0-9]{5} ' /var/log/auth.log
```

_Resultado:_

```text
20
```


`[0-9]{5}` sustituye a cinco `[0-9]` seguidos: mismo resultado, un patrón mucho más corto.
</details>


#### 🟡 Ejercicio 5.24 · "Y" en un solo grep

En `auth.log`, muestra con **un solo `grep`** las líneas que contengan `Failed` **y después** `root`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'Failed.*root' /var/log/auth.log | cut -c1-100
```

_Resultado:_

```text
Nov  4 14:02:11 ubuntu-pc sshd[3805]: Failed password for root from 198.51.100.23 port 51234 ssh2
Nov  4 14:02:14 ubuntu-pc sshd[5256]: Failed password for root from 198.51.100.23 port 51234 ssh2
```


`Failed.*root` = `Failed`, lo que sea, `root` (en ese orden). Antes lo hacíamos con dos `grep` en tubería.
</details>


#### 🟡 Ejercicio 5.25 · Un día y un tipo

En un solo `grep`, muestra las líneas de `/var/log/dpkg.log` del `2024-11-05` que sean un `upgrade`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^2024-11-05.* upgrade ' /var/log/dpkg.log
```

_Resultado:_

```text
2024-11-05 09:10:41 upgrade libssl3t64:amd64 3.0.13-0ubuntu3.1 3.0.13-0ubuntu3.4
2024-11-05 09:10:44 upgrade openssh-client:amd64 1:9.6p1-3ubuntu13.4 1:9.6p1-3ubuntu13.5
2024-11-05 09:10:49 upgrade python3.12:amd64 3.12.3-1ubuntu0.1 3.12.3-1ubuntu0.3
2024-11-05 09:10:58 upgrade linux-image-6.8.0-45-generic:amd64 6.8.0-44.44 6.8.0-45.45
```


`^2024-11-05` (empieza por la fecha) + `.*` (hora y lo que sea) + ` upgrade ` (con espacios para no coger otras palabras).
</details>


#### 🟡 Ejercicio 5.26 · Comentarios con sangría

Muestra las líneas de `conf-ejemplo.conf` que sean **comentarios con `#`**, aunque estén **sangrados** con espacios o tabuladores.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -n '^[[:space:]]*#' conf-ejemplo.conf
```

_Resultado:_

```text
1:# Fichero de configuracion de ejemplo
2:# Los comentarios empiezan por almohadilla
9:    # comentario con sangria
23:# fin
```


`^[[:space:]]*#` = principio de línea, cero o más espacios, y un `#`. Así cazamos también `    # comentario con sangria`.
</details>


#### 🟡 Ejercicio 5.27 · Configuración "de verdad" (dos patrones)

Muestra `conf-ejemplo.conf` **sin** comentarios (con `#`, también sangrados) y **sin** líneas vacías o en blanco. Un solo `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' conf-ejemplo.conf
```

_Resultado:_

```text
; Esto es un comentario estilo ini
[servidor]
puerto = 8080
host=localhost
debug = true
[base_datos]
usuario = admin
clave = s3creta
host = 192.168.1.50
puerto=5432
[correo]
smtp = smtp.ejemplo.com
puerto = 587
remitente = noreply@ejemplo.com
```


Dos patrones con `-e` y `-v` (los descarta). Queda un caso por resolver: el comentario `;` de estilo ini. En el capítulo 6 lo harás en un solo patrón con alternativas `(#|;|$)`.
</details>


#### 🟡 Ejercicio 5.28 · Espacios finales

Cuenta cuántas líneas de `frases.txt` terminan con **espacios o tabuladores** invisibles.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '[[:space:]]+$' frases.txt
```

_Resultado:_

```text
1
```


Solo 1. `+` = al menos uno.
</details>


#### 🟡 Ejercicio 5.29 · Empiezan con espacio

Muestra, con número de línea, las líneas de `frases.txt` que empiezan con uno o más espacios o tabuladores.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -nE '^[[:space:]]+' frases.txt
```

_Resultado:_

```text
17:   Esta frase empieza con tres espacios.
19:	Esta empieza con un tabulador.
```

</details>


#### 🟡 Ejercicio 5.30 · La `o` triple

Muestra solo las palabras que tengan **tres o más `o` seguidas**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'o{3,}' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
h«ooo»la
```

</details>


#### 🔴 Ejercicio 5.31 · GID de tres o más cifras

Muestra (con `cut` para verlo mejor) los usuarios de `/etc/passwd` cuyo **GID** (4.º campo) tenga **tres o más cifras**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[^:]*:[0-9]{3,}:' /etc/passwd | cut -d: -f1,4
```

_Resultado:_

```text
sync:65534
_apt:65534
nobody:65534
systemd-network:998
systemd-timesync:996
systemd-resolve:991
messagebus:104
syslog:105
uuidd:106
tss:107
sshd:65534
tcpdump:108
landscape:109
fwupd-refresh:990
polkitd:989
mysql:112
postgres:113
alumno:1000
ana:1001
luis:1002
… (y 3 líneas más)
```


`[^:]*:` se repite 3 veces (nombre, `x`, UID) y luego `[0-9]{3,}:` = GID de 3 o más cifras. `cut -d: -f1,4` solo muestra los campos 1 y 4. (En el [capítulo 6](06-grupos-alternancia.md) haremos "GID ≥ 50" con alternativas.)
</details>


#### 🔴 Ejercicio 5.32 · UID de cuatro cifras o más

Muestra los usuarios de `/etc/passwd` cuyo **UID** (3.er campo) tenga **cuatro o más cifras**. ¿Es lo mismo que "UID ≥ 1000"?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:[0-9]{4,}:' /etc/passwd | cut -d: -f1,3
```

_Resultado:_

```text
nobody:65534
alumno:1000
ana:1001
luis:1002
marta:1003
pedro:1004
invitado:1005
backup2:1006
```


Casi: UID ≥ 1000 equivale a "4 o más cifras", pero **también** entra `nobody` con UID **65534** (5 cifras), que no es un usuario "normal". Para excluirlo harían falta alternativas (capítulo 6).
</details>


#### 🔴 Ejercicio 5.33 · La coma que no separaba

En `csv-dificil.csv` hay campos con comas **dentro** de comillas. Muestra las líneas que tengan **al menos una coma dentro de comillas** (algo entre comillas con una coma): `"…,…"`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '"[^"]*,[^"]*"' csv-dificil.csv
```

_Resultado_ (coincidencias entre « »):

```text
1,«"Pérez, Luis"»,«"Le gusta Linux, grep y sed"»
3,«"Ruiz, Marta"»,"Dice: "«"hola, mundo"»""
4,Pedro,«"Una coma, otra coma, otra más"»
```


`"[^"]*,[^"]*"` = comilla, texto sin comillas, **coma**, texto sin comillas, comilla. Este ejemplo enseña por qué partir un CSV por comas con herramientas simples es peligroso: la coma tiene doble vida (separador y texto).
</details>


#### 🔴 Ejercicio 5.34 · Etiquetas HTML sin ser voraz

Extrae **solo los enlaces** `<a href="…">` de `html.txt` (la etiqueta de apertura entera, una por línea).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o '<a [^>]*>' html.txt
```

_Resultado:_

```text
<a href="https://www.ejemplo.com">
<a href="http://otro.org/pagina">
```


`<a ` + `[^>]*` (todo menos `>`) + `>`. `-o` imprime solo el trozo. Con `.*` en vez de `[^>]*` los dos enlaces de la línea se fundirían en uno.
</details>


#### 🔴 Ejercicio 5.35 · Dentro de las comillas

Extrae solo las **URLs** (lo que hay entre comillas) de los atributos `href="…"` de `html.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -o 'href="[^"]*"' html.txt
```

_Resultado:_

```text
href="https://www.ejemplo.com"
href="http://otro.org/pagina"
```


`[^"]*` = "cualquier cosa que no sea una comilla": se detiene en la comilla de cierre. (Quedarnos solo con la URL sin `href="`… eso lo conseguirás en el capítulo 13.)
</details>


#### 🔴 Ejercicio 5.36 · Windows sin dolor

En `windows.txt` (con finales de Windows), cuenta cuántas líneas terminan en `x` ignorando el retorno de carro. Compara con `x$`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'x$' windows.txt
grep -c 'x[[:space:]]*$' windows.txt
```

_Resultado:_

```text
0
1
```


Con `x$` no sale nada (hay un `\r` antes del fin de línea). `x[[:space:]]*$` absorbe el `\r` y coincide con `linux`.
</details>


#### 🔴 Ejercicio 5.37 · Números de versión x.y.z

En `versiones.txt`, muestra las líneas que contengan un número de versión con formato `X.Y.Z` (tres números separados por puntos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '[0-9]+\.[0-9]+\.[0-9]+' versiones.txt
```

_Resultado_ (coincidencias entre « »):

```text
Linux version «6.8.0»-45-generic
Python «3.12.3»
openssl «3.0.13»
v«1.2.3»
«1.2.3»-rc1
bash «5.2.21»(1)-release
nginx/«1.24.0»
kernel «5.15.0»-91-generic #101-Ubuntu SMP
Ubuntu «24.04.1» LTS
```


`[0-9]+` (uno o más dígitos) + `\.` (punto de verdad) repetido tres veces. Salen `6.8.0`, `3.12.3`, `3.0.13`, `1.2.3`, `5.2.21`… cada una con su `x.y.z`.
</details>


#### ⚫ Ejercicio 5.38 · IPv4 "de pega"

En `ips.txt`, muestra las líneas que contengan algo con **forma** de IP: cuatro grupos de 1 a 3 dígitos separados por puntos. (No hace falta que sean válidas: eso lo cuidaremos en el capítulo 12.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168.1.1»
«10.0.0.1»
«172.16.254.1»
«255.255.255.255»
«0.0.0.0»
«127.0.0.1»
«8.8.8.8»
«1.1.1.1»
«256.1.1.1»
«192.168.1.256»
«999.999.999.999»
«300.300.300.300»
«1.2.3.4».5
«01.02.03.04»
«192.168.001.001»
Servidor DNS: «8.8.4.4»
Gateway «192.168.0.254» activo
IP de origen=«203.0.113.45» destino=«198.51.100.7»
«192.168.0.1»:8080
«10.0.0.0»/8
… (y 4 líneas más)
```


Coincide también con `999.999.999.999` o `256.1.1.1` (no son IPs válidas, pero tienen la *forma*), y con la `1.2.3.4.5` (porque contiene un `1.2.3.4`). Para precisión hay que añadir más reglas (capítulo 12).
</details>


---

## ✅ Resumen del capítulo 5

| Cuantificador | ERE (`grep -E`) | BRE (`grep`) | Significa |
|---|---|---|---|
| cero o más | `*` | `*` | `a*` |
| uno o más | `+` | `\+` | `a+` |
| cero o uno | `?` | `\?` | `a?` |
| exactamente n | `{n}` | `\{n\}` | `a{3}` |
| n o más | `{n,}` | `\{n,\}` | `a{3,}` |
| de n a m | `{n,m}` | `\{n,m\}` | `a{2,5}` |
| hasta m | `{,m}` | `\{,m\}` | `a{,5}` |

**La coma:** normal en texto y en corchetes; **separador min/máx dentro de `{ }`** (sin espacios).

**`.*`** = cualquier cosa. **Voraz**: se come todo; usa `[^X]*` para frenarlo antes de `X`.

➡️ **Siguiente parada:** [Capítulo 6](06-grupos-alternancia.md): paréntesis, alternativas con `|` y "memoria" con `\1`.

---
⬅️ [Capítulo 4 · Los corchetes `[ ]`: elegir entre varios caracteres](04-corchetes.md) · 🏠 [Índice](README.md) · [Capítulo 6 · Grupos, alternativas y memoria: `( )` `|` `\1`](06-grupos-alternancia.md) ➡️
