
#-------------- Declaracion de variables --------------
.data 
saltoLinea: .asciiz "\n"
zero: .float 0.0
uno: .float 1.0
resultado: .space 100
var_0: .float 1.000
var_2: .float 3.000
var_6: .float 7.000
var_8: .asciiz "3+5 es mayor que 7"
var_10: .asciiz "3+"
var_11: .asciiz " es menor que 7"

#--------------------- Ejecuciones ---------------------
.text
lwc1 $f31, zero
lwc1 $f0, var_0
lwc1 $f2, var_2
add.s $f3, $f2, $f0
la $t10, var_10
la $t11, var_11
la $s0, resultado
cadena_10: 
  lb $s1, 0($t10)
  beqz $s1, finCadena_10
  sb $s1, 0($s0)
  addi $s0, $s0, 1
  addi $t10, $t10, 1
  j cadena_10
finCadena_10: 
  la $t11, var_11
cadena_11: 
  lb $s1, 0($t11)
  beqz $s1, fin_11
  sb $s1, 0($s0)
  addi $s0, $s0, 1
  addi $t11, $t11, 1
  j cadena_11
fin_11: 
  sb $zero, 0($s0)
li $v0, 4
la $a0, resultado
addi $v0, $0, 4  #Movemos el registro 12 al 30 iniciado a false
syscall #Llamada al sistema
li $v0, 4
la $a0, saltoLinea
syscall #Llamada al sistema
