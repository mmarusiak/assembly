.data
	prompt_operacja: .asciiz "\nDeszyfrowac (D) czy szyfrowac (S)? [D/S]:\n"
	prompt_operacja_blad: .asciiz "\n Bledna operacja. Wybierz D lub S.\n"
	prompt_dlugosc_klucza: .asciiz "\nPodaj dlugosc klucza (liczba calkowita z zakresu 3-8):\n"
	ciag_klucz_buf: .space 9 
	prompt_dlugosc_klucza_blad: .asciiz "\nNiepoprawna dlugosc klucza. Dlugosc musi byc miedzy 3 a 8.\n"
	prompt_klucz_wartosc: .asciiz "\nPodaj klucz (cyfry od 1 do DlugoscKlucza, bez powtorzen, np. dla dlugosci 4: 2413):\n"
	prompt_klucz_dlugosc_niezgadza_sie: .asciiz "\nKlucz jest zbyt krotki lub zbyt dlugi! Wpisales inna liczbe cyfr niz zadeklarowana dlugosc klucza.\n"
	prompt_klucz_wartosc_blad: .asciiz "\nKlucz jest niepoprawny! Upewnij sie, ze cyfry sa z wlasciwego zakresu (1-DlugoscKlucza) i sie nie powtarzaja.\n"
	prompt_tekst_do_przetworzenia: .asciiz "\nPodaj tekst (po usunieciu spacji/interpunkcji musi skladac sie tylko z WIELKICH LITER A-Z, max 50 znakow):\n"
	prompt_tekst_zawiera_niedozwolone_znaki: .asciiz "\nBLAD: Tekst zawiera male litery, cyfry lub inne niedozwolone znaki (po usunieciu spacji/interpunkcji).\nWprowadz tekst jeszcze raz.\n"
	permutacja_klucza: .space 8 # dla kazdego mozliwego chara z zakresu maksymalnego spisujemy ile razy wystapil w kluczu
	tekst_wejsciowy_buf: .space 52 
	tekst_tymczasowy_po_usunieciu_spacji_buf: .space 51 
	komunikat_obciecie_tekstu: .asciiz "Uwaga: Tekst po normalizacji zostal obciety do 50 znakow.\n"
	tekst_znormalizowany_buf: .space 51  
	tekst_wynikowy_buf: .space 51  
	znak_nowej_linii: .asciiz "\n" 
	czy_kontynuowac: .asciiz "Czy kontynuowac? t/n:\n"
	kontynuowac_zle: .asciiz "\nBledna operacja. Wybierz t/n:\n"
	klucz_dluzszy_niz_tekst: .asciiz "\nKlucz dluzszy niz tekst... Nie da sie szyfrowac - wpisz tekst jeszcze raz\n"

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
	move $a1, $s3 # wrzucamy dlugosc klucza + 2 do a1, bo jeszcze \n jest wczytywane do ciagu
	addi $a1, $a1, 2    
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
	la $a0, prompt_tekst_do_przetworzenia # wczytaj tekst
	syscall	
	la $a0, tekst_wejsciowy_buf # surowy tekst wejsciowy
	li $v0, 8 
	li $a1, 52 
	syscall	
	
	la $t1, tekst_wejsciowy_buf # zapisujemy do t1
	la $t2, tekst_tymczasowy_po_usunieciu_spacji_buf # do t2 robimy miejsce na tymczasowy tekst, krotszy bez spacji, bedziemy sprawdzac dlugosc 
	li $t7, 0 # indeks petli
etap1_usun_spacje_interpunkcje_petla:
	lb $t3, 0($t1) # wczytaj kolejny bajt		
	
	beq $t3, $zero, etap1_koniec # jesli jest rowny 0 - koniec stringu wejsciowego
	beq $t3, '\n', etap1_koniec # jesli znalezlismy \n to koniec linii wejsciowej

	li $t4, 'A'
	blt $t3, $t4, sprawdz_czy_mala_litera_etap1 # jest mniejsze od 'A' oznacza mala litere potencjalnie
	li $t4, 'Z'
	bgt $t3, $t4, sprawdz_czy_mala_litera_etap1 # jest wieksze od 'Z' oznacza mala litere potencjalnie
	j znak_do_zachowania_etap1 # inaczej to potencjalnie dobry znak

sprawdz_czy_mala_litera_etap1:
	li $t4, 'a'
	blt $t3, $t4, sprawdz_czy_cyfra_etap1 # jesli jest mniejsze od 'a' to mozliwe ze to cyfra
	li $t4, 'z'
	bgt $t3, $t4, sprawdz_czy_cyfra_etap1 # jesli jest wieksze od 'z' to mozliwe ze to cyfra
	j znak_do_zachowania_etap1 # to w takim razie nie jest znak interpunkcyjny, nie pomijamy

sprawdz_czy_cyfra_etap1:
	li $t4, '0'
	blt $t3, $t4, pomin_znak_etap1 # jesli nie cyfra to pomijamy znak - traktujemy jako interpunkcja
	li $t4, '9'
	bgt $t3, $t4, pomin_znak_etap1 # to samo ^
	
znak_do_zachowania_etap1:
	bge $t7, 50, etap1_limit_osiagniety # jesli indeks = 50, oznacza to ze dotarlismy na koniec - etap1 konczymy
	sb $t3, 0($t2) # zapisujemy ten znak w t2       
	addi $t2, $t2, 1 # idziemy dalej w t2
	addi $t7, $t7, 1 # indesk o 1 zwiekszamy

pomin_znak_etap1:
	addi $t1, $t1, 1 # przesuwamy t1 dalej  
	j etap1_usun_spacje_interpunkcje_petla # usuwamy spacje i interpunkcje dalej - indeksu nie zwiekszamy, nie dodajemy nic na wyjscie, po prostu pomijamy i wracamy do petlu

etap1_limit_osiagniety: 
etap1_przewin_do_konca_wejscia:
	lb $t3, 0($t1) # ladujemy pozostale bajty dopoki nie dotrzemy do \n lub 0
	beqz $t3, etap1_koniec
	beq $t3, '\n', etap1_koniec
	addi $t1, $t1, 1 # idziemy dalej powtarzamy
	j etap1_przewin_do_konca_wejscia

etap1_koniec: 
	sb $zero, 0($t2) # konczymy rowniez nasz klucz wyjsciowy wpisujac 0 na koniec - informacja o koncu

etap2_walidacja_znakow:
	la $t1, tekst_tymczasowy_po_usunieciu_spacji_buf # wczytujemy prawie znormalizowany tekst do t1
	li $t8, 0 # wynik walidacji - 1 gdy wykryto maly znak lub cyfre, 0 gdy ok
	li $s4, 0 # indeks			
	la $t2, tekst_znormalizowany_buf # koncowa normalizacja tekstu - kolejne bajty/slowa koncowego tekstu	
etap2_waliduj_petla:
	lb $t3, 0($t1) # wczytujemy pierwsze slowo do sprawdzenia	
	beq $t3, $zero, etap2_walidacja_zakonczona # jesli to slowo to 0 - nasze oznaczenie na koniec - to zakonczylismy walidacje

	li $t4, 'A'
	blt $t3, $t4, etap2_wykryto_niepoprawny_znak_lub_mala_lit_cyfre # mniej od "A' oznacza cyfre lub liczbe - reszte wywalilismy
	li $t4, 'Z'
	bgt $t3, $t4, etap2_wykryto_niepoprawny_znak_lub_mala_lit_cyfre # wiecej od 'Z' oznacza cyfre lub liczbe - reszte wywalilismy
	
	sb $t3, 0($t2) # umieszczamy ten bajt u nas w nowym, znormalizowanym koncowo tekscie		
	addi $t2, $t2, 1 # przesuwamy sie
	addi $s4, $s4, 1 # indeks + 1	
	
	addi $t1, $t1, 1 # przesuwamy sie rowniez po tekscie pierwotnym, znormalizowanym nie do konca		
	j etap2_waliduj_petla # petla dalej

etap2_wykryto_niepoprawny_znak_lub_mala_lit_cyfre:
	li $t8, 1 # w tekscie maja byc tylko duze litery - zly tekst!		
	j etap2_walidacja_zakonczona # koniec walidacji	

etap2_walidacja_zakonczona:
	sb $zero, 0($t2) # konczymy nasz nowy klucz rowniez zerem, maksymalnie znormalizowany

	bne $t8, $zero, tekst_zawiera_bledy_normalizacji # jesli status != 0 oznacza to ze ma cyfre lub male litery
	
	li $t3, 50 # 50 to dlugosc maksymalna klucza
	bne $s4, $t3, przygotuj_klucz_do_szyfrowania # jesli nie jest tyle rowny indeks - spokojnie mozemy kontynuowac program, nie zapchamy bufora
	la $t7, tekst_tymczasowy_po_usunieciu_spacji_buf # Sprawdzamy oryginalny, przefiltrowany tekst
	add $t7, $t7, 50 # Czy 51-szy znak w tymczasowym (po usunieciu spacji) istnial?
	lb $t6, 0($t7) # Jesli tak, i bylby wielka litera, to znaczy ze obcieto >50 wielkich liter
	beqz $t6, przygotuj_klucz_do_szyfrowania 
    
	# Sprawdzamy czy ten 51szy znak bylby wielka litera (bo tylko takie nas interesuja)
	li $t4, 'A'
	blt $t6, $t4, przygotuj_klucz_do_szyfrowania 
	li $t4, 'Z'
	bgt $t6, $t4, przygotuj_klucz_do_szyfrowania 
    # Jesli tak, to faktycznie obcieto wiecej niz 50 wielkich liter
	li $v0, 4
	la $a0, komunikat_obciecie_tekstu 
	syscall
	# Przejdz dalej normalnie
	j przygotuj_klucz_do_szyfrowania

tekst_zawiera_bledy_normalizacji:
	li $v0, 4
	la $a0, prompt_tekst_zawiera_niedozwolone_znaki # info o bledach
	syscall
	j wczytaj_i_przetworz_tekst_uzytkownika # proba jeszcze raz

przygotuj_klucz_do_szyfrowania: 
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

dlugosc_klucza_tekst:
	li $v0, 4
	la $a0, klucz_dluzszy_niz_tekst
	syscall
	j wczytaj_i_przetworz_tekst_uzytkownika

wykonaj_szyfrowanie_lub_deszyfrowanie: 
	la $s0, tekst_znormalizowany_buf # wczytujemy tekst
	la $s1, tekst_wynikowy_buf # wczytujemy wynik
	la $s2, permutacja_klucza # wczytujemy klucz z ktorym latwo nam bedzie pracowac - przekonwertowany na inty od 0 do dlugosci klucza - 1
	
	bgt $s3, $s4, dlugosc_klucza_tekst
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
	bgt $t1, $s4, nastepny_blok_szyfrujacy # warunek dla ostatniego bloku gdy niepelny - skaczemu do nastepnego bloku i konczymy szyfrowanie prawidlowo
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
	bge $t4, $s4, szyfrowanie_odczyt_znaku_poza_zakresem # jesli wypadamy poza tekst
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
	j koniec_programu
koniec:
