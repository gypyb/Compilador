// ----------------------------- GLOSARIO DE IMPORTS -------------------------------------------
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// ----------------------------- DECLARACION DE VARIABLES Y ESTRUCTURAS --------------------------------------------
extern FILE *yyout;
int contadorEtiqueta = 0;         // Variable para el control de las etiquetas
int numMaxRegistros = 32;         // Variable que indica el numero maximo de registros disponibles
int nombreVariable = 0;           // Almacena el entero que se asociará al nombre de la variable
int contadorRegistrosCadenas = 0;
int numMaxRegistrosCadenas = 6;   // Variable que indica el numero maximo de registros disponibles para cadenas

//Por defecto, tenemos 32 registros de tipo f para controlar los registros libres (true) o ocupados (false)
bool registros[32] = {[0 ... 29] = true, [30 ... 31] = true}; // Los registros 30 y 31 están reservados por defecto para imprimir por pantalla
bool registroString[6] = {[0 ... 5] = true};

bool concatenacionCadena = false;

// Estructura variable, se hará uso de la misma para almacenar y imprimir las variables del codigo python
struct variable {
    float dato;
    char *texto;
    int nombre; //limite de caracteres de la variable
    int registro;
    bool disponible;
    int *array;
};

struct variable variables[64]; // Declaramos el array de variables usando la estructura definida

// Estructura de tipo de dato que almacenna el nodo del arbol
union astValor {
    double valorDouble;
    char *valorString;
    int *array;
};

// Estructura que almacena el valor de retorno de la funcion comprobarValorNodo
struct valorNodoRetorno {
    double valor;
    char *texto;
    bool booleano;
    int *array;
};


// Estructura AST, se define la estructura de los nodos del arbol
struct ast
{
  struct ast *izq;     // Nodo izquierdo del arbol
  struct ast *dcha;    // Nodo derecho del arbol
  int tipoNodo;        // Almacena el tipo de nodo
  //double valor;        // Almacena el valor del nodo
  union astValor valorNodo; // Almacena el valor del nodo
  char *tipo;          // El tipo de dato que almacena: numericoDecimal, numerico o string
  int resultado;       // Registro donde está el resultado
  int nombreVar;       // Indica el nombre de la variable
};

//-----------------------------------------------  METODOS -------------------------------------------------------

// METODO "crearNombreVariable", incremente el valor de la variable "nombreVariable"
int crearNombreVariable(){
  return nombreVariable++; //retorna la variable y luego la incrementa
}

// METODO "comprobarValorNodo", se escribe el lenguaje máquina (por tipo de nodo) desde árbol completo generado al nivel del axioma de la gramática
struct valorNodoRetorno comprobarValorNodo(struct ast *n, int contadorEtiquetaLocal)
{
  struct valorNodoRetorno dato;

  //TIPO NODO 1 - Nueva hoja en el arbol
  if (n->tipoNodo == 1) {
    if (strcmp(n->tipo, "texto") == 0) {
      dato.texto = n->valorNodo.valorString;

      fprintf(yyout, "la $t%d, var_%d\n", n->resultado, n->nombreVar);

      //contadorRegistrosCadenas = n->resultado+1;

    } else if (strcmp(n->tipo, "numerico") == 0) {
      dato.valor = n->valorNodo.valorDouble;
      fprintf(yyout, "lwc1 $f%d, var_%d\n", n->resultado, n->nombreVar);
    } else if (strcmp(n->tipo, "numericoDecimal") == 0) {
      dato.valor = n->valorNodo.valorDouble;
      fprintf(yyout, "lwc1 $f%d, var_%d\n", n->resultado, n->nombreVar);
    }
    else if (strcmp(n->tipo, "array") == 0) {
      dato.array = n->valorNodo.array;
      fprintf(yyout, "lwc1 $f%d, var_%d\n", n->resultado, n->nombreVar);
    }


  //TIPO NODO 3 - Nueva suma
  }  else if (n->tipoNodo == 2) {

    if (strcmp(n->tipo, "texto") == 0) {

      char *izqString = comprobarValorNodo(n->izq, contadorEtiquetaLocal).texto;
      char *dchaString = comprobarValorNodo(n->dcha, contadorEtiquetaLocal).texto;

      dato.texto = malloc(strlen(izqString) + strlen(dchaString) + 1);
      strcpy(dato.texto, izqString);
      strcat(dato.texto, dchaString);

      // registro t6 para el puntero de la cadena
      fprintf(yyout, "la $s0, resultado\n");
      

      fprintf(yyout, "cadena_%d: \n", n->izq->resultado);
      fprintf(yyout, "  lb $s1, 0($t%d)\n", n->izq->resultado);
      fprintf(yyout, "  beqz $s1, finCadena_%d\n", n->izq->resultado);
      fprintf(yyout, "  sb $s1, 0($s0)\n");
      fprintf(yyout, "  addi $s0, $s0, 1\n");
      fprintf(yyout, "  addi $t%d, $t%d, 1\n", n->izq->resultado, n->izq->resultado);
      fprintf(yyout, "  j cadena_%d\n", n->izq->resultado);


      fprintf(yyout, "finCadena_%d: \n", n->izq->resultado);
      fprintf(yyout, "  la $t%d, var_%d\n", n->dcha->resultado, n->dcha->resultado);


      fprintf(yyout, "cadena_%d: \n", n->dcha->resultado);
      fprintf(yyout, "  lb $s1, 0($t%d)\n", n->dcha->resultado);
      fprintf(yyout, "  beqz $s1, fin_%d\n", n->dcha->resultado);
      fprintf(yyout, "  sb $s1, 0($s0)\n");
      fprintf(yyout, "  addi $s0, $s0, 1\n");
      fprintf(yyout, "  addi $t%d, $t%d, 1\n", n->dcha->resultado, n->dcha->resultado);
      fprintf(yyout, "  j cadena_%d\n", n->dcha->resultado);

      fprintf(yyout, "fin_%d: \n", n->dcha->resultado); 
      fprintf(yyout, "  sb $zero, 0($s0)\n"); //Fin de la cadena

      concatenacionCadena = true;

    }
     else if (strcmp(n->tipo, "numerico") == 0) {
      dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor + comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
      fprintf(yyout, "add.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza add.s para + en ASM

    } else if (strcmp(n->tipo, "numericoDecimal") == 0) {
      dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor + comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
      fprintf(yyout, "add.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza add.s para + en ASM

    }

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  //TIPO NODO 4 - Nueva resta
  } else if (n->tipoNodo == 3) {
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor - comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
    fprintf(yyout, "sub.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza sub.s para - en ASM
    fprintf(yyout, "mov.s $f%d, $f%d\n", n->izq->resultado, n->resultado);
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  //TIPO NODO 18 - Nuevo imprimir
  } else if (n->tipoNodo == 4) {
    comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    funcionImprimir(n->izq);

  //TIPO NODO 19 - Nueva asignación
  }else if (n->tipoNodo == 5) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal);

  //TIPO NODO 20 - Nueva variable
  } else if (n->tipoNodo == 6) {

    if (strcmp(n->tipo, "texto") == 0) {
      dato.texto = n->valorNodo.valorString;
    } else if (strcmp(n->tipo, "numerico") == 0) {
      dato.valor = n->valorNodo.valorDouble;
    } else if (strcmp(n->tipo, "numericoDecimal") == 0) {
      dato.valor = n->valorNodo.valorDouble;
    }
    else if (strcmp(n->tipo, "array") == 0) {
      dato.array = n->valorNodo.array;
    }

  //TIPO NODO 22 - Lista de sentencias
  } else if (n->tipoNodo == 7) {
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal);
    comprobarValorNodo(n->dcha, contadorEtiquetaLocal);


  // Nueva división
  } else if (n->tipoNodo == 8){
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor / comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
    fprintf(yyout, "div.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza div.s para - en ASM
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  // Nueva multiplicación
  } else if (n->tipoNodo == 9){
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor * comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
    fprintf(yyout, "mul.s $f%d, $f%d, $f%d\n", n->resultado, n->izq->resultado, n->dcha->resultado); //se utiliza mul.s para * en ASM
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  // Nueva MAYORQUE
  } else if (n->tipoNodo == 10){
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor > comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;

    // Comparación usando c.lt.s y salto condicional
    fprintf(yyout, "c.lt.s $f%d, $f%d\n", n->dcha->resultado, n->izq->resultado);
    fprintf(yyout, "  bc1t es_mayor_%d\n", n->izq->resultado);
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      li $t0, 0\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "      j fin_mayor_%d\n", n->izq->resultado);
    fprintf(yyout, "    es_mayor_%d:\n", n->izq->resultado);
    fprintf(yyout, "      li $t0, 1065353216\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "    fin_mayor_%d:\n", n->izq->resultado);

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  // Nueva MAYOR_IGUAL_QUE
  } else if (n->tipoNodo == 11){
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor >= comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
    // Comparación usando c.lt.s y salto condicional
    fprintf(yyout, "c.le.s $f%d, $f%d\n", n->dcha->resultado, n->izq->resultado);
    fprintf(yyout, "  bc1t es_mayor_o_igual_%d\n", n->izq->resultado);
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      li $t0, 0\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "      j fin_mayor_o_igual_%d\n", n->izq->resultado);
    fprintf(yyout, "    es_mayor_o_igual_%d:\n", n->izq->resultado);
    fprintf(yyout, "      li $t0, 1065353216\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "    fin_mayor_o_igual_%d:\n", n->izq->resultado);

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  // Nueva MENOR_QUE
  } else if (n->tipoNodo == 12){
    dato.valor = !(comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor < comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor);

    // Comparación usando c.lt.s y salto condicional
    fprintf(yyout, "c.lt.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);
    fprintf(yyout, "  bc1t es_menor_%d\n", n->izq->resultado);
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      li $t0, 0\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "      j fin_menor_%d\n", n->izq->resultado);
    fprintf(yyout, "    es_menor_%d:\n", n->izq->resultado);
    fprintf(yyout, "      li $t0, 1065353216\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "    fin_menor_%d:\n", n->izq->resultado);

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  // Nueva MENOR_IGUAL_QUE
  } else if (n->tipoNodo == 13){
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor <= comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;

    // Comparación usando c.lt.s y salto condicional
    fprintf(yyout, "c.le.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);
    fprintf(yyout, "  bc1t es_menor_o_igual_%d\n", n->izq->resultado);
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      li $t0, 0\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "      j fin_menor_o_igual_%d\n", n->izq->resultado);
    fprintf(yyout, "    es_menor_o_igual_%d:\n", n->izq->resultado);
    fprintf(yyout, "      li $t0, 1065353216\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "    fin_menor_o_igual_%d:\n", n->izq->resultado);

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  // Nueva IGIUAL_IGUAL
  } else if (n->tipoNodo == 14){
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor == comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
    // Comparación usando c.lt.s y salto condicional
    fprintf(yyout, "c.eq.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);
    fprintf(yyout, "  bc1t son_iguales_%d\n", n->izq->resultado);
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      li $t0, 0\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "      j fin_igual_%d\n", n->izq->resultado);
    fprintf(yyout, "    son_iguales_%d:\n", n->izq->resultado);
    fprintf(yyout, "      li $t0, 1065353216\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "    fin_igual_%d:\n", n->izq->resultado);

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

  //Nueva NO_IGUAL
  }else if (n->tipoNodo == 15){
   // printf("---------------pppunaaaa: %s\n", n->izq->tipo);//NO FUNCIONA
    // if (n->izq->tipo != NULL || n->dcha->tipo != NULL) {
    //    printf("---------------unooooo: %s\n", n->izq->tipo);//NO FUNCIONA
    // } else{
      // Comparación usando c.lt.s y salto condicional
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor != comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
    fprintf(yyout, "c.eq.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);
    fprintf(yyout, "  bc1t son_distintos_%d\n", n->izq->resultado);
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      li $t0, 1065353216\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "      j fin_son_distintos_%d\n", n->izq->resultado);
    fprintf(yyout, "    son_distintos_%d:\n", n->izq->resultado);
    fprintf(yyout, "      li $t0, 0\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado);
    fprintf(yyout, "    fin_son_distintos_%d:\n", n->izq->resultado);
    //   printf("---------------dooos: %d + %d\n", n->izq->resultado, n->dcha->resultado);
    // }

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

    // Nuevo AND
  }else if (n->tipoNodo == 16){
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor && comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;

    // Comparacion si ambos son verdaderos
    fprintf(yyout, "c.eq.s $f%d, $f%d\n", n->izq->resultado, n->dcha->resultado);
    fprintf(yyout, "  bc1t son_iguales\n");
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      li $t0, 0\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado); //Si no son iguales, se pone a 0
    fprintf(yyout, "      j fin_igual\n");
    fprintf(yyout, "    son_iguales:\n");
    fprintf(yyout, "      li $t0, 1065353216\n");
    fprintf(yyout, "      mtc1 $t0, $f%d\n", n->resultado); //Si son iguales, se pone a 1
    fprintf(yyout, "    fin_igual:\n");

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

    // Nuevo OR
  }else if (n->tipoNodo == 17){ //Nueva OR
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor || comprobarValorNodo(n->dcha, contadorEtiquetaLocal).valor;
    // Comparacion del OR
    fprintf(yyout,"l.s $f29, uno\n");
    fprintf(yyout, "c.eq.s $f%d, $f29\n", n->izq->resultado);
    fprintf(yyout, "  bc1t existe_uno\n");
    fprintf(yyout, "    nop\n");
    fprintf(yyout, "      c.eq.s $f%d, $f29\n", n->dcha->resultado);
    fprintf(yyout, "      bc1t existe_uno\n");
    fprintf(yyout, "        nop\n");
    fprintf(yyout, "          li $t0, 0\n");
    fprintf(yyout, "          mtc1 $t0, $f%d\n", n->resultado); //Si no existe ninguno, se pone a 0
    fprintf(yyout, "          j fin_existe_uno\n");
    fprintf(yyout, "        existe_uno:\n");
    fprintf(yyout, "          li $t0, 1065353216\n");
    fprintf(yyout, "          mtc1 $t0, $f%d\n", n->resultado); //Si existe uno, se pone a 1
    fprintf(yyout, "      fin_existe_uno:\n");

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

    // Nuevo bucle while
  }else if (n->tipoNodo == 21){
    int etiqueta = contadorEtiquetaLocal;
    contadorEtiquetaLocal++;
    fprintf(yyout,"l.s $f29, zero\n");
    fprintf(yyout, "etiqueta%d:\n", etiqueta);
    dato = comprobarValorNodo(n->izq, contadorEtiquetaLocal);

    fprintf(yyout, "c.eq.s $f%d, $f29\n", n->izq->resultado); //Comprobamos si el valor es 0

    fprintf(yyout, "  bc1t fin_bucle%d\n", etiqueta); //Si es 0, salimos del bucle
    fprintf(yyout, "    nop\n");

    comprobarValorNodo(n->dcha, contadorEtiquetaLocal); //Comprobamos el valor del nodo derecho
    fprintf(yyout, "j etiqueta%d\n", etiqueta); //Volvemos a la etiqueta
    fprintf(yyout, "fin_bucle%d:\n", etiqueta);   //Etiqueta de fin de bucle

    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)

    // Nuevo bucle for
  } else if (n->tipoNodo == 22){  // nueva bucle for
    int etiqueta = contadorEtiquetaLocal;
    contadorEtiquetaLocal++;
    fprintf(yyout,"l.s $f29, zero\n"); //cargar esto al final de zero nuevamente
    dato.valor = comprobarValorNodo(n->izq, contadorEtiquetaLocal).valor;
    fprintf(yyout, "etiqueta%d:\n", etiqueta);
    // Comparo si el valor de f29 es menor que el valor del nodo izq
    fprintf(yyout, "c.lt.s $f%d, $f%d\n", 29, n->izq->resultado);
    fprintf(yyout, "  bc1f fin_bucle%d\n", etiqueta); //Si es 0, salimos del bucle
    fprintf(yyout, "    nop\n");

    comprobarValorNodo(n->dcha, 7); //Comprobamos el valor del nodo derecho
    // Incremento el valor de f29 en 1

    fprintf(yyout,"l.s $f30, uno\n");
    fprintf(yyout, "add.s $f29, $f29, $f30\n");
    fprintf(yyout, "j etiqueta%d\n", etiqueta); //Volvemos a la etiqueta
    fprintf(yyout, "fin_bucle%d:\n", etiqueta);   //Etiqueta de fin de bucle
    fprintf(yyout,"l.s $f29, zero\n"); //cargar esto al final de zero nuevamente
    borrarReg(n->izq, n->dcha); //borrado de registros (se ponen a true)


  }

  return dato; //Devolvemos el valor
}

// METODO "comprobarAST", imprime el codigo .asm y generas sus respectivos pasos
comprobarAST(struct ast *n)
{
  imprimirVariables(); //Metodo que realiza la impresion de la parte de variables para Mips
  fprintf(yyout, "\n#--------------------- Ejecuciones ---------------------");
  fprintf(yyout, "\n.text\n");
  fprintf(yyout, "lwc1 $f31, zero\n");
  comprobarValorNodo(n, contadorEtiqueta); //Comprueba el valor del nodo
}

// METODO "imprimir", imprime el codigo .asm que hace referencia a la funcion imprimir de python
funcionImprimir(struct ast *n)
{

  if (strcmp(n->tipo, "texto") == 0) {

    fprintf(yyout, "li $v0, 4\n");

    if (concatenacionCadena == true) {
      fprintf(yyout, "la $a0, resultado\n");
    } else {
      fprintf(yyout, "la $a0, var_%d\n", n->resultado); // Mover del registro n al registro 30 (es el que empleamos para imprimir)
    }
    fprintf(yyout, "addi $v0, $0, 4  #Movemos el registro 12 al 30 iniciado a false\n");
    fprintf(yyout, "syscall #Llamada al sistema\n");
    saltoLinea();
  } else if (strcmp(n->tipo, "numerico") == 0) {
    fprintf(yyout, "li $v0, 2\n"); //entero
    fprintf(yyout, "add.s $f12, $f31, $f%d\n", n->resultado); // Mover del registro n al registro 30 (es el que empleamos para imprimir)
    fprintf(yyout, "mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false\n");
    fprintf(yyout, "syscall #Llamada al sistema\n");
    saltoLinea(); //Introducimos un salto de linea
  } else if (strcmp(n->tipo, "numericoDecimal") == 0) {
    fprintf(yyout, "li $v0, 4\n"); //entero
    fprintf(yyout, "add.s $f12, $f31, $f%d\n", n->resultado); // Mover del registro n al registro 30 (es el que empleamos para imprimir)
    fprintf(yyout, "mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false\n");
    fprintf(yyout, "syscall #Llamada al sistema\n");
    saltoLinea(); //Introducimos un salto de linea
  }

}


// METODO "imprimirVariables", imprime el archivo .asm la estructura del .data
// Recorrer los registros y devolver la posicion del primero que esté libre
imprimirVariables(){
  fprintf(yyout, "\n#-------------- Declaracion de variables --------------");
  fprintf(yyout, "\n.data \n");
  fprintf(yyout, "saltoLinea: .asciiz \"\\n\"\n"); //Variable salto de linea
  fprintf(yyout, "zero: .float 0.0\n"); //Se inserta una variable auxiliar var_0 con valor 0.000
  fprintf(yyout, "uno: .float 1.0\n"); //Se inserta una variable auxiliar var_1 con valor 1.000
  fprintf(yyout, "resultado: .space 100\n"); //Se inserta una variable auxiliar resultado para la concatenacion
  //Bucle que recorre el array de variables y las imprime en el archivo .asm
  for (int i = 0; i < 64; i++) {
      if(variables[i].disponible == true){
        if (variables[i].texto != NULL) {
          fprintf(yyout, "var_%d: .asciiz \"%s\"\n", variables[i].nombre, variables[i].texto);
        } else if (variables[i].array != NULL ) {
          fprintf(yyout, "var_%d: .word ", variables[i].nombre);
          for (int j = 1; j <= variables[i].array[0]; j++) {
            if (j == variables[i].array[0]) {
              fprintf(yyout, "%d\n", variables[i].array[j]);
            } else {
              fprintf(yyout, "%d, ", variables[i].array[j]);
            }
          }
          fprintf(yyout, "\n");

        }
         else {
          fprintf(yyout, "var_%d: .float %.3f\n", variables[i].nombre, variables[i].dato);
      }
      }
  }
}

// METODO "saltoLinea", incorpora un salto de linea en la salida de nuestro codigo
saltoLinea(){
	fprintf(yyout, "li $v0, 4\n");                      //especifica al registro $v0 que va a imprimir una cadena de caracteres
	fprintf(yyout, "la $a0, saltoLinea\n");             //carga en $a0 el valor del salto de linea
	fprintf(yyout, "syscall #Llamada al sistema\n");
}

// METODO "encontrarReg", comprueba si el registro está libre y devuelve su posicion
// Recorrer los registros y devolver la posicion del primero que esté libre
encontrarReg()
{
  int posicion = 0;
  while (posicion <= (numMaxRegistros - 1) && registros[posicion] == 0) {  // registros[posicion] == 0, evita recorrer todo el array
    posicion++;
  }

  if (posicion == numMaxRegistros) {
    posicion = 0;
  }

  registros[posicion] = 0;
  return posicion; //retorna la posicion donde se encuentra el registro libre
}

encontrarRegString()
{
  int posicion = 0;

  while (contadorRegistrosCadenas <= (numMaxRegistrosCadenas -1) && registroString[posicion] == 0) {
    posicion++;
  }
  if (contadorRegistrosCadenas == numMaxRegistrosCadenas) {
    contadorRegistrosCadenas = 0;
    posicion = 0;
  }

  registroString[posicion] = 0;

  return posicion; //retorna la posicion donde se encuentra el registro libre
}


// METODO "borrarReg", pone a true de nuevo el registro para que pueda volver a usarse
borrarReg(struct ast *izq, struct ast *dcha) {
  registros[izq->resultado] = true; registros[dcha->resultado] = true;
}

//METODO "crearNodoVacio", crea un nuevo nodo sin contenido
struct ast *crearNodoVacio()
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = NULL;
  n->tipo = NULL;
  return n;
}

// METODO "crearNodoTerminal", crear una nueva hoja en el arbol AST de tipo numerico o numericodecimal
struct ast *crearNodoTerminal(double valor , char *tipo)
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 1;
  n->valorNodo.valorDouble = valor;

  n->tipo = tipo;

  n->resultado = encontrarReg(); //Hacemos llamada al metodo para buscar un nuevo registro
  n->nombreVar = crearNombreVariable();
  printf("# AST - Registro $f%d ocupado para var_%d = %.3f\n", n->resultado, n->nombreVar, n->valorNodo.valorDouble);
  variables[n->resultado].dato = n->valorNodo.valorDouble;
  variables[n->resultado].nombre = n->nombreVar;
  variables[n->resultado].registro = n->resultado;
  variables[n->resultado].disponible = true;
  return n;
}

// METODO "crearNodoTerminalString", crear una nueva hoja en el arbol AST de tipo string
struct ast *crearNodoTerminalString(char *valor , char *tipo)
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 1;
  n->valorNodo.valorString = valor;

  n->tipo = tipo;

  n->resultado = encontrarReg(); //Hacemos llamada al metodo para buscar un nuevo registro
  n->nombreVar = crearNombreVariable();
  printf("# AST - Registro $f%d ocupado para var_%d = %s\n", n->resultado, n->nombreVar, n->valorNodo.valorString);
  variables[n->resultado].texto = n->valorNodo.valorString;
  variables[n->resultado].nombre = n->nombreVar;
  variables[n->resultado].registro = n->resultado;
  variables[n->resultado].disponible = true;
  return n;
}

// METODO "crearNodoTerminalArray", crear una nueva hoja en el arbol AST de tipo array
struct ast *crearNodoTerminalArray(int *valores , char *tipo)
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 1;
  n->valorNodo.array = valores;

  n->tipo = tipo;

  n->resultado = encontrarReg(); //Hacemos llamada al metodo para buscar un nuevo registro
  n->nombreVar = crearNombreVariable();
  printf("# AST - Registro $f%d ocupado para var_%d =\n", n->resultado, n->nombreVar);
  variables[n->resultado].array = n->valorNodo.array;
  variables[n->resultado].nombre = n->nombreVar;
  variables[n->resultado].disponible = true;
  return n;
}


// METODO "crearNodoNoTerminal", crea un nuevo nodo, asignamos sus hijos y tipo, y buscamos nuevo registro
struct ast *crearNodoNoTerminal(struct ast *izq, struct ast *dcha, int tipoNodo)
{

  struct ast *n = malloc(sizeof(struct ast)); // Crea un nuevo nodo
  n->izq = izq; n->dcha = dcha; n->tipoNodo = tipoNodo; // Asignamos al nodo genérico sus hijos y tipo
  //n->izq->tipo = izq->tipo; n->dcha->tipo = dcha->tipo;
  n->nombreVar = crearNombreVariable();


  n->resultado = encontrarReg(); //Hacemos llamada al metodo para buscar un nuevo registro
  //printf("\nNuevo nodo no terminal creado con nombre de variable izq %d\n", n->izq->nombreVar);
  //printf("\nNuevo nodo no terminal creado con nombre de variable dcha %d\n", n->dcha->nombreVar);

  return n;
}





// METODO "crearVariableTerminal", crear el nodo hoja para una variable ya creada
struct ast *crearVariableTerminal(double valor, int registro, char *t)
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 6; n->valorNodo.valorDouble = valor;
  n->tipo = t;
  n->resultado = registro;
  return n;
}


// METODO "crearVariableTerminalString", crear el nodo hoja para una variable ya creada
struct ast *crearVariableTerminalString(char *valor, int registro, char *t)
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 6; n->valorNodo.valorString = valor;
  n->tipo = t;
  n->resultado = registro;

  return n;
}


// METODO "crearVariableTerminalArray", crear el nodo hoja para una variable ya creada
struct ast *crearVariableTerminalArray(int *valores, int registro, char *t)
{
  struct ast *n = malloc(sizeof(struct ast)); // Asigna memoria dinamicamente para el nuevo nodo
  n->izq = NULL; n->dcha = NULL; n->tipoNodo = 6; n->valorNodo.array = valores;
  n->tipo = t;
  n->resultado = registro;
  return n;
}
