.data
    # Komunikaty menu
    powitanie: .asciiz "\n=== KALKULATOR WYRAZEN ALGEBRAICZNYCH ===\n"
    instrukcja: .asciiz "Wpisz liczby i operatory kolejno na stos\n"
    instrukcja2: .asciiz "Kolejnosc operacji jest zachowana (*, / przed +, -)\n"
    instrukcja3: .asciiz "Zakoncz wyrazenie wpisujac '=' lub naciskajac Enter\n\n"
    
    # Prosby o dane
    prosba_element: .asciiz "\nPodaj liczbe lub operator (+, -, *, /, =): "
    
    # Wyniki
    wynik_tekst: .asciiz "\nWynik: "
    kontynuuj_pytanie: .asciiz "\nCzy chcesz kontynuowac? (T/t=tak, N/n=nie): "
    
    # Komunikaty bledow
    blad_kontynuacja: .asciiz "\nBlad: Wpisz T/t dla tak lub N/n dla nie.\n"
    blad_dzielenie_zero: .asciiz "Blad: Dzielenie przez zero!\n"
    blad_przepelnienie: .asciiz "\nBlad: Przepelnienie arytmetyczne!\n"
    blad_dane: .asciiz "\nBlad: Nieprawidlowe dane wejsciowe!\n"
    blad_nieskonczonosc: .asciiz "\nBlad: Wprowadzona liczba przekracza zakres!\n"
    blad_skladnia: .asciiz "\nBlad: Nieprawidlowa skladnia wyrazenia!\n"
    blad_stos_pusty: .asciiz "\nBlad: Za malo operandow dla operatora!\n"
    blad_za_duzo_operandow: .asciiz "\nBlad: Za duzo operandow!\n"
    blad_operator: .asciiz "\nBlad: Nieprawidlowy operator! Uzyj +, -, *, / lub =\n"
    
    # Stale znakow
    znak_plus: .byte 43     # '+'
    znak_minus: .byte 45    # '-'  
    znak_razy: .byte 42     # '*'
    znak_dziel: .byte 47    # '/'
    znak_rowna: .byte 61    # '='
    znak_T: .byte 84        # 'T'
    znak_t: .byte 116       # 't'
    znak_N: .byte 78        # 'N'
    znak_n: .byte 110       # 'n'
    
    # Stale liczbowe
    zero_double: .double 0.0
    dwa_double: .double 2.0
    
    pozegnanie: .asciiz "Dziekuje za korzystanie z kalkulatora!\n"
    
    # Stos dla liczb (maksymalnie 32 liczby typu double)
    stos_liczb: .space 256  # 32 * 8 bajtow
    wskaznik_stosu: .word 0  # indeks wierzcholka stosu
    
    # Stos dla operatorów (maksymalnie 64 operatory)
    stos_operatorow: .space 64
    wskaznik_op_stosu: .word 0
    
    # Flaga pierwszej liczby
    pierwsza_liczba: .word 1
    
    # Pomocnicze stringi
    newline_str: .asciiz "\n"
    prosba_liczba: .asciiz "\nPodaj liczbe: "

.text
.globl main

main:
    # Wyswietl powitanie i instrukcje
    li $v0, 4
    la $a0, powitanie
    syscall
    
    li $v0, 4
    la $a0, instrukcja
    syscall
    
    li $v0, 4
    la $a0, instrukcja2
    syscall
    
    li $v0, 4
    la $a0, instrukcja3
    syscall
    
glowna_petla:
    # Wyczysc stosy i ustaw flagi
    sw $zero, wskaznik_stosu
    sw $zero, wskaznik_op_stosu
    li $t0, 1
    sw $t0, pierwsza_liczba
    
petla_wczytywania:
    li $v0, 4
    la $a0, prosba_element
    syscall
    
    # Wczytaj znak operatora
    li $v0, 12
    syscall
    move $t0, $v0
    
    # Sprawdz czy to znak rownosci (koniec wyrazenia)
    lb $t1, znak_rowna
    beq $t0, $t1, zakoncz_wyrazenie
    
    # Sprawdz czy to operator
    lb $t1, znak_plus
    beq $t0, $t1, obsluz_operator_plus
    
    lb $t1, znak_minus
    beq $t0, $t1, sprawdz_operator_minus
    
    lb $t1, znak_razy
    beq $t0, $t1, obsluz_operator_mnozenie
    
    lb $t1, znak_dziel
    beq $t0, $t1, obsluz_operator_dzielenie
    
    # Sprawdz czy to cyfra (poczatek liczby)
    blt $t0, 48, blad_nieprawidlowy_operator  # mniejsze od '0'
    bgt $t0, 57, blad_nieprawidlowy_operator  # wieksze od '9'
    
    # To cyfra - wczytaj cala liczbe
    j wczytaj_liczbe

sprawdz_operator_minus:
    # Sprawdz czy to pierwszy element (liczba ujemna) czy operator
    lw $t1, pierwsza_liczba
    beq $t1, 1, wczytaj_liczbe  # jesli pierwsza liczba, to liczba ujemna
    j obsluz_operator_minus     # w przeciwnym razie operator

wczytaj_liczbe:
    # Cofnij wskaznik stdin zeby ponownie wczytac cyfre
    # (nie ma bezposredniego sposobu w MARS, wiec po prostu wczytamy liczbe)
    li $v0, 4
    la $a0, newline_str
    syscall
    
    li $v0, 4
    la $a0, prosba_liczba
    syscall
    
    li $v1, 0  # resetuj wyjatek
    li $v0, 7  # wczytaj double
    syscall
    
    bnez $v1, blad_danych_liczba
    
    # Sprawdz prawidlowosc liczby
    jal sprawdz_prawidlowosc_liczby
    beq $v0, 0, blad_liczby_nieskonczonosc
    
    # Dodaj liczbe na stos
    jal push_liczba
    beq $v0, 0, blad_stos_pelny
    
    # Ustaw flage ze to juz nie pierwsza liczba
    sw $zero, pierwsza_liczba
    
    j petla_wczytywania

obsluz_operator_plus:
    li $a0, 43
    j przetwarz_operator

obsluz_operator_minus:
    li $a0, 45
    j przetwarz_operator

obsluz_operator_mnozenie:
    li $a0, 42
    j przetwarz_operator

obsluz_operator_dzielenie:
    li $a0, 47
    j przetwarz_operator

przetwarz_operator:
    # Sprawdz czy mamy przynajmniej jedna liczbe na stosie
    lw $t0, wskaznik_stosu
    beq $t0, 0, blad_brak_operandu
    
    # Zastosuj algorytm Shunting Yard
    jal obsluz_operator_shunting
    beq $v0, 0, blad_operatora
    
    j petla_wczytywania

zakoncz_wyrazenie:
    # Wykonaj wszystkie pozostale operatory ze stosu
    jal wykonaj_pozostale_operatory
    beq $v0, 0, blad_operatora
    
    # Sprawdz czy na stosie zostala dokladnie jedna liczba
    lw $t0, wskaznik_stosu
    beq $t0, 0, blad_brak_wyniku
    bne $t0, 1, blad_za_duzo_liczb
    
    # Pobierz wynik ze stosu
    jal pop_liczba
    mov.d $f4, $f0
    
    j wyswietl_wynik

# Funkcja sprawdzajaca prawidlowosc liczby (bez zmian z oryginalnego kodu)
sprawdz_prawidlowosc_liczby:
    c.eq.d $f0, $f0
    bc1f sprawdz_liczba_nieprawidlowa_ret
    
    ldc1 $f2, zero_double
    c.eq.d $f0, $f2
    bc1t sprawdz_liczba_prawidlowa_ret

    ldc1 $f8, dwa_double
    mul.d $f6, $f0, $f8
    
    c.eq.d $f0, $f6
    bc1t sprawdz_liczba_nieprawidlowa_ret
    
sprawdz_liczba_prawidlowa_ret:
    li $v0, 1
    jr $ra
    
sprawdz_liczba_nieprawidlowa_ret:
    li $v0, 0
    jr $ra

# Funkcja dodajaca liczbe na stos
push_liczba:
    lw $t0, wskaznik_stosu
    bge $t0, 32, stos_pelny
    
    sll $t1, $t0, 3
    la $t2, stos_liczb
    add $t2, $t2, $t1
    
    sdc1 $f0, 0($t2)
    
    addi $t0, $t0, 1
    sw $t0, wskaznik_stosu
    
    li $v0, 1
    jr $ra

stos_pelny:
    li $v0, 0
    jr $ra

# Funkcja pobierajaca liczbe ze stosu
pop_liczba:
    lw $t0, wskaznik_stosu
    beq $t0, 0, stos_pusty
    
    addi $t0, $t0, -1
    sw $t0, wskaznik_stosu
    
    sll $t1, $t0, 3
    la $t2, stos_liczb
    add $t2, $t2, $t1
    
    ldc1 $f0, 0($t2)
    
    li $v0, 1
    jr $ra

stos_pusty:
    li $v0, 0
    jr $ra

# Funkcja dodajaca operator na stos
push_operator:
    lw $t0, wskaznik_op_stosu
    bge $t0, 64, stos_op_pelny
    
    la $t1, stos_operatorow
    add $t1, $t1, $t0
    sb $a0, 0($t1)
    
    addi $t0, $t0, 1
    sw $t0, wskaznik_op_stosu
    
    li $v0, 1
    jr $ra

stos_op_pelny:
    li $v0, 0
    jr $ra

# Funkcja pobierajaca operator ze stosu
pop_operator:
    lw $t0, wskaznik_op_stosu
    beq $t0, 0, stos_op_pusty
    
    addi $t0, $t0, -1
    sw $t0, wskaznik_op_stosu
    
    la $t1, stos_operatorow
    add $t1, $t1, $t0
    lb $v1, 0($t1)
    
    li $v0, 1
    jr $ra

stos_op_pusty:
    li $v0, 0
    jr $ra

# Funkcja sprawdzajaca priorytet operatora
priorytet_operatora:
    beq $a0, 43, priorytet_1  # +
    beq $a0, 45, priorytet_1  # -
    beq $a0, 42, priorytet_2  # *
    beq $a0, 47, priorytet_2  # /
    li $v0, 0
    jr $ra

priorytet_1:
    li $v0, 1
    jr $ra

priorytet_2:
    li $v0, 2
    jr $ra

# Funkcja obslugujaca operator wedlug algorytmu Shunting Yard
obsluz_operator_shunting:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)
    
    move $s0, $a0  # zapisz operator
    
    # Pobierz priorytet aktualnego operatora
    jal priorytet_operatora
    move $t0, $v0

petla_shunting:
    # Sprawdz czy stos operatorow nie jest pusty
    lw $t1, wskaznik_op_stosu
    beq $t1, 0, dodaj_operator_shunting
    
    # Pobierz operator z wierzcholka (bez usuwania)
    addi $t2, $t1, -1
    la $t3, stos_operatorow
    add $t3, $t3, $t2
    lb $a0, 0($t3)
    
    # Sprawdz priorytet operatora na stosie
    jal priorytet_operatora
    move $t4, $v0
    
    # Jesli priorytet na stosie >= aktualnego, wykonaj operator ze stosu
    blt $t4, $t0, dodaj_operator_shunting
    
    # Wykonaj operator ze stosu
    jal pop_operator
    move $a0, $v1
    jal wykonaj_operator
    beq $v0, 0, blad_shunting
    
    j petla_shunting

dodaj_operator_shunting:
    # Dodaj aktualny operator na stos
    move $a0, $s0
    jal push_operator
    beq $v0, 0, blad_shunting
    
    li $v0, 1
    j koniec_shunting

blad_shunting:
    li $v0, 0

koniec_shunting:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Funkcja wykonujaca operator
wykonaj_operator:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Pobierz dwie liczby ze stosu
    jal pop_liczba
    beq $v0, 0, blad_za_malo_operandow_op
    mov.d $f22, $f0  # druga liczba (b)
    
    jal pop_liczba
    beq $v0, 0, blad_za_malo_operandow_op
    mov.d $f20, $f0  # pierwsza liczba (a)
    
    # Wykonaj operacje: a op b
    beq $a0, 43, wykonaj_dodawanie_op
    beq $a0, 45, wykonaj_odejmowanie_op
    beq $a0, 42, wykonaj_mnozenie_op
    beq $a0, 47, wykonaj_dzielenie_op
    
    li $v0, 0
    j koniec_wykonaj_operator

wykonaj_dodawanie_op:
    add.d $f0, $f20, $f22
    j sprawdz_wynik_op

wykonaj_odejmowanie_op:
    sub.d $f0, $f20, $f22
    j sprawdz_wynik_op

wykonaj_mnozenie_op:
    mul.d $f0, $f20, $f22
    j sprawdz_wynik_op

wykonaj_dzielenie_op:
    # Sprawdz dzielenie przez zero
    ldc1 $f6, zero_double
    c.eq.d $f22, $f6
    bc1t blad_dzielenia_przez_zero_op
    
    div.d $f0, $f20, $f22
    j sprawdz_wynik_op

sprawdz_wynik_op:
    # Sprawdz prawidlowosc wyniku
    jal sprawdz_prawidlowosc_liczby
    beq $v0, 0, blad_przepelnienia_op
    
    # Dodaj wynik na stos
    jal push_liczba
    beq $v0, 0, blad_stos_op
    
    li $v0, 1
    j koniec_wykonaj_operator

blad_za_malo_operandow_op:
    li $v0, 4
    la $a0, blad_stos_pusty
    syscall
    li $v0, 0
    j koniec_wykonaj_operator

blad_dzielenia_przez_zero_op:
    li $v0, 4
    la $a0, blad_dzielenie_zero
    syscall
    li $v0, 0
    j koniec_wykonaj_operator

blad_przepelnienia_op:
    li $v0, 4
    la $a0, blad_przepelnienie
    syscall
    li $v0, 0
    j koniec_wykonaj_operator

blad_stos_op:
    li $v0, 0

koniec_wykonaj_operator:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja wykonujaca wszystkie pozostale operatory ze stosu
wykonaj_pozostale_operatory:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

petla_pozostalych:
    lw $t0, wskaznik_op_stosu
    beq $t0, 0, koniec_pozostalych
    
    jal pop_operator
    move $a0, $v1
    jal wykonaj_operator
    beq $v0, 0, blad_pozostale
    
    j petla_pozostalych

koniec_pozostalych:
    li $v0, 1
    j koniec_wykonaj_pozostale

blad_pozostale:
    li $v0, 0

koniec_wykonaj_pozostale:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

wyswietl_wynik:
    li $v0, 4
    la $a0, wynik_tekst
    syscall
    
    li $v0, 3
    mov.d $f12, $f4
    syscall
    
    j pytaj_o_kontynuacje

pytaj_o_kontynuacje:
pobierz_kontynuacje:
    li $v0, 4
    la $a0, kontynuuj_pytanie
    syscall
    
    li $v0, 12
    syscall
    
    move $t0, $v0
    
    lb $t1, znak_T
    beq $t0, $t1, glowna_petla
    
    lb $t1, znak_t
    beq $t0, $t1, glowna_petla
    
    lb $t1, znak_N
    beq $t0, $t1, zakoncz_program
    
    lb $t1, znak_n
    beq $t0, $t1, zakoncz_program
    
    li $v0, 4
    la $a0, blad_kontynuacja
    syscall
    j pobierz_kontynuacje

# Obsluga bledow
blad_nieprawidlowy_operator:
    li $v0, 4
    la $a0, blad_operator
    syscall
    j petla_wczytywania

blad_danych_liczba:
    li $v0, 4
    la $a0, blad_dane
    syscall
    j petla_wczytywania

blad_liczby_nieskonczonosc:
    li $v0, 4
    la $a0, blad_nieskonczonosc
    syscall
    j petla_wczytywania

blad_stos_pelny:
    li $v0, 4
    la $a0, blad_skladnia
    syscall
    j glowna_petla

blad_brak_operandu:
    li $v0, 4
    la $a0, blad_stos_pusty
    syscall
    j petla_wczytywania

blad_operatora:
    li $v0, 4
    la $a0, blad_skladnia
    syscall
    j glowna_petla

blad_brak_wyniku:
    li $v0, 4
    la $a0, blad_skladnia
    syscall
    j glowna_petla

blad_za_duzo_liczb:
    li $v0, 4
    la $a0, blad_za_duzo_operandow
    syscall
    j glowna_petla

zakoncz_program:
    li $v0, 4
    la $a0, pozegnanie
    syscall
    
    li $v0, 10
    syscall

# =====================================
# OBSLUGA WYJATKOW SYSTEMOWYCH
# =====================================

.kdata
    komunikat_przepelnienie: .asciiz "WYJATEK: Przepelnienie arytmetyczne wykryte przez procesor!\n"

.ktext 0x80000180
__punkt_wejscia_jadra:
    mfc0 $k0, $13
    andi $k1, $k0, 0x00007c
    srl $k1, $k1, 2

__obsluga_wyjatku:
    beq $k1, 12, __wyjatek_przepelnienie
    j __wyjatek_ogolny

__wyjatek_przepelnienie:
    li $v0, 4
    la $a0, komunikat_przepelnienie
    syscall
    li $v1, 0
    j __powrot_z_wyjatku

__wyjatek_ogolny:
    li $v1, 1
    j __powrot_z_wyjatku

__powrot_z_wyjatku:
    mfc0 $k0, $14
    addi $k0, $k0, 4
    mtc0 $k0, $14
    eret