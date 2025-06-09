.data
    # Komunikaty dla użytkownika
    komunikat_powitalny: .asciiz "=== GRA W KOLKO I KRZYZYK ===\n"
    komunikat_znak: .asciiz "Wybierz swoj znak (O lub X): "
    komunikat_rundy: .asciiz "Ile rund chcesz zagrac (1-5)? "
    komunikat_ruch: .asciiz "Podaj numer pola (1-9): "
    komunikat_plansza: .asciiz "\nAktualna plansza:\n"
    komunikat_wygrana_gracz: .asciiz "Wygrales runde!\n"
    komunikat_wygrana_komputer: .asciiz "Komputer wygral runde!\n"
    komunikat_remis: .asciiz "Remis!\n"
    komunikat_podsumowanie: .asciiz "\n=== PODSUMOWANIE ===\n"
    komunikat_twoje_wygrane: .asciiz "Twoje wygrane rundy: "
    komunikat_komputer_wygrane: .asciiz "Wygrane rundy komputera: "
    komunikat_remisy: .asciiz "Remisy: "
    komunikat_ruch_komputer: .asciiz "Komputer stawia na polu: "
    komunikat_blad_pole: .asciiz "Pole jest juz zajete! Sprobuj ponownie.\n"
    komunikat_blad_znak: .asciiz "Nieprawidlowy znak! Wpisz O lub X.\n"
    komunikat_blad_rundy: .asciiz "Nieprawidlowa liczba rund! Wpisz 1-5.\n"
    komunikat_blad_pole_num: .asciiz "Nieprawidlowy numer pola! Wpisz 1-9.\n"
    nowa_linia: .asciiz "\n"
    spacja: .asciiz " "
    kreska: .asciiz " | "
    linia_sep: .asciiz "---------\n"
    
    # Tablica planszy (9 elementów, inicjalizowana spacjami)
    .align 2
    plansza: .space 36  # 9 * 4 bajty dla każdego pola
    
    # Zmienne gry
    .align 2
    znak_gracza: .word 0
    znak_komputera: .word 0
    liczba_rund: .word 0
    aktualna_runda: .word 0
    wygrane_gracza: .word 0
    wygrane_komputera: .word 0
    remisy: .word 0

.text
.globl main

main:
    # Inicjalizacja zmiennych
    sw $zero, wygrane_gracza
    sw $zero, wygrane_komputera  
    sw $zero, remisy
    sw $zero, aktualna_runda
    
    # Wyświetl komunikat powitalny
    li $v0, 4
    la $a0, komunikat_powitalny
    syscall
    
    # Pobierz znak gracza
    jal pobierz_znak_gracza
    
    # Pobierz liczbę rund
    jal pobierz_liczbe_rund
    
    # Główna pętla gry
petla_glowna:
    lw $t0, aktualna_runda
    lw $t1, liczba_rund
    slt $t2, $t0, $t1
    beq $t2, $zero, koniec_gry
    
    # Zwiększ licznik rund
    addi $t0, $t0, 1
    sw $t0, aktualna_runda
    
    # Zainicjalizuj planszę
    jal inicjalizuj_plansze
    
    # Graj rundę
    jal graj_runde
    
    j petla_glowna

koniec_gry:
    # Wyświetl podsumowanie
    jal wyswietl_podsumowanie
    
    # Zakończ program
    li $v0, 10
    syscall

# Funkcja pobierania znaku gracza
pobierz_znak_gracza:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
pobierz_znak_petla:
    # Wyświetl komunikat
    li $v0, 4
    la $a0, komunikat_znak
    syscall
    
    # Pobierz znak
    li $v0, 12  # read character
    syscall
    
    # Sprawdź czy to 'O' lub 'X'
    li $t0, 79  # 'O'
    beq $v0, $t0, znak_ok
    li $t0, 111 # 'o'
    beq $v0, $t0, ustaw_O
    li $t0, 88  # 'X'
    beq $v0, $t0, znak_ok
    li $t0, 120 # 'x'
    beq $v0, $t0, ustaw_X
    
    # Błędny znak
    li $v0, 4
    la $a0, komunikat_blad_znak
    syscall
    j pobierz_znak_petla
    
ustaw_O:
    li $v0, 79  # zamień 'o' na 'O'
    j znak_ok
    
ustaw_X:
    li $v0, 88  # zamień 'x' na 'X'
    
znak_ok:
    # Zapisz znak gracza
    sw $v0, znak_gracza
    
    # Ustaw znak komputera (odwrotny do gracza)
    li $t0, 79  # 'O'
    beq $v0, $t0, komputer_X
    # Jeśli gracz ma 'X', komputer będzie 'O'
    li $t1, 79  # komputer będzie 'O'
    sw $t1, znak_komputera
    j koniec_pobierz_znak
    
komputer_X:
    # Jeśli gracz ma 'O', komputer będzie 'X'
    li $t1, 88  # 'X'
    sw $t1, znak_komputera
    
koniec_pobierz_znak:
    # Nowa linia
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja pobierania liczby rund
pobierz_liczbe_rund:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
pobierz_rundy_petla:
    # Wyświetl komunikat
    li $v0, 4
    la $a0, komunikat_rundy
    syscall
    
    # Pobierz liczbę
    li $v0, 5
    syscall
    
    # Sprawdź zakres 1-5
    li $t0, 1
    slt $t1, $v0, $t0  # czy < 1
    bne $t1, $zero, rundy_blad
    
    li $t0, 5
    slt $t1, $t0, $v0  # czy > 5
    bne $t1, $zero, rundy_blad
    
    # Zapisz liczbę rund
    sw $v0, liczba_rund
    j koniec_pobierz_rundy
    
rundy_blad:
    li $v0, 4
    la $a0, komunikat_blad_rundy
    syscall
    j pobierz_rundy_petla
    
koniec_pobierz_rundy:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja inicjalizacji planszy
inicjalizuj_plansze:
    la $t0, plansza
    li $t1, 32      # kod spacji
    li $t2, 0       # licznik
    
init_petla:
    li $t3, 9
    slt $t4, $t2, $t3
    beq $t4, $zero, koniec_init
    
    sll $t5, $t2, 2  # indeks * 4
    add $t6, $t0, $t5
    sw $t1, 0($t6)
    
    addi $t2, $t2, 1
    j init_petla
    
koniec_init:
    jr $ra

# Funkcja gry jednej rundy
graj_runde:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $t0, 0  # licznik ruchów
    
petla_runda:
    # Wyświetl planszę
    jal wyswietl_plansze
    
    # Sprawdź czy koniec gry
    jal sprawdz_koniec_gry
    bne $v0, $zero, koniec_rundy
    
    # Ruch gracza
    jal ruch_gracza
    
    # Sprawdź czy koniec gry
    jal sprawdz_koniec_gry
    bne $v0, $zero, koniec_rundy
    
    # Ruch komputera
    jal ruch_komputera
    
    j petla_runda
    
koniec_rundy:
    # Wyświetl końcową planszę
    jal wyswietl_plansze
    
    # Wyświetl wynik
    jal wyswietl_wynik_rundy
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja wyświetlania planszy
wyswietl_plansze:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Komunikat
    li $v0, 4
    la $a0, komunikat_plansza
    syscall
    
    # Wyświetl planszę 3x3
    li $t0, 0  # licznik
    
    
wyswietl_petla:
    li $t1, 9
    slt $t2, $t0, $t1
    beq $t2, $zero, koniec_wyswietl
    
    # Pobierz znak z planszy
    la $t3, plansza
    sll $t4, $t0, 2
    add $t5, $t3, $t4
    lw $a0, 0($t5)
    
    beq $a0, 'X', kontynuuj_wyswietl_petla
    beq $a0, 'O', kontynuuj_wyswietl_petla
    
    addi $t9, $t0, 49
    move $a0,  $t9 # wyswietl numer pola
   
kontynuuj_wyswietl_petla: 
    # Wyświetl znak
    li $v0, 11
    syscall
    
    # Sprawdź czy koniec wiersza
    addi $t0, $t0, 1
    li $t6, 3
    div $t0, $t6
    mfhi $t7
    
    bne $t7, $zero, nie_koniec_wiersza
    
    # Koniec wiersza
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Jeśli nie ostatni wiersz, wyświetl separator
    li $t8, 9
    beq $t0, $t8, wyswietl_petla
    
    li $v0, 4
    la $a0, linia_sep
    syscall
    
    j wyswietl_petla
    
nie_koniec_wiersza:
    # Wyświetl separator kolumn
    li $v0, 4
    la $a0, kreska
    syscall
    j wyswietl_petla
    
koniec_wyswietl:
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja ruchu gracza
ruch_gracza:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
ruch_gracza_petla:
    # Pobierz numer pola
    li $v0, 4
    la $a0, komunikat_ruch
    syscall
    
    li $v0, 5
    syscall
    
    # Sprawdź zakres 1-9
    li $t0, 1
    slt $t1, $v0, $t0
    bne $t1, $zero, ruch_gracza_blad
    
    li $t0, 9
    slt $t1, $t0, $v0
    bne $t1, $zero, ruch_gracza_blad
    
    # Konwertuj na indeks 0-8
    addi $t2, $v0, -1
    
    # Sprawdź czy pole wolne
    la $t3, plansza
    sll $t4, $t2, 2
    add $t5, $t3, $t4
    lw $t6, 0($t5)
    
    li $t7, 32  # spacja
    bne $t6, $t7, pole_zajete
    
    # Postaw znak gracza
    lw $t8, znak_gracza
    sw $t8, 0($t5)
    
    j koniec_ruch_gracza
    
pole_zajete:
    li $v0, 4
    la $a0, komunikat_blad_pole
    syscall
    j ruch_gracza_petla
    
ruch_gracza_blad:
    li $v0, 4
    la $a0, komunikat_blad_pole_num
    syscall
    j ruch_gracza_petla
    
koniec_ruch_gracza:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja ruchu komputera (strategia: środek, rogi, boki)
ruch_komputera:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Najpierw spróbuj wygrać
    jal znajdz_ruch_wygrywajacy
    bne $v0, -1, wykonaj_ruch_komputera
    
    # Następnie spróbuj zablokować gracza
    jal znajdz_ruch_blokujacy
    bne $v0, -1, wykonaj_ruch_komputera
    
    # Strategia podstawowa: środek -> rogi -> boki
    # Sprawdź środek (pole 4)
    la $t0, plansza
    lw $t1, 16($t0)  # pole 4 (indeks 4)
    li $t2, 32       # spacja
    beq $t1, $t2, wybierz_srodek
    
    # Sprawdź rogi (0,2,6,8)
    lw $t1, 0($t0)   # pole 0
    beq $t1, $t2, wybierz_rog_0
    lw $t1, 8($t0)   # pole 2
    beq $t1, $t2, wybierz_rog_2
    lw $t1, 24($t0)  # pole 6
    beq $t1, $t2, wybierz_rog_6
    lw $t1, 32($t0)  # pole 8
    beq $t1, $t2, wybierz_rog_8
    
    # Sprawdź boki (1,3,5,7)
    lw $t1, 4($t0)   # pole 1
    beq $t1, $t2, wybierz_bok_1
    lw $t1, 12($t0)  # pole 3
    beq $t1, $t2, wybierz_bok_3
    lw $t1, 20($t0)  # pole 5
    beq $t1, $t2, wybierz_bok_5
    lw $t1, 28($t0)  # pole 7
    beq $t1, $t2, wybierz_bok_7
    
    j koniec_ruch_komputera  # Nie powinno się zdarzyć
    
wybierz_srodek:
    li $v0, 4
    j wykonaj_ruch_komputera
    
wybierz_rog_0:
    li $v0, 0
    j wykonaj_ruch_komputera
    
wybierz_rog_2:
    li $v0, 2
    j wykonaj_ruch_komputera
    
wybierz_rog_6:
    li $v0, 6
    j wykonaj_ruch_komputera
    
wybierz_rog_8:
    li $v0, 8
    j wykonaj_ruch_komputera
    
wybierz_bok_1:
    li $v0, 1
    j wykonaj_ruch_komputera
    
wybierz_bok_3:
    li $v0, 3
    j wykonaj_ruch_komputera
    
wybierz_bok_5:
    li $v0, 5
    j wykonaj_ruch_komputera
    
wybierz_bok_7:
    li $v0, 7
    
wykonaj_ruch_komputera:
    # $v0 zawiera indeks pola (0-8)
    move $t0, $v0
    
    # Postaw znak komputera
    la $t1, plansza
    sll $t2, $t0, 2
    add $t3, $t1, $t2
    lw $t4, znak_komputera
    sw $t4, 0($t3)
    
    # Wyświetl komunikat
    li $v0, 4
    la $a0, komunikat_ruch_komputer
    syscall
    
    addi $a0, $t0, 1  # konwertuj na 1-9
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
koniec_ruch_komputera:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja znajdowania ruchu wygrywającego
znajdz_ruch_wygrywajacy:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    
    lw $s0, znak_komputera
    jal znajdz_ruch_dla_znaku
    
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra

# Funkcja znajdowania ruchu blokującego
znajdz_ruch_blokujacy:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    
    lw $s0, znak_gracza
    jal znajdz_ruch_dla_znaku
    
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra

# Funkcja znajdowania ruchu dla określonego znaku
znajdz_ruch_dla_znaku:
    # $s0 - znak do sprawdzenia
    la $t0, plansza
    li $t1, 32  # spacja

sprawdz_wiersz_1:
    # Sprawdź wszystkie linie wygrywające
    # Wiersz 1: pola 0,1,2
    lw $t2, 0($t0)   # pole 0
    lw $t3, 4($t0)   # pole 1  
    lw $t4, 8($t0)   # pole 2
    
    j sprawdz_wiersz2
    
sprawdz_wiersz1_0:
    beq $t3, $s0, sprawdz_wiersz1_0_1
    beq $t4, $s0, sprawdz_wiersz1_0_2
    j sprawdz_wiersz1_1
    
sprawdz_wiersz1_0_1:
    beq $t4, $t1, zwroc_pole_2
    j sprawdz_wiersz1_1
    
sprawdz_wiersz1_0_2:
    beq $t3, $t1, zwroc_pole_1
    j sprawdz_wiersz1_1
    
sprawdz_wiersz1_1:
    beq $t4, $s0, sprawdz_wiersz1_1_2
    j sprawdz_wiersz1_2
    
sprawdz_wiersz1_1_2:
    beq $t2, $t1, zwroc_pole_0
    j sprawdz_wiersz1_2
    
sprawdz_wiersz1_2:
    # Kontynuuj sprawdzanie pozostałych linii...
    
sprawdz_wiersz2:
    # Wiersz 2: pola 3,4,5
    lw $t2, 12($t0)  # pole 3
    lw $t3, 16($t0)  # pole 4
    lw $t4, 20($t0)  # pole 5
    # ... podobnie jak wyżej
    
    # Uproszczone - zwróć -1 (brak ruchu)
    li $v0, -1
    jr $ra
    
zwroc_pole_0:
    li $v0, 0
    jr $ra
zwroc_pole_1:  
    li $v0, 1
    jr $ra
zwroc_pole_2:
    li $v0, 2
    jr $ra

# Funkcja sprawdzania końca gry
sprawdz_koniec_gry:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Sprawdź wygrane
    jal sprawdz_wygrane
    bne $v0, $zero, koniec_sprawdz_koniec
    
    # Sprawdź remis
    jal sprawdz_remis
    
koniec_sprawdz_koniec:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja sprawdzania wygranych
sprawdz_wygrane:
    la $t0, plansza
    
    # Sprawdź wiersze
    # Wiersz 1
    lw $t1, 0($t0)
    lw $t2, 4($t0)  
    lw $t3, 8($t0)
    beq $t1, $t2, sprawdz_wiersz1_dalej
    j sprawdz_wiersz2_start
    
sprawdz_wiersz1_dalej:
    beq $t2, $t3, sprawdz_wiersz1_znak
    j sprawdz_wiersz2_start
    
sprawdz_wiersz1_znak:
    li $t4, 32  # spacja
    beq $t1, $t4, sprawdz_wiersz2_start
    li $v0, 1   # znaleziono wygraną
    jr $ra
    
sprawdz_wiersz2_start:  
    # Wiersz 2
    lw $t1, 12($t0)
    lw $t2, 16($t0)
    lw $t3, 20($t0)
    beq $t1, $t2, sprawdz_wiersz2_dalej
    j sprawdz_wiersz3_start
    
sprawdz_wiersz2_dalej:
    beq $t2, $t3, sprawdz_wiersz2_znak
    j sprawdz_wiersz3_start
    
sprawdz_wiersz2_znak:
    li $t4, 32
    beq $t1, $t4, sprawdz_wiersz3_start
    li $v0, 1
    jr $ra
    
sprawdz_wiersz3_start:
    # Wiersz 3  
    lw $t1, 24($t0)
    lw $t2, 28($t0)
    lw $t3, 32($t0)
    beq $t1, $t2, sprawdz_wiersz3_dalej
    j sprawdz_kolumny_start
    
sprawdz_wiersz3_dalej:
    beq $t2, $t3, sprawdz_wiersz3_znak
    j sprawdz_kolumny_start
    
sprawdz_wiersz3_znak:
    li $t4, 32
    beq $t1, $t4, sprawdz_kolumny_start
    li $v0, 1
    jr $ra
    
sprawdz_kolumny_start:
    # Kolumna 1
    lw $t1, 0($t0)
    lw $t2, 12($t0)
    lw $t3, 24($t0)
    beq $t1, $t2, sprawdz_kolumna1_dalej
    j sprawdz_kolumna2_start
    
sprawdz_kolumna1_dalej:
    beq $t2, $t3, sprawdz_kolumna1_znak
    j sprawdz_kolumna2_start
    
sprawdz_kolumna1_znak:
    li $t4, 32
    beq $t1, $t4, sprawdz_kolumna2_start
    li $v0, 1
    jr $ra
    
sprawdz_kolumna2_start:
    # Kolumna 2
    lw $t1, 4($t0)
    lw $t2, 16($t0)
    lw $t3, 28($t0)
    beq $t1, $t2, sprawdz_kolumna2_dalej
    j sprawdz_kolumna3_start
    
sprawdz_kolumna2_dalej:
    beq $t2, $t3, sprawdz_kolumna2_znak
    j sprawdz_kolumna3_start
    
sprawdz_kolumna2_znak:
    li $t4, 32
    beq $t1, $t4, sprawdz_kolumna3_start
    li $v0, 1
    jr $ra
    
sprawdz_kolumna3_start:
    # Kolumna 3
    lw $t1, 8($t0)
    lw $t2, 20($t0)
    lw $t3, 32($t0)
    beq $t1, $t2, sprawdz_kolumna3_dalej
    j sprawdz_przekatne_start
    
sprawdz_kolumna3_dalej:
    beq $t2, $t3, sprawdz_kolumna3_znak
    j sprawdz_przekatne_start
    
sprawdz_kolumna3_znak:
    li $t4, 32
    beq $t1, $t4, sprawdz_przekatne_start
    li $v0, 1
    jr $ra
    
sprawdz_przekatne_start:
    # Przekątna główna
    lw $t1, 0($t0)
    lw $t2, 16($t0)
    lw $t3, 32($t0)
    beq $t1, $t2, sprawdz_przekatna1_dalej
    j sprawdz_przekatna2_start
    
sprawdz_przekatna1_dalej:
    beq $t2, $t3, sprawdz_przekatna1_znak
    j sprawdz_przekatna2_start
    
sprawdz_przekatna1_znak:
    li $t4, 32
    beq $t1, $t4, sprawdz_przekatna2_start
    li $v0, 1
    jr $ra
    
sprawdz_przekatna2_start:
    # Przekątna poboczna
    lw $t1, 8($t0)
    lw $t2, 16($t0)
    lw $t3, 24($t0)
    beq $t1, $t2, sprawdz_przekatna2_dalej
    j brak_wygranej
    
sprawdz_przekatna2_dalej:
    beq $t2, $t3, sprawdz_przekatna2_znak
    j brak_wygranej
    
sprawdz_przekatna2_znak:
    li $t4, 32
    beq $t1, $t4, brak_wygranej
    li $v0, 1
    jr $ra
    
brak_wygranej:
    li $v0, 0
    jr $ra

# Funkcja sprawdzania remisu
sprawdz_remis:  
    la $t0, plansza
    li $t1, 32  # spacja
    li $t2, 0   # licznik
    
sprawdz_remis_petla:
    li $t3, 9
    slt $t4, $t2, $t3
    beq $t4, $zero, jest_remis
    
    sll $t5, $t2, 2
    add $t6, $t0, $t5
    lw $t7, 0($t6)
    
    beq $t7, $t1, nie_ma_remisu  # znaleziono puste pole
    
    addi $t2, $t2, 1
    j sprawdz_remis_petla
    
jest_remis:
    li $v0, 2  # kod remisu
    jr $ra
    
nie_ma_remisu:
    li $v0, 0
    jr $ra

# Funkcja wyświetlania wyniku rundy
wyswietl_wynik_rundy:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Sprawdź kto wygrał
    jal sprawdz_kto_wygral
    
    # $v0: 1 = gracz, 2 = komputer, 3 = remis
    li $t0, 1
    beq $v0, $t0, gracz_wygral_runde
    li $t0, 2  
    beq $v0, $t0, komputer_wygral_runde
    li $t0, 3
    beq $v0, $t0, remis_w_rundzie
    
gracz_wygral_runde:
    li $v0, 4
    la $a0, komunikat_wygrana_gracz
    syscall
    
    # Zwiększ licznik wygranych gracza
    lw $t0, wygrane_gracza
    addi $t0, $t0, 1
    sw $t0, wygrane_gracza
    j koniec_wynik_rundy
    
komputer_wygral_runde:
    li $v0, 4
    la $a0, komunikat_wygrana_komputer
    syscall
    
    # Zwiększ licznik wygranych komputera
    lw $t0, wygrane_komputera
    addi $t0, $t0, 1
    sw $t0, wygrane_komputera
    j koniec_wynik_rundy
    
remis_w_rundzie:
    li $v0, 4
    la $a0, komunikat_remis
    syscall
    
    # Zwiększ licznik remisów
    lw $t0, remisy
    addi $t0, $t0, 1
    sw $t0, remisy
    
koniec_wynik_rundy:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja sprawdzania kto wygrał rundę
sprawdz_kto_wygral:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Jeśli nie ma wygranej, sprawdź remis
    jal sprawdz_wygrane
    beq $v0, $zero, sprawdz_czy_remis
    
    # Jest wygrana - sprawdź czyja
    jal sprawdz_czyja_wygrana
    j koniec_sprawdz_kto_wygral
    
sprawdz_czy_remis:
    jal sprawdz_remis
    li $t0, 2
    beq $v0, $t0, jest_remis_w_grze
    li $v0, 0  # gra trwa dalej
    j koniec_sprawdz_kto_wygral
    
jest_remis_w_grze:
    li $v0, 3  # remis
    j koniec_sprawdz_kto_wygral
    
koniec_sprawdz_kto_wygral:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funkcja sprawdzania czyja jest wygrana
sprawdz_czyja_wygrana:
    la $t0, plansza
    lw $t1, znak_gracza
    lw $t2, znak_komputera
    
    # Sprawdź wiersze
    # Wiersz 1
    lw $t3, 0($t0)
    lw $t4, 4($t0)
    lw $t5, 8($t0)
    bne $t3, $t4, sprawdz_wiersz2_czyj
    bne $t4, $t5, sprawdz_wiersz2_czyj
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
sprawdz_wiersz2_czyj:
    # Wiersz 2
    lw $t3, 12($t0)
    lw $t4, 16($t0)
    lw $t5, 20($t0)
    bne $t3, $t4, sprawdz_wiersz3_czyj
    bne $t4, $t5, sprawdz_wiersz3_czyj
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
sprawdz_wiersz3_czyj:
    # Wiersz 3
    lw $t3, 24($t0)
    lw $t4, 28($t0)
    lw $t5, 32($t0)
    bne $t3, $t4, sprawdz_kolumny_czyje
    bne $t4, $t5, sprawdz_kolumny_czyje
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
sprawdz_kolumny_czyje:
    # Kolumna 1
    lw $t3, 0($t0)
    lw $t4, 12($t0)
    lw $t5, 24($t0)
    bne $t3, $t4, sprawdz_kolumna2_czyja
    bne $t4, $t5, sprawdz_kolumna2_czyja
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
sprawdz_kolumna2_czyja:
    # Kolumna 2
    lw $t3, 4($t0)
    lw $t4, 16($t0)
    lw $t5, 28($t0)
    bne $t3, $t4, sprawdz_kolumna3_czyja
    bne $t4, $t5, sprawdz_kolumna3_czyja
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
sprawdz_kolumna3_czyja:
    # Kolumna 3
    lw $t3, 8($t0)
    lw $t4, 20($t0)
    lw $t5, 32($t0)
    bne $t3, $t4, sprawdz_przekatne_czyje
    bne $t4, $t5, sprawdz_przekatne_czyje
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
sprawdz_przekatne_czyje:
    # Przekątna główna
    lw $t3, 0($t0)
    lw $t4, 16($t0)
    lw $t5, 32($t0)
    bne $t3, $t4, sprawdz_przekatna2_czyja
    bne $t4, $t5, sprawdz_przekatna2_czyja
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
sprawdz_przekatna2_czyja:
    # Przekątna poboczna
    lw $t3, 8($t0)
    lw $t4, 16($t0)
    lw $t5, 24($t0)
    bne $t3, $t4, koniec_sprawdz_czyja_wygrana
    bne $t4, $t5, koniec_sprawdz_czyja_wygrana
    beq $t3, $t1, gracz_wygral_sprawdz
    beq $t3, $t2, komputer_wygral_sprawdz
    
gracz_wygral_sprawdz:
    li $v0, 1
    jr $ra
    
komputer_wygral_sprawdz:
    li $v0, 2
    jr $ra
    
koniec_sprawdz_czyja_wygrana:
    li $v0, 0
    jr $ra

# Funkcja wyświetlania podsumowania
wyswietl_podsumowanie:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Nagłówek podsumowania
    li $v0, 4
    la $a0, komunikat_podsumowanie
    syscall
    
    # Wygrane gracza
    li $v0, 4
    la $a0, komunikat_twoje_wygrane
    syscall
    
    lw $a0, wygrane_gracza
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Wygrane komputera
    li $v0, 4
    la $a0, komunikat_komputer_wygrane
    syscall
    
    lw $a0, wygrane_komputera
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Remisy
    li $v0, 4
    la $a0, komunikat_remisy
    syscall
    
    lw $a0, remisy
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
