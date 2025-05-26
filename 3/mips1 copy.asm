.data:
	# Komunikaty systemowe
	nowa_linia: .asciiz "\n"
	zapytanie_o_liczbe_instrukcji: .asciiz "\nPodaj liczbe instrukcji (1-5): \n"
	blad_liczby_instrukcji: .asciiz "\nLiczba instrukcji nie zgadza sie. Wprowadz jeszcze raz! \n"
	zapytanie_o_instrukcje: .asciiz "\nPodaj instrukcje: (Mozliwe instrukcje to: ADD, ADDI, J, NOOP, MULT, JR, JAL, SUB) \n"
	blad_instrukcji: .asciiz "\nNieprawidlowo wprowadzona instrukcja - sprobuj ponownie. \n"
	komunikat_pamieci: .asciiz "\nIlosc pamieci zaalokowanej na stosie: \n"
	linia_oddzielajaca: .asciiz "--------------------------------------------"
	zapytanie_kontynuacji: .asciiz "Czy kontynuowac? T/N: "
	
	# Dostępne instrukcje MIPS
	instrukcja_add: .asciiz "ADD"
	instrukcja_addi: .asciiz "ADDI"
	instrukcja_j: .asciiz "J"
	instrukcja_noop: .asciiz "NOOP"
	instrukcja_mult: .asciiz "MULT"
	instrukcja_jr: .asciiz "JR"
	instrukcja_jal: .asciiz "JAL"
	instrukcja_sub: .asciiz "SUB"
	
	# Bufor na wprowadzane dane
	bufor_wejsciowy: .space 51

.text:
	# Rejestry używane w programie:
	# $s0 - pozostała liczba instrukcji do wczytania
	# $s1 - całkowita liczba instrukcji na stosie (nieużywany w oryginalnym kodzie)
	# $s2 - liczba słów w aktualnie przetwarzanej instrukcji
	# $s3 - tablica wskaźników do słów aktualnej instrukcji
	# $s4 - adres pierwszego słowa instrukcji
	# $s5 - ilość pamięci zaalokowanej na stosie
	
	main:
		# Inicjalizacja głównych zmiennych programu
		li $s0, 0
		li $s1, 0
		li $s2, 0
		li $s3, 0
		li $s4, 0
		li $s5, 0					# Wyzerowanie licznika pamięci na stosie
		
	pobierz_liczbe_instrukcji:
		# Wyświetlenie zapytania o liczbę instrukcji
		li $v0, 4
		la $a0, zapytanie_o_liczbe_instrukcji
		syscall
		
		# Wczytanie liczby instrukcji od użytkownika
		li $v0, 5
		syscall
		
		# Sprawdzenie czy liczba mieści się w przedziale [1, 5]
		blez $v0, bledna_liczba_instrukcji		# Jeśli <= 0, to błąd
		bgt $v0, 5, bledna_liczba_instrukcji		# Jeśli > 5, to błąd
		j zakoncz_pobieranie_liczby			# Liczba poprawna, kontynuuj
		
	bledna_liczba_instrukcji:
		# Wyświetlenie komunikatu o błędzie
		li $v0, 4
		la $a0, blad_liczby_instrukcji
		syscall
		j pobierz_liczbe_instrukcji			# Ponowne zapytanie o liczbę
		
	zakoncz_pobieranie_liczby:
		# Zapisanie liczby instrukcji do rejestru $s0
		move $s0, $v0
	
	pobierz_instrukcje:
		# Wyświetlenie zapytania o instrukcję
		li $v0, 4
		la $a0, zapytanie_o_instrukcje
		syscall
	
		# Alokacja pamięci na bufor dla wprowadzonej instrukcji
		li $v0, 9
		li $a0, 51
		syscall
		move $t0, $v0
	
		# Wczytanie instrukcji od użytkownika
		li $v0, 8
		move $a0, $t0
		li $a1, 51
		syscall
		
		# Podział wprowadzonego tekstu na słowa
		move $a0, $t0
		jal podziel_tekst_na_slowa
		move $s2, $v0					# Liczba słów
		move $s3, $v1					# Tablica wskaźników do słów
		
		j przetwarzaj_instrukcje

	przetwarzaj_instrukcje:
		# Sprawdzenie czy instrukcja ma przynajmniej jedno słowo
		blez $s2, nieprawidlowa_instrukcja
		
		# Pobranie pierwszego słowa (nazwy instrukcji)
		lw $s4, ($s3)
		
		# Sprawdzenie czy instrukcja to ADD
		move $a0, $s4
		la $a1, instrukcja_add
		jal porownaj_teksty
		beq $v0, 1, obsluz_add
		
		# Sprawdzenie czy instrukcja to ADDI
		move $a0, $s4
		la $a1, instrukcja_addi
		jal porownaj_teksty
		beq $v0, 1, obsluz_addi
		
		# Sprawdzenie czy instrukcja to J
		move $a0, $s4
		la $a1, instrukcja_j
		jal porownaj_teksty
		beq $v0, 1, obsluz_j
		
		# Sprawdzenie czy instrukcja to NOOP
		move $a0, $s4
		la $a1, instrukcja_noop
		jal porownaj_teksty
		beq $v0, 1, obsluz_noop
		
		# Sprawdzenie czy instrukcja to MULT
		move $a0, $s4
		la $a1, instrukcja_mult
		jal porownaj_teksty
		beq $v0, 1, obsluz_mult
		
		# Sprawdzenie czy instrukcja to JR
		move $a0, $s4
		la $a1, instrukcja_jr
		jal porownaj_teksty
		beq $v0, 1, obsluz_jr
		
		# Sprawdzenie czy instrukcja to JAL
		move $a0, $s4
		la $a1, instrukcja_jal
		jal porownaj_teksty
		beq $v0, 1, obsluz_jal
		
		# dla nowej instrukcji - SUB
		move $a0, $s4
		la $a1, instrukcja_sub
		jal porownaj_teksty
		beq $v0, 1, obsluz_add # tyle samo argumentow co dla add 
		
		# Jeśli żadna z instrukcji nie pasuje
		j nieprawidlowa_instrukcja
		
	nieprawidlowa_instrukcja:
		# Wyświetlenie komunikatu o błędnej instrukcji
		li $v0, 4
		la $a0, blad_instrukcji
		syscall
		j pobierz_instrukcje				# Ponowne zapytanie o instrukcję
		
	umiesc_instrukcje_na_stosie:
		# Obliczenie indeksu ostatniego elementu tablicy
		addi $t0, $s2, -1				# $t0 = liczba_słów - 1
		mul $t0, $t0, 4					# Przemnożenie przez 4 (rozmiar wskaźnika)
		add $t0, $t0, $s3				# Dodanie adresu tablicy
		
		# Aktualizacja licznika pamięci na stosie
		add $s5, $s5, $s2
		
		# Inicjalizacja licznika dla pętli
		move $t2, $s2
		move $t9, $zero
		
		petla_umieszczania_instrukcji:
			# Sprawdzenie czy wszystkie słowa zostały umieszczone
			blez $t2, pobierz_kolejna_instrukcje
			
			# Pobranie adresu słowa i umieszczenie na stosie
			lw $t1, ($t0)				# Pobranie adresu słowa
			addi $sp, $sp, -4			# Zmniejszenie wskaźnika stosu
			sw $t1, ($sp)				# Umieszczenie adresu na stosie
		
			# Przejście do poprzedniego słowa
			addi $t2, $t2, -1			# Zmniejszenie licznika
			addi $t0, $t0, -4			# Przejście do poprzedniego wskaźnika
			j petla_umieszczania_instrukcji
			
		
	pobierz_kolejna_instrukcje:
		# Zmniejszenie licznika pozostałych instrukcji
		addi $s0, $s0, -1
		
		# Sprawdzenie czy wszystkie instrukcje zostały wprowadzone
		beqz $s0, zakoncz_program
		j pobierz_instrukcje
		
	zakoncz_program:
		# Przygotowanie do wyświetlenia zawartości stosu
		move $t0, $s5					# Liczba elementów do wyświetlenia
		
		# Obliczenie i wyświetlenie ilości zaalokowanej pamięci
		mul $t1, $t0, 4					# Pamięć w bajtach
		li $v0, 4
		la $a0, komunikat_pamieci
		syscall
		li $v0, 1
		move $a0, $t1
		syscall
		li $v0, 4
		la $a0, nowa_linia
		syscall
		
		wyswietl_stos:
			# Sprawdzenie czy stos jest pusty
			beqz $t0, zapytaj_o_kontynuacje
		
			# Wyświetlenie elementu ze stosu
			lw $a0, ($sp)
			li $v0, 4
			syscall
			
			# Wyświetlenie nowej linii
			la $a0, nowa_linia
			li $v0, 4
			syscall
			
			# Przejście do następnego elementu
			addi $sp, $sp, 4
			addi $t0, $t0, -1
			j wyswietl_stos
	
	zapytaj_o_kontynuacje:
		# Wyświetlenie zapytania o kontynuację
		li $v0, 4
		la $a0, zapytanie_kontynuacji
		syscall
		
		# Wczytanie odpowiedzi
		li $v0, 12 # read char
		syscall
		
		# Sprawdzenie odpowiedzi - czy to 'T'
		li $a0, 84
		beq $v0, $a0, main # Jesli 'T', restart programu
		
		li $a0, 116
		beq $v0, $a0, main # Jesli 't', restart programu
		
		# Sprawdzenie odpowiedzi - czy to 'T'
		li $a0, 78
		beq $v0, $a0, wyjscie # Jesli 'N', wyjscie
		
		li $a0, 110
		beq $v0, $a0, wyjscie # Jesli 'n', wyjscie
		
		
		# Jeśli nieprawidłowa odpowiedź, zapytaj ponownie
		j zapytaj_o_kontynuacje
		
	wyjscie:
		# Zakończenie programu
		li $v0, 10
		syscall
		
	# ========== OBSŁUGA POSZCZEGÓLNYCH INSTRUKCJI ==========
	
	obsluz_add:
		# Instrukcja ADD wymaga dokładnie 4 słów: ADD rd, rs, rt
		bne $s2, 4, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy drugi argument to rejestr
		lw $a0, 4($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy trzeci argument to rejestr
		lw $a0, 8($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy czwarty argument to rejestr
		lw $a0, 12($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Instrukcja poprawna - umiesc na stosie
		j umiesc_instrukcje_na_stosie
		
	obsluz_addi:
		# Instrukcja ADDI wymaga dokładnie 4 słów: ADDI rt, rs, immediate
		bne $s2, 4, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy drugi argument to rejestr
		lw $a0, 4($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy trzeci argument to rejestr
		lw $a0, 8($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy czwarty argument to wartość natychmiastowa
		lw $a0, 12($s3)
		jal czy_wartosc_natychmiastowa
		beqz $v0, nieprawidlowa_instrukcja
		
		# Instrukcja poprawna - umiesc na stosie
		j umiesc_instrukcje_na_stosie
		
	obsluz_j:
		# Instrukcja J wymaga dokładnie 2 słów: J label
		bne $s2, 2, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy drugi argument to etykieta
		lw $a0, 4($s3)
		jal czy_etykieta
		beqz $v0, nieprawidlowa_instrukcja
		
		# Instrukcja poprawna - umiesc na stosie
		j umiesc_instrukcje_na_stosie
		
	obsluz_noop:
		# Instrukcja NOOP wymaga dokładnie 1 słowa: NOOP
		bne $s2, 1, nieprawidlowa_instrukcja
		
		# Instrukcja poprawna - umiesc na stosie
		j umiesc_instrukcje_na_stosie
		
	obsluz_mult:
		# Instrukcja MULT wymaga dokładnie 3 słów: MULT rs, rt
		bne $s2, 3, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy drugi argument to rejestr
		lw $a0, 4($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy trzeci argument to rejestr
		lw $a0, 8($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Instrukcja poprawna - umiesc na stosie
		j umiesc_instrukcje_na_stosie
		
	obsluz_jr:
		# Instrukcja JR wymaga dokładnie 2 słów: JR rs
		bne $s2, 2, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy drugi argument to rejestr
		lw $a0, 4($s3)
		jal czy_rejestr
		beqz $v0, nieprawidlowa_instrukcja
		
		# Instrukcja poprawna - umiesc na stosie
		j umiesc_instrukcje_na_stosie
		
	obsluz_jal:
		# Instrukcja JAL wymaga dokładnie 2 słów: JAL label
		bne $s2, 2, nieprawidlowa_instrukcja
		
		# Sprawdzenie czy drugi argument to etykieta
		lw $a0, 4($s3)
		jal czy_etykieta
		beqz $v0, nieprawidlowa_instrukcja
		
		# Instrukcja poprawna - umiesc na stosie
		j umiesc_instrukcje_na_stosie
		
	# ========== FUNKCJE POMOCNICZE ==========
	
	porownaj_teksty:
		# Funkcja porównująca dwa teksty zakończone znakiem null
		# Argumenty: $a0 - adres pierwszego tekstu, $a1 - adres drugiego tekstu
		# Zwraca: $v0 - 1 jeśli teksty są identyczne, 0 w przeciwnym przypadku
		
		sprawdz_znak:
			# Inicjalizacja zmiennych tymczasowych
		 	li $t0, 0
		 	li $t1, 0
		 	
		 	# Pobranie znaków z obu tekstów
			lb $t0, ($a0)
			lb $t1, ($a1)
			
			# Sprawdzenie czy znaki są różne
			bne $t0, $t1, zwroc_rozne_teksty
			
			# Sprawdzenie czy dotarliśmy do końca tekstów
			beq $t0, 0, zwroc_identyczne_teksty
			
			# Przejście do następnych znaków
			addi $a0, $a0, 1
			addi $a1, $a1, 1
			j sprawdz_znak
			
		zwroc_rozne_teksty:
			# Teksty są różne
			li $v0, 0
			jr $ra
			
		zwroc_identyczne_teksty:
			# Teksty są identyczne
			li $v0, 1
			jr $ra
		
	czy_wartosc_natychmiastowa:
		# Funkcja sprawdzająca czy tekst reprezentuje wartość natychmiastową (liczbę)
		# Argument: $a0 - adres tekstu zakończonego znakiem null
		# Zwraca: $v0 - 1 jeśli to liczba, 0 w przeciwnym przypadku
		
		# Zapisanie adresu powrotu na stos
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		# Pobranie pierwszego znaku
		lb $t0, ($a0)
		
		sprawdz_znak_minus:
			# Sprawdzenie czy pierwszy znak to minus
			bne $t0, 45, sprawdz_znak_plus
			addi $a0, $a0, 1			# Pomiń znak minus
		
		sprawdz_znak_plus:
			# Sprawdzenie czy pierwszy znak to plus
			bne $t0, 43, sprawdz_czy_cyfra
			addi $a0, $a0, 1			# Pomiń znak plus
		
		sprawdz_czy_cyfra:
			# Pobranie aktualnego znaku
			lb $t0, ($a0)
			
			# Sprawdzenie czy dotarliśmy do końca tekstu
			beqz $t0, zwroc_jest_liczba
			
			# Sprawdzenie czy znak jest cyfrą (ASCII 48-57)
			blt $t0, 48, zwroc_nie_jest_liczba	# Jeśli < '0'
			bgt $t0, 57, zwroc_nie_jest_liczba	# Jeśli > '9'
			
			# Przejście do następnego znaku
			addi $a0, $a0, 1
			j sprawdz_czy_cyfra
			
		zwroc_jest_liczba:
			# Przywrócenie adresu powrotu
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 1
			jr $t0
			
		zwroc_nie_jest_liczba:
			# Przywrócenie adresu powrotu
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 0
			jr $t0
		
	czy_etykieta:
		# Funkcja sprawdzająca czy tekst reprezentuje poprawną etykietę
		# Argument: $a0 - adres tekstu zakończonego znakiem null
		# Zwraca: $v0 - 1 jeśli to etykieta, 0 w przeciwnym przypadku
		
		# Zapisanie adresu powrotu na stos
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		sprawdz_czy_litera:
			# Pobranie aktualnego znaku
			lb $t0, ($a0)
			
			# Sprawdzenie czy dotarliśmy do końca tekstu
			beqz $t0, zwroc_jest_etykieta
			
			# Sprawdzenie czy znak jest wielką literą (A-Z, ASCII 65-90)
			sge $t1, $t0, 65			# $t1 = 1 jeśli >= 'A'
			sle $t2, $t0, 90			# $t2 = 1 jeśli <= 'Z'
			
			# Sprawdzenie czy znak jest małą literą (a-z, ASCII 97-122)
			sge $t3, $t0, 97			# $t3 = 1 jeśli >= 'a'
			sle $t4, $t0, 122			# $t4 = 1 jeśli <= 'z'
			
			# Sprawdzenie czy znak należy do przedziału A-Z
			and $t1, $t1, $t2
			
			# Sprawdzenie czy znak należy do przedziału a-z
			and $t3, $t3, $t4
			
			# Sprawdzenie czy znak jest literą (A-Z lub a-z)
			or $t1, $t1, $t3
			beqz $t1, zwroc_nie_jest_etykieta
			
			# Przejście do następnego znaku
			addi $a0, $a0, 1
			j sprawdz_czy_litera
			
		zwroc_jest_etykieta:
			# Przywrócenie adresu powrotu
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 1
			jr $t0
			
		zwroc_nie_jest_etykieta:
			# Przywrócenie adresu powrotu
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 0
			jr $t0
		
	czy_rejestr:
		# Funkcja sprawdzająca czy tekst reprezentuje poprawny rejestr MIPS
		# Argument: $a0 - adres tekstu zakończonego znakiem null
		# Zwraca: $v0 - 1 jeśli to rejestr, 0 w przeciwnym przypadku
		# Format rejestru: $X lub $XX gdzie X to cyfry, zakres $0-$31
		
		# Zapisanie adresu powrotu na stos
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		# Pobranie pierwszych czterech znaków
		lb $t0, 0($a0)					# Pierwszy znak (powinien być '$')
		lb $t1, 1($a0)					# Drugi znak (pierwsza cyfra)
		lb $t2, 2($a0)					# Trzeci znak (druga cyfra lub null)
		lb $t3, 3($a0)					# Czwarty znak (powinien być null)
		
		# Sprawdzenie czy pierwszy znak to '$'
		bne $t0, 36, zwroc_nie_jest_rejestrem
		
		# Sprawdzenie czy to rejestr jednocyfrowy czy dwucyfrowy
		beqz $t2, sprawdz_rejestr_jednocyfrowy
		beqz $t3, sprawdz_rejestr_dwucyfrowy
		j zwroc_nie_jest_rejestrem
		
		sprawdz_rejestr_dwucyfrowy:
			# Sprawdzenie pierwszej cyfry (1-3)
			blt $t1, 49, zwroc_nie_jest_rejestrem	# Jeśli < '1'
			bgt $t1, 51, zwroc_nie_jest_rejestrem	# Jeśli > '3'
			
			# Sprawdzenie drugiej cyfry (0-9)
			blt $t2, 48, zwroc_nie_jest_rejestrem	# Jeśli < '0'
			bgt $t2, 57, zwroc_nie_jest_rejestrem	# Jeśli > '9'
			
			# Jeśli pierwsza cyfra to '3', druga może być tylko '0' lub '1'
			bne $t1, 51, zwroc_jest_rejestrem	# Pierwsza cyfra < 3, rejestr poprawny
			bgt $t2, 49, zwroc_nie_jest_rejestrem	# Liczba > 31
			j zwroc_jest_rejestrem
		
		sprawdz_rejestr_jednocyfrowy:
			# Sprawdzenie czy druga pozycja to cyfra (0-9)
			blt $t1, 48, zwroc_nie_jest_rejestrem	# Jeśli < '0'
			bgt $t1, 57, zwroc_nie_jest_rejestrem	# Jeśli > '9'
			j zwroc_jest_rejestrem
		
		zwroc_jest_rejestrem:
			# Przywrócenie adresu powrotu
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 1
			jr $t0
			
		zwroc_nie_jest_rejestrem:
			# Przywrócenie adresu powrotu
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 0
			jr $t0
		
	podziel_tekst_na_slowa:
		# Funkcja dzieląca pojedynczy tekst na tablicę słów zakończonych null
		# Argument: $a0 - adres tekstu zakończonego znakiem null
		# Zwraca: $v0 - liczba słów, $v1 - tablica wskaźników do słów
		
		# Zapisanie adresu powrotu na stos
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		# Inicjalizacja zmiennych
		move $t0, $a0					# Adres aktualnego znaku
		li $t1, 0					# Flaga: czy ostatni znak był częścią słowa
		li $t2, 0					# Liczba słów
		li $t3, 32					# Symulacja białego znaku na początku
		move $t7, $a0					# Oryginalny adres tekstu
		
		policz_slowa:
			# Pobranie aktualnego znaku
			lb $t3, ($t0)
			
			# Sprawdzenie czy dotarliśmy do końca tekstu
			beqz $t3, stos_do_tablicy
			
			# Sprawdzenie czy znak to biały znak (spacja, nowa linia, przecinek)
			seq $t4, $t3, 32			# $t4 = 1 jeśli spacja
			seq $t5, $t3, 10			# $t5 = 1 jeśli nowa linia
			or $t4, $t4, $t5
			seq $t5, $t3, 44			# $t5 = 1 jeśli przecinek
			or $t4, $t4, $t5
			
			# Jeśli to biały znak
			seq $t5, $t4, 0				# $t5 = 1 jeśli to nie biały znak
			and $t1, $t5, $t1			# Ustaw flagę słowa na 0
			mul $t3, $t3, $t5			# Wyzeruj znak jeśli to biały znak
			sb $t3, ($t0)				# Zapisz zmodyfikowany znak
			add $t0, $t0, $t4			# Zwiększ adres o 1 jeśli biały znak
			beq $t4, 1, policz_slowa		# Jeśli biały znak, kontynuuj pętlę
			
			# Znak nie jest białym znakiem
			seq $t5, $t1, 0				# $t5 = 1 jeśli ostatni znak był białym znakiem
		
			# Jeśli zaczynamy nowe słowo
			beqz $t5, pomin_stos
			add $t2, $t2, 1				# Zwiększ licznik słów
			addi $sp, $sp, -4			# umiesc wskaźnik na stos
			sw $t0, ($sp)
			
			pomin_stos:
			addi $t0, $t0, 1			# Przejdź do następnego znaku
			li $t1, 1				# Ustaw flagę słowa
			j policz_slowa
		
		stos_do_tablicy:
			# Alokacja pamięci na tablicę wskaźników
			li $v0, 9
			mul $a0, $t2, 4				# Rozmiar tablicy = liczba_słów * 4
			syscall
				
			# Przygotowanie zmiennych dla kopiowania ze stosu
			move $t0, $v0				# Adres początku tablicy
			move $v0, $t2				# Liczba słów (wynik funkcji)
			move $v1, $t0				# Adres tablicy (wynik funkcji)
			
			# Obliczenie adresu końca tablicy
			mul $t1, $t2, 4
			add $t1, $t1, $t0
			addi $t1, $t1, -4			# Wskaźnik na ostatni element tablicy
			
			petla_stos_do_tablicy:
				# Sprawdzenie czy wszystkie słowa zostały skopiowane
				beqz $t2, powrot_z_funkcji
				
				# Kopiowanie wskaźnika ze stosu do tablicy
				lw $t4, ($sp)			# Pobranie wskaźnika ze stosu
				sw $t4, ($t1)			# Umieszczenie w tablicy
				
				# Przejście do poprzedniego elementu
				addi $t1, $t1, -4		# Poprzedni element tablicy
				addi $sp, $sp, 4		# Usunięcie elementu ze stosu
				addi $t2, $t2, -1		# Zmniejszenie licznika
				j petla_stos_do_tablicy
		
		powrot_z_funkcji:
			# Przywrócenie adresu powrotu i powrót
			lw $ra, 0($sp)
        	addi $sp, $sp, 4
        	jr $ra
