%option noyywrap

%{
#include "pyBis.h"
extern YYSTYPE yylval;
int num_linea = 1; 

%}

%%

"+"	                                            return SUMA;
"-"	                                            return RESTA;
"*"                                             return MULTIPLICACION; 
"/"                                             return DIVISION; 
"="	                                            return IGUAL;
"=="                                            return IGUALREL; 
"!="                                            return NOIGUALREL; 
"<"                                             return MENORREL; 
">"                                             return MAYORREL; 
"<="                                            return MENORIGUALREL; 
">="                                            return MAYORIGUALREL;  
"{"                                             return INICIOBLOQUE; 
"}"                                             return FINALBLOQUE; 
";"                                             return PUNTOYCOMA; 
"if"                                            return IF;           
"else"                                          return ELSE;        
"for"                                           return FOR;   
"while"                                         return WHILE;
"("	                                            return APERTURAPARENTESIS;
")"	                                            return CIERREPARENTESIS;
imprimir|escribir|print                         return IMPRIMIR;
[0-9]+                                          {yylval.enteroVal = atoi(yytext); return NUMERICO;}
[0-9]+.[0-9]+                                   {yylval.realVal   = atof(yytext); return NUMERICODECIMAL;}
_?[a-zA-Z0-9]+		                            {yylval.stringVal = strdup(yytext); printf(yytext);return IDENTIFICADOR;}
\"([^\\"]|\\.)*\"                               { yylval.strVal = strdup(yytext); return STRING; }
\n		                                        {num_linea++;} //Incrementa el numero de linea para saber en que num_linea se encuentra

%%
