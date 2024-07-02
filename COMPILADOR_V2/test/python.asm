
#-------------- Declaracion de variables --------------
.data 
saltoLinea: .asciiz "\n"
zero: .float 0.0
uno: .float 1.0
resultado: .space 100
var_0: .float 1.000
var_1: .float 3.000
var_6: .float 11.000
var_7: .float 1.000
var_13: .float 10.000
var_19: .float 77.000

#--------------------- Ejecuciones ---------------------
.text
lwc1 $f31, zero
lwc1 $f0, var_0
lwc1 $f1, var_1
add.s $f2, $f0, $f1
li $v0, 2
add.s $f12, $f31, $f2
mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false
syscall #Llamada al sistema
li $v0, 4
la $a0, saltoLinea
syscall #Llamada al sistema
lwc1 $f6, var_6
lwc1 $f7, var_7
sub.s $f8, $f6, $f7
mov.s $f6, $f8
li $v0, 2
add.s $f12, $f31, $f8
mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false
syscall #Llamada al sistema
li $v0, 4
la $a0, saltoLinea
syscall #Llamada al sistema
li $v0, 2
add.s $f12, $f31, $f2
mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false
syscall #Llamada al sistema
li $v0, 4
la $a0, saltoLinea
syscall #Llamada al sistema
l.s $f29, zero
etiqueta0:
c.lt.s $f29, $f2
  bc1f fin_bucle0
    nop
lwc1 $f19, var_19
li $v0, 2
add.s $f12, $f31, $f19
mov.s $f30, $f12  #Movemos el registro 12 al 30 iniciado a false
syscall #Llamada al sistema
li $v0, 4
la $a0, saltoLinea
syscall #Llamada al sistema
l.s $f30, uno
add.s $f29, $f29, $f30
j etiqueta0
fin_bucle0:
l.s $f29, zero
