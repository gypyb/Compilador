# Compilador para Python con Flex y Bison

## Descripción
Este proyecto consiste en desarrollar un compilador usando Flex y Bison para el lenguaje de programación Python. El compilador generará código ejecutable en ensamblador MIPS y se validará mediante el emulador MARS. Este trabajo es colaborativo y cada miembro del grupo tiene roles específicos asignados.

## Objetivos
- **Hito 1**: Crear una gramática inicial y procesar un programa Python simple que incluya operaciones aritméticas, booleanas y estructuras de control básicas.
- **Hito 2**: Ampliar la funcionalidad para incluir análisis semántico, generación de código intermedio y manejo de funciones y arrays multidimensionales.
- **Hito 3**: Generar código ensamblador final para todas las funcionalidades incorporadas y probar el compilador con casos de prueba tanto válidos como inválidos.

## Instalación
1. Clonar el repositorio:
git clone https://github.com/gypyb/Compilador.git
2. Navegar al directorio del proyecto:
cd nombre-del-repositorio

## Compilación y Ejecución
- Compilar el proyecto:
make all
- Ejecutar el compilador:
./compilador input.py output.asm

## Pruebas
El directorio `pruebas` contiene ejemplos de programas en Python que se pueden usar para verificar la funcionalidad del compilador. Para ejecutar las pruebas, use:
./run_tests.sh

## Contribuciones
- **Guillermo Pérez Bartolomé**: Desarrollo de la gramática y análisis sintáctico.
- **Carlos González Van Liempt**: Implementación de análisis semántico y generación de código intermedio.
- **Andrés Felipe Pérez Peña**: Pruebas, documentación y manejo de errores.

## Documentación Adicional
Para más detalles sobre cómo utilizar el compilador y los detalles técnicos, revisar la `memoria.pdf` incluida en la raíz del proyecto.
