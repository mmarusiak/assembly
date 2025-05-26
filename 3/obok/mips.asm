.data:
	nowaLinia: .asciiz "\n"
	
	zapytanieOLiczbeInstrukcji: .asciiz "\nPodaj liczbe instrukcji (1-5): \n"
	komunikatBlednejLiczbyInstrukcji: .asciiz "\nNieprawidlowa liczba instrukcji. \n"
	zapytanieOInstrukcje: .asciiz "\nPodaj instrukcje: \n"
	komunikatBlednejInstrukcji: .asciiz "\nNieprawidlowa instrukcja \n"
	komunikatAlokacjiPamieci: .asciiz "\nPamiec zaalokowana na stosie: \n"
	separatorLinii: .asciiz "________________________________"
	
	tekstKoniec: .asciiz "AppFinished"
	zapytanieKontynuacji: .asciiz "Czy kontynuowac? T/N: "
	
	instrukcjaAdd: .asciiz "ADD"
	instrukcjaAddi: .asciiz "ADDI"
	instrukcjaJ: .asciiz "J"
	instrukcjaNoop: .asciiz "NOOP"
	instrukcjaMult: .asciiz "MULT"
	instrukcjaJr: .asciiz "JR"
	instrukcjaJal: .asciiz "JAL"
	instrukcjaModyfikacji: .asciiz "MOVE"
	
	buforWejsciowy: .space 51
	odpowiedzUzytkownika: .space 3

.text:
	# Rejestry s0-s5 przechowuja stan programu:
	# s0 - pozostalaLiczbaInstrukcji (ile jeszcze instrukcji do wczytania)
	# s1 - calkowitaLiczbaInstrukcjiNaStosie (laczna liczba elementow na stosie)
	# s2 - liczbaElementowBiezacejInstrukcji (ile slow ma aktualna instrukcja)
	# s3 - adresTabeliStringowBiezacejInstrukcji (wskaznik do tablicy slow instrukcji)
	# s4 - adresPierwszegoSlowaInstrukcji (adres nazwy instrukcji)
	# s5 - pamiecZaalokowanaNaStosie (ile bajtow zaalokowano na stosie)
	
	glownyProgram:
		# Rozpoczynamy program od zapetlenia glownej logiki
		petlaGlownaProgram:
		
		pobierzLiczbeInstrukcji:
			# Wyswietlamy zapytanie o liczbe instrukcji
			li $v0, 4
			la $a0, zapytanieOLiczbeInstrukcji
			syscall
			
			# Wczytujemy liczbe calkowita od uzytkownika
			li $v0, 5
			syscall
			
			# Sprawdzamy czy liczba jest w przedziale 1-5
			blez $v0, nieprawidlowaLiczbaInstrukcji
			bgt $v0, 5, nieprawidlowaLiczbaInstrukcji
			j zakonczPobieranieInstrukcji
			
			nieprawidlowaLiczbaInstrukcji:
			# Wyswietlamy komunikat o bledzie
			li $v0, 4
			la $a0, komunikatBlednejLiczbyInstrukcji
			syscall
			# Wracamy do pobierania liczby instrukcji
			j pobierzLiczbeInstrukcji
			
			zakonczPobieranieInstrukcji:
			# Zapisujemy liczbe instrukcji do rejestru s0
			move $s0, $v0
		
		pobierzInstrukcje:
			# Wyswietlamy zapytanie o instrukcje
			li $v0, 4
			la $a0, zapytanieOInstrukcje
			syscall
		
			# Alokujemy pamiec na string (51 bajtow)
			li $v0, 9
			li $a0, 51
			syscall
			move $t0, $v0
		
			# Wczytujemy string od uzytkownika
			li $v0, 8
			move $a0, $t0
			li $a1, 51
			syscall
			
			# Rozdzielamy string na poszczegolne elementy
			move $a0, $t0
			jal podzielString
			move $s2, $v0  # liczba elementow
			move $s3, $v1  # tablica wskaznikow do elementow
			
			# Przechodzimy do przetwarzania instrukcji
			j przetworzInstrukcje
		
	przetworzInstrukcje:
		# Sprawdzamy czy instrukcja ma jakies elementy
		blez $s2, nieprawidlowaInstrukcja
		# Pobieramy pierwszy element (nazwe instrukcji)
		lw $s4, ($s3)
		
		# Porownujemy z dostepnymi instrukcjami i wywolujemy odpowiednia obsluge
		move $a0, $s4
		la $a1, instrukcjaAdd
		jal porownajTekst
		beq $v0, 1, obsluzAdd
		
		move $a0, $s4
		la $a1, instrukcjaAddi
		jal porownajTekst
		beq $v0, 1, obsluzAddI
		
		move $a0, $s4
		la $a1, instrukcjaJ
		jal porownajTekst
		beq $v0, 1, obsluzJ
		
		move $a0, $s4
		la $a1, instrukcjaNoop
		jal porownajTekst
		beq $v0, 1, obsluzNOOP
		
		move $a0, $s4
		la $a1, instrukcjaMult
		jal porownajTekst
		beq $v0, 1, obsluzMult
		
		move $a0, $s4
		la $a1, instrukcjaJr
		jal porownajTekst
		beq $v0, 1, obsluzJR
		
		move $a0, $s4
		la $a1, instrukcjaJal
		jal porownajTekst
		beq $v0, 1, obsluzJAL
		
		# MODYFIKACJA
		# ------
		move $a0, $s4
		la $a1, instrukcjaModyfikacji
		jal porownajTekst
		beq $v0, 1, obsluzMult # bo tez przyjmuje dwa rejestry
		# ------
		
		# Jesli zaden pattern nie pasuje, instrukcja jest nieprawidlowa
		j nieprawidlowaInstrukcja
		
	nieprawidlowaInstrukcja:
		# Wyswietlamy komunikat o blednej instrukcji
		li $v0, 4
		la $a0, komunikatBlednejInstrukcji
		syscall
		# Wracamy do pobierania instrukcji
		j pobierzInstrukcje
		
	umiescInstrukcjeNaStosie:
		# Obliczamy indeks ostatniego elementu w tablicy
		addi $t0, $s2, -1
		mul $t0, $t0, 4
		add $t0, $t0, $s3
		# Dodajemy liczbe elementow do calkowitej liczby na stosie
		add $s5, $s5, $s2
		
		# Kopiujemy liczbe elementow do licznika petli
		move $t2, $s2
		
		petlaUmieszczaniaInstrukcji:
			# Sprawdzamy czy zostaly jeszcze elementy do umieszczenia
			blez $t2, umieszczSeparator
			# Pobieramy adres aktualnego stringa
			lw $t1, ($t0)
			# Umieszczamy na stosie
			addi $sp, $sp, -4
			sw $t1, ($sp)
			# Dekrementujemy licznik i przesuwamy wskaznik
			addi $t2, $t2, -1
			addi $t0, $t0, -4
			j petlaUmieszczaniaInstrukcji
			
		umieszczSeparator:
			# Umieszczamy separator miedzy instrukcjami na stosie
			la $t0, separatorLinii
			addi $sp, $sp, -4
			sw $t0, ($sp)
			# Zwiekszamy licznik elementow na stosie
			add $s5, $s5, 1
			
			# Przechodzimy do sprawdzenia czy pobrac kolejna instrukcje
			j sprawdzCzyPobracKolejnaInstrukcje
		
	sprawdzCzyPobracKolejnaInstrukcje:
		# Dekrementujemy licznik pozostalych instrukcji
		addi $s0, $s0, -1
		# Jesli zostaly jeszcze instrukcje, pobieramy kolejna
		beqz $s0, zakonczProgram
		j pobierzInstrukcje
		
	zakonczProgram:
		# Kopiujemy liczbe elementow na stosie do rejestru roboczego
		move $t0, $s5
		
		# Obliczamy rozmiar pamieci w bajtach i wyswietlamy
		mul $t1, $t0, 4
		li $v0, 4
		la $a0, komunikatAlokacjiPamieci
		syscall
		li $v0, 1
		move $a0, $t1
		syscall
		li $v0, 4
		la $a0, nowaLinia
		syscall
		
		wyswietlStos:
			# Sprawdzamy czy zostaly elementy do wyswietlenia
			beqz $t0, zapytajOKontynuacje
		
			# Pobieramy element ze stosu i wyswietlamy
			lw $a0, ($sp)
			li $v0, 4
			syscall
			
			# Dodajemy nowa linie po kazdym elemencie
			la $a0, nowaLinia
			li $v0, 4
			syscall
			
			# Przesuwamy wskaznik stosu i dekrementujemy licznik
			addi $sp, $sp, 4
			addi $t0, $t0, -1
			j wyswietlStos
	
		zapytajOKontynuacje:
		# Wyswietlamy zapytanie o kontynuacje programu
		li $v0, 4
		la $a0, zapytanieKontynuacji
		syscall
		
		# Wczytujemy odpowiedz uzytkownika
		li $v0, 8
		la $a0, odpowiedzUzytkownika
		li $a1, 3
		syscall
		
		# Sprawdzamy pierwszy znak odpowiedzi
		lb $t0, 0($a0)
		
		# Jesli 'T' lub 't', kontynuujemy program
		beq $t0, 84, zerujStanIKontynuj   # 'T'
		beq $t0, 116, zerujStanIKontynuj  # 't'
		
		# W przeciwnym przypadku konczymy program
		j wyjscieZProgramu
		
		zerujStanIKontynuj:
		# Zerujemy wszystkie rejestry stanu
		li $s0, 0
		li $s1, 0
		li $s2, 0
		li $s3, 0
		li $s4, 0
		li $s5, 0
		# Wracamy do poczatku programu
		j glownyProgram
		
		wyjscieZProgramu:
		# Konczymy wykonywanie programu
		li $v0, 10
		syscall
		
	# Obsluga instrukcji ADD - wymaga 4 elementow (nazwa + 3 rejestry)
	obsluzAdd:
		# Sprawdzamy czy instrukcja ma dokladnie 4 elementy
		bne $s2, 4, nieprawidlowaInstrukcja
		
		# Sprawdzamy czy drugi element to rejestr
		lw $a0, 4($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		# Sprawdzamy czy trzeci element to rejestr
		lw $a0, 8($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		# Sprawdzamy czy czwarty element to rejestr
		lw $a0, 12($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		# Jesli wszystko sie zgadza, umieszczamy instrukcje na stosie
		j umiescInstrukcjeNaStosie
		
	# Obsluga instrukcji ADDI - wymaga 4 elementow (nazwa + 2 rejestry + wartosc natychmiastowa)
	obsluzAddI:
		# Sprawdzamy liczbe elementow
		bne $s2, 4, nieprawidlowaInstrukcja
		
		# Sprawdzamy pierwszy rejestr
		lw $a0, 4($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		# Sprawdzamy drugi rejestr
		lw $a0, 8($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		# Sprawdzamy czy ostatni element to wartosc natychmiastowa
		lw $a0, 12($s3)
		jal czyToWartoscNatychmiastowa
		beqz $v0, nieprawidlowaInstrukcja
		
		j umiescInstrukcjeNaStosie
		
	# Obsluga instrukcji J - wymaga 2 elementow (nazwa + etykieta)
	obsluzJ:
		# Sprawdzamy liczbe elementow
		bne $s2, 2, nieprawidlowaInstrukcja
		
		# Sprawdzamy czy drugi element to etykieta
		lw $a0, 4($s3)
		jal czyToEtykieta
		beqz $v0, nieprawidlowaInstrukcja
		
		j umiescInstrukcjeNaStosie
		
	# Obsluga instrukcji NOOP - wymaga tylko 1 elementu (sama nazwa)
	obsluzNOOP:
		# Sprawdzamy czy instrukcja ma dokladnie 1 element
		bne $s2, 1, nieprawidlowaInstrukcja
		
		j umiescInstrukcjeNaStosie
		
	# Obsluga instrukcji MULT - wymaga 3 elementow (nazwa + 2 rejestry)
	obsluzMult:
		# Sprawdzamy liczbe elementow
		bne $s2, 3, nieprawidlowaInstrukcja
		
		# Sprawdzamy pierwszy rejestr
		lw $a0, 4($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		# Sprawdzamy drugi rejestr
		lw $a0, 8($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		j umiescInstrukcjeNaStosie
		
	# Obsluga instrukcji JR - wymaga 2 elementow (nazwa + rejestr)
	obsluzJR:
		# Sprawdzamy liczbe elementow
		bne $s2, 2, nieprawidlowaInstrukcja
		
		# Sprawdzamy czy drugi element to rejestr
		lw $a0, 4($s3)
		jal czyToRejestr
		beqz $v0, nieprawidlowaInstrukcja
		
		j umiescInstrukcjeNaStosie
		
	# Obsluga instrukcji JAL - wymaga 2 elementow (nazwa + etykieta)
	obsluzJAL:
		# Sprawdzamy liczbe elementow
		bne $s2, 2, nieprawidlowaInstrukcja
		
		# Sprawdzamy czy drugi element to etykieta
		lw $a0, 4($s3)
		jal czyToEtykieta
		beqz $v0, nieprawidlowaInstrukcja
		
		j umiescInstrukcjeNaStosie
		
	# Funkcja porownujaca dwa stringi znak po znak
	# Parametry: a0 - adres pierwszego stringa, a1 - adres drugiego stringa
	# Zwraca: v0 - 1 jesli stringi sa identyczne, 0 jesli rozne
	porownajTekst:
		sprawdzZnak:
			# Wczytujemy po jednym znaku z kazdego stringa
		 	li $t0, 0
		 	li $t1, 0
			lb $t0, ($a0)
			lb $t1, ($a1)
			# Jesli znaki sa rozne, stringi nie sa identyczne
			bne $t0, $t1, zwrocNierowne
			# Jesli dotarlismy do konca stringow (znak 0), sa identyczne
			beq $t0, 0, zwrocRowne
			# Przesuwamy wskazniki na kolejne znaki
			addi $a0, $a0, 1
			addi $a1, $a1, 1
			j sprawdzZnak
			
		zwrocNierowne:
			# Zwracamy 0 (false)
			li $v0, 0
			jr $ra
			
		zwrocRowne:
			# Zwracamy 1 (true)
			li $v0, 1
			jr $ra
		
	# Funkcja sprawdzajaca czy string reprezentuje wartosc natychmiastowa (liczbe)
	# Parametr: a0 - adres stringa
	# Zwraca: v0 - 1 jesli to liczba, 0 jesli nie
	czyToWartoscNatychmiastowa:
		# Zapisujemy adres powrotu na stos
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		# Pobieramy pierwszy znak
		lb $t0, ($a0)
		
		sprawdzZnakMinus:
		# Sprawdzamy czy to znak minus (kod ASCII 45)
		bne $t0, 45, sprawdzZnakPlus
		addi $a0, $a0, 1
		
		sprawdzZnakPlus:
		# Sprawdzamy czy to znak plus (kod ASCII 43)
		bne $t0, 43, sprawdzCzyToLiczba
		addi $a0, $a0, 1
		
		sprawdzCzyToLiczba:
			# Pobieramy kolejny znak
			lb $t0, ($a0)
			# Jesli koniec stringa, to byla poprawna liczba
			beqz $t0, zwrocJestWartosciaNatychmiastowa
			
			# Sprawdzamy czy znak jest cyfra (ASCII 48-57)
			blt $t0, 48, zwrocNieJestWartosciaNatychmiastowa
			bgt $t0, 57, zwrocNieJestWartosciaNatychmiastowa
			
			# Przechodzimy do kolejnego znaku
			addi $a0, $a0, 1
			j sprawdzCzyToLiczba
			
		zwrocJestWartosciaNatychmiastowa:
			# Przywracamy adres powrotu i zwracamy 1
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 1
			jr $t0
			
		zwrocNieJestWartosciaNatychmiastowa:
			# Przywracamy adres powrotu i zwracamy 0
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 0
			jr $t0
		
	# Funkcja sprawdzajaca czy string reprezentuje etykiete (tylko litery)
	# Parametr: a0 - adres stringa
	# Zwraca: v0 - 1 jesli to etykieta, 0 jesli nie
	czyToEtykieta:
		# Zapisujemy adres powrotu na stos
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		sprawdzCzyToLitera:
			# Pobieramy kolejny znak
			lb $t0, ($a0)
			# Jesli koniec stringa, etykieta jest poprawna
			beqz $t0, zwrocJestEtykieta
			
			# Sprawdzamy czy znak jest wielka litera (A-Z, ASCII 65-90)
			sge $t1, $t0, 65
			sle $t2, $t0, 90
			# Sprawdzamy czy znak jest mala litera (a-z, ASCII 97-122)
			sge $t3, $t0, 97
			sle $t4, $t0, 122
			
			# Obliczamy czy znak jest litera
			and $t1, $t1, $t2  # czy wielka litera
			and $t3, $t3, $t4  # czy mala litera
			or $t1, $t1, $t3   # czy jakakolwiek litera
			# Jesli nie litera, etykieta niepoprawna
			beqz $t1, zwrocNieJestEtykieta
			
			# Przechodzimy do kolejnego znaku
			addi $a0, $a0, 1
			j sprawdzCzyToLitera
			
		zwrocJestEtykieta:
			# Przywracamy adres powrotu i zwracamy 1
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 1
			jr $t0
			
		zwrocNieJestEtykieta:
			# Przywracamy adres powrotu i zwracamy 0
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 0
			jr $t0
		
	# Funkcja sprawdzajaca czy string reprezentuje rejestr (format $xx)
	# Parametr: a0 - adres stringa
	# Zwraca: v0 - 1 jesli to rejestr, 0 jesli nie
	czyToRejestr:
		# Zapisujemy adres powrotu na stos
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		# Pobieramy pierwsze 4 znaki stringa
		lb $t0, 0($a0)  # pierwszy znak
		lb $t1, 1($a0)  # drugi znak
		lb $t2, 2($a0)  # trzeci znak
		lb $t3, 3($a0)  # czwarty znak
		
		# Pierwszy znak musi byc '$' (ASCII 36)
		bne $t0, 36, zwrocNieJestRejestrem
		
		# Sprawdzamy czy rejestr jest jednocyfrowy czy dwucyfrowy
		beqz $t2, sprawdzRejestrJednocyfrowy
		beqz $t3, sprawdzRejestrDwucyfrowy
		# Jesli ani jednocyfrowy ani dwucyfrowy, to bledny
		j zwrocNieJestRejestrem
		
		sprawdzRejestrDwucyfrowy:
		# Pierwsza cyfra musi byc 1, 2 lub 3 (ASCII 49-51)
		blt $t1, 49, zwrocNieJestRejestrem
		bgt $t1, 51, zwrocNieJestRejestrem
		# Druga cyfra musi byc cyfra (ASCII 48-57)
		blt $t2, 48, zwrocNieJestRejestrem
		bgt $t2, 57, zwrocNieJestRejestrem
		
		# Jesli pierwsza cyfra to 3, druga nie mozne byc wieksza niz 1 (max $31)
		bne $t1, 51, zwrocJestRejestrem
		bgt $t2, 49, zwrocNieJestRejestrem
		j zwrocJestRejestrem
		
		sprawdzRejestrJednocyfrowy:
		# Cyfra musi byc w zakresie 0-9 (ASCII 48-57)
		blt $t1, 48, zwrocNieJestRejestrem
		bgt $t1, 57, zwrocNieJestRejestrem
		j zwrocJestRejestrem
		
		zwrocJestRejestrem:
			# Przywracamy adres powrotu i zwracamy 1
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 1
			jr $t0
			
		zwrocNieJestRejestrem:
			# Przywracamy adres powrotu i zwracamy 0
			lw $t0, ($sp)
			addi $sp, $sp, 4
			li $v0, 0
			jr $t0
		
	# Funkcja dzielaca string na oddzielne slowa
	# Parametr: a0 - adres stringa do podzialu
	# Zwraca: v0 - liczba slow, v1 - tablica wskaznikow do slow
	podzielString:
		# Zapisujemy adres powrotu na stos
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		# Inicjalizujemy rejestry robocze
		move $t0, $a0  # aktualny adres znaku w stringu
		li $t1, 0      # flaga czy poprzedni znak byl czescia slowa
		li $t2, 0      # liczba znalezionych slow
		li $t3, 32     # kod ASCII spacji (udajemy ze poprzedni znak byl spacja)
		
		move $t7, $a0  # zachowujemy oryginalny adres stringa
		
		liczSlow:
			# Pobieramy kolejny znak
			lb $t3, ($t0)
			# Jesli koniec stringa, przechodzimy do tworzenia tablicy
			beqz $t3, tablicaZeStosu
			
			# Sprawdzamy czy znak to separator (spacja, nowa linia, przecinek)
			seq $t4, $t3, 32   # spacja
			seq $t5, $t3, 10   # nowa linia
			or $t4, $t4, $t5
			seq $t5, $t3, 44   # przecinek
			or $t4, $t4, $t5
			
			# Jesli to separator
			seq $t5, $t4, 0     # t5 = 1 jesli znak NIE jest separatorem
			and $t1, $t5, $t1   # jesli separator, resetujemy flage slowa
			mul $t3, $t3, $t5   # jesli separator, zamieniamy znak na 0
			sb $t3, ($t0)       # zapisujemy zmieniony znak
			add $t0, $t0, $t4   # przesuwamy wskaznik o 1 jesli separator
			beq $t4, 1, liczSlow  # jesli separator, kontynuujemy petle
			
			# Znak nie jest separatorem
			seq $t5, $t1, 0       # sprawdzamy czy poprzedni znak byl separatorem
		
			beqz $t5, pominUmieszczeniaNaStosie
			# Jesli zaczynamy nowe slowo, zwiekszamy licznik slow
			add $t2, $t2, 1
			# Umieszczamy adres poczatku slowa na stosie
			addi $sp, $sp, -4
			sw $t0, ($sp)
			
			pominUmieszczeniaNaStosie:
			# Przesuwamy wskaznik i ustawiamy flage ze jestesmy w srodku slowa
			addi $t0, $t0, 1
			li $t1, 1
			j liczSlow
		
		tablicaZeStosu:
			# Alokujemy pamiec na tablice wskaznikow (liczba_slow * 4 bajty)
			li $v0, 9
			mul $a0, $t2, 4
			syscall
				
			# Przygotowujemy wyniki
			move $t0, $v0     # adres poczatku tablicy
			move $v0, $t2     # liczba slow do zwrocenia
			move $v1, $t0     # adres tablicy do zwrocenia
			
			# Obliczamy adres konca tablicy
			mul $t1, $t2, 4
			add $t1, $t1, $t0
			addi $t1, $t1, -4
			
			petlaPrzenoszeniaZeStosu:
				# Sprawdzamy czy zostaly elementy do przeniesienia
				beqz $t2, powrot
				
				# Pobieramy adres slowa ze stosu
				lw $t4, ($sp)
				# Umieszczamy w tablicy
				sw $t4, ($t1)
				# Przesuwamy wskazniki
				addi $t1, $t1, -4
				addi $sp, $sp, 4
				
				# Dekrementujemy licznik
				addi $t2, $t2, -1
				j petlaPrzenoszeniaZeStosu
		
		powrot:
			# Przywracamy adres powrotu i wracamy
			lw $ra, 0($sp)
        	addi $sp, $sp, 4
        	jr $ra
