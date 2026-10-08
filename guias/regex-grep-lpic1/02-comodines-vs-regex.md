# Capítulo 2 · Comodines de la terminal ≠ expresiones regulares

> 🎯 **Objetivo:** que **nunca** confundas los comodines de la terminal (`*`, `?`, `[ ]`) con las expresiones regulares de `grep`. Es el error nº 1 de todo principiante… y una pregunta clásica del examen.
>
> 📘 **LPIC-1:** 103.3 (comodines / *globbing* para gestionar ficheros) y 103.7 (expresiones regulares).

---

## 2.1 · Dos idiomas con palabras parecidas

En español **"embarazada"** y en inglés **"embarrassed"** se parecen muchísimo… pero una significa "esperando un bebé" y la otra "avergonzada". Se llaman **falsos amigos**.

En Linux hay unos falsos amigos famosos: **los comodines de la terminal** y **las expresiones regulares**. Usan *los mismos símbolos* (`*`, `?`, `[ ]`) pero **significan cosas distintas**, y los entiende **un programa distinto**:

| | **Comodines** (*globbing*) | **Expresiones regulares** |
|---|---|---|
| ¿Quién los entiende? | **La terminal** (`bash`) | **El programa**: `grep`, `sed`, `awk`, `vi`, `less`… |
| ¿Para qué sirven? | Elegir **nombres de ficheros** | Buscar patrones **dentro del texto** |
| ¿Cuándo actúan? | **Antes** de lanzar el comando | **Dentro** del comando |
| Ejemplo | `ls *.txt` | `grep 'ho*la' fichero` |

> 🧠 **Truco para no liarte:** pregúntate *"¿estoy hablando de **nombres de ficheros** o de **contenido**?"*
> - Nombres de ficheros → comodines.
> - Contenido de los ficheros → expresiones regulares.

---

## 2.2 · Cómo funcionan los comodines: la terminal hace trampa

Cuando escribes `ls *.txt` y pulsas Enter, **antes de ejecutar `ls`**, la terminal busca todos los nombres que encajan con `*.txt` y **reescribe la orden** sustituyendo `*.txt` por esa lista. Mira, esto lo podemos comprobar con `echo`, que solo repite lo que recibe:

```bash
echo *.csv
```

_Resultado:_

```text
csv-dificil.csv usuarios.csv
```


`echo` no sabe nada de comodines: **recibió dos nombres ya expandidos** (`csv-dificil.csv` y `usuarios.csv`). El `*` desapareció antes de que `echo` llegase a enterarse.

Aún más revelador: ¿qué recibe `grep` cuando escribes `grep gato *.txt`?

```bash
echo grep gato *.txt
```

_Resultado:_

```text
grep gato agenda.txt colores.txt contrasenas.txt correos.txt dni.txt dominios.txt fechas.txt frases.txt html.txt ips.txt ipv6.txt macs.txt matriculas.txt nombres.txt numeros.txt palabras.txt poema.txt repetidas.txt sin-salto-final.txt telefonos.txt urls.txt versiones.txt windows.txt
```


`grep` recibe **una lista larga de ficheros**, ni rastro del `*`. Por eso `grep gato *.txt` funciona: la terminal le monta la lista y `grep` busca `gato` en cada uno.

### La tabla de comodines

| Comodín | Significa | Ejemplo |
|---|---|---|
| `*` | **cualquier** secuencia de caracteres (también vacía) | `*.txt` → todos los acabados en `.txt` |
| `?` | **exactamente un** carácter cualquiera | `????.txt` → nombres de 4 letras + `.txt` |
| `[abc]` | **uno** de los caracteres de la lista | `IMG_000[123].jpg` |
| `[a-c]` | **uno** del rango | `IMG_000[1-3].*` |
| `[!abc]` | **uno que NO** esté en la lista (también vale `[^abc]` en bash) | `[!a]*.txt` |
| `{a,b,c}` | no es un comodín, sino **generar texto** (*brace expansion*) | `echo {a,b,c}` |

Veámoslos:

```bash
echo ????.txt
```

_Resultado:_

```text
html.txt ipv6.txt macs.txt urls.txt
```


Cuatro caracteres exactos antes de `.txt`: `html`, `ipv6`, `macs`, `urls`.

```bash
ls arbol/fotos/IMG_000[1-3].*
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/IMG_0003.JPG
```


```bash
echo informe-{2023,2024}-0{1,2}.txt
```

_Resultado:_

```text
informe-2023-01.txt informe-2023-02.txt informe-2024-01.txt informe-2024-02.txt
```


Las llaves **no consultan ningún fichero**: simplemente *fabrican* todas las combinaciones (¡útil para crear muchas carpetas de golpe: `mkdir -p proyecto/{src,doc,test}`!).

### Los ficheros ocultos

El comodín `*` **no encaja con los nombres que empiezan por punto** (los ocultos):

```bash
ls arbol/docs/*
```

_Resultado:_

```text
arbol/docs/README.md
arbol/docs/manual.pdf
arbol/docs/notas.txt

arbol/docs/antiguo:
viejo.txt
viejo.txt.bak
```


Nos faltó `.oculto.txt`. Con `ls -A` sí lo vemos:

```bash
ls -A arbol/docs
```

_Resultado:_

```text
.oculto.txt
README.md
antiguo
manual.pdf
notas.txt
```


---

## 2.3 · Los mismos símbolos, significados distintos

Aquí está el corazón del capítulo. Mira cómo cambia **el mismo símbolo** según quién lo lea:

| Símbolo | En la **terminal** (comodín) | En **`grep`** (expresión regular) |
|---|---|---|
| `*` | cualquier cosa (`*.txt`) | el carácter **anterior**, repetido **0 o más veces** (`ho*la`) |
| `?` | un carácter cualquiera | *(en ERE)* el carácter anterior es **opcional** |
| `.` | un punto normal y corriente | **un carácter cualquiera** |
| `[!abc]` | todo menos a, b, c | `[^abc]` (con circunflejo) |
| `{a,b}` | genera `a` y `b` | *(en ERE)* repetición `{n,m}` — significa otra cosa |

El `*` es el más traicionero. En la terminal, `a*` significa *"algo que empiece por a"*. En una regex, `a*` significa *"cero o más letras a"*, y como **"cero a" también vale**, ¡**coincide con todas las líneas**!

```bash
grep -c 'a*' palabras.txt
```

_Resultado:_

```text
71
```


71 de 71: absolutamente todas. Porque aunque una línea no tenga ninguna `a`, tiene "cero `a`" (que cuenta). Más sobre esto en el capítulo 5.

### Y un caso rarísimo: el `*` a principio de patrón

Si escribes `grep '*.txt'` pensando en "cualquier cosa acabada en .txt"…

```bash
ls | grep '*.txt'
```

_Resultado:_

```text
(no sale nada)
```


…no sale nada. Y no es que no haya ficheros `.txt`. Resulta que en una regex básica, un `*` **al principio del patrón** no tiene nada delante que repetir, así que se toma **como un asterisco normal**. `grep` busca líneas con un `*` literal seguido de cualquier carácter y `txt`: no hay ninguna.

---

## 2.4 · ¿Quién interpreta qué? Las comillas deciden

Este es **el error clásico**. Mira:

```bash
echo grep p* palabras.txt
```

_Resultado:_

```text
grep palabras.txt poema.txt programa.py palabras.txt
```


Si en `grep p* palabras.txt` quisiste decir *"busca líneas que empiecen por p"* (o *"p seguida de lo que sea"*), la terminal se te adelantó: expandió `p*` a los ficheros del laboratorio que empiezan por `p` (`palabras.txt`, `poema.txt`, `programa.py`…) y le entregó a `grep`:

```text
grep palabras.txt poema.txt programa.py palabras.txt
       └─ ¡esto es ahora el "patrón"!
```

`grep` buscaría la **palabra** `palabras.txt` en `poema.txt`, `programa.py` y `palabras.txt`. Un desastre silencioso.

**La solución: comillas simples.** Dentro de `' '` la terminal no toca nada y el patrón llega intacto a `grep`:

```bash
grep 'p*' palabras.txt      # ✅ el * llega a grep y grep lo interpreta como regex
grep  p*  palabras.txt      # ❌ la terminal lo expande antes
```

### Y si no hay ningún fichero que encaje…

Si el comodín **no encaja con nada**, `bash` lo deja **tal cual** (sin expandir). Compruébalo:

```bash
echo z*
```

_Resultado:_

```text
z*
```


Ningún fichero empieza por `z`, y `echo` recibió el `z*` literal. Es **peor** de lo que parece: `grep z* fichero` "funcionaría" hoy (porque no hay ficheros con `z`)… y se rompería **mañana**, cuando alguien cree un fichero `zeta.txt`. Los fallos que dependen de qué ficheros hay en la carpeta son los más difíciles de encontrar.

> 🏅 **Regla de oro nº 2 (otra vez):** *Las expresiones regulares van SIEMPRE entre comillas simples.* Los **ficheros** van **sin comillas** si quieres que la terminal expanda comodines (`*.txt`), y **con comillas** si no.

---

## 2.5 · Mapa: ¿qué comando usa qué?

| Usan **comodines** (la terminal los expande) | Usan **expresiones regulares** |
|---|---|
| `ls`, `cp`, `mv`, `rm`, `mkdir`… (los **nombres** que les pasas) | `grep`, `egrep`, `fgrep` |
| `find -name 'patrón'` (¡`find` los interpreta él mismo: por eso lleva comillas!) | `sed`, `awk` |
| `case … in` de los scripts | `vi`/`vim` (`/`, `:s`), `less` (`/`), `man` (`/`) |
| | `find -regex`, `locate --regex` |

Hay un punto curioso: **`find -name`** usa comodines, pero **no los expande la terminal**, los expande `find`; por eso hay que ponerlos entre comillas (`find . -name '*.txt'`) para que la terminal no los toque antes. Lo veremos en el capítulo 15.

---

## 2.6 · 🏋️ Ejercicios

#### 🟢 Ejercicio 2.1 · Todos los CSV

Muestra, con un solo comando y un comodín, todos los ficheros del laboratorio que acaben en `.csv`.

<details>
<summary>💡 Ver solución</summary>


```bash
ls *.csv
```

_Resultado:_

```text
csv-dificil.csv
usuarios.csv
```


La terminal expande `*.csv` a `csv-dificil.csv usuarios.csv` y se lo pasa a `ls`.
</details>


#### 🟢 Ejercicio 2.2 · Nombres de 4 letras

Lista los ficheros `.txt` cuyo nombre (sin la extensión) tenga **exactamente 4 caracteres**.

<details>
<summary>💡 Ver solución</summary>


```bash
ls ????.txt
```

_Resultado:_

```text
html.txt
ipv6.txt
macs.txt
urls.txt
```


Cada `?` es **un** carácter. Cuatro interrogantes = cuatro caracteres.
</details>


#### 🟢 Ejercicio 2.3 · Nombres de 3 letras

Lista los ficheros `.txt` cuyo nombre sin la extensión tenga **3** caracteres.

<details>
<summary>💡 Ver solución</summary>


```bash
ls ???.txt
```

_Resultado:_

```text
dni.txt
ips.txt
```

</details>


#### 🟢 Ejercicio 2.4 · Empiezan por "p"

Lista los ficheros del laboratorio cuyo nombre **empieza por `p`**.

<details>
<summary>💡 Ver solución</summary>


```bash
ls p*
```

_Resultado:_

```text
palabras.txt
poema.txt
programa.py
```


`p*` = una `p` seguida de lo que sea. Salen `palabras.txt`, `poema.txt` y `programa.py`.
</details>


#### 🟢 Ejercicio 2.5 · Rango de números

Lista las fotos `IMG_0001` a `IMG_0003` de `arbol/fotos/` (con cualquier extensión).

<details>
<summary>💡 Ver solución</summary>


```bash
ls arbol/fotos/IMG_000[1-3].*
```

_Resultado:_

```text
arbol/fotos/IMG_0001.jpg
arbol/fotos/IMG_0002.jpg
arbol/fotos/IMG_0003.JPG
```


`[1-3]` es **un** carácter que sea 1, 2 o 3.
</details>


#### 🟢 Ejercicio 2.6 · Uno u otro

Lista los informes de 2024 de enero **o** febrero (en `.txt`) de `arbol/informes/`.

<details>
<summary>💡 Ver solución</summary>


```bash
ls arbol/informes/informe-2024-0[12].txt
```

_Resultado:_

```text
arbol/informes/informe-2024-01.txt
arbol/informes/informe-2024-02.txt
```


`[12]` = 1 **o** 2. Comprueba que no sale el `.pdf`.
</details>


#### 🟢 Ejercicio 2.7 · Generando nombres

Sin crear nada, haz que la terminal **escriba** estos cuatro nombres con un solo `echo`: `informe-2023-01.txt informe-2023-02.txt informe-2024-01.txt informe-2024-02.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo informe-{2023,2024}-0{1,2}.txt
```

_Resultado:_

```text
informe-2023-01.txt informe-2023-02.txt informe-2024-01.txt informe-2024-02.txt
```


Las llaves combinan todos los elementos entre sí (2 × 2 = 4 nombres).
</details>


#### 🟢 Ejercicio 2.8 · Lo que ve `grep`

Escribe una orden que **demuestre** qué argumentos recibiría `grep` en `grep root *.conf`. (Pista: `echo`.)

<details>
<summary>💡 Ver solución</summary>


```bash
echo grep root *.conf
```

_Resultado:_

```text
grep root conf-ejemplo.conf
```


Solo hay un `.conf` en el laboratorio (`conf-ejemplo.conf`), y es lo que `grep` recibiría. `echo` te enseña la orden **ya expandida**: es tu mejor herramienta para depurar comodines.
</details>


#### 🟡 Ejercicio 2.9 · El truco de `echo`

Con `echo`, averigua cuántos ficheros (no ocultos) tiene la carpeta `arbol/scripts/`. No uses `ls`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo arbol/scripts/*
```

_Resultado:_

```text
arbol/scripts/backup.sh arbol/scripts/deploy.sh arbol/scripts/limpiar.py arbol/scripts/test.PY
```


Salen cuatro: `backup.sh`, `deploy.sh`, `limpiar.py`, `test.PY`. `echo` te muestra el resultado de la expansión sin usar ningún otro comando.
</details>


#### 🟡 Ejercicio 2.10 · El fichero oculto

La carpeta `arbol/docs` contiene un fichero oculto. Demuestra que el comodín `*` **no** lo incluye y que `ls -A` sí.

<details>
<summary>💡 Ver solución</summary>


```bash
echo arbol/docs/*
ls -A arbol/docs
```

_Resultado:_

```text
arbol/docs/README.md arbol/docs/antiguo arbol/docs/manual.pdf arbol/docs/notas.txt
.oculto.txt
README.md
antiguo
manual.pdf
notas.txt
```


Un nombre que empieza por punto no encaja con `*` (hay que escribir el punto a propósito: `arbol/docs/.*`).
</details>


#### 🟡 Ejercicio 2.11 · `*` terminal vs `*` regex

En `palabras.txt`, ¿cuántas líneas **empiezan por `g`**? Primero usa **un comodín incorrecto** (para ver que no sirve) y luego la forma buena con regex.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c g* palabras.txt
```

_Resultado:_

```text
71
```


Mal: la terminal expande `g*` (no hay ficheros que empiecen por `g`, así que lo deja `g*`) y `grep` lo toma como regex: **"cero o más g"**, que coincide con todas las líneas. ¡Ni siquiera avisa!

La forma buena (aún no sabes todo lo necesario, pero fíjate: el `^` significa "al principio de la línea"):

```bash
grep -c '^g' palabras.txt
```

_Resultado:_

```text
6
```


Ya lo estudiaremos en el siguiente capítulo.
</details>


#### 🟡 Ejercicio 2.12 · El asterisco literal

Comprueba qué pasa al hacer `ls | grep '*.txt'` y explica por qué no devuelve nada, aunque haya ficheros `.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
ls | grep '*.txt'
echo "código de salida: $?"
```

_Resultado:_

```text
código de salida: 1
```


En una regex **básica**, un `*` al principio del patrón se toma como un asterisco normal. Busca líneas con un `*` literal: no hay ninguna.

Lo que realmente querías (ficheros acabados en `.txt`) se escribe con regex así: `ls | grep '\.txt$'` (lo entenderás en el próximo capítulo) o, mucho más simple, con el comodín de la terminal: `ls *.txt`.
</details>


#### 🟡 Ejercicio 2.13 · ¿Quién interpreta el asterisco?

Para cada orden, di si el `*` lo expande **la terminal** o lo interpreta **el programa**: `ls *.txt` · `grep 'a*' f` · `grep a* f` · `find . -name '*.txt'` · `find . -name *.txt`.

<details>
<summary>💡 Ver solución</summary>


| Orden | ¿Quién interpreta el `*`? |
|---|---|
| `ls *.txt` | **La terminal** (expande a nombres de fichero) |
| `grep 'a*' f` | **`grep`** (regex: "cero o más a") — las comillas protegen el `*` |
| `grep a* f` | **La terminal** (se adelanta y expande `a*` a ficheros que empiezan por `a`) — ¡probable error! |
| `find . -name '*.txt'` | **`find`** (las comillas impiden a la terminal tocarlo) |
| `find . -name *.txt` | **La terminal**, si hay `.txt` en la carpeta actual (y entonces `find` recibe nombres concretos y falla o busca mal); si no hay, lo deja tal cual y `find` lo interpreta |

La conclusión de siempre: **comillas simples para lo que debe llegar intacto**.
</details>


#### 🔴 Ejercicio 2.14 · Demuestra el desastre

Explica y demuestra con `echo` qué recibe `grep` en `grep p* palabras.txt`. ¿Qué intenta buscar y dónde?

<details>
<summary>💡 Ver solución</summary>


```bash
echo grep p* palabras.txt
```

_Resultado:_

```text
grep palabras.txt poema.txt programa.py palabras.txt
```


La terminal ha sustituido `p*` por `palabras.txt poema.txt programa.py`. Así que `grep` recibe **`palabras.txt` como patrón** y busca esa cadena en `poema.txt`, `programa.py` y `palabras.txt`. La orden correcta para buscar líneas que **empiezan por `p`** es `grep '^p' palabras.txt`.
</details>


#### 🔴 Ejercicio 2.15 · Comodín dentro de comillas

¿Qué pasa si escribes `ls '*.txt'` (con comillas)? Pruébalo.

<details>
<summary>💡 Ver solución</summary>


```bash
ls '*.txt'
```

_Resultado:_

```text
ls: cannot access '*.txt': No such file or directory
```


Con comillas, la terminal no expande nada y `ls` busca un fichero cuyo nombre sea literalmente `*.txt`, que no existe. Las comillas simples **apagan** los comodines.
</details>


---

## ✅ Resumen del capítulo 2

| Concepto | Resumen |
|---|---|
| Comodines | Los expande **la terminal** antes de ejecutar el comando. Sirven para **nombres de fichero**. |
| Expresiones regulares | Las interpreta **el programa** (`grep`, `sed`…). Sirven para **contenido**. |
| `*` terminal | "cualquier cosa" |
| `*` regex | "el carácter anterior, 0 o más veces" |
| `echo comando…` | Te enseña cómo queda la orden **después** de expandir comodines |
| Regla de oro | **Patrones de `grep` entre comillas simples** |
| `find -name` | Usa comodines, pero **los interpreta `find`**: hay que ponerlos entre comillas |

➡️ **Siguiente parada:** el [Capítulo 3](03-punto-y-anclas.md): por fin, los primeros **superpoderes** de las regex: el punto, el circunflejo y el dólar.

---
⬅️ [Capítulo 1 · Tu primer `grep`: encontrar agujas en pajares](01-primer-grep.md) · 🏠 [Índice](README.md) · [Capítulo 3 · El punto y las anclas: `.` `^` `$` `\`](03-punto-y-anclas.md) ➡️
