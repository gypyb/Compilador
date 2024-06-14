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
"if"                                            return IF;           
"else"                                          return ELSE; 
"end-if"                                        return ENDIF;
"AND"                                           return AND; 
"OR"                                            return OR;
":"                                             return DOSPUNTOS;
"("	                                            return APERTURAPARENTESIS;
")"	                                            return CIERREPARENTESIS;
"array"                                         return ARRAY;
"["                                             return APERTURA_CORCHETE;
"]"                                             return CIERRE_CORCHETE;
","                                             return COMA;
imprimir|escribir|print                         return IMPRIMIR;
[0-9]+                                          {yylval.enteroVal = atoi(yytext); return NUMERICO;}
[0-9]+.[0-9]+                                   {yylval.realVal   = atof(yytext); return NUMERICODECIMAL;}
_?[a-zA-Z0-9]+		                            {yylval.stringVal = strdup(yytext); printf(yytext);return IDENTIFICADOR;}
\"([^\\"]|\\.)*\"                               { yylval.stringVal = strdup(yytext); return CADENA; }
\n		                                        {num_linea++;} //Incrementa el numero de linea para saber en que num_linea se encuentra

%%
