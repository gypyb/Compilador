
#-------------- Declaracion de variables --------------
.data 
saltoLinea: .asciiz "\n"
zero: .float 0.0
uno: .float 1.0
resultado: .space 100
var_0: .float 5.000
var_2: .float 10.000
var_6: .float 7.000
var_8: .asciiz "mayor"
var_10: .asciiz "menor"

#--------------------- Ejecuciones ---------------------
.text
lwc1 $f31, zero
lwc1 $f0, var_0
lwc1 $f2, var_2
add.s $f3, $f2, $f0
la $t8, var_8
li $v0, 4
la $a0, var_8
addi $v0, $0, 4  #Movemos el registro 12 al 30 iniciado a false
syscall #Llamada al sistema
li $v0, 4
la $a0, saltoLinea
syscall #Llamada al sistema
