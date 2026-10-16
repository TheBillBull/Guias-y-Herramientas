# Capítulo 8 · `umask`: por qué tus ficheros nuevos nacen con esos permisos

> 🎯 **Objetivo:** entender **de dónde salen** los permisos de un fichero recién creado (`-rw-rw-r--`, `-rw-r--r--`…), saber **calcular** una `umask` en un segundo, evitar la **trampa de la resta**, cambiarla de forma temporal y permanente y saber **qué comandos la obedecen y cuáles no**.
>
> 📘 **LPIC-1:** 104.5 (`umask`, permisos por defecto de ficheros nuevos).
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`.

---

## 8.1 · La pregunta del millón

¿Por qué cuando haces `touch nuevo.txt` sale `-rw-rw-r--`, y cuando haces `mkdir nueva` sale `drwxrwxr-x`? Nadie te preguntó qué permisos querías. **Los decide la `umask`.**

```text
$ cd ~/lab-permisos
$ touch nuevo.txt
$ mkdir nueva
$ ls -ld nuevo.txt nueva
drwxrwxr-x 2 alumno alumno 4096 Oct 16 17:09 nueva
-rw-rw-r-- 1 alumno alumno    0 Oct 16 17:09 nuevo.txt
$ umask
0002
```

La idea, en una imagen:

> 🧱 **Los programas piden los permisos "máximos"** (`666` para un fichero, `777` para una carpeta) y **la `umask` es una plantilla de lo que NO se les concede**: ella **apaga** bits.

```text
                  FICHERO                     CARPETA
pide el programa:  666  rw-rw-rw-              777  rwxrwxrwx
umask (0002):      002  -------w-              002  -------w-      ← "estos NO"
                  ─────────────                ─────────────
resultado:         664  rw-rw-r--              775  rwxrwxr-x
```

- **¿Por qué 666 y no 777 para los ficheros?** Por **seguridad**: un fichero **nuevo nunca nace ejecutable**. Si quieres que lo sea, tienes que pedirlo tú con `chmod +x`. Así evitas que un fichero descargado o creado por error se pueda lanzar sin querer. (Por eso `hola.sh` no funcionaba en el capítulo 2.)
- **¿Y las carpetas?** Necesitan la `x` para poder entrar, así que parten de `777`.

---

## 8.2 · Ver la `umask`

```text
$ umask
0002
$ umask -S
u=rwx,g=rwx,o=rx
```

| Comando | Qué muestra |
|---|---|
| `umask` | la máscara en **octal** (4 cifras): `0002` = lo que **se quita** |
| `umask -S` | lo contrario, en **letras**: `u=rwx,g=rwx,o=rx` = lo que **se concede** |

Cuidado con la **inversión**: `umask` te enseña lo que **se apaga**; `umask -S` lo que **queda permitido** (para carpetas). Son *complementarios*. Con `0002`: se apaga la `w` de otros → `umask -S` dice que **otros** pueden `r-x`.

> 💡 La primera cifra de `0002` (el cero) corresponde a los bits especiales y casi siempre es `0`. Las tres siguientes son **dueño, grupo, otros**, como en `chmod`.

---

## 8.3 · El cálculo: `permisos = base & ~umask`

La fórmula exacta (y la única que siempre funciona) es:

```text
permisos nuevos  =  permisos pedidos  Y  (NO umask)
                  =  666 & ~umask    (ficheros)
                  =  777 & ~umask    (carpetas)
```

Es el **Y NO** (`& ~`) que vimos en el capítulo 7: "enciende solo los bits que el programa pide **y** que la umask no bloquea". Verlo con números:

```text
umask 027  →  bits que se APAGAN:   ---  -w-  rwx
carpeta  777 =  rwx  rwx  rwx
                 │    │    │
                 ▼    ▼    ▼
             quita ---  -w-  rwx     →   rwx  r-x  ---   =  750
fichero  666 =  rw-  rw-  rw-
             quita ---  -w-  rwx     →   rw-  r--  ---   =  640
```

La tabla de las `umask` que debes conocer (calculada por un programa, así que sin erratas):

| `umask` | Ficheros nuevos (666 & ~umask) | Carpetas nuevas (777 & ~umask) | Uso típico |
|:-:|:-:|:-:|---|
| `0000` | `666` `rw-rw-rw-` | `777` `rwxrwxrwx` | nada se quita (¡peligroso!) |
| `0002` | `664` `rw-rw-r--` | `775` `rwxrwxr-x` | **Ubuntu** para usuarios normales (grupo escribe) |
| `0007` | `660` `rw-rw----` | `770` `rwxrwx---` | equipo cerrado: otros no ven nada, el grupo trabaja |
| `0022` | `644` `rw-r--r--` | `755` `rwxr-xr-x` | **clásica**: `root`, Debian, casi todo (grupo y otros solo leen) |
| `0027` | `640` `rw-r-----` | `750` `rwxr-x---` | servidores: grupo lee, otros nada |
| `0037` | `640` `rw-r-----` | `740` `rwxr-----` | grupo solo lee (sin `x`), otros nada |
| `0077` | `600` `rw-------` | `700` `rwx------` | **privado**: solo el dueño |
| `0222` | `444` `r--r--r--` | `555` `r-xr-xr-x` | ficheros y carpetas "de solo lectura" al nacer |

Y la comprobamos **con el sistema** (en subshells `( … )`, para no cambiar tu `umask` real):

```text
$ oct() { printf '%03o' "0$(stat -c %a "$1")"; }
$ for u in 000 002 022 027 077 007; do
  ( umask $u; rm -rf pf pd; touch pf; mkdir pd
    echo "umask $u → fichero $(oct pf)  carpeta $(oct pd)" )
done
umask 000 → fichero 666  carpeta 777
umask 002 → fichero 664  carpeta 775
umask 022 → fichero 644  carpeta 755
umask 027 → fichero 640  carpeta 750
umask 077 → fichero 600  carpeta 700
umask 007 → fichero 660  carpeta 770
$ rm -rf pf pd
```

---

## 8.4 · ⚠️ La trampa: la umask **no** es una resta

Casi todo el mundo aprende *"restas la umask de 666 (o de 777)"*. Y casi siempre funciona (con `022`, `002`, `027`, `077`), **pero no siempre**. Mira:

| `umask` | Resta "de cabeza" (666 − umask) | **Real** (666 & ~umask) | ¿Coincide? |
|:-:|:-:|:-:|:-:|
| `022` | `644` | `644` | ✅ |
| `002` | `664` | `664` | ✅ |
| `027` | `640` | `640` | ✅ |
| `077` | `600` | `600` | ✅ |
| `011` | `655` | `666` | ❌ **¡no!** |
| `033` | `633` | `644` | ❌ **¡no!** |
| `013` | `653` | `664` | ❌ **¡no!** |
| `035` | `631` | `642` | ❌ **¡no!** |
| `055` | `611` | `622` | ❌ **¡no!** |
| `101` | `565` | `666` | ❌ **¡no!** |

¿Por qué falla? Porque los ficheros parten de `666`, que **no tiene `x`** (el bit `1`). Si la `umask` apaga un bit que **ya estaba apagado**, no pasa nada: no se puede quitar lo que no existe. Pero una **resta** sí "quita" un 1, y falsea el resultado. Prueba: `umask 011` apaga las `x`; los ficheros ya no tenían `x`, así que quedan **`666`**, no `655`.

> 🎓 **Regla segura para ficheros, sin fórmulas:** **calcula como si fuera una carpeta** (`7 − cifra`) **y después quítale la `x`** a todo lo que haya salido (7 → 6, 5 → 4, 3 → 2, 1 → 0).
>
> ```text
> umask 033  →  carpeta: 7-0, 7-3, 7-3 = 744  →  ficheros: 644 ✔
> umask 027  →  carpeta: 750                  →  ficheros: 640 ✔
> umask 011  →  carpeta: 766                  →  ficheros: 666 ✔
> ```

Y con **la herramienta** lo ves y se avisa de la trampa (la calculadora visual `herramientas/calculadora-chmod.html` también tiene una sección de `umask`, con el mismo aviso):

```text
$ permisos -u 033
umask 0033

  Ficheros nuevos    666 & ~033 = 644   rw-r--r--
  Carpetas nuevas    777 & ~033 = 744   rwxr--r--

  ⚠  Restar 666 − 033 cifra a cifra daría 633, pero el resultado real es 644.
     La umask es una MÁSCARA (se apagan bits), no una resta.
$ permisos -u 022
umask 0022

  Ficheros nuevos    666 & ~022 = 644   rw-r--r--
  Carpetas nuevas    777 & ~022 = 755   rwxr-xr-x
```

---

## 8.5 · Cambiar la `umask`

### 🔹 Solo para **esta terminal**

```text
$ umask
0002
$ umask 077
$ umask
0077
$ touch secreto-nuevo.txt
$ mkdir carpeta-nueva
$ stat -c '%a %A %n' secreto-nuevo.txt carpeta-nueva
600 -rw------- secreto-nuevo.txt
700 drwx------ carpeta-nueva
$ umask 002
```

Con `umask 077` los ficheros nacen `600` y las carpetas `700`. El cambio afecta **a esa shell y a los procesos que lance** (los hijos la **heredan**), y se pierde al cerrar la terminal. (Aquí hemos vuelto a `002` al final.)

### 🔹 Solo para **un comando o un grupo de comandos**: subshell

```text
$ umask
0002
$ ( umask 077; touch dentro.txt; stat -c '%a %n' dentro.txt )
600 dentro.txt
$ umask
0002
$ touch fuera.txt
$ stat -c '%a %n' fuera.txt
664 fuera.txt
```

Dentro de `( … )` la `umask` es `077`; fuera sigue como estaba. **No hay forma de que un hijo cambie la `umask` del padre** (igual que no puedes cambiar el `cd` de otro con un script).

### 🔹 Para **siempre**: ¿dónde se configura?

| Dónde | Efecto |
|---|---|
| **`~/.bashrc`** o **`~/.profile`** (`umask 027`) | solo **tú**, en tus terminales |
| **`/etc/profile`**, **`/etc/bash.bashrc`** | **todos** los usuarios que usen bash |
| **`/etc/login.defs`** (`UMASK 022`) | valor por defecto del sistema (lo usa `pam_umask`) |
| **`/etc/pam.d/common-session`** (`session optional pam_umask.so`) | aplica `login.defs` al iniciar sesión |
| **systemd** (`UMask=0027` en el `.service`) | para un **servicio** concreto |

Echemos un vistazo a **tu Ubuntu**:

```text
$ grep -n -E '^(UMASK|USERGROUPS_ENAB)' /etc/login.defs
151:UMASK		022
238:USERGROUPS_ENAB yes
$ grep -n pam_umask /etc/pam.d/common-session
22:# The pam_umask module will set the umask according to the system default in
25:# See "man pam_umask".
26:session optional			pam_umask.so
$ grep -n umask ~/.profile
7:# the default umask is set in /etc/profile; for setting the umask
8:# for ssh logins, install and configure the libpam-umask package.
9:#umask 022
```

### 🐧 El misterio de Ubuntu: ¿por qué `0002` si `login.defs` dice `022`?

Porque `login.defs` también dice **`USERGROUPS_ENAB yes`**. Con esa opción, `pam_umask` hace un truco: **si tu grupo privado se llama igual que tú** (y el UID es igual que el GID, como `alumno:alumno`), copia los bits del **dueño** al **grupo**: `022` → `002`. Se hace porque, al tener **cada usuario su grupo propio** (UPG), dar escritura al grupo no arriesga nada (¡el grupo solo eres tú!).

| Usuario | Grupo principal | `umask` resultante |
|---|---|:-:|
| `alumno` (grupo privado `alumno`) | `alumno` | **`0002`** → ficheros `664` |
| `root` | `root` | `0022` → ficheros `644` |
| usuario de un grupo compartido (`ana` con grupo `users`) | `users` | `0022` |

Esa es la razón de que tu `cerve.sh` tenga `-rwxrwxr-x` (creado `664`, luego `chmod +x`), y los demás ficheros del sistema, `-rw-r--r--`.

### 🔹 ¿Y `sudo`? Siempre al menos `022`

```text
$ umask
0002
$ sudo sh -c umask
0022
$ sudo -u ana sh -c umask
0022
```

`sudo` ejecuta con `umask 0022` (el valor más restrictivo entre la tuya y la de `sudoers`), así que **los ficheros que crees con `sudo` serán `644`/`755`**, no `664`/`775`.

---

## 8.6 · ¿Qué comandos obedecen la `umask`? (y cuáles no)

| Comando | ¿La obedece? | Detalle |
|---|:-:|---|
| `touch f`, `> f`, `>> f` | ✅ | ficheros nuevos: `666 & ~umask` |
| `mkdir d` | ✅ | `777 & ~umask` |
| `cp origen destino` | ✅ | al crear el destino: `modo-del-origen & ~umask` |
| `cp -p` | ❌ | **conserva** el modo del origen |
| `mv` | ❌ | no crea nada: **mantiene** el modo |
| `mkdir -m 755 d` | ❌ | el modo explícito **manda** (no usa la umask) |
| `install -m 640 a b` | ❌ | el modo explícito manda |
| `chmod` | ❌ (salvo "sin quién", cap. 6) | el modo que pides es el que queda |
| `tar x` | ✅ / ❌ | aplica la umask salvo con `-p` (root lo hace por defecto) |
| editores (`nano f`) | ✅ | un fichero nuevo, sí; uno existente, mantiene su modo |

Lo comprobamos:

```text
$ ( umask 077
  cp saludos.sh copia-umask.sh
  cp -p saludos.sh copia-p.sh
  mkdir -m 755 d-explicita
  mkdir d-normal
  install -m 640 saludos.sh instalado.sh
  stat -c '%a %n' saludos.sh copia-umask.sh copia-p.sh d-explicita d-normal instalado.sh )
751 saludos.sh
700 copia-umask.sh
751 copia-p.sh
755 d-explicita
700 d-normal
640 instalado.sh
$ mv copia-p.sh movido.sh
$ stat -c '%a %n' movido.sh
751 movido.sh
```

- `saludos.sh` es `751`. Con `umask 077`: `cp` lo deja en **`700`** (751 sin lo de grupo/otros); `cp -p` **conserva `751`**; `mv` no toca nada.
- `mkdir -m 755` **ignora** la `umask` (sale `755`); `mkdir` a secas sale `700`.
- `install -m 640` pone exactamente `640`.

---

## 8.7 · `umask` y seguridad

**Para trabajar con cosas sensibles**, pon `umask 077` **antes** de crear los ficheros. Es mejor que crearlos y luego hacer `chmod 600`, porque entre una orden y otra **hay un instante en que el fichero es legible** (una *condición de carrera*). Con la `umask` bien puesta, **nace ya protegido**:

```text
$ cat > crea-secreto.sh <<'EOF'
#!/bin/bash
umask 077                      # a partir de aquí, todo lo que cree nace privado
echo "clave=supersecreta" > mis-claves.txt
mkdir copias-privadas
EOF
$ chmod +x crea-secreto.sh
$ ./crea-secreto.sh
$ stat -c '%a %A %n' mis-claves.txt copias-privadas
600 -rw------- mis-claves.txt
700 drwx------ copias-privadas
```

(El `umask` dentro del script **solo afecta a ese script**.)

> ⚠️ **La `umask` no protege ficheros ya existentes** y tampoco los copiados con `cp -p` ni los extraídos de un `tar` con `-p`: ahí mandan los permisos del origen.

---

## 8.8 · 🏋️ Ejercicios

#### 🟢 Ejercicio 8.1 · Tu `umask`

¿Qué `umask` tienes? ¿Qué permisos tienen tus ficheros nuevos y tus carpetas nuevas?

<details>
<summary>💡 Ver solución</summary>

```text
$ umask
0002
$ touch ej-um.txt
$ mkdir ej-um-dir
$ stat -c '%a %A %n' ej-um.txt ej-um-dir
664 -rw-rw-r-- ej-um.txt
775 drwxrwxr-x ej-um-dir
```

Con `0002`: ficheros `664`, carpetas `775`.
</details>

#### 🟢 Ejercicio 8.2 · Privado por defecto

Haz que **todo lo que crees a partir de ahora, en un subshell**, sea privado (solo tú).

<details>
<summary>💡 Ver solución</summary>

```text
$ ( umask 077; touch priv.txt; mkdir priv-dir; stat -c '%a %n' priv.txt priv-dir )
600 priv.txt
700 priv-dir
```
</details>

#### 🟢 Ejercicio 8.3 · Calcular con la fórmula

Con `umask 027`, ¿qué permisos tendrán un fichero y una carpeta nuevos?

<details>
<summary>💡 Ver solución</summary>

Carpeta: `7−0, 7−2, 7−7` → **750**. Fichero (quitando la `x`): **640**.

```text
$ permisos -u 027 | grep -E 'Ficheros|Carpetas'
  Ficheros nuevos    666 & ~027 = 640   rw-r-----
  Carpetas nuevas    777 & ~027 = 750   rwxr-x---
```
</details>

#### 🟡 Ejercicio 8.4 · Hacia atrás

Quieres que los **ficheros nuevos** nazcan `640` y las **carpetas** `750`. ¿Qué `umask`?

<details>
<summary>💡 Ver solución</summary>

La umask es **lo que se apaga**: para las carpetas, `777 − 750 = 027`. **`umask 027`**. Comprobación:

```text
$ ( umask 027; touch u1; mkdir u2; stat -c '%a %n' u1 u2 )
640 u1
750 u2
```
</details>

#### 🟡 Ejercicio 8.5 · Equipo

Para un equipo que **comparte** una carpeta, ¿qué `umask` conviene: `022` o `002`? ¿Por qué?

<details>
<summary>💡 Ver solución</summary>

**`002`**. Con ella, lo que cada uno crea sale **`664`/`775`**: el **grupo** puede escribir. Con `022`, los compañeros solo podrían leer y nadie más podría modificar tus ficheros. (Y se combina con la carpeta **SGID**, capítulo 10, para que además hereden el grupo.)
</details>

#### 🟡 Ejercicio 8.6 · `cp` frente a `cp -p`

Con `umask 077`, copia `salario.sh` (`775`) con `cp` y con `cp -p`. ¿Qué modos salen?

<details>
<summary>💡 Ver solución</summary>

```text
$ ( umask 077
  cp salario.sh s1.sh
  cp -p salario.sh s2.sh
  stat -c '%a %n' salario.sh s1.sh s2.sh )
775 salario.sh
700 s1.sh
775 s2.sh
```

`cp` aplica la umask al modo del origen: `775 & ~077 = 700`. `cp -p` **conserva** `775`.
</details>

#### 🟡 Ejercicio 8.7 · Los ficheros nunca nacen ejecutables

Con `umask 000` (¡la más permisiva!), ¿un fichero nuevo sale `777`?

<details>
<summary>💡 Ver solución</summary>

```text
$ ( umask 000; touch ej0; mkdir ej0d; stat -c '%a %A %n' ej0 ej0d )
666 -rw-rw-rw- ej0
777 drwxrwxrwx ej0d
```

**No**: sale `666`. Los programas piden `666` para ficheros; **la `x` no se concede nunca por defecto**, ni siquiera sin `umask`. La carpeta sí sale `777` (se pide `777`).
</details>

#### 🔴 Ejercicio 8.8 · La trampa de la resta

Con `umask 033`, ¿qué permisos tendrá un fichero nuevo? ¿Y por qué **no** es `633`?

<details>
<summary>💡 Ver solución</summary>

```text
$ ( umask 033; touch tr1; stat -c '%a' tr1 )
644
```

**644**. La resta daría `633`, pero `666 & ~033`: en las cifras de grupo y otros, `6 = rw-` y la umask `3 = -wx` apaga **la `w`** (y la `x`, que ya estaba apagada): quedan `r--` → `4`. Restar `6−3` da `3 = -wx`, que ¡ni existe en el fichero!
</details>

#### 🔴 Ejercicio 8.9 · ¿Qué `umask` da carpetas `700` y ficheros `600`?

<details>
<summary>💡 Ver solución</summary>

**`077`**. Carpetas: `777 − 077 = 700`; ficheros: `600`. (La más usada para trabajar en privado.)
</details>

#### 🔴 Ejercicio 8.10 · Un script seguro

Escribe un script que cree un fichero `datos-sensibles.csv` **que nunca sea legible por otros**, ni siquiera un instante.

<details>
<summary>💡 Ver solución</summary>

```text
$ cat > seguro.sh <<'EOF'
#!/bin/bash
umask 077
echo "id;valor" > datos-sensibles.csv
EOF
$ chmod +x seguro.sh
$ ./seguro.sh
$ stat -c '%a %A %n' datos-sensibles.csv
600 -rw------- datos-sensibles.csv
```

El `umask 077` va **antes** de crear el fichero, así que nace `600` (no hay "ventana" entre `touch` y `chmod`).
</details>

#### 🔴 Ejercicio 8.11 · El `sudo` y los 644

Si ejecutas `sudo touch f`, ¿qué permisos tiene `f`? ¿Por qué no `664`?

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo touch por-sudo.txt
$ stat -c '%a %A %U:%G %n' por-sudo.txt
644 -rw-r--r-- root:root por-sudo.txt
```

`644`, y es de `root`: `sudo` pone su `umask 0022`, que es **más restrictiva** que tu `0002` y prevalece.
</details>

#### ⚫ Ejercicio 8.12 · ¿Quién obedece?

De `touch`, `cp`, `cp -p`, `mv`, `mkdir -m 700`, `install -m 600`: ¿cuáles **respetan** la `umask` y cuáles la **ignoran**?

<details>
<summary>💡 Ver solución</summary>

- **La respetan:** `touch`, `cp` (a secas), `mkdir` (a secas).
- **La ignoran:** `cp -p` (conserva el modo original), `mv` (no crea nada), `mkdir -m …` y `install -m …` (modo explícito).
</details>

#### ⚫ Ejercicio 8.13 · Entrenamiento de velocidad

**Umask → permisos de los ficheros y de las carpetas nuevas**

1. `umask 0022`
2. `umask 0002`
3. `umask 0077`
4. `umask 0027`
5. `umask 0007`
6. `umask 0037`
7. `umask 0033`
8. `umask 0011`
9. `umask 0026`
10. `umask 0222`

<details>
<summary>💡 Ver respuestas</summary>

1. `0022` → ficheros **644** (`rw-r--r--`) · carpetas **755** (`rwxr-xr-x`)
2. `0002` → ficheros **664** (`rw-rw-r--`) · carpetas **775** (`rwxrwxr-x`)
3. `0077` → ficheros **600** (`rw-------`) · carpetas **700** (`rwx------`)
4. `0027` → ficheros **640** (`rw-r-----`) · carpetas **750** (`rwxr-x---`)
5. `0007` → ficheros **660** (`rw-rw----`) · carpetas **770** (`rwxrwx---`)
6. `0037` → ficheros **640** (`rw-r-----`) · carpetas **740** (`rwxr-----`)
7. `0033` → ficheros **644** (`rw-r--r--`) · carpetas **744** (`rwxr--r--`)
8. `0011` → ficheros **666** (`rw-rw-rw-`) · carpetas **766** (`rwxrw-rw-`)
9. `0026` → ficheros **640** (`rw-r-----`) · carpetas **751** (`rwxr-x--x`)
10. `0222` → ficheros **444** (`r--r--r--`) · carpetas **555** (`r-xr-xr-x`)

</details>

#### ⚫ Ejercicio 8.14 · Entrenamiento: hacia atrás

**Quiero estos permisos → ¿qué `umask`?**

1. ficheros **640** y carpetas **750**
2. ficheros **600** y carpetas **700**
3. ficheros **664** y carpetas **775**
4. ficheros **660** y carpetas **770**
5. ficheros **644** y carpetas **755**
6. ficheros **666** y carpetas **777**
7. ficheros **444** y carpetas **555**
8. ficheros **640** y carpetas **751**

<details>
<summary>💡 Ver respuestas</summary>

1. ficheros 640 / carpetas 750 → **`umask 027`**
2. ficheros 600 / carpetas 700 → **`umask 077`**
3. ficheros 664 / carpetas 775 → **`umask 002`**
4. ficheros 660 / carpetas 770 → **`umask 007`**
5. ficheros 644 / carpetas 755 → **`umask 022`**
6. ficheros 666 / carpetas 777 → **`umask 000`**
7. ficheros 444 / carpetas 555 → **`umask 222`**
8. ficheros 640 / carpetas 751 → **`umask 026`**

</details>

(Hay **varias** `umask` válidas para un mismo resultado en ficheros: lo que cuenta es la que sirva también para las **carpetas**.)

#### ⚫ Ejercicio 8.15 · Examen: la `umask` y el nuevo fichero

*Con `umask 0027`, ¿qué permisos tendrá un fichero nuevo creado con `touch`?* a) `rw-r-----` b) `rwxr-x---` c) `rw-r--r--` d) `rwx------`

<details>
<summary>💡 Ver solución</summary>

**a) `rw-r-----` (640).** `666 & ~027`. (b) sería una carpeta; los ficheros nuevos nunca llevan `x`.
</details>

#### ⚫ Ejercicio 8.16 · Examen: la `umask` de un usuario normal

*Un usuario ejecuta `umask 077` y después `mkdir secreto`. ¿Qué permisos tiene `secreto`?* a) `drwx------` b) `drwxr-xr-x` c) `drwxrwxrwx` d) `d---------`

<details>
<summary>💡 Ver solución</summary>

**a) `drwx------` (700).**
</details>

---

⬅️ [Capítulo 7 · `chmod` en modo octal: `755`, `644`, `4755`… y cómo aplicarlos a un árbol](07-chmod-octal.md) · [📚 Índice](README.md) · [Capítulo 9 · `chown` y `chgrp`: cambiar el dueño y el grupo](09-chown-chgrp.md) ➡️
