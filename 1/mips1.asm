.data
prompt_1: .asciiz "\nWybierz dzialanie wpisując na klawiaturze 1-3: \n 1. (a + b)/c \n 2. a/(bc) \n 3. (2 * a - b)/c\n" # prompt wyboru działania
prompt_zmiennych: .asciiz "\nWpisz wartosc zmiennej " # prompty wyboru zmiennych a, b i c

komunikat_wyboru: .asciiz "\nHej wybrales rownanie nr. "

komunikat_dzielenia_przez_zero: .asciiz "\nWykryto dzielenie przez zero!"

output: .asciiz "\n Wynikiem dzialania jest: "
reszta: .asciiz "\n Reszta: "

kontynuuj: .asciiz "\n Czy kontynuowac? t/n"

.text
main:
li $v0, 4
la $a0, prompt_1 # wypisanie prompt 1 - wybór działania

syscall
#wczytanie ciagu znakowego
li $v0, 12  # syscall dla read_char
syscall
move $t0, $v0 # wczytujemy input do $t0

li $t1, 49      # '1' w ASCII to 49
beq $t0, $t1, wczytaj_zmienne

li $t1, 50      # '2'
beq $t0, $t1, wczytaj_zmienne

li $t1, 51      # '3'
beq $t0, $t1, wczytaj_zmienne

j main

wczytaj_zmienne:

# a: $t3, b: $t4, c: $t5

skok1: # wybór (a + b) / c
jal wypisz_wybor
jal wybor_zmiennych
beq $t5, $zero, przez_zero
add $t3, $t3, $t4 # t3 = t3 + t4 = a + b
div $t3, $t5 # t3/t5 = (a + b)/c
mflo $t0 # $t0 = wynik (iloraz)
mfhi $t1 # $t1 = reszta
j wyswietl_wyniki

skok2: # wybór a / (bc)
jal wypisz_wybor
jal wybor_zmiennych
beq $t5, $zero, przez_zero
beq $t4, $zero, przez_zero
mul $t4, $t4, $t5 # t4 = t4 * t5 = bc
div $t3, $t4 # t3 / t4 = a / bc
mflo $t0 # $t0 = wynik (iloraz)
mfhi $t1 # $t1 = reszta
j wyswietl_wyniki

skok3: # wybór (2 * a - b) / c
jal wypisz_wybor
jal wybor_zmiennych
beq $t5, $zero, przez_zero
li $t6, 2
mul $t3, $t3, $t6 # t3 = 2 * t3 = 2a 
sub $t3, $t3, $t4 # t3 = t3 - t4 = 2a - b
div $t3, $t5  # t3 / t5 = (2a - b) / c
mflo $t0 # $t0 = wynik (iloraz)
mfhi $t1 # $t1 = reszta
j wyswietl_wyniki

wypisz_wybor:
# wypisz komunikat tekstowy
li $v0, 4
la $a0, komunikat_wyboru
syscall

# wypisz numer wyboru jako znak
li $v0, 11         # syscall: print_char
move $a0, $t0      # w $t0 mamy ASCII '1', '2', '3'
syscall

jr $ra             # powrót

wybor_zmiennych:

move $t7, $ra # nie chcemy zgubic tego gdzie chcemy wrocic po jal!

li $a0, 97 # 97 = ASCII 'a'
jal wybor_zmiennej
move $t3, $t2 # wynik przenosimy t3 - tu będziemy mieć wartość zmiennej a


li $a0, 98 # 98 = ASCII 'b'
jal wybor_zmiennej
move $t4, $t2 # wynik przenosimy do t4 - tu będziemy mieć wartość zmiennej b

li $a0, 99 # 99 = ASCII 'c'
jal wybor_zmiennej
move $t5, $t2 # wynik przenosimy do t5 - tu będziemy mieć wartość zmiennej c

move $ra, $t7 # chcemy wrócić w dobre miejsce!

jr $ra

wybor_zmiennej:
move $t6, $a0

li $v0, 4
la $a0, prompt_zmiennych
syscall

move $a0, $t6

li $v0, 11       # syscall: print_char
syscall

li $v0, 5        # syscall 5 = read_int
syscall
move $t2, $v0    # przenosimy wynik (int) z $v0 do $t2
jr $ra

przez_zero:
li $v0, 4
la $a0, komunikat_dzielenia_przez_zero
syscall
j main

wyswietl_wyniki:

la $t2, output
move $t3, $t0
jal wyniki

la $t2, reszta
move $t3, $t1
jal wyniki

j koniec


wyniki:
# wynik: tekst- tytuł wyniki
li $v0, 4
move $a0, $t2
syscall

# wynik: int
li $v0, 1
move $a0, $t3
syscall

jr $ra

koniec:
# spytaj czy kontynuowac
li $v0, 4
la $a0, kontynuuj
syscall

# Wpiszmy chary
li $v0, 12  # syscall dla read_char
syscall
move $t0, $v0 # wczytujemy input do $t0

li $t1, 116 # ASCII 't'
beq $t0, $t1, main # czy input to t?

li $t1, 110 # ASCII 'n'
bne $t0, $t1, koniec # czy input to nie n? wtedy spytajmy sie jeszcze raz! 

