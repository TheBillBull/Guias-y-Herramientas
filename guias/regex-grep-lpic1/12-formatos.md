# Capítulo 12 · Reconocer formatos: IPv4, IPv6, correos, dominios, MAC…

> 🎯 **Objetivo:** construir **paso a paso**, de lo ingenuo a lo preciso, las expresiones regulares que **validan formatos reales**: direcciones IP, correos, nombres de máquina, MAC, teléfonos, fechas, URLs…
>
> 📘 **LPIC-1:** 103.7. Y son los ejercicios clásicos de cualquier curso de expresiones regulares: *"expresión que identifique una IPv4, una IPv6, una cuenta de correo, un nombre de máquina con un subdominio y un TLD de 3 letras"*.
>
> 🧪 `cd ~/lab-regex`

---

## 12.0 · Cómo se construye una regex seria

Una regex que **valida un formato** se escribe siempre en **tres pasos**:

1. **Forma:** ¿cómo "se ve" el dato? (cuatro números separados por puntos…).
2. **Rangos y límites:** ¿qué valores son legales? (cada número de 0 a 255…).
3. **Bordes:** ¿la línea entera debe ser eso? (`^…$`), ¿o puede estar dentro de un texto?

### Tres técnicas de este capítulo

**① Validar la línea entera con `-x`.** La opción `-x` equivale a poner `^(…)$` alrededor del patrón (¡incluso si contiene alternativas!). Así no hace falta escribir anclas ni paréntesis extra:

```text
grep -Ex 'PATRÓN' fichero     ≡     grep -E '^(PATRÓN)$' fichero
```

**② Guardar piezas en variables de la terminal.** Los patrones grandes se vuelven ilegibles. Con una **variable** (`OCTETO='…'`) y **comillas dobles** (para que se expanda) los construyes como si fueran ladrillos:

```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'     # pieza reutilizable
grep -Ex "($OCTETO\.){3}$OCTETO" fichero                 # 4 octetos separados por puntos
```

> ⚠️ Con comillas **dobles** la terminal expande `$OCTETO`, y también interpreta `$`, `` ` `` y `\` en ciertas posiciones. Por eso evitamos poner un `$` final de patrón (usamos `-x` en su lugar).

**③ Probar con datos buenos y malos.** Todo patrón se prueba con ejemplos que **deben** pasar y otros que **deben** fallar. Los ficheros del laboratorio ya los traen.

---

## 12.1 · 🌐 La dirección IPv4

Una IPv4 son **4 números de 0 a 255 separados por puntos**: `192.168.1.1`.

El fichero `ips.txt` tiene IPs válidas, inválidas y "mezcladas con texto":

```bash
cat ips.txt
```

_Resultado:_

```text
192.168.1.1
10.0.0.1
172.16.254.1
255.255.255.255
0.0.0.0
127.0.0.1
8.8.8.8
1.1.1.1
256.1.1.1
192.168.1.256
999.999.999.999
300.300.300.300
1.2.3
1.2.3.4.5
192.168.1
192.168..1
01.02.03.04
192.168.001.001
abc.def.ghi.jkl
1.2.3.x
… (y 10 líneas más)
```


### Intento 1: la forma (¡demasiado permisivo!)

```bash
grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' ips.txt
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
… (y 16 líneas más)
```


Pasa casi todo, **incluidas IPs imposibles** como `999.999.999.999` y `256.1.1.1`.

### Intento 2: de 1 a 3 cifras por bloque, línea entera

`[0-9]{1,3}(\.[0-9]{1,3}){3}` = un bloque de 1 a 3 cifras y **tres veces** "punto + bloque":

```bash
grep -Ex '[0-9]{1,3}(\.[0-9]{1,3}){3}' ips.txt
```

_Resultado:_

```text
192.168.1.1
10.0.0.1
172.16.254.1
255.255.255.255
0.0.0.0
127.0.0.1
8.8.8.8
1.1.1.1
256.1.1.1
192.168.1.256
999.999.999.999
300.300.300.300
01.02.03.04
192.168.001.001
192.168.1.100
```


Mejor, pero sigue dejando pasar `256.1.1.1`, `999.999.999.999` y `01.02.03.04`.

### Intento 3: el octeto correcto (0–255)

Ya construimos esta pieza en el capítulo 6. La repasamos por rangos:

| Valores | Patrón | Ejemplos |
|---|---|---|
| 250–255 | `25[0-5]` | 250, 255 |
| 200–249 | `2[0-4][0-9]` | 200, 249 |
| 100–199 | `1[0-9]{2}` | 100, 199 |
| 0–99 | `[1-9]?[0-9]` | 0, 7, 42, 99 |

Y la IPv4 **completa**, con la variable:

```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "($OCTETO\.){3}$OCTETO" ips.txt
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
«192.168.1.100»
```


¡Ahora sí! Las **9 IPs válidas**. Y rechaza `256.1.1.1`, `999.999.999.999`, `1.2.3`, `1.2.3.4.5`, y también **`01.02.03.04`** y **`192.168.001.001`** (el `[1-9]?[0-9]` no permite ceros a la izquierda; es una decisión de diseño: si quieres admitirlos, cambia a `0*[0-9]{1,2}`…).

### ¿Y una IP dentro de un texto?

Con `-x` exigimos la línea entera. Para **encontrar IPs dentro de frases** quitamos `-x` y ponemos **límites de palabra**:

```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -oE "\b($OCTETO\.){3}$OCTETO\b" ips.txt | tr '\n' ' '
```

_Resultado:_

```text
192.168.1.1 10.0.0.1 172.16.254.1 255.255.255.255 0.0.0.0 127.0.0.1 8.8.8.8 1.1.1.1 1.2.3.4 8.8.4.4 192.168.0.254 203.0.113.45 198.51.100.7 192.168.0.1 10.0.0.0 192.168.1.0 10.10.10.10 10.10.10.11 1.2.3.4 192.168.1.100 
```


Muy cerca, pero fíjate en que de la línea `1.2.3.4.5` ha extraído `1.2.3.4`: el punto separa palabras, así que `\b` no ve problema. Para ser **exactos** necesitamos "mirar alrededor" (que no haya más dígitos o puntos pegados), y eso es de **PCRE** (`grep -P`, capítulo 13).

---

## 12.2 · 🌐 La dirección IPv6

Una IPv6 son **8 grupos de hasta 4 dígitos hexadecimales separados por `:`**:

```text
2001:0db8:85a3:0000:0000:8a2e:0370:7334
```

Y se puede **abreviar** de dos formas:

1. Quitando los **ceros a la izquierda** de cada grupo: `2001:db8:85a3:0:0:8a2e:370:7334`.
2. Sustituyendo **una sola vez** una secuencia de grupos de ceros por **`::`**: `2001:db8:85a3::8a2e:370:7334`, `::1`, `fe80::`, `::`.

Los grupos hex: `[0-9a-f]{1,4}` (usaremos `-i` para ignorar mayúsculas).

### Intento 1: la forma completa (8 grupos)

```bash
H='[0-9a-f]{1,4}'
grep -Eix "(${H}:){7}${H}" ipv6.txt
```

_Resultado_ (coincidencias entre « »):

```text
«2001:0db8:85a3:0000:0000:8a2e:0370:7334»
«2001:db8:85a3:0:0:8a2e:370:7334»
«FE80:0000:0000:0000:0202:B3FF:FE1E:8329»
«1:2:3:4:5:6:7:8»
```


Solo las que tienen los 8 grupos explícitos. Pero `::1` o `2001:db8::1` (con `::`) se quedan fuera.

### Intento 2: con `::`

El problema de `::` es que **representa un número variable de grupos**: entre 1 y 7 grupos de ceros. Si hay `a` grupos antes del `::` y `b` después, tiene que cumplirse `a + b ≤ 7`. Una regex no sabe "sumar", así que **enumeramos los casos**:

```text
 antes del ::     después del ::      ejemplo
 ───────────────  ──────────────────  ───────────────────────
 8 grupos, sin ::                      1:2:3:4:5:6:7:8
 1 a 7 grupos      (nada)              fe80::
 1 a 6 grupos      1 grupo             2001:db8::1
 1 a 5 grupos      1 a 2 grupos        1:2:3::4:5
 1 a 4 grupos      1 a 3 grupos
 1 a 3 grupos      1 a 4 grupos
 1 a 2 grupos      1 a 5 grupos
 1 grupo           1 a 6 grupos
 (nada)            1 a 7 grupos, o nada  ::1    ::
```

Cada fila es una alternativa. Todas juntas (con `H` como "un grupo hex"):

```bash
H='[0-9a-f]{1,4}'
grep -Eix "(${H}:){7}${H}|(${H}:){1,7}:|(${H}:){1,6}:${H}|(${H}:){1,5}(:${H}){1,2}|(${H}:){1,4}(:${H}){1,3}|(${H}:){1,3}(:${H}){1,4}|(${H}:){1,2}(:${H}){1,5}|${H}:((:${H}){1,6})|:((:${H}){1,7}|:)" ipv6.txt
```

_Resultado_ (coincidencias entre « »):

```text
«2001:0db8:85a3:0000:0000:8a2e:0370:7334»
«2001:db8:85a3:0:0:8a2e:370:7334»
«2001:db8:85a3::8a2e:370:7334»
«2001:db8::1»
«::1»
«::»
«fe80::1ff:fe23:4567:890a»
«fe80::»
«FE80:0000:0000:0000:0202:B3FF:FE1E:8329»
«1:2:3:4:5:6:7:8»
```


Han pasado las **10 válidas**. Y estas **se rechazan** (comprobémoslo con `-v`):

```bash
H='[0-9a-f]{1,4}'
grep -Eivx "(${H}:){7}${H}|(${H}:){1,7}:|(${H}:){1,6}:${H}|(${H}:){1,5}(:${H}){1,2}|(${H}:){1,4}(:${H}){1,3}|(${H}:){1,3}(:${H}){1,4}|(${H}:){1,2}(:${H}){1,5}|${H}:((:${H}){1,6})|:((:${H}){1,7}|:)" ipv6.txt
```

_Resultado:_

```text
::ffff:192.0.2.1
2001:db8:::1
12345::1
gggg::1
2001:db8:85a3:0:0:8a2e:370:7334:1234
2001:db8
1:2:3:4:5:6:7
1::2::3
inet6 fe80::a00:27ff:fe4e:66a1/64 scope link
```


- `::ffff:192.0.2.1` → es una IPv6 "mapeada" con IPv4; la tratamos aparte (siguiente apartado).
- `2001:db8:::1` (tres dos puntos), `12345::1` (5 cifras en un grupo), `gggg::1` (no es hex), 9 grupos, `2001:db8` y `1:2:3:4:5:6:7` (**faltan** grupos y no hay `::`), `1::2::3` (**dos** `::`): todo mal.
- Y la última línea es una frase con una IPv6 dentro (no es una IPv6 por sí sola).

### La IPv6 "mapeada" a IPv4

```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Eix "::ffff:($OCTETO\.){3}$OCTETO" ipv6.txt
```

_Resultado_ (coincidencias entre « »):

```text
«::ffff:192.0.2.1»
```


### Una versión "pragmática"

Para **extraer** direcciones IPv6 de un texto, sin preocuparse de la validez exacta, basta algo suelto:

```bash
ip a | grep -oE 'inet6 [0-9a-f:]+'
```

_Resultado:_

```text
inet6 ::1
inet6 2001:db8:abcd:12::37
inet6 fe80::a00:27ff:fe4e:66a1
```


`[0-9a-f:]+` = "una cadena de dígitos hex y dos puntos". Es suficiente para **buscar**, no para **validar**.

---

## 12.3 · ✉️ La cuenta de correo

Un correo es `usuario@dominio.tld`. Se construye en tres niveles de exigencia:

### Nivel 1: lo mínimo

```bash
grep -Ex '[^@ ]+@[^@ ]+' correos.txt | wc -l
```

_Resultado:_

```text
16
```


"Algo, una `@`, algo; sin espacios". Pasan **demasiadas**.

### Nivel 2: lo habitual (el que se usa de verdad)

```bash
grep -Ex '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' correos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«juan@cas-training.com»
«nombre.apellido@dominio.es»
«user+etiqueta@gmail.com»
«ana_garcia99@ejemplo.org»
«MAYUSCULAS@EJEMPLO.COM»
«a@b.co»
«pepe@sub.dominio.co.uk»
«info@mi-empresa.net»
«usuario@dominio..com»
«usuario@-dominio.com»
«.punto@ejemplo.com»
«punto.@ejemplo.com»
«us..er@ejemplo.com»
```


- Usuario: letras, números y `. _ % + -` (el `-` al final del corchete, literal).
- Dominio: letras, números, puntos y guiones, un punto y una **terminación de 2 o más letras** (el TLD).

Rechaza `sin-arroba.com`, `@sin-usuario.com`, `doble@@…`, `espacios en@…`, `usuario@dominio` (sin TLD), `usuario@.com`, `usuario@ejemplo.c`. Pero deja pasar casos absurdos: `usuario@dominio..com`, `usuario@-dominio.com`, `.punto@ejemplo.com`, `punto.@…`, `us..er@…`.

### Nivel 3: estricto

Dos piezas, cada una pensada con cuidado:

- **Usuario** (`L`): partes separadas por **un solo punto**, **sin** punto al principio ni al final: `parte(\.parte)*`.
- **Dominio** (`D`): **etiquetas** que no empiezan ni acaban en guion, separadas por puntos, y TLD de 2+ letras.

```bash
L='[A-Za-z0-9_%+-]+(\.[A-Za-z0-9_%+-]+)*'
D='([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}'
grep -Ex "$L@$D" correos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«juan@cas-training.com»
«nombre.apellido@dominio.es»
«user+etiqueta@gmail.com»
«ana_garcia99@ejemplo.org»
«MAYUSCULAS@EJEMPLO.COM»
«a@b.co»
«pepe@sub.dominio.co.uk»
«info@mi-empresa.net»
```


Ya solo pasan los **8 correos buenos**. Los casos absurdos del nivel 2 se rechazan.

> 💡 La ortodoxia dice que **nunca se valida un correo del todo con una regex** (el estándar es complejísimo). Esta regex del nivel 3 es más que suficiente en el 99 % de los casos.

### Extraer correos de un texto

Quitamos `-x` y las anclas, y usamos `-o`:

```bash
grep -ohE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' agenda.txt frases.txt
```

_Resultado:_

```text
juan@cas-training.com
ana.garcia@ejemplo.org
luis@ejemplo.com
marta_ruiz@tienda.es
pedro@ejemplo.net
juan@ejemplo.com
ana@ejemplo.org
```


---

## 12.4 · 🖥️ El nombre de máquina (FQDN)

Un **FQDN** (*Fully Qualified Domain Name*) es el nombre completo de una máquina:

```text
 www . cas-training . com
  │        │          └─ TLD (dominio de primer nivel): com, org, es, net…
  │        └─ dominio
  └─ máquina / subdominio
```

Cada trozo entre puntos es una **etiqueta**. Reglas de una etiqueta:

- Letras, números y guiones.
- **No** empieza ni acaba en guion.

```text
ETIQUETA = [a-z0-9]([a-z0-9-]*[a-z0-9])?
```

Y todo en minúsculas, o usamos `-i`.

### 🎯 El ejercicio de tu profe: *"nombre de máquina con **solo un nivel de subdominio** y TLD de **3 letras**"*

Hay que interpretar la frase. "Un nivel de subdominio" por delante del dominio. Veamos las dos lecturas razonables:

**Lectura A** — `máquina.dominio.tld` (3 etiquetas): la máquina (`www`) es **un** nivel por delante del dominio. Es la más común (`www.cas-training.com`).

```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "$LAB\.$LAB\.[a-z]{3}" dominios.txt
```

_Resultado_ (coincidencias entre « »):

```text
«www.cas-training.com»
«mail.google.com»
«host1.empresa.com»
«ftp.ubuntu.com»
«ns1.dominio.org»
«WWW.EJEMPLO.COM»
«aula.cas-training.com»
```


- `$LAB\.$LAB\.` = dos etiquetas con su punto.
- `[a-z]{3}` = un TLD de **exactamente 3 letras**.
- `-x` = la línea entera, `-i` = ignora mayúsculas.

Salen `www.cas-training.com`, `mail.google.com`, `host1.empresa.com`, `ftp.ubuntu.com`, `ns1.dominio.org`, `WWW.EJEMPLO.COM`, `aula.cas-training.com`.

**Lectura B** — `máquina.subdominio.dominio.tld` (4 etiquetas): se cuenta **un subdominio** *además* de máquina y dominio.

```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "$LAB\.$LAB\.$LAB\.[a-z]{3}" dominios.txt
```

_Resultado_ (coincidencias entre « »):

```text
«intranet.corp.empresa.com»
```


Sale `intranet.corp.empresa.com`.

> 🧠 Sea cual sea la lectura que pida tu profe, la **técnica** es la misma: **N etiquetas** (`$LAB\.` repetido) + **TLD de longitud fija** (`[a-z]{3}`). Si quiere "entre 1 y 3 niveles", usas `($LAB\.){1,3}`.

### Un FQDN genérico

Cualquier número de etiquetas y un TLD de 2 o más letras:

```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "($LAB\.)+[a-z]{2,}" dominios.txt | tr '\n' ' '; echo
```

_Resultado:_

```text
www.cas-training.com mail.google.com ejemplo.org servidor.dominio.es a.b.c.ejemplo.net host1.empresa.com web.mi-empresa.info ftp.ubuntu.com mi-pc.local test.uk intranet.corp.empresa.com ns1.dominio.org WWW.EJEMPLO.COM tienda.ejemplo.tienda aula.cas-training.com 
```


Rechaza `localhost` (sin punto), `-malo.ejemplo.com` y `malo-.ejemplo.com` (etiquetas con guion mal puesto), `ejem plo.com` (espacio), `ejemplo..com` (etiqueta vacía) y `www.ejemplo.com.` (punto final).

---

## 12.5 · 🔌 La dirección MAC

Una MAC son **6 pares hexadecimales** separados por `:` o `-`: `08:00:27:4e:66:a1`.

**Versión simple:**

```bash
grep -Ex '([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}' macs.txt
```

_Resultado_ (coincidencias entre « »):

```text
«00:1A:2B:3C:4D:5E»
«00-1A-2B-3C-4D-5E»
«00:1a:2b:3c:4d:5e»
«08:00:27:4e:66:a1»
«FF:FF:FF:FF:FF:FF»
«00:1A-2B:3C-4D:5E»
```


Pero admite `00:1A-2B:3C-4D:5E` (mezclando `:` y `-`).

**Versión con memoria:** el primer separador se **captura** y se **repite** con `\1`: así **todos** son iguales.

```bash
grep -Ex '[0-9A-Fa-f]{2}([:-])([0-9A-Fa-f]{2}\1){4}[0-9A-Fa-f]{2}' macs.txt
```

_Resultado_ (coincidencias entre « »):

```text
«00:1A:2B:3C:4D:5E»
«00-1A-2B-3C-4D-5E»
«00:1a:2b:3c:4d:5e»
«08:00:27:4e:66:a1»
«FF:FF:FF:FF:FF:FF»
```


Ahora `00:1A-2B:3C-4D:5E` ya no pasa: solo los coherentes.

---

## 12.6 · Otros formatos de la vida real

| Formato | Regex (ERE) | Ejemplos |
|---|---|---|
| **Fecha ISO** | `[0-9]{4}-(0[1-9]\|1[0-2])-(0[1-9]\|[12][0-9]\|3[01])` | 2024-12-31 |
| **Hora** | `([01][0-9]\|2[0-3]):[0-5][0-9](:[0-5][0-9])?` | 23:59:59 |
| **Código postal español** | `(0[1-9]\|[1-4][0-9]\|5[0-2])[0-9]{3}` | 28001 |
| **IBAN español** | `ES[0-9]{2}( ?[0-9]{4}){5}` | ES91 2100 0418 4502 0005 1332 |
| **DNI / NIE** | `([0-9]{8}\|[XYZ][0-9]{7})[A-Z]` | 12345678Z, X1234567L |
| **Móvil español** | `[67][0-9]{8}` | 612345678 |
| **URL** | `(https?\|ftp)://[^/ ]+(/[^ ]*)?` | https://a.com/ruta |
| **Color hex** | `#([0-9a-fA-F]{3}\|[0-9a-fA-F]{6})` | #1a2B3c |
| **Versión x.y.z** | `[0-9]+(\.[0-9]+){2}` | 3.12.3 |

(En esta tabla, `\|` es la barra vertical de las alternativas; no la escribas con la barra invertida.)

---

## 12.7 · 🏋️ Ejercicios: IPv4

#### 🟢 Ejercicio 12.1 · La forma de una IP

Muestra las líneas de `ips.txt` que **contienen** algo con forma de IP (4 grupos de dígitos separados por puntos). Cuéntalas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -cE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' ips.txt
```

_Resultado:_

```text
24
```

</details>


#### 🟢 Ejercicio 12.2 · Exactamente cuatro bloques de 1 a 3 cifras

Muestra las líneas de `ips.txt` que **son** (línea entera) cuatro bloques de 1 a 3 cifras separados por puntos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '[0-9]{1,3}(\.[0-9]{1,3}){3}' ips.txt | tr '\n' ' '
```

_Resultado:_

```text
192.168.1.1 10.0.0.1 172.16.254.1 255.255.255.255 0.0.0.0 127.0.0.1 8.8.8.8 1.1.1.1 256.1.1.1 192.168.1.256 999.999.999.999 300.300.300.300 01.02.03.04 192.168.001.001 192.168.1.100 
```


`-x` ya exige la línea entera. Pasan `256.1.1.1`, `999.999.999.999`… (falta controlar el rango).
</details>


#### 🟡 Ejercicio 12.3 · ⭐ La IPv4 de tu profe: validación exacta

**"Expresión regular que identifique una IPv4."** Muestra solo las líneas de `ips.txt` que son una **IPv4 válida** (cuatro números de 0 a 255, sin ceros a la izquierda).

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "($OCTETO\.){3}$OCTETO" ips.txt
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
«192.168.1.100»
```


La expresión sin variables, por si te piden escribirla de una vez (con `^…$` explícitos):

```text
^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$
```

Explicación: `(OCTETO\.){3}` = tres veces "octeto y punto"; y un `OCTETO` final sin punto. Cada `OCTETO` es una alternativa de cuatro rangos (250–255, 200–249, 100–199, 0–99).
</details>


#### 🟡 Ejercicio 12.4 · Las no válidas

Muestra las líneas de `ips.txt` que **no son** una IPv4 válida.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -vEx "($OCTETO\.){3}$OCTETO" ips.txt
```

_Resultado:_

```text
256.1.1.1
192.168.1.256
999.999.999.999
300.300.300.300
1.2.3
1.2.3.4.5
192.168.1
192.168..1
01.02.03.04
192.168.001.001
… (y 11 líneas más)
```


`-v` invierte: salen las inválidas (`256.1.1.1`…) **y** las líneas con texto, que no son "una IP" por sí solas.
</details>


#### 🟡 Ejercicio 12.5 · Cuántas válidas y cuántas no

Cuenta las IPs válidas y las que no lo son, con dos comandos `grep -c`.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -cEx "($OCTETO\.){3}$OCTETO" ips.txt
grep -cvEx "($OCTETO\.){3}$OCTETO" ips.txt
```

_Resultado:_

```text
9
21
```

</details>


#### 🟡 Ejercicio 12.6 · IPs dentro de texto

Extrae **todas las IPv4 válidas** que aparezcan en cualquier parte de `ips.txt` (una por línea), con `-o`.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -oE "\b($OCTETO\.){3}$OCTETO\b" ips.txt | tr '\n' ' '
```

_Resultado:_

```text
192.168.1.1 10.0.0.1 172.16.254.1 255.255.255.255 0.0.0.0 127.0.0.1 8.8.8.8 1.1.1.1 1.2.3.4 8.8.4.4 192.168.0.254 203.0.113.45 198.51.100.7 192.168.0.1 10.0.0.0 192.168.1.0 10.10.10.10 10.10.10.11 1.2.3.4 192.168.1.100 
```


`\b` evita coger trozos de un número mayor (no extrae `192.168.1.25` de `192.168.1.256`), pero extrae `1.2.3.4` de `1.2.3.4.5`; para evitarlo hace falta `grep -P` con `(?<![\d.])` (capítulo 13).
</details>


#### 🟡 Ejercicio 12.7 · La red privada 10.0.0.0/8

Muestra las IPs de `ips.txt` (válidas, línea entera) que pertenecen a la red privada **10.x.x.x**.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "10\.($OCTETO\.){2}$OCTETO" ips.txt
```

_Resultado:_

```text
10.0.0.1
```

</details>


#### 🟡 Ejercicio 12.8 · La red privada 192.168.0.0/16

Muestra las IPs válidas de `ips.txt` que pertenecen a **192.168.x.x**.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "192\.168\.$OCTETO\.$OCTETO" ips.txt
```

_Resultado:_

```text
192.168.1.1
192.168.1.100
```

</details>


#### 🟡 Ejercicio 12.9 · La red privada 172.16.0.0/12

Muestra las IPs válidas del bloque privado **172.16.x.x a 172.31.x.x**.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "172\.(1[6-9]|2[0-9]|3[01])\.$OCTETO\.$OCTETO" ips.txt
```

_Resultado:_

```text
172.16.254.1
```


El segundo octeto es **16 a 31**: `1[6-9]` (16–19), `2[0-9]` (20–29), `3[01]` (30–31).
</details>


#### 🔴 Ejercicio 12.10 · Todas las privadas en un patrón

Muestra las IPs válidas **privadas** (10/8, 172.16/12 y 192.168/16) con **una sola** regex.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "(10\.$OCTETO|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.$OCTETO\.$OCTETO" ips.txt
```

_Resultado:_

```text
192.168.1.1
10.0.0.1
172.16.254.1
192.168.1.100
```


Las tres redes comparten los dos últimos octetos, así que la alternativa solo abarca el principio: `(10.A | 172.B | 192.168)` y luego `.OCTETO.OCTETO`.
</details>


#### 🔴 Ejercicio 12.11 · Las IPs públicas

Muestra las IPs válidas de `ips.txt` que **no** son privadas ni de loopback (`127.x`). *(Dos comandos: validar y descartar.)*

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "($OCTETO\.){3}$OCTETO" ips.txt | grep -vE '^(10\.|127\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)'
```

_Resultado:_

```text
255.255.255.255
0.0.0.0
8.8.8.8
1.1.1.1
```


Valida primero, filtra después. Quedan `0.0.0.0`, `255.255.255.255`, `8.8.8.8` y `1.1.1.1` (ojo: técnicamente `0.0.0.0` y `255.255.255.255` son direcciones **especiales**, no "públicas" normales).
</details>


#### 🔴 Ejercicio 12.12 · Con máscara CIDR

Muestra las líneas de `ips.txt` con formato **IP/prefijo** (como `10.0.0.0/8`), con prefijo de 0 a 32.

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Ex "($OCTETO\.){3}$OCTETO/(3[0-2]|[12]?[0-9])" ips.txt
```

_Resultado:_

```text
10.0.0.0/8
192.168.1.0/24
```


El prefijo `(3[0-2]|[12]?[0-9])`: 30–32 o 0–29.
</details>


#### ⚫ Ejercicio 12.13 · IP con puerto

Muestra las líneas con formato **IP:puerto** válido (puerto de 0 a 65535).

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
PUERTO='(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{0,3}|0)'
grep -Ex "($OCTETO\.){3}$OCTETO:$PUERTO" ips.txt
```

_Resultado:_

```text
192.168.0.1:8080
```


El puerto es el equivalente al octeto, pero con más tramos: 65530–65535, 65500–65529, 65000–65499, 60000–64999, 10000–59999, 1–9999 y 0.
</details>


---

## 12.8 · 🏋️ Ejercicios: IPv6

#### 🟢 Ejercicio 12.14 · Las ocho

Muestra las direcciones IPv6 de `ipv6.txt` en **forma completa** (8 grupos de 1 a 4 cifras hex, sin `::`).

<details>
<summary>💡 Ver solución</summary>


```bash
H='[0-9a-f]{1,4}'
grep -Eix "(${H}:){7}${H}" ipv6.txt
```

_Resultado:_

```text
2001:0db8:85a3:0000:0000:8a2e:0370:7334
2001:db8:85a3:0:0:8a2e:370:7334
FE80:0000:0000:0000:0202:B3FF:FE1E:8329
1:2:3:4:5:6:7:8
```


`-i` para admitir `FE80:…` en mayúsculas; `-x` línea entera.
</details>


#### 🟡 Ejercicio 12.15 · ⭐ La IPv6 de tu profe: validación exacta

**"Expresión regular que identifique una IPv6."** Muestra solo las líneas de `ipv6.txt` que son una IPv6 válida (completa o abreviada con `::`).

<details>
<summary>💡 Ver solución</summary>


```bash
H='[0-9a-f]{1,4}'
grep -Eix "(${H}:){7}${H}|(${H}:){1,7}:|(${H}:){1,6}:${H}|(${H}:){1,5}(:${H}){1,2}|(${H}:){1,4}(:${H}){1,3}|(${H}:){1,3}(:${H}){1,4}|(${H}:){1,2}(:${H}){1,5}|${H}:((:${H}){1,6})|:((:${H}){1,7}|:)" ipv6.txt
```

_Resultado:_

```text
2001:0db8:85a3:0000:0000:8a2e:0370:7334
2001:db8:85a3:0:0:8a2e:370:7334
2001:db8:85a3::8a2e:370:7334
2001:db8::1
::1
::
fe80::1ff:fe23:4567:890a
fe80::
FE80:0000:0000:0000:0202:B3FF:FE1E:8329
1:2:3:4:5:6:7:8
```


Nueve alternativas: la forma completa y las ocho maneras de repartir los grupos a ambos lados del `::`. Con variable `H` = "un grupo hex de 1 a 4 cifras".
</details>


#### 🟡 Ejercicio 12.16 · Las inválidas

Muestra las líneas de `ipv6.txt` que **no son** una IPv6 válida (en el sentido del ejercicio anterior).

<details>
<summary>💡 Ver solución</summary>


```bash
H='[0-9a-f]{1,4}'
grep -Eivx "(${H}:){7}${H}|(${H}:){1,7}:|(${H}:){1,6}:${H}|(${H}:){1,5}(:${H}){1,2}|(${H}:){1,4}(:${H}){1,3}|(${H}:){1,3}(:${H}){1,4}|(${H}:){1,2}(:${H}){1,5}|${H}:((:${H}){1,6})|:((:${H}){1,7}|:)" ipv6.txt
```

_Resultado:_

```text
::ffff:192.0.2.1
2001:db8:::1
12345::1
gggg::1
2001:db8:85a3:0:0:8a2e:370:7334:1234
2001:db8
1:2:3:4:5:6:7
1::2::3
inet6 fe80::a00:27ff:fe4e:66a1/64 scope link
```

</details>


#### 🟡 Ejercicio 12.17 · Link-local

Muestra las direcciones IPv6 de **enlace local** (empiezan por `fe80:`, sin importar mayúsculas).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ei '^fe80:' ipv6.txt
```

_Resultado:_

```text
fe80::1ff:fe23:4567:890a
fe80::
FE80:0000:0000:0000:0202:B3FF:FE1E:8329
```

</details>


#### 🟡 Ejercicio 12.18 · Loopback y "no especificada"

Muestra solo las líneas **exactamente** `::1` o `::`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '::1?' ipv6.txt
```

_Resultado:_

```text
::1
::
```


`::1?` = `::` seguido de un `1` opcional. Con `-x` la línea entera.
</details>


#### 🟡 Ejercicio 12.19 · La IPv6 mapeada

Muestra las IPv6 "mapeadas a IPv4" (`::ffff:` + una IPv4 válida).

<details>
<summary>💡 Ver solución</summary>


```bash
OCTETO='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
grep -Eix "::ffff:($OCTETO\.){3}$OCTETO" ipv6.txt
```

_Resultado:_

```text
::ffff:192.0.2.1
```

</details>


#### 🟡 Ejercicio 12.20 · Las de `ip a`

Extrae **solo las direcciones IPv6** (sin el prefijo `/64`) de la salida de `ip a`.

<details>
<summary>💡 Ver solución</summary>


```bash
ip a | grep -oE 'inet6 [0-9a-f:]+' | cut -d' ' -f2
```

_Resultado:_

```text
::1
2001:db8:abcd:12::37
fe80::a00:27ff:fe4e:66a1
```


`grep -o` extrae `inet6 DIRECCIÓN`; `cut -d' ' -f2` se queda con la dirección. (Con `-P` y `\K`, un solo comando; capítulo 13.)
</details>


---

## 12.9 · 🏋️ Ejercicios: correo

#### 🟡 Ejercicio 12.21 · ⭐ El correo de tu profe

**"Expresión regular que identifique una cuenta de correo."** Muestra las líneas de `correos.txt` que sean un correo **bien formado** (versión habitual).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' correos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«juan@cas-training.com»
«nombre.apellido@dominio.es»
«user+etiqueta@gmail.com»
«ana_garcia99@ejemplo.org»
«MAYUSCULAS@EJEMPLO.COM»
«a@b.co»
«pepe@sub.dominio.co.uk»
«info@mi-empresa.net»
«usuario@dominio..com»
«usuario@-dominio.com»
«.punto@ejemplo.com»
«punto.@ejemplo.com»
«us..er@ejemplo.com»
```


`usuario@dominio.tld`: caracteres permitidos, una `@`, dominio con puntos y TLD de al menos 2 letras. Con anclas explícitas: `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`.
</details>


#### 🔴 Ejercicio 12.22 · La versión estricta

Mejora el ejercicio anterior para rechazar `usuario@dominio..com`, `usuario@-dominio.com`, `.punto@ejemplo.com`, `punto.@ejemplo.com` y `us..er@ejemplo.com`.

<details>
<summary>💡 Ver solución</summary>


```bash
L='[A-Za-z0-9_%+-]+(\.[A-Za-z0-9_%+-]+)*'
D='([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}'
grep -Ex "$L@$D" correos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«juan@cas-training.com»
«nombre.apellido@dominio.es»
«user+etiqueta@gmail.com»
«ana_garcia99@ejemplo.org»
«MAYUSCULAS@EJEMPLO.COM»
«a@b.co»
«pepe@sub.dominio.co.uk»
«info@mi-empresa.net»
```


Usuario: partes con un solo punto entre ellas. Dominio: etiquetas sin guion al borde y sin vacías.
</details>


#### 🟡 Ejercicio 12.23 · Los correos de un dominio

Muestra los correos de `correos.txt` que sean de **`ejemplo.org`** o **`ejemplo.com`** (usuario de forma habitual + `@ejemplo.` + `org`/`com`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Eix '[a-z0-9._%+-]+@ejemplo\.(org|com)' correos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ana_garcia99@ejemplo.org»
«MAYUSCULAS@EJEMPLO.COM»
«.punto@ejemplo.com»
«punto.@ejemplo.com»
«us..er@ejemplo.com»
```

</details>


#### 🟡 Ejercicio 12.24 · Solo los .org

Muestra los correos de `correos.txt` cuya terminación sea **`.org`** (línea entera, forma habitual).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.org' correos.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ana_garcia99@ejemplo.org»
```

</details>


#### 🟡 Ejercicio 12.25 · Solo el usuario

Muestra **solo el nombre de usuario** (lo que va antes de la `@`) de los correos válidos, con un solo `grep`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' correos.txt | grep -o '^[^@]*'
```

_Resultado:_

```text
juan
nombre.apellido
user+etiqueta
ana_garcia99
MAYUSCULAS
a
pepe
info
usuario
usuario
.punto
punto.
us..er
```


Dos `grep`: validar y extraer. (Con `-P` y `\K`, en uno solo: capítulo 13.)
</details>


#### 🟡 Ejercicio 12.26 · Solo el dominio

Muestra **solo el dominio** (lo que va tras la `@`) de los correos válidos.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' correos.txt | grep -o '@.*' | cut -c2-
```

_Resultado:_

```text
cas-training.com
dominio.es
gmail.com
ejemplo.org
EJEMPLO.COM
b.co
sub.dominio.co.uk
mi-empresa.net
dominio..com
-dominio.com
ejemplo.com
ejemplo.com
ejemplo.com
```


`grep -o '@.*'` extrae desde la `@` hasta el final; `cut -c2-` quita la `@`.
</details>


#### 🟡 Ejercicio 12.27 · Correos dentro de frases

Extrae todos los correos que aparezcan **dentro de frases** de `frases.txt` y `agenda.txt` (uno por línea, sin nombre de fichero).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -ohE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' frases.txt agenda.txt
```

_Resultado:_

```text
juan@ejemplo.com
ana@ejemplo.org
juan@cas-training.com
ana.garcia@ejemplo.org
luis@ejemplo.com
marta_ruiz@tienda.es
pedro@ejemplo.net
```


`-o` solo el trozo, `-h` sin nombre de fichero.
</details>


#### 🔴 Ejercicio 12.28 · Ranking de terminaciones

Muestra **cuántos correos válidos** hay por **TLD** (`com`, `es`, `org`…).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' correos.txt | grep -oE '[A-Za-z]+$' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn
```

_Resultado:_

```text
      8 com
      1 uk
      1 org
      1 net
      1 es
      1 co
```


Validamos, extraemos la última palabra (`[A-Za-z]+$`), pasamos a minúsculas con `tr` y contamos.
</details>


---

## 12.10 · 🏋️ Ejercicios: nombres de máquina

#### 🟡 Ejercicio 12.29 · ⭐ El nombre de máquina de tu profe (lectura A)

**"Nombre de máquina que tenga solo un nivel de subdominio y que el TLD tenga 3 letras."** Muestra los de `dominios.txt` con forma `máquina.dominio.tld` y TLD de **exactamente 3 letras**.

<details>
<summary>💡 Ver solución</summary>


```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "$LAB\.$LAB\.[a-z]{3}" dominios.txt
```

_Resultado_ (coincidencias entre « »):

```text
«www.cas-training.com»
«mail.google.com»
«host1.empresa.com»
«ftp.ubuntu.com»
«ns1.dominio.org»
«WWW.EJEMPLO.COM»
«aula.cas-training.com»
```


Sin variables y escrita a mano (la forma "de examen"):

```text
^[a-z0-9]([a-z0-9-]*[a-z0-9])?\.[a-z0-9]([a-z0-9-]*[a-z0-9])?\.[a-z]{3}$
```

(con la opción `-i` para admitir mayúsculas). Cada etiqueta `[a-z0-9]([a-z0-9-]*[a-z0-9])?` acepta letras, números y guiones **internos**.
</details>


#### 🟡 Ejercicio 12.30 · El mismo (lectura B)

La otra interpretación: `máquina.subdominio.dominio.tld` (**cuatro** etiquetas) y TLD de 3 letras.

<details>
<summary>💡 Ver solución</summary>


```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "$LAB\.$LAB\.$LAB\.[a-z]{3}" dominios.txt
```

_Resultado_ (coincidencias entre « »):

```text
«intranet.corp.empresa.com»
```

</details>


#### 🟡 Ejercicio 12.31 · De 2 a 3 etiquetas

Muestra los nombres con **1 o 2 etiquetas** antes del TLD de 3 letras (por ejemplo `ejemplo.org` o `www.ejemplo.com`).

<details>
<summary>💡 Ver solución</summary>


```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "($LAB\.){1,2}[a-z]{3}" dominios.txt
```

_Resultado_ (coincidencias entre « »):

```text
«www.cas-training.com»
«mail.google.com»
«ejemplo.org»
«host1.empresa.com»
«ftp.ubuntu.com»
«ns1.dominio.org»
«WWW.EJEMPLO.COM»
«aula.cas-training.com»
```


`($LAB\.){1,2}` = una o dos etiquetas con punto, y luego un TLD de 3 letras. (Con `{2,2}` o `{2}` volverías a la lectura A.)
</details>


#### 🟡 Ejercicio 12.32 · Un FQDN cualquiera

Muestra los nombres de `dominios.txt` que sean un FQDN válido (cualquier número de etiquetas, TLD de 2 o más letras).

<details>
<summary>💡 Ver solución</summary>


```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "($LAB\.)+[a-z]{2,}" dominios.txt
```

_Resultado:_

```text
www.cas-training.com
mail.google.com
ejemplo.org
servidor.dominio.es
a.b.c.ejemplo.net
host1.empresa.com
web.mi-empresa.info
ftp.ubuntu.com
mi-pc.local
test.uk
intranet.corp.empresa.com
ns1.dominio.org
WWW.EJEMPLO.COM
tienda.ejemplo.tienda
aula.cas-training.com
```

</details>


#### 🟡 Ejercicio 12.33 · TLD de dos letras

Muestra los FQDN válidos cuyo TLD tenga **exactamente 2 letras** (países: `es`, `uk`…).

<details>
<summary>💡 Ver solución</summary>


```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eix "($LAB\.)+[a-z]{2}" dominios.txt
```

_Resultado:_

```text
servidor.dominio.es
test.uk
```

</details>


#### 🟡 Ejercicio 12.34 · Los inválidos

Muestra los nombres de `dominios.txt` que **no** son un FQDN válido.

<details>
<summary>💡 Ver solución</summary>


```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -Eivx "($LAB\.)+[a-z]{2,}" dominios.txt
```

_Resultado:_

```text
localhost
-malo.ejemplo.com
malo-.ejemplo.com
ejem plo.com
ejemplo..com
www.ejemplo.com.
```


Salen `localhost`, `-malo.ejemplo.com`, `malo-.ejemplo.com`, `ejem plo.com`, `ejemplo..com` y `www.ejemplo.com.`
</details>


#### 🔴 Ejercicio 12.35 · Nombres de máquina en /etc/hosts

Extrae de `/etc/hosts` los nombres con **un solo nivel de subdominio** del dominio `miempresa` (por ejemplo `servidor.miempresa.com`).

<details>
<summary>💡 Ver solución</summary>


```bash
LAB='[a-z0-9]([a-z0-9-]*[a-z0-9])?'
grep -oE "\b$LAB\.miempresa\.[a-z]{2,3}\b" /etc/hosts
```

_Resultado:_

```text
servidor.miempresa.com
impresora.miempresa.com
nas.miempresa.com
backup.miempresa.es
antiguo.miempresa.com
```


(Fíjate que también sale `antiguo.miempresa.com`, de la línea comentada.)
</details>


---

## 12.11 · 🏋️ Ejercicios: MAC y otros formatos

#### 🟢 Ejercicio 12.36 · Una MAC sencilla

Muestra las líneas de `macs.txt` que son una **MAC** (6 pares hex separados por `:` o `-`, línea entera).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}' macs.txt
```

_Resultado:_

```text
00:1A:2B:3C:4D:5E
00-1A-2B-3C-4D-5E
00:1a:2b:3c:4d:5e
08:00:27:4e:66:a1
FF:FF:FF:FF:FF:FF
00:1A-2B:3C-4D:5E
```

</details>


#### 🟡 Ejercicio 12.37 · La MAC coherente

Rechaza las que **mezclan** `:` y `-`: el separador debe ser el mismo en toda la dirección.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '[0-9A-Fa-f]{2}([:-])([0-9A-Fa-f]{2}\1){4}[0-9A-Fa-f]{2}' macs.txt
```

_Resultado:_

```text
00:1A:2B:3C:4D:5E
00-1A-2B-3C-4D-5E
00:1a:2b:3c:4d:5e
08:00:27:4e:66:a1
FF:FF:FF:FF:FF:FF
```


`([:-])` captura el primer separador y `\1` lo repite en los otros 4 puntos: referencia hacia atrás en acción.
</details>


#### 🟡 Ejercicio 12.38 · MACs de `ip a`

Extrae las direcciones MAC (`link/ether …`) de la salida de `ip a`.

<details>
<summary>💡 Ver solución</summary>


```bash
ip a | grep -oE 'link/ether ([0-9a-f]{2}:){5}[0-9a-f]{2}' | cut -d' ' -f2
```

_Resultado:_

```text
08:00:27:4e:66:a1
02:42:ac:11:00:02
```

</details>


#### 🟡 Ejercicio 12.39 · El fabricante (OUI)

Muestra las MACs de `macs.txt` cuyos **tres primeros bytes** sean `08:00:27` (el prefijo de VirtualBox), en minúsculas o mayúsculas.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ei '^08:00:27' macs.txt
```

_Resultado:_

```text
08:00:27:4e:66:a1
```

</details>


#### 🟡 Ejercicio 12.40 · Teléfonos (formato libre)

Muestra los teléfonos de `telefonos.txt` con prefijo opcional (`+34` o `0034`), y luego **9 dígitos** que empiecen por 6, 7, 8 o 9, **agrupados** en tres bloques de 3 con espacio o guion opcionales.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '(\+34|0034)? ?[6-9][0-9]{2}[ -]?[0-9]{3}[ -]?[0-9]{3}' telefonos.txt
```

_Resultado:_

```text
612345678
712345678
912345678
+34 612 345 678
+34612345678
0034 612345678
900123456
812345678
612-345-678
```

</details>


#### 🟡 Ejercicio 12.41 · DNI o NIE

Muestra los DNI/NIE sintácticamente válidos de `dni.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '([0-9]{8}|[XYZ][0-9]{7})[A-Z]' dni.txt
```

_Resultado:_

```text
12345678Z
00000000T
X1234567L
Y7654321F
Z0000000M
```

</details>


#### 🟡 Ejercicio 12.42 · Código postal español

De la lista `28001`, `52999`, `53000`, `00123`, `08001`, muestra los **códigos postales válidos** (provincias 01–52).

<details>
<summary>💡 Ver solución</summary>


```bash
printf '28001\n52999\n53000\n00123\n08001\n' | grep -Ex '(0[1-9]|[1-4][0-9]|5[0-2])[0-9]{3}'
```

_Resultado:_

```text
28001
52999
08001
```


Provincia: `0[1-9]` (01–09), `[1-4][0-9]` (10–49), `5[0-2]` (50–52); y 3 cifras más.
</details>


#### 🟡 Ejercicio 12.43 · IBAN español

Muestra los IBAN españoles bien formados (`ES` + 2 dígitos de control + 5 bloques de 4 dígitos, con o sin espacios).

<details>
<summary>💡 Ver solución</summary>


```bash
printf 'ES91 2100 0418 4502 0005 1332\nES9121000418450200051332\nES91 2100 0418 4502 0005\n' | grep -Ex 'ES[0-9]{2}( ?[0-9]{4}){5}'
```

_Resultado:_

```text
ES91 2100 0418 4502 0005 1332
ES9121000418450200051332
```

</details>


#### 🟡 Ejercicio 12.44 · Fechas ISO

Muestra, de `2024-02-30`, `2024-13-01`, `2024-12-31`, las que tengan **formato** de fecha ISO válido (mes 01–12, día 01–31).

<details>
<summary>💡 Ver solución</summary>


```bash
printf '2024-02-30\n2024-13-01\n2024-12-31\n' | grep -Ex '[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
```

_Resultado:_

```text
2024-02-30
2024-12-31
```


`2024-02-30` pasa porque la regex **no sabe** que febrero no tiene 30 días: controlar el calendario es cosa de otros programas.
</details>


#### 🟡 Ejercicio 12.45 · URLs

Muestra las URLs bien formadas de `urls.txt` (protocolo `http`, `https` o `ftp`, un host sin espacios y una ruta opcional sin espacios).

<details>
<summary>💡 Ver solución</summary>


```bash
grep -Ex '(https?|ftp)://[^/ ]+(/[^ ]*)?' urls.txt
```

_Resultado:_

```text
http://www.ejemplo.com
https://www.ejemplo.com/
https://cas-training.com/cursos/linux?id=5&lang=es
ftp://ftp.ubuntu.com/pub/
http://localhost:8080/index.html
https://192.168.1.10:8443/admin
```

</details>


#### 🟡 Ejercicio 12.46 · URLs dentro de un texto

Extrae las URLs que aparezcan **dentro** de frases de `urls.txt`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '(https?|ftp)://[^ ]+' urls.txt | tail -4
```

_Resultado:_

```text
https://192.168.1.10:8443/admin
https://ejemplo.com/ruta
https://github.com/TheBillBull
http://ejemplo.org/pagina.html
```


`[^ ]+` se come todo hasta el siguiente espacio, por eso de `https://ejemplo.com/ruta con espacios` solo sale `https://ejemplo.com/ruta`. Los dos últimos resultados son las URLs de la frase *"Visita … y … hoy"*.
</details>


#### 🔴 Ejercicio 12.47 · Versiones

Extrae las **versiones** con formato `X.Y.Z` (o `X.Y`) de `versiones.txt`, sin repetir.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -oE '[0-9]+(\.[0-9]+){1,3}' versiones.txt | sort -u
```

_Resultado:_

```text
1.0
1.2.3
1.24.0
13.5
24.04.1
3.0.13
3.11
3.12.3
4.9
5.15.0
5.2.21
6.8.0
9.6
```

</details>


---

## ✅ Resumen del capítulo 12

| Formato | Pieza clave |
|---|---|
| **IPv4** | `(25[0-5]\|2[0-4][0-9]\|1[0-9]{2}\|[1-9]?[0-9])` por octeto, `(OCT\.){3}OCT` |
| **IPv6** | 9 alternativas según los grupos a cada lado del `::` |
| **Correo** | usuario `[A-Za-z0-9._%+-]+` + `@` + dominio `…\.[A-Za-z]{2,}` |
| **FQDN** | etiqueta `[a-z0-9]([a-z0-9-]*[a-z0-9])?` repetida + TLD `[a-z]{n}` |
| **MAC** | `([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}` (con `\1` para el mismo separador) |

**Técnicas:** `-x` (línea entera), **variables** para piezas reutilizables, `-i` (hex en cualquier caso), **`-o`** para extraer, y siempre **datos buenos y malos** para probar.

➡️ **Siguiente parada:** [Capítulo 13](13-nivel-master.md): **nivel master**. `grep -P`, `\K`, mirar alrededor (`lookahead`/`lookbehind`) y cómo reducir tuberías de 3 comandos a **uno**.

---
⬅️ [Capítulo 11 · Los logs: `syslog`, `auth.log`, `ufw.log`, `dpkg.log`, Apache…](11-logs.md) · 🏠 [Índice](README.md) · [Capítulo 13 · Nivel master: `grep -P`, `\K` y mirar alrededor](13-nivel-master.md) ➡️
