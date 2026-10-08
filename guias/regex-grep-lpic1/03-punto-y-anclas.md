# Capítulo 3 · El punto y las anclas: `.` `^` `$` `\`

> 🎯 **Objetivo:** conocer tus **primeros superpoderes**: el comodín de un carácter (`.`), los bordes de la línea (`^` y `$`) y el escudo anti-superpoderes (`\`).
>
> 📘 **LPIC-1:** 103.7 — *"special characters, anchors"*.
>
> 🧪 `cd ~/lab-regex` y vamos.

---

## 3.1 · Letras normales y letras con superpoderes

Hasta ahora buscábamos **palabras normales**: `root`, `gato`, `error`. En una expresión regular, casi todos los caracteres son **normales** y significan *"yo mismo"*: una `a` busca una `a`, un `7` busca un `7`, una coma busca una coma.

Pero **unos pocos caracteres tienen superpoderes**. Se llaman **metacaracteres** ("más allá del carácter"): en vez de buscarse a sí mismos, **dan una orden** a `grep`.

Es como en un tablero de juego: la mayoría de las fichas son peones normales, pero unas pocas son **el rey y la reina**, que tienen poderes especiales.

Los metacaracteres de las expresiones regulares **básicas** (las que usa `grep` por defecto) son:

```text
.   [   ]   ^   $   *   \
```

*(y varios más con barra invertida que iremos conociendo: `\(` `\)` `\{` `\}` `\+` `\?` `\|`)*

En este capítulo conocemos cuatro: **`.`**, **`^`**, **`$`** y **`\`**.

---

## 3.2 · El punto `.`: "aquí va cualquier carácter"

¿Has hecho crucigramas? Una casilla en blanco puede contener **cualquier letra**. Pues el **punto** es una casilla en blanco: **encaja con UN carácter, el que sea**.

```text
c.sa     →  c + (lo que sea) + s + a
```

```bash
grep 'c.sa' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«casa»
«casa»s
«cosa»
«casa»
```


Han coincidido `casa` (con `a` en la casilla), `casas`, `cosa` (con `o`) y la `casa` repetida del final. `Casa` (con mayúscula) no, porque empieza por `C` y nosotros escribimos `c`. Y `caso` no, porque tras la casilla comodín espera una `s`, y ahí hay otra letra.

### Cosas que tienes que saber del punto

**1. Es UN carácter, ni más ni menos.** Con `c.sa` no encaja `cs` ni `cuasa`. Si quieres dos casillas, dos puntos: `c..a`.

```bash
grep 'c..a' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«casa»
«casa»s
«cosa»
«cama»
«caña»
«casa»
```


**2. Encaja con *cualquier* carácter**: una letra, un número, un espacio, un símbolo, ¡hasta un punto o unos dos puntos! Pero **no** con "la ausencia de carácter": tiene que haber algo.

```bash
printf 'a1b\na b\na-b\na.b\naxb\nab\n' | grep 'a.b'
```

_Resultado_ (coincidencias entre « »):

```text
«a1b»
«a b»
«a-b»
«a.b»
«axb»
```


Han pasado las cinco primeras líneas (con `1`, espacio, `-`, `.` y `x` en medio). La sexta, `ab`, no: entre la `a` y la `b` **no hay nada**, y el punto exige **un** carácter.

> ⚠️ Guarda esto en la memoria: el punto también encaja con los **dos puntos** (`:`). Más adelante nos dará guerra.

**3. Con la codificación UTF-8, las letras con tilde y la `ñ` cuentan como UN carácter**:

```bash
grep 'ca.a' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«casa»
«casa»s
«cama»
«caña»
«casa»
```


`caña` coincide porque para `grep` (en UTF-8) la `ñ` es un solo carácter. (En una terminal antigua configurada en modo `C`, la `ñ` serían **dos** bytes y `ca.a` no encajaría: dato curioso.)

```bash
echo 'caña' | grep -c 'ca.a'
echo 'caña' | LC_ALL=C grep -c 'ca.a'
```

_Resultado:_

```text
1
0
```


---

## 3.3 · El circunflejo `^`: el principio de la línea

Piensa en una hoja de cuaderno. El **borde izquierdo** del renglón es donde "empieza la línea". El **circunflejo `^`** significa precisamente eso: *"aquí tiene que ser el principio de la línea"*.

`^root` = "la línea **empieza** por `root`".

```bash
grep '^root' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root»:x:0:0:root:/root:/bin/bash
```


Compara con `grep root`, que encontraba `root` en cualquier parte. Ahora **solo** vale si está al principio. Mira la diferencia con `daemon`:

```bash
grep -c 'bin' /etc/passwd
```

_Resultado:_

```text
41
```


```bash
grep -c '^bin' /etc/passwd
```

_Resultado:_

```text
1
```


`bin` aparece en muchísimas líneas (en `/bin/bash`, `/usr/sbin/nologin`…), pero **empezar** por `bin` solo lo hace el usuario `bin`.

> 🔑 **La primera pregunta del examen LPIC:** *"¿Qué hace `^`?"* → *Ancla el patrón al **principio de la línea***.

**Aplicación estrella (¡el ejercicio de tu profe!):** *las líneas de `/etc/os-release` que empiezan por `VERSION`*:

```bash
grep '^VERSION' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
«VERSION»_ID="24.04"
«VERSION»="24.04.1 LTS (Noble Numbat)"
«VERSION»_CODENAME=noble
```


Saltan **tres**: `VERSION_ID`, `VERSION` y `VERSION_CODENAME`; todas empiezan por `VERSION`. Pero **no** sale `PRETTY_NAME="Ubuntu 24.04.1 LTS"` ni `UBUNTU_CODENAME`, porque `VERSION` no está al principio.

---

## 3.4 · El dólar `$`: el final de la línea

El **borde derecho** del renglón. `$` significa *"aquí tiene que acabar la línea"*.

`bash$` = "la línea **acaba** en `bash`".

```bash
grep 'bash$' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
root:x:0:0:root:/root:/bin/«bash»
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/«bash»
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/«bash»
ana:x:1001:1001:Ana Garcia,,,:/home/ana:/bin/«bash»
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro:/bin/«bash»
```


Ahora sí: **los usuarios cuya shell es `bash`** (porque `bash` es lo último de la línea). En el capítulo 1 sacábamos las mismas, pero con el riesgo de coger líneas donde `bash` apareciera en medio.

```bash
grep -c 'nologin$' /etc/passwd
```

_Resultado:_

```text
29
```


> 🔑 **Examen:** `$` ancla al **final** de la línea.

### El dúo `^` + `$`: la línea ENTERA

Si pones **los dos**, exiges que la línea sea **exactamente** eso, ni un carácter más ni menos:

```bash
grep '^gato$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gato»
«gato»
```


Solo las líneas que son *exactamente* `gato` (dos veces: la primera y la del final). `gatos`, `gatito`… quedan fuera.

> 💡 Es lo mismo que hace la opción `-x` de `grep` (*"line-regexp"*). `grep -x gato` ≡ `grep '^gato$'`.

### `^$`: la línea vacía

Una línea **vacía** es una que *empieza* y *acaba* sin nada entre medias: `^$`.

```bash
grep -n '^$' conf-ejemplo.conf
```

_Resultado:_

```text
3:
5:
11:
17:
```


Son las líneas 3, 5, 11 y 17: ahí hay un salto de línea y nada más. ¿Y la línea 18? La 18 **parece** vacía, pero tiene **espacios** (tres), así que `^$` no la considera vacía. Tendrás que esperar al capítulo 5 (`^ *$`) para cazar también las "falsamente vacías".

```bash
grep -c '' conf-ejemplo.conf
grep -c '^$' conf-ejemplo.conf
grep -c '.' conf-ejemplo.conf
```

_Resultado:_

```text
23
4
19
```


Total de líneas (23), líneas vacías (4) y líneas con **al menos un carácter** (19, la `.` exige un carácter). 23 = 4 + 19. 🧮

### Contar caracteres con los puntos y las anclas

¿Cuántas casillas hay? `^.$` es una línea de **un** carácter; `^..$`, de dos; `^...$`, de tres:

```bash
grep '^...$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ala»
«oso»
«ojo»
«sol»
«sal»
«mar»
«luz»
«pan»
«paz»
«aaa»
«abc»
«zsh»
```


Palabras de **exactamente 3 caracteres**. (Y `^.$` encuentra la línea que solo tiene una `a`.) Sin las anclas, `...` encontraría **cualquier línea con tres o más** caracteres.

### Dónde NO funcionan como anclas

`^` solo es ancla **al principio del patrón** y `$` **al final** (en las regex básicas). En cualquier otro sitio son **caracteres normales**:

```bash
printf 'a^b\na$b\nab\n' | grep 'a^b'
printf 'a^b\na$b\nab\n' | grep 'a$b'
```

_Resultado:_

```text
a^b
a$b
```


Un `^` en medio es un circunflejo normal. *(Ojo: en las regex **extendidas**, que veremos en el capítulo 8, siempre son anclas.)*

---

## 3.5 · La barra invertida `\`: el escudo anti-superpoderes

Y ahora la pregunta del millón: **¿cómo busco un punto de verdad?** Si escribo `3.14`, el punto es un comodín y encaja con `3x14` o con `3,14`:

```bash
grep '3.14' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«3.14»
«3x14»
«3,14»
```


Han coincidido `3.14` (el que queríamos), `3x14` y `3,14` (señuelos que cuelan). Para decirle a `grep` *"quiero un punto de verdad, no un comodín"* le pones por delante la **barra invertida `\`**, que **desactiva** el superpoder del carácter siguiente:

```bash
grep '3\.14' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«3.14»
```


Ahora solo coincide el número con punto de verdad. A esto se le llama **escapar** un carácter.

> 🧠 La barra `\` es un **escudo** (o una capa de invisibilidad): *"el carácter siguiente, aunque tenga superpoderes, trátalo como un carácter normal"*.

### Lo mismo con la IP del gateway

```bash
grep '192.168.1.1' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168.1.1»
«192x168x1x1»
```


Sin escapar, cuela `192x168x1x1`. Escapando los puntos:

```bash
grep '192\.168\.1\.1' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168.1.1»
```


### Los caracteres que normalmente hay que escapar

| Quiero buscar… | Escribo | Ejemplo |
|---|---|---|
| un **punto** | `\.` | `3\.14` |
| un **dólar** | `\$` | `\$99` |
| un **asterisco** | `\*` | `2\*3` |
| un **corchete** `[` | `\[` | `\[ERROR\]` |
| una **barra invertida** | `\\` | `C:\\Windows` |
| un **circunflejo** al principio | `\^` | `\^cuidado` |

```bash
grep '\$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«$»99
```


Las líneas con un `$` de verdad (`$99`). Si no lo escapas, `grep '$'` coincide con **todas** las líneas (todas tienen un final de línea):

```bash
grep -c '$' numeros.txt
grep -c '' numeros.txt
```

_Resultado:_

```text
33
33
```


### Un error típico: el corchete solo

```bash
grep '[' palabras.txt
```

_Resultado:_

```text
grep: Invalid regular expression
```


`grep` se queja porque `[` **abre** algo (un grupo de caracteres, capítulo 4) que nunca cierra. (El texto del error exacto depende de la versión de `grep`.) Escapado funciona:

```bash
grep '\[' palabras.txt
```

_Resultado:_

```text
(no sale nada)
```


Nada, porque no hay corchetes en esa lista; pero ya no da error.

### Letras normales: ¡no las escapes!

Los caracteres normales **no** se escapan: ni la coma, ni los dos puntos, ni el guion, ni la arroba, ni el espacio, ni las letras, ni los números. En particular:

- `:` → `grep ':'` busca un `:`. (No `\:`: eso es **innecesario**, y en las versiones nuevas de `grep` incluso da un aviso.)
- `,` → una coma es una coma. **Por ahora.** Más adelante verás que *dentro de unas llaves* `{2,5}` la coma sí tiene un papel especial, y por qué.

```bash
grep -c ',,,' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
9
```


Nueve usuarios tienen `,,,` en el campo de comentarios (la coma es una letra normal).

---

## 3.6 · ⚠️ Trampas y curiosidades

### Trampa 1: el punto también coincide con los dos puntos

Queremos los usuarios cuyo **nombre tenga 4 letras**. Un intento ingenuo: nombre = 4 caracteres seguidos de `:` al principio de línea…

```bash
grep '^....:' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root:»x:0:0:root:/root:/bin/bash
«sync:»x:4:65534:sync:/bin:/bin/sync
«lp:x:»7:7:lp:/var/spool/lpd:/usr/sbin/nologin
«mail:»x:8:8:mail:/var/mail:/usr/sbin/nologin
«news:»x:9:9:news:/var/spool/news:/usr/sbin/nologin
«uucp:»x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
«list:»x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
«_apt:»x:42:65534::/nonexistent:/usr/sbin/nologin
«sshd:»x:105:65534::/run/sshd:/usr/sbin/nologin
«luis:»x:1002:1002:Luis Perez,,,:/home/luis:/bin/zsh
```


¿Ves el intruso? **`lp`** tiene solo 2 letras, pero ha colado. La línea es `lp:x:7:7:…` y el patrón `^....:` se aplica así: `l`, `p`, `:` y `x` son los **cuatro puntos** (¡el `:` cuenta como "un carácter cualquiera"!) y el siguiente carácter es el segundo `:`, que es justo lo que pedía el patrón. ¡**El `.` también se come los `:`**! En el [capítulo 4](04-corchetes.md) lo arreglaremos con `[^:]` ("cualquier cosa que no sea dos puntos").

### Trampa 2: los espacios invisibles al final

La línea 18 de `frases.txt` dice "Esta frase termina con espacios." Busquemos una frase que **acabe en** `con espacios.`:

```bash
grep -n 'con espacios\.$' frases.txt
```

_Resultado:_

```text
(no sale nada)
```


¡No sale nada! Pero la frase **está ahí**:

```bash
grep -n 'termina con espacios\.' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
18:Esta frase «termina con espacios.»   
```


¿Por qué falla `$`? Mira el final de la línea con `cat -A` (que marca el fin de línea con un `$`):

```bash
sed -n 18p frases.txt | cat -A
```

_Resultado:_

```text
Esta frase termina con espacios.   $
```


Tras el punto hay **tres espacios invisibles**, así que el punto no es lo último de la línea. Un clásico: el fichero *parece* correcto y `$` no coincide. (Solución en el capítulo 5: `\.[[:space:]]*$`.)

### Trampa 3: los finales de línea de Windows

Los ficheros creados en Windows terminan cada línea con **dos** caracteres invisibles (`\r\n`) en vez de uno (`\n`). Lo vemos con `cat -A` (muestra `^M` para el retorno de carro y `$` para el fin de línea):

```bash
cat -A windows.txt
```

_Resultado:_

```text
hola^M$
mundo^M$
linux^M$
```


Y entonces `$` ya no es lo que parece:

```bash
grep -c 'mundo' windows.txt
grep -c 'mundo$' windows.txt
```

_Resultado:_

```text
1
0
```


`mundo` está en el fichero, pero **`mundo$` no coincide** porque tras `mundo` hay un carácter invisible (`\r`) antes del fin de línea. Lo arreglamos en el capítulo 5.

---

## 3.7 · Quitar comentarios y líneas vacías (el clásico de los ficheros de configuración)

Casi todos los ficheros de configuración de Linux tienen:

- **Comentarios**: líneas que empiezan por `#` (o `;`).
- **Líneas vacías.**

Y lo que muchas veces queremos ver es **solo la configuración "de verdad"**. Con lo aprendido ya puedes hacerlo:

```text
quita las líneas que empiezan por #   →  -v '^#'
quita las líneas vacías               →  -v '^$'
```

Se pueden juntar con **dos `-e`** (recuerda: `-e` = "esta pista **o** esta"; y `-v` invierte: "ni la una ni la otra"):

```bash
grep -v -e '^#' -e '^$' /etc/ssh/sshd_config
```

_Resultado:_

```text
Include /etc/ssh/sshd_config.d/*.conf
PermitRootLogin no
MaxAuthTries 3
PubkeyAuthentication yes
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
AllowUsers alumno ana luis
```


¡Ahí está la configuración activa de `sshd`, sin ruido! Y para contar cuántas directivas activas hay:

```bash
grep -vc -e '^#' -e '^$' /etc/ssh/sshd_config
```

_Resultado:_

```text
11
```


> 🏅 **Este comando es un clásico** que usarás toda tu vida. Tiene dos limitaciones que resolveremos más adelante: no quita comentarios **con sangría** (`    # algo`) ni líneas que solo tienen espacios.

---

## 3.8 · 🏋️ Ejercicios

#### 🟢 Ejercicio 3.1 · La casilla del crucigrama

Muestra las líneas de `palabras.txt` que cumplan: `p`, un carácter cualquiera, `rro`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'p.rro' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«perro»
```


La `.` ocupa la casilla central: `perro` (con `e`). Fíjate que `Perro` no, porque empieza por `P` mayúscula.
</details>


#### 🟢 Ejercicio 3.2 · Palabras de 5 letras

Muestra las palabras de `palabras.txt` que tengan **exactamente 5 caracteres**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^.....$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«gatos»
«perro»
«Perro»
«perra»
«casas»
«cañón»
«árbol»
«Árbol»
«ñandú»
«radar»
«rotor»
«silla»
«libro»
«hoola»
«Linux»
«linux»
«LINUX»
«egrep»
«fgrep»
```


Cinco puntos entre `^` y `$`: la línea debe empezar, tener 5 caracteres cualquiera y acabar. Sin los anclajes saldrían todas las palabras de 5 o más.
</details>


#### 🟢 Ejercicio 3.3 · Comentarios del fstab

Muestra las líneas de `/etc/fstab` que son **comentarios** (empiezan por `#`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^#' /etc/fstab
```

_Resultado_ (coincidencias entre « »):

```text
«#» /etc/fstab: static file system information.
«#»
«#» <file system> <mount point>   <type>  <options>       <dump>  <pass>
«#» / was on /dev/sda2 during installation
«#» /boot/efi was on /dev/sda1 during installation
```

</details>


#### 🟢 Ejercicio 3.4 · Fstab sin comentarios

Muestra las líneas de `/etc/fstab` que **no** son comentarios.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v '^#' /etc/fstab
```

_Resultado:_

```text
UUID=3f5a9c1e-7b2d-4e8a-9c01-5d6e7f8a9b0c /               ext4    errors=remount-ro 0       1
UUID=A1B2-C3D4  /boot/efi       vfat    umask=0077      0       1
/swapfile                                 none            swap    sw              0       0
/dev/sdb1       /datos          ext4    defaults        0       2
/dev/sdc1       /backup         xfs     defaults,noatime 0      2
//nas/compartido /mnt/nas       cifs    credentials=/root/.cred,uid=1000 0 0
tmpfs           /tmp            tmpfs   defaults,size=2G 0      0
```


`-v` invierte el criterio. Las líneas que quedan son los sistemas de ficheros montados de verdad.
</details>


#### 🟢 Ejercicio 3.5 · Usuarios con bash

Muestra los usuarios de `/etc/passwd` cuya **shell** sea `bash` (la línea **acaba** en `bash`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep 'bash$' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
root:x:0:0:root:/root:/bin/«bash»
postgres:x:111:113:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/«bash»
alumno:x:1000:1000:Alumno Linux,,,:/home/alumno:/bin/«bash»
ana:x:1001:1001:Ana Garcia,,,:/home/ana:/bin/«bash»
pedro:x:1004:1100:Pedro Gomez,,,:/home/pedro:/bin/«bash»
```

</details>


#### 🟢 Ejercicio 3.6 · Sin sesión

Cuenta los usuarios de `/etc/passwd` cuya línea **acaba** en `nologin`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c 'nologin$' /etc/passwd
```

_Resultado:_

```text
29
```

</details>


#### 🟢 Ejercicio 3.7 · La pregunta de tu profe, parte 1

Escribe una expresión regular que obtenga las **líneas que empiezan por `VERSION`** del fichero `/etc/os-release`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^VERSION' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
«VERSION»_ID="24.04"
«VERSION»="24.04.1 LTS (Noble Numbat)"
«VERSION»_CODENAME=noble
```


`^` ancla al principio. Salen `VERSION_ID`, `VERSION` y `VERSION_CODENAME`.

(En el [capítulo 13](13-nivel-master.md) verás la parte 2: *devolver solo el número* de versión, en un único comando.)
</details>


#### 🟢 Ejercicio 3.8 · Solo la clave "VERSION="

De `/etc/os-release`, muestra **solo** la línea cuya clave es exactamente `VERSION` (la que lleva `VERSION=`, no `VERSION_ID=`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^VERSION=' /etc/os-release
```

_Resultado_ (coincidencias entre « »):

```text
«VERSION=»"24.04.1 LTS (Noble Numbat)"
```


El `=` es una letra normal. Añadirlo descarta `VERSION_ID` y `VERSION_CODENAME`.
</details>


#### 🟢 Ejercicio 3.9 · Empiezan por "s"

Muestra los usuarios de `/etc/passwd` cuyo **nombre empieza por `s`**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^s' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«s»ys:x:3:3:sys:/dev:/usr/sbin/nologin
«s»ync:x:4:65534:sync:/bin:/bin/sync
«s»ystemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin
«s»ystemd-timesync:x:996:996:systemd Time Synchronization:/:/usr/sbin/nologin
«s»ystemd-resolve:x:991:991:systemd Resolver:/:/usr/sbin/nologin
«s»yslog:x:101:105::/nonexistent:/usr/sbin/nologin
«s»shd:x:105:65534::/run/sshd:/usr/sbin/nologin
```

</details>


#### 🟢 Ejercicio 3.10 · Cuántas líneas vacías

Cuenta las líneas **vacías** de `conf-ejemplo.conf`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '^$' conf-ejemplo.conf
```

_Resultado:_

```text
4
```


`^$`: la línea empieza y acaba sin nada en medio. Hay 4. (La línea con espacios no cuenta como vacía para `^$`.)
</details>


#### 🟢 Ejercicio 3.11 · Dónde están las líneas vacías

Muestra el **número** de cada línea vacía de `conf-ejemplo.conf`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -n '^$' conf-ejemplo.conf
```

_Resultado:_

```text
3:
5:
11:
17:
```


Cada resultado muestra el número de línea y nada más (porque la línea está vacía).
</details>


#### 🟢 Ejercicio 3.12 · Fichero sin líneas vacías

Muestra `conf-ejemplo.conf` **sin** las líneas vacías.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v '^$' conf-ejemplo.conf
```

_Resultado:_

```text
# Fichero de configuracion de ejemplo
# Los comentarios empiezan por almohadilla
; Esto es un comentario estilo ini
[servidor]
puerto = 8080
host=localhost
    # comentario con sangria
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
# fin
```


Mira la línea que parece vacía pero sigue ahí: es la de los 3 espacios. Tiene caracteres, así que `^$` no la reconoce.
</details>


#### 🟢 Ejercicio 3.13 · La línea exacta

Muestra solo las líneas de `palabras.txt` que sean **exactamente** `casa` (ni `casas` ni `Casa`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^casa$' palabras.txt
# Otra forma equivalente:
grep -x casa palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«casa»
«casa»
```


Las dos formas dan lo mismo: `^…$` o la opción `-x` (*match the whole line*).
</details>


#### 🟢 Ejercicio 3.14 · Palabras de 3 letras

Muestra las palabras de exactamente 3 caracteres.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^...$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ala»
«oso»
«ojo»
«sol»
«sal»
«mar»
«luz»
«pan»
«paz»
«aaa»
«abc»
«zsh»
```

</details>


#### 🟢 Ejercicio 3.15 · La palabra de una sola letra

Muestra las líneas de `palabras.txt` que contengan **un único carácter**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^.$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«a»
```

</details>


#### 🟡 Ejercicio 3.16 · Frases con punto final

Muestra las líneas de `frases.txt` que **terminen en un punto** (`.`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '\.$' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
El perro come carne«.»
El gato duerme en el sofá«.»
La casa es grande y blanca«.»
Hoy es lunes, 14 de octubre de 2024«.»
Mañana será martes«.»
El el perro ladra mucho«.»
Voy a a la playa«.»
Linux es libre, Linux es gratis«.»
Me gusta el café, el té y el chocolate«.»
Tengo 3 gatos, 2 perros y 15 peces«.»
El número de teléfono es 612345678«.»
Mi correo es juan@ejemplo.com y el tuyo es ana@ejemplo.org«.»
   Esta frase empieza con tres espacios«.»
	Esta empieza con un tabulador«.»
Fin«.»
```


`\.` es un punto de verdad y `$` marca el final. (Si pusieras `.$` sin escapar, significaría "cualquier carácter al final", es decir, **todas** las líneas no vacías.)

¿Qué líneas **no** han salido? `¿Dónde está la biblioteca?` y `¡Qué día tan bonito!` (acaban en `?` y `!`), las dos líneas sin puntuación final, y `Esta frase termina con espacios.   `: aunque *lleva* un punto, tiene **tres espacios detrás**, así que el punto no es lo último de la línea.
</details>


#### 🟡 Ejercicio 3.17 · Preguntas

Muestra las líneas de `frases.txt` que **terminan en `?`**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '?$' frases.txt
```

_Resultado_ (coincidencias entre « »):

```text
¿Dónde está la biblioteca«?»
```


En las regex **básicas**, `?` es un carácter normal (en las extendidas, no: capítulo 8). Por eso no hace falta escaparlo aquí.
</details>


#### 🟡 Ejercicio 3.18 · Dólares de verdad

Muestra las líneas de `numeros.txt` que contengan un símbolo `$`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '\$' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«$»99
```


Sin la barra, `$` sería "fin de línea" y coincidiría con todas las líneas.
</details>


#### 🟡 Ejercicio 3.19 · El peligro del dólar sin escapar

Demuestra que `grep -c '$' numeros.txt` cuenta **todas** las líneas del fichero.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c '$' numeros.txt
grep -c '' numeros.txt
```

_Resultado:_

```text
33
33
```


Las dos cifras coinciden: cualquier línea tiene un final, así que `$` coincide con todas.
</details>


#### 🟡 Ejercicio 3.20 · Números con punto decimal

Muestra las líneas de `numeros.txt` que contengan un **punto de verdad**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '\.' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
3«.»14
0«.»5
«.»5
10«.»
1«.»000«.»000
99«.»99€
```


Salen `3.14`, `0.5`, `.5`, `10.`, `1.000.000` y `99.99€`: todas llevan un punto de verdad. No sale `3x14` ni `3,14`, que tienen otro carácter en esa posición.
</details>


#### 🟡 Ejercicio 3.21 · El señuelo del 3.14

Muestra solo el `3.14` de `numeros.txt` (que **no** salgan `3x14` ni `3,14`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '3\.14' numeros.txt
```

_Resultado_ (coincidencias entre « »):

```text
«3.14»
```

</details>


#### 🟡 Ejercicio 3.22 · La IP exacta

Muestra la línea de `ips.txt` que contiene la IP `192.168.1.1` **de verdad** (no `192x168x1x1`).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '192\.168\.1\.1' ips.txt
```

_Resultado_ (coincidencias entre « »):

```text
«192.168.1.1»
```


Cada punto de la IP hay que escaparlo. Y ojo: esto también encontraría una línea `192.168.1.100` (porque tras el `1` final puede seguir lo que sea). Esa pega la resolvemos en el capítulo 7 con `\b` y `-w`.
</details>


#### 🟡 Ejercicio 3.23 · IPs del bloque 192.168 en hosts

Muestra las líneas de `/etc/hosts` que **empiezan** por `192.168` (descartando la que está comentada).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^192\.168' /etc/hosts
```

_Resultado_ (coincidencias entre « »):

```text
«192.168».1.10   servidor.miempresa.com   servidor
«192.168».1.11   impresora.miempresa.com  impresora
«192.168».1.20   nas.miempresa.com        nas
```


El `^` descarta la línea `#192.168.1.99 …` porque esa empieza por `#`. Y la barra impide que el punto sea comodín.
</details>


#### 🟡 Ejercicio 3.24 · Configuración activa de /etc/hosts

Muestra las líneas **activas** de `/etc/hosts`: ni comentarios, ni líneas vacías. **En un solo comando.**

<details>
<summary>💡 Ver solución</summary>


```bash
grep -v -e '^#' -e '^$' /etc/hosts
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


Dos `-e` con `-v`: se descartan las líneas que cumplan *cualquiera* de los dos patrones.
</details>


#### 🟡 Ejercicio 3.25 · Directivas activas de sshd

Cuenta cuántas líneas **activas** (ni comentarios ni vacías) tiene `/etc/ssh/sshd_config`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -vc -e '^#' -e '^$' /etc/ssh/sshd_config
```

_Resultado:_

```text
11
```


`-v` invierte, `-c` cuenta, y `-e` dos veces. Un solo `grep`.
</details>


#### 🟡 Ejercicio 3.26 · Shells "falsas"

Muestra los usuarios de `/etc/passwd` cuya línea **acaba** en `:/bin/false`.

<details>
<summary>💡 Ver solución</summary>


```bash
grep ':/bin/false$' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
tss:x:104:107:TPM software stack,,,:/var/lib/tpm«:/bin/false»
pollinate:x:106:1::/var/cache/pollinate«:/bin/false»
mysql:x:110:112:MySQL Server,,,:/nonexistent«:/bin/false»
backup2:x:1006:34:Copias nocturnas:/srv/backup«:/bin/false»
```


Los dos puntos son letras normales. Son usuarios de servicios (bases de datos…) que no deben abrir sesión.
</details>


#### 🟡 Ejercicio 3.27 · Campos vacíos

En `/etc/passwd`, muestra los usuarios que tienen el campo de comentario **vacío** (dos `:` seguidos justo después del GID).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '::' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
_apt:x:42:65534«::»/nonexistent:/usr/sbin/nologin
messagebus:x:100:104«::»/nonexistent:/usr/sbin/nologin
syslog:x:101:105«::»/nonexistent:/usr/sbin/nologin
uuidd:x:102:106«::»/run/uuidd:/usr/sbin/nologin
sshd:x:105:65534«::»/run/sshd:/usr/sbin/nologin
pollinate:x:106:1«::»/var/cache/pollinate:/bin/false
tcpdump:x:107:108«::»/nonexistent:/usr/sbin/nologin
landscape:x:108:109«::»/var/lib/landscape:/usr/sbin/nologin
```


`::` significa "campo vacío" porque entre un `:` y el siguiente no hay nada. Los `:` son letras normales. (Ojo: esto podría coincidir con cualquier otro campo vacío, no solo el de comentarios; aquí es el único que se da.)
</details>


#### 🟡 Ejercicio 3.28 · Comas, que son letras normales

Cuenta cuántas líneas de `/etc/passwd` contienen **tres comas seguidas**.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -c ',,,' /etc/passwd
```

_Resultado:_

```text
9
```


Una coma es una letra normal. (Más adelante verás que dentro de `{ }` sí significa otra cosa.)
</details>


#### 🟡 Ejercicio 3.29 · Un día concreto en dpkg.log

Muestra las líneas de `/var/log/dpkg.log` del **5 de noviembre de 2024** (empiezan por `2024-11-05`) que sean de tipo `upgrade`. *(Pista: dos pistas en un solo patrón, la fecha al principio y la palabra `upgrade` en cualquier parte… ya sabes hacerlo con dos `grep` en tubería.)*

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^2024-11-05' /var/log/dpkg.log | grep ' upgrade '
```

_Resultado:_

```text
2024-11-05 09:10:41 upgrade libssl3t64:amd64 3.0.13-0ubuntu3.1 3.0.13-0ubuntu3.4
2024-11-05 09:10:44 upgrade openssh-client:amd64 1:9.6p1-3ubuntu13.4 1:9.6p1-3ubuntu13.5
2024-11-05 09:10:49 upgrade python3.12:amd64 3.12.3-1ubuntu0.1 3.12.3-1ubuntu0.3
2024-11-05 09:10:58 upgrade linux-image-6.8.0-45-generic:amd64 6.8.0-44.44 6.8.0-45.45
```


Primero `^` limita a las líneas que empiezan por esa fecha; luego se filtra `upgrade` (con espacios alrededor para no coger otras palabras). En el [capítulo 5](05-repeticiones.md) verás cómo unirlo en **un solo** `grep` con `.*`.
</details>


#### 🔴 Ejercicio 3.30 · El intruso `lp`

Con `grep '^....:' /etc/passwd` buscamos usuarios de 4 letras, pero se cuela `lp`. Explica por qué (sin arreglarlo; eso viene en el siguiente capítulo).

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^....:' /etc/passwd
```

_Resultado_ (coincidencias entre « »):

```text
«root:»x:0:0:root:/root:/bin/bash
«sync:»x:4:65534:sync:/bin:/bin/sync
«lp:x:»7:7:lp:/var/spool/lpd:/usr/sbin/nologin
«mail:»x:8:8:mail:/var/mail:/usr/sbin/nologin
«news:»x:9:9:news:/var/spool/news:/usr/sbin/nologin
«uucp:»x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
«list:»x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
«_apt:»x:42:65534::/nonexistent:/usr/sbin/nologin
«sshd:»x:105:65534::/run/sshd:/usr/sbin/nologin
«luis:»x:1002:1002:Luis Perez,,,:/home/luis:/bin/zsh
```


La línea de `lp` es `lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin`. El patrón `^....:` pide 4 caracteres cualquiera y luego un `:`. Los 4 primeros caracteres son `l`, `p`, `:` y `x` (¡el segundo `:` también cuenta como "carácter cualquiera"!), y el siguiente carácter es otro `:`. Por eso coincide, aunque el nombre solo tenga 2 letras.

La solución buena (capítulo 4): `^[^:][^:][^:][^:]:`, donde `[^:]` significa "cualquier cosa **menos** dos puntos".
</details>


#### 🔴 Ejercicio 3.31 · Finales de línea de Windows

Comprueba con `cat -A` que `windows.txt` tiene finales de línea de Windows, y demuestra que `grep 'mundo$'` falla.

<details>
<summary>💡 Ver solución</summary>


```bash
cat -A windows.txt
grep -c 'mundo$' windows.txt
```

_Resultado:_

```text
hola^M$
mundo^M$
linux^M$
0
```


`cat -A` revela `^M` (el retorno de carro `\r`) antes del `$` (fin de línea). Como `mundo` no es lo último de la línea (le sigue el `\r`), `mundo$` no coincide. Para ficheros así existe el programa `dos2unix`, o una regex que acepte el `\r` (capítulo 5).
</details>


#### 🔴 Ejercicio 3.32 · Línea con espacios que parece vacía

La línea 18 de `conf-ejemplo.conf` parece vacía. Demuestra que `^$` **no** la reconoce y averigua cuántos caracteres tiene realmente.

<details>
<summary>💡 Ver solución</summary>


```bash
grep -n '^$' conf-ejemplo.conf
sed -n 18p conf-ejemplo.conf | cat -A
```

_Resultado:_

```text
3:
5:
11:
17:
   $
```


`cat -A` muestra `   $`: son **tres espacios** y luego el fin de línea. Por eso `^$` (que exige *nada* entre inicio y fin) no la ve. Con `^   $` (tres espacios) sí; con `^ *$` (cualquier número de espacios, capítulo 5) también.
</details>


#### ⚫ Ejercicio 3.33 · ¿Quién empieza y acaba?

Muestra las líneas de `palabras.txt` que **empiecen por `a`** y **acaben por `a`** y tengan exactamente **tres** caracteres.

<details>
<summary>💡 Ver solución</summary>


```bash
grep '^a.a$' palabras.txt
```

_Resultado_ (coincidencias entre « »):

```text
«ala»
«aaa»
```


`^a` (empieza por a) + `.` (un carácter) + `a$` (acaba en a). Tres casillas. Salen `ala` y `aaa`.
</details>


---

## ✅ Resumen del capítulo 3

| Símbolo | Nombre | Significa | Ejemplo |
|---|---|---|---|
| `.` | punto | **un** carácter cualquiera | `c.sa` → casa, cosa… |
| `^` | circunflejo | **principio** de línea | `^root` |
| `$` | dólar | **final** de línea | `bash$` |
| `^$` | | línea **vacía** | `grep -c '^$'` |
| `^…$` | | la línea **entera** es… | `^gato$` ≡ `-x gato` |
| `\` | barra invertida | **escapa**: convierte en normal el carácter siguiente | `3\.14` |

**Trampas:** el `.` también coincide con `:`; `$` y los espacios o `\r` invisibles; un `[` suelto da error.

**Receta:** quitar comentarios y vacías → `grep -v -e '^#' -e '^$' fichero`.

➡️ **Siguiente parada:** el [Capítulo 4](04-corchetes.md): los **corchetes**, la herramienta más poderosa de este nivel.

---
⬅️ [Capítulo 2 · Comodines de la terminal ≠ expresiones regulares](02-comodines-vs-regex.md) · 🏠 [Índice](README.md)
