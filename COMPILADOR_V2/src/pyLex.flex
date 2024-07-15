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
"elif"                                          return ELIF; 
"else"                                          return ELSE; 
"finIf"                                         return ENDIF;
"and"                                           return AND; 
"or"                                            return OR;
"while"                                         return WHILE;
"finWhile"                                      return ENDWHILE;
"for"                                           return FOR;
"finFor"                                        return ENDFOR;
"in"                                            return IN;
"range"                                         return RANGE;
":"                                             return DOSPUNTOS;
"("	                                            return APERTURAPARENTESIS;
")"	                                            return CIERREPARENTESIS;
"["                                             return APERTURACORCHETE;
"]"                                             return CIERRECORCHETE;
","                                             return COMA;
print                                           return IMPRIMIR;
[-]?[0-9]+                                          {yylval.enteroVal = atoi(yytext); return NUMERICO;}
[-]?[0-9]+.[0-9]+                                   {yylval.realVal   = atof(yytext); return NUMERICODECIMAL;}
_?[a-zA-Z0-9_]+		                            {yylval.stringVal = strdup(yytext); return IDENTIFICADOR;}
\"[^\"\n]*\"                                    {yylval.stringVal = strdup(yytext + 1); yylval.stringVal[strlen(yylval.stringVal) - 1] = '\0'; printf(yytext);return CADENA;}
\n                                              { printf("\n--------------- Linea de codigo %d ----------------\n\n", num_linea); num_linea++;}
[ \t]                                           { /* no se hace nada */ }

"#"(.)*                                         // Ignorar comentarios de una línea
\"\"\"([^\"]|\"[^\"])*\"\"\"                    { int num_newlines = 0; char *p; for (p = yytext; *p; p++) { if (*p == '\n') { num_newlines++; } } int old_number = num_linea; num_linea += num_newlines; }

%%
