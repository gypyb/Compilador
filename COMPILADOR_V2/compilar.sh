bison -d -o src/pyBis.c src/pyBis.y       
flex -o src/pyLex.c src/pyLex.flex
gcc -o build/COMPILADO src/pyLex.c src/pyBis.c
./build/COMPILADO ./test/codigo.python