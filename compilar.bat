@echo off
cd C:\Users\guill\OneDrive\Documents\UEM\4curso\Compiladores\Compilador

if not exist build\COMPILADO (
    echo Compilando el compilador...
    flex -o src\lexer.c src\lexer.l
    bison -d -o src\parser.c src\parser.y
    gcc -o build\COMPILADO src\lexer.c src\parser.c src\helper\utils.c -Iinclude
    echo Compilación completada.
)

set /p TESTFILE=Ingrese la ruta del archivo de prueba, o presione Enter para usar un archivo predeterminado: 
if "%TESTFILE%"=="" set TESTFILE=test\correct\test_correct1.py

build\COMPILADO %TESTFILE%
