# Kalkulator dla liczb zmiennoprzecinkowych podwojnej precyzji
# Program obsluguje podstawowe operacje arytmetyczne z obsluga wyjatkow i walidacja danych

.data
    # Komunikaty menu
    powitanie: .asciiz "\n=== KALKULATOR LICZB ZMIENNOPRZECINKOWYCH ===\n"
    menu: .asciiz "\nWybierz operacje:\n+ Dodawanie\n- Odejmowanie\n* Mnozenie\n/ Dzielenie\nWpisz znak operacji (+, -, *, /): "
    
    # Prosby o dane
    prosba_pierwsza: .asciiz "\nPodaj pierwsza liczbe: "
    prosba_druga: .asciiz "\nPodaj druga liczbe: "
    
    # Wyniki
    wynik_tekst: .asciiz "\nWynik: "
    kontynuuj_pytanie: .asciiz "\nCzy chcesz kontynuowac? (T/t=tak, N/n=nie): "
    
    # Komunikaty bledow
    blad_wybor: .asciiz "\nBlad: Nieprawidlowy znak! Wpisz +, -, *, lub /\n"
    blad_kontynuacja: .asciiz "\nBlad: Wpisz T/t dla tak lub N/n dla nie.\n"
    blad_dzielenie_zero: .asciiz "Blad: Dzielenie przez zero!\n"
    blad_przepelnienie: .asciiz "\nBlad: Przepelnienie arytmetyczne!\n"
    blad_dane: .asciiz "\nBlad: Nieprawidlowe dane wejsciowe! Liczba jest za duza lub nieprawidlowa.\n"
    blad_nieskonczonosc: .asciiz "\nBlad: Wprowadzona liczba przekracza zakres zmiennych podwojnej precyzji!\n"
    
    # Komunikaty operacji
    dodawanie_tekst: .asciiz "\nDodawanie: "
    odejmowanie_tekst: .asciiz "\nOdejmowanie: "
    mnozenie_tekst: .asciiz "\nMnozenie: "
    dzielenie_tekst: .asciiz "\nDzielenie: "
    
    # Stale znakow
    znak_plus: .byte 43     # '+'
    znak_minus: .byte 45    # '-'  
    znak_razy: .byte 42     # '*'
    znak_dziel: .byte 47    # '/'
    znak_T: .byte 84        # 'T'
    znak_t: .byte 116       # 't'
    znak_N: .byte 78        # 'N'
    znak_n: .byte 110       # 'n'
    
    # Stale liczbowe
    zero_double: .double 0.0
    jeden_double: .double 1.0
    
    pozegnanie: .asciiz "Dziekuje za korzystanie z kalkulatora!\n"

.text
.globl main

main:
    # Wyswietl powitanie
    li $v0, 4
    la $a0, powitanie
    syscall
    
glowna_petla:
    # Wyswietl menu
    li $v0, 4
    la $a0, menu
    syscall
    
pobierz_operacje:
    # Wczytaj znak operacji
    li $v0, 8           # syscall dla wczytania stringa
    la $a0, bufor_znak  # adres bufora
    li $a1, 2           # maksymalnie 2 znaki (znak + \n)
    syscall
    
    # Wczytaj pierwszy znak z bufora
    lb $t0, bufor_znak
    
    # Sprawdz jaki znak zostal wpisany
    lb $t1, znak_plus
    beq $t0, $t1, wczytaj_liczby
    
    lb $t1, znak_minus
    beq $t0, $t1, wczytaj_liczby
    
    lb $t1, znak_razy
    beq $t0, $t1, wczytaj_liczby
    
    lb $t1, znak_dziel
    beq $t0, $t1, wczytaj_liczby
    
    # Jesli zaden nie pasuje, wyswietl blad i pytaj ponownie
    li $v0, 4
    la $a0, blad_wybor
    syscall
    j pobierz_operacje

wczytaj_liczby:
    # Zapisz wybrany znak operacji do uzycia pozniej
    move $s0, $t0
    
pobierz_pierwsza_liczba:
    li $v1, 0 # resetuj wyjatek
    # Wczytaj pierwsza liczbe
    li $v0, 4
    la $a0, prosba_pierwsza
    syscall
    
    li $v0, 7      # syscall dla double
    syscall
    mov.d $f20, $f0  # zapisz pierwsza liczbe w $f20
    
    bnez $v1, blad_danych_pierwsza # jesli wyjatek "nieokreslony" to oznacza ze zle dane!
    
    # Sprawdz czy liczba jest prawidlowa (nie Infinity ani NaN)
    mov.d $f0, $f20  # przygotuj argument dla funkcji
    jal sprawdz_prawidlowosc_liczby
    beq $v0, 0, blad_pierwszej_liczby  # jesli funkcja zwroci 0, liczba nieprawidlowa

pobierz_druga_liczba:
    li $v1, 0 # resetuj wyjatek
    # Wczytaj druga liczbe
    li $v0, 4
    la $a0, prosba_druga
    syscall
    
    li $v0, 7      # syscall dla double
    syscall
    mov.d $f22, $f0  # zapisz druga liczbe w $f22
    
    beq $v1, 1, blad_danych_druga # jesli wyjatek "nieokreslony" to oznacza ze zle dane!
    
    # Sprawdz czy liczba jest prawidlowa (nie Infinity ani NaN)
    mov.d $f0, $f22  # przygotuj argument dla funkcji
    jal sprawdz_prawidlowosc_liczby
    beq $v0, 0, blad_drugiej_liczby  # jesli funkcja zwroci 0, liczba nieprawidlowa
    
    # Wykonaj operacje na podstawie zapisanego znaku
    lb $t1, znak_plus
    beq $s0, $t1, wykonaj_dodawanie
    
    lb $t1, znak_minus
    beq $s0, $t1, wykonaj_odejmowanie
    
    lb $t1, znak_razy
    beq $s0, $t1, wykonaj_mnozenie
    
    lb $t1, znak_dziel
    beq $s0, $t1, wykonaj_dzielenie

# Funkcja sprawdzajaca prawidlowosc liczby
# Argument: $f0 - liczba do sprawdzenia
# Zwraca: $v0 = 1 jesli liczba prawidlowa, 0 jesli nieprawidlowa
sprawdz_prawidlowosc_liczby:
    # Sprawdz czy liczba to NaN (NaN != NaN)
    c.eq.d $f0, $f0
    bc1f liczba_nieprawidlowa  # jesli nie rowne sobie, to NaN
    
    # Sprawdz czy liczba to nieskończonosc
    # Nieskończonosc ma wlasciwosc ze inf + 1 = inf
    ldc1 $f2, jeden_double
    add.d $f6, $f0, $f2      # $f4 = liczba + 1
    c.eq.d $f0, $f6          # porownaj liczba z liczba+1
    bc1t liczba_nieprawidlowa # jesli rowne, to nieskonczonosc
    
    # Liczba prawidlowa
    li $v0, 1
    jr $ra
    
liczba_nieprawidlowa:
    li $v0, 0
    jr $ra

wykonaj_dodawanie:
    li $v0, 4
    la $a0, dodawanie_tekst
    syscall
    
    li $v0, 3
    mov.d $f12, $f20
    syscall
    
    li $v0, 11
    lb $a0, znak_plus
    syscall
    
    li $v0, 3
    mov.d $f12, $f22
    syscall
    
    add.d $f4, $f20, $f22    # $f4 = pierwsza + druga
    j sprawdz_wynik_operacji

wykonaj_odejmowanie:
    li $v0, 4
    la $a0, odejmowanie_tekst
    syscall
    
    li $v0, 3
    mov.d $f12, $f20
    syscall
    
    li $v0, 11
    lb $a0, znak_minus
    syscall
    
    li $v0, 3
    mov.d $f12, $f22
    syscall
    
    sub.d $f4, $f20, $f22    # $f4 = pierwsza - druga
    j sprawdz_wynik_operacji

wykonaj_mnozenie:
    li $v0, 4
    la $a0, mnozenie_tekst
    syscall
    
    li $v0, 3
    mov.d $f12, $f20
    syscall
    
    li $v0, 11
    lb $a0, znak_razy
    syscall
    
    li $v0, 3
    mov.d $f12, $f22
    syscall
    
    mul.d $f4, $f20, $f22    # $f4 = pierwsza * druga
    j sprawdz_wynik_operacji

wykonaj_dzielenie:
    # Sprawdz dzielenie przez zero
    ldc1 $f6, zero_double
    c.eq.d $f22, $f6
    bc1t blad_dzielenia_przez_zero
    
    li $v0, 4
    la $a0, dzielenie_tekst
    syscall
    
    li $v0, 3
    mov.d $f12, $f20
    syscall
    
    li $v0, 11
    lb $a0, znak_dziel
    syscall
    
    li $v0, 3
    mov.d $f12, $f22
    syscall
    
    div.d $f4, $f20, $f22    # $f4 = pierwsza / druga
    j sprawdz_wynik_operacji

sprawdz_wynik_operacji:
    # Sprawdz czy wynik jest prawidlowy
    mov.d $f0, $f4  # przygotuj argument
    jal sprawdz_prawidlowosc_liczby
    beq $v0, 0, blad_przepelnienia  # jesli nieprawidlowy, pokaz blad przepelnienia
    j wyswietl_wynik

wyswietl_wynik:
    # Wyswietl tekst wyniku
    li $v0, 4
    la $a0, wynik_tekst
    syscall
    
    # Wyswietl liczbe zmiennoprzecinkowa podwojnej precyzji
    li $v0, 3
    mov.d $f12, $f4
    syscall
    
    j pytaj_o_kontynuacje

pytaj_o_kontynuacje:
pobierz_kontynuacje:
    # Zapytaj czy kontynuowac
    li $v0, 4
    la $a0, kontynuuj_pytanie
    syscall
    
    # Wczytaj odpowiedz
    li $v0, 12           # syscall dla wczytania chara
    syscall
    
    # Wczytaj pierwszy znak z bufora
    move $t0, $v0
    
    # Sprawdz czy to 'T' lub 't' (tak)
    lb $t1, znak_T
    beq $t0, $t1, glowna_petla
    
    lb $t1, znak_t
    beq $t0, $t1, glowna_petla
    
    # Sprawdz czy to 'N' lub 'n' (nie)
    lb $t1, znak_N
    beq $t0, $t1, zakoncz_program
    
    lb $t1, znak_n
    beq $t0, $t1, zakoncz_program
    
    # Jesli zaden nie pasuje, wyswietl blad i pytaj ponownie
    li $v0, 4
    la $a0, blad_kontynuacja
    syscall
    j pobierz_kontynuacje

blad_wyboru:
    li $v0, 4
    la $a0, blad_wybor
    syscall
    j pobierz_operacje

blad_pierwszej_liczby:
    li $v0, 4
    la $a0, blad_nieskonczonosc
    syscall
    j pobierz_pierwsza_liczba

blad_danych_pierwsza:
    li $v0, 4
    la $a0, blad_dane
    syscall
    j pobierz_pierwsza_liczba  # Wroc do wczytywania liczb

blad_drugiej_liczby:
    li $v0, 4
    la $a0, blad_nieskonczonosc
    syscall
    j pobierz_druga_liczba
    
blad_danych_druga:
    li $v0, 4
    la $a0, blad_dane
    syscall
    j pobierz_druga_liczba  # Wroc do wczytywania liczb

blad_dzielenia_przez_zero:
    li $v0, 4
    la $a0, blad_dzielenie_zero
    syscall
    j pytaj_o_kontynuacje

blad_przepelnienia:
    li $v0, 4
    la $a0, blad_przepelnienie
    syscall
    j pytaj_o_kontynuacje

zakoncz_program:
    li $v0, 4
    la $a0, pozegnanie
    syscall
    
    # Zakończ program
    li $v0, 10
    syscall

# =====================================
# OBSLUGA WYJATKOW SYSTEMOWYCH
# =====================================

.kdata
    komunikat_przepelnienie: .asciiz "WYJATEK: Przepelnienie arytmetyczne wykryte przez procesor!\n"

.ktext 0x80000180
__punkt_wejscia_jadra:
    # Pobierz wartosc z rejestru przyczyny i skopiuj do $k0
    mfc0 $k0, $13
    
    # Maskuj wszystkie bity oprocz kodu wyjatku (bity 2-6)
    andi $k1, $k0, 0x00007c
    
    # Przesuń o dwa bity w prawo aby otrzymac kod wyjatku
    srl $k1, $k1, 2
    
    # Teraz $k0 = wartosc rejestru przyczyny
    #      $k1 = kod wyjatku

__obsluga_wyjatku:
    # Sprawdz typ wyjatku na podstawie kodu w $k1
    # (wyjatek przepelnienia ma kod 12)
    beq $k1, 12, __wyjatek_przepelnienie
    
    # Inne wyjatki
    j __wyjatek_ogolny

__wyjatek_przepelnienie:
    # Uzyj systemowego wywolania MARS 4 (wydrukuj string)
    li $v0, 4
    la $a0, komunikat_przepelnienie
    syscall
    li $v1, 0 # 0 - wyjatek przepelnienie
    
    j __powrot_z_wyjatku

__wyjatek_ogolny:
    # Obsluga innych wyjatkow
    li $v1, 1 # zwracamy 1 - co bedzie oznaczac wyjatek ogolny
    
    j __powrot_z_wyjatku

__powrot_z_wyjatku:
    # Gdy wystapi wyjatek, wartosc licznika programu ($pc)
    # jest automatycznie zapisywana w ECP (Exception Program Counter)
    # czyli rejestr $14 w Koprocesorze 0
    
    # Pobierz wartosc ECP (adres instrukcji powodujacej wyjatek)
    mfc0 $k0, $14
    
    # Zwieksz ECP o 4, aby przejsc do nastepnej instrukcji
    # (unikamy zapetlenia na tej samej instrukcji)
    addi $k0, $k0, 4
    mtc0 $k0, $14
    
    # Uzyj instrukcji eret (Exception Return) aby ustawic licznik programu
    # na wartosc zapisana w rejestrze ECP (rejestr 14 w koprocesorze 0)
    eret
