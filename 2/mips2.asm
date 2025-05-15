.data
	prompt1: .asciiz "\nDeszyfrowac czy szyfrowac? d/s:\n"
	prompt1_b: .asciiz "\n Bledna operacja...\n"
	prompt2: .asciiz "\nPodaj dlugosc klucza [zakres 3-8]:\n"
	ciag_klucz: .space 8
	prompt2_b: .asciiz "\nNiepoprawna dlugosc klucza..\n"
	prompt3: .asciiz "\nPodaj klucz pamietaj, ze klucz musi miec tylko liczby z zakresu 1 - dlugosc klucza oraz liczby nie moga sie powtarzac:\n"
	prompt3_b1: .asciiz "\nKlucz jest zbyt krotki - dlugosc klucza ktora podales jest wieksza niz ciag klucza, ktory wpisales!\n"
	prompt3_b2: .asciiz "\nKlucz jest niepoprawny. Upewnij sie ze wpisales liczby z prawidlowego zakresu i nie wpisales powtorzen!\n"
	prompt4: .asciiz "\nPodaj tekst:\n"
	permutacja: .space 8 # 1 jeśli dana liczba była widziana, 0 jeśli nie

.text
	main:
		# PROMPT 1 - DESZYFROWAC CZY SZYFROWAC?
		li $v0, 4
		la $a0, prompt1 # wypisanie prompt 1 - wybór działania
		syscall
		# WCZYTAJ TYP OPERACJI D\S
		li $v0, 12  # syscall dla read_char
		syscall
		move $t0, $v0 # wczytujemy input do $t0
		
		li $t1, 100      # 'd' w ASCII to 49
		beq $t0, $t1, deszyfrowanie
		
		li $t1, 68      # 'D' w ASCII to 49
		beq $t0, $t1, deszyfrowanie
		
		li $t1, 115	# 'S' w ASCII to 115
		beq $t0, $t1, szyfrowanie 
		
		li $t1, 83	# 's' w ASCII to 83
		beq $t0, $t1, szyfrowanie
		
		# bledna operacja
		li $v0, 4
		la $a0, prompt1_b # wypisanie prompt 1_b
		syscall
		j main
		
	
	# dla latwiejszego porywnywania, operacja szyfrowania jest wskazywana przez wartosc 0 na $t0
	# a operacja deszyfrowania przez wartosc 1 na $t0	
	szyfrowanie:
		li $t0, 0
		j klucz
	
	deszyfrowanie:
		li $t0, 1
		j klucz
		
	#DLUGOSC KLUCZA I JEGO ZAWARTOSC
	klucz:
		# PROMPT 2 - Podaj dlugosc klucza [zakres 1-8]:
		li $v0, 4
		la $a0, prompt2 # wypisanie prompt 2
		syscall
		
		li $v0, 5        # syscall 5 = read_int
		syscall
		move $t1, $v0    # przenosimy wynik (int) z $v0 do $t1
		
		li $t2, 3
		bge $t1, $t2, skok1 # sprawdzamy czy $t1 >= 3
		j dlugosc_zla
	dlugosc_zla:
		li $v0, 4
		la $a0, prompt2_b
		syscall
		j klucz
	skok1:
		li $t2, 9
		bge $t1, $t2, dlugosc_zla # sprawdzamy czy 9 >= $t1
		# jesli sie zgadza, to mozemy wczytywac klucz!
		
	wczytaj_ciag_klucz:
		# PROMPT 3 - podaj klucz
		li $v0, 4
		la $a0, prompt3 # wypisanie prompt 3
		syscall
	
		add $t2, $t1, 1 # zwiekszamy o 1 bo lancuch konczy sie zawsze null charem lub \n
		la $a0, ciag_klucz
		move $a1, $t2 # dlugosc lancucha
		li $v0, 8 # syscall dla wczytywania lancucha znakow
    		syscall
    		
    		jal strlen
    		
    		beq $t1, $v0, skok2
    		
    		j klucz_zlej_dlugosci
    		
    	klucz_zlej_dlugosci:
    		# PROMPT 3_b1 - zla dlugosc klucza
		li $v0, 4
		la $a0, prompt3_b1 # wypisanie prompt 1 - wybór działania
		syscall
		j klucz
    		
    	# Assumes:
	# $a0 = address of the string
	# Result:
	# $v0 = length (number of characters before null byte)

	strlen:
    		li $v0, 0          # length = 0

	strlen_loop:
    		lb $t0, 0($a0)     # load byte from string
    		beq $t0, $zero, strlen_done  # if byte == 0, end
    		addi $v0, $v0, 1     # length++
    		addi $a0, $a0, 1     # move to next character
    		j strlen_loop

	strlen_done:
    		jr $ra             # return to caller
    		
    	sprawdz_poprawnosc_klucza:
    		j wyczysc_permutacje
    	
    	wyczysc_permutacje:
    		la $t3, permutacja
    		li $t4, 0 # index czyszczenia
    		move $t5, $t1 # dlugosc permutacji 
    		j wyczysc_permutacje_loop
    		
    	wyczysc_permutacje_loop:
    		beq $t4, $t5, permutuj # jesli index == dlugosci to wyjdz z petli
    		sb $zero, 0($t3) # ustaw wartosc permutacji na 0 - nie widzielismy zadnego chara jeszcze
    		addi $t3, $t3, 1 # przesun w prawo
    		addi $t4, $t4, 1 # zwieksz indeks
    		j wyczysc_permutacje_loop
    		
    	permutuj:
    		la $t3, ciag_klucz
    		li $t4, 0 # index poprawnosci
    		move $t5, $t1 # dlugosc permutacji
    		li $t6, 49 # ascii '1'
    		li $v0, 1 # 1 poprawny ciag
    		j permutuj_loop
    		
    	permutuj_loop:
    		beq $t4, $t5, ciag_poprawny
    		lb $t7, 0($t3)
    		sub $t7, $t7, $t6 # zmniejszamy wartosc o wartosc ascii '1' nasz range to teraz: [0-len-1]
    		bltz $t7, ciag_niepoprawny # sprwadzenie czy nasz char jest w range ['1', 'dlugosc']
    		bge $t7, $t5, ciag_niepoprawny
    		la $t8, permutacja
    		add $t8, $t8, $t7
    		lb $t9, 0($t8)
    		bne $t9, $zero, ciag_niepoprawny # wartosc tego chara sie powtarza w ciagu
    		
    		li $t9, 1
    		sb $t9, 0($t8)
    		
    		add $t4, $t4, 1 # zwieksz indeks poprawnosci o 1
    		add $t3, $t3, 1 # przemiesc sie dalej po stringu
    		j permutuj_loop
    		
    	ciag_niepoprawny:
    		li, $v0, 0
    		jr $ra
    	
    	ciag_poprawny:
    		jr $ra	
    	
	niepoprawny_klucz:
    		# PROMPT 3_b2 - zly klucz - powtorzenia lub zakres
		li $v0, 4
		la $a0, prompt3_b2 # wypisanie promptu
		syscall
		j wczytaj_ciag_klucz
		
    	
    	skok2:
    		jal sprawdz_poprawnosc_klucza
    		beqz $v0, niepoprawny_klucz # klucz sie powtarza, lub jego liczby nie mieszcza sie w zakresie
    		# klucz sie zgadza, jest zapisany teraz mozemy wczytac tekst do szyfrowania i szyfrowac
    		
		


