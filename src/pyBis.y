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
    double* valores;        // Para arrays
    int tamano;             // Para el tamaño de los arrays
    double** valores2d;     // Para arrays 2D
  }tr;
}

/*Declaración de los TOKENS*/
%token ARRAY APERTURA_CORCHETE CIERRE_CORCHETE COMA
%token SUMA RESTA MULTIPLICACION DIVISION IGUAL APERTURAPARENTESIS CIERREPARENTESIS IMPRIMIR IGUALREL NOIGUALREL MENORREL MAYORREL MENORIGUALREL MAYORIGUALREL ENDIF AND OR DOSPUNTOS IF ELSE

/*Declaración de los TOKENS que provienen de FLEX con su respectivo tipo*/
%token <enteroVal> NUMERICO 
%token <realVal> NUMERICODECIMAL 
%token <stringVal> IDENTIFICADOR CADENA


/*Declaración de los TOKENS NO TERMINALES con su estructura*/
%type <tr> sentencias sentencia tipos expresion asignacion imprimir condicional logic_expr array_declaration array_usage array_element array_elements array_2d_elements

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
//D --> A | I | C
sentencia:   //Por defecto bison, asigna $1 a $$ por lo que no es obligatoria realizar la asignacion
    asignacion              
    | imprimir
    | condicional
    | array_declaration
    | array_usage       
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
            quitarComillas($3.cadena);
            printf("Asignado el valor \"%s\" a la variable\n", $3.cadena);
            tabla[indice].nombre = $1; tabla[indice].tipo = tipos[2]; tabla[indice].cadena = $3.cadena; tabla[indice].registro = $3.n->resultado;
            indice++; // incrementamos el valor del inidice para pasar a la siguiente posicion y dejar la anterior guardada
        }
        $$.n=crearNodoNoTerminal($3.n, crearNodoVacio(), 5);
    }
;

//-------------------------------------------------------- ARRAY --------------------------------------------------------
// Producción "declaración de array"
// Producción "declaración de array"
array_declaration:
    IDENTIFICADOR IGUAL APERTURA_CORCHETE array_elements CIERRE_CORCHETE {
        printf("> [SENTENCIA] - Declaracion de Array\n");
        int size = $4.tamano;
        double* values = $4.valores;
        tabla[indice].nombre = $1;
        tabla[indice].tipo = "array";
        tabla[indice].array_size = size;
        tabla[indice].array_values = values;
        $$.n = crearNodoArray(values, size);
        indice++;
    }
    | IDENTIFICADOR IGUAL APERTURA_CORCHETE array_2d_elements CIERRE_CORCHETE {
        printf("> [SENTENCIA] - Declaracion de Array 2D\n");
        int size = $4.tamano;
        double** values = $4.valores2d;
        tabla[indice].nombre = $1;
        tabla[indice].tipo = "array2d";
        tabla[indice].array_size = size;
        tabla[indice].array_values_2d = values;
        $$.n = crearNodoArray2D(values, size);
        indice++;
    }
;


// Producción "uso de array"
array_usage:
    IDENTIFICADOR APERTURA_CORCHETE NUMERICO CIERRE_CORCHETE IGUAL expresion {
        printf("> [SENTENCIA] - Uso de Array\n");
        int pos = buscarTabla(indice, $1, tabla);
        if (pos != -1 && strcmp(tabla[pos].tipo, "array") == 0) {
            if ($3 < tabla[pos].array_size) {
                tabla[pos].array_values[$3] = $6.n->valor;
            } else {
                yyerror("Índice fuera de rango");
            }
        } else {
            yyerror("Variable no definida o no es un array");
        }
    }
    | IDENTIFICADOR APERTURA_CORCHETE NUMERICO CIERRE_CORCHETE APERTURA_CORCHETE NUMERICO CIERRE_CORCHETE IGUAL expresion {
        printf("> [SENTENCIA] - Uso de Array 2D\n");
        int pos = buscarTabla(indice, $1, tabla);
        if (pos != -1 && strcmp(tabla[pos].tipo, "array2d") == 0) {
            if ($3 < tabla[pos].array_size && $6 < tabla[pos].array_size) {
                tabla[pos].array_values_2d[$3][$6] = $9.n->valor;
            } else {
                yyerror("Índice fuera de rango");
            }
        } else {
            yyerror("Variable no definida o no es un array 2D");
        }
    }
;

// Producción "elemento de array"
array_element:
    IDENTIFICADOR APERTURA_CORCHETE NUMERICO CIERRE_CORCHETE {
        int pos = buscarTabla(indice, $1, tabla);
        if (pos != -1 && strcmp(tabla[pos].tipo, "array") == 0) {
            if ($3 < tabla[pos].array_size) {
                $$.n = crearNodoTerminal(tabla[pos].array_values[$3]);
            } else {
                yyerror("Índice fuera de rango");
            }
        } else {
            yyerror("Variable no definida o no es un array");
        }
    }
    | IDENTIFICADOR APERTURA_CORCHETE NUMERICO CIERRE_CORCHETE APERTURA_CORCHETE NUMERICO CIERRE_CORCHETE {
        int pos = buscarTabla(indice, $1, tabla);
        if (pos != -1 && strcmp(tabla[pos].tipo, "array2d") == 0) {
            if ($3 < tabla[pos].array_size && $6 < tabla[pos].array_size) {
                $$.n = crearNodoTerminal(tabla[pos].array_values_2d[$3][$6]);
            } else {
                yyerror("Índice fuera de rango");
            }
        } else {
            yyerror("Variable no definida o no es un array 2D");
        }
    }
;

// Producción "elementos de array"
array_elements:
    expresion {
        $$.valores = malloc(sizeof(double));
        $$.valores[0] = $1.n->valor;
        $$.tamano = 1;
    }
    | array_elements COMA expresion {
        int newSize = $1.tamano + 1;
        $$.valores = realloc($1.valores, sizeof(double) * newSize);
        $$.valores[$1.tamano] = $3.n->valor;
        $$.tamano = newSize;
    }
;

// Producción "elementos de array 2D"
array_2d_elements:
    APERTURA_CORCHETE array_elements CIERRE_CORCHETE {
        $$.valores2d = malloc(sizeof(double*));
        $$.valores2d[0] = $2.valores;
        $$.tamano = 1;
    }
    | array_2d_elements COMA APERTURA_CORCHETE array_elements CIERRE_CORCHETE {
        int newSize = $1.tamano + 1;
        $$.valores2d = realloc($1.valores2d, sizeof(double*) * newSize);
        $$.valores2d[$1.tamano] = $4.valores;
        $$.tamano = newSize;
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
            printf("> Suma { %d + %d }\n", $1.numerico, $3.numerico);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 2); 
            $$.tipo = tipos[0]; $$.numerico = $1.numerico + $3.numerico;      
        }

        //Suma de numericoDecimal + numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> Suma { %.3f + %.3f }\n", $1.numericoDecimal, $3.numericoDecimal);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 2);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal + $3.numericoDecimal;
        }
        //Concatenación de cadenas
        else if (strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2]) == 0) { // comprobacion del tipo
            printf("> Concatenacion { %s + %s }\n", $1.cadena, $3.cadena);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 10);
            $$.cadena = concatenarCadenas($1.cadena, $3.cadena);
            $$.tipo = tipos[2];
        }
    }
    //RESTA
    | expresion RESTA tipos {
        
        //Resta de numerico - numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) {  //comprobacion del tipo
            printf("> Resta { %d - %d }\n", $1.numerico, $3.numerico);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 3);
            $$.tipo = tipos[0]; $$.numerico = $1.numerico - $3.numerico;
        }
        //Resta de numericoDecimal - numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){  //comprobacion del tipo
            printf("> Resta { %.3f - %.3f }\n", $1.numericoDecimal, $3.numericoDecimal);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 3);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal - $3.numericoDecimal;
        }
    }
    // MULTIPLICACION
    | expresion MULTIPLICACION tipos {
        // Multiplicación de numerico * numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) { // comprobación del tipo
            printf("> Multiplicación { %d * %d }\n", $1.numerico, $3.numerico);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 8);
            $$.tipo = tipos[0]; $$.numerico = $1.numerico * $3.numerico;
        }
        // Multiplicación de numericoDecimal * numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){ // comprobación del tipo
            printf("> Multiplicación { %.3f * %.3f }\n", $1.numericoDecimal, $3.numericoDecimal);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 8);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal * $3.numericoDecimal;
        }
    }
    // DIVISION
    | expresion DIVISION tipos {
        // División de numerico / numerico
        if (strcmp($1.tipo, tipos[0]) == 0 && strcmp($3.tipo, tipos[0]) == 0) { // comprobación del tipo
            printf("> División { %d / %d }\n", $1.numerico, $3.numerico);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 9);
            $$.tipo = tipos[0]; $$.numerico = $1.numerico / $3.numerico;
        }
        // División de numericoDecimal / numericoDecimal
        else if (strcmp($1.tipo, tipos[1]) == 0 && strcmp($3.tipo, tipos[1]) == 0){ // comprobación del tipo
            printf("> Division { %.3f / %.3f }\n", $1.numericoDecimal, $3.numericoDecimal);
            $$.n = crearNodoNoTerminal($1.n, $3.n, 9);
            $$.tipo = tipos[1]; $$.numericoDecimal = $1.numericoDecimal / $3.numericoDecimal;
        }
    }
    
    | tipos {$$ = $1;} //la produccion operacion puede ser tipos, un subnivel para realizar la jerarquia de operaciones
    | array_element {
        $$ = $1;
    }
;

//-----------------------------------------------  CONDICIONAL  ---------------------------------------------
// Producción para el if
//C --> if ( B ): I ENDIF
condicional:
    IF APERTURAPARENTESIS logic_expr CIERREPARENTESIS DOSPUNTOS sentencias ENDIF{
        printf("> Condicional IF\n");
        printf(" ---------------Resultado logico = %d\n", $3.n->boolean);
        if($3.n->boolean == 1){
            $$.n=$6.n;
        }else{
            $$.n=crearNodoVacio();
        }
        
    }
    | IF APERTURAPARENTESIS logic_expr CIERREPARENTESIS DOSPUNTOS sentencias ELSE DOSPUNTOS sentencias ENDIF {
        printf("> Condicional IF-ELSE\n");
        printf(" ---------------Resultado logico = %d\n", $3.n->boolean);
        if($3.n->boolean == 1){
            $$.n=$6.n;
        }else{
            $$.n=$9.n;
        }

        
    }
;

//-----------------------------------------------  EXPRESION LOGICA ---------------------------------------------
// Definición de expresiones lógicas para el if
logic_expr:

      expresion IGUALREL expresion {
        $$.n = crearNodoNoTerminal($1.n, $3.n, 11); // 11 es el tipo de nodo para igualdad
        printf("--logic--> IGUALDAD\n");
        if((strcmp($1.tipo, tipos[0]) == 0 ) && (strcmp($3.tipo, tipos[0])== 0)){
            printf("%d == %d ?\n", $1.numerico, $3.numerico);
           if($1.numerico == $3.numerico){
                $$.n->boolean = 1;
                printf("TRUE\n");
                
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 

        }else if((strcmp($1.tipo, tipos[1]) == 0) && (strcmp($3.tipo, tipos[1])== 0)){
            printf("%.3f == %.3f ?/n", $1.numericoDecimal, $3.numericoDecimal);
           if($1.numericoDecimal == $3.numericoDecimal){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if(strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2])){
            printf("%s == %s ?/n", $1.cadena, $3.cadena);
           if($1.cadena == $3.cadena){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[0]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[0])==0)){

            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numerico == tabla[buscarTabla(0,$3.n->cadena,tabla)].numerico){
                printf("%s == %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[1]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[1])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numericoDecimal == tabla[buscarTabla(0,$3.n->cadena,tabla)].numericoDecimal){
                printf("%s == %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[2]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[2])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].cadena == tabla[buscarTabla(0,$3.n->cadena,tabla)].cadena){
                printf("%s == %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }

        }
      }
    | expresion NOIGUALREL expresion {
          printf("--logic--> DESIGUALDAD\n");
        $$.n = crearNodoNoTerminal($1.n, $3.n, 12); // 11 es el tipo de nodo para igualdad
        if((strcmp($1.tipo, tipos[0]) == 0 ) && (strcmp($3.tipo, tipos[0])== 0)){
            printf("%d != %d ?\n", $1.numerico, $3.numerico);
           if($1.numerico != $3.numerico){
                $$.n->boolean = 1;
                printf("TRUE\n");
                
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 

        }else if((strcmp($1.tipo, tipos[1]) == 0) && (strcmp($3.tipo, tipos[1])== 0)){
            printf("%.3f != %.3f ?/n", $1.numericoDecimal, $3.numericoDecimal);
           if($1.numericoDecimal != $3.numericoDecimal){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if(strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2])){
            printf("%s != %s ?/n", $1.cadena, $3.cadena);
           if($1.cadena != $3.cadena){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[0]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[0])==0)){

            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numerico != tabla[buscarTabla(0,$3.n->cadena,tabla)].numerico){
                printf("%s != %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[1]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[1])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numericoDecimal != tabla[buscarTabla(0,$3.n->cadena,tabla)].numericoDecimal){
                printf("%s != %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[2]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[2])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].cadena != tabla[buscarTabla(0,$3.n->cadena,tabla)].cadena){
                printf("%s != %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }

        }
      }
    | expresion MENORREL expresion {
        printf("--logic--> MENOR QUE\n");
        $$.n = crearNodoNoTerminal($1.n, $3.n, 13); // 13 es el tipo de nodo para menor que
        if((strcmp($1.tipo, tipos[0]) == 0 ) && (strcmp($3.tipo, tipos[0])== 0)){
            printf("%d < %d ?\n", $1.numerico, $3.numerico);
           if($1.numerico < $3.numerico){
                $$.n->boolean = 1;
                printf("TRUE\n");
                
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 

        }else if((strcmp($1.tipo, tipos[1]) == 0) && (strcmp($3.tipo, tipos[1])== 0)){
            printf("%.3f < %.3f ?/n", $1.numericoDecimal, $3.numericoDecimal);
           if($1.numericoDecimal < $3.numericoDecimal){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if(strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2])){
            printf("%s < %s ?/n", $1.cadena, $3.cadena);
           if($1.cadena < $3.cadena){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[0]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[0])==0)){

            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numerico < tabla[buscarTabla(0,$3.n->cadena,tabla)].numerico){
                printf("%s < %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[1]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[1])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numericoDecimal < tabla[buscarTabla(0,$3.n->cadena,tabla)].numericoDecimal){
                printf("%s < %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[2]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[2])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].cadena < tabla[buscarTabla(0,$3.n->cadena,tabla)].cadena){
                printf("%s < %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }

        }
      }
    | expresion MAYORREL expresion {
          printf("--logic--> MAYOR QUE\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 14); // 14 es el tipo de nodo para mayor que
          if((strcmp($1.tipo, tipos[0]) == 0 ) && (strcmp($3.tipo, tipos[0])== 0)){
            printf("%d > %d ?\n", $1.numerico, $3.numerico);
           if($1.numerico > $3.numerico){
                $$.n->boolean = 1;
                printf("TRUE\n");
                
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 

        }else if((strcmp($1.tipo, tipos[1]) == 0) && (strcmp($3.tipo, tipos[1])== 0)){
            printf("%.3f > %.3f ?/n", $1.numericoDecimal, $3.numericoDecimal);
           if($1.numericoDecimal > $3.numericoDecimal){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if(strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2])){
            printf("%s > %s ?/n", $1.cadena, $3.cadena);
           if($1.cadena > $3.cadena){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[0]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[0])==0)){

            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numerico > tabla[buscarTabla(0,$3.n->cadena,tabla)].numerico){
                printf("%s > %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[1]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[1])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numericoDecimal > tabla[buscarTabla(0,$3.n->cadena,tabla)].numericoDecimal){
                printf("%s > %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[2]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[2])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].cadena > tabla[buscarTabla(0,$3.n->cadena,tabla)].cadena){
                printf("%s > %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }

        }
      }
    | expresion MENORIGUALREL expresion {
          printf("--logic--> MENOR O IGUAL QUE\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 15); // 15 es el tipo de nodo para menor o igual que
          if((strcmp($1.tipo, tipos[0]) == 0 ) && (strcmp($3.tipo, tipos[0])== 0)){
            printf("%d <= %d ?\n", $1.numerico, $3.numerico);
           if($1.numerico <= $3.numerico){
                $$.n->boolean = 1;
                printf("TRUE\n");
                
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 

        }else if((strcmp($1.tipo, tipos[1]) == 0) && (strcmp($3.tipo, tipos[1])== 0)){
            printf("%.3f <= %.3f ?/n", $1.numericoDecimal, $3.numericoDecimal);
           if($1.numericoDecimal <= $3.numericoDecimal){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if(strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2])){
            printf("%s <= %s ?/n", $1.cadena, $3.cadena);
           if($1.cadena <= $3.cadena){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[0]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[0])==0)){

            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numerico <= tabla[buscarTabla(0,$3.n->cadena,tabla)].numerico){
                printf("%s <= %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[1]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[1])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numericoDecimal <= tabla[buscarTabla(0,$3.n->cadena,tabla)].numericoDecimal){
                printf("%s <= %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[2]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[2])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].cadena <= tabla[buscarTabla(0,$3.n->cadena,tabla)].cadena){
                printf("%s <= %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }

        }
      }
    | expresion MAYORIGUALREL expresion {
          printf("--logic--> MAYOR O IGUAL QUE\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 16); // 16 es el tipo de nodo para mayor o igual que
          if((strcmp($1.tipo, tipos[0]) == 0 ) && (strcmp($3.tipo, tipos[0])== 0)){
            printf("%d >= %d ?\n", $1.numerico, $3.numerico);
           if($1.numerico >= $3.numerico){
                $$.n->boolean = 1;
                printf("TRUE\n");
                
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 

        }else if((strcmp($1.tipo, tipos[1]) == 0) && (strcmp($3.tipo, tipos[1])== 0)){
            printf("%.3f >= %.3f ?/n", $1.numericoDecimal, $3.numericoDecimal);
           if($1.numericoDecimal >= $3.numericoDecimal){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if(strcmp($1.tipo, tipos[2]) == 0 && strcmp($3.tipo, tipos[2])){
            printf("%s >= %s ?/n", $1.cadena, $3.cadena);
           if($1.cadena >= $3.cadena){
                $$.n->boolean = 1;
                printf("TRUE\n");
            } else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            } 
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[0]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[0])==0)){

            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numerico >= tabla[buscarTabla(0,$3.n->cadena,tabla)].numerico){
                printf("%s >= %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[1]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[1])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].numericoDecimal >= tabla[buscarTabla(0,$3.n->cadena,tabla)].numericoDecimal){
                printf("%s >= %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }
        }else if((strcmp(tabla[buscarTabla(0,$1.n->cadena,tabla)].tipo,tipos[2]) == 0) && (strcmp(tabla[buscarTabla(0,$3.n->cadena,tabla)].tipo,tipos[2])==0)){
            if(tabla[buscarTabla(0,$1.n->cadena,tabla)].cadena >= tabla[buscarTabla(0,$3.n->cadena,tabla)].cadena){
                printf("%s >= %s ?/n", $1.n->cadena, $3.n->cadena);
                $$.n->boolean = 1;
                printf("TRUE\n");
            }else{
                $$.n->boolean = 0;
                printf("FALSE\n");
            }

        }
      }
      
    | expresion AND expresion {
          printf("--logic--> AND\n");
          $$.n = crearNodoNoTerminal($1.n, $3.n, 17); // 17 es el tipo de nodo para AND
      }
    | expresion OR expresion {
          printf("--logic--> OR\n");
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
        printf(" <-- IDENTIFICADOR \n");
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
        printf("\n- Tipo Int: %ld\n", $$.numerico);
        $$.n = crearNodoTerminal($1);  
        $$.tipo = tipos[0]; 
    }

    //Numero decimal normal
    | NUMERICODECIMAL {
        $$.numericoDecimal = $1;
        printf("\n- Tipo Double: %.3f\n", $$.numericoDecimal); 
        $$.n = crearNodoTerminal($1);  
        $$.tipo = tipos[1];  
    }
    //Cadena de texto
    | CADENA {
        $$.cadena = $1;
        printf("\n- Tipo String: %s\n", $$.cadena);
        $$.n = crearNodoTerminalC($1);
        $$.tipo = tipos[2];
    }
;

//-----------------------------------------------  IMPRIMIR  ---------------------------------------------
//Representa la estructura del print en lenguaje latino
//I --> print ( E ) 
imprimir: 
    IMPRIMIR APERTURAPARENTESIS expresion CIERREPARENTESIS {
        printf("> Funcion Imprimir \n");
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