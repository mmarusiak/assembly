# Gra w kółko i krzyżyk - implementacja w MIPS Assembly
# Autor: Implementacja laboratoryjna
# Plansza reprezentowana jako tablica znaków 3x3

.data
    # Tablica planszy - 9 pól (indeksy 0-8)
    plansza: .space 36          # 9 słów (każde pole 4 bajty)
    
    # Znaki graczy
    znak_gracza: .word 0        # 'O' = 79, 'X' = 88
    znak_komputera: .word 0     # przeciwny do gracza
    
    # Liczniki wyników
    wygrane_gracza: .word 0
    wygrane_komputera: .word 0
    remisy: .word 0
    
    # Zmienne pomocnicze
    liczba_rund: .word 0
    aktualna_runda: .word 0
    
    # Komunikaty
    komunikat_start: .asciiz "\n=== GRA W KÓŁKO I KRZYŻYK ===\n"
    wybor_znaku: .asciiz "Wybierz swój znak (79 dla O, 88 dla X): "
    wybor_rund: .asciiz "Ile rund chcesz grać (1-5)? "
    komunikat_runda: .asciiz "\n--- RUNDA "
    komunikat_runda2: .asciiz " ---\n"
    wybor_pola: .asciiz "Wybierz pole (1-9): "
    komunikat_plansza: .asciiz "\nAktualna plansza:\n"
    komunikat_wygrana_gracz: .asciiz "Gratulacje! Wygrałeś rundę!\n"
    komunikat_wygrana_komputer: .asciiz "Komputer wygrał rundę!\n"
    komunikat_remis: .asciiz "Remis!\n"
    komunikat_wyniki: .asciiz "\n=== KOŃCOWE WYNIKI ===\n"
    komunikat_gracz_wygral: .asciiz "Gracz: "
    komunikat_komputer_wygral: .asciiz "Komputer: "
    komunikat_remisy_tekst: .asciiz "Remisy: "
    komunikat_ruch_komputera: .asciiz "Komputer wykonał ruch.\n"
    komunikat_pole_zajete: .asciiz "Pole zajęte! Spróbuj ponownie.\n"
    komunikat_nieprawidlowy_znak: .asciiz "Nieprawidłowy znak! Wybierz 79 (O) lub 88 (X).\n"
    komunikat_nieprawidlowa_liczba_rund: .asciiz "Nieprawidłowa liczba rund! Wybierz 1-5.\n"
    komunikat_nieprawidlowe_pole: .asciiz "Nieprawidłowe pole! Wybierz 1-9.\n"
    nowa_linia: .asciiz "\n"
    spacja: .asciiz " "
    separator_planszy: .asciiz " | "
    linia_planszy: .asciiz "---------\n"

.text
.globl main

main:
    # Wyświetl komunikat startowy
    li $v0, 4
    la $a0, komunikat_start
    syscall
    
    # Inicjalizuj grę
    jal inicjalizuj_gre
    
    # Pętla główna gry
    petla_gry:
        # Sprawdź czy jeszcze są rundy do rozegrania
        lw $t0, aktualna_runda
        lw $t1, liczba_rund
        bge $t0, $t1, koniec_gry
        
        # Inkrementuj numer rundy
        addi $t0, $t0, 1
        sw $t0, aktualna_runda
        
        # Wyświetl numer rundy
        jal wyswietl_numer_rundy
        
        # Zresetuj planszę
        jal zresetuj_plansze
        
        # Graj rundę
        jal graj_runde
        
        # Wróć do początku pętli
        j petla_gry
    
    koniec_gry:
        # Wyświetl końcowe wyniki
        jal wyswietl_wyniki
        
        # Zakończ program
        li $v0, 10
        syscall

# === FUNKCJE INICJALIZACJI ===

inicjalizuj_gre:
    # Zapisz adres powrotu
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    petla_wybor_znaku:
        # Wybór znaku gracza
        li $v0, 4
        la $a0, wybor_znaku
        syscall
        
        li $v0, 5
        syscall
        move $t0, $v0
        
        # Sprawdź poprawność znaku
        li $t1, 79      # 'O'
        beq $t0, $t1, znak_ok
        li $t1, 88      # 'X'
        beq $t0, $t1, znak_ok
        
        # Nieprawidłowy znak
        li $v0, 4
        la $a0, komunikat_nieprawidlowy_znak
        syscall
        j petla_wybor_znaku
    
    znak_ok:
        sw $t0, znak_gracza
        
        # Ustaw znak komputera (przeciwny)
        li $t1, 79      # 'O'
        beq $t0, $t1, ustaw_x_komputer
        li $t1, 79      # Komputer = 'O'
        sw $t1, znak_komputera
        j dalej_inicjalizacja
        
        ustaw_x_komputer:
            li $t1, 88  # Komputer = 'X'
            sw $t1, znak_komputera
    
    dalej_inicjalizacja:
    
    petla_wybor_rund:
        # Wybór liczby rund
        li $v0, 4
        la $a0, wybor_rund
        syscall
        
        li $v0, 5
        syscall
        move $t0, $v0
        
        # Sprawdź poprawność liczby rund (1-5)
        blt $t0, 1, nieprawidlowa_liczba_rund
        bgt $t0, 5, nieprawidlowa_liczba_rund
        
        sw $t0, liczba_rund
        j koniec_inicjalizacji
        
        nieprawidlowa_liczba_rund:
            li $v0, 4
            la $a0, komunikat_nieprawidlowa_liczba_rund
            syscall
            j petla_wybor_rund
    
    koniec_inicjalizacji:
    # Przywróć adres powrotu
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# === FUNKCJE PLANSZY ===

zresetuj_plansze:
    # Zapisz rejestry
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)
    
    # Inicjalizuj licznik pętli
    li $s0, 0           # i = 0
    li $s1, 9           # maksymalny indeks
    la $t2, plansza     # adres bazowy planszy
    
    petla_reset:
        # Sprawdź warunek pętli
        bge $s0, $s1, koniec_reset
        
        # Oblicz adres elementu planszy[i]
        sll $t0, $s0, 2    # i * 4 (rozmiar słowa)
        add $t0, $t0, $t2  # adres planszy[i]
        
        # Ustaw pole jako puste (32 = spacja)
        li $t1, 32
        sw $t1, 0($t0)
        
        # i++
        addi $s0, $s0, 1
        j petla_reset
    
    koniec_reset:
    # Przywróć rejestry
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

wyswietl_plansze:
    # Zapisz rejestry
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $s2, 0($sp)
    
    # Wyświetl nagłówek
    li $v0, 4
    la $a0, komunikat_plansza
    syscall
    
    # Inicjalizuj zmienne pętli
    li $s0, 0           # i = 0
    li $s1, 9           # maksymalny indeks
    la $s2, plansza     # adres bazowy planszy
    
    petla_wyswietlania:
        # Sprawdź warunek pętli
        bge $s0, $s1, koniec_wyswietlania
        
        # Oblicz adres elementu planszy[i]
        sll $t0, $s0, 2    # i * 4
        add $t0, $t0, $s2  # adres planszy[i]
        
        # Załaduj znak z planszy
        lw $t1, 0($t0)
        
        # Wyświetl znak
        li $v0, 11
        move $a0, $t1
        syscall
        
        # Sprawdź pozycję dla formatowania
        addi $t2, $s0, 1   # i + 1
        
        # Sprawdź czy to koniec wiersza
        li $t3, 3
        div $t2, $t3
        mfhi $t4           # reszta z dzielenia
        
        beqz $t4, nowa_linia_plansza  # jeśli reszta = 0, nowa linia
        
        # Nie koniec wiersza - dodaj separator
        li $v0, 4
        la $a0, separator_planszy
        syscall
        j dalej_wyswietlanie
        
        nowa_linia_plansza:
            li $v0, 4
            la $a0, nowa_linia
            syscall
            
            # Dodaj linię podziału (oprócz ostatniego wiersza)
            li $t5, 6
            bgt $s0, $t5, bez_linii_podzialu
            li $v0, 4
            la $a0, linia_planszy
            syscall
            
        bez_linii_podzialu:
        
        dalej_wyswietlanie:
        # i++
        addi $s0, $s0, 1
        j petla_wyswietlania
    
    koniec_wyswietlania:
    # Przywróć rejestry
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra

# === FUNKCJE RUCHU ===

wykonaj_ruch_gracza:
    # Zapisz rejestry
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)
    
    petla_ruchu_gracza:
        # Wyświetl planszę
        jal wyswietl_plansze
        
        # Poproś o wybór pola
        li $v0, 4
        la $a0, wybor_pola
        syscall
        
        li $v0, 5
        syscall
        move $s0, $v0       # numer pola (1-9)
        
        # Sprawdź poprawność numeru pola
        blt $s0, 1, nieprawidlowe_pole
        bgt $s0, 9, nieprawidlowe_pole
        
        # Konwertuj na indeks tablicy (0-8)
        addi $s0, $s0, -1
        
        # Sprawdź czy pole jest wolne
        move $a0, $s0
        jal sprawdz_pole_wolne
        beqz $v0, pole_zajete
        
        # Wykonaj ruch
        move $a0, $s0
        lw $a1, znak_gracza
        jal postaw_znak
        j koniec_ruchu_gracza
        
        nieprawidlowe_pole:
            li $v0, 4
            la $a0, komunikat_nieprawidlowe_pole
            syscall
            j petla_ruchu_gracza
        
        pole_zajete:
            li $v0, 4
            la $a0, komunikat_pole_zajete
            syscall
            j petla_ruchu_gracza
    
    koniec_ruchu_gracza:
    # Przywróć rejestry
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

wykonaj_ruch_komputera:
    # Prosta strategia: znajdź pierwsze wolne pole
    # Zapisz rejestry
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)
    
    li $s0, 0           # i = 0
    li $s1, 9           # maksymalny indeks
    
    petla_ruchu_komputera:
        bge $s0, $s1, koniec_ruchu_komputera
        
        move $a0, $s0
        jal sprawdz_pole_wolne
        bnez $v0, wykonaj_ruch_komp
        
        addi $s0, $s0, 1
        j petla_ruchu_komputera
    
    wykonaj_ruch_komp:
        move $a0, $s0
        lw $a1, znak_komputera
        jal postaw_znak
        
        # Wyświetl komunikat o ruchu komputera
        li $v0, 4
        la $a0, komunikat_ruch_komputera
        syscall
    
    koniec_ruchu_komputera:
    # Przywróć rejestry
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

# === FUNKCJE POMOCNICZE ===

sprawdz_pole_wolne:
    # $a0 = indeks pola (0-8)
    # zwraca 1 jeśli wolne, 0 jeśli zajęte
    
    la $t0, plansza
    sll $t1, $a0, 2        # indeks * 4
    add $t1, $t1, $t0      # adres pola
    lw $t2, 0($t1)         # zawartość pola
    
    li $t3, 32             # kod spacji
    seq $v0, $t2, $t3      # 1 jeśli równe spacji
    jr $ra

postaw_znak:
    # $a0 = indeks pola (0-8)
    # $a1 = znak do postawienia
    
    la $t1, plansza
    sll $t2, $a0, 2        # indeks * 4
    add $t2, $t2, $t1      # adres pola
    sw $a1, 0($t2)         # postaw znak
    jr $ra

sprawdz_wygrana:
    # Zwraca kod znaku wygrywającego lub 0 jeśli brak wygranej
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Sprawdź wiersze
    jal sprawdz_wiersze
    bnez $v0, koniec_sprawdzenia
    
    # Sprawdź kolumny
    jal sprawdz_kolumny
    bnez $v0, koniec_sprawdzenia
    
    # Sprawdź przekątne
    jal sprawdz_przekatne
    
    koniec_sprawdzenia:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

sprawdz_wiersze:
    # Sprawdź każdy wiersz
    li $t0, 0               # numer wiersza
    
    petla_wierszy:
        li $t7, 3
        bge $t0, $t7, koniec_wierszy
        
        # Oblicz indeksy pól w wierszu
        li $t1, 3
        mul $t1, $t0, $t1   # pierwszy indeks wiersza
        addi $t2, $t1, 1    # drugi indeks
        addi $t3, $t1, 2    # trzeci indeks
        
        # Pobierz znaki z planszy
        la $t4, plansza
        sll $t5, $t1, 2
        add $t5, $t5, $t4
        lw $s0, 0($t5)      # pierwszy znak
        
        sll $t5, $t2, 2
        add $t5, $t5, $t4
        lw $s1, 0($t5)      # drugi znak
        
        sll $t5, $t3, 2
        add $t5, $t5, $t4
        lw $s2, 0($t5)      # trzeci znak
        
        # Sprawdź czy wszystkie są takie same i nie puste
        bne $s0, $s1, nastepny_wiersz
        bne $s1, $s2, nastepny_wiersz
        li $t6, 32          # spacja
        beq $s0, $t6, nastepny_wiersz
        
        # Znaleziono wygraną
        move $v0, $s0
        jr $ra
        
        nastepny_wiersz:
        addi $t0, $t0, 1
        j petla_wierszy
    
    koniec_wierszy:
    li $v0, 0
    jr $ra

sprawdz_kolumny:
    # Podobnie jak wiersze, ale indeksy: 0,3,6 | 1,4,7 | 2,5,8
    li $t0, 0               # numer kolumny
    
    petla_kolumn:
        li $t7, 3
        bge $t0, $t7, koniec_kolumn
        
        # Oblicz indeksy pól w kolumnie
        move $t1, $t0       # pierwszy indeks
        addi $t2, $t0, 3    # drugi indeks
        addi $t3, $t0, 6    # trzeci indeks
        
        # Pobierz znaki z planszy
        la $t4, plansza
        sll $t5, $t1, 2
        add $t5, $t5, $t4
        lw $s0, 0($t5)
        
        sll $t5, $t2, 2
        add $t5, $t5, $t4
        lw $s1, 0($t5)
        
        sll $t5, $t3, 2
        add $t5, $t5, $t4
        lw $s2, 0($t5)
        
        # Sprawdź czy wszystkie są takie same i nie puste
        bne $s0, $s1, nastepna_kolumna
        bne $s1, $s2, nastepna_kolumna
        li $t6, 32
        beq $s0, $t6, nastepna_kolumna
        
        # Znaleziono wygraną
        move $v0, $s0
        jr $ra
        
        nastepna_kolumna:
        addi $t0, $t0, 1
        j petla_kolumn
    
    koniec_kolumn:
    li $v0, 0
    jr $ra

sprawdz_przekatne:
    # Przekątna główna: 0,4,8
    la $t0, plansza
    lw $s0, 0($t0)      # pole 0
    lw $s1, 16($t0)     # pole 4 (4*4=16)
    lw $s2, 32($t0)     # pole 8 (8*4=32)
    
    bne $s0, $s1, sprawdz_druga_przekatna
    bne $s1, $s2, sprawdz_druga_przekatna
    li $t1, 32
    beq $s0, $t1, sprawdz_druga_przekatna
    
    move $v0, $s0
    jr $ra
    
    sprawdz_druga_przekatna:
    # Przekątna poboczna: 2,4,6
    lw $s0, 8($t0)      # pole 2 (2*4=8)
    lw $s1, 16($t0)     # pole 4 (4*4=16)
    lw $s2, 24($t0)     # pole 6 (6*4=24)
    
    bne $s0, $s1, brak_wygranej_przekatne
    bne $s1, $s2, brak_wygranej_przekatne
    li $t1, 32
    beq $s0, $t1, brak_wygranej_przekatne
    
    move $v0, $s0
    jr $ra
    
    brak_wygranej_przekatne:
    li $v0, 0
    jr $ra

sprawdz_remis:
    # Sprawdź czy wszystkie pola są zajęte
    li $t0, 0           # licznik zajętych pól
    li $t1, 0           # indeks
    la $t2, plansza
    
    petla_sprawdz_remis:
        li $t7, 9
        bge $t1, $t7, koniec_sprawdz_remis
        
        sll $t3, $t1, 2
        add $t3, $t3, $t2
        lw $t4, 0($t3)
        
        li $t5, 32      # spacja
        beq $t4, $t5, nie_remis
        
        addi $t0, $t0, 1    # zwiększ licznik zajętych pól
        
        nie_remis:
        addi $t1, $t1, 1
        j petla_sprawdz_remis
    
    koniec_sprawdz_remis:
    # Jeśli wszystkie 9 pól zajęte - remis
    li $v0, 0
    li $t6, 9
    blt $t0, $t6, koniec_funkcji_remis
    li $v0, 1
    
    koniec_funkcji_remis:
    jr $ra

# === FUNKCJA GŁÓWNEJ RUNDY ===

graj_runde:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    petla_runda:
        # Ruch gracza
        jal wykonaj_ruch_gracza
        
        # Sprawdź wygraną
        jal sprawdz_wygrana
        bnez $v0, sprawdz_kto_wygral
        
        # Sprawdź remis
        jal sprawdz_remis
        bnez $v0, remis_rundy
        
        # Ruch komputera
        jal wykonaj_ruch_komputera
        
        # Sprawdź wygraną
        jal sprawdz_wygrana
        bnez $v0, sprawdz_kto_wygral
        
        # Sprawdź remis
        jal sprawdz_remis
        bnez $v0, remis_rundy
        
        j petla_runda
    
    sprawdz_kto_wygral:
        lw $t0, znak_gracza
        beq $v0, $t0, wygrana_gracza
        j wygrana_komputera
    
    wygrana_gracza:
        jal wyswietl_plansze
        li $v0, 4
        la $a0, komunikat_wygrana_gracz
        syscall
        
        lw $t0, wygrane_gracza
        addi $t0, $t0, 1
        sw $t0, wygrane_gracza
        j koniec_rundy
    
    wygrana_komputera:
        jal wyswietl_plansze
        li $v0, 4
        la $a0, komunikat_wygrana_komputer
        syscall
        
        lw $t0, wygrane_komputera
        addi $t0, $t0, 1
        sw $t0, wygrane_komputera
        j koniec_rundy
    
    remis_rundy:
        jal wyswietl_plansze
        li $v0, 4
        la $a0, komunikat_remis
        syscall
        
        lw $t0, remisy
        addi $t0, $t0, 1
        sw $t0, remisy
    
    koniec_rundy:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# === FUNKCJE WYŚWIETLANIA ===

wyswietl_numer_rundy:
    li $v0, 4
    la $a0, komunikat_runda
    syscall
    
    li $v0, 1
    lw $a0, aktualna_runda
    syscall
    
    li $v0, 4
    la $a0, komunikat_runda2
    syscall
    
    jr $ra

wyswietl_wyniki:
    li $v0, 4
    la $a0, komunikat_wyniki
    syscall
    
    # Wyniki gracza
    li $v0, 4
    la $a0, komunikat_gracz_wygral
    syscall
    
    li $v0, 1
    lw $a0, wygrane_gracza
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Wyniki komputera
    li $v0, 4
    la $a0, komunikat_komputer_wygral
    syscall
    
    li $v0, 1
    lw $a0, wygrane_komputera
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    # Remisy
    li $v0, 4
    la $a0, komunikat_remisy_tekst
    syscall
    
    li $v0, 1
    lw $a0, remisy
    syscall
    
    li $v0, 4
    la $a0, nowa_linia
    syscall
    
    jr $ra