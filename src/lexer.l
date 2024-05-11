%{
#include "parser.tab.h"  // Asegúrate de cambiar "y.tab.h" por "parser.tab.h" si es necesario
void countLines(void);
%}

%option noyywrap

digit       [0-9]
letter      [a-zA-Z]
identifier  {letter}({letter}|{digit})*

%%
[ \t]+                     ;
\n                         { countLines(); }
"//".*                     ;
"/*"(.|\n)*"*/"            ;
{digit}+                   { yylval.intVal = atoi(yytext); return INTEGER; }
{digit}+"."{digit}*        { yylval.realVal = atof(yytext); return REAL; }
\"([^\\\n]|(\\.))*\"       { yylval.strVal = strdup(yytext); return STRING; }
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
{identifier}               { yylval.strVal = strdup(yytext); return IDENTIFIER; }

%%
void countLines(void) { ++yylineno; }
