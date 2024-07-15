%{

// ----------------------------- GLOSARIO DE IMPORTS -------------------------------------------
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tabla_simbolos.h"
#include "AST_py.h"

// ----------------------------- DECLARACION DE VARIABLES Y ESTRUCTURAS -------------------------------------------

//Declaracion de variables "extern" sirve para declararlas como variables globales
FILE *yyout;
extern FILE* yyin;
extern int num_linea; //Almacena el numero de linea durante la ejecucion
extern tSimbolos tabla[256];
extern int indice; //Se almacena el índice de la tabla de tSimbolos
char* tipos[] = {"numerico", "numericoDecimal", "texto", "bool", "array"}; //Para parsear el tipo que se detecta en flex al tipo del nodo

typedef struct array{
    char* name;
    int size;
    int* valores;
} array;

array arrays[100]; // Store detected arrays
int array_count = 0;

%}

/*Definicion de tipos y estructuras empleadas*/
%union {
  int enteroVal;
  float realVal;
  char* stringVal;
  char* cadenaVal;
  int* valores;
  struct atributos{
    int numerico;
    float numericoDecimal;
    struct array *miarray;
    char* texto;
    char* tipo;             //Define el tipo que se esta usando
    struct ast *n;          //Para almacenar los nodos del AST
  }tr;
}

/*Declaración de los TOKENS*/
%token SUMA RESTA MULTIPLICACION DIVISION IGUAL APERTURAPARENTESIS CIERREPARENTESIS APERTURACORCHETE CIERRECORCHETE IMPRIMIR MAYORREL MENORREL MAYORIGUALREL MENORIGUALREL IGUALREL NOIGUALREL AND OR WHILE ENDWHILE DOSPUNTOS FOR ENDFOR IN RANGE COMA IF ELIF ELSE ENDIF

/*Declaración de los TOKENS que provienen de FLEX con su respectivo tipo*/
%token <enteroVal> NUMERICO 
%token <realVal> NUMERICODECIMAL 
%token <stringVal> IDENTIFICADOR
%token <cadenaVal> CADENA
%token <enteroVal> NUM

/*Declaración de los TOKENS NO TERMINALES con su estructura*/
%type <tr> sentencias sentencia tipos expresion asignacion bucle_w bucle_f condicion_if elif_clauses else_clause imprimir
%type <valores> elements  

/*Declaración de la precedencia siendo menor la del primero y mayor la del último*/
%left SUMA RESTA MULTIPLICACION DIVISION MAYORREL MENORREL MAYORIGUALREL MENORIGUALREL AND OR IGUALREL NOIGUALREL


%start codigo
%%

//GRAMATICA
//X --> S
//S --> D | S D
//D --> A | I 
//A --> id = E 
//E --> E op T | T
//T --> id | num | numdecimal
//I --> imprimir ( E )

//-----------------------------------------------  PRODUCCIONES  -------------------------------------------------------

//PRODUCCION "codigo", formado por sentencias
//X --> S
codigo:
    sentencias  {
        comprobarAST($1.n); 
        printf("\n[FINALIZADO]\n");     
    }
;

//PRODUCCION "sentencias", puede estar formado por una sentencia o un grupo de sentencias
//S --> D | S D
sentencias:
    sentencia { $$ = $1; }
    | sentencias sentencia { //para hacerlo recursivo
        $$.n = crearNodoNoTerminal($1.n, $2.n, 7);
    }
;

//PRODUCCION "sentencia", puede estar formado por asignaciones, condicionales, bucles whiles, imprimir
//D --> A | I 
sentencia:   //Por defecto bison, asigna $1 a $$ por lo que no es obligatoria realizar la asignacion
    asignacion                  
    | imprimir      
    | bucle_w       
    | bucle_f       
    | condicion_if      
;

//-------------------------------------------------------- ASIGNACION --------------------------------------------------------
//PRODUCCION "asignacion", formado por un identificador, un igual y una expresion
//A --> id = E 
asignacion:
    IDENTIFICADOR IGUAL expresion {
        printf("> Asignacion\n");

        //Para crear un nuevo simbolo de tipo numerico
        if(strcmp($3.tipo, tipos[0]) == 0){ //comprobacion si es numerico
            printf("Asignado a la variable el valor %d\n",$3.numerico);
            tabla[indice].nombre = $1; 
            tabla[indice].tipo = tipos[0]; 
            tabla[indice].numerico = $3.numerico;
            tabla[indice].registro = $3.n->resultado;
            
            indice++; //incrementamos el valor del inidice para pasar a la siguiente posicion y dejar la anterior guardada
        }
        //Para crear un nuevo simbolo de tipo numericoDecimal
        else if(strcmp($3.tipo, tipos[1]) == 0){ //comprobacion si es numericoDecimal
            printf("Asignado a la variable el valor %d\n",$3.numericoDecimal);
            tabla[indice].nombre = $1; 
            tabla[indice].tipo = tipos[1]; 
            tabla[indice].numericoDecimal = $3.numericoDecimal; 
            tabla[indice].registro = $3.n->resultado;

            indice++; //incrementamos el valor del inidice para pasar a la siguiente posicion y dejar la anterior guardada
        }
        
        //Para crear un nuevo simbolo de tipo texto
        else if (strcmp($3.tipo, tipos[2]) == 0){ //comprobacion si es texto
            printf("Asignado a la variable el valor %s\n",$3.texto);
            tabla[indice].nombre = $1; 
            tabla[indice].tipo = tipos[2];
            tabla[indice].texto = $3.texto;
            tabla[indice].registro = $3.n->resultado;

            indice++;
        }
        //Para crear un nuevo simbolo de tipo array
        else if (strcmp($3.tipo, tipos[4]) == 0){ //comprobacion si es array
            printf("Asignado a la variable el valor %d\n", $3.miarray->valores[1]);
            tabla[indice].nombre = $1; 
            tabla[indice].tipo = tipos[4];
            tabla[indice].arrayNumerico = $3.miarray->valores;
            tabla[indice].tamano = $3.miarray->size;
            tabla[indice].registro = $3.n->resultado;

            indice++;
        }

        // Control de errores
        else{
            yyerror("*** ERROR No es ninguno de los tipos definidos ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
        
        $$.n=crearNodoNoTerminal($3.n, crearNodoVacio(), 5);
        

    }
;


//-----------------------------------------------  EXPRESION ---------------------------------------------
//PRODUCCION "expresion", en esta gramática se representa la suma, resta y otros terminos
//E --> E op T | T
expresion:
    
    //SUMA
    expresion SUMA tipos {

        //Suma de numerico + numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) { //comprobacion del tipo
            printf("> Suma {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 2); 
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico + $3.numerico;
            $$.n->tipo = tipos[0];
        }

        //Suma de numericoDecimal + numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> Suma {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 2);
            $$.tipo = tipos[1];
            $$.n->tipo = tipos[1];
            $$.numericoDecimal = $1.numericoDecimal + $3.numericoDecimal;
        }

        //Suma de texto + texto
        else if (strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2]) == 0) {  //comprobacion del tipo
            printf("> Concatenacion {texto / texto}\n");


            char *cadenaUnificada = malloc(strlen($1.n->valorNodo.valorString) + strlen($3.n->valorNodo.valorString) + 2);

            strcpy(cadenaUnificada, $1.n->valorNodo.valorString);
            strcat(cadenaUnificada, "");
            strcat(cadenaUnificada, $3.n->valorNodo.valorString);
            
            $$.n = crearNodoNoTerminal($1.n, $3.n, 2);
            $$.n->tipo = tipos[2];

            
            $$.tipo = tipos[2];

            $$.n->valorNodo.valorString = cadenaUnificada;
            $$.texto = cadenaUnificada;

            // variables[$$.n->resultado].texto = cadenaUnificada;
            // variables[$$.n->resultado].nombre = $$.n->nombreVar;
            // variables[$$.n->resultado].registro = $$.n->resultado;
            // variables[$$.n->resultado].disponible = true;

            // for (int i = 0; i < 64; i++){
            //     printf("\nValor de las variable en la posicion %d: %s\n", i, variables[i].texto);
            // }

        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en SUMA ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }

    }
    //RESTA
    | expresion RESTA tipos {
        
        //Resta de numerico - numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> Resta {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 3);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico - $3.numerico;
        }
        //Resta de numericoDecimal - numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> Resta {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 3);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal - $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en RESTA ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }
    //MULTIPLICACION
    | expresion MULTIPLICACION tipos {
        
        //Multiplicación de numerico * numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> Multiplicacion {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 9);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico * $3.numerico;
        }
        //Multiplicación de numericoDecimal * numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> Multiplicacion {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 9);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal * $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en MULTIPLICACION ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }
    //DIVISION
    | expresion DIVISION tipos {
        
        //DIVISION de numerico * numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> Division {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 8);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico / $3.numerico;
        }
        //DIVISION de numericoDecimal * numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> Division {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 8);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal / $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en division ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }
    //MAYORREL
    | expresion MAYORREL tipos {
        
        //MAYORREL de numerico > numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> --logic--> MAYORREL {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 10);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico > $3.numerico;
        }
        //MAYORREL de numericoDecimal > numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> --logic--> MAYORREL {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 10);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal > $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en MAYOR QUE ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }
    //MAYORIGUALREL
    | expresion MAYORIGUALREL tipos {
        
        //MAYORIGUALREL de numerico > numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> --logic--> MAYORIGUALREL {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 11);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico >= $3.numerico;
        }
        //MAYORIGUALREL de numericoDecimal > numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> --logic--> MAYORIGUALREL {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 11);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal >= $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en MAYOR O IGUAL QUE ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }
    //MENORREL
    | expresion MENORREL tipos {
        
        //MENORREL de numerico > numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> --logic--> MENORREL {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 12);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico < $3.numerico;
        }
        //MENORREL de numericoDecimal > numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> --logic--> MENORREL {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 12);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal < $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en MENOR QUE ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }
    //MENORIGUALREL
    | expresion MENORIGUALREL tipos {
        
        //MENORIGUALREL de numerico > numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> --logic--> MENORIGUALREL {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 13);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico <= $3.numerico;
        }
        //MENORIGUALREL de numericoDecimal > numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> --logic--> MENORIGUALREL {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 13);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal <= $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en MENOR O IGUAL QUE ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }//IGUALREL
    | expresion IGUALREL tipos {
        
        //IGUALREL de numerico == numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> --logic--> IGUALDAD {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 14);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico == $3.numerico;
        }
        //IGUALREL de numericoDecimal == numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> --logic--> IGUALDAD {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 14);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal == $3.numericoDecimal;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en IGUAL IGUAL ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }//NOIGUALREL
    | expresion NOIGUALREL tipos {
        
        //NOIGUALREL de numerico != numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> --logic--> NOIGUALREL {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 15);
            $$.tipo = tipos[0]; 
            $$.numerico = $1.numerico != $3.numerico;
        }
        //NOIGUALREL de numericoDecimal != numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> --logic--> NOIGUALREL {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 15);
            $$.tipo = tipos[1]; 
            $$.numericoDecimal = $1.numericoDecimal != $3.numericoDecimal;
        }
        //NOIGUALREL de string != string (texto)
        else if (strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2]) == 0){  //comprobacion del tipo
            printf("> --logic--> NOIGUALREL {texto / texto}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 15);
            $$.tipo = tipos[2]; 
            $$.texto = $1.texto != $3.texto;
        }
        // Control de errores
        else{
            yyerror("*** Ha ocurrido un ERROR en DISTINTO DE ***");
            printf("Linea de ERROR: %d\n", num_linea);
        }
    }
        //AND
    | expresion AND tipos {
            
            //AND de numerico > numerico
            if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
                printf("> --logic--> AND {numerico / numerico}\n");
                $$.n = crearNodoNoTerminal($1.n, $3.n, 16);
                $$.tipo = tipos[0]; $$.numerico = $1.numerico && $3.numerico;
            }
            //AND de numericoDecimal > numericoDecimal
            else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
                printf("> --logic--> AND {numericoDecimal / numericoDecimal}\n");
                $$.n = crearNodoNoTerminal($1.n, $3.n, 16);
                $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal && $3.numericoDecimal;
            }

        
    }
    //OR
    | expresion OR tipos {
            
            //OR de numerico > numerico
            if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
                printf("> --logic--> OR {numerico / numerico}\n");
                $$.n = crearNodoNoTerminal($1.n, $3.n, 17);
                $$.tipo = tipos[0]; 
                $$.numerico = $1.numerico || $3.numerico;
            }
            //OR de numericoDecimal > numericoDecimal
            else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
                printf("> --logic--> OR {numericoDecimal / numericoDecimal}\n");
                $$.n = crearNodoNoTerminal($1.n, $3.n, 17);
                $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal || $3.numericoDecimal;
            }
    }
    // POSICION DEL ARRAY
    | IDENTIFICADOR APERTURACORCHETE expresion CIERRECORCHETE {
        printf("> --logic--> GUARDAR POSICION DEL ARRAY \n");
        int pos = buscarTabla(indice, $1, tabla);
        printf("Posicion encontrada en la tabla : %d con el nombre de %s\n", pos, tabla[pos].nombre);
        // int *arrayEncontrado = tabla[pos].arrayNumerico;

        $$.tipo = tipos[0];
        $$.numerico = tabla[pos].arrayNumerico[$3.numerico+1];
        $$.n = crearNodoTerminal($$.numerico, tipos[0]);
    }


    //PARA ARRAY
    | APERTURACORCHETE elements CIERRECORCHETE {
        printf("> --logic--> - ARRAY \n");
        arrays[array_count].valores = $2;
        arrays[array_count].size = $2[0];

        printf("Array de tamanio %d\n", $2[0]);
        for (int i = 1; i <= $2[0]; i++) {
            printf("%d ", $2[i]);
        }
        printf("\n");
        $$.tipo = tipos[4];
        $$.miarray = &arrays[array_count];
        $$.n = crearNodoTerminalArray($$.miarray->valores, tipos[4]);
        array_count++;  // Incrementamos el contador de arrays
        
    }

    | tipos {$$ = $1;} //la produccion operacion puede ser tipos, un subnivel para realizar la jerarquia de operaciones
;



elements:
    /* Handle an array of numbers */
    NUMERICO {
        int* array = malloc(2 * sizeof(int));
        array[0] = 1;
        array[1] = $1;
        $$ = array;
    }
    | elements COMA NUMERICO {
        int* array = realloc($1, ($1[0] + 2) * sizeof(int));
        array[0]++;
        array[array[0]] = $3;
        $$ = array;
    }
    ;




//-----------------------------------------------  TIPOS  ---------------------------------------------
/*PRODUCCION "tipos", en esta gramática se represetan los tipos de datos:
- identificadores (variables) - numeros enteros o decimales positivos o negativos
- cadenas de texto - estructura parentesis
T --> id | num | numdecimal */
tipos:

    //Identificador
    IDENTIFICADOR {
        printf(" <-- IDENTIFICADOR %s\n",$1);
        //Buscamos en la tabla el identificador
        if(buscarTabla(indice, $1, tabla) != -1){     //En este IF entra si buscarTabla devuelve la posicion
            int pos = buscarTabla(indice, $1, tabla);
            //Para si es de tipo numerico
            if(tabla[pos].tipo==tipos[0]){
                $$.tipo = tabla[pos].tipo; 
                $$.numerico=tabla[pos].numerico; 
                $$.n = crearVariableTerminal(tabla[pos].numerico, tabla[pos].registro, tabla[pos].tipo);  //Creamos un nodo terminal con los numeros   
            }
            //Para si es de tipo numericoDecimal
            else if(tabla[pos].tipo==tipos[1]){
                $$.tipo = tabla[pos].tipo; $$.numericoDecimal=tabla[pos].numericoDecimal;
                $$.n = crearVariableTerminal(tabla[pos].numericoDecimal, tabla[pos].registro, tabla[pos].tipo); //Creamos un nodo terminal con los numeros        
            }
            //Para si es de tipo texto
            else if (tabla[pos].tipo==tipos[2]){
                $$.tipo = tabla[pos].tipo; 
                $$.n = crearVariableTerminalString(tabla[pos].texto, tabla[pos].registro, tabla[pos].tipo); //Creamos un nodo terminal con las cadenas{
            }
            //Para si es de tipo array
            else if (tabla[pos].tipo==tipos[4]){
                $$.tipo = tabla[pos].tipo;
                $$.n = crearVariableTerminalArray(tabla[pos].arrayNumerico, tabla[pos].registro, tabla[pos].tipo); //Creamos un nodo terminal con las cadenas{
            }
        }
    }

    //Numero entero normal
    | NUMERICO {
        $$.numerico = $1;
        printf("\n> Tipo int: %d\n", $$.numerico);
        
        $$.tipo = tipos[0];

        $$.n = crearNodoTerminal($1, tipos[0]);
        
    }

    //Numero decimal normal
    | NUMERICODECIMAL {
        $$.numericoDecimal = $1;
        printf("\n> Tipo double: %.3f\n", $$.numericoDecimal); 

        $$.tipo = tipos[1];

        $$.n = crearNodoTerminal($1, tipos[1]); 
    }

    //Cadena de texto
    | CADENA {
        $$.texto = $1;
        printf("\n> Tipo String: %s\n", $1);

        $$.tipo = tipos[2];

        $$.n = crearNodoTerminalString($1, tipos[2]);
    }
;

//-----------------------------------------------  IMPRIMIR  ---------------------------------------------
//Representa la estructura del print en lenguaje python
//I --> imprimir ( E ) 
imprimir: 
    IMPRIMIR APERTURAPARENTESIS expresion CIERREPARENTESIS { 
        printf(">  Funcion Imprimir \n");

        $$.n = crearNodoNoTerminal($3.n, crearNodoVacio(), 4);

        if (strcmp($3.n->tipo, "numerico") == 0) {
            printf("Resultado del print es: %.0f\n", $$.n->izq->valorNodo.valorDouble);
        } else if (strcmp($3.n->tipo, "numericoDecimal") == 0) {
            printf("Resultado del print es: %.3f\n", $$.n->izq->valorNodo.valorDouble);
        } else if (strcmp($3.n->tipo, "texto") == 0) {
            printf("Resultado del print es: %s\n", $$.n->izq->valorNodo.valorString);
        } else if (strcmp($3.n->tipo, "array") == 0) {
            printf("Resultado del print es: %d\n", $$.n->izq->valorNodo.array);
        }
        
    
    }
;


//-----------------------------------------------  BUCLE WHILE ---------------------------------------------
//Representa la estructura del bucle while en lenguaje python
//W --> while ( E ): S 'fin_bucle'
bucle_w:
    WHILE APERTURAPARENTESIS expresion CIERREPARENTESIS DOSPUNTOS sentencias ENDWHILE {
        printf("> Bucle While\n");
        $$.n = crearNodoNoTerminal($3.n, $6.n, 21); // 21 es el numero del while
    }

;

//-----------------------------------------------  BUCLE FOR ---------------------------------------------
//Representa la estructura del bucle for en lenguaje PYTHON
//F --> for E in range ( E ): S 'fin_bucle'
bucle_f:
    FOR IDENTIFICADOR IN RANGE APERTURAPARENTESIS expresion CIERREPARENTESIS DOSPUNTOS sentencias ENDFOR {
        printf("> Bucle For\n");
        $$.n = crearNodoNoTerminal($6.n, $9.n, 22); // 22 es el numero del for
    }

;

//-----------------------------------------------  CONDICION IF ---------------------------------------------
//Representa la estructura de la condicion if en lenguaje python
//IF --> if ( E ): S else: S 'fin_conndicion'
condicion_if:
    IF APERTURAPARENTESIS expresion CIERREPARENTESIS DOSPUNTOS sentencias elif_clauses else_clause ENDIF {
        printf("> Condicional If\n");
        if($3.numerico == 1){
            $$.n = crearNodoNoTerminal($6.n, crearNodoVacio(), 7); // 7 is the number for if
        } else if ($7.numerico == 1) {
            $$.n = crearNodoNoTerminal($7.n, crearNodoVacio(), 7); // 7 is the number for elif
        } else {
            $$.n = crearNodoNoTerminal($8.n, crearNodoVacio(), 7); // 7 is the number for else
        }
    }
    ;

elif_clauses:
    /* empty */ {
        $$.numerico = 0;
    }
    | elif_clauses ELIF APERTURAPARENTESIS expresion CIERREPARENTESIS DOSPUNTOS sentencias {
        printf("> Condicional Elif\n");
        if($4.numerico == 1){
            $$.numerico = 1;
            $$.n = crearNodoNoTerminal($7.n, crearNodoVacio(), 7); // 7 is the number for elif
        }
    }
    ;

else_clause:
    ELSE DOSPUNTOS sentencias {
        $$.n = $3.n;
    }
    | /* empty */ {
        $$.n = crearNodoVacio();
    }
    ;





%% 

//------------------------------- METODO MAIN ---------------------------
int main(int argc, char** argv) {
    if(argc < 2) {
        fprintf(stderr, "Uso: %s <archivo de entrada>\n", argv[0]);
        return 1;
    }
    
    yyin = fopen(argv[1], "rt"); // Apertura del archivo codigo.py
    if(yyin == NULL) {
        perror("Error al abrir el archivo de entrada");
        return 1;
    }

    char* input_filename = argv[1];
    char* output_filename = malloc(strlen(input_filename) + 4); // Suficiente espacio para cambiar la extensión
    if(output_filename == NULL) {
        perror("Error al asignar memoria");
        fclose(yyin);
        return 1;
    }

    strcpy(output_filename, input_filename);
    char* dot = strrchr(output_filename, '.');
    if(dot != NULL) {
        strcpy(dot, ".asm");
    } else {
        strcat(output_filename, ".asm");
    }

    yyout = fopen(output_filename, "wt");  // Para el archivo .ASM
    if(yyout == NULL) {
        perror("Error al abrir el archivo de salida");
        free(output_filename);
        fclose(yyin);
        return 1;
    }

    yyparse();

    fclose(yyin);
    fclose(yyout);
    free(output_filename);

    return 0;
}


#define RED     "\x1b[31m"
#define RESET   "\x1b[0m"
//Metodo yyerror, generado por defecto
void yyerror(const char* s) {
    fprintf(stderr, "\n--------------------------------------------------------\n");
    fprintf(stderr, "Linea de ERROR: %d: %s", num_linea, s);
    fprintf(stderr, "\n--------------------------------------------------------\n\n");
}
