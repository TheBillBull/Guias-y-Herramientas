#!/usr/bin/env python3
# Programa de ejemplo
import os
import sys

# TODO: validar argumentos
def saludar(nombre):
    """Saluda a alguien."""
    print("Hola, " + nombre)  # saludo

def main():
    if len(sys.argv) < 2:
        print("Uso: programa.py NOMBRE")   # FIXME: mejorar mensaje
        sys.exit(1)

    saludar(sys.argv[1])
    # TODO: guardar log
    x = 42
    y = 3.14

if __name__ == "__main__":
    main()
