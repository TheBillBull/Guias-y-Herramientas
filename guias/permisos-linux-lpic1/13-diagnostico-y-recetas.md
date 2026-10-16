# Capítulo 13 · Diagnóstico: "¡Permission denied!" y qué hacer · Recetas

> 🎯 **Objetivo:** ante un fallo de permisos, **no adivinar ni tirar de `chmod 777`**, sino **diagnosticar con método**: leer bien el mensaje, localizar **qué elemento exacto** bloquea (`namei`, `diagnostica`, `strace`) y arreglarlo con **el cambio mínimo**. Más un **recetario** de situaciones típicas.
>
> 📘 **LPIC-1:** 104.5 · 110.1 · 103.1 (leer errores).
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`. Instala las herramientas de la guía si no lo hiciste ([capítulo 5](05-octal-binario-decimal.md)): esta vez también necesitamos **`diagnostica`**.

---

## 13.1 · Primero, **lee el mensaje**: no todos los errores son "permisos"

Casi la mitad de los "problemas de permisos" **no** son de permisos. El texto del error te dice casi siempre por dónde ir:

| Mensaje (inglés / español) | Qué significa | Primera comprobación |
|---|---|---|
| **`Permission denied`** / *Permiso denegado* | te **falta un permiso** (rwx), en el fichero o en el camino; o `noexec`/MAC | `ls -ld`, `namei -l`, `id` |
| **`Operation not permitted`** / *Operación no permitida* | acción **reservada** (no es cuestión de rwx): `chown` sin ser root, `chmod` sin ser dueño, **sticky**, **inmutable** | ¿soy dueño/root? `lsattr` |
| **`No such file or directory`** / *No existe el fichero…* | la **ruta no existe**… o es un enlace roto… o el **intérprete** del *shebang* no existe | `ls`, `readlink -f`, `head -1 script` |
| **`command not found`** / *orden no encontrada* | no está en el `PATH` (¡no es de permisos!) | `echo $PATH`, `./script` |
| **`Is a directory`** | intentas leer/ejecutar una carpeta como un fichero | `ls -ld` |
| **`Not a directory`** | usas un fichero como si fuera carpeta (`cat f/x`) | `ls -ld` |
| **`Read-only file system`** | la partición está **montada `ro`** | `findmnt -T ruta` |
| **`Text file busy`** | intentas **escribir sobre un programa que se está ejecutando** | `fuser`, `lsof` |
| **`cannot execute: required file not found`** (bash 5.2, Ubuntu 24.04) o **`bad interpreter`** (bash antiguos) | la primera línea (`#!`) apunta a un programa que no existe (o lleva un `\r` de Windows) | `head -1 script \| cat -A` |
| **`cannot execute binary file: Exec format error`** | no es un ejecutable válido (o es de otra arquitectura) | `file fichero` |

Las **dos primeras** son las que importan para esta guía y se confunden mucho:

> 🔑 **`Permission denied` = "te falta un permiso"** (se arregla dándolo).
> **`Operation not permitted` = "esto no se puede hacer así, ni con permisos"** (hay que ser otro usuario o quitar una protección).

### Demostraciones de los que **no son** de permisos

```text
$ printf '#!/bin/bash\necho hola\n' > ok.sh
$ chmod +x ok.sh
$ ok.sh
bash: ok.sh: command not found
$ ./ok.sh
hola
$ ./datos
bash: ./datos: Is a directory
$ cat cerve.sh/x
cat: cerve.sh/x: Not a directory
$ cd cerve.sh
bash: cd: cerve.sh: Not a directory
```

- `ok.sh` a secas → **`command not found`**: el script **no** está en el `PATH` (el directorio actual no está). Con `./ok.sh` sí.
- `./datos` → **`Is a directory`**.
- `cat cerve.sh/x` y `cd cerve.sh` → **`Not a directory`** (`cerve.sh` es un fichero).

```text
$ printf '#!/bin/noexiste\necho hola\n' > malo.sh
$ chmod +x malo.sh
$ ./malo.sh
bash: ./malo.sh: cannot execute: required file not found
$ printf '#!/bin/bash\r\necho hola\r\n' > windows.sh
$ chmod +x windows.sh
$ ./windows.sh
bash: ./windows.sh: cannot execute: required file not found
$ printf 'MZ\000\001' > falso.bin
$ chmod +x falso.bin
$ ./falso.bin
bash: ./falso.bin: cannot execute binary file: Exec format error
```

- `malo.sh` → **`cannot execute: required file not found`** (en Ubuntu 22.04 o anteriores verías `/bin/noexiste: bad interpreter: No such file or directory`): el fichero **sí existe**, pero **el programa de la primera línea** no.
- `windows.sh` → el **mismo error**: el script se guardó con finales de línea de Windows (`\r\n`) y el intérprete que se busca es `/bin/bash^M` (`^M` = el `\r` invisible). Solución: `sed -i 's/\r$//' windows.sh` (o `dos2unix`). Para verlo: `head -1 windows.sh | cat -A`.
- `falso.bin` → **`Exec format error`**: tiene `x`, pero su contenido no es un ejecutable.

> 🎓 Si el error **no** es de permisos, **cambiar permisos no lo arreglará**. Y *"el script existe pero dice que no existe"* casi siempre es el *shebang* o el `\r` de Windows.

---

## 13.2 · 🧭 El método de 7 pasos

Cuando algo falla con `Permission denied`, sigue **siempre** este orden (es el mapa del [capítulo 12](12-mas-alla-de-rwx.md)):

| # | Pregunta | Herramienta |
|:-:|---|---|
| **1** | ¿**Qué dice exactamente** el error y **sobre qué ruta**? | leer el mensaje completo |
| **2** | ¿**Quién soy** (o quién es el proceso)? ¿qué **grupos** tengo? | `id`, `id usuario` |
| **3** | ¿Puedo **llegar** (x en **todas** las carpetas del camino)? | **`namei -l ruta`** |
| **4** | ¿Qué **permisos, dueño y grupo** tiene el objeto? | `ls -ld ruta`, `stat ruta` |
| **5** | ¿**Qué trozo** me toca (dueño / grupo / otros) y qué le falta? | el algoritmo del capítulo 4 → **`diagnostica`** |
| **6** | ¿Hay algo **por encima**? ACL, atributos, `noexec/ro`, capacidades, AppArmor/SELinux | `getfacl`, `lsattr`, `findmnt -T`, `getcap`, `aa-status` |
| **7** | **Arreglar con el cambio mínimo**: un `chmod` concreto, un `chgrp`, una ACL… **¡nunca `777`!** | `chmod`, `chgrp`, `usermod -aG` + volver a entrar |

---

## 13.3 · 🛠️ Las herramientas

### `namei -l`: ¿en qué tramo se cae?

```text
$ namei -l /home/alumno/lab-permisos/datos/secreto.txt
f: /home/alumno/lab-permisos/datos/secreto.txt
drwxr-xr-x root   root   /
drwxr-xr-x root   root   home
drwxr-x--x alumno alumno alumno
drwxr-xr-x alumno alumno lab-permisos
drwxr-xr-x alumno alumno datos
-rw------- alumno alumno secreto.txt
```

Recorre **todos** los tramos y te enseña dueño, grupo y permisos de cada uno. Busca la carpeta que **no** deja pasar (te falta la `x`).

### `diagnostica`: el algoritmo del capítulo 4, tramo a tramo

La herramienta `diagnostica` (del directorio `herramientas/`) aplica la lógica exacta del sistema para un usuario y te dice **qué tramo bloquea**. (Se instala igual que `permisos`; se ejecuta con `sudo` para poder mirar carpetas de otros.)

```bash
sudo install -m 755 ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/herramientas/diagnostica /usr/local/bin/diagnostica
```

**Caso ①: `carla` quiere leer `secreto.txt`**

```text
$ sudo diagnostica -u carla /home/alumno/lab-permisos/datos/secreto.txt
Usuario: carla (uid 1004)   Grupos: carla soporte
Ruta:    /home/alumno/lab-permisos/datos/secreto.txt

  Tramo                                        Permisos    Dueño:Grupo     Aplica rwx  ¿Puede?
  /                                            drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home                                        drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home/alumno                                 drwxr-x--x  alumno:alumno    otros  --x  ✔ puede atravesarlo
  /home/alumno/lab-permisos                    drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/datos              drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/datos/secreto.txt  -rw-------  alumno:alumno    otros  ---  (el objeto final: ver abajo)

Camino libre hasta el objeto. Sobre /home/alumno/lab-permisos/datos/secreto.txt, carla puede:
   ✘ leer (r)
   ✘ escribir (w)
   ✘ ejecutar (x)

Sin avisos de ACL, atributos inmutables ni opciones de montaje restrictivas.
(Recuerda además el MAC —AppArmor/SELinux— y que los grupos nuevos exigen volver a iniciar sesión.)
```

Léelo: el **camino está libre** (cada carpeta le da la `x` a "otros"), pero el **objeto final** es `rw-------`: para `carla` ("otros") `---`: ✘ leer, ✘ escribir, ✘ ejecutar.

**Caso ②: ahora cerramos tu carpeta personal y `ana` prueba a leer un fichero que es legible por todos**

```text
$ chmod o-x ~
$ sudo diagnostica -u ana /home/alumno/lab-permisos/datos/agenda.txt
Usuario: ana (uid 1002)   Grupos: ana equipo
Ruta:    /home/alumno/lab-permisos/datos/agenda.txt

  Tramo                                       Permisos    Dueño:Grupo     Aplica rwx  ¿Puede?
  /                                           drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home                                       drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home/alumno                                drwxr-x---  alumno:alumno    otros  ---  ✘ FALTA x para atravesarlo
  /home/alumno/lab-permisos                   drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/datos             drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/datos/agenda.txt  -rw-r--r--  alumno:alumno    otros  r--  (el objeto final: ver abajo)

✘ BLOQUEO en: /home/alumno  (otros: ---)
  Sin poder atravesar ese tramo, ana no llega al objeto: NO puede hacer nada con él.
  Remedio: dar la x que falta en esa carpeta (chmod o+x / g+x, o añadir al usuario al grupo).

Sin avisos de ACL, atributos inmutables ni opciones de montaje restrictivas.
(Recuerda además el MAC —AppArmor/SELinux— y que los grupos nuevos exigen volver a iniciar sesión.)
$ chmod o+x ~
```

El fichero es `644`, ¡pero `ana` no puede leerlo! La herramienta señala el **bloqueo**: la carpeta `/home/alumno` (`drwxr-x---`): a "otros" **les falta la `x`**. Esto es el *"he puesto 644 y no se lee"* del 90 % de los casos reales. (Y ya hemos devuelto el `o+x`.)

**Caso ③: un usuario del grupo**

```text
$ echo "informe" > datos/equipo.txt
$ sudo chgrp equipo datos/equipo.txt
$ chmod 640 datos/equipo.txt
$ sudo diagnostica -u beto datos/equipo.txt
Usuario: beto (uid 1003)   Grupos: beto equipo soporte
Ruta:    /home/alumno/lab-permisos/datos/equipo.txt

  Tramo                                       Permisos    Dueño:Grupo     Aplica rwx  ¿Puede?
  /                                           drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home                                       drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home/alumno                                drwxr-x--x  alumno:alumno    otros  --x  ✔ puede atravesarlo
  /home/alumno/lab-permisos                   drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/datos             drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/datos/equipo.txt  -rw-r-----  alumno:equipo    grupo  r--  (el objeto final: ver abajo)

Camino libre hasta el objeto. Sobre /home/alumno/lab-permisos/datos/equipo.txt, beto puede:
   ✔ leer (r)
   ✘ escribir (w)
   ✘ ejecutar (x)

Sin avisos de ACL, atributos inmutables ni opciones de montaje restrictivas.
(Recuerda además el MAC —AppArmor/SELinux— y que los grupos nuevos exigen volver a iniciar sesión.)
```

`beto` es de `equipo` → trozo **grupo** (`r--`) → puede **leer** pero no escribir ni ejecutar.

**Caso ④: tú, con un fichero del sistema**

```text
$ diagnostica /etc/shadow
Usuario: alumno (uid 1001)   Grupos: alumno
Ruta:    /etc/shadow

  Tramo        Permisos    Dueño:Grupo     Aplica rwx  ¿Puede?
  /            drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /etc         drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /etc/shadow  -rw-r-----  root:shadow      otros  ---  (el objeto final: ver abajo)

Camino libre hasta el objeto. Sobre /etc/shadow, alumno puede:
   ✘ leer (r)
   ✘ escribir (w)
   ✘ ejecutar (x)

Sin avisos de ACL, atributos inmutables ni opciones de montaje restrictivas.
(Recuerda además el MAC —AppArmor/SELinux— y que los grupos nuevos exigen volver a iniciar sesión.)
```

(Aquí no hace falta `sudo`: `/etc/shadow` es visible para todos los usuarios; lo que está protegido es su **contenido**.)

> 🧠 La herramienta **no** evalúa ACL, atributos, `noexec`, capacidades ni AppArmor: los **lista como avisos** al final (ACL, inmutable, `ro`, `noexec`, `nosuid`). Pero en el 90 % de los casos el culpable está en la tabla de permisos.

### `strace`: ver el fallo exacto, sin adivinar (nivel *pro*)

Cuando un programa dice *"Permission denied"* **sin decir qué fichero**, `strace` te lo cuenta: te enseña **cada llamada al sistema** y su resultado.

```text
$ sudo -u carla strace -f -e trace=openat cat datos/secreto.txt 2>&1 | grep -E 'secreto|EACCES'
openat(AT_FDCWD, "datos/secreto.txt", O_RDONLY) = -1 EACCES (Permission denied)
cat: datos/secreto.txt: Permission denied
```

Ahí está: `openat(…, "datos/secreto.txt", O_RDONLY) = -1 EACCES (Permission denied)`: `EACCES` **es** `Permission denied`. (`strace` quizá haya que instalarlo: `sudo apt install strace`.) Con un servicio que falla (`strace -f -e trace=file -p PID`), el fichero culpable aparece en la última línea con `EACCES`.

---

## 13.4 · Casos de la vida real

### 🧾 Caso A · "Mi script no se ejecuta"

| Síntoma | Causa | Arreglo |
|---|---|---|
| `bash: ./s.sh: Permission denied` | falta la **`x`** | `chmod +x s.sh` |
| `s.sh: command not found` | no está en el `PATH` | `./s.sh` o ponerlo en `~/bin` |
| `cannot execute: required file not found` / `bad interpreter` | *shebang* mal o `\r` de Windows | `head -1 s.sh \| cat -A`; `sed -i 's/\r$//' s.sh` |
| `Permission denied` aun con `x` | **`noexec`** en la partición; o falta `r` | `findmnt -T .`; `bash s.sh` |

### 🧾 Caso B · "Mi compañero no puede editar lo que yo creo en la carpeta compartida"

Causas típicas (¡las dos a la vez!): **(1)** el fichero nace con el **grupo equivocado** (falta **SGID** en la carpeta, capítulo 10) y **(2)** nace sin `w` de grupo (**`umask 022`** en vez de `002`, capítulo 8).

```text
sudo chgrp equipo carpeta
sudo chmod 2775 carpeta          ← SGID: lo nuevo hereda el grupo
# y en la sesión de cada miembro:  umask 002
```

### 🧾 Caso C · "El servidor web da *403 Forbidden*"

Su usuario (`www-data`) necesita **`x` en TODAS las carpetas del camino** y **`r` en el fichero**. Lo más típico es la **carpeta personal** cerrada (`750`) o una carpeta intermedia sin `x`. Diagnóstico: `sudo diagnostica -u www-data /home/pepe/web/index.html` (o `namei -l`).

### 🧾 Caso D · "Después de `usermod -aG` sigue sin funcionar"

Los grupos se leen **al iniciar sesión** (capítulo 4): cierra la sesión y vuelve a entrar, o usa `newgrp grupo`. Comprueba con **`id`** (no `id usuario`).

### 🧾 Caso E · "No puedo borrar este fichero"

| Mensaje | Causa | Arreglo |
|---|---|---|
| `Permission denied` | no tienes `w`+`x` en la **carpeta** | `chmod u+wx carpeta` |
| `Operation not permitted` en `/tmp` o carpeta compartida | **sticky**: el fichero es de otro | pídeselo al dueño o usa `sudo` |
| `Operation not permitted` **incluso con `sudo`** | atributo **inmutable** | `lsattr f` → `sudo chattr -i f` |
| `Read-only file system` | partición `ro` | `findmnt -T ruta` → remontar |

### 🧾 Caso F · "Mis ficheros son de `root` y no puedo editarlos"

Los creó un comando con `sudo` (capítulo 9). Arreglo: **`sudo chown -R "$USER": carpeta`**. Para el futuro: **no uses `sudo` salvo cuando haga falta** y no lo mezcles con herramientas que crean ficheros en tu carpeta personal.

### 🧾 Caso G · "He ejecutado `chmod -R 777` y ahora todo es un lío"

Respira. Se arregla **por tipos** (capítulo 7):

```text
find carpeta -type d -exec chmod 755 {} +
find carpeta -type f -exec chmod 644 {} +
# y los scripts que deban ejecutarse:
chmod +x carpeta/scripts/*.sh
```

Si fue sobre carpetas del **sistema** (`/etc`, `/usr`…) ya no hay forma limpia de repararlo a mano: **reinstalar o restaurar copia**. Por eso nunca `chmod -R` en `/`.

---

## 13.5 · 📋 Recetario: "quiero que…" → "haz esto"

| Quiero… | Receta |
|---|---|
| Un **fichero privado** | `chmod 600 f` |
| Una **carpeta privada** | `chmod 700 d` |
| Un **script ejecutable** por todos | `chmod 755 s.sh` |
| **Publicar** un árbol (web, documentación) | `chmod -R u=rwX,go=rX d` |
| Una **carpeta de equipo** (todos del grupo editan) | `sudo chgrp g d && sudo chmod 2770 d` + `umask 002` |
| Una **carpeta de equipo** que otros puedan **leer** | `sudo chmod 2775 d` |
| Una **carpeta pública** donde cada uno borra lo suyo | `chmod 1777 d` |
| Un **buzón** (depositar sin listar) | `sudo chgrp g d && chmod 1730 d` |
| Un **fichero solo de lectura** para todos | `chmod 444 f` (¡y la carpeta controlada!) |
| Un fichero **a prueba de borrado**, incluso de root | `sudo chattr +i f` |
| Un **log** al que solo se pueda añadir | `sudo chattr +a f` |
| Dar acceso a **un solo usuario** concreto | ACL: `setfacl -m u:ana:r f` (cap. 12) |
| **Quitar la `x`** a todos los ficheros (no a carpetas) | `find . -type f -exec chmod a-x {} +` |
| Copiar un fichero **conservando permisos y dueño** | `sudo cp -a origen destino` (o `rsync -a`) |
| Copiar un árbol y que **mande mi `umask`** | `cp -r origen destino` (sin `-p`/`-a`) |
| **Clonar permisos** de otro fichero | `chmod --reference=modelo f` y `chown --reference=modelo f` |
| **Ver los permisos de todo un árbol** en octal | `find d -exec stat -c '%a %U:%G %n' {} + \| sort -k3` |
| Encontrar **peligros** | `find / -xdev -perm -0002 -type f`, `find / -perm -4000 -type f` |
| Que un usuario **vea qué hay pero no cambie** nada | dueño ≠ usuario; `chmod o=rX d` |
| **Reparar** ficheros que quedaron de `root` en `~` | `sudo chown -R "$USER": ~/carpeta` |
| **Auditar** qué puede hacer un usuario con una ruta | `sudo diagnostica -u usuario ruta` |

---

## 13.6 · 🛠️ Retos de reparación

Cada reto empieza con un **bloque que prepara el desastre** (ejecútalo tal cual). Tu misión: **diagnosticar** (con el método de 7 pasos y las herramientas) y **arreglar con el cambio mínimo**. Las soluciones están desplegadas.

#### 🟡 Reto 13.1 · "ana no llega a `proyecto-x/docs/leeme.txt`"

```text
$ mkdir -p proyecto-x/docs
$ echo "documentación" > proyecto-x/docs/leeme.txt
$ chmod 755 proyecto-x
$ chmod 700 proyecto-x/docs
$ chmod 644 proyecto-x/docs/leeme.txt
$ sudo -u ana cat proyecto-x/docs/leeme.txt
cat: proyecto-x/docs/leeme.txt: Permission denied
```

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo diagnostica -u ana /home/alumno/lab-permisos/proyecto-x/docs/leeme.txt
Usuario: ana (uid 1002)   Grupos: ana equipo
Ruta:    /home/alumno/lab-permisos/proyecto-x/docs/leeme.txt

  Tramo                                                Permisos    Dueño:Grupo     Aplica rwx  ¿Puede?
  /                                                    drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home                                                drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home/alumno                                         drwxr-x--x  alumno:alumno    otros  --x  ✔ puede atravesarlo
  /home/alumno/lab-permisos                            drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/proyecto-x                 drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/proyecto-x/docs            drwx------  alumno:alumno    otros  ---  ✘ FALTA x para atravesarlo
  /home/alumno/lab-permisos/proyecto-x/docs/leeme.txt  -rw-r--r--  alumno:alumno    otros  r--  (el objeto final: ver abajo)

✘ BLOQUEO en: /home/alumno/lab-permisos/proyecto-x/docs  (otros: ---)
  Sin poder atravesar ese tramo, ana no llega al objeto: NO puede hacer nada con él.
  Remedio: dar la x que falta en esa carpeta (chmod o+x / g+x, o añadir al usuario al grupo).

Sin avisos de ACL, atributos inmutables ni opciones de montaje restrictivas.
(Recuerda además el MAC —AppArmor/SELinux— y que los grupos nuevos exigen volver a iniciar sesión.)
$ chmod 755 proyecto-x/docs
$ sudo -u ana cat proyecto-x/docs/leeme.txt
documentación
```

El fichero es `644`, pero **la carpeta `docs` es `700`**: a `ana` ("otros") le falta la `x` ahí. Arreglo mínimo: `chmod 755 docs` (o solo `o+rx`).
</details>

#### 🟡 Reto 13.2 · "`backup.sh` da Permission denied"

```text
$ printf '#!/bin/bash\necho haciendo copia\n' > backup.sh
$ chmod 600 backup.sh
$ ./backup.sh
bash: ./backup.sh: Permission denied
```

<details>
<summary>💡 Ver solución</summary>

```text
$ ls -l backup.sh
-rw------- 1 alumno alumno 32 Oct 16 17:08 backup.sh
$ chmod u+x backup.sh
$ ./backup.sh
haciendo copia
```

Le faltaba la **`x`** (y como es un script, tiene que mantener la `r`: `rwx------`, o sea `700`).
</details>

#### 🔴 Reto 13.3 · "`beto` no puede guardar en `informes/` aunque es de equipo"

```text
$ mkdir informes
$ chmod 750 informes
$ sudo chgrp equipo informes
$ sudo -u beto sh -c 'echo "datos" > informes/beto.txt'
sh: 1: cannot create informes/beto.txt: Permission denied
```

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo diagnostica -u beto /home/alumno/lab-permisos/informes
Usuario: beto (uid 1003)   Grupos: beto equipo soporte
Ruta:    /home/alumno/lab-permisos/informes

  Tramo                               Permisos    Dueño:Grupo     Aplica rwx  ¿Puede?
  /                                   drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home                               drwxr-xr-x  root:root        otros  r-x  ✔ puede atravesarlo
  /home/alumno                        drwxr-x--x  alumno:alumno    otros  --x  ✔ puede atravesarlo
  /home/alumno/lab-permisos           drwxr-xr-x  alumno:alumno    otros  r-x  ✔ puede atravesarlo
  /home/alumno/lab-permisos/informes  drwxr-x---  alumno:equipo    grupo  r-x  (el objeto final: ver abajo)

Camino libre hasta el objeto. Sobre /home/alumno/lab-permisos/informes, beto puede:
   ✔ listar (r)
   ✘ crear/borrar dentro (w)
   ✔ entrar (x)

Sin avisos de ACL, atributos inmutables ni opciones de montaje restrictivas.
(Recuerda además el MAC —AppArmor/SELinux— y que los grupos nuevos exigen volver a iniciar sesión.)
$ chmod 770 informes
$ sudo -u beto sh -c 'echo "datos" > informes/beto.txt'
$ ls -l informes
total 4
-rw-r--r-- 1 beto beto 6 Oct 16 17:08 beto.txt
```

`beto` entra por el trozo **grupo** (`r-x`): puede entrar y listar, pero **no crear** (falta `w`). Arreglo: `chmod 770` (o `g+w`). Y para que lo que cree herede el grupo: `sudo chmod 2770` (capítulo 10).
</details>

#### 🔴 Reto 13.4 · "No puedo borrar `viejo.log` ni con `sudo`"

```text
$ echo "datos" > viejo.log
$ sudo chattr +i viejo.log
$ sudo rm -f viejo.log
rm: cannot remove 'viejo.log': Operation not permitted
```

<details>
<summary>💡 Ver solución</summary>

```text
$ lsattr viejo.log
----i---------e------- viejo.log
$ sudo chattr -i viejo.log
$ sudo rm -f viejo.log
$ ls viejo.log
ls: cannot access 'viejo.log': No such file or directory
```

`Operation not permitted` **incluso siendo `root`** → atributo **inmutable** (`i`). Se ve con `lsattr` y se quita con `chattr -i`.
</details>

#### 🔴 Reto 13.5 · "Diseña el reparto"

Prepara `intranet/` con dos carpetas: `publico/` (lo puede **leer cualquiera**) y `privado/` (**solo `equipo`**, que además puede escribir). `carla` (de `soporte`) no debe ver `privado`, pero sí `publico`.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir -p intranet/publico intranet/privado
$ echo "para todos" > intranet/publico/info.txt
$ echo "solo equipo" > intranet/privado/plan.txt
$ chmod 755 intranet
$ chmod 755 intranet/publico
$ chmod 644 intranet/publico/info.txt
$ sudo chgrp -R equipo intranet/privado
$ sudo chmod 2770 intranet/privado
$ sudo chmod 660 intranet/privado/plan.txt
$ sudo -u carla cat intranet/publico/info.txt
para todos
$ sudo -u carla cat intranet/privado/plan.txt
cat: intranet/privado/plan.txt: Permission denied
$ sudo -u ana sh -c 'echo "añadido por ana" >> intranet/privado/plan.txt'
$ cat intranet/privado/plan.txt
solo equipo
añadido por ana
```

`publico` → `755/644` (todos leen). `privado` → grupo `equipo`, `2770` (equipo entra/escribe, SGID para heredar el grupo) y los ficheros `660`; **otros nada**.
</details>

#### ⚫ Reto 13.6 · Examen: ¿cuál es el primer paso?

*Un servicio falla con "Permission denied" al abrir `/srv/datos/conf.ini`. ¿Cuál es el mejor **primer** comando de diagnóstico?* a) `chmod -R 777 /srv` b) `namei -l /srv/datos/conf.ini` c) `reboot` d) `chown root /srv/datos/conf.ini`

<details>
<summary>💡 Ver solución</summary>

**b)** `namei -l` enseña los permisos de **todos los tramos**: ¡lo más probable es que falte la `x` en una carpeta! (`a)` es el parche peligroso; `d)` rompería el acceso del servicio.)
</details>

#### ⚫ Reto 13.7 · Examen: dos errores

*Un usuario intenta `chown ana f` (siendo dueño de `f`) y recibe `Operation not permitted`. Otro intenta leer un fichero `-rw-------` ajeno y recibe `Permission denied`. ¿Qué diferencia hay entre ambos mensajes?*

<details>
<summary>💡 Ver solución</summary>

`Operation not permitted` (EPERM): la **acción** está reservada (solo `root` cambia el dueño); da igual los permisos del fichero. `Permission denied` (EACCES): falta un **permiso** (`r`) para esa operación.
</details>

---

⬅️ [Capítulo 12 · Más allá de `rwx`: atributos, ACL, *capabilities* y montajes](12-mas-alla-de-rwx.md) · [📚 Índice](README.md) · [Capítulo 14 · 🏆 El jefe final: misiones, auditoría y mini-examen LPIC-1](14-jefe-final.md) ➡️
