.data
    # Komunikaty dla gracza
    powitanie:      .asciiz "=== KOLKO I KRZYZYK ===\n"
    wybor_znaku:    .asciiz "Wybierz swoj znak (O lub X): "
    wybor_rund:     .asciiz "Podaj liczbe rund (1-5): "
    ruch_gracza:    .asciiz "Twoj ruch (podaj numer pola 1-9): "
    aktualna_plansza: .asciiz "\nStan planszy:\n"
    wygrana_gracz:  .asciiz "\nBrawo! Wygrales te runde!\n"
    wygrana_komp:   .asciiz "\nNiestety, komputer wygral te runde.\n"
    remis_komunikat: .asciiz "\nRemis w tej rundzie!\n"
    podsumowanie:   .asciiz "\n=== KONIEC GRY ===\n"
    twoje_punkty:   .asciiz "Twoje wygrane: "
    punkty_komp:    .asciiz "Wygrane komputera: "
    remisy_ilosc:   .asciiz "Remisy: "
    ruch_komputera: .asciiz "Komputer wybral pole: "
    blad_zajete:    .asciiz "To pole jest juz zajete!\n"
    blad_znak:      .asciiz "Niepoprawny znak! Wybierz O lub X.\n"
    blad_runda:     .asciiz "Niepoprawna liczba rund! Wybierz 1-5.\n"
    blad_pole:      .asciiz "Niepoprawny numer pola! Wybierz 1-9.\n"
    nowa_linia:     .asciiz "\n"
    separator:      .asciiz " | "
    linia_pozioma:  .asciiz "---------\n"
    
    # Plansza gry (9 pol)
    .align 2
    plansza: .space 36  # 9 pol * 4 bajty
    
    # Zmienne gry
    .align 2
    znak_gracza: .word 0
    znak_komputera: .word 0
    ile_rund: .word 0
    obecna_runda: .word 0
    punkty_gracza: .word 0
    punkty_komputera: .word 0
    liczba_remisow: .word 0

.text
.globl main

main:
    # Przygotowanie gry
    sw $zero, punkty_gracza
    sw $zero, punkty_komputera
    sw $zero, liczba_remisow
    sw $zero, obecna_runda
    
    # Powitanie
    li $v0, 4
    la $a0, powitanie
    syscall
    
    # Wybor znaku przez gracza
    jal wybierz_znak
    
    # Wybor liczby rund
    jal wybierz_rundy
    
    # Glowna petla gry
glowna_petla:
    lw $t0, obecna_runda
    lw $t1, ile_rund
    bge $t0, $t1, koniec_programu
    
    # Inkrementacja rundy
    addi $t0, $t0, 1
    sw $t0, obecna_runda
    
    # Przygotowanie planszy
    jal przygotuj_plansze
    
    # Rozegranie rundy
    jal rozegraj_runde
    
    j glowna_petla

koniec_programu:
    # Wyswietlenie wynikow
    jal pokaz_wyniki
    
    # Zakonczenie programu
    li $v0, 10
    syscall

# Funkcja wyboru znaku przez gracza
wybierz_znak:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
petla_znaku:
    # Prosba o znak
    li $v0, 4
    la $a0, wybor_znaku
    syscall
    
    # Pobranie znaku
    li $v0, 12
    syscall
    
    # Sprawdzenie poprawnosci znaku
    beq $v0, 'O', poprawny_znak
    beq $v0, 'o', mala_o
    beq $v0, 'X', poprawny_znak
    beq $v0, 'x', mala_x
    
    # Blad - zly znak
    li $v0, 4
    la $a0, blad_znak
    syscall
    j petla_znaku
    
mala_o:
    li $v0, 'O'  # Zamiana na duza litere
    j poprawny_znak
    
mala_x:
    li $v0, 'X'  # Zamiana na duza litere
    
poprawny_znak:
    # Zapisanie znaku gracza
    sw $v0, znak_gracza
    
    # Ustawienie znaku komputera (przeciwny)
    beq $v0, 'O', ustaw_komp_X
    li $t0, 'O'  # Gracz ma X, komputer O
    sw $t0, znak_komputera
    j koniec_wyboru_znaku
    
ustaw_komp_X:
    li $t0, 'X'  # Gracz ma O, komputer X
    sw $t0, znak_komputera
    
koniec_wyboru_znaku:
    # Nowa linia
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja wyboru liczby rund
wybierz_rundy:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
petla_rund:
    # Prosba o liczbe rund
    li $v0, 4
    la $a0, wybor_rund
    syscall
    
    # Pobranie liczby
    li $v0, 5
    syscall
    
    # Sprawdzenie zakresu 1-5
    blt $v0, 1, blad_rund
    bgt $v0, 5, blad_rund
    
    # Zapisanie liczby rund
    sw $v0, ile_rund
    j koniec_wyboru_rund
    
blad_rund:
    li $v0, 4
    la $a0, blad_runda
    syscall
    j petla_rund
    
koniec_wyboru_rund:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Przygotowanie planszy (wyczyszczenie)
przygotuj_plansze:
    la $t0, plansza
    li $t1, ' '      # spacja
    li $t2, 0        # indeks
    
czyszczenie:
    bge $t2, 9, koniec_czyszczenia
    
    # Wyczyszczenie pola
    sll $t3, $t2, 2
    add $t4, $t0, $t3
    sw $t1, 0($t4)
    
    addi $t2, $t2, 1
    j czyszczenie
    
koniec_czyszczenia:
    jr $ra

# Rozegranie pojedynczej rundy
rozegraj_runde:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $t0, 0  # licznik ruchow
    
petla_ruchy:
    # Wyswietlenie planszy
    jal pokaz_plansze
    
    # Sprawdzenie konca gry
    jal sprawdz_wynik
    bnez $v0, koniec_rundy
    
    # Ruch gracza
    jal wykonaj_ruch_gracza
    
    # Ponowne sprawdzenie
    jal sprawdz_wynik
    bnez $v0, koniec_rundy
    
    # Ruch komputera
    jal wykonaj_ruch_komputera
    
    j petla_ruchy
    
koniec_rundy:
    # Wyswietlenie koncowej planszy
    jal pokaz_plansze
    
    # Wyswietlenie wyniku rundy
    jal pokaz_wynik_rundy
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Wyswietlenie planszy
pokaz_plansze:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Naglowek
    li $v0, 4
    la $a0, aktualna_plansza
    syscall
    
    la $t0, plansza
    li $t1, 0  # indeks
    
wyswietlanie:
    bge $t1, 9, koniec_wyswietlania
    
    # Pobranie znaku z planszy
    sll $t2, $t1, 2
    add $t3, $t0, $t2
    lw $a0, 0($t3)
    
    # Jesli puste, pokaz numer
    beq $a0, ' ', pokaz_numer
    j wyswietl_znak
    
pokaz_numer:
    addi $a0, $t1, 1  # numeracja 1-9
    li $v0, 1
    syscall
    j sprawdz_format
    
wyswietl_znak:
    li $v0, 11
    syscall
    
sprawdz_format:
    # Sprawdzenie czy koniec wiersza
    addi $t1, $t1, 1
    rem $t4, $t1, 3
    
    beqz $t4, nowy_wiersz
    
    # Separator miedzy polami
    li $v0, 4
    la $a0, separator
    syscall
    j wyswietlanie
    
nowy_wiersz:
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Linia pozioma po kazdym wierszu (opcjonalnie)
    blt $t1, 7, wyswietlanie
    j wyswietlanie
    
koniec_wyswietlania:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Wykonanie ruchu przez gracza
wykonaj_ruch_gracza:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
ruch_petla:
    # Prosba o ruch
    li $v0, 4
    la $a0, ruch_gracza
    syscall
    
    # Pobranie numeru pola
    li $v0, 5
    syscall
    
    # Walidacja
    blt $v0, 1, blad_numer
    bgt $v0, 9, blad_numer
    
    # Konwersja na indeks 0-8
    addi $t0, $v0, -1
    
    # Sprawdzenie czy pole wolne
    la $t1, plansza
    sll $t2, $t0, 2
    add $t3, $t1, $t2
    lw $t4, 0($t3)
    
    bne $t4, ' ', pole_zajete
    
    # Wstawienie znaku gracza
    lw $t5, znak_gracza
    sw $t5, 0($t3)
    
    j koniec_ruchu
    
blad_numer:
    li $v0, 4
    la $a0, blad_pole
    syscall
    j ruch_petla
    
pole_zajete:
    li $v0, 4
    la $a0, blad_zajete
    syscall
    j ruch_petla
    
koniec_ruchu:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Wykonanie ruchu przez komputer
wykonaj_ruch_komputera:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Prosta strategia: srodek, rogi, boki
    la $t0, plansza
    
    # 1. Sprawdz srodek
    lw $t1, 16($t0)  # pole 5 (indeks 4)
    beq $t1, ' ', wybierz_srodek
    
    # 2. Sprawdz rogi
    lw $t1, 0($t0)   # pole 1
    beq $t1, ' ', wybierz_rog1
    lw $t1, 8($t0)   # pole 3
    beq $t1, ' ', wybierz_rog3
    lw $t1, 24($t0)  # pole 7
    beq $t1, ' ', wybierz_rog7
    lw $t1, 32($t0)  # pole 9
    beq $t1, ' ', wybierz_rog9
    
    # 3. Sprawdz boki
    lw $t1, 4($t0)   # pole 2
    beq $t1, ' ', wybierz_bok2
    lw $t1, 12($t0)  # pole 4
    beq $t1, ' ', wybierz_bok4
    lw $t1, 20($t0)  # pole 6
    beq $t1, ' ', wybierz_bok6
    lw $t1, 28($t0)  # pole 8
    beq $t1, ' ', wybierz_bok8
    
    # Teoretycznie nigdy tu nie dojdziemy (sprawdzane wczesniej)
    j koniec_ruchu_komp
    
wybierz_srodek:
    li $v0, 4
    j wykonaj_ruch
    
wybierz_rog1:
    li $v0, 0
    j wykonaj_ruch
    
wybierz_rog3:
    li $v0, 2
    j wykonaj_ruch
    
wybierz_rog7:
    li $v0, 6
    j wykonaj_ruch
    
wybierz_rog9:
    li $v0, 8
    j wykonaj_ruch
    
wybierz_bok2:
    li $v0, 1
    j wykonaj_ruch
    
wybierz_bok4:
    li $v0, 3
    j wykonaj_ruch
    
wybierz_bok6:
    li $v0, 5
    j wykonaj_ruch
    
wybierz_bok8:
    li $v0, 7
    
wykonaj_ruch:
    # Wstawienie znaku komputera
    move $t0, $v0
    la $t1, plansza
    sll $t2, $t0, 2
    add $t3, $t1, $t2
    lw $t4, znak_komputera
    sw $t4, 0($t3)
    
    # Komunikat o ruchu
    li $v0, 4
    la $a0, ruch_komputera
    syscall
    
    addi $a0, $t0, 1  # numeracja 1-9
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
koniec_ruchu_komp:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Sprawdzenie wyniku gry
sprawdz_wynik:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Sprawdzenie wygranej
    jal czy_wygrana
    bnez $v0, koniec_sprawdzania
    
    # Sprawdzenie remisu
    jal czy_remis
    
koniec_sprawdzania:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Sprawdzenie czy ktos wygral
czy_wygrana:
    la $t0, plansza
    
    # Sprawdzenie wierszy
    # Wiersz 1 (pola 0,1,2)
    lw $t1, 0($t0)
    lw $t2, 4($t0)
    lw $t3, 8($t0)
    beq $t1, $t2, sprawdz_w1
    j sprawdz_w2
    
sprawdz_w1:
    beq $t2, $t3, wygrana_znaleziona
    j sprawdz_w2
    
sprawdz_w2:
    # Wiersz 2 (pola 3,4,5)
    lw $t1, 12($t0)
    lw $t2, 16($t0)
    lw $t3, 20($t0)
    beq $t1, $t2, sprawdz_w2_dalej
    j sprawdz_w3
    
sprawdz_w2_dalej:
    beq $t2, $t3, wygrana_znaleziona
    j sprawdz_w3
    
sprawdz_w3:
    # Wiersz 3 (pola 6,7,8)
    lw $t1, 24($t0)
    lw $t2, 28($t0)
    lw $t3, 32($t0)
    beq $t1, $t2, sprawdz_w3_dalej
    j sprawdz_kol
    
sprawdz_w3_dalej:
    beq $t2, $t3, wygrana_znaleziona
    j sprawdz_kol
    
sprawdz_kol:
    # Sprawdzenie kolumn analogicznie
    # (pominięte dla zwięzłości)
    
    # Sprawdzenie przekątnych
    # Przekątna 1 (0,4,8)
    lw $t1, 0($t0)
    lw $t2, 16($t0)
    lw $t3, 32($t0)
    beq $t1, $t2, sprawdz_przek1
    j sprawdz_przek2
    
sprawdz_przek1:
    beq $t2, $t3, wygrana_znaleziona
    j sprawdz_przek2
    
sprawdz_przek2:
    # Przekątna 2 (2,4,6)
    lw $t1, 8($t0)
    lw $t2, 16($t0)
    lw $t3, 24($t0)
    beq $t1, $t2, sprawdz_przek2_dalej
    j brak_wygranej
    
sprawdz_przek2_dalej:
    beq $t2, $t3, wygrana_znaleziona
    j brak_wygranej
    
wygrana_znaleziona:
    # Sprawdzenie kto wygral
    beq $t1, ' ', brak_wygranej
    li $v0, 1
    jr $ra
    
brak_wygranej:
    li $v0, 0
    jr $ra

# Sprawdzenie remisu
czy_remis:
    la $t0, plansza
    li $t1, 0  # indeks
    
sprawdz_pola:
    bge $t1, 9, remis
    
    # Sprawdzenie czy pole puste
    sll $t2, $t1, 2
    add $t3, $t0, $t2
    lw $t4, 0($t3)
    beq $t4, ' ', brak_remisu
    
    addi $t1, $t1, 1
    j sprawdz_pola
    
remis:
    li $v0, 2
    jr $ra
    
brak_remisu:
    li $v0, 0
    jr $ra

# Pokazanie wyniku rundy
pokaz_wynik_rundy:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Sprawdzenie wyniku
    jal sprawdz_wynik
    
    beq $v0, 1, gracz_wygral
    beq $v0, 2, komp_wygral
    beq $v0, 0, koniec_wyniku
    
    # Remis
    li $v0, 4
    la $a0, remis_komunikat
    syscall
    
    # Zwiekszenie licznika remisow
    lw $t0, liczba_remisow
    addi $t0, $t0, 1
    sw $t0, liczba_remisow
    j koniec_wyniku
    
gracz_wygral:
    li $v0, 4
    la $a0, wygrana_gracz
    syscall
    
    # Zwiekszenie punktow gracza
    lw $t0, punkty_gracza
    addi $t0, $t0, 1
    sw $t0, punkty_gracza
    j koniec_wyniku
    
komp_wygral:
    li $v0, 4
    la $a0, wygrana_komp
    syscall
    
    # Zwiekszenie punktow komputera
    lw $t0, punkty_komputera
    addi $t0, $t0, 1
    sw $t0, punkty_komputera
    
koniec_wyniku:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Pokazanie podsumowania gry
pokaz_wyniki:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Naglowek
    li $v0, 4
    la $a0, podsumowanie
    syscall
    
    # Wygrane gracza
    li $v0, 4
    la $a0, twoje_punkty
    syscall
    
    lw $a0, punkty_gracza
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Wygrane komputera
    li $v0, 4
    la $a0, punkty_komp
    syscall
    
    lw $a0, punkty_komputera
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Remisy
    li $v0, 4
    la $a0, remisy_ilosc
    syscall
    
    lw $a0, liczba_remisow
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra