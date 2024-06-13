                      
#-------------- Declaracion de variables --------------
.data 
saltoLinea: .asciiz "\n"
zero: .float 0.0
var_0: .float 5.000
var_1: .float 7.000
var_2: .asciiz "a"
var_3: .asciiz "b"
var_4: .asciiz "c"
var_5: .asciiz "ba"
var_6: .asciiz zjk

#--------------------- Ejecuciones ---------------------
.text
lwc1 $f31, zero
lwc1 $f0, var_0
lwc1 $f2, var_1
c.ge.s $f0, $f2
lwc1 $f16, var_6
li $v0, 2
add.s $f12, $f31, $f16
mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false
syscall #Llamada al sistema
li $v0, 4
la $a0, saltoLinea
syscall #Llamada al sistema
