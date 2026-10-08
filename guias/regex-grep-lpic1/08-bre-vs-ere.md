# Capítulo 8 · BRE contra ERE: `grep`, `egrep`, `fgrep` (¡y `-P`!)

> 🎯 **Objetivo:** tener clarísimas las diferencias entre las expresiones regulares **básicas** (BRE) y **extendidas** (ERE), saber traducir de una a otra y entender qué hacen `egrep`, `fgrep`, `grep -F` y `grep -P`.
>
> 📘 **LPIC-1:** 103.7 — *"Understand the differences between basic and extended regular expressions"*. **Pregunta segura del examen.**
>
> 🧪 `cd ~/lab-regex`

---

## 8.1 · Los tres sabores y sus cuatro nombres

En tu helado de expresiones regulares hay **sabores**. Linux entiende varios, y `grep` los elige con una opción:

| Opción | Sabor | Cómo se le llama |
|---|---|---|
| `grep` (o `grep -G`) | **BRE** (*Basic Regular Expressions*) | el modo por defecto |
| `grep -E` (o `egrep`) | **ERE** (*Extended Regular Expressions*) | "extendido" |
| `grep -F` (o `fgrep`) | **Fixed strings** | **sin** regex: busca texto literal |
| `grep -P` | **PCRE** (Perl) | regex "de lujo" (lookahead, `\d`…) |

- `egrep` ≡ `grep -E` y `fgrep` ≡ `grep -F`. Son **comandos antiguos** y están **obsoletos**: en Ubuntu 24.04 son un script de una línea que llama a `grep -E`/`grep -F`; en otras distribuciones con `grep` 3.8 o más reciente, además imprimen un aviso (*"egrep is obsolescent"*). **Para el examen hay que conocerlos; en la vida real usa `grep -E` y `grep -F`.**
- `grep -P` **no es POSIX** ni entra en el examen LPIC-1; lo veremos en el capítulo 13.

```bash
egrep 'ho+la' palabras.txt
# Otra forma equivalente:
grep -E 'ho+la' palabras.txt
```

_Resultado:_

```text
hola
hoola
hooola
```


```bash
fgrep 'a.c' palabras.txt
# Otra forma equivalente:
grep -F 'a.c' palabras.txt
```

_Resultado:_

```text
(no sale nada)
```


(`fgrep 'a.c'` busca el texto literal `a.c`, punto incluido; no hay ninguna palabra con eso.)

---

## 8.2 · La gran tabla comparativa

Memorízala (o, mejor, **entiéndela**: ahora verás la regla que la gobierna):

```text
CONCEPTO                  BRE (grep)          ERE (grep -E)
------------------------  ------------------  ------------------
cualquier carácter        .                   .
principio / fin de línea  ^   $               ^   $
lista de caracteres       [abc]               [abc]
cero o más                *                   *
uno o más                 \+  (GNU)           +
cero o uno                \?  (GNU)           ?
repetición exacta         \{n\}  \{n,m\}      {n}  {n,m}
agrupar                   \(  \)              (  )
alternativa (O)           \|  (GNU)           |
recordar lo capturado     \1  \2 ...          \1  \2 ... (GNU)
```

> *(Esta tabla está en un bloque de código porque la barra vertical `|` rompe las tablas de Markdown.)*

### La regla que lo explica todo

Fíjate en las **cinco** filas que cambian (`+ ? {} () |`). Las llamaremos **"los cinco poderes extra"**:

```text
                       +   ?   {   }   (   )   |
```

- En **BRE**, esos cinco son **letras normales**. Para activarlos hay que poner **barra** delante: `\+  \?  \{  \}  \(  \)  \|`.
- En **ERE**, esos cinco **ya están activados**. Para tratarlos como letras normales hay que poner **barra** delante.

```text
          ┌─────────────── BRE ───────────────┐   ┌─────────────── ERE ───────────────┐
 símbolo  │ sin barra         con barra       │   │ sin barra         con barra       │
 ───────  │ ───────────       ───────────     │   │ ───────────       ───────────     │
    +     │ letra "+"         "uno o más"     │   │ "uno o más"       letra "+"       │
    (     │ letra "("         inicia grupo    │   │ inicia grupo      letra "("       │
```

> 🧠 **Una frase para el examen:** *"En BRE, la barra invertida **activa** `+ ? { } ( ) |`; en ERE, la barra invertida los **desactiva**."*

Los demás metacaracteres (`. * ^ $ [ ] \`) funcionan **igual** en ambos sabores.

### Las "extensiones GNU" (letra pequeña)

El estándar POSIX define para BRE **solo** `*`, `\{ \}` y `\( \)`. Los `\+`, `\?` y `\|` son **extensiones de GNU** (funcionan en el `grep` de Linux, pero no en todos los Unix). En ERE, en cambio, `+ ? |` sí son estándar. Por eso, si buscas portabilidad, **ERE es la apuesta segura**.

---

## 8.3 · Traducir de BRE a ERE (y vuelta)

El método es mecánico: **cada vez que veas `\+ \? \{ \} \( \) \|`, quita la barra** (y viceversa).

| BRE (`grep`) | ERE (`grep -E`) |
|---|---|
| `ho\+la` | `ho+la` |
| `colou\?r` | `colou?r` |
| `^[0-9]\{3\}$` | `^[0-9]{3}$` |
| `\(ab\)\+` | `(ab)+` |
| `a\(b\)\1` | `a(b)\1` |

(Y la alternativa `a\|b` en BRE ↔ `a|b` en ERE.)

Vamos a **demostrar** que son equivalentes: las dos formas deben dar siempre la misma salida (la guía lo comprueba por ti):

```bash
grep '^\(ala\|oso\|ojo\)$' palabras.txt
# Otra forma equivalente:
grep -E '^(ala|oso|ojo)$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ala»
«oso»
«ojo»
```


```bash
grep '^[0-9]\{4\}$' numeros.txt
# Otra forma equivalente:
grep -E '^[0-9]{4}$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«1000»
«2024»
```


---

## 8.4 · Buscar el símbolo literal: dos mundos

¿Cómo busco un `+` de verdad? Depende del sabor, porque **lo que activa un poder en uno, lo desactiva en el otro**:

| Quiero buscar… | En **BRE** | En **ERE** |
|---|---|---|
| un `+` | `+` | `\+` |
| un `?` | `?` | `\?` |
| un `(` | `(` | `\(` |
| un `{` | `{` | `\{` |

Y la barra vertical (`|`, que no cabe bien en una tabla de Markdown): en **BRE** un `|` suelto es un carácter normal; en **ERE** hay que escribirlo con barra delante para que sea literal.

```bash
printf 'a+b\naab\n' | grep 'a+b'
# Otra forma equivalente:
printf 'a+b\naab\n' | grep -E 'a\+b'
```

_Resultado_ (coincidencias entre « »):

```text
«a+b»
```


```bash
grep '(Noble' /etc/os-release
# Otra forma equivalente:
grep -E '\(Noble' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
VERSION="24.04.1 LTS «(Noble» Numbat)"
```


### El truco universal: **dentro de un corchete** todo es literal

Hay una forma de **no tener que acordarte** de qué sabor usas: poner el símbolo en un corchete, donde **ningún** superpoder funciona:

```bash
grep '[(]Noble' /etc/os-release
# Otra forma equivalente:
grep -E '[(]Noble' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
VERSION="24.04.1 LTS «(Noble» Numbat)"
```


Igual en los dos sabores: `[(]` = un paréntesis literal. Lo mismo vale para `[+]`, `[?]`, `[{]`, `[|]`, `[.]`, `[*]`, `[$]`… Recuerda la regla del capítulo 4: dentro de un corchete **no se escapa nada** (ni siquiera la barra `\`, que ahí es una barra normal).

### Un paréntesis solo es un error

```bash
printf '(x)\n' | grep -E '('
```

_Resultado:_

```text
grep: Unmatched ( or \(
```


`grep -E '('` = "abro un grupo y no lo cierro" → error. En BRE, `grep '('` busca un paréntesis normal (y no da error); en cambio `grep '\('` (BRE con barra) sí da error por lo mismo.

### Las llaves: ¿repetición o literales?

```bash
printf 'a{\na{2}\naa\n' | grep -E 'a{'
```

_Resultado_ (coincidencias entre « »):

```text
«a{»
«a{»2}
```


Una llave `{` que **no forma una repetición válida** (como `a{` sin cerrar) la toma GNU `grep` como un `{` literal. Pero `a{2}` **sí** es repetición: `aa`.

```bash
printf 'a{2}\naa\n' | grep -E 'a{2}'
```

_Resultado_ (coincidencias entre « »):

```text
«aa»
```


Solo `aa` (dos `a` seguidas). Y para buscar literalmente `a{2}`:

```bash
printf 'a{2}\naa\n' | grep -E 'a\{2\}'
# Otra forma equivalente:
printf 'a{2}\naa\n' | grep 'a{2}'
```

_Resultado_ (coincidencias entre « »):

```text
«a{2}»
```


(El primero es ERE con `\{`; el segundo, BRE, donde `{` es normal.)

---

## 8.5 · `grep -F` (el antiguo `fgrep`): texto literal, sin regex

Si lo que buscas **no es una regex**, sino un texto exacto —con puntos, asteriscos, dólares…— `-F` es lo mejor: **no hay metacaracteres**, todo es literal.

```bash
grep -F '192.168.1.1' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168.1.1»
«192.168.1.1»00
```


El `.` aquí **es un punto**, no un comodín (por eso `192x168x1x1` ya no cuela). Sigue colándose `192.168.1.100`, pero eso se arregla con `-w` (capítulo 7): `grep -Fw '192.168.1.1' ips.txt`. Y con símbolos peligrosos:

```bash
grep -F '$99' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«$99»
```


Con `grep '$99'` el `$` sería "fin de línea" y no encontrarías nada.

### Muchas pistas desde un fichero: `-f`

Si tienes **una lista de cosas** a buscar, ponla en un fichero (una por línea) y úsala con **`-f`**:

```bash
printf 'gato\nperro\n' > pistas.txt
grep -Ff pistas.txt palabras.txt | tr '\n' ' '
```

_Resultado:_

```text
gato gatos perro gato 
```


`-F -f pistas.txt` = "busca cualquiera de las cadenas del fichero". (Sin `-F`, `-f` interpreta cada línea como una **regex**; también vale y puede ser muy potente: `grep -Ef patrones.txt`.)

---

## 8.6 · `grep -P` (PCRE) en una línea

`-P` usa expresiones regulares al estilo de **Perl**, con extras como `\d` (dígito), `\w`, y mucho más:

```bash
echo 'a1b22' | grep -oP '\d+'
```

_Resultado:_

```text
1
22
```


Está **fuera del examen** LPIC-1, pero es oro puro en la vida real: lo estudiamos a fondo en el [capítulo 13](13-nivel-master.md).

---

## 8.7 · ¿Qué sabor usa cada programa?

No todos los programas hablan el mismo dialecto (¡cuidado en el examen!):

| Programa | Sabor por defecto | Cómo cambiarlo |
|---|---|---|
| `grep` | **BRE** | `-E` (ERE), `-F` (fijo), `-P` (Perl) |
| `egrep` | **ERE** | — |
| `fgrep` | **fijo** (sin regex) | — |
| `sed` | **BRE** | `-E` o `-r` (ERE) |
| `awk` | **ERE** | — |
| `vi` / `vim` | BRE (parecido, con sus particularidades: `\<`, `\>`) | `\v` ("very magic") |
| `less`, `man` (al buscar con `/`) | BRE (la de GNU) | — |
| `find -regex` | tipo **emacs** (¡ni BRE ni ERE!) | `-regextype posix-extended` |
| `locate` | **BRE** con `-r` / `--regexp` | `--regex` = ERE |

```bash
sed -n '/ho\+la/p' palabras.txt | tr '\n' ' '; echo
# Otra forma equivalente:
sed -nE '/ho+la/p' palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
hola hoola hooola 
```


El mismo patrón, `sed` en BRE (`\+`) y en ERE (`-E`, `+`).

---

## 8.8 · 🏋️ Ejercicios

#### 🟢 Ejercicio 8.1 · BRE → ERE (1)

Traduce a ERE (`grep -E`) este comando BRE y comprueba que da lo mismo: `grep 'ho\+la' palabras.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'ho\+la' palabras.txt
# Otra forma equivalente:
grep -E 'ho+la' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«hola»
«hoola»
«hooola»
```


Se quita la barra de `\+`.
</details>


#### 🟢 Ejercicio 8.2 · BRE → ERE (2)

Traduce a ERE: `grep '^[0-9]\{3\}$' numeros.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^[0-9]\{3\}$' numeros.txt
# Otra forma equivalente:
grep -E '^[0-9]{3}$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«100»
«007»
```


Las llaves `\{3\}` pierden las barras. El corchete y las anclas no cambian.
</details>


#### 🟢 Ejercicio 8.3 · BRE → ERE (3)

Traduce a ERE: `grep '^\(Linux\|linux\|LINUX\)$' palabras.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^\(Linux\|linux\|LINUX\)$' palabras.txt
# Otra forma equivalente:
grep -E '^(Linux|linux|LINUX)$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«Linux»
«linux»
«LINUX»
```


Cuatro barras fuera: dos de los paréntesis y dos de las alternativas.
</details>


#### 🟢 Ejercicio 8.4 · ERE → BRE (1)

Traduce a BRE (`grep` sin `-E`): `grep -E 'colou?r'`. Pruébalo con `printf 'color\ncolour\n'`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'color\ncolour\n' | grep -E 'colou?r'
# Otra forma equivalente:
printf 'color\ncolour\n' | grep 'colou\?r'
```

_Resultado_ (coincidencias entre « »):

```text
«color»
«colour»
```


En BRE, el `?` necesita barra: `\?`.
</details>


#### 🟢 Ejercicio 8.5 · ERE → BRE (2)

Traduce a BRE: `grep -E '^(ab)+$'`. Pruébalo con `printf 'ab\nabab\nabb\n'`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'ab\nabab\nabb\n' | grep -E '^(ab)+$'
# Otra forma equivalente:
printf 'ab\nabab\nabb\n' | grep '^\(ab\)\+$'
```

_Resultado_ (coincidencias entre « »):

```text
«ab»
«abab»
```

</details>


#### 🟢 Ejercicio 8.6 · ERE → BRE (3)

Traduce a BRE: `grep -E '^[0-9]{2,4}$' numeros.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[0-9]{2,4}$' numeros.txt
# Otra forma equivalente:
grep '^[0-9]\{2,4\}$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«42»
«100»
«1000»
«2024»
«007»
```


Las llaves necesitan barra en BRE, **incluida la coma** dentro (que sigue siendo la misma coma, sin barra).
</details>


#### 🟢 Ejercicio 8.7 · Buscar un `+` de verdad

En `numeros.txt`, muestra las líneas que contienen un signo `+`. Hazlo en BRE, en ERE y con un corchete.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '+' numeros.txt
# Otra forma equivalente:
grep -E '\+' numeros.txt
# Otra forma equivalente:
grep '[+]' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«+»8
«+»34612345678
```


BRE: el `+` es normal. ERE: hay que escaparlo. Corchete: funciona igual en ambos.
</details>


#### 🟢 Ejercicio 8.8 · Paréntesis de verdad

En `/etc/os-release`, muestra la línea que contiene un paréntesis de apertura `(` (el de `(Noble Numbat)`), con las tres formas (BRE, ERE y corchete).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '(' /etc/os-release
# Otra forma equivalente:
grep -E '\(' /etc/os-release
# Otra forma equivalente:
grep '[(]' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
VERSION="24.04.1 LTS «(»Noble Numbat)"
```

</details>


#### 🟢 Ejercicio 8.9 · Interrogación literal

En `urls.txt`, muestra las URLs con **parámetros** (que contengan un `?` literal). BRE, ERE y corchete.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '?' urls.txt
# Otra forma equivalente:
grep -E '\?' urls.txt
# Otra forma equivalente:
grep '[?]' urls.txt
```

_Resultado_ (coincidencias entre « »):

```text
https://cas-training.com/cursos/linux«?»id=5&lang=es
```

</details>


#### 🟡 Ejercicio 8.10 · El `|` literal

En una cadena `a|b`, busca un `|` literal. Hazlo en BRE y en ERE.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a|b\nab\n' | grep 'a|b'
# Otra forma equivalente:
printf 'a|b\nab\n' | grep -E 'a\|b'
# Otra forma equivalente:
printf 'a|b\nab\n' | grep 'a[|]b'
```

_Resultado_ (coincidencias entre « »):

```text
«a|b»
```


En BRE el `|` sin barra es un carácter normal. En ERE, `\|` lo desactiva. Con el corchete `[|]`, siempre.
</details>


#### 🟡 Ejercicio 8.11 · Las llaves literales

Con `printf 'a{2}\naa\n'`, haz que `grep` encuentre **la línea que contiene `a{2}` literalmente** (con las llaves) y no `aa`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a{2}\naa\n' | grep 'a{2}'
# Otra forma equivalente:
printf 'a{2}\naa\n' | grep -E 'a\{2\}'
```

_Resultado_ (coincidencias entre « »):

```text
«a{2}»
```


En BRE las llaves sin barra son normales; en ERE se escapan.
</details>


#### 🟡 Ejercicio 8.12 · `-F` para IPs

Usa `-F` para encontrar la IP `10.0.0.1` literal en `ips.txt` (sin que el punto sea comodín).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -F '10.0.0.1' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«10.0.0.1»
```


Con `-F`, `.` es un punto de verdad. (Ojo: sigue sin ser "palabra completa": también encontraría `10.0.0.10`, si existiera. Añade `-w` para evitarlo.)
</details>


#### 🟡 Ejercicio 8.13 · `-F` con símbolos

Con `-F`, busca en `numeros.txt` las líneas con el texto `$99`, y las que contienen `%`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -F '$99' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«$99»
```


```bash
grep -F '%' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
50«%»
```


En `-F` no hace falta escapar nada (ni `$`, ni `.`, ni `*`).
</details>


#### 🟡 Ejercicio 8.14 · Muchas pistas a la vez

Crea un fichero `pistas.txt` con las líneas `Linux`, `Debian` y `Fedora`, y muestra las líneas de `palabras.txt` que coincidan **exactamente** con alguna.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'Linux\nDebian\nFedora\n' > pistas.txt
grep -Fxf pistas.txt palabras.txt
```

_Resultado:_

```text
Linux
Debian
Fedora
```


`-F` (literal), `-x` (línea entera), `-f pistas.txt` (patrones del fichero). Se pueden juntar: `-Fxf`.
</details>


#### 🟡 Ejercicio 8.15 · `sed` en los dos sabores

Escribe con `sed` (en BRE y en ERE) la orden que **imprime solo** las líneas de `palabras.txt` de tipo `ho…la` con una o más `o`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n '/^ho\+la$/p' palabras.txt | tr '\n' ' '; echo
# Otra forma equivalente:
sed -nE '/^ho+la$/p' palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
hola hoola hooola 
```


`sed -n '/regex/p'` imprime solo las líneas que coinciden. Con `-E` se usa ERE.
</details>


#### 🟡 Ejercicio 8.16 · Retrocesos: `\1` en los dos sabores

Encuentra, en `palabras.txt`, las palabras con **dos letras iguales seguidas**, en BRE y en ERE. Cuenta cuántas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '\(.\)\1' palabras.txt
# Otra forma equivalente:
grep -cE '(.)\1' palabras.txt
```

_Resultado:_

```text
11
```


La referencia `\1` se escribe igual en los dos; solo cambian los paréntesis del grupo.
</details>


#### 🔴 Ejercicio 8.17 · ¿Cuál de estos es válido?

Predice cuál de estos comandos da **error**: (a) `grep 'a\+' f` (b) `grep -E 'a\+' f` (c) `grep -E '(a' f` (d) `grep '(a' f`. Compruébalo en `palabras.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'a\+' palabras.txt
grep -cE 'a\+' palabras.txt
grep -cE '(a' palabras.txt
grep -c '(a' palabras.txt
```

_Resultado:_

```text
46
0
grep: Unmatched ( or \(
0
```


- (a) válido: BRE, `\+` = uno o más `a`.
- (b) válido: ERE, `\+` = un `+` literal (no hay ninguno).
- (c) **error** (`Unmatched ( or \(`): en ERE el `(` abre un grupo sin cerrar.
- (d) válido: en BRE el `(` es un carácter normal.

Cada `grep` es un comando independiente: el error de (c) no impide que se ejecute (d). Solo **(c)** da error.
</details>


#### 🔴 Ejercicio 8.18 · Detector de sabores

Explica la salida de estas dos líneas (misma regex, distinto sabor) con `printf 'a+b\naab\n'`: `grep 'a+b'` y `grep -E 'a+b'`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'a+b\naab\n' | grep 'a+b'
echo ---
printf 'a+b\naab\n' | grep -E 'a+b'
```

_Resultado:_

```text
a+b
---
aab
```


BRE: el `+` es un carácter normal, así que `a+b` busca esas tres letras seguidas y solo encuentra la primera línea. ERE: `+` significa "uno o más" y `a+b` busca "una o más `a` y luego una `b`": solo encuentra `aab`. Una prueba de que **la misma regex significa cosas distintas** en cada sabor.
</details>


#### 🔴 Ejercicio 8.19 · Pregunta tipo examen

*"¿Qué comando muestra las líneas que tienen exactamente 3 dígitos seguidos, usando regex básicas?"* (a) `grep '[0-9]{3}'` (b) `grep '[0-9]\{3\}'` (c) `grep -E '[0-9]\{3\}'` (d) `grep '[0-9]+3'`. Pruébalas con `numeros.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf '(a) '; grep -c '[0-9]{3}' numeros.txt
printf '(b) '; grep -c '[0-9]\{3\}' numeros.txt
printf '(c) '; grep -cE '[0-9]\{3\}' numeros.txt
printf '(d) '; grep -c '[0-9]+3' numeros.txt
```

_Resultado:_

```text
(a) 0
(b) 11
(c) 0
(d) 0
```


**(b)** es la correcta: BRE con `\{3\}`. (a) busca un dígito seguido de `{3}` literal; (c) en ERE `\{` es una llave literal; (d) busca un dígito, un `+` y un 3. Fíjate: "exactamente 3" en el examen significa 3 **o más** si no pones anclas (con `^…$` serían solo 3).
</details>


---

## ✅ Resumen del capítulo 8

| | BRE (`grep`) | ERE (`grep -E` / `egrep`) |
|---|---|---|
| Los 5 poderes extra `+ ? { } ( )` y `\|` | necesitan barra para **activarse** | funcionan **sin barra**; la barra los **desactiva** |
| `. * ^ $ [ ]` | igual | igual |
| `\1`…`\9` | sí | sí (GNU) |
| Estándar POSIX | `*`, `\{ \}`, `\( \)` | todo |

| Opción | Qué hace |
|---|---|
| `-G` | BRE (por defecto) |
| `-E` | ERE (≡ `egrep`) |
| `-F` | texto fijo (≡ `fgrep`) |
| `-P` | PCRE (Perl) |
| `-f FICHERO` | lee los patrones de un fichero |

**Truco universal:** los símbolos dentro de un corchete (`[+]`, `[(]`, `[.]`) son literales **en cualquier sabor**.

➡️ **Siguiente parada:** [Capítulo 9](09-opciones-de-grep.md): todas las opciones de `grep` con ejemplos (`-o`, `-A`, `-B`, `-C`, `-r`, `--include`, `-q`, `-s`…).

---
⬅️ [Capítulo 7 · Palabras y fronteras: `-w` `-x` `\b` `\<` `\>` `\w`](07-palabras-y-fronteras.md) · 🏠 [Índice](README.md) · [Capítulo 9 · Todas las opciones de `grep` (y los flujos de la terminal)](09-opciones-de-grep.md) ➡️
