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
char* tipos[] = {"numerico", "numericoDecimal", "texto", "bool"}; //Para parsear el tipo que se detecta en flex al tipo del nodo

void yyerror(const char* s);
int yylex(void);

%}

/*Definicion de tipos y estructuras empleadas*/
%union {
  int enteroVal;
  float realVal;
  char* stringVal;
  struct atributos{
    int numerico;
    float numericoDecimal;
    char* texto;
    char* tipo;             //Define el tipo que se esta usando
    char* cadena;           // Añadir el miembro cadena
    struct ast *n;          //Para almacenar los nodos del AST
  }tr;
}

/*Declaración de los TOKENS*/
%token SUMA RESTA MULTIPLICACION DIVISION IGUAL APERTURAPARENTESIS CIERREPARENTESIS IMPRIMIR IGUALREL NOIGUALREL MENORREL MAYORREL MENORIGUALREL MAYORIGUALREL ENDIF AND OR DOSPUNTOS IF ELSE

/*Declaración de los TOKENS que provienen de FLEX con su respectivo tipo*/
%token <enteroVal> NUMERICO 
%token <realVal> NUMERICODECIMAL 
%token <stringVal> IDENTIFICADOR CADENA


/*Declaración de los TOKENS NO TERMINALES con su estructura*/
%type <tr> sentencias sentencia tipos expresion asignacion imprimir condicional logic_expr 

/*Declaración de la precedencia siendo menor la del primero y mayor la del último*/
%left SUMA RESTA MULTIPLICACION DIVISION IGUALREL NOIGUALREL MENORREL MAYORREL MENORIGUALREL MAYORIGUALREL


%start codigo
%%

//GRAMATICA
//X --> S
//S --> D | S D
//D --> A | I | C
//A --> id = E 
//C --> if ( B ) { S } [else { S }]
//E --> E op T | T
//B --> T oprel T
//T --> id | num | numdecimal | cadena
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
    sentencia
    | sentencias sentencia { //para hacerlo recursivo
        $$.n = crearNodoNoTerminal($1.n, $2.n, 7);
    }
;

//PRODUCCION "sentencia", puede estar formado por asignaciones, condicionales, bucles whiles, imprimir
//D --> A | I 
sentencia:   //Por defecto bison, asigna $1 a $$ por lo que no es obligatoria realizar la asignacion
    asignacion              
    | imprimir
    | condicional       
;

//-------------------------------------------------------- ASIGNACION --------------------------------------------------------
//PRODUCCION "asignacion", formado por un identificador, un igual y una expresion
//A --> id = E 
asignacion:
    IDENTIFICADOR IGUAL expresion {
        printf("> [SENTENCIA] - Asignacion\n");

        //Para crear un nuevo simbolo de tipo numerico
        if(strcmp($3.tipo, tipos[0]) == 0){ //comprobacion si es numerico
        printf("Asignado el valor %d a la variable\n",$3.numerico);
        tabla[indice].nombre = $1; tabla[indice].tipo = tipos[0]; tabla[indice].numerico = $3.numerico; tabla[indice].registro = $3.n->resultado;
        indice++; //incrementamos el valor del inidice para pasar a la siguiente posicion y dejar la anterior guardada
        }
        //Para crear un nuevo simbolo de tipo numericoDecimal
        else if(strcmp($3.tipo, tipos[1]) == 0){ //comprobacion si es numericoDecimal
        printf("Asignado el valor %d a la variable\n",$3.numericoDecimal);
        tabla[indice].nombre = $1; tabla[indice].tipo = tipos[1]; tabla[indice].numericoDecimal = $3.numericoDecimal; tabla[indice].registro = $3.n->resultado;
        indice++; //incrementamos el valor del inidice para pasar a la siguiente posicion y dejar la anterior guardada
        }
        //Para crear un nuevo simbolo de tipo cadena
        else if (strcmp($3.tipo, tipos[2]) == 0) { // comprobacion si es cadena
            printf("Asignado el valor %s a la variable\n", $3.cadena);
            tabla[indice].nombre = $1; tabla[indice].tipo = tipos[2]; tabla[indice].cadena = $3.cadena; tabla[indice].registro = $3.n->resultado;
            indice++; // incrementamos el valor del inidice para pasar a la siguiente posicion y dejar la anterior guardada
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
            printf("> [OPERACION] - SUMA {numerico + numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 2); 
            $$.tipo = tipos[0]; $$.numerico = $1.numerico + $3.numerico;      
        }

        //Suma de numericoDecimal + numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> [OPERACION] - SUMA {numericoDecimal + numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 2);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal + $3.numericoDecimal;
        }
        //Concatenación de cadenas
        else if (strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2]) == 0) { // comprobacion del tipo
            printf("> [OPERACION] - CONCATENACION {cadena + cadena}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 10);
            $$.cadena = concatenarCadenas($1.cadena, $3.cadena);
            $$.tipo = tipos[2];
        }
    }
    //RESTA
    | expresion RESTA tipos {
        
        //Resta de numerico - numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> [OPERACION] - RESTA {numerico - numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 3);
            $$.tipo = tipos[0]; $$.numerico = $1.numerico - $3.numerico;
        }
        //Resta de numericoDecimal - numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> [OPERACION] - RESTA {numericoDecimal - numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 3);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal - $3.numericoDecimal;
        }
    }
    // MULTIPLICACION
    | expresion MULTIPLICACION tipos {
        // Multiplicación de numerico * numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) { // comprobación del tipo
            printf("> [OPERACION] - MULTIPLICACION {numerico * numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 8);
            $$.tipo = tipos[0]; $$.numerico = $1.numerico * $3.numerico;
        }
        // Multiplicación de numericoDecimal * numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){ // comprobación del tipo
            printf("> [OPERACION] - MULTIPLICACION {numericoDecimal * numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 8);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal * $3.numericoDecimal;
        }
    }
    // DIVISION
    | expresion DIVISION tipos {
        // División de numerico / numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) { // comprobación del tipo
            printf("> [OPERACION] - DIVISION {numerico / numerico}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 9);
            $$.tipo = tipos[0]; $$.numerico = $1.numerico / $3.numerico;
        }
        // División de numericoDecimal / numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){ // comprobación del tipo
            printf("> [OPERACION] - DIVISION {numericoDecimal / numericoDecimal}\n");
            $$.n = crearNodoNoTerminal($1.n, $3.n, 9);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal / $3.numericoDecimal;
        }
    }
    
    | tipos {$$ = $1;} //la produccion operacion puede ser tipos, un subnivel para realizar la jerarquia de operaciones
;

//-----------------------------------------------  CONDICIONAL  ---------------------------------------------
// Producción para el if
//C --> if ( B ): I ENDIF
condicional:
    IF APERTURAPARENTESIS logic_expr CIERREPARENTESIS DOSPUNTOS sentencias ENDIF{
        printf("> [SENTENCIA] - IF\n");
        $$.n = crearNodoIf($3.n, $6.n, crearNodoVacio());
    }
    | IF APERTURAPARENTESIS logic_expr CIERREPARENTESIS DOSPUNTOS sentencias ELSE DOSPUNTOS sentencias ENDIF {
        printf("> [SENTENCIA] - IF-ELSE\n");
        $$.n = crearNodoIf($3.n, $6.n, $9.n);
    }
;

//-----------------------------------------------  EXPRESION LOGICA ---------------------------------------------
// Definición de expresiones lógicas para el if
logic_expr:
      expresion IGUALREL expresion {
          printf("> [OPERACION] - IGUALDAD\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 11); // 11 es el tipo de nodo para igualdad
      }
    | expresion NOIGUALREL expresion {
          printf("> [OPERACION] - DESIGUALDAD\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 12); // 12 es el tipo de nodo para desigualdad
      }
    | expresion MENORREL expresion {
          printf("> [OPERACION] - MENOR QUE\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 13); // 13 es el tipo de nodo para menor que
      }
    | expresion MAYORREL expresion {
          printf("> [OPERACION] - MAYOR QUE\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 14); // 14 es el tipo de nodo para mayor que
      }
    | expresion MENORIGUALREL expresion {
          printf("> [OPERACION] - MENOR O IGUAL QUE\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 15); // 15 es el tipo de nodo para menor o igual que
      }
    | expresion MAYORIGUALREL expresion {
          printf("> [OPERACION] - MAYOR O IGUAL QUE\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 16); // 16 es el tipo de nodo para mayor o igual que
      }
    | expresion AND expresion {
          printf("> [OPERACION] - AND\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 17); // 17 es el tipo de nodo para AND
      }
    | expresion OR expresion {
          printf("> [OPERACION] - OR\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 18); // 18 es el tipo de nodo para OR
      }
;

//-----------------------------------------------  TIPOS  ---------------------------------------------
/*PRODUCCION "tipos", en esta gramática se represetan los tipos de datos:
- identificadores (variables) - numeros enteros o decimales positivos o negativos
- cadenas de texto - estructura parentesis
T --> id | num | numdecimal | cadena*/
tipos:

    //Identificador
    IDENTIFICADOR {
        printf(" IDENTIFICADOR %s\n",$1);
        //Buscamos en la tabla el identificador
        if(buscarTabla(indice, $1, tabla) != -1){     //En este IF entra si buscarTabla devuelve la posicion
            int pos = buscarTabla(indice, $1, tabla);
            //Para si es de tipo numerico
            if(tabla[pos].tipo==tipos[0]){
                $$.tipo = tabla[pos].tipo; $$.numerico=tabla[pos].numerico; 
                $$.n = crearVariableTerminal(tabla[pos].numerico, tabla[pos].registro); // Creamos un nodo terminal con los numeros   
            }
            //Para si es de tipo numericoDecimal
            else if(tabla[pos].tipo==tipos[1]){
                $$.tipo = tabla[pos].tipo; $$.numericoDecimal=tabla[pos].numericoDecimal;
                $$.n = crearVariableTerminal(tabla[pos].numericoDecimal, tabla[pos].registro); // Creamos un nodo terminal con los numeros        
            }
            //Para si es de tipo cadena
            else if (tabla[pos].tipo == tipos[2]) {
                $$.tipo = tabla[pos].tipo; $$.cadena = tabla[pos].cadena;
                $$.n = crearVariableTerminalC(tabla[pos].cadena, tabla[pos].registro); // Creamos un nodo terminal con las cadenas
            }
        }
    }

    //Numero entero normal
    | NUMERICO {
        $$.numerico = $1;
        printf("\n> [TIPO] - Numerico Positivo: %ld\n", $$.numerico);
        $$.n = crearNodoTerminal($1);  
        $$.tipo = tipos[0]; 
    }

    //Numero decimal normal
    | NUMERICODECIMAL {
        $$.numericoDecimal = $1;
        printf("\n> [TIPO] - NumericoDecimal: %.3f\n", $$.numericoDecimal); 
        $$.n = crearNodoTerminal($1);  
        $$.tipo = tipos[1];  
    }
    //Cadena de texto
    | CADENA {
        $$.cadena = $1;
        printf("\n> [TIPO] - Cadena: %s\n", $$.cadena);
        $$.n = crearNodoTerminalC($1);
        $$.tipo = tipos[2];
    }
;

//-----------------------------------------------  IMPRIMIR  ---------------------------------------------
//Representa la estructura del print en lenguaje latino
//I --> print ( E ) 
imprimir: 
    IMPRIMIR APERTURAPARENTESIS expresion CIERREPARENTESIS { 
        printf("> [SENTENCIA] - Imprimir\n");
        $$.n = crearNodoNoTerminal($3.n, crearNodoVacio(), 4);        
    }
;

%% 

//--------------------------------------------------- METODO MAIN -----------------------------------------------
int main(int argc, char** argv) {
    yyin = fopen(argv[1], "rt");            //Apertura del archivo codigo.latino
    yyout = fopen( "./latino.asm", "wt" );  //Para el archivo .ASM con nombre "latino.asm"
	yyparse();
    fclose(yyin);
    return 0;
}

//Metodo yyerror, generado por defecto
void yyerror(const char* s) {
    fprintf(stderr, "%s\n", s);
}