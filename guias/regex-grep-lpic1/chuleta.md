# 📄 Chuleta: expresiones regulares y `grep` (LPIC-1)

> Todo en una página. Imprímela, pégala en la pared, pero **no te limites a leerla**: ¡practica los [ejercicios](README.md)!

---

## 1 · Los metacaracteres

| Símbolo | Significa | Ejemplo |
|---|---|---|
| `.` | **un** carácter cualquiera | `c.sa` → casa, cosa |
| `^` | **principio** de línea | `^root` |
| `$` | **final** de línea | `bash$` |
| `^$` | línea **vacía** | `grep -c '^$'` |
| `\` | **escapa** el símbolo siguiente | `3\.14` |
| `*` | el anterior, **0 o más** veces | `ho*la` |
| `[abc]` | **uno** de a, b, c | `gr[ae]p` |
| `[a-z]` `[0-9]` | un carácter del **rango** | `[A-Z][a-z]*` |
| `[^abc]` | uno que **no** sea a, b, c | `[^:]*` |
| `[[:digit:]]` | clase POSIX (¡doble corchete!) | `[[:alpha:]_]` |

## 2 · BRE contra ERE (los "5 poderes extra")

| Quiero… | **BRE** (`grep`) | **ERE** (`grep -E`) |
|---|---|---|
| uno o más | `a\+` | `a+` |
| cero o uno | `a\?` | `a?` |
| repetir n veces | `a\{3\}` `a\{2,5\}` | `a{3}` `a{2,5}` |
| agrupar | `\(ab\)` | `(ab)` |
| recordar | `\1` | `\1` |

**Alternativa (O):** en BRE se escribe `a\|b` (GNU); en ERE, `a|b`.

> 🧠 **Regla:** en BRE, la barra **activa** `+ ? { } ( ) |`; en ERE, la barra los **desactiva**.

## 3 · Cuantificadores y la coma

| | |
|---|---|
| `{3}` | exactamente 3 |
| `{3,}` | 3 o más |
| `{3,5}` | de 3 a 5 |
| `{,5}` | hasta 5 (GNU) |

La **coma** es normal en el texto y dentro de `[ ]`; dentro de `{ }` separa mínimo y máximo (¡sin espacios!).

## 4 · Palabras y atajos (GNU)

| | |
|---|---|
| `\<` `\>` | principio / fin de **palabra** |
| `\b` `\B` | límite / no límite de palabra |
| `\w` `\W` | carácter de palabra (`[_[:alnum:]]`) / no |
| `\s` `\S` | espacio en blanco / no |
| `-w` | solo **palabras** completas |
| `-x` | solo **líneas** completas |

## 5 · Clases POSIX

`[:digit:]` `[:alpha:]` `[:alnum:]` `[:upper:]` `[:lower:]` `[:space:]` `[:blank:]` `[:punct:]` `[:xdigit:]` `[:print:]` `[:graph:]` `[:cntrl:]`

Siempre **dentro de otro corchete**: `[[:digit:]]`, `[^[:space:]]`.

## 6 · Dentro de un `[ ]`

| Carácter | Qué pasa |
|---|---|
| `.` `*` `$` `?` `+` `(` `)` `{` `}` | son **literales** |
| `\` | también literal (¡no escapa!) |
| `^` | negación **solo si va el primero** |
| `-` | rango entre dos; literal al principio o al final |
| `]` | literal si va **el primero** |

## 7 · `grep`: opciones esenciales

| Opción | Hace |
|---|---|
| `-i` | ignora mayúsculas |
| `-v` | **invierte** (líneas que no coinciden) |
| `-c` | cuenta **líneas** |
| `-n` | número de línea |
| `-o` | **solo lo que coincide** |
| `-l` / `-L` | ficheros que sí / que no contienen |
| `-q` | silencio (solo código de salida) |
| `-s` | oculta errores de ficheros |
| `-m N` | para tras N coincidencias |
| `-A N` `-B N` `-C N` | contexto después / antes / alrededor |
| `-r` / `-R` | recursivo (sin / con enlaces simbólicos) |
| `--include=` `--exclude=` `--exclude-dir=` | filtros por nombre |
| `-h` / `-H` | sin / con nombre de fichero |
| `-e P` / `-f FICH` | patrón(es) / patrones desde un fichero |
| `-E` `-F` `-G` `-P` | ERE · texto fijo · BRE · Perl |
| `-a` / `-I` | binarios como texto / ignorarlos |

**Códigos de salida:** `0` encontró · `1` no encontró · `2` error.

## 8 · Recetas que usarás toda tu vida

```text
# Quitar comentarios y líneas vacías
grep -Ev '^[[:space:]]*(#|$)' fichero

# Contar apariciones (no líneas)
grep -o 'palabra' fichero | wc -l

# Ranking de lo más repetido
grep -o 'DATO' fichero | sort | uniq -c | sort -rn

# Extraer solo el valor tras una clave   (PCRE)
grep -oP 'CLAVE=\K.*' fichero

# Campo N de un fichero separado por ":"  (PCRE)
grep -oP '^([^:]*:){N-1}\K[^:]*' fichero

# Varias condiciones a la vez, en cualquier orden  (PCRE)
grep -P '^(?=.*A)(?=.*B)(?!.*C)' fichero

# ¿Existe el usuario? (para scripts)
grep -q '^alumno:' /etc/passwd && echo existe

# Ocultar errores de permisos
grep -r 'algo' /etc 2>/dev/null

# Extraer IPs
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' fichero

# El truco del ps | grep
ps aux | grep '[s]shd'

# Lo que está entre comillas
grep -o '"[^"]*"' fichero

# Líneas duplicadas
sort fichero | uniq -d
```

## 9 · Piezas de formatos (ERE, con `-x` para línea entera)

```text
Octeto 0-255    (25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])
IPv4            (OCTETO\.){3}OCTETO
Hora hh:mm      ([01][0-9]|2[0-3]):[0-5][0-9]
Fecha ISO       [0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])
Correo          [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}
Etiqueta DNS    [a-z0-9]([a-z0-9-]*[a-z0-9])?
MAC             ([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}
DNI/NIE         ([0-9]{8}|[XYZ][0-9]{7})[A-Z]
```

## 10 · ¿Qué dialecto usa cada programa?

| Programa | Dialecto |
|---|---|
| `grep` | BRE (`-E` ERE, `-F` fijo, `-P` Perl) |
| `egrep` / `fgrep` | ERE / fijo |
| `sed` | BRE (`-E` o `-r` = ERE) |
| `awk` | ERE |
| `vi` | BRE-like (`:s`, `:g`, `/`) |
| `less`, `man` | en Ubuntu, extendida |
| `find -regex` | tipo `emacs` (toda la ruta); `-regextype posix-extended` = ERE |
| `find -name` | **comodines**, no regex |
| `locate -r` / `--regex` | BRE / ERE |
| `bash [[ =~ ]]` | ERE |

## 11 · `sed` en 10 líneas

```text
sed 's/viejo/nuevo/g' f        sustituir (g = todas)
sed -n '5p' f                  imprimir la línea 5
sed -n '3,7p' f                líneas 3 a 7
sed '/regex/d' f               borrar líneas que coinciden
sed -n '/ini/,/fin/p' f        rango entre dos regex
sed -E 's/(a)(b)/\2\1/' f      reordenar con grupos
sed 's/.*/\U&/' f              a mayúsculas
sed -i.bak 's/a/b/' f          modificar el fichero (¡con copia!)
sed '2i\texto' f               insertar antes de la 2
sed -n '$=' f                  contar líneas
```

## 12 · Tuberías y redirecciones ([cap. 17](17-tuberias-y-redirecciones.md))

| Quiero… | Escribo |
|---|---|
| guardar la salida (pisa) / añadir | `cmd > f` / `cmd >> f` |
| guardar los errores | `cmd 2> f` / `cmd 2>> f` |
| tirar la salida / los errores | `cmd > /dev/null` / `cmd 2> /dev/null` |
| **todo** al mismo sitio | `cmd > f 2>&1` · `cmd &> f` |
| leer de un fichero | `cmd < f` |
| pasar un texto | `cmd <<< 'texto'` · `cmd <<'FIN' … FIN` |
| encadenar (solo `stdout`) / con errores | `a \| b` / `a \|& b` (`a 2>&1 \| b`) |
| guardar y seguir | `a \| tee f \| b` (`-a` añade) |
| lista → argumentos | `a \| xargs b` · `xargs -0` con `find -print0` · `b $(a)` |
| salida como si fuera un fichero | `diff <(a) <(b)` |
| solo si salió bien / mal | `a && b` / `a \|\| b` |

**Trampas:** `sort f > f` deja `f` **vacío** · `2>&1 > f` ≠ `> f 2>&1` (el orden importa) · `$?` de una tubería es el del **último** (`${PIPESTATUS[@]}`) · un `while read` tras `\|` corre en un subshell · `sudo cmd > f` no da permisos a `>` (usa `\| sudo tee f`).

---

## 13 · Mapa del examen LPIC-1

| Objetivo | Qué entra |
|---|---|
| **103.1** línea de comandos | `echo`, `history`, `man`, `which`, `type`, variables |
| **103.2** filtros | `cat` `cut` `head` `tail` `nl` `paste` `join` `sort` `uniq` `tr` `wc` `sed` `split` `od` `md5sum`… |
| **103.3** gestión de ficheros | comodines (`*` `?` `[ ]`), `cp` `mv` `rm` `find` |
| **103.4** flujos y tuberías | `>` `>>` `2>` `2>&1` `<` `<<` `\|` `tee` `xargs` (→ [cap. 17](17-tuberias-y-redirecciones.md)) |
| **103.7** regex | BRE vs ERE, `grep` `egrep` `fgrep` `sed`, clases, cuantificadores, anclas |
| **103.8** `vi` | modos, `/`, `:s`, `:g`, `:wq`, `:q!` |
| **104.7** buscar ficheros | `find` `locate` `updatedb` `whereis` `which` `type` |

---

⬅️ [Volver al índice](README.md)
