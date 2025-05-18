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
	permutacja_klucza: .space 8 
	tekst_wejsciowy_buf: .space 52 
	tekst_tymczasowy_po_usunieciu_spacji_buf: .space 51 
	komunikat_obciecie_tekstu: .asciiz "Uwaga: Tekst po normalizacji zostal obciety do 50 znakow.\n"
	tekst_znormalizowany_buf: .space 51  
	tekst_wynikowy_buf: .space 51  
	znak_nowej_linii: .asciiz "\n" 

.text
start_programu: 
	li $v0, 4
	la $a0, prompt_operacja
	syscall	
	li $v0, 12  
	syscall	
	move $s5, $v0 

	li $t1, 'd'
	beq $s5, $t1, ustaw_deszyfrowanie
	li $t1, 'D'
	beq $s5, $t1, ustaw_deszyfrowanie
	li $t1, 's'
	beq $s5, $t1, ustaw_szyfrowanie
	li $t1, 'S'
	beq $s5, $t1, ustaw_szyfrowanie
	
	li $v0, 4
	la $a0, prompt_operacja_blad
	syscall	
	j start_programu		
ustaw_szyfrowanie:
	li $s5, 0 
	j pobierz_dlugosc_klucza	
ustaw_deszyfrowanie:
	li $s5, 1 
	j pobierz_dlugosc_klucza		
pobierz_dlugosc_klucza:
	li $v0, 4
	la $a0, prompt_dlugosc_klucza
	syscall	
	li $v0, 5 
	syscall	
	move $s3, $v0    
	
	li $t2, 3
	blt $s3, $t2, dlugosc_klucza_niepoprawna
	li $t2, 8
	bgt $s3, $t2, dlugosc_klucza_niepoprawna
	j pobierz_wartosc_klucza
dlugosc_klucza_niepoprawna:
	li $v0, 4
	la $a0, prompt_dlugosc_klucza_blad
	syscall	
	j pobierz_dlugosc_klucza 
pobierz_wartosc_klucza:
	li $v0, 4
	la $a0, prompt_klucz_wartosc
	syscall
	la $a0, ciag_klucz_buf
	move $a1, $s3       
	addi $a1, $a1, 2    
	li $v0, 8           
	syscall	
	la $a0, ciag_klucz_buf
	jal normalizuj_i_zmierz_dlugosc_klucza 
	
	bne $s3, $v0, klucz_ma_zla_dlugosc_po_wczytaniu
	j sprawdz_zawartosc_klucza_wejscie	
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
	beq $t3, $zero, normalizuj_klucz_koniec 
	beq $t3, '\n', normalizuj_klucz_koniec_linii 
	bge $t2, $s3, normalizuj_klucz_za_dlugi_przed_terminatorem 
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
	beqz $v0, klucz_ma_niepoprawna_zawartosc 
	j wczytaj_i_przetworz_tekst_uzytkownika

sprawdz_zawartosc_klucza_podprogram: 
	la $t1, permutacja_klucza 
	li $t2, 0                  
inicjalizuj_pomocniczy_buf_klucza_petla:
	bge $t2, $s3, inicjalizacja_pomocniczego_buf_klucza_koniec 
	sb $zero, 0($t1)           
	addi $t1, $t1, 1
	addi $t2, $t2, 1
	j inicjalizuj_pomocniczy_buf_klucza_petla
inicjalizacja_pomocniczego_buf_klucza_koniec:
	la $t1, ciag_klucz_buf     
	li $t2, 0                  
	li $t4, '1'                
waliduj_cyfry_klucza_petla:
	bge $t2, $s3, walidacja_cyfr_klucza_poprawna 
	lb $t5, 0($t1)             
	sub $t5, $t5, $t4          
	bltz $t5, walidacja_cyfr_klucza_niepoprawna   
	bge $t5, $s3, walidacja_cyfr_klucza_niepoprawna 
	la $t6, permutacja_klucza
	add $t6, $t6, $t5          
	lb $t7, 0($t6)             
	bne $t7, $zero, walidacja_cyfr_klucza_niepoprawna 
	li $t7, 1                  
	sb $t7, 0($t6)
	addi $t2, $t2, 1           
	addi $t1, $t1, 1           
	j waliduj_cyfry_klucza_petla
walidacja_cyfr_klucza_poprawna:
	li $v0, 1                  
	jr $ra
walidacja_cyfr_klucza_niepoprawna:
	li $v0, 0                  
	jr $ra
klucz_ma_niepoprawna_zawartosc:
	li $v0, 4
	la $a0, prompt_klucz_wartosc_blad
	syscall	
	j pobierz_dlugosc_klucza 

wczytaj_i_przetworz_tekst_uzytkownika: 
	li $v0, 4
	la $a0, prompt_tekst_do_przetworzenia
	syscall	
	la $a0, tekst_wejsciowy_buf
	li $v0, 8 
	li $a1, 52 
	syscall	
	
	la $t1, tekst_wejsciowy_buf       		
	la $t2, tekst_tymczasowy_po_usunieciu_spacji_buf  
	li $t7, 0                         		
etap1_usun_spacje_interpunkcje_petla:
	lb $t3, 0($t1)                    		
	
	beq $t3, $zero, etap1_koniec_stringu_wejsciowego
	beq $t3, '\n', etap1_koniec_linii_wejsciowej

	li $t4, 'A'
	blt $t3, $t4, sprawdz_czy_mala_litera_etap1
	li $t4, 'Z'
	bgt $t3, $t4, sprawdz_czy_mala_litera_etap1
	j znak_do_zachowania_etap1 

sprawdz_czy_mala_litera_etap1:
	li $t4, 'a'
	blt $t3, $t4, sprawdz_czy_cyfra_etap1
	li $t4, 'z'
	bgt $t3, $t4, sprawdz_czy_cyfra_etap1
	j znak_do_zachowania_etap1 

sprawdz_czy_cyfra_etap1:
	li $t4, '0'
	blt $t3, $t4, pomin_znak_etap1 
	li $t4, '9'
	bgt $t3, $t4, pomin_znak_etap1 
	
znak_do_zachowania_etap1:
	bge $t7, 50, etap1_limit_osiagniety 
	sb $t3, 0($t2)                    
	addi $t2, $t2, 1                  
	addi $t7, $t7, 1                  

pomin_znak_etap1:
	addi $t1, $t1, 1                  
	j etap1_usun_spacje_interpunkcje_petla

etap1_limit_osiagniety: 
etap1_przewin_do_konca_wejscia:
	lb $t3, 0($t1)
	beqz $t3, etap1_koniec_stringu_wejsciowego
	beq $t3, '\n', etap1_koniec_linii_wejsciowej
	addi $t1, $t1, 1
	j etap1_przewin_do_konca_wejscia

etap1_koniec_linii_wejsciowej:
	sb $zero, 0($t2) 
	j etap2_walidacja_znakow

etap1_koniec_stringu_wejsciowego: 
	sb $zero, 0($t2) 

etap2_walidacja_znakow:
	la $t1, tekst_tymczasowy_po_usunieciu_spacji_buf 
	li $t8, 0					
	li $s4, 0					
	la $t2, tekst_znormalizowany_buf		
etap2_waliduj_petla:
	lb $t3, 0($t1)				
	beq $t3, $zero, etap2_walidacja_zakonczona

	li $t4, 'A'
	blt $t3, $t4, etap2_wykryto_niepoprawny_znak_lub_mala_lit_cyfre
	li $t4, 'Z'
	bgt $t3, $t4, etap2_wykryto_niepoprawny_znak_lub_mala_lit_cyfre
	
	sb $t3, 0($t2)				
	addi $t2, $t2, 1
	addi $s4, $s4, 1			
	
	addi $t1, $t1, 1			
	j etap2_waliduj_petla

etap2_wykryto_niepoprawny_znak_lub_mala_lit_cyfre:
	li $t8, 1				
	j etap2_walidacja_zakonczona 	

etap2_walidacja_zakonczona:
	sb $zero, 0($t2) 

	bne $t8, $zero, tekst_zawiera_bledy_normalizacji 
	
	li $t3, 50                        
	bne $s4, $t3, przygotuj_klucz_do_szyfrowania 
	la $t7, tekst_tymczasowy_po_usunieciu_spacji_buf # Sprawdzamy oryginalny, przefiltrowany tekst
	add $t7, $t7, 50      # Czy 51-szy znak w tymczasowym (po usunieciu spacji) istnial?
	lb $t6, 0($t7)        # Jesli tak, i bylby wielka litera, to znaczy ze obcieto >50 wielkich liter
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
	la $a0, prompt_tekst_zawiera_niedozwolone_znaki
	syscall
	j wczytaj_i_przetworz_tekst_uzytkownika 

przygotuj_klucz_do_szyfrowania: 
	la $t1, ciag_klucz_buf          
	la $t2, permutacja_klucza       
	li $t3, 0                       
	li $t4, '1'                     
konwertuj_klucz_petla:
	bge $t3, $s3, konwersja_klucza_koniec 
	lb $t5, 0($t1)                  
	sub $t5, $t5, $t4               
	sb $t5, 0($t2)                  
	
	addi $t1, $t1, 1                
	addi $t2, $t2, 1                
	addi $t3, $t3, 1                
	j konwertuj_klucz_petla
konwersja_klucza_koniec:
	j wykonaj_szyfrowanie_lub_deszyfrowanie

wykonaj_szyfrowanie_lub_deszyfrowanie: 
	la $s0, tekst_znormalizowany_buf
	la $s1, tekst_wynikowy_buf
	la $s2, permutacja_klucza
	    
	li $s6, 0              
petla_blokow_szyfrujacych: 
	bge $s6, $s4, przetwarzanie_szyfrem_koniec  
	li $s7, 0              
petla_wewnatrz_bloku_szyfrujacego: 
	bge $s7, $s3, nastepny_blok_szyfrujacy 
	add $t1, $s6, $s7           
	bge $t1, $s4, nastepny_blok_szyfrujacy 
	add $t2, $s2, $s7           
	lb $t3, 0($t2)             
	beq $s5, $zero, sciezka_szyfrowania 
sciezka_deszyfrowania:
	add $t4, $s0, $t1           
	lb $t5, 0($t4)             
	add $t6, $s6, $t3           
	bge $t6, $s4, deszyfrowanie_zapis_permutowany_poza_zakresem
	add $t6, $s1, $t6           
	sb $t5, 0($t6)             
	j inkrementuj_j_w_bloku_szyfrujacym 
deszyfrowanie_zapis_permutowany_poza_zakresem:
	add $t6, $s1, $t1           
	sb $t5, 0($t6)             
	j inkrementuj_j_w_bloku_szyfrujacym 
sciezka_szyfrowania:
	add $t4, $s6, $t3           
	bge $t4, $s4, szyfrowanie_odczyt_znaku_poza_zakresem 
	add $t4, $s0, $t4           
	lb $t5, 0($t4)             
	j szyfrowanie_znak_zrodlowy_pobrany
szyfrowanie_odczyt_znaku_poza_zakresem:
	add $t4, $s0, $t1           
	lb $t5, 0($t4)             
szyfrowanie_znak_zrodlowy_pobrany:
	add $t6, $s1, $t1           
	sb $t5, 0($t6)             
inkrementuj_j_w_bloku_szyfrujacym: 
	addi $s7, $s7, 1             
	j petla_wewnatrz_bloku_szyfrujacego
nastepny_blok_szyfrujacy: 
	add $s6, $s6, $s3           
	j petla_blokow_szyfrujacych
przetwarzanie_szyfrem_koniec: 
	add $t1, $s1, $s4           
	sb $zero, 0($t1)           
	li $v0, 4
	la $a0, tekst_wynikowy_buf
	syscall    
	li $v0, 4
	la $a0, znak_nowej_linii
	syscall    
	j koniec_programu
koniec_programu: 
	li $v0, 10 
	syscall