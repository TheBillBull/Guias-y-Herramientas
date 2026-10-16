# Capítulo 14 · 🏆 El jefe final: misiones, auditoría y mini-examen LPIC-1

> 🎯 **Objetivo:** juntar **todo** lo aprendido en problemas completos, con **autocomprobación** (✔/✘ medidos de verdad con distintos usuarios), una **auditoría de seguridad** con `find`, **velocidad** de conversión y un **mini-examen tipo LPIC-1** de 30 preguntas.
>
> 📘 **LPIC-1:** 104.5 · 110.1 · 107.1 · 103.3.
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`. Si algo quedó revuelto de capítulos anteriores, **vuelve a ejecutar el script del laboratorio**.

---

## 14.1 · El método del experto

1. 📝 **Traduce el enunciado a una tabla**: *quién* debe poder hacer *qué* sobre *qué*.
2. 🧱 **Elige la herramienta de cada fila**: `chmod` (permisos), `chgrp`/`chown` (propiedad), **SGID** (grupo heredado), **sticky** (borrado), `umask` (permisos de lo nuevo), `chattr` (blindaje).
3. 🔨 **Construye de fuera hacia dentro**: primero la carpeta, luego su grupo, luego sus permisos, luego los bits especiales.
4. 🧪 **Comprueba como cada usuario** (`sudo -u …`), **los éxitos y los fallos**: *"que no pueda"* también se prueba.
5. 🧹 **Simplifica**: permisos **mínimos**, nada de `777`.

---

## 14.2 · 🕵️ Misión 1: "La intranet de la empresa"

Eres el administrador. Hay 3 personas: **`ana`** y **`beto`** (grupo `equipo`) y **`carla`** y **`beto`** (grupo `soporte`). Tienes que montar en `intranet-final/` cinco carpetas con **estas reglas**:

| Carpeta | Regla |
|---|---|
| `equipo/` | Solo el grupo **`equipo`** puede **entrar, leer, crear y editar**. Lo que cree cualquiera **hereda el grupo `equipo`**. Los demás, **nada**. |
| `soporte/` | Lo mismo para el grupo **`soporte`**. |
| `publico/` | **Todos leen**, solo tú escribes. |
| `buzon/` | El grupo **`soporte`** puede **depositar** ficheros pero **no listar** la carpeta, y **ninguno borra lo de otro**. Los demás, nada. |
| `tmp/` | **Todos** crean; **cada uno borra solo lo suyo**. |

Primero, nuestro **comprobador** (pégalo: son dos funciones que dicen ✔ o ✘):

```bash
si() { d=$1; shift; if "$@" >/dev/null 2>&1; then echo "  ✔ $d"; else echo "  ✘ $d   ← NO CUMPLE"; fi; }
no() { d=$1; shift; if "$@" >/dev/null 2>&1; then echo "  ✘ $d   ← NO CUMPLE"; else echo "  ✔ $d"; fi; }
```

> 🧠 **Inténtalo tú primero.** Cuando termines, pega la solución y compara.

<details>
<summary>💡 Ver solución (la construcción)</summary>

```text
$ mkdir intranet-final
$ cd intranet-final
$ mkdir equipo soporte publico buzon tmp
# equipo/ y soporte/: grupo + SGID + acceso solo para el grupo
$ sudo chgrp equipo equipo
$ sudo chmod 2770 equipo
$ sudo chgrp soporte soporte
$ sudo chmod 2770 soporte
# publico/: todos leen
$ chmod 755 publico
$ echo "bienvenidos a la intranet" > publico/leeme.txt
$ chmod 644 publico/leeme.txt
# buzon/: soporte deposita (sin listar) + sticky
$ sudo chgrp soporte buzon
$ chmod 1730 buzon
# tmp/: público con sticky
$ chmod 1777 tmp
# la carpeta raíz, abierta para pasar pero sin escritura ajena
$ chmod 755 .
$ ls -l
total 20
drwx-wx--T 2 alumno soporte 4096 Oct 16 17:09 buzon
drwxrws--- 2 alumno equipo  4096 Oct 16 17:09 equipo
drwxr-xr-x 2 alumno alumno  4096 Oct 16 17:09 publico
drwxrws--- 2 alumno soporte 4096 Oct 16 17:09 soporte
drwxrwxrwt 2 alumno alumno  4096 Oct 16 17:09 tmp
```
</details>

Y ahora **el examen de la misión** (cada línea se prueba **como el usuario que corresponde**):

```bash
cd ~/lab-permisos/intranet-final
echo "── equipo/"
si "ana (equipo) crea en equipo/"                      sudo -u ana sh -c 'umask 002; touch equipo/de-ana.txt'
si "beto (equipo) edita lo que creó ana"              sudo -u beto sh -c 'echo x >> equipo/de-ana.txt'
si "lo creado en equipo/ hereda el grupo 'equipo'"     test "$(stat -c %G equipo/de-ana.txt)" = equipo
no "carla (otros) NO puede listar equipo/"            sudo -u carla ls equipo
echo "── soporte/"
si "carla (soporte) crea en soporte/"                  sudo -u carla sh -c 'umask 002; touch soporte/de-carla.txt'
si "beto (soporte) edita lo que creó carla"           sudo -u beto sh -c 'echo x >> soporte/de-carla.txt'
si "lo creado en soporte/ hereda el grupo 'soporte'"   test "$(stat -c %G soporte/de-carla.txt)" = soporte
no "ana (otros) NO puede entrar en soporte/"          sudo -u ana ls soporte
echo "── publico/"
si "ana lee publico/leeme.txt"                         sudo -u ana cat publico/leeme.txt
no "ana NO puede crear en publico/"                    sudo -u ana touch publico/x
no "carla NO puede borrar en publico/"                 sudo -u carla rm -f publico/leeme.txt
echo "── buzon/"
si "carla deposita en buzon/"                          sudo -u carla touch buzon/de-carla
si "beto (soporte) deposita en buzon/"                 sudo -u beto touch buzon/de-beto
no "carla NO puede listar buzon/"                      sudo -u carla ls buzon
no "beto NO puede borrar lo de carla (sticky)"         sudo -u beto rm -f buzon/de-carla
no "ana (otros) NO puede ni depositar en buzon/"       sudo -u ana touch buzon/de-ana
echo "── tmp/"
si "ana crea en tmp/"                                  sudo -u ana touch tmp/de-ana
no "beto NO puede borrar lo de ana en tmp/"            sudo -u beto rm -f tmp/de-ana
si "ana SÍ puede borrar lo suyo"                       sudo -u ana rm -f tmp/de-ana
cd ~/lab-permisos
```

_Resultado:_

```text
── equipo/
  ✔ ana (equipo) crea en equipo/
  ✔ beto (equipo) edita lo que creó ana
  ✔ lo creado en equipo/ hereda el grupo 'equipo'
  ✔ carla (otros) NO puede listar equipo/
── soporte/
  ✔ carla (soporte) crea en soporte/
  ✔ beto (soporte) edita lo que creó carla
  ✔ lo creado en soporte/ hereda el grupo 'soporte'
  ✔ ana (otros) NO puede entrar en soporte/
── publico/
  ✔ ana lee publico/leeme.txt
  ✔ ana NO puede crear en publico/
  ✔ carla NO puede borrar en publico/
── buzon/
  ✔ carla deposita en buzon/
  ✔ beto (soporte) deposita en buzon/
  ✔ carla NO puede listar buzon/
  ✔ beto NO puede borrar lo de carla (sticky)
  ✔ ana (otros) NO puede ni depositar en buzon/
── tmp/
  ✔ ana crea en tmp/
  ✔ beto NO puede borrar lo de ana en tmp/
  ✔ ana SÍ puede borrar lo suyo
```

Todo en ✔: **misión cumplida**. Fíjate en qué herramienta resuelve cada fila: **SGID** (grupo heredado) en `equipo` y `soporte`; **sticky + `-wx`** en el buzón; **sticky + `rwx`** en `tmp`; **`755`** en `publico`.

```text
$ ls -l intranet-final
total 20
drwx-wx--T 2 alumno soporte 4096 Oct 16 17:09 buzon
drwxrws--- 2 alumno equipo  4096 Oct 16 17:09 equipo
drwxr-xr-x 2 alumno alumno  4096 Oct 16 17:09 publico
drwxrws--- 2 alumno soporte 4096 Oct 16 17:09 soporte
drwxrwxrwt 2 alumno alumno  4096 Oct 16 17:09 tmp
```

---

## 14.3 · 🔍 Misión 2: auditoría de seguridad

Heredas un servidor con una carpeta `auditoria2/` **llena de malas prácticas**. Montamos el escenario (ejecuta el bloque tal cual):

```text
$ mkdir -p auditoria2/app auditoria2/logs auditoria2/claves auditoria2/tmp
$ printf '#!/bin/bash\necho servidor\n' > auditoria2/app/servidor.sh
$ chmod 4755 auditoria2/app/servidor.sh
$ cp /usr/bin/id auditoria2/app/herramienta
$ sudo chown root auditoria2/app/herramienta
$ sudo chmod 4755 auditoria2/app/herramienta
$ echo "pass=1234" > auditoria2/app/config.ini
$ chmod 644 auditoria2/app/config.ini
$ touch auditoria2/app/huerfano
$ sudo chown 4242:4242 auditoria2/app/huerfano
$ echo "evento" > auditoria2/logs/app.log
$ chmod 666 auditoria2/logs/app.log
$ echo "CLAVE-PRIVADA" > auditoria2/claves/id_ed25519
$ chmod 644 auditoria2/claves/id_ed25519
$ echo "clave-publica" > auditoria2/claves/id_ed25519.pub
$ chmod 644 auditoria2/claves/id_ed25519.pub
$ chmod 777 auditoria2/tmp
$ find auditoria2 -exec stat -c '%a %U:%G %n' {} + | sort -k3
775 alumno:alumno auditoria2
775 alumno:alumno auditoria2/app
644 alumno:alumno auditoria2/app/config.ini
4755 root:alumno auditoria2/app/herramienta
664 UNKNOWN:UNKNOWN auditoria2/app/huerfano
4755 alumno:alumno auditoria2/app/servidor.sh
775 alumno:alumno auditoria2/claves
644 alumno:alumno auditoria2/claves/id_ed25519
644 alumno:alumno auditoria2/claves/id_ed25519.pub
775 alumno:alumno auditoria2/logs
666 alumno:alumno auditoria2/logs/app.log
777 alumno:alumno auditoria2/tmp
```

Tu informe debe encontrar **seis tipos de problemas**. Intenta cada búsqueda **antes** de mirar la solución.

#### 🟡 Hallazgo 14.1 · Ficheros con SUID o SGID

<details>
<summary>💡 Ver solución</summary>

```text
$ find auditoria2 -type f -perm /6000
auditoria2/app/servidor.sh
auditoria2/app/herramienta
$ find auditoria2 -type f -perm -4000 -user root
auditoria2/app/herramienta
```

Dos SUID: `servidor.sh` (¡un **script** con SUID, que Linux ignora y solo es un riesgo!) y `herramienta` (un **binario SUID de `root`**, el más grave).
</details>

#### 🟡 Hallazgo 14.2 · Ficheros escribibles por cualquiera

<details>
<summary>💡 Ver solución</summary>

```text
$ find auditoria2 -type f -perm -0002
auditoria2/logs/app.log
```

`app.log` (`666`): cualquier usuario puede manipular el registro.
</details>

#### 🟡 Hallazgo 14.3 · Carpetas públicas sin *sticky*

<details>
<summary>💡 Ver solución</summary>

```text
$ find auditoria2 -type d -perm -0002 ! -perm -1000
auditoria2/tmp
```

`tmp` (`777` sin sticky): cualquiera borra lo de los demás.
</details>

#### 🟡 Hallazgo 14.4 · Ficheros huérfanos

<details>
<summary>💡 Ver solución</summary>

```text
$ find auditoria2 -nouser -o -nogroup
auditoria2/app/huerfano
```

`huerfano` pertenece al UID/GID `4242`, que no existe.
</details>

#### 🔴 Hallazgo 14.5 · Claves privadas legibles por otros

(Pista: `-name 'id_*'`, que **no** acabe en `.pub`, con permisos para grupo u otros: `-perm /077`.)

<details>
<summary>💡 Ver solución</summary>

```text
$ find auditoria2 -type f -name 'id_*' ! -name '*.pub' -perm /077
auditoria2/claves/id_ed25519
```

`id_ed25519` en `644`: `ssh` la rechazaría y cualquier usuario del sistema puede **copiarla**.
</details>

#### 🔴 Hallazgo 14.6 · Secretos legibles por todos

(Pista: ficheros `*.ini` con lectura para otros: `-perm -0004`.)

<details>
<summary>💡 Ver solución</summary>

```text
$ find auditoria2 -type f -name '*.ini' -perm -0004
auditoria2/app/config.ini
```

`config.ini` guarda `pass=1234` y es legible por todos (`644`).
</details>

#### ⚫ Corrección 14.7 · Dejarlo todo en orden

Arregla **cada** hallazgo con el cambio **mínimo**. Después, repite las búsquedas: **no debe salir nada**.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod u-s auditoria2/app/servidor.sh
$ sudo chmod u-s auditoria2/app/herramienta
$ chmod 640 auditoria2/logs/app.log
$ chmod 1777 auditoria2/tmp
$ sudo chown root:root auditoria2/app/huerfano
$ chmod 600 auditoria2/claves/id_ed25519
$ chmod 600 auditoria2/app/config.ini
$ echo "--- repetimos la auditoría (todo vacío = bien) ---"
--- repetimos la auditoría (todo vacío = bien) ---
$ find auditoria2 -type f -perm /6000
$ find auditoria2 -type f -perm -0002
$ find auditoria2 -type d -perm -0002 ! -perm -1000
$ find auditoria2 -nouser -o -nogroup
$ find auditoria2 -type f -name 'id_*' ! -name '*.pub' -perm /077
$ find auditoria2 -type f -name '*.ini' -perm -0004
$ echo "(fin)"
(fin)
```

Cada arreglo es mínimo y **el más estricto que no rompe nada**: quitar el `s`, quitar la escritura a otros, añadir sticky, dar el fichero a `root`, `600` para secretos.
</details>

---

## 14.4 · 🧩 Misión 3: "Reconstruye este listado, solo con letras"

Te pasan este listado y debes dejar **exactamente** esos permisos, **sin usar números**:

```text
-rwxr-x---  informe.sh
-rw-r-----  datos.csv
-r--r--r--  leeme.txt
-rwx--x--x  utilidad
-rw-rw-r--  notas.txt
---x------  oculto
```

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir reconstruir
$ cd reconstruir
$ touch informe.sh datos.csv leeme.txt utilidad notas.txt oculto
$ chmod u=rwx,g=rx,o=       informe.sh
$ chmod u=rw,g=r,o=         datos.csv
$ chmod a=r                 leeme.txt
$ chmod u=rwx,go=x          utilidad
$ chmod ug=rw,o=r           notas.txt
$ chmod u=x,go=             oculto
$ cat > esperado.txt <<'EOF'
---x------ oculto
-r--r--r-- leeme.txt
-rw-r----- datos.csv
-rw-rw-r-- notas.txt
-rwx--x--x utilidad
-rwxr-x--- informe.sh
EOF
$ stat -c '%A %n' informe.sh datos.csv leeme.txt utilidad notas.txt oculto | sort > obtenido.txt
$ sort esperado.txt | diff - obtenido.txt && echo "✅ IGUAL: listado reproducido"
✅ IGUAL: listado reproducido
$ cd ..
```

(`diff` sin salida + el `✅` significa que son **idénticos**.)
</details>

---

## 14.5 · ⚡ Misión 4: velocidad mixta

Cronométrate. Objetivo: **12 respuestas en menos de 1 minuto** (≈ 5 s cada una). Y para repetir sin fin con preguntas nuevas cada vez: `herramientas/entrenador-conversion.html` (¡prueba el *sprint* de 60 s!).

#### ⚫ Serie 14.8 · A

**Serie A**

1. `rwxr-x---` → ¿octal?
2. `2750` → ¿letras?
3. `umask 027` → ¿fichero y carpeta nuevos?
4. `111101000` → ¿octal y letras?
5. `rwsr-xr-x` → ¿octal?
6. `420` (decimal) → ¿octal?
7. `1777` → ¿letras?
8. `umask 022` → ¿fichero y carpeta nuevos?
9. `rw-rw-r--` → ¿octal?
10. `640` → ¿letras?
11. `umask 077` → ¿fichero y carpeta nuevos?
12. `rwxrwsr-x` → ¿octal?

<details>
<summary>💡 Ver respuestas</summary>

1. `rwxr-x---` → **750**
2. `2750` → **`rwxr-s---`**
3. `umask 027` → ficheros **640** · carpetas **750**
4. `111101000` → **750** (`rwxr-x---`)
5. `rwsr-xr-x` → **4755**
6. `420` → **644** (`rw-r--r--`)
7. `1777` → **`rwxrwxrwt`**
8. `umask 022` → ficheros **644** · carpetas **755**
9. `rw-rw-r--` → **664**
10. `640` → **`rw-r-----`**
11. `umask 077` → ficheros **600** · carpetas **700**
12. `rwxrwsr-x` → **2775**

</details>

#### ⚫ Serie 14.9 · B

**Serie B**

1. `751` → ¿letras?
2. `r--r-----` → ¿octal?
3. `umask 002` → ¿fichero y carpeta nuevos?
4. `488` (decimal) → ¿octal?
5. `4711` → ¿letras?
6. `110100000` → ¿octal y letras?
7. `rwx--s--x` → ¿octal?
8. `umask 037` → ¿fichero y carpeta nuevos?
9. `2770` → ¿letras?
10. `rw-r-----` → ¿octal?
11. `umask 033` → ¿fichero y carpeta nuevos?
12. `0600` → ¿letras?

<details>
<summary>💡 Ver respuestas</summary>

1. `751` → **`rwxr-x--x`**
2. `r--r-----` → **440**
3. `umask 002` → ficheros **664** · carpetas **775**
4. `488` → **750** (`rwxr-x---`)
5. `4711` → **`rws--x--x`**
6. `110100000` → **640** (`rw-r-----`)
7. `rwx--s--x` → **2711**
8. `umask 037` → ficheros **640** · carpetas **740**
9. `2770` → **`rwxrws---`**
10. `rw-r-----` → **640**
11. `umask 033` → ficheros **644** · carpetas **744**
12. `0600` → **`rw-------`**

</details>

---

## 14.6 · 📝 Mini-examen tipo LPIC-1 (30 preguntas)

**Reglas:** sin ordenador (aunque tienes laboratorio para comprobar después), **un minuto por pregunta**. Anota tus respuestas y compáralas con la **clave** de abajo. Hay preguntas de **una** respuesta y de **dos o tres** (se indica).

**P1.** ¿Qué número octal equivale a `-rwxr-x---`?
a) 750  b) 705  c) 570  d) 755

**P2.** ¿Qué comando muestra los permisos de la **carpeta** `/tmp` (y no los de su contenido)?
a) `ls -l /tmp`  b) `ls -ld /tmp`  c) `ls -a /tmp`  d) `stat -f /tmp`

**P3.** Con `umask 022`, ¿qué permisos tiene un **fichero nuevo** creado con `touch`?
a) `rw-rw-rw-`  b) `rwxr-xr-x`  c) `rw-r--r--`  d) `rw-------`

**P4.** ¿Quién puede cambiar el **propietario** de un fichero con `chown`?
a) El propietario  b) Cualquiera con permiso de escritura  c) Solo `root`  d) Cualquier miembro del grupo

**P5.** En `-rwsr-xr-x`, ¿qué significa la `s`?
a) El fichero es un socket  b) Se ejecuta con los privilegios de su **dueño**  c) Es un fichero compartido  d) Es sticky

**P6.** ¿Qué permiso **mínimo** sobre un directorio permite hacer `cd` en él?
a) `r`  b) `w`  c) `x`  d) `rwx`

**P7.** ¿Qué hace `chmod g+s carpeta`?
a) Da el SUID  b) Los ficheros nuevos **heredan el grupo** de la carpeta  c) Impide borrar ficheros ajenos  d) Hace la carpeta ejecutable

**P8.** (**Elige 2**) Un fichero tiene `-rw-r-----` con dueño `root` y grupo `ventas`. `juan` pertenece a `ventas`, `luis` no. ¿Qué es cierto?
a) `juan` puede leerlo  b) `luis` puede leerlo  c) `juan` puede escribirlo  d) `luis` no puede leerlo  e) `juan` puede ejecutarlo

**P9.** ¿Qué fichero contiene las contraseñas **cifradas** de los usuarios?
a) `/etc/passwd`  b) `/etc/shadow`  c) `/etc/group`  d) `/etc/login.defs`

**P10.** ¿Qué `chmod` simbólico equivale a `chmod 644 f`?
a) `u=rw,go=r`  b) `u=rwx,go=r`  c) `a=r`  d) `u=r,go=rw`

**P11.** ¿Para qué sirve el bit *sticky* en `/tmp`?
a) Para que los ficheros no se borren nunca  b) Para que solo el dueño de un fichero (o `root`) pueda borrarlo  c) Para ejecutar como `root`  d) Para heredar el grupo

**P12.** (**Elige 2**) ¿Qué comandos pueden cambiar el **grupo** propietario de un fichero?
a) `chgrp`  b) `chmod g=`  c) `chown :grupo`  d) `usermod`

**P13.** ¿Qué comando busca **todos** los ficheros con el bit SUID en el sistema?
a) `find / -perm 4000`  b) `find / -perm -4000`  c) `find / -type s`  d) `ls -l / | grep s`

**P14.** Un directorio tiene `dr--------`. Su dueño ejecuta `ls -l carpeta`. ¿Qué ocurre?
a) Muestra todo con detalles  b) Muestra los nombres pero da errores de acceso al pedir detalles  c) No muestra nada y da `Permission denied` en todo  d) Muestra solo la carpeta vacía

**P15.** `root` ejecuta `cat fichero` donde `fichero` tiene `---------- (000)`. ¿Qué pasa?
a) `Permission denied`  b) Muestra el contenido  c) `Operation not permitted`  d) Pide contraseña

**P16.** ¿Cuál es el problema de `chmod -R 755 .` sobre un árbol con muchos ficheros de texto?
a) Ninguno  b) Los ficheros de texto pasan a ser **ejecutables**  c) Se borran los permisos  d) Solo afecta a las carpetas

**P17.** ¿Qué hace `usermod -G ventas juan` **sin** `-a`?
a) Añade `ventas` a los grupos de `juan`  b) **Sustituye** todos sus grupos secundarios por `ventas`  c) Cambia su grupo principal  d) Da error

**P18.** ¿Qué octal equivale a `rw-rw-r--`?
a) 666  b) 664  c) 646  d) 764

**P19.** Un usuario ejecuta `umask 077` y luego `mkdir secreto`. ¿Qué permisos tiene `secreto`?
a) `drwxr-xr-x`  b) `drwx------`  c) `d---------`  d) `drwxrwxrwx`

**P20.** Un script tiene permisos `-r-x------` (dueño `maria`). `maria` ejecuta `./script`. ¿Qué ocurre?
a) Se ejecuta  b) `Permission denied`: necesita `w`  c) `command not found`  d) Se ejecuta solo con `sudo`

**P21.** ¿Qué permisos muestra `ls -l` para un **enlace simbólico**?
a) Los del destino  b) Siempre `lrwxrwxrwx`  c) `l---------`  d) Los del directorio

**P22.** ¿Qué significa la `S` **mayúscula** en `-rwSr--r--`?
a) SUID con `x` para el dueño  b) SUID **sin** `x` para el dueño  c) SGID  d) Es un error de `ls`

**P23.** Quieres dar `x` a **todas las carpetas** y solo a los ficheros que ya fueran ejecutables, con `-R`. ¿Qué usas?
a) `chmod -R +x`  b) `chmod -R a+X`  c) `chmod -R 755`  d) `chmod -R +s`

**P24.** (**Elige 2**) En el algoritmo de permisos, ¿qué es **verdad**?
a) Se mira el trozo del **dueño** si eres el dueño, aunque el del grupo sea más permisivo  b) Se suman los permisos de dueño y grupo  c) `root` se salta (casi) todos los permisos  d) "Otros" se comprueba siempre primero

**P25.** ¿Qué permisos necesitas en una **carpeta** para **borrar** un fichero que contiene (sin sticky)?
a) `r` en el fichero  b) `w` en el fichero  c) `w` y `x` en la **carpeta**  d) `r` y `x` en la carpeta

**P26.** ¿Cuál es el octal de `chmod u=rwx,g=rx,o= f`?
a) 755  b) 750  c) 740  d) 705

**P27.** Un fichero tiene `-rwsr-xr-x` y haces `chmod 755 f`. ¿Qué ocurre con el SUID?
a) Se conserva  b) Se **elimina**  c) Pasa a SGID  d) Da error

**P28.** `touch nuevo` falla con `Permission denied` en una carpeta `dr-xr-xr-x` de tu propiedad. ¿Por qué?
a) Falta la `x`  b) Falta la `r`  c) Falta la **`w`** en la carpeta  d) El fichero debe existir antes

**P29.** (**Elige 2**) ¿Qué es cierto del SGID en un **directorio**?
a) Los ficheros nuevos heredan el **grupo** del directorio  b) Los subdirectorios nuevos heredan también el SGID  c) Los ficheros nuevos se ejecutan como el dueño  d) Impide borrar ficheros ajenos

**P30.** ¿Qué comando lista los **ficheros normales escribibles por cualquiera** en `/var`?
a) `find /var -type f -perm -0002`  b) `find /var -type f -perm 0002`  c) `find /var -perm /0777`  d) `ls -lR /var | grep w`

---

### ✅ Clave de respuestas (con explicación)

<details>
<summary>💡 Ver la clave</summary>

| P | Resp. | Por qué |
|:-:|:-:|---|
| 1 | **a** | `rwx` `r-x` `---` → 7·5·0 |
| 2 | **b** | `-d` = la ficha de la carpeta misma |
| 3 | **c** | 666 & ~022 = 644 |
| 4 | **c** | solo `root` cambia el dueño |
| 5 | **b** | SUID |
| 6 | **c** | `x` = entrar |
| 7 | **b** | SGID en carpeta = grupo heredado |
| 8 | **a, d** | `juan` (grupo) → `r--`; `luis` (otros) → `---` |
| 9 | **b** | `/etc/shadow` |
| 10 | **a** | `u=rw` (6), `go=r` (4,4) |
| 11 | **b** | sticky |
| 12 | **a, c** | `chgrp g f` ≡ `chown :g f` |
| 13 | **b** | `-perm -4000` (todos esos bits) |
| 14 | **b** | `r` sin `x`: ves nombres, no detalles |
| 15 | **b** | `root` se salta rwx para leer |
| 16 | **b** | todos los ficheros reciben `x` |
| 17 | **b** | sin `-a` **sustituye** |
| 18 | **b** | 6·6·4 |
| 19 | **b** | 777 & ~077 = 700 |
| 20 | **a** | `r-x` del dueño: se ejecuta (necesita `r` y `x`, ¡y los tiene!) |
| 21 | **b** | siempre `lrwxrwxrwx` |
| 22 | **b** | `S` = bit sin la `x` de debajo |
| 23 | **b** | `a+X` (o `u=rwX,go=rX`) |
| 24 | **a, c** | primer trozo que coincide; root aparte |
| 25 | **c** | borrar manda la carpeta |
| 26 | **b** | 7·5·0 |
| 27 | **b** | en un **fichero**, `chmod 755` quita SUID/SGID |
| 28 | **c** | crear exige `w` (y `x`) en la carpeta |
| 29 | **a, b** | grupo y SGID heredados |
| 30 | **a** | `-perm -0002` (con `-`) = "tiene la `w` de otros" |

**Tu puntuación:** 27-30 → ¡a por el examen! · 22-26 → casi listo, repasa los fallos · menos de 22 → vuelve a los capítulos 4, 8 y 10.
</details>

---

## 14.7 · 🎓 Y ahora, ¿qué?

Has recorrido el 100 % de lo que pide el objetivo **104.5** de LPIC-1 y algo más. Para seguir:

| Si quieres… | Mira… |
|---|---|
| Dar permisos a un usuario concreto sin cambiar grupos | **ACL**: `man setfacl`, `man acl` (capítulo 12) |
| Entender el **MAC** de Ubuntu | AppArmor: `man apparmor`, `aa-status` |
| Dominar `sudo` y sus reglas | `man sudoers`, `visudo` (el fichero `/etc/sudoers` es `440`) |
| Practicar buscar y filtrar con `find`/`grep` | la guía de [regex y `grep`](../regex-grep-lpic1/README.md) |
| Repasar de un vistazo | la [chuleta de una página](chuleta.md) |

> 🧹 **Cuando termines**, deja tu sistema como estaba: `bash ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/laboratorio/preparar-laboratorio.sh --limpiar` borra `~/lab-permisos`, los usuarios `ana`, `beto`, `carla` y los grupos `equipo`, `soporte`, y devuelve a tu carpeta personal su permiso original.

---

⬅️ [Capítulo 13 · Diagnóstico: "¡Permission denied!" y qué hacer · Recetas](13-diagnostico-y-recetas.md) · [📚 Índice](README.md) · [📄 Chuleta](chuleta.md) ➡️
