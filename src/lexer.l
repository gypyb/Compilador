%{
#include "parser.tab.h"  // Incluye el archivo de cabecera generado por Bison
void countLines(void);
%}

%option noyywrap

digit       [0-9]+
letter      [a-zA-Z]
identifier  {letter}({letter}|{digit})*

%%
[ \t]+                     ;  // Ignora espacios y tabuladores
\n                         { countLines(); }  // Incrementa contador de líneas
"//".*                     ;  // Ignora comentarios de una línea
"/*"([^*]|"\n"|*[^/])*"*/" ;  // Ignora comentarios de múltiples líneas
{digit}+                   { yylval.intVal = atoi(yytext); return INTEGER; }  // Enteros
{digit}+"."{digit}*        { yylval.realVal = atof(yytext); return REAL; }  // Reales
\"([^\\"]|\\.)*\"          { yylval.strVal = strdup(yytext); return STRING; }  // Cadenas de texto
"+"                        { return PLUS; }
"-"                        { return MINUS; }
"*"                        { return MULT; }
"/"                        { return DIV; }
"="                        { return ASSIGN; }
"=="                       { return EQ; }
"!="                       { return NEQ; }
"<"                        { return LT; }
">"                        { return GT; }
"<="                       { return LE; }
">="                       { return GE; }
"("                        { return LPAREN; }
")"                        { return RPAREN; }
"{"                        { return BEGIN_BLOCK; }
"}"                        { return END_BLOCK; }
";"                        { return SEMICOLON; }
{identifier}               { yylval.strVal = strdup(yytext); return IDENTIFIER; }  // Identificadores

%%
void countLines(void) { ++yylineno; }
