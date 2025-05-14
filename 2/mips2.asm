.data
	prompt1: .asciiz "\nDeszyfrowac czy szyfrowac? d/s:\n"
	prompt1_b: .asciiz "\n Bledna operacja...\n"
	prompt2: .asciiz "\nPodaj dlugosc klucza [zakres 3-8]:\n"
	prompt2_b: .asciiz "\nNiepoprawna dlugosc klucza..\n"
	prompt3: .asciiz "\nPodaj klucz:\n"
	prompt4: .asciiz "\nPodaj tekst:\n"

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
		la $a0, prompt1_b # wypisanie prompt 1 - wybór działania
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
		la $a0, prompt2 # wypisanie prompt 1 - wybór działania
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
		
		