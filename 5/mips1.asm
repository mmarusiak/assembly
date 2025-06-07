# Definicje makr do podstawowych operacji
.macro drukuj (%etykieta)
    la $a0, %etykieta           # zaladuj adres etykiety
    li $v0, 4                   # kod syscall dla drukowania stringa
    syscall                     # wywolaj funkcje systemowa
.end_macro

.macro drukuj_adres (%adres)
    move $a0, %adres            # przenieś adres do rejestru argumentu
    li $v0, 4                   # kod syscall dla drukowania stringa
    syscall                     # wywolaj funkcje systemowa
.end_macro

.macro drukuj_liczbe (%rejestr)
    move $a0, %rejestr          # przenieś liczbę do rejestru argumentu
    li $v0, 1                   # kod syscall dla drukowania liczby int
    syscall                     # wywolaj funkcje systemowa
.end_macro

.macro drukuj_znak_adr (%rejestr)
    lb $a0, (%rejestr)          # zaladuj bajt z adresu
    li $v0, 11                  # kod syscall dla drukowania znaku
    syscall                     # wywolaj funkcje systemowa
.end_macro

.macro drukuj_znak_etykieta (%rejestr)
    lb $a0, %rejestr            # zaladuj bajt z etykiety
    li $v0, 11                  # kod syscall dla drukowania znaku
    syscall                     # wywolaj funkcje systemowa
.end_macro

.macro rozpocznij_funkcje
    sw $fp, -4($sp)             # zapisz stary frame pointer
    sw $ra, -8($sp)             # zapisz adres powrotu
    addi $sp, $sp, -8           # przesuń stos o 8 bajtów
    move $fp, $sp               # ustaw nowy frame pointer
.end_macro

.macro powrot
    la $sp, 8($fp)              # przywróć stack pointer
    lw $ra, ($fp)               # przywróć adres powrotu
    lw $fp, 4($fp)              # przywróć frame pointer
    jr $ra                      # skocz do adresu powrotu
.end_macro

.macro czytaj_cyfre
    li $v0, 12                  # kod syscall dla czytania znaku
    syscall                     # wywolaj funkcje systemowa
    addi $v0, $v0, -48          # konwertuj ASCII na liczbę (odejmij '0')
.end_macro

.macro wyjscie
    li $v0, 10                   # kod syscall dla wyjścia z programu
    syscall                     # wywolaj funkcje systemowa
.end_macro

.data
    # Komunikaty wyświetlane graczowi
    komunikat_liczba_rund: .asciiz "\nWybierz liczbe rund (1-5): \n"
    komunikat_blad_rund: .asciiz "\nNieprawidlowy wybor\n"

    komunikat_wybor_znaku: .asciiz "\nWybierz swoj znak (kolko - 0, krzyzyk 1): "
    komunikat_blad_znaku: .asciiz "\nNieprawidlowy wybor\n"
    
    komunikat_wygrane_komputera: .asciiz "\nLiczba wygranych komputera: "
    komunikat_wygrane_gracza: .asciiz "\nLiczba wygranych gracza: "
    
    komunikat_wybor_pola: .asciiz "\nPodaj pole (1-9): "
    komunikat_blad_pola: .asciiz "\nNieprawidlowe pole\n"
    komunikat_wybor_komputera: .asciiz "\nKomputer wybral: "
    
    komunikat_wygral_komputer: .asciiz "\nKomputer wygral\n"
    komunikat_wygral_gracz: .asciiz "\nGracz wygral\n"
    komunikat_remis: .asciiz "\nRemis\n"
    
    nowa_linia: .byte 10         # znak nowej linii ('\n')

    # Definicje znaków na planszy
    gracz: .byte 88              # X - znak gracza (domyślnie)
    komputer: .byte 79           # O - znak komputera (domyślnie)
    puste_pole: .byte 46         # . - puste pole

    # Definicje linii wygrywających (8 możliwych kombinacji)
    # Numery pól to -1 do -9 (ujemne offsety od adresu bazowego)
    # Kolejność: 3 poziome, 3 pionowe, 2 przekątne
    linie: .byte -1 -2 -3, -4 -5 -6, -7 -8 -9, -1 -4 -7, -2 -5 -8, -3 -6 -9, -1 -5 -9, -7 -5 -3

.text
    # Rejestry globalne:
    # s0 - liczba pozostałych rund
    # s1 - liczba wygranych gracza
    # s2 - liczba wygranych komputera
    # s3 - adres bazowy planszy
    main:
        move $fp, $sp               # ustaw frame pointer na szczyt stosu
        move $s3, $fp               # zapisz adres bazowy planszy
        move $a0, $fp               # przygotuj argument dla funkcji
        jal przygotuj_plansze       # zainicjalizuj planszę
        addi $sp, $sp, -12          # zarezerwuj miejsce na planszę (9 bajtów + padding)
        
        jal pobierz_liczbe_rund     # zapytaj gracza o liczbę rund
        
        # Główna pętla gry - wykonuj rundy
        petla_rund:
            beqz $s0, koniec_gry    # jeśli brak rund, zakończ
            jal pobierz_znak_gracza # zapytaj o wybór znaku
            
            jal wykonaj_runde       # zagraj jedną rundę
            addi $s0, $s0, -1       # zmniejsz liczbę pozostałych rund
            j petla_rund            # przejdź do następnej rundy
            
        koniec_gry:
            jal drukuj_wynik        # wyświetl końcowy wynik
            wyjscie                 # zakończ program
        
    # Funkcja pobierająca liczbę rund od gracza
    pobierz_liczbe_rund:
        drukuj (komunikat_liczba_rund)  # wyświetl komunikat
        czytaj_cyfre                    # wczytaj cyfrę od gracza
        blez $v0, blad_liczby_rund      # sprawdź czy liczba > 0
        bgt $v0, 5, blad_liczby_rund    # sprawdź czy liczba <= 5
        
        move $s0, $v0               # zapisz liczbę rund
        jr $ra                      # powrót z funkcji
        
        blad_liczby_rund:
            drukuj (komunikat_blad_rund)    # wyświetl komunikat błędu
            j pobierz_liczbe_rund           # spróbuj ponownie
    
    # Funkcja pobierająca wybór znaku od gracza
    pobierz_znak_gracza:
        drukuj (komunikat_wybor_znaku)  # wyświetl komunikat
        czytaj_cyfre                    # wczytaj cyfrę
        beqz $v0, gracz_kolko          # 0 = gracz wybiera kółko
        beq $v0, 1, gracz_krzyzyk      # 1 = gracz wybiera krzyżyk
        drukuj (komunikat_blad_znaku)   # nieprawidłowy wybór
        j pobierz_znak_gracza           # spróbuj ponownie
        
        gracz_kolko:
            li $v0, 79              # O - kółko dla gracza
            sb $v0, gracz           # zapisz znak gracza
            li $v0, 88              # X - krzyżyk dla komputera
            sb $v0, komputer        # zapisz znak komputera
            jr $ra                  # powrót z funkcji
            
        gracz_krzyzyk:
            li $v0, 79              # O - kółko dla komputera
            sb $v0, komputer        # zapisz znak komputera
            li $v0, 88              # X - krzyżyk dla gracza
            sb $v0, gracz           # zapisz znak gracza
            jr $ra                  # powrót z funkcji
    
    # Funkcja wyświetlająca końcowy wynik gry
    drukuj_wynik:
        drukuj (komunikat_wygrane_gracza)   # wyświetl komunikat
        drukuj_liczbe ($s1)                 # wyświetl liczbę wygranych gracza
        drukuj (komunikat_wygrane_komputera) # wyświetl komunikat
        drukuj_liczbe ($s2)                 # wyświetl liczbę wygranych komputera
        jr $ra                              # powrót z funkcji
        
    # Sekcja wykonywania pojedynczej rundy gry
    wykonaj_runde:
        rozpocznij_funkcje          # przygotuj stos funkcji
        
        move $a0, $s3               # przekaż adres planszy
        jal przygotuj_plansze       # wyczyść planszę
        
        # Pętla ruchów w rundzie - naprzemiennie gracz i komputer
        ruch_gracza:
            drukuj_znak_etykieta (nowa_linia)   # wyświetl nową linię
            move $a0, $s3                       # przekaż adres planszy
            jal rysuj_plansze                   # wyświetl planszę
        
            move $a0, $s3                       # przekaż adres planszy
            jal zapytaj_o_ruch_gracza           # pobierz ruch gracza
            
            add $t0, $s3, $v0                   # oblicz adres pola
            lb $t1, gracz                       # załaduj znak gracza
            sb $t1, ($t0)                       # umieść znak na planszy
            
            move $a0, $s3                       # przekaż adres planszy
            jal sprawdz_stan_gry                # sprawdź czy gra się skończyła
            beqz $v0, ruch_komputera            # jeśli gra trwa, ruch komputera
            j koniec_rundy                      # inaczej zakończ rundę
            
        ruch_komputera:
            move $a0, $s3                       # przekaż adres planszy
            jal znajdz_najlepszy_ruch_komputera # oblicz ruch komputera - zwrotka w v0
            add $t0, $s3, $v0                   # oblicz adres pola
            move $t9, $v0
            li $t8, -1
            mult $t9, $t8
            mflo $t9
            drukuj (komunikat_wybor_komputera)
            drukuj_liczbe ($t9) 		# wypisz informacje gdzie ruszyl sie komputer
            lb $t1, komputer                    # załaduj znak komputera
            sb $t1, ($t0)                       # umieść znak na planszy
            
            move $a0, $s3                       # przekaż adres planszy
            jal sprawdz_stan_gry                # sprawdź czy gra się skończyła
            beqz $v0, ruch_gracza               # jeśli gra trwa, ruch gracza
            j koniec_rundy                      # inaczej zakończ rundę
        
        koniec_rundy:
            seq $t0, $v0, 1                     # sprawdź czy gracz wygrał
            seq $t1, $v0, 2                     # sprawdź czy komputer wygrał
            add $s1, $s1, $t0                   # dodaj wygraną gracza
            add $s2, $s2, $t1                   # dodaj wygraną komputera
            
            # Wyświetl odpowiedni komunikat o wyniku rundy
            bne $t0, 1, pomin_wygrana_gracza
            drukuj (komunikat_wygral_gracz)
            
            pomin_wygrana_gracza:
            bne $t1, 1, pomin_wygrana_komputera
            drukuj (komunikat_wygral_komputer)
            
            pomin_wygrana_komputera:
            or $t0, $t0, $t1                    # sprawdź czy ktoś wygrał
            bne $t0, 0, pomin_remis             # jeśli tak, pomiń remis
            drukuj (komunikat_remis)            # inaczej wyświetl remis
            
            pomin_remis:
            powrot                              # powrót z funkcji
        
    # Funkcja pobierająca i walidująca ruch gracza
    zapytaj_o_ruch_gracza:
        # Argumenty: a0 - adres pierwszego pola planszy
        # Zwraca: v0 - wybrany ruch (offset -1 do -9)
        move $t0, $a0                       # zapisz adres planszy
        
        zapytaj_o_ruch:
            drukuj_znak_etykieta (nowa_linia)   # wyświetl nową linię
            drukuj (komunikat_wybor_pola)       # wyświetl komunikat
            czytaj_cyfre                        # wczytaj cyfrę
            blez $v0, blad_ruchu               # sprawdź czy liczba > 0
            bgt $v0, 9, blad_ruchu             # sprawdź czy liczba <= 9
            
            neg $v0, $v0                       # konwertuj na ujemny offset
            add $t1, $t0, $v0                  # oblicz adres pola
            lb $t2, puste_pole                 # załaduj znak pustego pola
            lb $t1, ($t1)                      # załaduj zawartość pola
            bne $t2, $t1, blad_ruchu           # sprawdź czy pole jest puste
            
            move $t0, $v0                      # zapisz wybrany ruch
            drukuj_znak_etykieta (nowa_linia)  # wyświetl nową linię
            move $v0, $t0                      # przywróć wybrany ruch
            jr $ra                             # powrót z funkcji
            
        blad_ruchu:
            drukuj (komunikat_blad_pola)       # wyświetl komunikat błędu
            j zapytaj_o_ruch                   # spróbuj ponownie
    
    # Funkcja inicjalizująca pustą planszę
    przygotuj_plansze:
        # Argumenty: a0 - adres pierwszego pola planszy
        lb $t0, puste_pole              # załaduj znak pustego pola
        
        # Wypełnij wszystkie 9 pól znakiem pustego pola
        sb $t0, -1($a0)                 # pole 1
        sb $t0, -2($a0)                 # pole 2
        sb $t0, -3($a0)                 # pole 3
        sb $t0, -4($a0)                 # pole 4
        sb $t0, -5($a0)                 # pole 5
        sb $t0, -6($a0)                 # pole 6
        sb $t0, -7($a0)                 # pole 7
        sb $t0, -8($a0)                 # pole 8
        sb $t0, -9($a0)                 # pole 9
        jr $ra                          # powrót z funkcji
    
    # Funkcja rysująca planszę na ekranie
    rysuj_plansze:
        # Argumenty: a0 - adres pierwszego pola planszy
        # Zapisz rejestry na stosie
        sw $t0, -4($sp)
        sw $t1, -8($sp)
        sw $a0, -12($sp)
        move $t0, $a0                   # kopiuj adres planszy
        
        # Pierwszy rząd - pola 1, 2, 3
        addi $t0, $t0, -1               # przejdź do pola 1
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre1     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po1
        drukuj_cyfre1:
            li $a0, 49                  # znak '1' (ASCII 49)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po1:
        
        addi $t0, $t0, -1               # przejdź do pola 2
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre2     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po2
        drukuj_cyfre2:
            li $a0, 50                  # znak '2' (ASCII 50)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po2:
        
        addi $t0, $t0, -1               # przejdź do pola 3
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre3     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po3
        drukuj_cyfre3:
            li $a0, 51                  # znak '3' (ASCII 51)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po3:
        drukuj_znak_etykieta (nowa_linia)   # nowa linia po pierwszym rzędzie
        
        # Drugi rząd - pola 4, 5, 6
        addi $t0, $t0, -1               # przejdź do pola 4
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre4     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po4
        drukuj_cyfre4:
            li $a0, 52                  # znak '4' (ASCII 52)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po4:
        
        addi $t0, $t0, -1               # przejdź do pola 5
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre5     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po5
        drukuj_cyfre5:
            li $a0, 53                  # znak '5' (ASCII 53)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po5:
        
        addi $t0, $t0, -1               # przejdź do pola 6
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre6     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po6
        drukuj_cyfre6:
            li $a0, 54                  # znak '6' (ASCII 54)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po6:
        drukuj_znak_etykieta (nowa_linia)   # nowa linia po drugim rzędzie
        
        # Trzeci rząd - pola 7, 8, 9
        addi $t0, $t0, -1               # przejdź do pola 7
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre7     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po7
        drukuj_cyfre7:
            li $a0, 55                  # znak '7' (ASCII 55)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po7:
        
        addi $t0, $t0, -1               # przejdź do pola 8
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre8     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po8
        drukuj_cyfre8:
            li $a0, 56                  # znak '8' (ASCII 56)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po8:
        
        addi $t0, $t0, -1               # przejdź do pola 9
        lb $t1, ($t0)                   # załaduj zawartość pola
        lb $t2, puste_pole              # załaduj znak pustego pola
        beq $t1, $t2, drukuj_cyfre9     # jeśli puste, drukuj numer
        drukuj_znak_adr ($t0)           # inaczej drukuj znak
        j po9
        drukuj_cyfre9:
            li $a0, 57                  # znak '9' (ASCII 57)
            li $v0, 11                  # syscall dla drukowania znaku
            syscall
        po9:
        drukuj_znak_etykieta (nowa_linia)   # nowa linia po trzecim rzędzie
        drukuj_znak_etykieta (nowa_linia)   # dodatkowa nowa linia
        
        # Przywróć rejestry ze stosu
        lw $t0, -4($sp)
        lw $t1, -8($sp)
        lw $a0, -12($sp)
        jr $ra                          # powrót z funkcji
    
    # Funkcja sprawdzająca stan gry (wygrana, remis, gra trwa)
    sprawdz_stan_gry:
        # Argumenty: a0 - adres pierwszego pola planszy
        # Zwraca: v0 - stan (0=gra trwa, 1=gracz wygrał, 2=komputer wygrał, 3=remis)
        rozpocznij_funkcje
        
        # Sprawdź wszystkie możliwe linie wygrywające
        
        # Pierwszy rząd poziomy (1-2-3)
        lb $t0, -1($a0)                 # pole 1
        lb $t1, -2($a0)                 # pole 2
        lb $t2, -3($a0)                 # pole 3
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        # Drugi rząd poziomy (4-5-6)
        lb $t0, -4($a0)                 # pole 4
        lb $t1, -5($a0)                 # pole 5
        lb $t2, -6($a0)                 # pole 6
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        # Trzeci rząd poziomy (7-8-9)
        lb $t0, -7($a0)                 # pole 7
        lb $t1, -8($a0)                 # pole 8
        lb $t2, -9($a0)                 # pole 9
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        # Pierwsza kolumna (1-4-7)
        lb $t0, -1($a0)                 # pole 1
        lb $t1, -4($a0)                 # pole 4
        lb $t2, -7($a0)                 # pole 7
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        # Druga kolumna (2-5-8)
        lb $t0, -2($a0)                 # pole 2
        lb $t1, -5($a0)                 # pole 5
        lb $t2, -8($a0)                 # pole 8
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        # Trzecia kolumna (3-6-9)
        lb $t0, -3($a0)                 # pole 3
        lb $t1, -6($a0)                 # pole 6
        lb $t2, -9($a0)                 # pole 9
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        # Przekątna rosnąca (7-5-3)
        lb $t0, -7($a0)                 # pole 7
        lb $t1, -5($a0)                 # pole 5
        lb $t2, -3($a0)                 # pole 3
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        # Przekątna opadająca (1-5-9)
        lb $t0, -1($a0)                 # pole 1
        lb $t1, -5($a0)                 # pole 5
        lb $t2, -9($a0)                 # pole 9
        jal sprawdz_wygrana             # sprawdź czy to wygrana
        bnez $v0, zwroc_stan_wygrana    # jeśli tak, zwróć wynik
        
        j sprawdz_remis                 # sprawdź czy jest remis
        
        # Funkcja pomocnicza sprawdzająca czy trzy pola tworzą wygraną
        sprawdz_wygrana:
            # Sprawdza rejestry t0, t1, t2 - czy zawierają identyczne znaki
            seq $t0, $t0, $t1           # sprawdź czy pole1 == pole2
            seq $t1, $t1, $t2           # sprawdź czy pole2 == pole3
            and $t0, $t0, $t1           # sprawdź czy wszystkie są równe
            beqz $t0, brak_wygranej     # jeśli nie, brak wygranej
            
            # Sprawdź czy to znak gracza czy komputera
            lb $t1, gracz               # załaduj znak gracza
            beq $t1, $t2, wygrana_gracza    # jeśli pasuje, gracz wygrał
            lb $t1, komputer            # załaduj znak komputera
            beq $t1, $t2, wygrana_komputera # jeśli pasuje, komputer wygrał
            
            brak_wygranej:
                li $v0, 0               # zwróć 0 (brak wygranej)
                jr $ra
            
            wygrana_gracza:
                li $v0, 1               # zwróć 1 (gracz wygrał)
                jr $ra
                
            wygrana_komputera:
                li $v0, 2               # zwróć 2 (komputer wygrał)
                jr $ra
                
        zwroc_stan_wygrana:
            powrot                      # powrót z funkcji z wynikiem wygranej
            
       sprawdz_remis:
			li $t0, 0				# Inicjalizuj licznik pól na 0
			sprawdz_kolejne_pole_remis:
				addi $t0, $t0, -1		# Przesuń licznik na poprzednie pole
				beq $t0, -10, zwroc_remis	# Jeśli sprawdzono wszystkie 9 pól, zwróć remis
				li $t1, 0			# Wyzeruj rejestr pomocniczy
				add $t1, $a0, $t0		# Oblicz adres sprawdzanego pola
				lb $t2, ($t1)			# Załaduj znak z danego pola
				lb $t1, puste_pole		# Załaduj znak pustego pola ('.')
				beq $t2, $t1, zwroc_gra_trwa	# Jeśli pole puste, gra jeszcze trwa
				j sprawdz_kolejne_pole_remis	# Sprawdź następne pole
				
			zwroc_remis:
				li $v0, 3			# Zwróć kod remisu (3)
				powrot
				
			zwroc_gra_trwa:
				li $v0, 0			# Zwróć kod gry trwającej (0)
				powrot

	znajdz_najlepszy_ruch_komputera:
		# a0 - adres planszy
		# v0 - wybrany ruch [-1, -9]
		rozpocznij_funkcje
		move $t0, $a0        			# Skopiuj wskaźnik na początek planszy
		li $t1, 0            			# Aktualna pozycja w tablicy linii (zawsze podzielna przez 3)
		lb $t7, komputer			# Załaduj znak komputera
		
		# Sprawdź czy komputer może wygrać jednym ruchem
		petla_sprawdz_wygrana:
			beq $t1, 24, koniec_sprawdz_wygrana	# Jeśli sprawdzono wszystkie 8 linii, przejdź dalej
			
			lb $t2, linie($t1)      		# Załaduj numer pierwszego pola w linii
			add $t2, $t2, $t0       		# Oblicz adres pierwszego pola
			lb $t2, ($t2)           		# Załaduj znak z pierwszego pola
			
			lb $t3, linie + 1($t1)  		# Załaduj numer drugiego pola w linii
			add $t3, $t3, $t0       		# Oblicz adres drugiego pola
			lb $t3, ($t3)           		# Załaduj znak z drugiego pola
			
			lb $t4, linie + 2($t1)  		# Załaduj numer trzeciego pola w linii
			add $t4, $t4, $t0       		# Oblicz adres trzeciego pola
			lb $t4, ($t4)           		# Załaduj znak z trzeciego pola
			
			# Sprawdź wzór: komputer-komputer-puste
			seq $t5, $t2, $t7       		# Sprawdź czy pole 1 to znak komputera
			seq $t6, $t3, $t7       		# Sprawdź czy pole 2 to znak komputera
			and $t5, $t5, $t6       		# Połącz warunki - oba pola mają znak komputera
			seq $t6, $t4, 46        		# Sprawdź czy pole 3 jest puste (46 = '.')
			and $t5, $t5, $t6       		# Sprawdź pełny wzór komputer-komputer-puste
			lb $v0, linie + 2($t1)  		# Załaduj pozycję trzeciego pola jako potencjalny ruch
			bnez $t5, zwroc_ruch     		# Jeśli wzór pasuje, wykonaj ruch wygrywający
			
			# Sprawdź wzór: komputer-puste-komputer
			seq $t5, $t2, $t7       		# Sprawdź czy pole 1 to znak komputera
			seq $t6, $t4, $t7       		# Sprawdź czy pole 3 to znak komputera
			and $t5, $t5, $t6       		# Połącz warunki - pole 1 i 3 mają znak komputera
			seq $t6, $t3, 46        		# Sprawdź czy pole 2 jest puste
			and $t5, $t5, $t6       		# Sprawdź pełny wzór komputer-puste-komputer
			lb $v0, linie + 1($t1)  		# Załaduj pozycję drugiego pola jako potencjalny ruch
			bnez $t5, zwroc_ruch     		# Jeśli wzór pasuje, wykonaj ruch wygrywający
			
			# Sprawdź wzór: puste-komputer-komputer
			seq $t5, $t4, $t7       		# Sprawdź czy pole 3 to znak komputera
			seq $t6, $t3, $t7       		# Sprawdź czy pole 2 to znak komputera
			and $t5, $t5, $t6       		# Połącz warunki - pole 2 i 3 mają znak komputera
			seq $t6, $t2, 46        		# Sprawdź czy pole 1 jest puste
			and $t5, $t5, $t6       		# Sprawdź pełny wzór puste-komputer-komputer
			lb $v0, linie($t1)      		# Załaduj pozycję pierwszego pola jako potencjalny ruch
			bnez $t5, zwroc_ruch     		# Jeśli wzór pasuje, wykonaj ruch wygrywający
			
			addi $t1, $t1, 3			# Przejdź do następnej linii (3 bajty dalej)
			j petla_sprawdz_wygrana			# Kontynuuj sprawdzanie

		koniec_sprawdz_wygrana:
			li $t1, 0               		# Zresetuj licznik linii
			lb $t7, gracz           		# Teraz załaduj znak gracza do sprawdzenia blokady
			
		# Sprawdź czy trzeba zablokować gracza przed wygraną
		petla_sprawdz_blokada:
			beq $t1, 24, wybierz_srodek		# Jeśli sprawdzono wszystkie linie, przejdź do strategii
			
			lb $t2, linie($t1)      		# Załaduj numer pierwszego pola w linii
			add $t2, $t2, $t0       		# Oblicz adres pierwszego pola
			lb $t2, ($t2)           		# Załaduj znak z pierwszego pola
			
			lb $t3, linie + 1($t1)  		# Załaduj numer drugiego pola w linii
			add $t3, $t3, $t0       		# Oblicz adres drugiego pola
			lb $t3, ($t3)           		# Załaduj znak z drugiego pola
			
			lb $t4, linie + 2($t1)  		# Załaduj numer trzeciego pola w linii
			add $t4, $t4, $t0       		# Oblicz adres trzeciego pola
			lb $t4, ($t4)           		# Załaduj znak z trzeciego pola
			
			# Sprawdź wzór: gracz-gracz-puste
			seq $t5, $t2, $t7       		# Sprawdź czy pole 1 to znak gracza
			seq $t6, $t3, $t7       		# Sprawdź czy pole 2 to znak gracza
			and $t5, $t5, $t6       		# Połącz warunki - oba pola mają znak gracza
			seq $t6, $t4, 46        		# Sprawdź czy pole 3 jest puste
			and $t5, $t5, $t6       		# Sprawdź pełny wzór gracz-gracz-puste
			lb $v0, linie + 2($t1)  		# Załaduj pozycję trzeciego pola jako ruch blokujący
			bnez $t5, zwroc_ruch     		# Jeśli wzór pasuje, zablokuj gracza
			
			# Sprawdź wzór: gracz-puste-gracz
			seq $t5, $t2, $t7       		# Sprawdź czy pole 1 to znak gracza
			seq $t6, $t4, $t7       		# Sprawdź czy pole 3 to znak gracza
			and $t5, $t5, $t6       		# Połącz warunki - pole 1 i 3 mają znak gracza
			seq $t6, $t3, 46        		# Sprawdź czy pole 2 jest puste
			and $t5, $t5, $t6       		# Sprawdź pełny wzór gracz-puste-gracz
			lb $v0, linie + 1($t1)  		# Załaduj pozycję drugiego pola jako ruch blokujący
			bnez $t5, zwroc_ruch     		# Jeśli wzór pasuje, zablokuj gracza
			
			# Sprawdź wzór: puste-gracz-gracz
			seq $t5, $t4, $t7       		# Sprawdź czy pole 3 to znak gracza
			seq $t6, $t3, $t7       		# Sprawdź czy pole 2 to znak gracza
			and $t5, $t5, $t6       		# Połącz warunki - pole 2 i 3 mają znak gracza
			seq $t6, $t2, 46        		# Sprawdź czy pole 1 jest puste
			and $t5, $t5, $t6       		# Sprawdź pełny wzór puste-gracz-gracz
			lb $v0, linie($t1)      		# Załaduj pozycję pierwszego pola jako ruch blokujący
			bnez $t5, zwroc_ruch     		# Jeśli wzór pasuje, zablokuj gracza
			
			addi $t1, $t1, 3			# Przejdź do następnej linii
			j petla_sprawdz_blokada			# Kontynuuj sprawdzanie blokad
			
		# Jeśli brak ruchów wygrywających/blokujących, wybierz strategicznie
		wybierz_srodek:
			# Spróbuj zająć środek planszy (pole -5)
			add $t1, $t0, -5			# Oblicz adres środkowego pola
			lb $t2, ($t1)				# Załaduj znak ze środkowego pola
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_srodek		# Jeśli środek pusty, wybierz go
			
		wybierz_naroznik:
			# Spróbuj zająć narożniki w kolejności priorytetowej
			add $t1, $t0, -1        		# Oblicz adres lewego górnego narożnika
			lb $t2, ($t1)				# Załaduj znak z lewego górnego narożnika
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_lewy_gorny		# Jeśli pusty, wybierz lewy górny
			
			add $t1, $t0, -3        		# Oblicz adres prawego górnego narożnika
			lb $t2, ($t1)				# Załaduj znak z prawego górnego narożnika
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_prawy_gorny		# Jeśli pusty, wybierz prawy górny
			
			add $t1, $t0, -7        		# Oblicz adres lewego dolnego narożnika
			lb $t2, ($t1)				# Załaduj znak z lewego dolnego narożnika
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_lewy_dolny		# Jeśli pusty, wybierz lewy dolny
			
			add $t1, $t0, -9        		# Oblicz adres prawego dolnego narożnika
			lb $t2, ($t1)				# Załaduj znak z prawego dolnego narożnika
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_prawy_dolny		# Jeśli pusty, wybierz prawy dolny
			
		wybierz_bok:
			# Spróbuj zająć boczne pola (środki krawędzi)
			add $t1, $t0, -2        		# Oblicz adres górnego boku
			lb $t2, ($t1)				# Załaduj znak z górnego boku
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_gorny		# Jeśli pusty, wybierz górny bok
			
			add $t1, $t0, -4        		# Oblicz adres lewego boku
			lb $t2, ($t1)				# Załaduj znak z lewego boku
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_lewy		# Jeśli pusty, wybierz lewy bok
			
			add $t1, $t0, -6        		# Oblicz adres prawego boku
			lb $t2, ($t1)				# Załaduj znak z prawego boku
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_prawy		# Jeśli pusty, wybierz prawy bok
			
			add $t1, $t0, -8        		# Oblicz adres dolnego boku
			lb $t2, ($t1)				# Załaduj znak z dolnego boku
			lb $t3, puste_pole			# Załaduj znak pustego pola
			beq $t2, $t3, zwroc_dolny		# Jeśli pusty, wybierz dolny bok
			
		# Jeśli wszystkie strategiczne pola zajęte, znajdź pierwsze dostępne puste pole
		znajdz_puste_pole:
			li $t1, -1				# Inicjalizuj licznik od pierwszego pola
			petla_znajdz_puste:
				beq $t1, -10, zwroc_pierwsze_puste	# Jeśli sprawdzono wszystkie pola
				add $t2, $t0, $t1			# Oblicz adres sprawdzanego pola
				lb $t3, ($t2)				# Załaduj znak z pola
				lb $t4, puste_pole			# Załaduj znak pustego pola
				beq $t3, $t4, zwroc_puste		# Jeśli pole puste, wybierz je
				addi $t1, $t1, -1			# Przejdź do następnego pola
				j petla_znajdz_puste			# Kontynuuj szukanie
				
		zwroc_srodek:
			li $v0, -5				# Zwróć pozycję środka (-5)
			powrot
			
		zwroc_lewy_gorny:
			li $v0, -1				# Zwróć pozycję lewego górnego narożnika (-1)
			powrot
			
		zwroc_prawy_gorny:
			li $v0, -3				# Zwróć pozycję prawego górnego narożnika (-3)
			powrot
			
		zwroc_lewy_dolny:
			li $v0, -7				# Zwróć pozycję lewego dolnego narożnika (-7)
			powrot
			
		zwroc_prawy_dolny:
			li $v0, -9				# Zwróć pozycję prawego dolnego narożnika (-9)
			powrot
			
		zwroc_gorny:
			li $v0, -2				# Zwróć pozycję górnego boku (-2)
			powrot
			
		zwroc_lewy:
			li $v0, -4				# Zwróć pozycję lewego boku (-4)
			powrot
			
		zwroc_prawy:
			li $v0, -6				# Zwróć pozycję prawego boku (-6)
			powrot
			
		zwroc_dolny:
			li $v0, -8				# Zwróć pozycję dolnego boku (-8)
			powrot
			
		zwroc_puste:
			move $v0, $t1				# Zwróć pozycję znalezionego pustego pola
			powrot
			
		zwroc_pierwsze_puste:
			li $v0, -1				# Zwróć domyślną pozycję (-1) jako fallback
			powrot
		
		zwroc_ruch:
			powrot					# Zwróć wybrany ruch (już w $v0)
