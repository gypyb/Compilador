// ----------------------------- GLOSARIO DE IMPORTS -------------------------------------------
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h> 

// ----------------------------- DECLARACION DE VARIABLES Y ESTRUCTURAS --------------------------------------------
extern FILE *yyout;
int contadorEtiqueta = 0;         // Variable para el control de las etiquetas 
int numMaxRegistros = 32;         // Variable que indica el numero maximo de registros disponibles
int nombreVariable = 0;           // Almacena el entero que se asociará al nombre de la variable


//Por defecto, tenemos 32 registros de tipo f para controlar los registros libres (true) o ocupados (false)
bool registros[32] = {[0 ... 29] = true, [30 ... 31] = true}; // Los registros 30 y 31 están reservados por defecto para imprimir por pantalla

// Estructura variable, se hará uso de la misma para almacenar y imprimir las variables del codigo latino
struct variable {
  union{
    float dato;
    char *datocadena;
    double* array_values;
    double** array_values_2d;
  };
  char* nombres;
  int nombre; //limite de caracteres de la variable
  bool disponible;
  char *tipo;
  int array_size;
};

struct variable variables[64]; // Declaramos el array de variables usando la estructura definida

// Estructura AST, se define la estructura de los nodos del arbol
struct ast
{
  struct ast *izq;     // Nodo izquierdo del arbol
  struct ast *dcha;    // Nodo derecho del arbol
  struct ast *condicion; // Nodo para la condición en el if
  int tipoNodo;        // Almacena el tipo de nodo
  double valor;        // Almacena el valor del nodo 
  char *tipo;          // El tipo de dato que almacena: numericoDecimal, numerico o string
  int resultado;       // Registro donde está el resultado
  int boolean;
  int nombreVar;       // Indica el nombre de la variable
  char *cadena;
  double* valores;     // Para arrays
  double** valores2d;  // Para arrays 2D
};

// Declaración de funciones
int crearNombreVariable(void);
double comprobarValorNodo(struct ast *n, int contadorEtiquetaLocal);
void comprobarAST(struct ast *n);
void funcionImprimir(struct ast *n);
void imprimirVariables(void);
void saltoLinea(void);
int encontrarReg(void);
void borrarReg(struct ast *izq, struct ast *dcha);
char* concatenarCadenas(const char* str1, const char* str2);

struct ast *crearNodoVacio(void);
struct ast *crearNodoTerminal(double valor);
struct ast *crearVariableTerminal(double valor, int registro);
struct ast *crearNodoTerminalC(char *cadena);
struct ast *crearVariableTerminalC(char *cadena, int registro);
struct ast *crearNodoNoTerminal(struct ast *izq, struct ast *dcha, int tipoNodo);
struct ast *crearNodoIf(struct ast *condicion, struct ast *entonces, struct ast *sino);
struct ast *crearNodoConcatenacion(struct ast *izq, struct ast *dcha);

//-----------------------------------------------  METODOS -------------------------------------------------------

// METODO "crearNombreVariable", incremente el valor de la variable "nombreVariable"
int crearNombreVariable(){
  return nombreVariable++; //retorna la variable y luego la incrementa
}

// METODO "comprobarValorNodo", se escribe el lenguaje máquina (por tipo de nodo) desde árbol completo generado al nivel del axioma de la gramática
double comprobarValorNodo(struct ast *n, int contadorEtiquetaLocal)
{
  double dato;

  //TIPO NODO 1 - Nueva hoja en el arbol
  if (n->tipoNodo == 1) {
    dato = n->valor;
    fprintf(yyout, "lwc1 $f%d, var_%d\n", n->resultado, n->nombreVar);

  //TIPO NODO 2 - Nueva suma
  } else if (n->tipoNodo == 2) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal) + comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    fprintf(yyout, "add.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza add.s para + en ASM
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  //TIPO NODO 3 - Nueva resta
  } else if (n->tipoNodo == 3) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal) - comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    fprintf(yyout, "sub.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza sub.s para - en ASM
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)
  
  //TIPO NODO 4 - Nuevo imprimir
  } else if (n->tipoNodo == 4) {
    comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    funcionImprimir(n->izq);

  //TIPO NODO 5 - Nueva asignación 
  } else if (n->tipoNodo == 5) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal);

  //TIPO NODO 6 - Nueva variable
  } else if (n->tipoNodo == 6) {
    dato = n->valor;

  //TIPO NODO 7 - Lista de sentencias
  } else if (n->tipoNodo == 7) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal); 
    comprobarValorNodo(n->dcha, contadorEtiquetaLocal); 

  //TIPO NODO 8 - Multiplicación  
  } else if (n->tipoNodo == 8) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal) * comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    fprintf(yyout, "mul.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza mul.s para * en ASM
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  //TIPO NODO 9 - Nueva división
  } else if (n->tipoNodo == 9) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal) / comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    fprintf(yyout, "div.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza div.s para / en ASM
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  //TIPO NODO 10 - Concatenación de cadenas
  } else if (n->tipoNodo == 10) {
    // La concatenación de cadenas se maneja en la producción de la gramática y no se necesita generar código ASM específico aquí

  //TIPO NODO 11 - Igualdad
  } else if (n->tipoNodo == 11) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq == valorDcha);
    fprintf(yyout, "c.eq.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 12 - Desigualdad
  } else if (n->tipoNodo == 12) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq != valorDcha);
    fprintf(yyout, "c.ne.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 13 - Menor que
  } else if (n->tipoNodo == 13) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq < valorDcha);
    fprintf(yyout, "c.lt.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 14 - Mayor que
  } else if (n->tipoNodo == 14) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq > valorDcha);
    fprintf(yyout, "c.gt.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 15 - Menor o igual que
  } else if (n->tipoNodo == 15) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq <= valorDcha);
    fprintf(yyout, "c.le.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 16 - Mayor o igual que
  } else if (n->tipoNodo == 16) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq >= valorDcha);
    fprintf(yyout, "c.ge.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 17 - AND
  } else if (n->tipoNodo == 17) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq && valorDcha);
    fprintf(yyout, "and $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 18 - OR
  } else if (n->tipoNodo == 18) {
    double valorIzq = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    double valorDcha = comprobarValorNodo(n->dcha, contadorEtiquetaLocal);
    dato = (valorIzq || valorDcha);
    fprintf(yyout, "or $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado);

  //TIPO NODO 19 - IF
  } else if (n->tipoNodo == 19) {
    double condicion = comprobarValorNodo(n->condicion, contadorEtiquetaLocal);
    if (condicion) {
        comprobarValorNodo(n->izq, contadorEtiquetaLocal); // Bloque "then"
    } else if (n->dcha) {
        comprobarValorNodo(n->dcha, contadorEtiquetaLocal); // Bloque "else"
    }
    
  //TIPO NODO 20 - Array
  } else if (n->tipoNodo == 20) {
    // Implementación específica para arrays si es necesario
    // Guardar los valores del array en registros
    for (int i = 0; i < variables[n->nombreVar].array_size; i++) {
        fprintf(yyout, "lwc1 $f%d, var_%d[%d]\n", n->resultado, n->nombreVar, i);
    }

  //TIPO NODO 21 - Array 2D
  } else if (n->tipoNodo == 21) {
    // Implementación específica para arrays 2D si es necesario
    // Guardar los valores del array 2D en registros
    for (int i = 0; i < variables[n->nombreVar].array_size; i++) {
        for (int j = 0; j < variables[n->nombreVar].array_size; j++) {
            fprintf(yyout, "lwc1 $f%d, var_%d[%d][%d]\n", n->resultado, n->nombreVar, i, j);
        }
    }
  }
  return dato; //Devolvemos el valor
}

// METODO "comprobarAST", imprime el codigo .asm y generas sus respectivos pasos
void comprobarAST(struct ast *n)
{
  imprimirVariables(); //Metodo que realiza la impresion de la parte de variables para Mips
  fprintf(yyout, "\n#--------------------- Ejecuciones ---------------------");
  fprintf(yyout, "\n.text\n");
  fprintf(yyout, "lwc1 $f31, zero\n");
  comprobarValorNodo(n, contadorEtiqueta); //Comprueba el valor del nodo
}

// METODO "imprimir", imprime el codigo .asm que hace referencia a la funcion imprimir de latino
void funcionImprimir(struct ast *n)
{
  fprintf(yyout, "li $v0, 2\n"); //entero
  fprintf(yyout, "add.s $f12, $f31, $f%d\n", n->resultado); // Mover del registro n al registro 30 (es el que empleamos para imprimir)
  fprintf(yyout, "mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false\n");
  fprintf(yyout, "syscall #Llamada al sistema\n");
  saltoLinea(); //Introducimos un salto de linea
}

// METODO "imprimirVariables", imprime el archivo .asm la estructura del .data
// Recorrer los registros y devolver la posicion del primero que esté libre
void imprimirVariables(){
  fprintf(yyout, "\n#-------------- Declaracion de variables --------------"); 
  fprintf(yyout, "\n.data \n");
  fprintf(yyout, "saltoLinea: .asciiz \"\\n\"\n"); //Variable salto de linea
  fprintf(yyout, "zero: .float 0.0\n"); //Se inserta una variable auxiliar var_0 con valor 0.000
  //Bucle que recorre el array de variables y las imprime en el archivo .asm
  for (int i = 0; i < 64; i++) {
      if(variables[i].disponible == true){
        if(variables[i].tipo == "numerico"){
          fprintf(yyout, "var_%d: .float %.3f\n", variables[i].nombre, variables[i].dato);
        }else if(variables[i].tipo == "cadena"){
          fprintf(yyout, "var_%d: .asciiz %s\n", variables[i].nombre, variables[i].datocadena);
        }
      }
  }
}

// METODO "saltoLinea", incorpora un salto de linea en la salida de nuestro codigo
void saltoLinea(){
	fprintf(yyout, "li $v0, 4\n");                      //especifica al registro $v0 que va a imprimir una cadena de caracteres
	fprintf(yyout, "la $a0, saltoLinea\n");             //carga en $a0 el valor del salto de linea
	fprintf(yyout, "syscall #Llamada al sistema\n");
}

// METODO "encontrarReg", comprueba si el registro está libre y devuelve su posicion
// Recorrer los registros y devolver la posicion del primero que esté libre
int encontrarReg()
{
  int posicion = 0;
  while (posicion <= (numMaxRegistros - 1) && registros[posicion] == 0) {  // registros[posicion] == 0, evita recorrer todo el array
    posicion++;
  }
  registros[posicion] = 0;
  return posicion; //retorna la posicion donde se encuentra el registro libre
}

// METODO "borrarReg", pone a true de nuevo el registro para que pueda volver a usarse
void borrarReg(struct ast *izq, struct ast *dcha) { 
  registros[izq->resultado] = true; registros[dcha->resultado] = true; 
}

//METODO "crearNodoVacio", crea un nuevo nodo sin contenido
struct ast *crearNodoVacio()
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = NULL; 
  return n;
}

// METODO "crearNodoTerminal", crear una nueva hoja en el arbol AST
struct ast *crearNodoTerminal(double valor)
{                   
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 1; n->valor = valor;
  n->resultado = encontrarReg(); //Hacemos llamada al metodo para buscar un nuevo registro
  n->nombreVar = crearNombreVariable();
  n->tipo = "numerico";
  printf("# [AST] - Registro $f%d ocupado para var_%d = %.3f\n", n->resultado, n->nombreVar, n->valor);
  variables[n->resultado].dato = n->valor; variables[n->resultado].nombre = n->nombreVar; variables[n->resultado].disponible = true; variables[n->resultado].tipo = n->tipo;
  return n;
}
struct ast *crearNodoTerminalC(char *cadena)
{                   
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 1; n->cadena = cadena;
  n->resultado = encontrarReg(); //Hacemos llamada al metodo para buscar un nuevo registro
  n->nombreVar = crearNombreVariable();
  n->tipo = "cadena";
  printf("# [AST] - Registro $f%d ocupado para var_%d = %s\n", n->resultado, n->nombreVar, n->cadena);
  variables[n->resultado].datocadena = n->cadena; variables[n->resultado].nombre = n->nombreVar; variables[n->resultado].disponible = true; variables[n->resultado].tipo = n->tipo;
  return n;
}

// METODO "crearNodoNoTerminal", crea un nuevo nodo, asignamos sus hijos y tipo, y buscamos nuevo registro
struct ast *crearNodoNoTerminal(struct ast *izq, struct ast *dcha, int tipoNodo)
{     
  struct ast *n = malloc(sizeof(struct ast)); // Crea un nuevo nodo
  n->izq = izq; n->dcha = dcha; n->tipoNodo = tipoNodo; // Asignamos al nodo genérico sus hijos y tipo
  n->resultado = encontrarReg(); //Hacemos llamada al metodo para buscar un nuevo registro
  n->boolean = 0;
  return n;
}

// METODO "crearVariableTerminal", crear el nodo hoja para una variable ya creada
struct ast *crearVariableTerminal(double valor, int registro)
{                                               
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 6; n->valor = valor;
  n->resultado = registro;
  return n;
}

struct ast *crearVariableTerminalC(char *cadena, int registro)
{                                               
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 6; n->cadena = cadena;
  n->resultado = registro;
  return n;
}

// METODO "crearNodoIf", crea un nuevo nodo if en el arbol AST
struct ast *crearNodoIf(struct ast *condicion, struct ast *entonces, struct ast *sino) {
    struct ast *n = malloc(sizeof(struct ast));
    n->tipoNodo = 19; // Tipo de nodo para if
    n->condicion = condicion;
    n->izq = entonces;
    n->dcha = sino;
    return n;
}
// METODO "crearNodoArray", crea un nuevo nodo array en el arbol AST
struct ast *crearNodoArray(double* valores, int tamano) {
    struct ast *n = malloc(sizeof(struct ast));
    n->tipoNodo = 20; // Tipo de nodo para array
    n->valores = valores;
    n->boolean = tamano;
    return n;
}

// METODO "crearNodoArray2D", crea un nuevo nodo array 2D en el arbol AST
struct ast *crearNodoArray2D(double** valores2d, int tamano) {
    struct ast *n = malloc(sizeof(struct ast));
    n->tipoNodo = 21; // Tipo de nodo para array 2D
    n->valores2d = valores2d;
    n->boolean = tamano;
    return n;
}
// METODO "crearNodoConcatenacion", crea un nuevo nodo de concatenación en el arbol AST
struct ast *crearNodoConcatenacion(struct ast *izq, struct ast *dcha) {
    struct ast *n = malloc(sizeof(struct ast));
    n->tipoNodo = 10;
    n->cadena = concatenarCadenas(izq->cadena, dcha->cadena);
    return n;
}

char* concatenarCadenas(const char* str1, const char* str2) {
    char *resultado = malloc(strlen(str1) + strlen(str2) + 1);
    strcpy(resultado, str1);
    strcat(resultado, str2);
    return resultado;
}
void quitarComillas(char* cadena) {
    int len = strlen(cadena);
    int j = 0;
    for (int i = 0; i < len; i++) {
        if (cadena[i] != '"') {
            cadena[j++] = cadena[i];
        }
    }
    cadena[j] = '\0'; // Termina la nueva cadena correctamente
}
