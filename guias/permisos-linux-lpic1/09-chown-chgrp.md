# Capítulo 9 · `chown` y `chgrp`: cambiar el dueño y el grupo

> 🎯 **Objetivo:** cambiar **quién es el dueño** y **qué grupo** tiene un fichero, saber **quién tiene permiso para hacerlo** (¡no es quien crees!), dominar todas las sintaxis (`usuario:grupo`, `:grupo`, `usuario:`), el modo recursivo y los casos de la vida real (ficheros que se quedan de `root` por usar `sudo`).
>
> 📘 **LPIC-1:** 104.5 (`chown`, `chgrp`).
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`.

---

## 9.1 · Qué cambia cada comando

| Comando | Cambia… | Ejemplo |
|---|---|---|
| **`chown`** (*change owner*) | el **dueño** (y opcionalmente el grupo) | `chown ana f` |
| **`chgrp`** (*change group*) | solo el **grupo** | `chgrp equipo f` |
| **`chmod`** | los **permisos** (capítulos 6-7) | `chmod 640 f` |

Los tres son independientes: cambiar el dueño **no** cambia los permisos, y al revés.

---

## 9.2 · ¿Quién puede cambiar qué? **La regla que sorprende**

| Acción | ¿Quién puede? |
|---|---|
| Cambiar el **dueño** (`chown ana f`) | **solo `root`** (¡ni el propio dueño!) |
| Cambiar el **grupo** (`chgrp g f`) | `root`, **o el dueño** si **él mismo pertenece al grupo `g`** |
| Cambiar los **permisos** (`chmod`) | el **dueño** o `root` |

¿Por qué **el dueño no puede regalar** su fichero? Para que nadie pueda **endosar** ficheros a otros (cuotas de disco, ficheros "trampa" que hagan parecer culpable a otro usuario…). Lo comprobamos:

```text
$ echo "contenido" > regalo.txt
$ chown ana regalo.txt
chown: changing ownership of 'regalo.txt': Operation not permitted
$ chgrp equipo regalo.txt
chgrp: changing group of 'regalo.txt': Operation not permitted
$ sudo chown ana regalo.txt
$ ls -l regalo.txt
-rw-rw-r-- 1 ana alumno 10 Oct 16 17:08 regalo.txt
```

- `chown ana …` → **`Operation not permitted`**: no eres `root`.
- `chgrp equipo …` → también falla: **tú no eres miembro de `equipo`** (el dueño solo puede asignar grupos **a los que pertenece**).
- Con `sudo` sí funciona.

Y ahora, con una dueña que **sí** es de `equipo` (`ana`) y de ningún `soporte`:

```text
$ sudo -u ana chgrp equipo regalo.txt
$ ls -l regalo.txt
-rw-rw-r-- 1 ana equipo 10 Oct 16 17:08 regalo.txt
$ sudo -u ana chgrp soporte regalo.txt
chgrp: changing group of 'regalo.txt': Operation not permitted
```

`ana` (dueña) puede ponerle `equipo` (es miembro) pero **no** `soporte` (no lo es).

> 🧠 **Resumen para el examen:** *solo `root` puede cambiar el dueño*; el dueño solo puede cambiar el grupo **a uno de sus propios grupos**.

---

## 9.3 · Todas las sintaxis

```text
chown  [usuario] [ : [grupo] ]  fichero…
         │            │   │
         │            │   └─ el grupo (opcional)
         │            └───── los dos puntos separan usuario y grupo
         └────────────────── el usuario (opcional)
```

| Forma | Efecto | Ejemplo |
|---|---|---|
| `chown ana f` | solo el **dueño** | dueño `ana`, el grupo no cambia |
| `chown ana:equipo f` | **dueño y grupo** | `ana` y `equipo` |
| `chown :equipo f` | solo el **grupo** (igual que `chgrp equipo f`) | |
| `chown ana: f` | dueño `ana` y grupo **= su grupo de inicio de sesión** | `ana:ana` |
| `chown ana.equipo f` | igual que `ana:equipo` (**sintaxis antigua**, evítala) | los usuarios con punto en el nombre la rompen |
| `chown 1002:1005 f` | con **números** (UID y GID) | |
| `chown --reference=otro f` | copia dueño y grupo de `otro` | |

```text
$ touch c1 c2 c3 c4 c5
$ sudo chown ana c1
$ sudo chown ana:equipo c2
$ sudo chown :soporte c3
$ sudo chown beto: c4
$ sudo chown 1004:1006 c5
$ ls -l c1 c2 c3 c4 c5
-rw-rw-r-- 1 ana    alumno  0 Oct 16 17:08 c1
-rw-rw-r-- 1 ana    equipo  0 Oct 16 17:08 c2
-rw-rw-r-- 1 alumno soporte 0 Oct 16 17:08 c3
-rw-rw-r-- 1 beto   beto    0 Oct 16 17:08 c4
-rw-rw-r-- 1 carla  soporte 0 Oct 16 17:08 c5
```

Lee la salida:

- `c1` → dueño `ana`; el grupo se quedó `alumno`.
- `c2` → `ana:equipo`.
- `c3` → solo cambió el **grupo** (`soporte`).
- `c4` → `beto:` = `beto` **y su grupo principal** (`beto`).
- `c5` → con **números** (UID y GID). En este laboratorio 1004 = `carla` y 1006 = `soporte`; en tu máquina pueden ser otros (míralos con `id carla`). ¡`ls` calcula los nombres al listar!

> ⚠️ Con `chown ana: f` los **dos puntos sin grupo detrás** significan "su grupo principal". Con `chown ana f` (sin dos puntos) **no se toca** el grupo.

### Para ver los números reales

```text
$ ls -ln c5
-rw-rw-r-- 1 1004 1006 0 Oct 16 17:08 c5
$ sudo chown 4242:4242 c5
$ ls -l c5
-rw-rw-r-- 1 4242 4242 0 Oct 16 17:08 c5
```

Si pones un número que **no corresponde a nadie**, `ls -l` enseña el **número** (el fichero queda **huérfano**). Los ficheros sin dueño válido se buscan con `find / -nouser -o -nogroup`.

---

## 9.4 · Las opciones útiles

| Opción | Hace |
|---|---|
| `-R` | **recursivo**: carpeta y todo lo que contiene |
| `-v` | cuenta cada fichero procesado |
| `-c` | informa **solo de los que cambian** |
| `--from=ANTIGUO` | cambia **solo si** ahora el dueño (o `:grupo`) es `ANTIGUO` |
| `--reference=MODELO` | copia dueño y grupo de `MODELO` |
| `-h` | si es un **enlace simbólico**, cambia **el enlace** (no el destino) |
| `--preserve-root` | no actúa sobre `/` con `-R` |

```text
$ touch o1 o2 o3
$ sudo chown -v ana:equipo o1 o2 o3
changed ownership of 'o1' from alumno:alumno to ana:equipo
changed ownership of 'o2' from alumno:alumno to ana:equipo
changed ownership of 'o3' from alumno:alumno to ana:equipo
$ sudo chown -c ana o1 o2 o3
$ sudo chown -c beto o1
changed ownership of 'o1' from ana to beto
```

`-v` lo dice todo; `-c` solo lo que **cambia** (la segunda orden no cambia nada: ya eran `ana`).

### `--from`: cambiar solo "si procede"

```text
$ sudo chown --from=beto carla o1 o2
$ ls -l o1 o2
-rw-rw-r-- 1 carla equipo 0 Oct 16 17:08 o1
-rw-rw-r-- 1 ana   equipo 0 Oct 16 17:08 o2
```

`o1` era de `beto` → pasó a `carla`; `o2` era de `ana` → **no se tocó**. Útil para "reasignar lo que era de un compañero que se fue".

### `--reference`

```text
$ touch igual.txt
$ sudo chown --reference=o2 igual.txt
$ ls -l o2 igual.txt
-rw-rw-r-- 1 ana equipo 0 Oct 16 17:08 igual.txt
-rw-rw-r-- 1 ana equipo 0 Oct 16 17:08 o2
```

---

## 9.5 · `chown -R`: la bomba de relojería

Con `-R` cambias **toda la carpeta**: potente, pero **cuidado**:

```text
$ mkdir -p proyecto/src proyecto/docs
$ touch proyecto/src/a.c proyecto/docs/leeme.txt
$ sudo chown -R ana:equipo proyecto
$ find proyecto -exec ls -ld {} +
drwxrwxr-x 4 ana equipo 4096 Oct 16 17:08 proyecto
drwxrwxr-x 2 ana equipo 4096 Oct 16 17:08 proyecto/docs
-rw-rw-r-- 1 ana equipo    0 Oct 16 17:08 proyecto/docs/leeme.txt
drwxrwxr-x 2 ana equipo 4096 Oct 16 17:08 proyecto/src
-rw-rw-r-- 1 ana equipo    0 Oct 16 17:08 proyecto/src/a.c
```

Reglas de oro:

1. **Mira dónde estás** (`pwd`) y **a qué apuntas** antes de pulsar Intro con `-R`.
2. **Nunca** `chown -R usuario /` ni `chown -R usuario /etc` (rompe el sistema; `--preserve-root` evita lo de `/`).
3. **Cuidado con `chown -R usuario .*`**: en shells antiguas `.*` incluye `..` ¡y cambias la carpeta **padre** entera! (En la Bash de Ubuntu 24.04 ya no sucede; por si acaso, **no lo escribas**.)
4. Con enlaces simbólicos: por defecto `-R` **no sigue** los enlaces (opción `-P`). Con `-L` los seguiría: **no lo uses** salvo que sepas muy bien qué haces.

---

## 9.6 · `chown` y los bits especiales: se **borran**

Cambiar el dueño o el grupo de un fichero **quita los bits SUID/SGID** de un programa. Es una medida de seguridad: nadie debe heredar un "superprograma" sin darse cuenta.

```text
$ cp /usr/bin/id mi-id
$ chmod 4755 mi-id
$ ls -l mi-id
-rwsr-xr-x 1 alumno alumno 39432 Oct 16 17:08 mi-id
$ sudo chown ana mi-id
$ ls -l mi-id
-rwxr-xr-x 1 ana alumno 39432 Oct 16 17:08 mi-id
```

El `s` desapareció (`-rwsr-xr-x` → `-rwxr-xr-x`). Si lo quieres, hay que **volver a ponerlo después** con `chmod u+s` (ver capítulo 10): siempre **primero `chown`, luego `chmod`**.

---

## 9.7 · Casos reales (los que de verdad vas a vivir)

### 🔥 ① El fichero que se quedó de `root` por usar `sudo`

Cuando haces `sudo` + un comando que **crea** ficheros, los crea **`root`**. Y luego tú no puedes modificarlos:

```text
$ sudo cp datos/agenda.txt copia-root.txt
$ ls -l copia-root.txt
-rw-r--r-- 1 root root 56 Oct 16 17:08 copia-root.txt
$ echo "añado una línea" >> copia-root.txt
bash: copia-root.txt: Permission denied
$ sudo chown alumno: copia-root.txt
$ echo "ahora sí" >> copia-root.txt
$ ls -l copia-root.txt
-rw-r--r-- 1 alumno alumno 66 Oct 16 17:08 copia-root.txt
```

La solución: **`sudo chown tu-usuario: fichero`** (los dos puntos finales ponen también tu grupo). Para buscar todo lo que `root` dejó en tu carpeta personal: `find ~ -user root`.

### 🌐 ② Una carpeta web

El servidor web (Apache/Nginx) corre como el usuario **`www-data`**. Si sube ficheros, estos deben ser suyos:

```text
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} +
sudo find /var/www/html -type f -exec chmod 644 {} +
```

### 👥 ③ Una carpeta de equipo

```text
$ mkdir carpeta-equipo
$ sudo chown :equipo carpeta-equipo
$ chmod 770 carpeta-equipo
$ ls -ld carpeta-equipo
drwxrwx--- 2 alumno equipo 4096 Oct 16 17:08 carpeta-equipo
$ sudo -u ana touch carpeta-equipo/de-ana.txt
$ sudo -u beto touch carpeta-equipo/de-beto.txt
$ sudo -u carla touch carpeta-equipo/de-carla.txt
touch: cannot touch 'carpeta-equipo/de-carla.txt': Permission denied
$ ls -l carpeta-equipo
total 0
-rw-r--r-- 1 ana  ana  0 Oct 16 17:08 de-ana.txt
-rw-r--r-- 1 beto beto 0 Oct 16 17:08 de-beto.txt
```

Solo `ana` y `beto` (de `equipo`) pueden crear dentro (y tú, `alumno`, **eres el dueño**: entras por la parte del dueño). Fíjate en el **grupo de los ficheros nuevos**: `ana:ana` y `beto:beto`, **no** `equipo`. Esto es un problema: el resto del equipo no podrá editar lo que otro crea. Lo arregla el bit **SGID** del capítulo 10.

### 🔁 ④ Dejar un fichero a nombre de otro usuario

```text
$ echo "entregable" > para-ana.txt
$ chmod 600 para-ana.txt
$ sudo chown ana:ana para-ana.txt
$ ls -l para-ana.txt
-rw------- 1 ana ana 11 Oct 16 17:08 para-ana.txt
$ cat para-ana.txt
cat: para-ana.txt: Permission denied
$ sudo -u ana cat para-ana.txt
entregable
```

Con `600` y dueña `ana`, **solo ana** (y root) lo lee; **tú, que lo creaste, ya no**. Y recuerda (capítulo 4): ya **no puedes hacerle `chmod`** (no eres dueño).

---

## 9.8 · Resumen de comandos

| Quiero… | Comando |
|---|---|
| Ver dueño y grupo | `ls -l`, `stat -c '%U:%G %n' f` |
| Ver los **números** | `ls -ln`, `stat -c '%u:%g %n' f` |
| Cambiar el dueño | `sudo chown ana f` |
| Cambiar dueño y grupo | `sudo chown ana:equipo f` |
| Cambiar solo el grupo | `chgrp equipo f` (si eres de `equipo`) o `sudo chgrp …` |
| Recursivo | `sudo chown -R ana:equipo carpeta` |
| Cambiar solo lo que era de X | `sudo chown --from=beto carla *` |
| Que sea mío otra vez | `sudo chown "$USER": f` |
| Buscar lo que dejó `root` en mi carpeta | `find ~ -user root` |
| Buscar ficheros huérfanos | `sudo find / -nouser -o -nogroup 2>/dev/null` |

---

## 9.9 · 🏋️ Ejercicios

#### 🟢 Ejercicio 9.1 · Ver dueño y grupo

Muestra dueño y grupo de `datos/agenda.txt` con **dos** comandos distintos (uno con letras y otro con números).

<details>
<summary>💡 Ver solución</summary>

```text
$ ls -l datos/agenda.txt
-rw-r--r-- 1 alumno alumno 56 Oct 12 09:30 datos/agenda.txt
$ ls -ln datos/agenda.txt
-rw-r--r-- 1 1001 1001 56 Oct 12 09:30 datos/agenda.txt
$ stat -c '%U:%G  (%u:%g)' datos/agenda.txt
alumno:alumno  (1001:1001)
```
</details>

#### 🟢 Ejercicio 9.2 · Cambiar el dueño

Haz que `ana` sea la dueña de `e1.txt`. ¿Qué necesitas?

<details>
<summary>💡 Ver solución</summary>

```text
$ touch e1.txt
$ sudo chown ana e1.txt
$ ls -l e1.txt
-rw-rw-r-- 1 ana alumno 0 Oct 16 17:08 e1.txt
```

`sudo`: solo `root` puede cambiar el dueño.
</details>

#### 🟢 Ejercicio 9.3 · Dueño y grupo de golpe

Deja `e2.txt` como `beto:soporte` con una sola orden.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch e2.txt
$ sudo chown beto:soporte e2.txt
$ ls -l e2.txt
-rw-rw-r-- 1 beto soporte 0 Oct 16 17:08 e2.txt
```
</details>

#### 🟡 Ejercicio 9.4 · Solo el grupo

Cambia únicamente el grupo de `e1.txt` a `equipo` de **dos formas** distintas.

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo chgrp equipo e1.txt
$ ls -l e1.txt
-rw-rw-r-- 1 ana equipo 0 Oct 16 17:08 e1.txt
$ sudo chown :soporte e1.txt
$ ls -l e1.txt
-rw-rw-r-- 1 ana soporte 0 Oct 16 17:08 e1.txt
```

`chgrp g f` ≡ `chown :g f`.
</details>

#### 🟡 Ejercicio 9.5 · ¿Puede el dueño regalar?

Tú eres el dueño de `e3.txt`. Intenta ponerle como dueña a `ana` **sin** `sudo`. ¿Qué pasa y por qué?

<details>
<summary>💡 Ver solución</summary>

```text
$ touch e3.txt
$ chown ana e3.txt
chown: changing ownership of 'e3.txt': Operation not permitted
```

`Operation not permitted`: **solo `root` puede cambiar el dueño**. Es una regla del sistema, no un fallo de permisos del fichero.
</details>

#### 🟡 Ejercicio 9.6 · Un grupo que no es tuyo

`ana` es dueña de `e4.txt`. ¿Puede cambiarle el grupo a `equipo`? ¿Y a `soporte`?

<details>
<summary>💡 Ver solución</summary>

```text
$ touch e4.txt
$ sudo chown ana e4.txt
$ sudo -u ana chgrp equipo e4.txt
$ ls -l e4.txt
-rw-rw-r-- 1 ana equipo 0 Oct 16 17:08 e4.txt
$ sudo -u ana chgrp soporte e4.txt
chgrp: changing group of 'e4.txt': Operation not permitted
```

A `equipo` sí (es miembro); a `soporte` no.
</details>

#### 🟡 Ejercicio 9.7 · Recuperar lo que es tuyo

Tienes `copia2.txt` creado con `sudo` (dueño `root`). Hazlo tuyo otra vez.

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo touch copia2.txt
$ ls -l copia2.txt
-rw-r--r-- 1 root root 0 Oct 16 17:08 copia2.txt
$ sudo chown "$USER": copia2.txt
$ ls -l copia2.txt
-rw-r--r-- 1 alumno alumno 0 Oct 16 17:08 copia2.txt
```

`$USER` vale `alumno`; los dos puntos finales ponen también tu grupo.
</details>

#### 🔴 Ejercicio 9.8 · Reasignar con `--from`

Tienes `r1`, `r2`, `r3`: `r1` y `r3` de `beto` y `r2` de `ana`. Pasa **solo los de `beto`** a `carla`.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch r1 r2 r3
$ sudo chown beto r1 r3
$ sudo chown ana r2
$ sudo chown --from=beto carla r1 r2 r3
$ ls -l r1 r2 r3
-rw-rw-r-- 1 carla alumno 0 Oct 16 17:08 r1
-rw-rw-r-- 1 ana   alumno 0 Oct 16 17:08 r2
-rw-rw-r-- 1 carla alumno 0 Oct 16 17:08 r3
```
</details>

#### 🔴 Ejercicio 9.9 · Primero `chown`, luego `chmod`

Quieres un programa `miprog` **SUID** de `root`. ¿Por qué debes hacer `chown` **antes** que `chmod u+s`?

<details>
<summary>💡 Ver solución</summary>

```text
$ cp /usr/bin/id miprog-mal
$ chmod u+s miprog-mal
$ sudo chown root miprog-mal
$ ls -l miprog-mal
-rwxr-xr-x 1 root alumno 39432 Oct 16 17:08 miprog-mal
$ cp /usr/bin/id miprog-bien
$ sudo chown root miprog-bien
$ sudo chmod u+s miprog-bien
$ ls -l miprog-bien
-rwsr-xr-x 1 root alumno 39432 Oct 16 17:08 miprog-bien
```

En `miprog-mal` se puso el SUID **y luego** se hizo el `chown`: el `chown` **borró el SUID** (`-rwxr-xr-x`). En `miprog-bien` se hizo primero el `chown` y después el `chmod`: el `s` se queda.
</details>

#### 🔴 Ejercicio 9.10 · Reparar una carpeta

Tienes `reparar/` con ficheros, todo de `root` por culpa de un `sudo`. Devuélvelo **a ti** de un solo comando.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir -p reparar/sub
$ sudo touch reparar/a reparar/sub/b
$ find reparar -exec ls -ld {} +
drwxrwxr-x 3 alumno alumno 4096 Oct 16 17:08 reparar
-rw-r--r-- 1 root   root      0 Oct 16 17:08 reparar/a
drwxrwxr-x 2 alumno alumno 4096 Oct 16 17:08 reparar/sub
-rw-r--r-- 1 root   root      0 Oct 16 17:08 reparar/sub/b
$ sudo chown -R "$USER": reparar
$ find reparar -exec ls -ld {} +
drwxrwxr-x 3 alumno alumno 4096 Oct 16 17:08 reparar
-rw-r--r-- 1 alumno alumno    0 Oct 16 17:08 reparar/a
drwxrwxr-x 2 alumno alumno 4096 Oct 16 17:08 reparar/sub
-rw-r--r-- 1 alumno alumno    0 Oct 16 17:08 reparar/sub/b
```
</details>

#### ⚫ Ejercicio 9.11 · Huérfanos

Crea un fichero con dueño `4242` (un UID que no existe). ¿Cómo lo ves en `ls -l`? ¿Cómo lo **encuentras** en un árbol?

<details>
<summary>💡 Ver solución</summary>

```text
$ touch huerfano.txt
$ sudo chown 4242:4242 huerfano.txt
$ ls -l huerfano.txt
-rw-rw-r-- 1 4242 4242 0 Oct 16 17:08 huerfano.txt
$ find . -nouser -o -nogroup
./huerfano.txt
./c5
```

`ls -l` enseña el número; `find -nouser -o -nogroup` lo encuentra. Es una **comprobación de auditoría** típica.
</details>

#### ⚫ Ejercicio 9.12 · Examen: el dueño y `chown`

*¿Quién puede cambiar el propietario de un fichero con `chown`?* a) Cualquier usuario con permiso de escritura b) Solo el propietario actual c) Solo `root` d) Cualquier miembro del grupo propietario

<details>
<summary>💡 Ver solución</summary>

**c) Solo `root`.**
</details>

#### ⚫ Ejercicio 9.13 · Examen: ¿qué hace `chown :web f`?

a) Cambia el dueño a `web` b) Cambia **solo el grupo** a `web` c) Es un error de sintaxis d) Cambia dueño y grupo a `web`

<details>
<summary>💡 Ver solución</summary>

**b)** Con `:grupo` sin usuario delante solo cambia el grupo (equivale a `chgrp web f`).
</details>

#### ⚫ Ejercicio 9.14 · Examen: `chown ana: f`

*¿Qué grupo queda en `f` tras `chown ana: f`?* a) El que tuviera b) `root` c) El grupo **principal de `ana`** d) Ninguno

<details>
<summary>💡 Ver solución</summary>

**c)**. Los dos puntos **sin grupo detrás** ponen el grupo de inicio de sesión del usuario (`ana:ana`).
</details>

---

⬅️ [Capítulo 8 · `umask`: por qué tus ficheros nuevos nacen con esos permisos](08-umask.md) · [📚 Índice](README.md) · [Capítulo 10 · Permisos especiales: SUID, SGID y *sticky* (`s`, `S`, `t`, `T`, `4755`, `2775`, `1777`)](10-permisos-especiales.md) ➡️
