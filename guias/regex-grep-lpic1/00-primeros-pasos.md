# Capítulo 0 · Tu primera vez frente a una terminal

> 🎯 **Objetivo:** que pierdas el miedo a la pantalla negra. Al terminar sabrás moverte por las carpetas, leer ficheros y tendrás montado tu **laboratorio de prácticas**.
>
> 📘 **LPIC-1:** 103.1 (trabajar en la línea de comandos) y 103.3 (gestión básica de ficheros).
>
> 🧒 **Nivel de partida:** cero. Si ya sabes moverte por la terminal, salta al [Capítulo 1](01-primer-grep.md).

---

## 0.1 · ¿Qué es una terminal?

Imagina que tu ordenador es un **restaurante**:

- Normalmente pides la comida señalando fotos en una carta (los **iconos y ventanas**: eso es el *entorno gráfico*).
- Pero también puedes hablar **directamente con el cocinero**, por escrito, con frases muy cortas y precisas. Eso es la **terminal**.

La terminal es una ventana donde **escribes órdenes** (se llaman **comandos**) y el ordenador te contesta con texto. No hay botones: solo tú, el teclado y el texto.

¿Y por qué querer hablar con el cocinero si hay fotos en la carta? Porque con palabras puedes pedir cosas que la carta no tiene, y puedes pedir **mil cosas de golpe**. Por ejemplo: "dime cuáles de estos 50.000 renglones contienen la palabra *error*" lo haces en un segundo desde la terminal, y a mano tardarías un día.

Ese "cocinero" que te entiende se llama **shell** (en Ubuntu, `bash`). Y la herramienta estrella de esta guía, **`grep`**, es uno de los comandos que le puedes pedir.

### Cómo abrir una terminal en Ubuntu

Pulsa a la vez **`Ctrl` + `Alt` + `T`**. Se abre una ventana con algo así:

```text
alumno@ubuntu-pc:~$ 
```

Eso se llama el **prompt** (la "invitación a escribir"). Se lee así:

| Trozo | Significa |
|---|---|
| `alumno` | **quién** eres (tu usuario) |
| `@` | "en" |
| `ubuntu-pc` | **qué máquina** es (el nombre del ordenador) |
| `:` | separador |
| `~` | **dónde estás**: `~` es tu carpeta personal (tu "casa") |
| `$` | "ya puedes escribir". Un `$` significa usuario normal. Si ves `#`, eres el administrador (**root**) y debes tener mucho más cuidado |

> ⚠️ **Regla de oro nº 1:** en esta guía, cuando veas un comando, **NO escribas el `$`**. Es solo el prompt. Escribes lo que viene después.

---

## 0.2 · Anatomía de una orden

Todas las órdenes tienen la misma forma:

```text
comando   opciones   argumentos
```

Piensa en una frase: *"**Come** (comando) **rápido** (opción) **la manzana** (argumento)"*.

- **Comando**: qué quieres hacer (`ls`, `cat`, `grep`…).
- **Opciones**: *cómo* lo quieres hacer. Empiezan por un guion (`-l`) o dos (`--help`).
- **Argumentos**: *sobre qué* lo quieres hacer (normalmente un fichero o carpeta).

Las partes se separan con **espacios**. Y ojo a estas tres cosas, que fastidian a todo el mundo al principio:

1. 🔡 **Mayúsculas y minúsculas importan.** `ls` funciona; `LS` o `Ls` no.
2. ⎵ **Los espacios importan.** `ls-l` no existe; `ls -l` sí.
3. 🤫 **Si todo va bien, la terminal casi no habla.** Muchas órdenes no dicen nada cuando funcionan. Silencio = normalmente "hecho".

Para ejecutar una orden pulsa **`Enter`** (↵).

---

## 0.3 · Los 5 comandos de supervivencia

### 1) `pwd` — ¿dónde estoy?

`pwd` significa *print working directory* ("muestra la carpeta de trabajo"). Es tu "estás aquí" del mapa del centro comercial.

```bash
pwd
```

Te contestará algo como `/home/alumno` (en tu caso, con tu nombre de usuario).

### 2) `ls` — ¿qué hay aquí?

`ls` (*list*) lista el contenido de la carpeta.

- `ls` → nombres.
- `ls -l` → formato "largo": permisos, dueño, tamaño y fecha.
- `ls -a` → incluye los ficheros **ocultos** (los que empiezan por un punto, como `.bashrc`).
- Se pueden juntar: `ls -la`.

### 3) `cd` — moverse a otra carpeta

`cd` (*change directory*) es como andar por la casa:

| Orden | Qué hace |
|---|---|
| `cd /etc` | Ir a la carpeta `/etc` (ruta **absoluta**: empieza por `/`) |
| `cd lab-regex` | Entrar en `lab-regex` que está **aquí** (ruta **relativa**) |
| `cd ..` | Subir **una** carpeta (los dos puntos significan "la de arriba") |
| `cd ~` o solo `cd` | Volver a tu casa |
| `cd -` | Volver a donde estabas antes |

El árbol de carpetas de Linux tiene **una única raíz**, la barra **`/`**. De ahí cuelga todo:

```text
/
├── etc/        ← ficheros de configuración del sistema (passwd, hosts...)
├── home/
│   └── alumno/ ← tu casa (~)
├── var/
│   └── log/    ← los registros (logs): syslog, auth.log...
├── usr/
├── bin/
└── tmp/
```

> 🧭 **Ruta absoluta** = empieza por `/` y funciona desde cualquier sitio (como una dirección completa: *"Calle Mayor 5, Madrid"*).
> **Ruta relativa** = depende de dónde estés (como decir *"la segunda a la derecha"*).

### 4) `cat` — ver un fichero entero

`cat` escupe el contenido del fichero por pantalla. Perfecto para ficheros cortos:

```bash
cat /etc/hostname
```

### 5) `less` — ver un fichero largo, página a página

Si el fichero es largo, `cat` te lo tira todo de golpe y solo ves el final. Con `less` lo lees con calma:

| Tecla | Acción |
|---|---|
| `↓` `↑` / `Espacio` / `b` | bajar, subir / página abajo / página arriba |
| `/palabra` + Enter | **buscar** "palabra" (¡y aquí también se pueden usar expresiones regulares!) |
| `n` / `N` | siguiente / anterior resultado |
| `q` | **salir** (la tecla más importante de tu vida) |

---

## 0.4 · Ver solo un trocito

Muchas veces solo quieres el principio o el final de un fichero.

| Orden | Qué hace |
|---|---|
| `head fichero` | Las **10 primeras** líneas |
| `head -n 3 fichero` | Las 3 primeras |
| `tail fichero` | Las **10 últimas** líneas |
| `tail -n 3 fichero` | Las 3 últimas |
| `wc -l fichero` | **Cuenta** las líneas (*word count*, opción `-l` = *lines*) |
| `echo hola` | Escribe "hola" en pantalla (sí, es tonto, pero lo usaremos mucho) |

---

## 0.5 · Trucos que te ahorran la mitad de las pulsaciones

| Truco | Para qué |
|---|---|
| **`Tab`** | **Autocompleta** nombres. Escribe `cat /etc/pas` y pulsa `Tab`: sale `/etc/passwd`. Si pulsas `Tab` dos veces te enseña las opciones |
| **`↑` y `↓`** | Recorren las órdenes que ya escribiste. ¡No las reescribas! |
| **`Ctrl` + `C`** | **Cancela** lo que esté pasando (si algo se queda "colgado", este es tu botón de pánico) |
| **`Ctrl` + `L`** o `clear` | Limpia la pantalla |
| **`Ctrl` + `R`** | Busca en tu historial: escribe un trozo de una orden antigua y te la recupera |
| `history` | Lista todas las órdenes que has escrito |
| **Copiar/pegar** | En la terminal es `Ctrl`+`Shift`+`C` / `Ctrl`+`Shift`+`V` (con `Ctrl`+`C` a secas **cancelarías**) |

### ¿Y si no sé cómo funciona un comando?

```text
man ls           → el manual completo de ls (se navega como less; sal con q)
ls --help        → un resumen rápido
```

El manual **es un fichero de texto en el que puedes buscar con `/`**. Más adelante verás que `man grep` y `man 7 regex` son tus mejores amigos para el examen.

---

## 0.6 · Dos símbolos mágicos que usaremos todo el rato

### La tubería `|` (pipe)

La tecla `|` (suele estar junto al `1`, o con `AltGr`+`1`). Hace que **la salida de un comando sea la entrada del siguiente**, como las tuberías de agua:

```text
comando1  |  comando2
   └─ lo que escupe ─┘ lo recibe y lo procesa
```

Ejemplo: contar cuántas líneas tiene `/etc/passwd`, pero pidiéndoselo a otro comando:

```bash
cat /etc/passwd | wc -l
```

_Resultado:_

```text
41
```


### Redirigir `>` y `2>`

- `comando > fichero` → en vez de enseñarlo por pantalla, **lo guarda** en un fichero (¡y lo pisa si ya existía!).
- `comando >> fichero` → lo **añade** al final.
- `comando 2> /dev/null` → tira a la basura los **mensajes de error** (`/dev/null` es el "agujero negro" de Linux). Lo veremos con calma en el [capítulo 9](09-opciones-de-grep.md) y, a fondo, en el [capítulo 17](17-tuberias-y-redirecciones.md).

---

## 0.7 · Reglas de seguridad (léelas, en serio)

1. 📖 **Lee antes de pulsar Enter.** Una orden mal escrita puede borrar cosas.
2. 🗑️ **No hay papelera.** `rm` borra para siempre. En esta guía **no necesitarás `rm`** fuera del laboratorio.
3. 🛑 **No uses `sudo` si no sabes por qué.** `sudo` = "hazlo como administrador". Todo lo de esta guía funciona **sin** sudo.
4. 🧪 **Practica solo en tu laboratorio** (ahora lo montamos). Si lo rompes, lo recreas con un comando y listo.
5. 🧱 **Los ficheros de `/etc` los vamos a *leer*, nunca a modificar.**

---

## 0.8 · Monta tu laboratorio 🧪

Todos los ejercicios usan unos ficheros de prueba (listas de palabras, IPs, correos, logs falsos…). Se crean con **un script**.

**Paso 1.** Descarga la guía (necesitas `git`; si no lo tienes: `sudo apt install git`):

```bash
cd ~
git clone -b claude/que-puedo-hacer-834z1j https://github.com/TheBillBull/Guias-y-Herramientas.git
```

> 📝 La parte `-b claude/que-puedo-hacer-834z1j` elige la rama donde está la guía. Cuando la guía esté en la rama principal, bastará con `git clone https://github.com/TheBillBull/Guias-y-Herramientas.git`.

**Paso 2.** Crea el laboratorio:

```bash
bash ~/Guias-y-Herramientas/guias/regex-grep-lpic1/laboratorio/preparar-laboratorio.sh
```

**Paso 3.** Entra y mira:

```bash
cd ~/lab-regex
ls
```

Verás algo así:

```bash
ls
```

_Resultado:_

```text
agenda.txt         dni.txt       matriculas.txt  sin-salto-final.txt
arbol              dominios.txt  nombres.txt     sistema
binario.bin        fechas.txt    numeros.txt     tabulado.tsv
colores.txt        frases.txt    palabras.txt    telefonos.txt
conf-ejemplo.conf  html.txt      poema.txt       urls.txt
contrasenas.txt    ips.txt       programa.py     usuarios.csv
correos.txt        ipv6.txt      repetidas.txt   versiones.txt
csv-dificil.csv    macs.txt      salidas         windows.txt
```


> 🔁 **Si algo se estropea**, o quieres empezar de cero, vuelve a ejecutar el Paso 2. Deja todo como nuevo.

### ¿Y los ficheros de `/etc`? ¿Y los logs?

En los ejercicios verás comandos sobre ficheros **reales** del sistema, como `/etc/passwd`. Funcionan en tu Ubuntu tal cual.

Pero tu `/etc/passwd` no es igual que el mío, así que **las salidas que ves en este libro vienen de una copia de ejemplo** de un Ubuntu típico (está en `~/lab-regex/sistema/`). Tu salida será *parecida* pero no idéntica (otros usuarios, otras fechas…). Lo importante es entender el filtro. Si quieres que te salga **exactamente** igual que en el libro, usa la copia:

```bash
grep root ~/lab-regex/sistema/etc/passwd
```

Y en vez de `/var/log/syslog` (que además suele requerir permisos especiales), el laboratorio trae `sistema/var/log/syslog`, `auth.log`, `kern.log`, `dpkg.log`, `ufw.log`… ya preparados para que practiques con calma.

---

## 0.9 · Cómo leer esta guía

Cada ejercicio tiene un nivel:

| Icono | Nivel | Significa |
|---|---|---|
| 🟢 | Fácil | Aplicar lo que acabas de aprender |
| 🟡 | Medio | Combinar dos o tres ideas |
| 🔴 | Difícil | Hay que pensar un rato |
| ⚫ | Master | Retos de verdad, a menudo en **un solo comando** |

Y cada ejercicio tiene la solución **escondida** en un desplegable:

<details>
<summary>💡 Ver solución (pruébame, haz clic)</summary>

¡Así! Pero **inténtalo primero tú**. Si miras la solución sin pensar, no aprendes: es como ir al gimnasio y ver cómo entrena otro.

La técnica que funciona: **(1)** lee el enunciado, **(2)** escribe tu intento, **(3)** ejecútalo, **(4)** si no sale, piensa por qué, **(5)** solo entonces mira la solución.

</details>

Cuando una solución muestra **`« »`**, es porque en tu terminal verás esa parte **en rojo**: es lo que `grep` ha considerado "coincidencia". En un libro no se puede poner color, así que lo marcamos con comillas angulares.

---

## 0.10 · 🏋️ Calentamiento

#### 🟢 Ejercicio 0.1 · ¿Dónde estoy?

Entra en el laboratorio y comprueba en qué carpeta estás.

<details>
<summary>💡 Ver solución</summary>


```bash
cd ~/lab-regex
pwd
```

_Resultado:_

```text
/home/alumno/lab-regex
```


`cd ~/lab-regex` te mueve y `pwd` confirma dónde estás. (En tu máquina saldrá tu usuario en lugar de `alumno`.)
</details>


#### 🟢 Ejercicio 0.2 · Cuenta los ficheros

Sin entrar en detalle: ¿cuántos elementos hay en el laboratorio? (Pista: `ls` y `wc -l` unidos con una tubería.)

<details>
<summary>💡 Ver solución</summary>


```bash
ls | wc -l
```

_Resultado:_

```text
32
```


`ls` escribe un nombre por línea (cuando va a una tubería) y `wc -l` cuenta líneas. Dos comandos, un resultado.
</details>


#### 🟢 Ejercicio 0.3 · Mira un fichero entero

Muestra por pantalla todo el contenido de `palabras.txt`. ¿Cuántas líneas ocupa?

<details>
<summary>💡 Ver solución</summary>


```bash
cat palabras.txt
```

_Resultado:_

```text
gato
Gato
GATO
gata
gatito
gatos
perro
Perro
… (y 63 líneas más)
```


Aquí solo se ven las 8 primeras para no llenar la página. Para saber cuántas líneas tiene:

```bash
wc -l palabras.txt
```

_Resultado:_

```text
71 palabras.txt
```


Cada línea es una palabra. Tiene 71 líneas.
</details>


#### 🟢 Ejercicio 0.4 · Las primeras líneas

Muestra solo las **5 primeras** líneas de `frases.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
head -n 5 frases.txt
```

_Resultado:_

```text
El perro come carne.
El gato duerme en el sofá.
La casa es grande y blanca.
¿Dónde está la biblioteca?
¡Qué día tan bonito!
```


`-n 5` significa "cinco líneas". También valdría la forma corta `head -5 frases.txt`.
</details>


#### 🟢 Ejercicio 0.5 · Las últimas líneas

Muestra solo las **3 últimas** líneas de `frases.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
tail -n 3 frases.txt
```

_Resultado:_

```text
Esta frase termina con espacios.   
	Esta empieza con un tabulador.
Fin.
```


Fíjate: la del medio empieza con un tabulador (por eso se ve sangrada) y la primera termina con tres espacios que no se ven. Los espacios invisibles dan mucha guerra con las expresiones regulares… ya lo verás.
</details>


#### 🟢 Ejercicio 0.6 · Una tubería con dos pasos

Muestra **solo la línea 3** de `frases.txt`. (Pista: toma las 3 primeras con `head` y de ellas solo la última con `tail`.)

<details>
<summary>💡 Ver solución</summary>


```bash
head -n 3 frases.txt | tail -n 1
```

_Resultado:_

```text
La casa es grande y blanca.
```


Primero `head` se queda con las líneas 1, 2 y 3; luego `tail -n 1` se queda con la última de ellas, o sea, la 3. ¡Tu primera tubería con dos comandos!

(Más adelante verás que con `sed` o `grep -n` se puede hacer con un solo comando.)
</details>


#### 🟢 Ejercicio 0.7 · El nombre de tu máquina

Muestra el contenido de `/etc/hostname`, que es el nombre del ordenador.

<details>
<summary>💡 Ver solución</summary>


```bash
cat /etc/hostname
```

_Resultado:_

```text
ubuntu-pc
```


En tu máquina saldrá el nombre de **tu** ordenador.
</details>


#### 🟢 Ejercicio 0.8 · Cuántos usuarios hay

Cuenta cuántas líneas tiene `/etc/passwd` (cada línea es un usuario del sistema, incluidos los "usuarios técnicos" que usan los programas).

<details>
<summary>💡 Ver solución</summary>


```bash
wc -l /etc/passwd
```

_Resultado:_

```text
41 /etc/passwd
```


Verás un número y el nombre del fichero. Si solo quieres el número: `wc -l < /etc/passwd` (el `<` le pasa el fichero por la entrada, y `wc` ya no tiene nombre que imprimir).
</details>


#### 🟢 Ejercicio 0.9 · Navega por el árbol

Ve a la carpeta `/etc`, comprueba que estás ahí, vuelve a tu casa y comprueba de nuevo.

<details>
<summary>💡 Ver solución</summary>


```bash
cd /etc
pwd
cd ~
pwd
```

Salida esperada:

```text
/etc
/home/alumno
```

Cuatro órdenes, una por línea. También podías haber escrito `cd /etc; pwd; cd; pwd` (el `;` encadena órdenes).
</details>


#### 🟢 Ejercicio 0.10 · Lee con calma

Abre `/etc/services` con `less`, busca la palabra `ssh` dentro, avanza al siguiente resultado y sal.

<details>
<summary>💡 Ver solución</summary>


```bash
less /etc/services
```

Dentro de `less`: escribe `/ssh` y pulsa Enter (salta a la primera coincidencia); pulsa `n` para ir a la siguiente; pulsa `q` para salir.

💡 **Ojo, primer contacto con las expresiones regulares:** lo que escribes tras `/` **es una expresión regular**. Cuando acabes la guía podrás buscar cosas como `/^ssh.*tcp` dentro de `less`.
</details>


#### 🟡 Ejercicio 0.11 · Ayuda, socorro

Averigua qué hace la opción `-v` de `grep` **sin salir de la terminal y sin buscar en internet**.

<details>
<summary>💡 Ver solución</summary>


```bash
man grep
```

Dentro del manual, pulsa `/` y escribe `-v` + Enter (`/-v`). Verás algo así: *"-v, --invert-match: Invert the sense of matching, to select non-matching lines"* — o sea: **muestra las líneas que NO contienen el patrón**. Sal con `q`.

Otra opción más rápida: `grep --help | grep -- -v` (sí, un `grep` dentro de otro; no te agobies, lo entenderás cuando acabes el capítulo 1).
</details>


#### 🟡 Ejercicio 0.12 · El primer grep (adelanto)

Aunque aún no hemos empezado, prueba esto y adivina qué hace:

```bash
grep root /etc/passwd
```

<details>
<summary>💡 Ver solución</summary>


```bash
grep root /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root»:x:0:0:«root»:/«root»:/bin/bash
```


`grep` ha leído `/etc/passwd` línea a línea y **solo ha enseñado las líneas que contienen la palabra `root`**. (Entre `« »` lo que ha coincidido.) ¡Ya sabes lo esencial de `grep`! En el siguiente capítulo lo vemos despacio.
</details>


---

## ✅ Resumen del capítulo 0

| Comando | Para qué |
|---|---|
| `pwd` | ¿dónde estoy? |
| `ls`, `ls -l`, `ls -a` | ¿qué hay aquí? |
| `cd carpeta` / `cd ..` / `cd ~` | moverme |
| `cat`, `less`, `head`, `tail` | leer ficheros |
| `wc -l` | contar líneas |
| `\|` | pasar la salida de un comando al siguiente |
| `man comando` | el manual |
| `Tab`, `↑`, `Ctrl+C` | tus tres mejores amigos |

➡️ **Siguiente parada:** el [Capítulo 1](01-primer-grep.md), donde conocerás a `grep` de verdad.

---
🏠 [Índice](README.md) · [Capítulo 1 · Tu primer `grep`: encontrar agujas en pajares](01-primer-grep.md) ➡️
