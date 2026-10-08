# Capítulo 16 · 🏆 El jefe final: misiones, retos y mini-examen

> 🎯 **Objetivo:** juntar **todo** lo aprendido. Aquí no hay un tema por capítulo: hay **problemas reales** que mezclan regex, `grep`, `sed`, ficheros del sistema y logs. Y al final, un **mini-examen tipo LPIC-1**.
>
> 📘 **LPIC-1:** 103.2 · 103.4 · 103.7 · 104.7 · 107.1 · 108.2.
>
> 🧪 `cd ~/lab-regex` · Intenta cada paso **sin mirar** y después compara.

---

## 16.1 · El método del experto en 5 pasos

Antes de escribir una sola regex, un master hace esto:

1. 👀 **Mira los datos.** `head`, `cat -A`, `less`. ¿Qué separadores hay? ¿Hay espacios invisibles, `\r`, mayúsculas?
2. 🧭 **Elige la herramienta** con el árbol de decisión:
   - elegir líneas → `grep` · extraer trozos → `grep -o` / `-oP` + `\K` · reordenar → `sed -E` · contar → `-c` / `uniq -c`.
3. 🧱 **Construye la regex por ladrillos** (variables de la terminal si es larga) y **de dentro a fuera**: primero lo más simple, luego añades condiciones.
4. 🧪 **Pruébala con casos buenos y malos.** Si no sabes qué debería fallar, no sabes qué haces.
5. ✂️ **Simplifica.** ¿Puedo hacerlo con **un solo comando**? ¿Sobra algún `cat`, `cut`, `wc`?

---

## 16.2 · 🕵️ Misión 1: "¿Nos han atacado?"

Eres el administrador y sospechas de un ataque por SSH. Tienes `auth.log`, `ufw.log` y el `access.log` de Apache. Sigue el rastro **paso a paso**.

#### 🟡 Ejercicio 16.1 · Paso 1: los sospechosos

Saca el **ranking de IPs externas** (no `192.168.…`) con **3 o más** intentos de contraseña fallidos en `auth.log`. Hazlo con la menor cantidad de comandos posible.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'Failed password .* from \K(?!192\.168\.)[\d.]+' /var/log/auth.log | sort | uniq -c | sort -rn | grep -E '^ *([3-9]|[0-9]{2,}) '
```

_Resultado:_

```text
      5 203.0.113.45
      3 203.0.113.99
      3 198.51.100.23
```


`\K` extrae la IP directamente; `(?!192\.168\.)` descarta las privadas; luego la cadena habitual de contar y un último `grep` que se queda con los recuentos ≥ 3. Tres IPs: `203.0.113.45`, `203.0.113.99` y `198.51.100.23`.
</details>


#### 🟡 Ejercicio 16.2 · Paso 2: qué usuarios probaron

¿Qué **nombres de usuario** probaron los atacantes? Muestra los **usuarios inexistentes** (`Invalid user`) y también si intentaron `root`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '(Invalid user \K\S+|Failed password for \Kroot(?= ))' /var/log/auth.log | sort | uniq -c
```

_Resultado:_

```text
      1 admin
      1 guest
      1 oracle
      2 root
      1 test
```


La alternativa `( … | … )` con **dos `\K` distintos**: extrae el nombre tras `Invalid user` o la palabra `root` en `Failed password for root`.
</details>


#### 🟡 Ejercicio 16.3 · Paso 3: ¿consiguieron entrar?

Comprueba si alguna de esas tres IPs aparece en un **`Accepted`** (login con éxito).

<details>
<summary>💡 Ver solución</summary>


```bash
grep Accepted /var/log/auth.log | grep -E '203\.0\.113\.(45|99)|198\.51\.100\.23'
echo "código: $?"
```

_Resultado:_

```text
código: 1
```


El primer `grep` selecciona los accesos aceptados y el segundo busca las IPs sospechosas. No sale nada (código 1): **buenas noticias**, ninguno entró. Con un solo `grep` y lookahead: `grep -P '^(?=.*Accepted)(?=.*(203\.0\.113\.(45|99)|198\.51\.100\.23))'`.
</details>


#### 🟡 Ejercicio 16.4 · Paso 4: qué puertos probaron en el cortafuegos

Muestra, para las IPs `203.0.113.45` y `198.51.100.23`, **a qué puertos** intentaron conectar según `ufw.log`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E 'SRC=(203\.0\.113\.45|198\.51\.100\.23) ' /var/log/ufw.log | grep -oP 'DPT=\K\d+' | sort -n | uniq -c
```

_Resultado:_

```text
      8 22
      1 23
      2 445
      1 3389
```

</details>


#### 🟡 Ejercicio 16.5 · Paso 5: ¿y la web?

Averigua **qué URLs pidieron** esas dos IPs en `access.log`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(203\.0\.113\.45|198\.51\.100\.23) ' /var/log/apache2/access.log | grep -oP '"\w+ \K\S+' | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      1 /xmlrpc.php
      1 /wp-login.php
      1 /phpmyadmin/
      1 /login
      1 /index.php?id=1'
      1 /cgi-bin/test.cgi
      1 /admin/login.php
      1 /admin
      1 /.git/config
      1 /.env
      1 /../../etc/passwd
```


`^(IP1|IP2) ` selecciona las líneas de esas IPs; `"\w+ \K\S+` extrae la URL (tras el método HTTP entre comillas). Se ven `/wp-login.php`, `/.env`, `/phpmyadmin/`… un **escáner de vulnerabilidades** clásico.
</details>


#### 🔴 Ejercicio 16.6 · Paso 6: ¿sacaron algo?

De esas peticiones, ¿cuántas respuestas hubo de **cada tipo de estado** (200, 404, 400…)?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^(203\.0\.113\.45|198\.51\.100\.23) ' /var/log/apache2/access.log | grep -oP '" \K\d{3}(?= )' | sort | uniq -c
```

_Resultado:_

```text
      2 400
      1 401
      8 404
```


Casi todo `404` y `400`, y un único `401` (un intento de login rechazado): el atacante **no obtuvo ni una página** (ningún `200`). Misión cumplida: intento de intrusión **repelido**.
</details>


---

## 16.3 · 🔐 Misión 2: "Auditoría de cuentas"

Toca revisar `/etc/passwd` y `/etc/group` con ojo de auditor.

#### 🟡 Ejercicio 16.7 · Paso 1: ¿hay más de un administrador?

Muestra **todos** los usuarios con **UID 0**. Solo debería haber uno.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^[^:]*:[^:]*:0:' /etc/passwd
```

_Resultado:_

```text
root:x:0:0:root:/root:/bin/bash
```

</details>


#### 🟡 Ejercicio 16.8 · Paso 2: ¿líneas corruptas?

Comprueba que **todas** las líneas de `/etc/passwd` tienen exactamente 7 campos (6 `:`). Muestra las que **no**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -vE '^([^:]*:){6}[^:]*$' /etc/passwd
```

_Resultado:_

```text
(no sale nada)
```


`^([^:]*:){6}[^:]*$` = "6 veces campo y `:`, y un último campo". Con `-v`, las líneas que **no** cumplen: ninguna, todo bien.
</details>


#### 🟡 Ejercicio 16.9 · Paso 3: contraseñas fuera de /etc/shadow

Muestra los usuarios cuyo 2.º campo **no** sea `x`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -vE '^[^:]*:x:' /etc/passwd
```

_Resultado:_

```text
(no sale nada)
```

</details>


#### 🔴 Ejercicio 16.10 · Paso 4: grupos que no existen

Encuentra los **GID** que algún usuario tiene como principal y que **no existen** en `/etc/group`, y **qué usuario** los usa.

<details>
<summary>💡 Ver solución</summary>


```bash
for gid in $(cut -d: -f4 /etc/passwd | sort -u | grep -vxFf <(cut -d: -f3 /etc/group)); do
  grep -E "^([^:]*:){3}$gid:" /etc/passwd | cut -d: -f1,4
done
```

_Resultado:_

```text
polkitd:989
```


Primero se obtienen los GID huérfanos (como en el capítulo 10) y luego se busca qué usuario los tiene. Sale `polkitd:989`.
</details>


#### 🔴 Ejercicio 16.11 · Paso 5: ¿los miembros de `sudo` existen?

Comprueba que **todos los miembros** del grupo `sudo` son usuarios que existen en `/etc/passwd`. Muestra los que **no** existen (debería no salir nada).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^sudo:' /etc/group | cut -d: -f4 | tr ',' '\n' | grep -vxFf <(cut -d: -f1 /etc/passwd)
```

_Resultado:_

```text
(no sale nada)
```


Se lista a los miembros del grupo, uno por línea, y se descartan (`-v`) los que coinciden exactamente (`-x`) como texto fijo (`-F`) con algún nombre de `/etc/passwd` (`-f`). Lo que quede serían **fantasmas**.
</details>


#### 🔴 Ejercicio 16.12 · Paso 6: usuarios que pueden iniciar sesión de verdad

Muestra **solo los nombres** de los usuarios que **sí** pueden entrar al sistema (UID ≥ 1000 y shell que no sea `nologin` ni `false`), con **un solo comando**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^[^:]+(?=:[^:]*:([1-9]\d{3}|[1-5]\d{4}):[^:]*:[^:]*:[^:]*:(?!.*(nologin|false)$))' /etc/passwd | tr '\n' ' '; echo
```

_Resultado:_

```text
alumno ana luis marta pedro 
```


Lookahead positivo para el UID **y** lookahead negativo para la shell: dos condiciones en el mismo patrón, sobre campos distintos. Salen `alumno ana luis marta pedro` (no `invitado`: su shell es `nologin`; no `backup2`: es `false`).
</details>


---

## 16.4 · ⚙️ Misión 3: "Limpiar y migrar un fichero de configuración"

Tienes `conf-ejemplo.conf` (formato INI) y hay que **limpiarlo, revisarlo y convertirlo**.

#### 🟡 Ejercicio 16.13 · Paso 1: quitar el ruido

Muestra solo las líneas de configuración "de verdad" (sin comentarios `#` ni `;`, ni vacías, ni en blanco), **normalizando** `clave = valor` a `clave=valor`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -E '/^[[:space:]]*([#;]|$)/d; s/[[:space:]]*=[[:space:]]*/=/' conf-ejemplo.conf
```

_Resultado:_

```text
[servidor]
puerto=8080
host=localhost
debug=true
[base_datos]
usuario=admin
clave=s3creta
host=192.168.1.50
puerto=5432
[correo]
smtp=smtp.ejemplo.com
puerto=587
remitente=noreply@ejemplo.com
```


Un solo `sed` con **dos órdenes** separadas por `;`: la primera borra comentarios y vacías, la segunda quita los espacios alrededor del `=`.
</details>


#### 🟡 Ejercicio 16.14 · Paso 2: las secciones

Lista **solo los nombres de las secciones** (lo que va entre corchetes).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^\[\K[^]]+' conf-ejemplo.conf
```

_Resultado:_

```text
servidor
base_datos
correo
```


`^\[` = el corchete de apertura (se descarta con `\K`); `[^]]+` = todo lo que no sea `]` (aquí el `]` va **primero** en el corchete negado, como aprendimos en el capítulo 4).
</details>


#### 🔴 Ejercicio 16.15 · Paso 3: claves repetidas

¿Qué **claves** aparecen en más de una sección? (Solo los nombres.)

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '^\s*\K\w+(?=\s*=)' conf-ejemplo.conf | sort | uniq -d
```

_Resultado:_

```text
host
puerto
```


`^\s*\K\w+(?=\s*=)` = el nombre de la clave (palabra seguida de `=`, con espacios opcionales). `sort | uniq -d` = solo las repetidas.
</details>


#### 🔴 Ejercicio 16.16 · Paso 4: ¿puertos válidos?

Extrae los valores de las claves `puerto` y comprueba que **todos son un puerto válido** (1–65535). Muestra los que no lo sean.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP 'puerto\s*=\s*\K\d+' conf-ejemplo.conf | grep -vE '^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$'
```

_Resultado:_

```text
(no sale nada)
```


El primer `grep` extrae el número; el segundo, con `-v`, deja solo los que **no** encajan en el rango 1–65535 (si no sale nada, todos son válidos).
</details>


#### 🔴 Ejercicio 16.17 · Paso 5: la IP del servidor de base de datos

Extrae **solo la IP** de la clave `host` de la sección `[base_datos]`, en un solo comando (la sección tiene `host = 192.168.1.50`; la de `[servidor]` es `localhost`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Pzo '(?s)\[base_datos\].*?host\s*=\s*\K[\d.]+' conf-ejemplo.conf | tr -d '\0'; echo
```

_Resultado:_

```text
192.168.1.50
```


`-z` trata el fichero como una línea; `(?s)` deja que `.` cruce saltos de línea; `.*?` salta de forma perezosa hasta el primer `host =` **después** de `[base_datos]`; `\K` descarta todo eso y queda la IP.
</details>


---

## 16.5 · 🌐 Misión 4: "Forense web"

#### 🟡 Ejercicio 16.18 · Paso 1: los visitantes más activos

Muestra las **3 IPs** que más peticiones han hecho a la web.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^[0-9.]+' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head -3
```

_Resultado:_

```text
     18 203.0.113.11
     13 203.0.113.10
     12 192.168.1.51
```

</details>


#### 🟡 Ejercicio 16.19 · Paso 2: humanos contra robots

Cuenta las peticiones de **robots** (`Googlebot`, `bingbot`, `curl`, `zgrab`, `sqlmap`, `python-requests`) y de navegadores "normales" (`Mozilla` sin `zgrab` ni bots).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -ciE 'googlebot|bingbot|curl/|zgrab|sqlmap|python-requests' /var/log/apache2/access.log
grep -cP '^(?!.*(?i:googlebot|bingbot|zgrab)).*Mozilla' /var/log/apache2/access.log
```

_Resultado:_

```text
55
66
```


El primero cuenta robots con una alternativa; el segundo, con lookahead negativo, `Mozilla` sin `Googlebot`/`bingbot`/`zgrab` (que **también** dicen ser Mozilla).
</details>


#### 🔴 Ejercicio 16.20 · Paso 3: intentos de intrusión en la web

Muestra (acortadas) las peticiones con **rutas típicas de ataque**: `.env`, `.git`, `wp-login`, `phpmyadmin`, `../` o inyección SQL (`' OR`), con su estado.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '\.env|\.git|wp-login|phpmyadmin|\.\./|%27|'"'"' OR' /var/log/apache2/access.log | grep -oP '"\K[A-Z]+ .*? HTTP/[\d.]+" \d{3}'
```

_Resultado:_

```text
GET /wp-login.php HTTP/1.1" 404
GET /.env HTTP/1.1" 404
GET /phpmyadmin/ HTTP/1.1" 404
GET /.git/config HTTP/1.1" 404
GET /index.php?id=1' OR '1'='1 HTTP/1.1" 400
GET /../../etc/passwd HTTP/1.1" 400
```


El primer `grep` selecciona (con una alternativa, y `'"'"'` para meter una comilla simple dentro de comillas simples); el segundo extrae método, URL, versión y estado con `\K` (el `.*?` perezoso permite que la URL tenga espacios, como en la inyección SQL).
</details>


#### 🔴 Ejercicio 16.21 · Paso 4: cuántas peticiones hubo por franja de 10 minutos

Cuenta las peticiones de `access.log` por **franja de 10 minutos** (`10:0`, `10:1`, `10:2`, `10:3`…).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '14/Oct/2024:\K\d{2}:\d(?=\d:\d{2} )' /var/log/apache2/access.log | sort | uniq -c
```

_Resultado:_

```text
     30 10:0
     31 10:1
     34 10:2
     26 10:3
```


`\d{2}:\d(?=\d:\d{2} )` = la hora y la **decena** de minutos (sin la unidad); el lookahead exige que detrás vengan la unidad del minuto y los segundos, pero **no los incluye**.
</details>


---

## 16.6 · 👹 Retos del jefe final

#### 🔴 Ejercicio 16.22 · Un CSV de verdad

Trocea la línea `3,"Ruiz, Marta","Dice: ""hola, mundo"""` (de `csv-dificil.csv`) en **sus 3 campos**, uno por línea, respetando las comas **dentro de comillas**.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -n 4p csv-dificil.csv | grep -oP '(?:^|,)\K(?:"(?:[^"]|"")*"|[^,]*)'
```

_Resultado:_

```text
3
"Ruiz, Marta"
"Dice: ""hola, mundo"""
```


El patrón `(?:^|,)\K(?:"(?:[^"]|"")*"|[^,]*)` dice: "al principio o tras una coma (se olvida con `\K`), **o** un campo entre comillas (que admite `""` dentro), **o** un campo sin comillas". Es el análisis clásico de un CSV con una sola regex. (`sed -n 4p` elige esa fila, la 4.ª del fichero.)
</details>


#### 🔴 Ejercicio 16.23 · De la agenda a un CSV

Convierte `agenda.txt` (`Nombre: … | Tel: … | Email: …`) en un CSV `nombre,telefono,email`, con un solo `sed`.

<details>
<summary>💡 Ver solución</summary>


```bash
sed -E 's/^Nombre: ([^|]+) \| Tel: ([^|]+) \| Email: (.*)$/\1,\2,\3/; s/ ,/,/g' agenda.txt
```

_Resultado:_

```text
Juan Flores,612345678,juan@cas-training.com
Ana García,655443322,ana.garcia@ejemplo.org
Luis Pérez,91 555 66 77,luis@ejemplo.com
Marta Ruiz,699001122,marta_ruiz@tienda.es
Pedro Gómez,sin telefono,pedro@ejemplo.net
Lucía Martín,644112233,sin correo
```


Tres grupos capturan los tres campos (los dos primeros terminan antes del ` |`); el reemplazo los une con comas y la segunda orden limpia el espacio sobrante antes de las comas.
</details>


#### 🔴 Ejercicio 16.24 · Clasificar números

Cuenta en `numeros.txt` cuántas líneas son **enteros** (con signo opcional), cuántas **decimales** (con punto o coma) y cuántas **hexadecimales** (`0x…`).

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'enteros:   '; grep -cE '^[+-]?[0-9]+$' numeros.txt
printf 'decimales: '; grep -cE '^[+-]?([0-9]+[.,][0-9]*|[.,][0-9]+)$' numeros.txt
printf 'hex:       '; grep -cE '^0[xX][0-9a-fA-F]+$' numeros.txt
```

_Resultado:_

```text
enteros:   13
decimales: 6
hex:       2
```

</details>


#### 🔴 Ejercicio 16.25 · Consonante, vocal, consonante, vocal…

Muestra las palabras de `palabras.txt` formadas por parejas **consonante+vocal** repetidas (`ca`, `sa`, `ba`, `na`…).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -iE '^([^aeiou][aeiou])+$' palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
gato Gato GATO gata gatito casa Casa caso cosa cama camino caña mesa hola banana Fedora gato casa 
```


`([^aeiou][aeiou])+` = "una consonante (o no-vocal) y una vocal", una o más veces, de principio a fin. (Salen palabras como `gato`, `casa`, `banana`, `Fedora`…)
</details>


#### 🔴 Ejercicio 16.26 · Cuatro consonantes seguidas

Muestra las palabras con **cuatro caracteres seguidos que no son vocales**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '[^aeiouáéíóú]{4}' palabras.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
GATO LINUX python 
```


Salen `GATO`, `LINUX` y `python`: `GATO` y `LINUX` porque las vocales en mayúscula **no** están en el corchete.
</details>


#### 🔴 Ejercicio 16.27 · Mi casa es mi nombre

Muestra los usuarios de `/etc/passwd` cuya **carpeta personal es `/home/` + su propio nombre** (una referencia hacia atrás).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -E '^([^:]+):.*:/home/\1:' /etc/passwd | cut -d: -f1 | tr '\n' ' '; echo
```

_Resultado:_

```text
alumno ana luis marta pedro invitado 
```


`^([^:]+)` captura el nombre; `:/home/\1:` exige que la carpeta sea `/home/` + **ese mismo nombre**.
</details>


#### 🔴 Ejercicio 16.28 · Dos amigos en el mismo grupo

Muestra los grupos de `/etc/group` a los que pertenecen **a la vez `ana` y `luis`**, en cualquier orden.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -P '^(?=.*[:,]ana(,|$))(?=.*[:,]luis(,|$))' /etc/group
```

_Resultado:_

```text
docentes:x:1100:ana,luis,marta,pedro
```

</details>


#### 🔴 Ejercicio 16.29 · La hora más ocupada

¿A qué **hora** (día y hora) se escribieron más líneas en `syslog`?

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '^Nov +[0-9]+ [0-9]{2}' /var/log/syslog | sort | uniq -c | sort -rn | head -1
```

_Resultado:_

```text
     25 Nov  4 08
```


El arranque del día 4 (08:55) concentra los eventos.
</details>


#### 🔴 Ejercicio 16.30 · Código frente a comentarios

Cuenta cuántas líneas de `programa.py` son **código**, cuántas son **comentarios de línea completa** y cuántas están **vacías**.

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'codigo:      '; grep -cvE '^[[:space:]]*(#|$)' programa.py
printf 'comentarios: '; grep -cE '^[[:space:]]*#' programa.py
printf 'vacias:      '; grep -cE '^[[:space:]]*$' programa.py
```

_Resultado:_

```text
codigo:      14
comentarios: 4
vacias:      4
```


Código = ni comentario ni vacía. (Las líneas con código **y** comentario al final, como `print(...)  # saludo`, cuentan como código.)
</details>


#### ⚫ Ejercicio 16.31 · Quitar los comentarios HTML

Borra de `html.txt` los **comentarios HTML** (`<!-- … -->`) y cuenta cuántas líneas quedan vacías.

<details>
<summary>💡 Ver solución</summary>


```bash
sed 's/<!--.*-->//' html.txt | grep -c '^$'
```

_Resultado:_

```text
1
```


`<!--.*-->` (voraz aquí está bien: hay un comentario por línea). Después de borrarlo, la línea del comentario queda vacía.
</details>


#### ⚫ Ejercicio 16.32 · Quita la cabecera y ordena

En `usuarios.csv`, muestra **nombre y salario** (columnas 2 y 7) de las personas, **sin la cabecera**, ordenadas por salario **de mayor a menor**.

<details>
<summary>💡 Ver solución</summary>


```bash
tail -n +2 usuarios.csv | cut -d, -f2,7 | sort -t, -k2 -rn | head -5
```

_Resultado:_

```text
José,4100.50
Pedro,3900.00
Luis,3200.75
María,3100.00
Álvaro,2750.00
```


`tail -n +2` quita la cabecera; `cut -d, -f2,7` deja las dos columnas; `sort -t, -k2 -rn` ordena por la 2.ª (numérica e invertida).
</details>


#### ⚫ Ejercicio 16.33 · Cuántos usuarios por tipo de shell (solo nombre de la shell)

Muestra cuántos usuarios usan cada shell, mostrando **solo el nombre de la shell** (`bash`, `nologin`, `false`…), sin la ruta.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oP '[^/]+$' /etc/passwd | sort | uniq -c | sort -rn
```

_Resultado:_

```text
     29 nologin
      5 bash
      4 false
      1 zsh
      1 sync
      1 sh
```


`[^/]+$` = lo que hay tras la última `/` hasta el final de la línea (el nombre de la shell). `uniq -c` cuenta.
</details>


---

## 16.7 · 📝 Mini-examen tipo LPIC-1 (30 preguntas)

> Responde primero **sin mirar**. Pulsa en la solución para comprobar. *(Son del estilo del examen: una sola respuesta correcta.)*

**1.** ¿Qué opción de `grep` muestra **solo la parte** de la línea que coincide con el patrón?

a) `-c`  b) `-o`  c) `-l`  d) `-w`

<details><summary>Respuesta</summary>

**b) `-o`** (*only-matching*). `-c` cuenta líneas, `-l` lista ficheros, `-w` exige palabra completa.
</details>

**2.** En **regex básicas** (BRE), ¿cuál de estas expresiones significa "una o más `a`"?

a) `a+`  b) `a\+`  c) `a{1}`  d) `a(1,)`

<details><summary>Respuesta</summary>

**b) `a\+`**. En BRE `+` es un carácter normal; `\+` (extensión GNU) es el cuantificador. (`a+` solo vale en ERE.)
</details>

**3.** ¿Qué hace `grep -v '^#' fichero`?

a) Muestra solo las líneas que empiezan por `#`  b) Muestra las líneas que **no** empiezan por `#`  c) Cuenta las líneas con `#`  d) Muestra las que contienen `#` en cualquier sitio

<details><summary>Respuesta</summary>

**b)**. `-v` invierte la selección; `^#` = "empieza por `#`".
</details>

**4.** ¿Cuál es el significado de `[^0-9]`?

a) Un dígito al principio de línea  b) Cualquier carácter que **no** sea un dígito  c) El carácter `^` o un dígito  d) Un dígito que no sea el 0

<details><summary>Respuesta</summary>

**b)**. El `^` **justo después de `[`** niega el conjunto.
</details>

**5.** ¿Qué patrón ERE reconoce exactamente tres dígitos (la línea entera)?

a) `[0-9]3`  b) `^[0-9]{3}$`  c) `^[0-9]\{3\}$`  d) `^[0-9]+3$`

<details><summary>Respuesta</summary>

**b)** `^[0-9]{3}$`. La c) es BRE (`\{3\}`) y no valdría con `grep -E`.
</details>

**6.** ¿A qué es equivalente `egrep`?

a) `grep -F`  b) `grep -E`  c) `grep -P`  d) `grep -G`

<details><summary>Respuesta</summary>

**b) `grep -E`**. `fgrep` ≡ `grep -F`; `grep -G` es el modo básico por defecto; `-P` es Perl.
</details>

**7.** ¿Qué hace `grep -F 'a.c' fichero`?

a) Busca `a`, cualquier carácter y `c`  b) Busca el texto literal `a.c`  c) Da error  d) Busca `a` o `c`

<details><summary>Respuesta</summary>

**b)**. `-F` desactiva los metacaracteres: el `.` es un punto de verdad.
</details>

**8.** ¿Cómo se busca un **punto literal** en una regex básica?

a) `.`  b) `\.`  c) `[.]`  d) b) y c) son correctas

<details><summary>Respuesta</summary>

**d)**. `\.` escapa el punto y `[.]` lo deja literal dentro del corchete.
</details>

**9.** ¿Qué devuelve `echo $?` justo después de un `grep` que **no encontró** ninguna coincidencia?

a) 0  b) 1  c) 2  d) 127

<details><summary>Respuesta</summary>

**b) 1**. 0 = encontró, 1 = no encontró, 2 = error.
</details>

**10.** ¿Qué diferencia hay entre `grep -r` y `grep -R`?

a) Ninguna  b) `-R` sigue los enlaces simbólicos  c) `-r` es solo para ficheros binarios  d) `-R` ignora mayúsculas

<details><summary>Respuesta</summary>

**b)**. Ambos son recursivos, pero `-R` sigue **todos** los enlaces simbólicos (`-r` solo los de la línea de comandos).
</details>

**11.** ¿Qué significa `\<` en una regex GNU?

a) Principio de línea  b) Principio de palabra  c) Un `<` literal  d) Fin de palabra

<details><summary>Respuesta</summary>

**b)**. `\>` es el fin de palabra, `^` el principio de línea.
</details>

**12.** ¿Cuál **no** es una clase de caracteres POSIX válida?

a) `[:digit:]`  b) `[:alpha:]`  c) `[:letter:]`  d) `[:space:]`

<details><summary>Respuesta</summary>

**c) `[:letter:]`**. La correcta es `[:alpha:]`.
</details>

**13.** ¿Cómo se escribe correctamente una clase POSIX en un patrón?

a) `[:digit:]`  b) `[[:digit:]]`  c) `[digit]`  d) `:digit:`

<details><summary>Respuesta</summary>

**b)**. La clase va **dentro** de un corchete: dos pares.
</details>

**14.** ¿Qué hace `sed 's/a/b/g' fichero`?

a) Cambia solo la primera `a` del fichero  b) Cambia todas las `a` de cada línea, mostrando el resultado sin modificar el fichero  c) Modifica el fichero  d) Borra las `a`

<details><summary>Respuesta</summary>

**b)**. `g` = todas las de cada línea; sin `-i`, el fichero **no** cambia.
</details>

**15.** ¿Qué muestra `sed -n '3p' fichero`?

a) Todo menos la línea 3  b) Solo la línea 3  c) Las 3 primeras líneas  d) La línea 3 duplicada

<details><summary>Respuesta</summary>

**b)**. `-n` suprime la salida automática y `3p` imprime la línea 3.
</details>

**16.** ¿Cuál de estos patrones reconoce `color` **y** `colour` en ERE?

a) `colou*r`  b) `colou?r`  c) `colo(u)r`  d) `colo.r`

<details><summary>Respuesta</summary>

**b) `colou?r`**: la `u` es opcional. (`colou*r` también admitiría `colouur`; `colo.r` aceptaría `colxr`.)
</details>

**17.** ¿Qué hace `grep -c 'error' fichero`?

a) Muestra las líneas con `error`  b) Cuenta las líneas que contienen `error`  c) Cuenta las apariciones de `error`  d) Muestra el número de línea

<details><summary>Respuesta</summary>

**b)**: cuenta **líneas** (no apariciones).
</details>

**18.** ¿Qué hace `grep -w 'ana' /etc/passwd`?

a) Busca `ana` en cualquier parte  b) Busca `ana` como **palabra completa**  c) Busca la línea entera `ana`  d) Ignora mayúsculas

<details><summary>Respuesta</summary>

**b)**. `-x` sería la línea entera; `-i` ignora mayúsculas.
</details>

**19.** En el **modo extendido**, ¿cómo se escribe la alternativa "gato o perro"?

a) `gato\|perro`  b) `gato|perro`  c) `gato||perro`  d) `(gato,perro)`

<details><summary>Respuesta</summary>

**b)** `gato|perro`. La a) es la forma BRE de GNU.
</details>

**20.** ¿Qué hace el comando `find / -name '*.conf' 2>/dev/null`?

a) Busca ficheros `.conf` y oculta los mensajes de error  b) Busca y borra los `.conf`  c) Cuenta los `.conf`  d) Da error por las comillas

<details><summary>Respuesta</summary>

**a)**. `2>/dev/null` tira `stderr` (los "Permiso denegado"); las comillas evitan que la terminal expanda el `*`.
</details>

**21.** En `find`, ¿qué opción filtra el nombre con una **expresión regular** sobre la **ruta completa**?

a) `-name`  b) `-iname`  c) `-regex`  d) `-path`

<details><summary>Respuesta</summary>

**c) `-regex`**. `-name` e `-iname` usan comodines y miran solo el nombre.
</details>

**22.** ¿Qué opción de `locate` interpreta el patrón como **regex básica**?

a) `-i`  b) `-r`  c) `-c`  d) `-b`

<details><summary>Respuesta</summary>

**b) `-r`** (`--regexp`). `--regex` = extendida.
</details>

**23.** En `vi`, ¿qué hace `:%s/viejo/nuevo/g`?

a) Sustituye solo en la línea actual  b) Sustituye todas las apariciones en **todo el fichero**  c) Busca `viejo`  d) Borra las líneas con `viejo`

<details><summary>Respuesta</summary>

**b)**. `%` = todo el fichero, `g` = todas las veces por línea.
</details>

**24.** En `vi`, ¿cómo se **sale sin guardar**?

a) `:wq`  b) `ZZ`  c) `:q!`  d) `:w`

<details><summary>Respuesta</summary>

**c) `:q!`**. `:wq` y `ZZ` guardan.
</details>

**25.** ¿Qué patrón ERE coincide con `a{2,3}`?

a) `a`, `aa` o `aaa`  b) Solo `aa` o `aaa`  c) La cadena literal `a{2,3}`  d) `a2` o `a3`

<details><summary>Respuesta</summary>

**b)**: de dos a tres `a` seguidas.
</details>

**26.** ¿Qué ocurre al ejecutar `grep gato *.txt` si en la carpeta hay `a.txt` y `b.txt`?

a) `grep` recibe `*.txt` literal  b) La terminal lo expande y `grep` busca `gato` en `a.txt` y `b.txt`  c) Da error  d) Busca la palabra `*.txt`

<details><summary>Respuesta</summary>

**b)**: los **comodines** los expande la terminal, no `grep`.
</details>

**27.** ¿Qué hace `grep -A2 'error' log`?

a) Muestra las 2 líneas **antes** de cada coincidencia  b) Muestra las 2 líneas **después** de cada coincidencia (además de ella)  c) Muestra solo 2 coincidencias  d) Muestra todo menos 2 líneas

<details><summary>Respuesta</summary>

**b)**. `-B2` = antes; `-C2` = antes y después; `-m2` = solo 2 coincidencias.
</details>

**28.** ¿Para qué sirve `tr -d '[:digit:]'`?

a) Borrar los dígitos de la entrada  b) Pasar a mayúsculas  c) Contar dígitos  d) Quedarse solo con los dígitos

<details><summary>Respuesta</summary>

**a)**. Con `-cd` (complemento + borrar) se quedaría **solo** con los dígitos.
</details>

**29.** ¿Qué patrón reconoce una línea formada **solo** por una o más cifras?

a) `[0-9]+`  b) `^[0-9]+$`  c) `^[0-9]*`  d) `[^0-9]`

<details><summary>Respuesta</summary>

**b)**. Sin anclas (a) cualquier línea con un dígito pasaría; `*` (c) también admitiría la vacía; y d) es lo contrario.
</details>

**30.** ¿Cuál es la forma correcta de **ver todas las líneas de `/etc/ssh/sshd_config` que no son comentarios ni vacías**?

a) `grep '#' /etc/ssh/sshd_config`  b) `grep -Ev '^[[:space:]]*(#|$)' /etc/ssh/sshd_config`  c) `grep -v '$' /etc/ssh/sshd_config`  d) `grep '^[0-9]' /etc/ssh/sshd_config`

<details><summary>Respuesta</summary>

**b)**. Invierte (`-v`) las líneas que son (tras espacios opcionales) un comentario o están vacías.
</details>

---

## 🎓 ¡Lo has conseguido!

Si has llegado hasta aquí practicando, ya sabes:

- 🔤 Todos los **metacaracteres**: `. ^ $ * + ? { } [ ] ( ) | \ \b \< \> \w \K`.
- 🧰 Las **opciones de `grep`** y cuándo usar `-E`, `-F` o `-P`.
- 🔧 A **transformar** con `sed` y a **filtrar** con `cut`, `sort`, `uniq`, `tr`, `wc`.
- 🗂️ A **leer el sistema**: `/etc/passwd`, `/etc/group`, logs, paquetes…
- 🥋 A pensar **"¿se puede hacer con un solo comando?"**

Siguiente paso: la [**chuleta**](chuleta.md) para tenerlo todo en una página, y **rehacer los ejercicios sin mirar**. ¡Eres un master de Linux en ciernes! 🐧

> 🚰 **¿Te queda un cabo suelto con las tuberías?** El [capítulo 17](17-tuberias-y-redirecciones.md) (LPIC 103.4) es un **extra de fontanería**: redirecciones, `2>&1`, `tee`, `xargs`, `$( )` y `<( )`, con 37 ejercicios más. Puede leerse a partir del capítulo 9.

---

---
⬅️ [Capítulo 15 · Regex fuera de `grep`: `less`, `vi`, `find`, `locate`](15-vi-find-locate.md) · 🏠 [Índice](README.md) · [Capítulo 17 · 🚰 La fontanería de Linux: entradas, salidas y tuberías](17-tuberias-y-redirecciones.md) ➡️
