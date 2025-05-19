.data
	prompt_operacja: .asciiz "\nDeszyfrowac (D) czy szyfrowac (S)? [D/S]:\n"
	prompt_operacja_blad: .asciiz "\n Bledna operacja. Wybierz D lub S.\n"
	prompt_dlugosc_klucza: .asciiz "\nPodaj dlugosc klucza (liczba calkowita z zakresu 3-8):\n"
	ciag_klucz_buf: .space 9 
	prompt_dlugosc_klucza_blad: .asciiz "\nNiepoprawna dlugosc klucza. Dlugosc musi byc miedzy 3 a 8.\n"
	prompt_klucz_wartosc: .asciiz "\nPodaj klucz (cyfry od 1 do DlugoscKlucza, bez powtorzen, np. dla dlugosci 4: 2413):\n"
	prompt_klucz_dlugosc_niezgadza_sie: .asciiz "\nKlucz jest zbyt krotki lub zbyt dlugi! Wpisales inna liczbe cyfr niz zadeklarowana dlugosc klucza.\n"
	prompt_klucz_wartosc_blad: .asciiz "\nKlucz jest niepoprawny! Upewnij sie, ze cyfry sa z wlasciwego zakresu (1-DlugoscKlucza) i sie nie powtarzaja.\n"
	# Zmieniony prompt informujacy o nowej funkcjonalnosci zamiany cyfr na slowa
	prompt_tekst_do_przetworzenia: .asciiz "\nPodaj tekst (cyfry 0-9 zostana zamienione na slowa, wymagane WIELKIE LITERY A-Z, spacje/interpunkcja usuniete, max 50 znakow po transformacji):\n"
	# Zmieniony komunikat bledu, aby odzwierciedlic nowe zasady walidacji
	prompt_tekst_zawiera_niedozwolone_znaki: .asciiz "\nBLAD: Tekst zawiera male litery lub inne niedozwolone znaki (po usunieciu spacji/interpunkcji i zamianie cyfr na slowa).\nWprowadz tekst jeszcze raz.\n"
	permutacja_klucza: .space 8 # dla kazdego mozliwego chara z zakresu maksymalnego spisujemy ile razy wystapil w kluczu
	tekst_wejsciowy_buf: .space 52 

	komunikat_obciecie_tekstu: .asciiz "Uwaga: Tekst po transformacji i normalizacji zostal obciety do 50 znakow.\n" # Zaktualizowany komunikat
	tekst_znormalizowany_buf: .space 51  
	tekst_wynikowy_buf: .space 51  
	znak_nowej_linii: .asciiz "\n" 
	czy_kontynuowac: .asciiz "Czy kontynuowac? t/n:\n"
	kontynuowac_zle: .asciiz "\nBledna operacja. Wybierz t/n:\n"
	klucz_dluzszy_niz_tekst: .asciiz "\nKlucz dluzszy niz tekst... Nie da sie szyfrowac - wpisz tekst jeszcze raz\n"

	slowo_zero: .asciiz "ZERO"
	slowo_jeden: .asciiz "JEDEN"
	slowo_dwa: .asciiz "DWA"
	slowo_trzy: .asciiz "TRZY"
	slowo_cztery: .asciiz "CZTERY"
	slowo_piec: .asciiz "PIEC"
	slowo_szesc: .asciiz "SZESC"
	slowo_siedem: .asciiz "SIEDEM"
	slowo_osiem: .asciiz "OSIEM"
	slowo_dziewiec: .asciiz "DZIEWIEC"
	# NOWE: Tablica wskaźników do słów dla cyfr
	adresy_slow_cyfr: .word slowo_zero, slowo_jeden, slowo_dwa, slowo_trzy, slowo_cztery, slowo_piec, slowo_szesc, slowo_siedem, slowo_osiem, slowo_dziewiec

.text
start_programu: 
	li $v0, 4
	la $a0, prompt_operacja # wypisz prompt do uzytkownika zeby wybral operacje
	syscall	
	li $v0, 12  
	syscall	
	move $s5, $v0 

	li $t1, 'd'
	beq $s5, $t1, ustaw_deszyfrowanie # jesli 'd' lub 'D' to deszyfruje
	li $t1, 'D'
	beq $s5, $t1, ustaw_deszyfrowanie
	li $t1, 's'
	beq $s5, $t1, ustaw_szyfrowanie # jesli 's' lub 'S' to szyfruje
	li $t1, 'S'
	beq $s5, $t1, ustaw_szyfrowanie
	
	li $v0, 4
	la $a0, prompt_operacja_blad # jesli nic - ponow zapytanie o operacje bo bledne wejscie!
	syscall	
	j start_programu		
ustaw_szyfrowanie:
	li $s5, 0 # s5 = 0 oznacza szyfrowanie, 1 oznacza deszyfrowanie
	j pobierz_dlugosc_klucza	
ustaw_deszyfrowanie:
	li $s5, 1 
	j pobierz_dlugosc_klucza		
pobierz_dlugosc_klucza:
	li $v0, 4
	la $a0, prompt_dlugosc_klucza # wpisz dlugosc klucza...
	syscall	
	li $v0, 5 
	syscall	
	move $s3, $v0 # rezultat do s3
	# dlugosc ma byc z zakresu [3;8]
	li $t2, 3
	blt $s3, $t2, dlugosc_klucza_niepoprawna # jesli mniejsza niz 3 to niepoprawna dlugosc
	li $t2, 8
	bgt $s3, $t2, dlugosc_klucza_niepoprawna # jesli wieksza niz 8 to niepoprawna dlugosc
	j pobierz_wartosc_klucza # jesli dlugosc poprawna - pobieramy wartosc klucza!
dlugosc_klucza_niepoprawna:
	li $v0, 4
	la $a0, prompt_dlugosc_klucza_blad
	syscall	
	j pobierz_dlugosc_klucza # wypisz ze bledna dlugosc i ponow zapytanie o klucz
pobierz_wartosc_klucza:
	# dlugosc klucza mamy w s3
	li $v0, 4
	la $a0, prompt_klucz_wartosc # wypisz zapytanie o wartosc klucza
	syscall
	la $a0, ciag_klucz_buf # wpisana wartosc bedzie do 52 bajtowego ciagu - to surowy ciag klucza
	move $a1, $s3 
	addi $a1, $a1, 2    # wrzucamy dlugosc klucza + 2 do a1, bo jeszcze \n jest wczytywane do ciagu
	li $v0, 8 # wczytaj ciag    
	syscall	
	la $a0, ciag_klucz_buf # rezultat mamy w a0
	jal normalizuj_i_zmierz_dlugosc_klucza
	
	bne $s3, $v0, klucz_ma_zla_dlugosc_po_wczytaniu # jesli zmierzona dlugosc nie jest rowna dlugosci zakladanej - cos poszlo nie tak i komunikat
	j sprawdz_zawartosc_klucza_wejscie # sprawdzamy czy wszystkie chary w zakresie sa odpowiednie, tzn z zakresu 1 - dlugosc klucza
klucz_ma_zla_dlugosc_po_wczytaniu:
	li $v0, 4
	la $a0, prompt_klucz_dlugosc_niezgadza_sie
	syscall	
	j pobierz_dlugosc_klucza 		
normalizuj_i_zmierz_dlugosc_klucza: 
	move $t1, $a0    
	li $t2, 0        
normalizuj_klucz_petla:
	lb $t3, 0($t1)      
	beq $t3, $zero, normalizuj_klucz_koniec # jesli dotarlismy do konca
	beq $t3, '\n', normalizuj_klucz_koniec_linii # jesli \n zamien na zero
	bge $t2, $s3, normalizuj_klucz_za_dlugi_przed_terminatorem # jesli za dlugi ciag - skoncz
	addi $t2, $t2, 1    
	addi $t1, $t1, 1    
	j normalizuj_klucz_petla
normalizuj_klucz_koniec_linii:
	sb $zero, 0($t1)    
	j normalizuj_klucz_koniec
normalizuj_klucz_za_dlugi_przed_terminatorem: 
	sb $zero, 0($t1) 
	j normalizuj_klucz_koniec
normalizuj_klucz_koniec:
	move $v0, $t2       
	jr $ra

sprawdz_zawartosc_klucza_wejscie:
	jal sprawdz_zawartosc_klucza_podprogram
	beqz $v0, klucz_ma_niepoprawna_zawartosc # jesli rezultat = 0 oznacza ze gdzies wykrylismy conajmniej jeden niepoprawny symbol 
	j wczytaj_i_przetworz_tekst_uzytkownika # w przeciwnym razie kontynuujmy program - wczytujemy tekst!

sprawdz_zawartosc_klucza_podprogram: 
	la $t1, permutacja_klucza # t1 to permutacja klucza
	li $t2, 0 # index
inicjalizuj_pomocniczy_buf_klucza_petla:
	bge $t2, $s3, inicjalizacja_pomocniczego_buf_klucza_koniec # jesli dotarlismy do konca - inicjalizujemy buffer ciagu (wartosci) klucza
	sb $zero, 0($t1) # zerujemy wystapienie kazdego chara
	addi $t1, $t1, 1 # przesuwamy sie na kolejne slowo, bajt
	addi $t2, $t2, 1 # indeks zwiekszamy o 1
	j inicjalizuj_pomocniczy_buf_klucza_petla
inicjalizacja_pomocniczego_buf_klucza_koniec:
	la $t1, ciag_klucz_buf # wczytujemy miejsce na wartosci ciagu klucza
	li $t2, 0 # indeks   
	li $t4, '1' # pomoc - 1 w ascii     
waliduj_cyfry_klucza_petla:
	bge $t2, $s3, walidacja_cyfr_klucza_poprawna # jesli dotarlismy na koniec bez bledow - klucz jest ok
	lb $t5, 0($t1) # ladujemy kolejny bajt z ciagu do t5
	sub $t5, $t5, $t4 # odejmujemy wartosc 1 ascii od t5
	bltz $t5, walidacja_cyfr_klucza_niepoprawna # jesli mniejsze od zera - wiemy ze wypadlismy pod, jestesmy poza zakresem ascii - zly klucz!
	bge $t5, $s3, walidacja_cyfr_klucza_niepoprawna # jesli wieksze lub rowne dlugosci klucza - rowniez to swiadczy ze wypadlismy tylko ze z drugiej strony zakresu - zly klucz
	la $t6, permutacja_klucza # wczytujemy sobie permutacje klucza
	add $t6, $t6, $t5 # przesuwamy sie na bajt odpowiadajacy danemu charowi - to jest tablica w ktorej po kolei mamy wartosci dla czarow ['1', '2', '3'] i wartosci ile razy juz byl w kluczu
	lb $t7, 0($t6) # ladujemy slowo odpowiadajce owemu bajtowi
	bne $t7, $zero, walidacja_cyfr_klucza_niepoprawna # jesli nie jest rowne 0 - oznacza ze juz tu "bylismy", ze widzielismy ta wartosc w kluczu! wartosc sie powtarza - zly klucz!
	li $t7, 1 # w przeciwnym razie ladujemy 1 do "odwiedzonego chara" - zaznaczamy tak ze juz widzielismy go w kluczu
	sb $t7, 0($t6) # zapisujemy ^
	addi $t2, $t2, 1 # dodajemy do indeksu
	addi $t1, $t1, 1 # przesuwamy sie po slowie
	j waliduj_cyfry_klucza_petla
walidacja_cyfr_klucza_poprawna:
	li $v0, 1 # ustawiamy wynik na 1 - informacja ze ok
	jr $ra # wracamy
walidacja_cyfr_klucza_niepoprawna:
	li $v0, 0 # ustawiamy wynik na 0 - informacja ze zly klucz        
	jr $ra # wracamy
klucz_ma_niepoprawna_zawartosc:
	li $v0, 4
	la $a0, prompt_klucz_wartosc_blad
	syscall	
	j pobierz_dlugosc_klucza # jesli klucz byl zly - informujemy uzytkownika i ponawiamy probe inputu

wczytaj_i_przetworz_tekst_uzytkownika: 
	li $v0, 4
	la $a0, prompt_tekst_do_przetworzenia # wczytaj tekst (prompt zaktualizowany)
	syscall	
	la $a0, tekst_wejsciowy_buf # surowy tekst wejsciowy
	li $v0, 8 
	li $a1, 52 
	syscall	
	
	# NOWA SEKCJA: Przetwarzanie tekstu z zamianą cyfr na słowa i walidacją
	la $s0, tekst_wejsciowy_buf       # $s0 = wskaźnik na źródłowy tekst_wejsciowy_buf
	la $s1, tekst_znormalizowany_buf  # $s1 = wskaźnik zapisu do tekst_znormalizowany_buf
	li $s4, 0                         # $s4 = licznik znaków w tekscie_znormalizowanym (finalna długość)
	li $t8, 0                         # $t8 = flaga błędu (0 = OK, 1 = błąd)
	li $t9, 50                        # $t9 = maksymalna długość tekstu znormalizowanego

normalizuj_konwertuj_waliduj_petla:
	lb $t2, 0($s0)                    # $t2 = bieżący znak z tekst_wejsciowy_buf
	
	beq $t2, $zero, normalizacja_konwertowanie_zakonczone_stringiem
	beq $t2, '\n', normalizacja_konwertowanie_zakonczone_linia

	# Sprawdzenie, czy osiągnięto limit długości dla tekstu znormalizowanego
	# Ten check jest tutaj, aby najpierw sprawdzić limit, zanim dodamy potencjalnie długie słowo za cyfrę.
	bge $s4, $t9, normalizacja_limit_osiagniety_przewin_reszte_wejscia

	# Sprawdzenie czy cyfra '0'-'9'
	li $t4, '0'
	blt $t2, $t4, normalizacja_sprawdz_litere
	li $t4, '9'
	bgt $t2, $t4, normalizacja_sprawdz_litere
	# Jest cyfra '0'-'9' -> zamień na słowo
	subi $t3, $t2, '0' # $t3 = wartość cyfry (0-9)
	sll $t3, $t3, 2    # $t3 = offset w tablicy adresow_slow_cyfr (wartosc_cyfry * 4)
	la $t4, adresy_slow_cyfr
	add $t4, $t4, $t3  # $t4 = adres wskaźnika do słowa dla cyfry w tablicy
	lw $t5, 0($t4)     # $t5 = adres stringu ze słowem (np. adres "ZERO")
	# Pętla kopiująca słowo cyfry do tekst_znormalizowany_buf
normalizacja_kopiuj_slowo_cyfry_petla:
	lb $t6, 0($t5)     # $t6 = znak ze słowa cyfry (np. 'Z', 'E', 'R', 'O')
	beqz $t6, normalizacja_koniec_kopiowania_slowa_cyfry # Jeśli koniec słowa (null terminator)
	
	bge $s4, $t9, normalizacja_limit_osiagniety_przewin_reszte_wejscia # Sprawdź limit PRZED każdym zapisem znaku słowa
	
	sb $t6, 0($s1)     # Zapisz znak słowa do tekst_znormalizowany_buf
	addi $s1, $s1, 1   # Przesuń wskaźnik zapisu w tekst_znormalizowany_buf
	addi $s4, $s4, 1   # Inkrementuj licznik długości tekstu znormalizowanego
	addi $t5, $t5, 1   # Następny znak słowa cyfry
	j normalizacja_kopiuj_slowo_cyfry_petla
normalizacja_koniec_kopiowania_slowa_cyfry:
	j normalizacja_nastepny_znak_wejsciowy # Po skopiowaniu słowa, przejdź do następnego znaku z wejścia

normalizacja_sprawdz_litere:
	# Sprawdzenie czy wielka litera A-Z
	li $t4, 'A'
	blt $t2, $t4, normalizacja_sprawdz_mala_litere
	li $t4, 'Z'
	bgt $t2, $t4, normalizacja_sprawdz_mala_litere
	# Jest wielką literą A-Z -> skopiuj
	sb $t2, 0($s1)     # Zapisz wielką literę
	addi $s1, $s1, 1
	addi $s4, $s4, 1
	j normalizacja_nastepny_znak_wejsciowy

normalizacja_sprawdz_mala_litere:
	# Sprawdzenie czy mała litera a-z -> BŁĄD
	li $t4, 'a'
	blt $t2, $t4, normalizacja_sprawdz_interpunkcje_do_usuniecia
	li $t4, 'z'
	bgt $t2, $t4, normalizacja_sprawdz_interpunkcje_do_usuniecia
	# Jest małą literą -> BŁĄD
	li $t8, 1          # Ustaw flagę błędu
	# Kontynuuj pętlę, aby wczytać resztę linii, błąd zostanie sprawdzony na końcu
	j normalizacja_nastepny_znak_wejsciowy 

normalizacja_sprawdz_interpunkcje_do_usuniecia:
	# Sprawdzenie czy spacja lub typowa interpunkcja -> Pomiń (usuń)
	li $t4, ' '
	beq $t2, $t4, normalizacja_nastepny_znak_wejsciowy 
	li $t4, '.'
	beq $t2, $t4, normalizacja_nastepny_znak_wejsciowy 
	li $t4, ','
	beq $t2, $t4, normalizacja_nastepny_znak_wejsciowy 
	li $t4, '!'
	beq $t2, $t4, normalizacja_nastepny_znak_wejsciowy 
	li $t4, '?'
	beq $t2, $t4, normalizacja_nastepny_znak_wejsciowy 
	# Inny, niedozwolony znak (nie jest cyfrą, wielką literą, małą literą ani znaną interpunkcją/spacją)
	li $t8, 1          # Ustaw flagę błędu
	# Kontynuuj pętlę, aby wczytać resztę linii, błąd zostanie sprawdzony na końcu
	# j normalizacja_nastepny_znak_wejsciowy # Przejdź dalej w pętli

normalizacja_nastepny_znak_wejsciowy:
	addi $s0, $s0, 1                  # Następny znak z tekst_wejsciowy_buf
	j normalizuj_konwertuj_waliduj_petla

normalizacja_limit_osiagniety_przewin_reszte_wejscia:
	# Osiągnięto limit 50 znaków w tekscie_znormalizowanym.
	# Zapisz flagę, że doszło do potencjalnego obcięcia, jeśli jeszcze nie ustawiona.
	li $s6, 1 # Używamy $s6 jako flagi obcięcia (wcześniej używany w pętli szyfrującej, ale tu jest bezpieczny)
przewin_wejscie_petla: # Przewijamy resztę bufora wejściowego
	lb $t2, 0($s0)
	beqz $t2, normalizacja_konwertowanie_zakonczone_stringiem_po_obcieciu
	beq $t2, '\n', normalizacja_konwertowanie_zakonczone_linia_po_obcieciu
	# Sprawdzamy, czy obcinane znaki byłyby błędne (np. małe litery)
	li $t4, 'a'
	blt $t2, $t4, dalej_przewijaj_bez_bledu_obcinania # nie jest małą literą
	li $t4, 'z'
	bgt $t2, $t4, dalej_przewijaj_bez_bledu_obcinania # nie jest małą literą
	li $t8, 1 # Jeśli obcinamy małą literę, to też jest błąd
dalej_przewijaj_bez_bledu_obcinania:
	addi $s0, $s0, 1
	j przewin_wejscie_petla
normalizacja_konwertowanie_zakonczone_stringiem_po_obcieciu:
    j normalizacja_konwertowanie_zakonczone_stringiem # Przejdź do standardowego zakończenia
normalizacja_konwertowanie_zakonczone_linia_po_obcieciu:
    j normalizacja_konwertowanie_zakonczone_linia # Przejdź do standardowego zakończenia

normalizacja_konwertowanie_zakonczone_linia:
	sb $zero, 0($s1) # Zakończ tekst_znormalizowany_buf znakiem '\0' ($s1 to aktualny wskaźnik zapisu)
	j normalizacja_konwertowanie_sprawdz_bledy_i_obciecie

normalizacja_konwertowanie_zakonczone_stringiem: 
	sb $zero, 0($s1) # Zakończ tekst_znormalizowany_buf znakiem '\0'

normalizacja_konwertowanie_sprawdz_bledy_i_obciecie:
	# $s4 zawiera długość tekstu_znormalizowanego_buf
	# $t8 zawiera flagę błędu (0 = OK, 1 = wykryto niedozwolony znak)
	# $s6 zawiera flagę potencjalnego obcięcia (1 = tak, 0 = nie)
	bne $t8, $zero, tekst_zawiera_bledy_przetwarzania_koncowego
	
	# Sprawdzenie komunikatu o obcięciu
	beqz $s6, przygotuj_klucz_do_szyfrowania_po_normalizacji # Jeśli $s6=0, nie było obcięcia z powodu limitu 50
	# Jeśli $s6=1, to znaczy, że $s4 osiągnęło 50 i były jeszcze znaki na wejściu.
	li $v0, 4
	la $a0, komunikat_obciecie_tekstu 
	syscall
	# Przejdź dalej
	j przygotuj_klucz_do_szyfrowania_po_normalizacji

tekst_zawiera_bledy_przetwarzania_koncowego:
	li $v0, 4
	la $a0, prompt_tekst_zawiera_niedozwolone_znaki
	syscall
	j wczytaj_i_przetworz_tekst_uzytkownika 

przygotuj_klucz_do_szyfrowania_po_normalizacji: 
	# $s4 zawiera teraz poprawną długość tekstu_znormalizowanego_buf
	# Sprawdzenie czy klucz nie jest dłuższy od tekstu
	blt $s4, $s3, dlugosc_klucza_przekracza_tekst # Jeśli dl_tekstu < dl_klucza, błąd
                                                # Użyłem blt, bo jeśli są równe, to jest OK.

	# Konwersja klucza na 0-indeksowane liczby całkowite
	la $t1, ciag_klucz_buf # t1 to nasza wartosc klucz    
	la $t2, permutacja_klucza # t2 to tablica wystepowan - juz niepotrzebna, wykorzystamy ja w innym celu
	li $t3, 0 # t3 to indeks
	li $t4, '1' # pomoc ascii                       
konwertuj_klucz_petla:
	bge $t3, $s3, konwersja_klucza_koniec # jesli dotarlismy do dlugosci - koniec 
	lb $t5, 0($t1) # ladujemy kolejny bajt klucza
	sub $t5, $t5, $t4 # bierzemy go jako int przesuniety o -1
	sb $t5, 0($t2) # i w ten sposob go zapisujemy! - latwiej bedzie nam z nim cos robic (w miejsce tablicy wystepowan, jej nie potrzebujemy a sie nada)
	
	addi $t1, $t1, 1 # } \      
	addi $t2, $t2, 1 # } - przesuniecia dalej w kluczach           
	addi $t3, $t3, 1 # indeks + 1
	j konwertuj_klucz_petla # petla
konwersja_klucza_koniec:
	j wykonaj_szyfrowanie_lub_deszyfrowanie # szyfrujemy/deszyfrujemy

dlugosc_klucza_przekracza_tekst:
	li $v0, 4
	la $a0, klucz_dluzszy_niz_tekst
	syscall
	j wczytaj_i_przetworz_tekst_uzytkownika

wykonaj_szyfrowanie_lub_deszyfrowanie: 
	la $s0, tekst_znormalizowany_buf # wczytujemy tekst
	la $s1, tekst_wynikowy_buf # wczytujemy wynik
	la $s2, permutacja_klucza # wczytujemy klucz z ktorym latwo nam bedzie pracowac - przekonwertowany na inty od 0 do dlugosci klucza - 1
	
	bgt $s3, $s4, dlugosc_klucza_przekracza_tekst
	# s3 - dlugosc klucza
	# s4 - dlugosc tekstu
	# s5 - tryb operacji 0 szyfr, 1 deszyfr
	li $s6, 0 # poczatek biezacego bloku tekstu
petla_blokow_szyfrujacych: 
	# przetworzono caly tekst v
	bge $s6, $s4, przetwarzanie_szyfrem_koniec #jesli dotarlismy na koniec tekstu to koniec
	li $s7, 0 # indeks w bloku
petla_wewnatrz_bloku_szyfrujacego: 
	bge $s7, $s3, nastepny_blok_szyfrujacy # jesli indeks jest wiekszy od dlugosci klucza, to wchodzimy na nastepny blok szyfrujacy
	add $t1, $s6, $s7 # do t1 bierzemy indeks slowa z calego tekstu
	bge $t1, $s4, nastepny_blok_szyfrujacy # warunek dla ostatniego bloku gdy niepelny - skaczemu do nastepnego bloku i konczymy szyfrowanie prawidlowo
	add $t2, $s2, $s7 # adres permutacji klucza dla tego indeksu w bloku
	lb $t3, 0($t2) # ladujemy obecna permutacje klucza
	beq $s5, $zero, sciezka_szyfrowania # jesli s5 = 0 to szyfr, inaczej deszyfr
sciezka_deszyfrowania:
	add $t4, $s0, $t1 # adres szyfrogramu - przesuniecie na obecne slowo   
	lb $t5, 0($t4) # ladujemy obecne slowo do t5
	add $t6, $s6, $t3 # docelowy wzgledny indeks w tekscie jawnym
	bgt $t6, $s4, deszyfrowanie_zapis_permutowany_poza_zakresem # jesli wypadamy z docelowym indeksem poza tekst
	add $t6, $s1, $t6 # adres wyniku - przesuwamy sie
	sb $t5, 0($t6) # zapisujemy slowo z szyfrogramu, odczytane juz prawidlowo do t5
	j inkrementuj_j_w_bloku_szyfrujacym 
deszyfrowanie_zapis_permutowany_poza_zakresem:
	# sciezka ratunkowa - zapisz tak jak "jest" - brak miejsca, koniec szyfru nic nie zrobimy
	add $t6, $s1, $t1    
	sb $t5, 0($t6)             
	j inkrementuj_j_w_bloku_szyfrujacym 
sciezka_szyfrowania:
	add $t4, $s6, $t3 # wzgledny indeks odczytu w tekscie    
	bgt $t4, $s4, szyfrowanie_odczyt_znaku_poza_zakresem # jesli wypadamy poza tekst
	add $t4, $s0, $t4 # faktyczny indeks
	lb $t5, 0($t4) # ladujemy szyfr do t5   
	j szyfrowanie_znak_zrodlowy_pobrany
szyfrowanie_odczyt_znaku_poza_zakresem:
	# sciezka ratunkowa - odczytujemy znak jak "jest", tzn. nie zmieniamy nic
	add $t4, $s0, $t1           
	lb $t5, 0($t4)              
szyfrowanie_znak_zrodlowy_pobrany:
	# zapisujemy t5 w swoje miejsce w wyniju
	add $t6, $s1, $t1 # t1 to indeks w tekscie calym aktualny
	sb $t5, 0($t6) # store byte
inkrementuj_j_w_bloku_szyfrujacym: 
	addi $s7, $s7, 1 # dodajemy indeks bloku + 1
	j petla_wewnatrz_bloku_szyfrujacego # petla
nastepny_blok_szyfrujacy: 
	add $s6, $s6, $s3 # przesuwamy poczatek bloku o dlugosc klucza
	j petla_blokow_szyfrujacych # petla
przetwarzanie_szyfrem_koniec: 
	li $v0, 4 # wyswietlamy wynik
	la $a0, tekst_wynikowy_buf
	syscall    
	li $v0, 4
	la $a0, znak_nowej_linii
	syscall    
	j koniec_programu # koniec programu

koniec_programu:
	li $v0, 4
	la $a0, czy_kontynuowac
	syscall
	li $v0, 12
	syscall
	move $t0, $v0
	li $t1, 't'
	beq $t0, $t1, start_programu
	li $t1, 'T'
	beq $t0, $t1, start_programu
	li $t1, 'n'
	beq $t0, $t1, koniec
	li $t1, 'N'
	beq $t0, $t1, koniec
	li $v0, 4
	la $a0, kontynuowac_zle
	syscall
	j koniec_programu # Wróć do pytania o kontynuację, jeśli zły input

koniec:
	# syscall 10 - koniec programu
	li $v0, 10
	syscall
