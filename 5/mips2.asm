.macro drukuj (%etykieta)
li $v0, 4
la $a0, %etykieta
syscall
.end_macro

.macro drukujAdres (%adres)
li $v0, 4
move $a0, %adres
syscall
.end_macro

.macro drukujLiczbe (%rejestr)
li $v0, 1
move $a0, %rejestr
syscall
.end_macro

.macro drukujZnakAdr (%rejestr)
li $v0, 11
lb $a0, (%rejestr)
syscall
.end_macro

.macro drukujZnakEtykieta (%rejestr)
li $v0, 11
lb $a0, %rejestr
syscall
.end_macro

.macro rozpocznijFunkcje
sw $fp, -4($sp)
sw $ra, -8($sp)
addi $sp, $sp, -8
move $fp, $sp
.end_macro

.macro powrot
la $sp, 8($fp)
lw $ra, ($fp)
lw $fp, 4($fp)
jr $ra
.end_macro

.macro czytajCyfre
li $v0, 12
syscall
addi $v0, $v0, -48
.end_macro

.macro wyjscie
li $v0, 10
syscall
.end_macro

.data
	komunikatLiczbaRund: .asciiz "\nWybierz liczbe rund (1-5): \n"
	komunikatBladRund: .asciiz "\nNieprawidlowy wybor\n"

	komunikatWyborZnaku: .asciiz "\nWybierz swoj znak (kolko - 0, krzyzyk 1): "
	komunikatBladZnaku: .asciiz "\nNieprawidlowy wybor\n"
	
	komunikatWygraneKomputera: .asciiz "\nLiczba wygranych komputera: "
	komunikatWygraneGracza: .asciiz "\nLiczba wygranych gracza: "
	
	komunikatWyborPola: .asciiz "\nPodaj pole (1-9): "
	komunikatBladPola: .asciiz "\nNieprawidlowe pole\n"
	
	komunikatWygralKomputer: .asciiz "\nKomputer wygral\n"
	komunikatWygralGracz: .asciiz "\nGracz wygral\n"
	komunikatRemis: .asciiz "\nRemis\n"
	
	nowaLinia: .byte 10

	gracz: .byte 88          # X
	komputer: .byte 79       # O
	pustePole: .byte 46      # .

	# Definicje linii wygrywajacych (poziome, pionowe, przekatne)
	linie: .byte -1 -2 -3, -4 -5 -6, -7 -8 -9, -1 -4 -7, -2 -5 -8, -3 -6 -9, -1 -5 -9, -7 -5 -3

.text
	# s0 - liczba pozostalych rund
	# s1 - wygrane gracza
	# s2 - wygrane komputera
	# s3 - adres planszy
	main:
		move $fp, $sp
		move $s3, $fp
		move $a0, $fp
		jal przygotujPlansze
		addi $sp, $sp, -12
		
		jal pobierzLiczbeRund
		
		
		petlaRund:
			beqz $s0, koniecGry
			jal pobierzZnakGracza
			
			jal wykonajRunde
			addi $s0, $s0, -1
			j petlaRund
			
		koniecGry:
			jal drukujWynik
			wyjscie
		
	pobierzLiczbeRund:
		drukuj (komunikatLiczbaRund)
		czytajCyfre
		blez $v0, bladLiczbyRund
		bgt $v0, 5, bladLiczbyRund
		
		move $s0, $v0
		jr $ra
		
		bladLiczbyRund:
			drukuj (komunikatBladRund)
			j pobierzLiczbeRund
	
	pobierzZnakGracza:
		drukuj (komunikatWyborZnaku)
		czytajCyfre
		beqz $v0, graczKolko
		beq $v0, 1, graczKrzyzyk
		drukuj (komunikatBladZnaku)
		j pobierzZnakGracza
		
		graczKolko:
			li $v0, 79      # O
			sb $v0, gracz
			li $v0, 88      # X
			sb $v0, komputer
			jr $ra
			
		graczKrzyzyk:
			li $v0, 79      # O
			sb $v0, komputer
			li $v0, 88      # X
			sb $v0, gracz
			jr $ra
	
	drukujWynik:
		drukuj (komunikatWygraneGracza)
		drukujLiczbe ($s1)
		drukuj (komunikatWygraneKomputera)
		drukujLiczbe ($s2)
		jr $ra
		
	# Sekcja wykonywania rundy
	wykonajRunde:
		rozpocznijFunkcje
		
		move $a0, $s3
		jal przygotujPlansze
		
		ruchGracza:
			drukujZnakEtykieta (nowaLinia)
			move $a0, $s3
			jal rysujPlansze
		
			move $a0, $s3
			jal zapytajORuchGracza
			
			add $t0, $s3, $v0
			lb $t1, gracz
			sb $t1, ($t0)
			
			move $a0, $s3
			jal sprawdzStanGry
			beqz $v0, ruchKomputera
			j koniecRundy
			
		ruchKomputera:
			move $a0, $s3
			jal znajdzNajlepszyRuchKomputera
			add $t0, $s3, $v0
			lb $t1, komputer
			sb $t1, ($t0)
			
			move $a0, $s3
			jal sprawdzStanGry
			beqz $v0, ruchGracza
			j koniecRundy
		
		koniecRundy:
			seq $t0, $v0, 1     # gracz wygral
			seq $t1, $v0, 2     # komputer wygral
			add $s1, $s1, $t0
			add $s2, $s2, $t1
			
			bne $t0, 1, pominWygranaGracza
			drukuj (komunikatWygralGracz)
			
			pominWygranaGracza:
			bne $t1, 1, pominWygranaKomputera
			drukuj (komunikatWygralKomputer)
			
			pominWygranaKomputera:
			or $t0, $t0, $t1
			bne $t0, 0, pominRemis
			drukuj (komunikatRemis)
			
			pominRemis:
			powrot
		
	zapytajORuchGracza:
		# a0 - adres pierwszego pola
		# v0 - wybrane pole [-1, -9]
		move $t0, $a0
		
		zapytajORuch:
			drukujZnakEtykieta (nowaLinia)
			drukuj (komunikatWyborPola)
			czytajCyfre
			blez $v0, bladRuchu
			bgt $v0, 9, bladRuchu
			
			neg $v0, $v0
			add $t1, $t0, $v0
			lb $t2, pustePole
			lb $t1, ($t1)
			bne $t2, $t1, bladRuchu
			
			move $t0, $v0
			drukujZnakEtykieta (nowaLinia)
			move $v0, $t0
			jr $ra
			
		bladRuchu:
			drukuj (komunikatBladPola)
			j zapytajORuch
	
	przygotujPlansze:
		# a0 - adres pierwszego pola
		lb $t0, pustePole
		
		sb $t0, -1($a0)
		sb $t0, -2($a0)
		sb $t0, -3($a0)
		sb $t0, -4($a0)
		sb $t0, -5($a0)
		sb $t0, -6($a0)
		sb $t0, -7($a0)
		sb $t0, -8($a0)
		sb $t0, -9($a0)
		jr $ra
	
	rysujPlansze:
		# a0 - adres pierwszego pola
		sw $t0, -4($sp)
		sw $t1, -8($sp)
		sw $a0, -12($sp)
		move $t0, $a0
		
		# rzad 1 - pola 1, 2, 3
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre1
		drukujZnakAdr ($t0)
		j po1
		drukujCyfre1:
			li $a0, 49  # znak '1'
			li $v0, 11
			syscall
		po1:
		
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre2
		drukujZnakAdr ($t0)
		j po2
		drukujCyfre2:
			li $a0, 50  # znak '2'
			li $v0, 11
			syscall
		po2:
		
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre3
		drukujZnakAdr ($t0)
		j po3
		drukujCyfre3:
			li $a0, 51  # znak '3'
			li $v0, 11
			syscall
		po3:
		drukujZnakEtykieta (nowaLinia)
		
		# rzad 2 - pola 4, 5, 6
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre4
		drukujZnakAdr ($t0)
		j po4
		drukujCyfre4:
			li $a0, 52  # znak '4'
			li $v0, 11
			syscall
		po4:
		
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre5
		drukujZnakAdr ($t0)
		j po5
		drukujCyfre5:
			li $a0, 53  # znak '5'
			li $v0, 11
			syscall
		po5:
		
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre6
		drukujZnakAdr ($t0)
		j po6
		drukujCyfre6:
			li $a0, 54  # znak '6'
			li $v0, 11
			syscall
		po6:
		drukujZnakEtykieta (nowaLinia)
		
		# rzad 3 - pola 7, 8, 9
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre7
		drukujZnakAdr ($t0)
		j po7
		drukujCyfre7:
			li $a0, 55  # znak '7'
			li $v0, 11
			syscall
		po7:
		
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre8
		drukujZnakAdr ($t0)
		j po8
		drukujCyfre8:
			li $a0, 56  # znak '8'
			li $v0, 11
			syscall
		po8:
		
		addi $t0, $t0, -1
		lb $t1, ($t0)
		lb $t2, pustePole
		beq $t1, $t2, drukujCyfre9
		drukujZnakAdr ($t0)
		j po9
		drukujCyfre9:
			li $a0, 57  # znak '9'
			li $v0, 11
			syscall
		po9:
		drukujZnakEtykieta (nowaLinia)
		drukujZnakEtykieta (nowaLinia)
		
		lw $t0, -4($sp)
		lw $t1, -8($sp)
		lw $a0, -12($sp)
		jr $ra
	
	sprawdzStanGry:
		# a0 - adres pierwszego pola
		# v0 - stan (0 - gra trwa, 1-gracz wygral, 2-komputer wygral, 3-remis)
		rozpocznijFunkcje
		
		# pierwszy rzad poziomy
		lb $t0, -1($a0)
		lb $t1, -2($a0)
		lb $t2, -3($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		# drugi rzad poziomy
		lb $t0, -4($a0)
		lb $t1, -5($a0)
		lb $t2, -6($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		# trzeci rzad poziomy
		lb $t0, -7($a0)
		lb $t1, -8($a0)
		lb $t2, -9($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		# pierwsza kolumna
		lb $t0, -1($a0)
		lb $t1, -4($a0)
		lb $t2, -7($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		# druga kolumna
		lb $t0, -2($a0)
		lb $t1, -5($a0)
		lb $t2, -8($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		# trzecia kolumna
		lb $t0, -3($a0)
		lb $t1, -6($a0)
		lb $t2, -9($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		# przekatna rosnaca
		lb $t0, -7($a0)
		lb $t1, -5($a0)
		lb $t2, -3($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		# przekatna opadajaca
		lb $t0, -1($a0)
		lb $t1, -5($a0)
		lb $t2, -9($a0)
		jal sprawdzWygrana
		bnez $v0, zwrocStanWygrana
		
		j sprawdzRemis
		
		sprawdzWygrana:
			# sprawdza rejestry t0, t1, t2
			seq $t0, $t0, $t1
			seq $t1, $t1, $t2
			and $t0, $t0, $t1
			beqz $t0, brakWygranej
			lb $t1, gracz
			beq $t1, $t2, wygranaGracza
			lb $t1, komputer
			beq $t1, $t2, wygranaKomputera
			
			brakWygranej:
				li $v0, 0
				jr $ra
			
			wygranaGracza:
				li $v0, 1
				jr $ra
				
			wygranaKomputera:
				li $v0, 2
				jr $ra
				
		zwrocStanWygrana:
			powrot
			
		sprawdzRemis:
			li $t0, 0
			sprawdzKolejnePoleRemis:
				addi $t0, $t0, -1
				beq $t0, -10, zwrocRemis
				li $t1, 0
				add $t1, $a0, $t0
				lb $t2, ($t1)
				lb $t1, pustePole
				beq $t2, $t1, zwrocGraTrawa
				j sprawdzKolejnePoleRemis
				
			zwrocRemis:
				li $v0, 3
				powrot
				
			zwrocGraTrawa:
				li $v0, 0
				powrot

	znajdzNajlepszyRuchKomputera:
		# a0 - adres planszy
		# v0 - wybrany ruch [-1, -9]
		rozpocznijFunkcje
		move $t0, $a0        # wskaznik na poczatek planszy
		li $t1, 0            # aktualna linia (zawsze podzielna przez 3)
		lb $t7, komputer
		
		# Sprawdz czy komputer moze wygrac
		petlaSprawdzWygrana:
			beq $t1, 24, koniecSprawdzWygrana
			
			lb $t2, linie($t1)      # t2 - numer pola
			add $t2, $t2, $t0       # t2 - adres pola
			lb $t2, ($t2)           # t2 - znak w polu
			
			lb $t3, linie + 1($t1)  # t3 - numer pola
			add $t3, $t3, $t0       # t3 - adres pola
			lb $t3, ($t3)           # t3 - znak w polu
			
			lb $t4, linie + 2($t1)  # t4 - numer pola
			add $t4, $t4, $t0       # t4 - adres pola
			lb $t4, ($t4)           # t4 - znak w polu
			
			# Sprawdz wzor: komputer-komputer-puste
			seq $t5, $t2, $t7       # t5 - pole 1 to komputer
			seq $t6, $t3, $t7       # t6 - pole 2 to komputer
			and $t5, $t5, $t6       # t5 - pole 1 i 2 to komputer
			seq $t6, $t4, 46        # t6 - pole 3 puste (46 = '.')
			and $t5, $t5, $t6       # t5 - wzor komputer-komputer-puste
			lb $v0, linie + 2($t1)  # zaladuj adres 3 pola
			bnez $t5, zwrocRuch     # zwroc jesli wzor pasuje
			
			# Sprawdz wzor: komputer-puste-komputer
			seq $t5, $t2, $t7       # t5 - pole 1 to komputer
			seq $t6, $t4, $t7       # t6 - pole 3 to komputer
			and $t5, $t5, $t6       # t5 - pole 1 i 3 to komputer
			seq $t6, $t3, 46        # t6 - pole 2 puste
			and $t5, $t5, $t6       # t5 - wzor komputer-puste-komputer
			lb $v0, linie + 1($t1)  # zaladuj adres 2 pola
			bnez $t5, zwrocRuch     # zwroc jesli wzor pasuje
			
			# Sprawdz wzor: puste-komputer-komputer
			seq $t5, $t4, $t7       # t5 - pole 3 to komputer
			seq $t6, $t3, $t7       # t6 - pole 2 to komputer
			and $t5, $t5, $t6       # t5 - pole 3 i 2 to komputer
			seq $t6, $t2, 46        # t6 - pole 1 puste
			and $t5, $t5, $t6       # t5 - wzor puste-komputer-komputer
			lb $v0, linie($t1)      # zaladuj adres 1 pola
			bnez $t5, zwrocRuch     # zwroc jesli wzor pasuje
			
			addi $t1, $t1, 3
			j petlaSprawdzWygrana

		koniecSprawdzWygrana:
			li $t1, 0               # reset licznika linii
			lb $t7, gracz           # teraz sprawdzamy ruchy gracza do zablokowania
			
		# Sprawdz czy trzeba zablokowac gracza
		petlaSprawdzBlokada:
			beq $t1, 24, wybierzSrodek
			
			lb $t2, linie($t1)      # t2 - numer pola
			add $t2, $t2, $t0       # t2 - adres pola
			lb $t2, ($t2)           # t2 - znak w polu
			
			lb $t3, linie + 1($t1)  # t3 - numer pola
			add $t3, $t3, $t0       # t3 - adres pola
			lb $t3, ($t3)           # t3 - znak w polu
			
			lb $t4, linie + 2($t1)  # t4 - numer pola
			add $t4, $t4, $t0       # t4 - adres pola
			lb $t4, ($t4)           # t4 - znak w polu
			
			# Sprawdz wzor: gracz-gracz-puste
			seq $t5, $t2, $t7       # t5 - pole 1 to gracz
			seq $t6, $t3, $t7       # t6 - pole 2 to gracz
			and $t5, $t5, $t6       # t5 - pole 1 i 2 to gracz
			seq $t6, $t4, 46        # t6 - pole 3 puste
			and $t5, $t5, $t6       # t5 - wzor gracz-gracz-puste
			lb $v0, linie + 2($t1)  # zaladuj adres 3 pola
			bnez $t5, zwrocRuch     # zwroc jesli wzor pasuje
			
			# Sprawdz wzor: gracz-puste-gracz
			seq $t5, $t2, $t7       # t5 - pole 1 to gracz
			seq $t6, $t4, $t7       # t6 - pole 3 to gracz
			and $t5, $t5, $t6       # t5 - pole 1 i 3 to gracz
			seq $t6, $t3, 46        # t6 - pole 2 puste
			and $t5, $t5, $t6       # t5 - wzor gracz-puste-gracz
			lb $v0, linie + 1($t1)  # zaladuj adres 2 pola
			bnez $t5, zwrocRuch     # zwroc jesli wzor pasuje
			
			# Sprawdz wzor: puste-gracz-gracz
			seq $t5, $t4, $t7       # t5 - pole 3 to gracz
			seq $t6, $t3, $t7       # t6 - pole 2 to gracz
			and $t5, $t5, $t6       # t5 - pole 3 i 2 to gracz
			seq $t6, $t2, 46        # t6 - pole 1 puste
			and $t5, $t5, $t6       # t5 - wzor puste-gracz-gracz
			lb $v0, linie($t1)      # zaladuj adres 1 pola
			bnez $t5, zwrocRuch     # zwroc jesli wzor pasuje
			
			addi $t1, $t1, 3
			j petlaSprawdzBlokada
			
		# Jesli brak ruchow wygrywajacych/blokujacych, wybierz strategicznie
		wybierzSrodek:
			# Sprobuj zajac srodek (pole -5)
			add $t1, $t0, -5
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocSrodek
			
		wybierzNaroznik:
			# Sprobuj zajac narozniki w kolejnosci
			add $t1, $t0, -1        # lewy gorny
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocLewyGorny
			
			add $t1, $t0, -3        # prawy gorny
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocPrawyGorny
			
			add $t1, $t0, -7        # lewy dolny
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocLewyDolny
			
			add $t1, $t0, -9        # prawy dolny
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocPrawyDolny
			
		wybierzBok:
			# Sprobuj zajac boki
			add $t1, $t0, -2        # gorny
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocGorny
			
			add $t1, $t0, -4        # lewy
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocLewy
			
			add $t1, $t0, -6        # prawy
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocPrawy
			
			add $t1, $t0, -8        # dolny
			lb $t2, ($t1)
			lb $t3, pustePole
			beq $t2, $t3, zwrocDolny
			
		# Jesli wszystko zajete, znajdz pierwsze puste pole
		znajdzPustePole:
			li $t1, -1
			petlaZnajdzPuste:
				beq $t1, -10, zwrocPierwszePuste
				add $t2, $t0, $t1
				lb $t3, ($t2)
				lb $t4, pustePole
				beq $t3, $t4, zwrocPuste
				addi $t1, $t1, -1
				j petlaZnajdzPuste
				
		zwrocSrodek:
			li $v0, -5
			powrot
			
		zwrocLewyGorny:
			li $v0, -1
			powrot
			
		zwrocPrawyGorny:
			li $v0, -3
			powrot
			
		zwrocLewyDolny:
			li $v0, -7
			powrot
			
		zwrocPrawyDolny:
			li $v0, -9
			powrot
			
		zwrocGorny:
			li $v0, -2
			powrot
			
		zwrocLewy:
			li $v0, -4
			powrot
			
		zwrocPrawy:
			li $v0, -6
			powrot
			
		zwrocDolny:
			li $v0, -8
			powrot
			
		zwrocPuste:
			move $v0, $t1
			powrot
			
		zwrocPierwszePuste:
			li $v0, -1
			powrot
		
		zwrocRuch:
			powrot
