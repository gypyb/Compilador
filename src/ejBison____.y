%{
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tabla_simbolos.h"
#include "AST_python.h"

extern int yylex();
extern int yylineno;  // Declaración externa para yylineno
extern char* yytext;  // Declaración externa para yytext

FILE *yyout;
extern FILE* yyin;
extern int num_linea; //Almacena el numero de linea durante la ejecucion
extern tSimbolos tabla[256];
extern int indice; //Se almacena el índice de la tabla de tSimbolos
char* tipos[] = {"numerico", "numericoDecimal", "texto", "bool"}; //Para parsear el tipo que se detecta en flex al tipo del nodo


void yyerror(const char *s) {
    fprintf(stderr, "Error de sintaxis en línea %d: %s\n", yylineno, s);
}


%}

%union {
    int intVal;
    double realVal;
    char* strVal;
    node* nodePtr;
}

%token <intVal> INTEGER
%token <realVal> REAL
%token <strVal> STRING IDENTIFIER
%token PLUS MINUS MULT DIV
%token ASSIGN EQ NEQ LT GT LE GE AND OR
%token IF ELSE WHILE
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON BEGIN_BLOCK END_BLOCK

%type <nodePtr> statement expression logic_expr assignment while_loop if_statement

%%



statement:
      expression SEMICOLON { $$ = newNode("expr"); addChild($$, $1); }
    | if_statement
    | while_loop
    | assignment SEMICOLON
;

expression:
      INTEGER { $$ = newNode("integer"); $$->token = strdup(yytext); }
    | REAL { $$ = newNode("real"); $$->token = strdup(yytext); }
    | STRING { $$ = newNode("string"); $$->token = strdup(yytext); }
    | IDENTIFIER { $$ = newNode("identifier"); $$->token = strdup(yytext); }
    | expression PLUS expression { $$ = newNode("add"); addChild($$, $1); addChild($$, $3); }
    | expression MINUS expression
    | expression MULT expression
    | expression DIV expression
;

assignment:
    IDENTIFIER ASSIGN expression { $$ = newNode("assign"); addChild($$, newNode($1)); addChild($$, $3); }
;

if_statement:
    IF LPAREN logic_expr RPAREN statement ELSE statement { $$ = newNode("if_else"); addChild($$, $3); addChild($$, $5); addChild($$, $7); }
;

while_loop:
    WHILE LPAREN logic_expr RPAREN statement { $$ = newNode("while"); addChild($$, $3); addChild($$, $5); }
;

logic_expr:
      expression EQ expression
    | expression NEQ expression
    | expression LT expression
    | expression GT expression
    | expression LE expression
    | expression GE expression
    | expression AND expression
    | expression OR expression
;

%%

int main(int argc, char **argv) {
    if (yyparse() == 0) {
        printf("Análisis completado con éxito.\n");
    } else {
        printf("Análisis fallido.\n");
    }
    return 0;
}

node* newNode(char* token) {
    node* n = malloc(sizeof(node));
    n->token = strdup(token);
    n->children = NULL;
    n->n_children = 0;
    n->capacity = 0;
    return n;
}

void addChild(node* parent, node* child) {
    if (parent->n_children == parent->capacity) {
        parent->capacity = parent->capacity ? parent->capacity * 2 : 4;
        parent->children = realloc(parent->children, parent->capacity * sizeof(node*));
    }
    parent->children[parent->n_children++] = child;
}

void freeNode(node* n) {
    if (!n) return;
    for (int i = 0; i < n->n_children; i++) {
        freeNode(n->children[i]);
    }
    free(n->children);
    free(n->token);
    free(n);
}
