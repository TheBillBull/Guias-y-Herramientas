# ============================================================================
#  Entorno virtual del libro "Expresiones regulares y grep (LPIC-1)"
#
#  Ubuntu 24.04 con:
#   - las herramientas del libro (grep, sed, vim/ex, find, plocate, man...)
#   - el usuario "alumno" y el laboratorio listo en /home/alumno/lab-regex
#   - /etc/passwd, /etc/group, /var/log/syslog... con el MISMO contenido que
#     usa el libro, para que TODAS las salidas coincidan.
#
#  Construir y entrar:   bash construir.sh   y   bash entrar.sh
# ============================================================================
ARG BASE=ubuntu:24.04
FROM ${BASE}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# 1) Paquetes. Se quita el filtro que elimina los manuales en las imágenes
#    Docker (para que `man grep` y `man 7 regex` funcionen) y se reinstalan
#    los paquetes base para recuperar sus manuales.
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes /etc/dpkg/dpkg.cfg.d/docker \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        bash grep sed coreutils findutils util-linux diffutils gzip bzip2 xz-utils tar \
        less man-db manpages vim plocate bsdextrautils procps iproute2 \
        sudo locales file tree nano ca-certificates \
 && apt-get install -y --reinstall --no-install-recommends \
        grep sed coreutils findutils util-linux diffutils less bash \
 && rm -f /usr/bin/man \
 && dpkg-divert --remove --rename /usr/bin/man \
 && sed -i 's/^# *\(en_US.UTF-8\|es_ES.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen \
 && mandb -q || true \
 && rm -rf /var/lib/apt/lists/*

# 2) Datos del libro y scripts de apoyo
COPY laboratorio /opt/lab
COPY entorno-virtual/scripts/ /opt/lab/scripts/
RUN bash /opt/lab/scripts/preparar-imagen.sh

# 3) A partir de aquí somos el alumno
USER alumno
WORKDIR /home/alumno
RUN bash /opt/lab/preparar-laboratorio.sh /home/alumno/lab-regex >/dev/null \
 && cat /opt/lab/scripts/bashrc-alumno >> /home/alumno/.bashrc
# 4) Índice de `locate` (después de crear el laboratorio, para que lo incluya)
USER root
RUN updatedb
USER alumno
WORKDIR /home/alumno/lab-regex

ENTRYPOINT ["/usr/local/bin/entrada-laboratorio"]
CMD ["bash"]
