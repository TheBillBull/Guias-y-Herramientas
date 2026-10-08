# Capítulo 13 · Nivel master: `grep -P`, `\K` y mirar alrededor

> 🎯 **Objetivo:** hacer con **UN solo comando** lo que antes hacías con tres o cuatro: extraer solo el dato que quieres, imponer varias condiciones a la vez y "mirar alrededor" sin consumir caracteres. Aquí está el **"ejercicio 2" de tu profe**: *"devolver solo la versión numérica de las líneas que empiecen por VERSION"*.
>
> 📘 **LPIC-1:** `grep -P` **no entra en el examen** (es PCRE, no POSIX). Pero en el trabajo real es oro. Todo lo anterior (BRE/ERE) **sí** entra.
>
> 🧪 `cd ~/lab-regex` · Requiere `grep` con soporte PCRE (en Ubuntu viene de serie).

---

## 13.1 · ¿Qué es `-P`?

`grep -P` usa **PCRE** (*Perl-Compatible Regular Expressions*): las expresiones regulares de Perl, las mismas que usan Python, PHP, JavaScript… con **extras muy potentes**:

| Extra | Qué hace |
|---|---|
| `\d` `\D` | un dígito / un no-dígito |
| `\w` `\W` `\s` `\S` | palabra / no-palabra / espacio / no-espacio |
| `\K` | **"olvida lo que llevo y empieza a contar desde aquí"** |
| `(?=…)` `(?!…)` | **mirar adelante** (*lookahead*): ¿lo que viene es / no es…? |
| `(?<=…)` `(?<!…)` | **mirar atrás** (*lookbehind*) |
| `*?` `+?` `??` | cuantificadores **perezosos** (no voraces) |
| `(?:…)` | grupo que **no captura** (no gasta número de `\1`) |
| `(?i)` | ignorar mayúsculas **solo desde aquí** |
| `\p{Lu}` `\p{Ll}` | letra mayúscula / minúscula **Unicode** |

> ⚠️ **Portabilidad:** `-P` existe en el `grep` de GNU (Linux), pero **no** en el `grep` de macOS ni en BusyBox/Alpine (por defecto). Si escribes un script para servidores variados, comprueba con `grep -P ''  </dev/null` o usa `sed`/`awk`.

---

## 13.2 · `\K`: el truco estrella ⭐

Con `grep -o` extraemos **lo que coincide**. Si queremos **solo una parte** del texto que sigue a una pista, necesitaríamos descartar la pista. Con **`\K`** (*keep*), todo lo que se haya leído hasta ese punto **se olvida** y la coincidencia empieza **desde ahí**:

```text
^VERSION="\K[0-9.]+
 └─ pista (se lee, pero se descarta) ─┘ └─ lo que quiero ─┘
```

### 🎯 El ejercicio 2 de tu profe, en un solo comando

> *"Escribir una expresión regular que me devuelva solo la versión numérica de las líneas que comiencen por VERSION."*

```bash
grep -oP '^VERSION="\K[0-9.]+' /etc/os-release
```

_Resultado:_

```text
24.04.1
```


¡Exactamente `24.04.1`! Descomposición:

- `^VERSION="` → líneas que empiezan por `VERSION="` (la pista).
- `\K` → "olvida todo lo leído hasta aquí".
- `[0-9.]+` → los números y puntos que siguen = **la versión**.
- `-o` → imprime solo la coincidencia (lo que queda tras `\K`).
- `-P` → habilita `\K` (es de PCRE).

**¿Y si queremos las dos líneas `VERSION_ID` y `VERSION`?** (todas las que **empiezan por `VERSION`**, como decía el enunciado):

```bash
grep -oP '^VERSION[^=]*="\K[0-9.]+' /etc/os-release
```

_Resultado:_

```text
24.04
24.04.1
```


`[^=]*` = "lo que sea hasta el `=`" (la parte `_ID` o nada). Salen `24.04` (de `VERSION_ID`) y `24.04.1` (de `VERSION`). `VERSION_CODENAME=noble` no sale: no tiene versión numérica.

### El mismo resultado **sin `-P`** (con más comandos)

| Forma | Comandos | Dificultad |
|---|---|---|
| `grep -oP '^VERSION="\K[0-9.]+'` | **1** | master |
| `sed -n 's/^VERSION="\([0-9.]*\).*/\1/p'` | **1** | media (sed) |
| `grep '^VERSION' f \| grep -o '[0-9][0-9.]*'` | 2 | fácil |
| `grep '^VERSION' f \| cut -d'"' -f2 \| cut -d' ' -f1` | 3 | rudimentaria |

```bash
grep -oP '^VERSION="\K[0-9.]+' /etc/os-release
# Otra forma equivalente:
sed -n 's/^VERSION="\([0-9.]*\).*/\1/p' /etc/os-release
```

_Resultado:_

```text
24.04.1
```


Las dos primeras filas dan el mismo resultado. (La 3.ª devuelve `24.04 24.04.1`, porque filtra *todas* las líneas `VERSION…`.)

---

## 13.3 · Mirar alrededor (*lookaround*) sin gastar caracteres

A veces quieres que algo **esté (o no esté) pegado** al trozo que buscas, **sin que ese "algo" forme parte de la coincidencia**. Eso son los **lookarounds**: condiciones de **ancho cero** (como `\b`, `^`, `$`, pero hechas a medida).

| Sintaxis | Nombre | Significa |
|---|---|---|
| `X(?=Y)` | **lookahead** positivo | `X` **seguido de** `Y` (sin incluir `Y`) |
| `X(?!Y)` | lookahead negativo | `X` **no seguido de** `Y` |
| `(?<=Y)X` | **lookbehind** positivo | `X` **precedido de** `Y` (sin incluir `Y`) |
| `(?<!Y)X` | lookbehind negativo | `X` **no precedido de** `Y` |

Ejemplos:

```bash
echo 'precio: 25 euros, 30 dolares, 8 euros' | grep -oP '\d+(?= euros)'
```

_Resultado:_

```text
25
8
```


Los números **seguidos de ` euros`** (`25` y `8`), sin la palabra "euros" en la salida.

```bash
printf 'foobar\nfoobaz\nfoo\n' | grep -P 'foo(?!bar)'
```

_Resultado:_

```text
foobaz
foo
```


`foo` **no seguido de** `bar`: salen `foobaz` y `foo`.

### Extraer una IPv4 *exacta* (¡la regex que prometí en el capítulo 12!)

Con `-E` no podíamos evitar que de `1.2.3.4.5` extrajera `1.2.3.4`. Con lookarounds sí: "**no precedida** de dígito o punto" y "**no seguida** de dígito (ni de punto+dígito)":

```bash
OCT='(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)'
grep -oP "(?<![\d.])($OCT\.){3}$OCT(?!\d|\.\d)" ips.txt | tr '\n' ' '
```

_Resultado:_

```text
192.168.1.1 10.0.0.1 172.16.254.1 255.255.255.255 0.0.0.0 127.0.0.1 8.8.8.8 1.1.1.1 8.8.4.4 192.168.0.254 203.0.113.45 198.51.100.7 192.168.0.1 10.0.0.0 192.168.1.0 10.10.10.10 10.10.10.11 1.2.3.4 192.168.1.100 
```


Ya no sale el `1.2.3.4` de `1.2.3.4.5`. Pero **sí** sale el de la frase *"version 1.2.3.4 del programa"* (aquí no hay más dígitos pegados).

---

## 13.4 · "Y" y "NO" en un solo patrón

El lookahead permite poner **varias condiciones sobre la misma línea**, en cualquier orden:

```text
^(?=.*A)(?=.*B)(?=.*C)     →  la línea contiene A, B y C  (en cualquier orden)
^(?!.*X)                   →  la línea NO contiene X
```

> `^(?=…)` mira desde el principio "sin moverse". Cada `(?=.*COSA)` comprueba que `COSA` aparece **en algún sitio** de la línea. Como no consumen, se pueden encadenar.

### Contraseña "fuerte" en un solo `grep`

¿Recuerdas la tubería de cuatro `grep` del capítulo 4? Ahora, **uno**:

```bash
grep -P '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[[:punct:]]).{8,}$' contrasenas.txt
```

_Resultado:_

```text
Password1!
S3gura!2024
corta1A!
Mi_Clave-Segura_99
a b c 1 A !
```


Mayúscula **y** minúscula **y** dígito **y** signo de puntuación **y** al menos 8 caracteres.

### "Contiene A pero no B"

```bash
grep -cP '^(?!.*[Ii]nvalid user).*Failed password' /var/log/auth.log
# Otra forma equivalente:
grep 'Failed password' /var/log/auth.log | grep -vic 'invalid user'
```

_Resultado:_

```text
3
```


Los intentos fallidos de **usuarios que existen** (no `invalid user`): 3, de las dos formas. La primera, en un solo `grep`.

---

## 13.5 · Perezoso en vez de voraz: `*?`

Ya conoces el problema: `<.*>` se come de más. En PCRE ponemos un **`?` tras el cuantificador** y se vuelve **perezoso** (coge **lo mínimo**):

```bash
sed -n 4,5p html.txt | grep -oP '<.*?>'
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


`<.*?>` = "un `<`, lo mínimo posible, un `>`": cada etiqueta por separado, sin recurrir al `[^>]*`.

Y juntando **perezoso + `\K` + lookahead**, para sacar el contenido de comillas:

```bash
grep -oP 'href="\K[^"]*' html.txt
```

_Resultado:_

```text
https://www.ejemplo.com
http://otro.org/pagina
```


(¡Esta es la que te dejé pendiente en el capítulo 5: **solo la URL**, sin `href="` ni la comilla!)

---

## 13.6 · Otras armas de PCRE

**Ignorar mayúsculas en parte del patrón:** `(?i)`.

```bash
printf 'Error\nERROR\nerror\nerRor\n' | grep -cP '(?i)error'
```

_Resultado:_

```text
4
```


**Grupos que no capturan:** `(?:…)` agrupa **sin** gastar un número de grupo (útil con `\1`):

```bash
grep -oiP '#(?:[0-9a-f]{3}){1,2}\b' colores.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
#FFF #ffffff #1a2B3c #ff0000 #00f 
```


**Palabras repetidas** (con `\1`, que en PCRE distingue `\w` y `\s`):

```bash
grep -oiP '\b(\w+)\s+\1\b' frases.txt
```

_Resultado:_

```text
El el
a a
```


**Letras con tilde y mayúsculas Unicode:** `\p{Lu}` (mayúscula), `\p{Ll}` (minúscula):

```bash
echo 'Árbol ñandú Zorro' | grep -oP '\p{Lu}\p{Ll}+'
```

_Resultado:_

```text
Árbol
Zorro
```


---

## 13.7 · Varias líneas a la vez: `-z` con `-P`

`grep` trabaja **línea a línea**. Con **`-z`** (*null data*) lee el fichero entero como **una sola "línea"** (separada por NULs), y entonces `\n` es un carácter más. Con `(?s)` el punto `.` también casa con saltos de línea. Así se extraen **bloques**:

```bash
grep -Pzo '(?s)\[base_datos\].*?(?=\n\n|\n\[|\z)' conf-ejemplo.conf | tr -d '\0'; echo
```

_Resultado:_

```text
[base_datos]
usuario = admin
clave = s3creta
host = 192.168.1.50
puerto=5432
```


Es la **sección `[base_datos]`** de un fichero INI, desde su título hasta la siguiente línea vacía o sección. (`tr -d '\0'` quita el NUL con que `-z` termina la salida.)

---

## 13.8 · Receta: "campo N" de un fichero con `:`

```text
^([^:]*:){N-1}\K[^:]*
```

Para el 6.º campo de `/etc/passwd` (la carpeta personal):

```bash
grep -oP '^([^:]*:){5}\K[^:]*' /etc/passwd | head -4
```

_Resultado:_

```text
/root
/usr/sbin
/bin
/dev
```


Y con lookahead se pueden **filtrar por un campo y mostrar otro**: *los nombres de los usuarios cuyo UID sea de 1000 a 59999*:

```bash
grep -oP '^[^:]+(?=:[^:]*:([1-9]\d{3}|[1-5]\d{4}):)' /etc/passwd | tr '\n' ' '; echo
```

_Resultado:_

```text
alumno ana luis marta pedro invitado backup2 
```


---

## 13.9 · El árbol de decisión del "mínimo número de comandos"

```text
¿Qué quiero?
 ├─ Seleccionar LÍNEAS enteras                 → grep  (con -E para legibilidad)
 ├─ Extraer un TROZO continuo de cada línea    → grep -o   (o grep -oP con \K)
 ├─ Varias condiciones a la vez (Y / NO)       → grep -P con (?=…) (?!…)
 ├─ Reordenar/transformar campos               → sed -E 's/…/\2:\1/'     (cap. 14)
 ├─ Cálculos o condiciones numéricas           → awk
 └─ Contar / ranking                           → grep -c, o  … | sort | uniq -c | sort -rn
```

---

## 13.10 · 🏋️ Ejercicios: `\K` y extracción

#### 🟢 Ejercicio 13.1 · ⭐ La versión numérica de tu profe

Devuelve **solo la versión numérica** de la línea `VERSION="…"` de `/etc/os-release`, en **un solo comando**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^VERSION="\K[0-9.]+' /etc/os-release
```

_Resultado:_

```text
24.04.1
```


`\K` descarta `VERSION="` y `-o` imprime solo `24.04.1`.
</details>


#### 🟢 Ejercicio 13.2 · Las dos versiones

Devuelve las **dos** versiones numéricas de las líneas que **empiezan por `VERSION`** (la de `VERSION_ID` y la de `VERSION`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^VERSION[^=]*="\K[0-9.]+' /etc/os-release
```

_Resultado:_

```text
24.04
24.04.1
```

</details>


#### 🟢 Ejercicio 13.3 · La misma, sin `-P`

Obtén `24.04.1` con **otras dos formas**: una con `sed` y otra con dos `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n 's/^VERSION="\([0-9.]*\).*/\1/p' /etc/os-release
# Otra forma equivalente:
grep '^VERSION=' /etc/os-release | grep -o '[0-9][0-9.]*'
```

_Resultado:_

```text
24.04.1
```


`sed` captura `\([0-9.]*\)` y lo devuelve (`\1`); con `grep`, el primero elige la línea (`VERSION=` exacto) y el segundo extrae los números.
</details>


#### 🟢 Ejercicio 13.4 · El nombre de la versión

Extrae **solo la palabra** de `VERSION_CODENAME` (`noble`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^VERSION_CODENAME=\K\w+' /etc/os-release
```

_Resultado:_

```text
noble
```

</details>


#### 🟢 Ejercicio 13.5 · Sin comillas

Extrae el valor de `PRETTY_NAME` **sin comillas**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^PRETTY_NAME="\K[^"]+' /etc/os-release
```

_Resultado:_

```text
Ubuntu 24.04.1 LTS
```


`[^"]+` = todo lo que no sea comilla: se detiene en la comilla de cierre.
</details>


#### 🟢 Ejercicio 13.6 · El valor de `ID`

Extrae el valor de la clave `ID=` (y no de `ID_LIKE=`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^ID=\K.*' /etc/os-release
```

_Resultado:_

```text
ubuntu
```


El `^ID=` (con `=`) descarta `ID_LIKE`.
</details>


#### 🟢 Ejercicio 13.7 · El puerto de ssh

Muestra **solo el número de puerto** del servicio `ssh` en `/etc/services`, en un solo comando.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^ssh\s+\K\d+' /etc/services
```

_Resultado:_

```text
22
```


(En el capítulo 10 lo hacíamos con dos `grep` en tubería.)
</details>


#### 🟢 Ejercicio 13.8 · Solo los números

Extrae **todos los números** (secuencias de dígitos) de `frases.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '\d+' frases.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
14 2024 3 2 15 612345678 
```

</details>


#### 🟢 Ejercicio 13.9 · Solo la URL

Extrae **solo la URL** (sin `href="` ni comillas) de los enlaces de `html.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'href="\K[^"]*' html.txt
```

_Resultado:_

```text
https://www.ejemplo.com
http://otro.org/pagina
```

</details>


#### 🟢 Ejercicio 13.10 · Usuario y dominio de un correo

De la cadena `juan@cas-training.com`, extrae **solo el usuario** y, en otra orden, **solo el dominio**.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'juan@cas-training.com' | grep -oP '^[^@]+(?=@)'
echo 'juan@cas-training.com' | grep -oP '(?<=@).*'
```

_Resultado:_

```text
juan
cas-training.com
```


Lookahead `(?=@)` ("seguido de `@`") para el usuario; lookbehind `(?<=@)` ("precedido de `@`") para el dominio. También valdría `@\K.*`.
</details>


#### 🟡 Ejercicio 13.11 · El nombre de máquina de /etc/hosts

Muestra **solo el nombre principal** (2.ª columna) de las líneas **activas** de `/etc/hosts`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^[^#\s]\S*\s+\K\S+' /etc/hosts
```

_Resultado:_

```text
localhost
ubuntu-pc
servidor.miempresa.com
impresora.miempresa.com
nas.miempresa.com
backup.miempresa.es
ip6-localhost
ip6-localnet
ip6-mcastprefix
ip6-allnodes
ip6-allrouters
```


`^[^#\s]\S*` = primer campo (que no empiece por `#` ni espacio), `\s+` separador, `\K` y `\S+` = segundo campo.
</details>


#### 🟡 Ejercicio 13.12 · La carpeta personal

Muestra **solo la carpeta personal** (6.º campo) de cada usuario.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^([^:]*:){5}\K[^:]*' /etc/passwd | head -5
```

_Resultado:_

```text
/root
/usr/sbin
/bin
/dev
/bin
```


`([^:]*:){5}` salta 5 campos, `\K` los olvida y `[^:]*` captura el 6.º.
</details>


#### 🟡 Ejercicio 13.13 · Usuarios con bash (sin `cut`)

Muestra **solo los nombres** de los usuarios cuya shell es `/bin/bash`, con **un solo `grep`**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^[^:]+(?=:.*:/bin/bash$)' /etc/passwd
```

_Resultado:_

```text
root
postgres
alumno
ana
pedro
```


El nombre `^[^:]+` solo cuenta si **va seguido** de "lo que sea y acaba en `:/bin/bash`" (lookahead). Antes: `grep … | cut -d: -f1`.
</details>


#### 🟡 Ejercicio 13.14 · UID de personas, solo el nombre

Muestra **solo el nombre** de los usuarios con UID de **1000 a 59999**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^[^:]+(?=:[^:]*:([1-9]\d{3}|[1-5]\d{4}):)' /etc/passwd | tr '\n' ' '; echo
```

_Resultado:_

```text
alumno ana luis marta pedro invitado backup2 
```

</details>


#### 🟡 Ejercicio 13.15 · Ranking de atacantes con un grep menos

Obtén el **ranking de IPs** con intentos fallidos de contraseña en `auth.log`, extrayendo la IP **directamente** con `\K` (sin segundo `grep`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'Failed password .* from \K[\d.]+' /var/log/auth.log | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      5 203.0.113.45
      3 203.0.113.99
      3 198.51.100.23
      1 192.168.1.51
```


Antes: `grep 'Failed password' … | grep -oE '([0-9]{1,3}\.){3}…'`. Ahora la IP se extrae en el mismo `grep`.
</details>


#### 🟡 Ejercicio 13.16 · Nombres de usuario inválidos

Extrae **solo el nombre** de los `Invalid user NOMBRE` de `auth.log`, con recuento.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'Invalid user \K\S+' /var/log/auth.log | sort | uniq -c
```

_Resultado:_

```text
      1 admin
      1 guest
      1 oracle
      1 test
```

</details>


#### 🟡 Ejercicio 13.17 · Solo el comando de sudo

Extrae **solo el comando** (lo que va tras `COMMAND=`) de las líneas de `sudo`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'COMMAND=\K.*' /var/log/auth.log
```

_Resultado:_

```text
/usr/bin/apt update
/usr/bin/apt install -y nano vim curl git
/usr/bin/systemctl restart ssh
/usr/bin/cat /etc/shadow
/usr/sbin/useradd -m -s /bin/bash pedro
```

</details>


#### 🟡 Ejercicio 13.18 · Quién entró

Extrae **solo el nombre de usuario** de cada `Accepted …` de `auth.log`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'Accepted \w+ for \K\w+' /var/log/auth.log | sort | uniq -c
```

_Resultado:_

```text
      2 alumno
      1 ana
      2 luis
```

</details>


#### 🟡 Ejercicio 13.19 · Puertos del cortafuegos

Muestra el **ranking de puertos de destino** de `ufw.log` mostrando **solo el número** (sin `DPT=`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'DPT=\K\d+' /var/log/ufw.log | sort -n | uniq -c | sort -rn | head -4
```

_Resultado:_

```text
     13 22
      5 23
      3 8080
      3 443
```

</details>


#### 🟡 Ejercicio 13.20 · Estados HTTP limpios

Muestra el reparto de **códigos de estado** HTTP de `access.log` mostrando **solo el código** (sin comilla ni espacios).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '" \K\d{3}(?= )' /var/log/apache2/access.log | sort | uniq -c
```

_Resultado:_

```text
     80 200
      3 301
      2 302
      6 304
      2 400
      2 401
      3 403
     18 404
      5 500
```


`" \K\d{3}(?= )` = comilla y espacio (se descartan), 3 dígitos, y **seguidos** de un espacio (sin incluirlo).
</details>


#### 🟡 Ejercicio 13.21 · Nombres de paquetes

Extrae **solo los nombres** de paquete (sin `install ` ni `:arquitectura`) de las líneas `install` de `dpkg.log`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP ' install \K[^:]+' /var/log/dpkg.log | tr '\n' ' '; echo
```

_Resultado:_

```text
nano vim curl git tree htop openssh-server apache2 net-tools ufw 
```

</details>


#### 🟡 Ejercicio 13.22 · De la versión vieja a la nueva

En las líneas `upgrade` de `dpkg.log`, extrae **solo la versión nueva** (el último campo).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP ' upgrade .* \K\S+$' /var/log/dpkg.log
```

_Resultado:_

```text
3.0.13-0ubuntu3.4
1:9.6p1-3ubuntu13.5
3.12.3-1ubuntu0.3
6.8.0-45.45
```


`.* ` es voraz y llega hasta el último espacio; `\K\S+$` deja solo el último campo.
</details>


---

## 13.11 · 🏋️ Ejercicios: lookahead y condiciones múltiples

#### 🟡 Ejercicio 13.23 · Contraseña fuerte en un solo grep

Muestra las contraseñas de `contrasenas.txt` con **mayúscula, minúscula, dígito, signo de puntuación y 8 o más caracteres**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -P '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[[:punct:]]).{8,}$' contrasenas.txt
```

_Resultado:_

```text
Password1!
S3gura!2024
corta1A!
Mi_Clave-Segura_99
a b c 1 A !
```

</details>


#### 🟡 Ejercicio 13.24 · Dos palabras en cualquier orden

Cuenta las líneas de `auth.log` que contienen **a la vez** `Failed` y `root`, **en cualquier orden**, con un solo `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cP '^(?=.*Failed)(?=.*root)' /var/log/auth.log
```

_Resultado:_

```text
2
```


Con `-E` habría que escribir `Failed.*root|root.*Failed`; con lookahead basta una condición por palabra.
</details>


#### 🟡 Ejercicio 13.25 · Fallos de usuarios que existen

Cuenta los `Failed password` que **no** sean de un `invalid user`, en un solo patrón. Verifícalo con la forma de dos `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cP '^(?!.*[Ii]nvalid user).*Failed password' /var/log/auth.log
# Otra forma equivalente:
grep 'Failed password' /var/log/auth.log | grep -vic 'invalid user'
```

_Resultado:_

```text
3
```

</details>


#### 🟡 Ejercicio 13.26 · Líneas sin dos palabras

Cuenta las líneas de `syslog` que **no** contienen ni `CRON` ni `systemd`, con un patrón y con `-v`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cP '^(?!.*(CRON|systemd))' /var/log/syslog
# Otra forma equivalente:
grep -cvE 'CRON|systemd' /var/log/syslog
```

_Resultado:_

```text
38
```


La versión `-vE` es más sencilla aquí; el lookahead negativo brilla cuando se **combina** con condiciones positivas.
</details>


#### 🔴 Ejercicio 13.27 · Palabras con las 5 vocales

Muestra, de `murcielago`, `mesa`, `educacion`, `unico`, las palabras que contienen **las cinco vocales**.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'murcielago\nmesa\neducacion\nunico\n' | grep -P '^(?=.*a)(?=.*e)(?=.*i)(?=.*o)(?=.*u)'
```

_Resultado:_

```text
murcielago
educacion
```


Cinco lookaheads: "hay una `a` en algún sitio", "hay una `e`"… Cada condición es independiente: el orden no importa.
</details>


#### 🔴 Ejercicio 13.28 · `foo` pero no `foobar`

De `foobar`, `foobaz`, `foo`, muestra las que contienen `foo` **sin** que vaya seguido de `bar`.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'foobar\nfoobaz\nfoo\n' | grep -P 'foo(?!bar)'
```

_Resultado:_

```text
foobaz
foo
```

</details>


#### 🔴 Ejercicio 13.29 · IPv4 exacta con lookaround

Extrae las IPv4 **válidas** de `ips.txt`, sin coger trozos de números mayores (`1.2.3.4.5` no debe dar `1.2.3.4`).

<details>
<summary>💡 Ver solución</summary>


```bash
OCT='(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)'
grep -oP "(?<![\d.])($OCT\.){3}$OCT(?!\d|\.\d)" ips.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
192.168.1.1 10.0.0.1 172.16.254.1 255.255.255.255 0.0.0.0 127.0.0.1 8.8.8.8 1.1.1.1 8.8.4.4 192.168.0.254 203.0.113.45 198.51.100.7 192.168.0.1 10.0.0.0 192.168.1.0 10.10.10.10 10.10.10.11 1.2.3.4 192.168.1.100 
```


`(?<![\d.])` = no precedida de dígito ni punto. `(?!\d|\.\d)` = no seguida de dígito ni de "punto + dígito" (así permitimos un punto de final de frase).
</details>


#### 🔴 Ejercicio 13.30 · Una IP asignada a una clave

En `/etc/netplan/01-network.yaml`, extrae **solo la IP** que aparece tras `- ` en la sección `addresses` (sin la máscara `/24`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP -- '- \K[\d.]+(?=/)' /etc/netplan/01-network.yaml
```

_Resultado:_

```text
192.168.1.37
```


`- \K` descarta el guion del elemento de lista; `[\d.]+` la IP; `(?=/)` exige que la siga `/` pero **sin** incluirla. (El `--` evita que `-` se interprete como opción.)
</details>


#### 🔴 Ejercicio 13.31 · Hex válido

Extrae los colores hexadecimales válidos (`#` + 3 o 6 cifras hex) de `colores.txt`, sin importar mayúsculas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oiP '#(?:[0-9a-f]{3}){1,2}\b' colores.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
#FFF #ffffff #1a2B3c #ff0000 #00f 
```


`(?:[0-9a-f]{3}){1,2}` = un grupo de 3 cifras hex repetido 1 o 2 veces = 3 o 6 cifras. `(?:…)` no captura.
</details>


#### 🔴 Ejercicio 13.32 · Mayúscula Unicode

Extrae las palabras que **empiezan por mayúscula** (incluida `Á`, `Ñ`…) de `Árbol ñandú Zorro Ñu`.

<details>
<summary>💡 Ver solución</summary>


```bash
echo 'Árbol ñandú Zorro Ñu' | grep -oP '\p{Lu}\p{L}*'
```

_Resultado:_

```text
Árbol
Zorro
Ñu
```


`\p{Lu}` = letra mayúscula (cualquier idioma); `\p{L}*` = más letras.
</details>


#### 🔴 Ejercicio 13.33 · Palabras repetidas (otra vez)

Encuentra, sin importar mayúsculas, las palabras **duplicadas** consecutivas de `frases.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oiP '\b(\w+)\s+\1\b' frases.txt
```

_Resultado:_

```text
El el
a a
```

</details>


---

## 13.12 · 🏋️ Ejercicios: recuentos exactos, bloques y retos finales (con `-E` y `-P`)

#### 🟡 Ejercicio 13.34 · Exactamente dos "a"

Muestra las palabras de `palabras.txt` que tienen **exactamente dos letras `a`** (ni una ni tres).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^([^a]*a){2}[^a]*$' palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
gata casa Casa casas cama caña ala anilina radar aa abcabc programa programación programador casa 
```


`([^a]*a){2}` = dos veces "lo que no sea `a`, y una `a`"; `[^a]*$` = el resto sin ninguna más. Es un **contador de apariciones**, y funciona sin PCRE.
</details>


#### 🟡 Ejercicio 13.35 · Exactamente seis comas

Muestra las líneas de `usuarios.csv` que tienen **exactamente 6 comas** (7 campos).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '^([^,]*,){6}[^,]*$' usuarios.csv
```

_Resultado:_

```text
13
```


13 = la cabecera y las 12 personas. Los campos vacíos cuentan igual.
</details>


#### 🔴 Ejercicio 13.36 · El `usuarios.csv` "malo"

En `csv-dificil.csv` cada línea **debería** tener 3 campos (2 comas), pero algunas tienen comas dentro de comillas. Muestra las líneas con **más de 2 comas**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^([^,]*,){3,}' csv-dificil.csv
```

_Resultado:_

```text
1,"Pérez, Luis","Le gusta Linux, grep y sed"
3,"Ruiz, Marta","Dice: ""hola, mundo"""
4,Pedro,"Una coma, otra coma, otra más"
```


`{3,}` = 3 o más comas. (Ahí se ve la coma "con doble vida": separadora y dentro de comillas.)
</details>


#### 🔴 Ejercicio 13.37 · Un bloque INI entero

Muestra la sección `[servidor]` de `conf-ejemplo.conf` (desde su título hasta antes de la siguiente sección).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Pzo '(?s)\[servidor\].*?(?=\n\[|\z)' conf-ejemplo.conf | tr -d '\0'; echo
```

_Resultado:_

```text
[servidor]
puerto = 8080
host=localhost
    # comentario con sangria
debug = true
```


`-z` lee el fichero entero como una línea; `(?s)` hace que `.` incluya saltos de línea; `.*?` es perezoso y se detiene ante `\n[` (la siguiente sección) o el final del fichero (`\z`).
</details>


#### 🔴 Ejercicio 13.38 · Valores que son IPs

En `conf-ejemplo.conf`, extrae **solo el valor** de las claves cuyo valor es una **dirección IP** (`clave = 192.168.1.50`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^\s*\w+\s*=\s*\K(\d{1,3}\.){3}\d{1,3}' conf-ejemplo.conf
```

_Resultado:_

```text
192.168.1.50
```


`^\s*\w+\s*=\s*` es la clave y el igual (se descarta con `\K`); luego, cuatro números separados por puntos.
</details>


#### ⚫ Ejercicio 13.39 · Claves y valores de la sección `[correo]`

Extrae **solo el nombre de las claves** de la sección `[correo]` de `conf-ejemplo.conf`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Pzo '(?s)\[correo\]\n\K.*?(?=\n#|\n\[|\z)' conf-ejemplo.conf | tr -d '\0' | grep -oP '^\w+'
```

_Resultado:_

```text
smtp
puerto
remitente
```


El primer `grep -Pzo` aísla el contenido de la sección (con `\K` para olvidar el título) y el segundo extrae la clave de cada línea (`^\w+`). En total dos comandos: para una sola orden se usaría `awk`.
</details>


---

## ✅ Resumen del capítulo 13

| Quiero… | Receta |
|---|---|
| **Solo el valor** tras una clave | `grep -oP 'CLAVE=\K.*'` |
| **Campo N** de una línea con `:` | `grep -oP '^([^:]*:){N-1}\K[^:]*'` |
| Dato **seguido de** algo (sin incluirlo) | `X(?=Y)` |
| Dato **precedido de** algo (sin incluirlo) | `(?<=Y)X` |
| **Varias condiciones** a la vez | `^(?=.*A)(?=.*B)(?=.*C)` |
| **NO** contiene X | `^(?!.*X)` |
| Cuantificador **perezoso** | `.*?`  `+?` |
| Letras Unicode | `\p{L}` `\p{Lu}` `\p{Ll}` |
| Varias líneas | `grep -Pzo '(?s)…'` |

**Regla de oro del master:** ante un problema, pregúntate *"¿lo puedo resolver con un solo comando?"* Casi siempre sí: `grep -o`, `grep -oP` + `\K`, `sed -E`.

➡️ **Siguiente parada:** [Capítulo 14](14-sed-y-filtros.md): **`sed`** y los filtros de texto (`cut`, `sort`, `uniq`, `tr`, `wc`…): transformar y reordenar, que es lo que `grep` no hace.

---
⬅️ [Capítulo 12 · Reconocer formatos: IPv4, IPv6, correos, dominios, MAC…](12-formatos.md) · 🏠 [Índice](README.md) · [Capítulo 14 · `sed` y los filtros de texto: `cut`, `sort`, `uniq`, `tr`, `wc`…](14-sed-y-filtros.md) ➡️
