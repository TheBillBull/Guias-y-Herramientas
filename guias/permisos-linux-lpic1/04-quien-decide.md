# Capítulo 4 · ¿Quién decide qué? El algoritmo de los permisos

> 🎯 **Objetivo:** saber **qué trozo** de `rwxrwxrwx` se le aplica a cada persona, entender las **paradojas** (¡el dueño puede tener *menos* permisos que un extraño!) y manejar **grupos** (principal, secundarios, `newgrp`, `usermod -aG`).
>
> 📘 **LPIC-1:** 104.5 (usar el campo *group* para dar acceso a miembros) · 107.1 (grupos).
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`.

---

## 4.1 · El algoritmo (cuando abres un fichero, Linux hace esto)

Cada vez que alguien intenta leer, escribir o ejecutar algo, el sistema se hace **tres preguntas, en este orden, y se queda con la primera que acierte**:

```text
                      ¿Quién intenta acceder?
                                │
              ┌─────────────────┴─────────────────┐
              ▼                                   │
     ¿Es ROOT (UID 0)?  ───── sí ───►  ✅ casi siempre PERMITIDO
              │ no                                │
              ▼
     ¿Es el DUEÑO del fichero?  ──── sí ───►  se mira SOLO el trozo del DUEÑO  ──► FIN
              │ no
              ▼
     ¿Pertenece al GRUPO del fichero?  ── sí ──►  se mira SOLO el trozo del GRUPO  ──► FIN
        (grupo principal o secundario)
              │ no
              ▼
     Es "OTROS"  ───────────────────────────►  se mira el trozo de OTROS  ──► FIN
```

Tres consecuencias que **hay que grabarse a fuego**:

> 🔑 **① Se mira UN solo trozo.** El que corresponda. Los otros **no se suman, no se heredan, no se consultan**.
>
> 🔑 **② Gana el primero que acierta**, no el más permisivo. Si eres el **dueño**, se te aplica el trozo del dueño **aunque el del grupo o el de otros sea mejor**.
>
> 🔑 **③ `root` va aparte**: no mira `rwx` (excepto la `x`, capítulo 2).

---

## 4.2 · Cuatro personas, un fichero: la **matriz de acceso**

Vamos a construir una herramienta muy útil: una función `quien` que, dado un fichero, te dice **qué pueden hacer `alumno`, `ana`, `beto` y `carla`** con él (leer ✔/✘, escribir, ejecutar). Es una "radiografía" de los permisos:

```bash
quien() {
  printf '%-8s leer  escribir  ejecutar\n' "$1"
  for u in alumno ana beto carla; do
    printf '%-8s' "$u"
    sudo -u $u test -r "$1" && printf '  ✔      ' || printf '  ✘      '
    sudo -u $u test -w "$1" && printf '  ✔       ' || printf '  ✘       '
    sudo -u $u test -x "$1" && printf '  ✔' || printf '  ✘'
    echo
  done
}
```

(`test -r f` pregunta "¿puede **quien lo ejecute** leer `f`?" y devuelve éxito o fallo.) Ahora creamos un fichero **nuestro** pero del **grupo `equipo`** con permisos `rw-r-----` (`640`):

```text
$ cp saludos.sh f
$ sudo chgrp equipo f
$ chmod 640 f
$ ls -l f
-rw-r----- 1 alumno equipo 93 Oct 16 17:08 f
$ quien f
f        leer  escribir  ejecutar
alumno    ✔        ✔         ✘
ana       ✔        ✘         ✘
beto      ✔        ✘         ✘
carla     ✘        ✘         ✘
```

Léelo con la receta del capítulo 1 y el algoritmo del 4.1:

| Persona | ¿Dueño? | ¿Del grupo `equipo`? | Trozo que se aplica | Resultado |
|---|:-:|:-:|:-:|---|
| 🧑‍🎓 **alumno** | **sí** | — | dueño `rw-` | lee ✔ escribe ✔ ejecuta ✘ |
| 👩 **ana** | no | **sí** | grupo `r--` | lee ✔ |
| 👨 **beto** | no | **sí** | grupo `r--` | lee ✔ |
| 👩‍🔧 **carla** | no | no | otros `---` | nada |

Para el mismo fichero, **cuatro personas distintas, cuatro resultados distintos**, y cada una usa un trozo diferente.

---

## 4.3 · 🤯 Las paradojas

### Paradoja 1: el dueño con **menos** poder que un extraño

```text
$ chmod 077 f
$ ls -l f
----rwxrwx 1 alumno equipo 93 Oct 16 17:08 f
$ quien f
f        leer  escribir  ejecutar
alumno    ✘        ✘         ✘
ana       ✔        ✔         ✔
beto      ✔        ✔         ✔
carla     ✔        ✔         ✔
```

`----rwxrwx`: el **dueño** (`alumno`) no tiene **nada**; el grupo y *otros* tienen **todo**. Como el dueño es el primero en comprobarse, **`alumno` se queda sin acceso** a su propio fichero (aunque, siendo dueño, puede rectificarlo con `chmod`). En cambio **`carla` (otros) puede leer, escribir y ejecutar**. ¡Es el mundo al revés!

> 😮 Es un error **de examen clásico**: *"el usuario es dueño y el grupo tiene más permisos, ¿qué se aplica?"* → **el del dueño**, aunque sea peor.

### Paradoja 2: el grupo **no** ayuda al dueño

`ana` es **dueña** de un fichero del grupo `equipo` (donde ella está). El grupo tiene `rw-`, pero la dueña solo `r--`:

```text
$ chmod 460 f
$ sudo chown ana:equipo f
$ ls -l f
-r--rw---- 1 ana equipo 93 Oct 16 17:08 f
$ quien f
f        leer  escribir  ejecutar
alumno    ✘        ✘         ✘
ana       ✔        ✘         ✘
beto      ✔        ✔         ✘
carla     ✘        ✘         ✘
```

> ⚠️ **Fíjate en el orden.** Primero `chmod` y **después** `chown`. En cuanto le regalas el fichero a `ana`, **dejas de ser el dueño** y ya no puedes cambiarle los permisos: `chmod: changing permissions of 'f': Operation not permitted`. Solo el **dueño** (o `root`) hace `chmod`.

- 👩 **ana**: dueña **y** del grupo, pero se aplica **el trozo del dueño** (`r--`): ¡no puede escribir!
- 👨 **beto**: del grupo → `rw-` → **sí** escribe.
- 🧑‍🎓 **alumno**: no es dueño ni del grupo → "otros" (`---`).

Es decir: **"ser del grupo" no suma al ser dueño**.

### Paradoja 3: el grupo sin permiso, "otros" con permiso

```text
$ sudo -u ana chmod 604 f
$ ls -l f
-rw----r-- 1 ana equipo 93 Oct 16 17:08 f
$ quien f
f        leer  escribir  ejecutar
alumno    ✔        ✘         ✘
ana       ✔        ✔         ✘
beto      ✘        ✘         ✘
carla     ✔        ✘         ✘
```

(El `chmod` lo hace `ana`, que ahora es la dueña.)

`rw----r--`: el **grupo** (`ana` es la dueña, pero `beto` es solo del grupo) tiene `---`, y *otros* tienen `r--`. **`beto` (grupo) no puede leer, pero `carla` (otros) sí.** Quien está en el grupo cae en el trozo del grupo (`---`) y **ya no mira "otros"**.

| Permisos | Lo que ocurre |
|---|---|
| `---rwxrwx` | el dueño no puede nada; los demás, todo |
| `rw-rw-rw-` | todo el mundo lee y escribe (peligrosísimo) |
| `r--rw-rw-` | el dueño no puede escribir; su grupo y los otros sí |
| `rw----rw-` | el grupo no puede nada; los otros leen y escriben |

---

## 4.4 · `root`: el que se salta las reglas

```text
$ cp saludos.sh g
$ chmod 000 g
$ ls -l g
---------- 1 alumno alumno 93 Oct 16 17:08 g
$ cat g
cat: g: Permission denied
$ sudo cat g | head -n 1
#!/bin/bash
$ sudo sh -c 'echo "echo root escribe" >> g'
$ sudo tail -n 1 g
echo root escribe
```

`root` puede leer y escribir un fichero `000`. Por debajo, en Linux, esto es la **capacidad** `CAP_DAC_OVERRIDE` ("saltarse el control de acceso discrecional"). Y ojo, lo repasamos: para **ejecutar** hace falta al menos una `x` (capítulo 2).

> 🛑 **Moraleja de seguridad:** si un fichero necesita estar protegido **incluso de `root`**, los permisos no bastan (hay que usar atributos como `chattr +i`, capítulo 12).

---

## 4.5 · Grupos: el principal y los secundarios

Cada usuario tiene:

| Qué | Para qué sirve | Se ve con |
|---|---|---|
| **Grupo principal** (uno) | es el grupo que se le pone a los ficheros **que crea** | `id -gn` |
| **Grupos secundarios** (0 o más) | dan **acceso** a lo que sea de esos grupos | `id -Gn`, `groups` |

Fíjate en cómo decide el **grupo de un fichero nuevo**. Preparamos una carpeta en la que **todos** puedan crear (`777`):

```text
$ mkdir comun
$ chmod 777 comun
$ sudo -u beto touch comun/de-beto-normal.txt
$ sudo -u beto sg equipo -c 'touch comun/de-beto-como-equipo.txt'
$ ls -l comun
total 0
-rw-r--r-- 1 beto equipo 0 Oct 16 17:08 de-beto-como-equipo.txt
-rw-r--r-- 1 beto beto   0 Oct 16 17:08 de-beto-normal.txt
```

`beto` tiene como principal `beto` y como secundarios `equipo` y `soporte`. Normalmente crea ficheros `beto:beto`. Con **`sg equipo -c 'comando'`** (o con `newgrp equipo`) cambia **temporalmente** su grupo principal a `equipo` y los ficheros nacen **del grupo `equipo`**.

| Comando | Qué hace |
|---|---|
| `id` / `id -Gn` | ver tus grupos |
| `groups` / `groups ana` | listar los grupos (tuyos o de otro) |
| `newgrp equipo` | abre una **sub-shell** con `equipo` como grupo principal (`exit` para volver) |
| `sg equipo -c 'cmd'` | ejecuta **un comando** con `equipo` como grupo principal |

---

## 4.6 · Añadir un usuario a un grupo: `usermod -aG` y el "cierra y abre sesión"

Un detalle que **cae en el examen** y descoloca a todos: cuando añades a alguien a un grupo, **no le afecta a lo que ya tiene abierto**. Los grupos de un proceso se fijan **al iniciar sesión**.

Lo probamos: `ana` crea un fichero del grupo `equipo` que solo el grupo puede leer. Tú (`alumno`) no eres de `equipo`:

```text
$ sudo -u ana sh -c 'echo "informe del equipo" > comun/informe.txt'
$ sudo chgrp equipo comun/informe.txt
$ sudo chmod 640 comun/informe.txt
$ ls -l comun/informe.txt
-rw-r----- 1 ana equipo 19 Oct 16 17:08 comun/informe.txt
$ cat comun/informe.txt
cat: comun/informe.txt: Permission denied
```

Ahora **te añadimos** al grupo `equipo`:

```text
$ sudo usermod -aG equipo alumno
$ id
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno)
$ id alumno
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno),1005(equipo)
$ cat comun/informe.txt
cat: comun/informe.txt: Permission denied
```

Fíjate en la trampa:

- `id alumno` (consulta la **base de datos**) → ya aparece `equipo`.
- `id` (a secas) → **todavía no**: tu terminal sigue con los grupos con los que arrancó.
- Y, por tanto, `cat` **sigue fallando** en esta terminal.

Cómo se ponen al día:

```text
$ sudo -u alumno id
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno),1005(equipo)
$ sg equipo -c 'cat comun/informe.txt'
informe del equipo
```

- `sudo -u alumno id` arranca un **proceso nuevo** y ya lleva el grupo.
- `sg equipo -c …` (o `newgrp equipo`) aplica el grupo en el momento.
- La solución "de verdad": **cerrar la sesión y volver a entrar** (o reiniciar la terminal/sesión gráfica).

Devolvemos el laboratorio a su estado:

```text
$ sudo gpasswd -d alumno equipo
Removing user alumno from group equipo
$ id alumno
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno)
```

> ⚠️ **¡Cuidado con `usermod -G` sin `-a`!** `usermod -G equipo alumno` **sustituye** *todos* los grupos secundarios por solo `equipo` (se pierden `sudo`, `adm`…). Hay que escribir **`-aG`** (*append* + *groups*) para **añadir**. Es un error que ha dejado a más de uno sin `sudo`.

---

## 4.7 · ¿Qué trozo me toca? La receta

Cuando mires un `ls -l` y te pregunten *"¿puede X hacer Y?"*:

1. **¿X es `root`?** → sí, salvo ejecutar sin ninguna `x`.
2. **¿X es el dueño** (3ª columna)? → mira **solo** el 1.er trozo.
3. Si no: **¿X está en el grupo** (4ª columna)? → mira **solo** el 2.º trozo. (Para saberlo: `id X`.)
4. Si no: → **3.er trozo** (otros).
5. ¿Y tiene X acceso a **todas las carpetas del camino** (`x`)? (capítulo 3)

```text
-rw-r----- 1 alumno equipo ...  f
   │  │  └─ 3º trozo: OTROS ─── carla (ni dueño ni de equipo)
   │  └──── 2º trozo: GRUPO ─── ana y beto (de equipo)
   └─────── 1º trozo: DUEÑO ─── alumno
```

---

## 4.8 · 🏋️ Ejercicios

Para cada uno: **primero piensa quién puede qué**, luego comprueba con `quien`. (Si en tu terminal no tienes la función `quien`, vuelve a pegar su definición del apartado 4.2.)

#### 🟢 Ejercicio 4.1 · Todo para todos

Fichero `abierto` con `rwxrwxrwx`. ¿Quién puede hacer qué?

<details>
<summary>💡 Ver solución</summary>

```text
$ cp saludos.sh abierto
$ chmod 777 abierto
$ quien abierto
abierto  leer  escribir  ejecutar
alumno    ✔        ✔         ✔
ana       ✔        ✔         ✔
beto      ✔        ✔         ✔
carla     ✔        ✔         ✔
```

**Todos** pueden todo (777). (Casi nunca es buena idea.)
</details>

#### 🟢 Ejercicio 4.2 · Solo el dueño

`secreto3` con `rw-------`.

<details>
<summary>💡 Ver solución</summary>

```text
$ cp datos/notas.txt secreto3
$ chmod 600 secreto3
$ quien secreto3
secreto3 leer  escribir  ejecutar
alumno    ✔        ✔         ✘
ana       ✘        ✘         ✘
beto      ✘        ✘         ✘
carla     ✘        ✘         ✘
```

Solo `alumno` (dueño) lee y escribe. Nadie ejecuta (no hay `x`).
</details>

#### 🟢 Ejercicio 4.3 · Lectura para el equipo

Haz que el grupo `equipo` **lea** `informe2` y solo tú lo **edites**. Los demás, nada.

<details>
<summary>💡 Ver solución</summary>

```text
$ cp datos/notas.txt informe2
$ sudo chgrp equipo informe2
$ chmod 640 informe2
$ quien informe2
informe2 leer  escribir  ejecutar
alumno    ✔        ✔         ✘
ana       ✔        ✘         ✘
beto      ✔        ✘         ✘
carla     ✘        ✘         ✘
```

`640` = `rw-r-----`. `ana` y `beto` leen; `carla`, nada.
</details>

#### 🟡 Ejercicio 4.4 · Edición para el equipo

Ahora que el grupo `equipo` también pueda **editar** `informe2`.

<details>
<summary>💡 Ver solución</summary>

```text
$ chmod 660 informe2
$ ls -l informe2
-rw-rw---- 1 alumno equipo 39 Oct 16 17:08 informe2
$ quien informe2
informe2 leer  escribir  ejecutar
alumno    ✔        ✔         ✘
ana       ✔        ✔         ✘
beto      ✔        ✔         ✘
carla     ✘        ✘         ✘
```

`660` = `rw-rw----`. Ahora `ana` y `beto` escriben; `carla` sigue fuera.
</details>

#### 🟡 Ejercicio 4.5 · El grupo "soporte"

Un fichero para el grupo `soporte`, legible por el grupo y por nadie más. ¿Quién puede leerlo?

<details>
<summary>💡 Ver solución</summary>

```text
$ cp datos/notas.txt tickets.txt
$ sudo chgrp soporte tickets.txt
$ chmod 640 tickets.txt
$ quien tickets.txt
tickets.txt leer  escribir  ejecutar
alumno    ✔        ✔         ✘
ana       ✘        ✘         ✘
beto      ✔        ✘         ✘
carla     ✔        ✘         ✘
```

`soporte` = `beto` y `carla`. `ana` no. Fíjate en que **`alumno`** lo lee por ser **dueño**.
</details>

#### 🟡 Ejercicio 4.6 · Dos grupos a la vez

`beto` pertenece a `equipo` y a `soporte`. Crea dos ficheros, uno de cada grupo, y demuestra que `beto` puede leer ambos pero `ana` solo el de `equipo`.

<details>
<summary>💡 Ver solución</summary>

```text
$ echo "uno" > f-equipo; echo "dos" > f-soporte
$ sudo chgrp equipo f-equipo
$ sudo chgrp soporte f-soporte
$ chmod 640 f-equipo f-soporte
$ sudo -u beto cat f-equipo f-soporte
uno
dos
$ sudo -u ana cat f-equipo f-soporte
uno
cat: f-soporte: Permission denied
```

Un usuario puede tener **tantos grupos secundarios como haga falta**; cada fichero solo mira **su** grupo.
</details>

#### 🔴 Ejercicio 4.7 · El error del dueño

Un compañero escribió `chmod 066 fichero` pensando que así lo "cerraba". ¿Qué ha logrado realmente?

<details>
<summary>💡 Ver solución</summary>

```text
$ cp datos/notas.txt f066
$ chmod 066 f066
$ ls -l f066
----rw-rw- 1 alumno alumno 39 Oct 16 17:08 f066
$ quien f066
f066     leer  escribir  ejecutar
alumno    ✘        ✘         ✘
ana       ✔        ✔         ✘
beto      ✔        ✔         ✘
carla     ✔        ✔         ✘
```

`066` = `---rw-rw-`: **el dueño no puede nada** y **todos los demás leen y escriben**. Ha conseguido lo contrario de proteger.
</details>

#### 🔴 Ejercicio 4.8 · Dueña sin permiso de escribir

`ana` es la dueña de `agenda-ana` (grupo `equipo`) con `r--rw----`. ¿Puede `ana` escribir? ¿Y `beto`? ¿Y cómo lo arreglaría ella?

<details>
<summary>💡 Ver solución</summary>

```text
$ cp datos/agenda.txt agenda-ana
$ chmod 460 agenda-ana
$ sudo chown ana:equipo agenda-ana
$ quien agenda-ana
agenda-ana leer  escribir  ejecutar
alumno    ✘        ✘         ✘
ana       ✔        ✘         ✘
beto      ✔        ✔         ✘
carla     ✘        ✘         ✘
$ sudo -u ana chmod u+w agenda-ana
$ ls -l agenda-ana
-rw-rw---- 1 ana equipo 56 Oct 16 17:08 agenda-ana
```

`ana` (dueña) **no puede escribir** (se aplica `r--`), `beto` (grupo, `rw-`) sí. Pero como **dueña** puede cambiar los permisos: `chmod u+w` y listo.
</details>

#### 🔴 Ejercicio 4.9 · El fichero invisible para su grupo

Haz un fichero del grupo `equipo` con `rw----r--`. ¿Puede `beto` (de `equipo`) leerlo? ¿Y `carla`?

<details>
<summary>💡 Ver solución</summary>

```text
$ cp datos/notas.txt f604
$ sudo chgrp equipo f604
$ chmod 604 f604
$ quien f604
f604     leer  escribir  ejecutar
alumno    ✔        ✔         ✘
ana       ✘        ✘         ✘
beto      ✘        ✘         ✘
carla     ✔        ✘         ✘
```

`beto` y `ana` (de `equipo`) → trozo del grupo `---` → **no**. `carla` → otros `r--` → **sí**. "Ser del grupo" no te deja usar "otros".
</details>

#### 🔴 Ejercicio 4.10 · Grupos nuevos y sesión vieja

Acabas de ejecutar `sudo usermod -aG docker pepe`, pero `pepe` (con la sesión abierta) sigue sin poder usar Docker. ¿Qué le dices?

<details>
<summary>💡 Ver solución</summary>

Los grupos se leen **al iniciar sesión**: debe **cerrar sesión y volver a entrar** (o usar `newgrp docker` para esa sub-shell). Se comprueba con `id` (no con `id pepe`, que lee la base de datos y ya lo mostraría).
</details>

#### ⚫ Ejercicio 4.11 · Quién puede qué (examen)

*El fichero `informe.txt` tiene `-rw-r-----` con propietario `maria` y grupo `ventas`. `juan` es miembro de `ventas`, `luis` no. ¿Cuál es correcta?* a) `juan` y `luis` pueden leerlo b) `juan` puede leerlo, `luis` no c) `luis` puede leerlo, `juan` no d) `juan` puede escribirlo

<details>
<summary>💡 Ver solución</summary>

**b).** `juan` → grupo `r--` → lee, no escribe. `luis` → otros `---` → nada.
</details>

#### ⚫ Ejercicio 4.12 · Quién puede qué (examen 2)

*`-r--rw-rw-` con dueño `maria`. ¿Puede `maria` escribir?* a) Sí, como dueña b) Sí, porque tiene `rw-` el grupo y es del grupo c) **No** d) Solo si usa `sudo`

<details>
<summary>💡 Ver solución</summary>

**c).** Como dueña se le aplica **solo** el trozo del dueño (`r--`). Aunque esté en el grupo, **no se suma**. (Ella podría cambiarse los permisos con `chmod u+w`.) La d) es cierta técnicamente (root se salta los permisos), pero la respuesta que busca el examen es la c).
</details>

#### ⚫ Ejercicio 4.13 · Verdadero o falso

*"Si un usuario es propietario de un fichero y también pertenece a su grupo, se aplican los permisos más amplios de ambos."*

<details>
<summary>💡 Ver solución</summary>

**Falso.** Se aplican **solo** los del propietario (el primero que coincide). Lo hemos comprobado con `ana` en la paradoja 2.
</details>

---

⬅️ [Capítulo 3 · `r`, `w` y `x` en los directorios: el capítulo que casi todos entienden mal](03-directorios.md) · [📚 Índice](README.md) · [Capítulo 5 · Octal, binario, decimal y letras: entender 755, 644 o 4755 de un vistazo](05-octal-binario-decimal.md) ➡️
