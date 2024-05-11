%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylex();
void yyerror(const char *s);
int yylineno;

typedef struct _node {
   char* token;
   struct _node** children;
   int n_children;
   int capacity;
} node;

node* newNode(char* token);
void addChild(node* n, node* child);
void freeNode(node* n);
void printTree(node* n, int level);
void generateMIPS(node* n);

node* root;
%}

%union {
    int intVal;
    double realVal;
    char* strVal;
    node* nodePtr;
}

%type <nodePtr> program statements statement expr assignment_statement if_statement while_statement block_statement
%token <intVal> INTEGER
%token <realVal> REAL
%token <strVal> STRING IDENTIFIER
%token PLUS MINUS MULT DIV ASSIGN EQ NEQ LT GT LE GE LPAREN RPAREN BEGIN_BLOCK END_BLOCK SEMICOLON

%%

program:
    statements                   { root = $1; }
    ;

statements:
    statement                    { $$ = newNode("statements"); addChild($$, $1); }
    | statements statement       { addChild($1, $2); $$ = $1; }
    ;

statement:
    expr SEMICOLON               { $$ = newNode("expr_statement"); addChild($$, $1); }  // Mínimo 1
    | assignment_statement       { $$ = $1; }  // Mínimo 6, 7
    | if_statement               { $$ = $1; }  // Mínimo 4
    | while_statement            { $$ = $1; }  // Mínimo 5
    | block_statement            { $$ = $1; }
    ;

expr:
    INTEGER                      { $$ = newNode("integer"); $$->token = strdup(yytext); }
    | REAL                       { $$ = newNode("real"); $$->token = strdup(yytext); }
    | IDENTIFIER                 { $$ = newNode("identifier"); $$->token = strdup(yytext); }
    | STRING                     { $$ = newNode("string"); $$->token = strdup(yytext); }  // Mínimo 2
    | expr PLUS expr             { $$ = newNode("plus"); addChild($$, $1); addChild($$, $3); }  // Mínimo 1, 2
    | expr MINUS expr            { $$ = newNode("minus"); addChild($$, $1); addChild($$, $3); }  // Mínimo 1
    | expr MULT expr             { $$ = newNode("mult"); addChild($$, $1); addChild($$, $3); }  // Mínimo 1
    | expr DIV expr              { $$ = newNode("div"); addChild($$, $1); addChild($$, $3); }  // Mínimo 1
    ;

assignment_statement:
    IDENTIFIER ASSIGN expr SEMICOLON { $$ = newNode("assignment"); addChild($$, newNode($1)); addChild($$, $3); }  // Mínimo 6, 7
    ;

if_statement:
    "if" LPAREN expr RPAREN statement "else" statement { $$ = newNode("if_else"); addChild($$, $3); addChild($$, $5); addChild($$, $7); }  // Mínimo 4
    | "if" LPAREN expr RPAREN statement                { $$ = newNode("if"); addChild($$, $3); addChild($$, $5); }  // Mínimo 4
    ;

while_statement:
    "while" LPAREN expr RPAREN statement { $$ = newNode("while"); addChild($$, $3); addChild($$, $5); }  // Mínimo 5
    ;

block_statement:
    BEGIN_BLOCK statements END_BLOCK     { $$ = newNode("block"); addChild($$, $2); }
    ;

%%

void generateMIPS(node* n) {
    if (strcmp(n->token, "integer") == 0) {
        printf("li $t0, %s\n", n->token);  // Load immediate
    } else if (strcmp(n->token, "plus") == 0) {
        generateMIPS(n->children[0]);  // Assume result in $t0
        generateMIPS(n->children[1]);  // Assume result in $t1
        printf("add $t0, $t0, $t1\n");  // Add
    } else if (strcmp(n->token, "assignment") == 0) {
        generateMIPS(n->children[1]);  // Right-hand side expression
        printf("sw $t0, %s\n", n->children[0]->token);  // Store word
    }
    // Agregar más traducciones para otros nodos
}

int main(void) {
    if (yyparse() == 0) {
        printTree(root, 0);  // Para depuración
        generateMIPS(root);  // Genera el código MIPS
        freeNode(root);
    }
    return 0;
}
