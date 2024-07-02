%option noyywrap

%{
#include "pyBis.h"
extern YYSTYPE yylval;
int num_linea = 1; 
%}

%%


"+"	                                            return SUMA;
"-"	                                            return RESTA;

"/"                                             return DIVISION;
"*"                                             return MULTIPLICACION;
"("	                                            return APERTURAPARENTESIS;
")"	                                            return CIERREPARENTESIS;
"["	                                            return APERTURACORCHETE;
"]"	                                            return CIERRECORCHETE;

">="                                            return MAYOR_IGUAL_QUE;
"<="                                            return MENOR_IGUAL_QUE;
">"                                             return MAYOR_QUE;
"<"                                             return MENOR_QUE;

"=="	                                        return IGUAL_IGUAL;
"!="	                                        return NO_IGUAL;
"="	                                            return IGUAL;

":"                                             return DOSPUNTOS;
"and"                                           return AND;
"or"                                            return OR;
"while"                                         return WHILE;
"finWhile"                                      return FIN_BUCLE;
"for"                                           return FOR_BUCLE;
"finFor"                                        return FIN_FOR;
"in"                                            return IN;
"range"                                         return RANGE;
"if"                                            return IF_CONDICION;
"elif"                                          return ELIF_CONDICION;
"else"                                          return ELSE_CONDICION;
"finIf"                                         return FIN_CONDICION;
","                                             return COMA;

"#"(.)*                                         
\"\"\"([^\"]|\"[^\"])*\"\"\"                    { int num_newlines = 0; char *p; for (p = yytext; *p; p++) { if (*p == '\n') { num_newlines++; } } int old_number = num_linea; num_linea += num_newlines; }
\"[^\"\n]*\"                                    {yylval.stringVal = strdup(yytext + 1); yylval.stringVal[strlen(yylval.stringVal) - 1] = '\0'; printf(yytext);return CADENA;}

print                                           return IMPRIMIR;
[0-9]+                                          {yylval.enteroVal = atoi(yytext); return NUMERICO;}
[0-9]+.[0-9]+                                   {yylval.realVal   = atof(yytext); return NUMERICODECIMAL;}
_?[a-zA-Z0-9_]+		                            {yylval.stringVal = strdup(yytext); return IDENTIFICADOR;}
                                        

\n                                              { printf("\n--------------- Linea de codigo %d ----------------\n\n", num_linea); num_linea++;}
[ \t]                                           { /* no se hace nada */ }


%%
