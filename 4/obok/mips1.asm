.data
    # Komunikaty menu
    menuOptions: .asciiz "\nWybierz operację:\n+ Dodawanie\n- Odejmowanie\n* Mnozenie\n/ Dzielenie\nWpisz znak operacji (+, -, *, /): "
    
    # Prośby o dane
    promptFirstNumber: .asciiz "\nPodaj pierwsza liczbe: "
    promptSecondNumber: .asciiz "\nPodaj druga liczbe: "
    
    # Wyniki
    resultText: .asciiz "\nWynik: "
    continuePrompt: .asciiz "\nCzy chcesz kontynuowac? (T/t=tak, N/n=nie): "
    
    # Komunikaty błędów
    errorInvalidChoice: .asciiz "\nBlad nieprawidlowy znak! Wpisz +, -, *, lub /\n"
    errorContinue: .asciiz "\nZla instrukcja wpisz T/t dla tak lub N/n dla nie.\n"
    errorDivisionByZero: .asciiz "Wykryto dzielenie przez zero!\n"
    errorOverflow: .asciiz "\nWykryto przepelnienie arytmetyczne!\n"
    errorInvalidInput: .asciiz "\nNieprawidlowe dane wejsciowe!\n"
    errorNumberRange: .asciiz "\nLiczba przekracza zakres zmiennych podwojnej precyzji!\n"
    
    # Komunikaty operacji
    additionText: .asciiz "\nWynik dodawania: "
    subtractionText: .asciiz "\nWynik odejmowania: "
    multiplicationText: .asciiz "\nWynik mnozenia: "
    divisionText: .asciiz "\nWynik dzielenie: "
    
    # Stałe znaków (ASCII)
    charPlus: .byte 43       # '+'
    charMinus: .byte 45      # '-'   
    charMultiply: .byte 42   # '*'
    charDivide: .byte 47     # '/'
    charTUpper: .byte 84     # 'T'
    charTLower: .byte 116    # 't'
    charNUpper: .byte 78     # 'N'
    charNLower: .byte 110    # 'n'
    
    # Stałe liczbowe
    doubleZero: .double 0.0
    doubleTwo: .double 2.0

.text
.globl main
    
main:
    # Wyświetl menu
    li $v0, 4
    la $a0, menuOptions
    syscall
    
getOperation:
    # Wczytaj znak operacji
    li $v0, 12           # syscall dla wczytania chara
    syscall
    move $s0, $v0        # Zapisz wybrany znak operacji w $s0
    
    # Sprawdź poprawność znaku operacji
    lb $t1, charPlus
    beq $s0, $t1, readNumbers
    
    lb $t1, charMinus
    beq $s0, $t1, readNumbers
    
    lb $t1, charMultiply
    beq $s0, $t1, readNumbers
    
    lb $t1, charDivide
    beq $s0, $t1, readNumbers
    
    # Jeśli żaden nie pasuje, wyświetl błąd i pytaj ponownie
    li $v0, 4
    la $a0, errorInvalidChoice
    syscall
    j getOperation

readNumbers:
    # Wczytaj pierwszą liczbę
readFirstNumber:
    li $v1, 0 # resetuj wyjatek
    li $v0, 4
    la $a0, promptFirstNumber
    syscall
    
    li $v0, 7        # syscall dla double
    syscall
    mov.d $f20, $f0  # Zapisz pierwszą liczbę w $f20
    
    bnez $v1, handleInvalidFirstInput # Jeśli wyjątek "nieokreślony" (1), to złe dane
    
    # Sprawdź czy liczba jest prawidłowa (nie Infinity ani NaN)
    mov.d $f0, $f20  # Przygotuj argument dla funkcji
    jal checkIfNumberIsValid
    beq $v0, 0, handleFirstNumberError  # Jeśli funkcja zwróci 0, liczba nieprawidłowa

    # Wczytaj drugą liczbę
readSecondNumber:
    li $v1, 0 # resetuj wyjatek
    li $v0, 4
    la $a0, promptSecondNumber
    syscall
    
    li $v0, 7        # syscall dla double
    syscall
    mov.d $f22, $f0  # Zapisz drugą liczbę w $f22
    
    bnez $v1, handleInvalidSecondInput # Jeśli wyjątek "nieokreślony" (1), to złe dane
    
    # Sprawdź czy liczba jest prawidłowa (nie Infinity ani NaN)
    mov.d $f0, $f22  # Przygotuj argument dla funkcji
    jal checkIfNumberIsValid
    beq $v0, 0, handleSecondNumberError  # Jeśli funkcja zwróci 0, liczba nieprawidłowa
    
    # Wykonaj operację na podstawie zapisanego znaku
    lb $t1, charPlus
    beq $s0, $t1, doAddition
    
    lb $t1, charMinus
    beq $s0, $t1, doSubtraction
    
    lb $t1, charMultiply
    beq $s0, $t1, doMultiplication
    
    lb $t1, charDivide
    beq $s0, $t1, doDivision

# Funkcja sprawdzająca prawidłowość liczby
# Argument: $f0 - liczba do sprawdzenia
# Zwraca: $v0 = 1 jeśli liczba prawidłowa, 0 jeśli nieprawidłowa
checkIfNumberIsValid:
    # Sprawdź czy liczba to NaN (NaN != NaN)
    c.eq.d $f0, $f0
    bc1f returnNumberInvalid  # jeśli nie równe sobie, to NaN
    
    # Sprawdź czy liczba to 0.0. Jeśli tak, jest prawidłowa (i nie jest Inf).
    ldc1 $f2, doubleZero      # $f2 = 0.0
    c.eq.d $f0, $f2           # porównaj liczba z 0.0
    bc1t returnNumberValid    # jeśli liczba == 0.0, to jest prawidłowa

    # Liczba != 0.0. Sprawdź czy to nieskończoność (liczba * 2.0 == liczba)
    ldc1 $f8, doubleTwo       # $f8 = 2.0
    mul.d $f6, $f0, $f8       # $f6 = liczba * 2.0
    
    c.eq.d $f0, $f6           # porównaj liczba z (liczba * 2.0)
    bc1t returnNumberInvalid  # jeśli równe (i nie zero), to nieskończoność
    
# Liczba prawidłowa (nie NaN, nie Inf; 0.0 już obsłużone)
returnNumberValid:
    li $v0, 1
    jr $ra
    
returnNumberInvalid:
    li $v0, 0
    jr $ra

doAddition:
    li $v0, 4
    la $a0, additionText
    syscall
    
    add.d $f4, $f20, $f22     # $f4 = firstNum + secondNum
    j checkOperationResult

doSubtraction:
    li $v0, 4
    la $a0, subtractionText
    syscall
    
    sub.d $f4, $f20, $f22     # $f4 = firstNum - secondNum
    j checkOperationResult

doMultiplication:
    li $v0, 4
    la $a0, multiplicationText
    syscall
    
    mul.d $f4, $f20, $f22     # $f4 = firstNum * secondNum
    j checkOperationResult

doDivision:
    # Sprawdź dzielenie przez zero
    ldc1 $f6, doubleZero
    c.eq.d $f22, $f6
    bc1t handleErrorDivisionByZero
    
    li $v0, 4
    la $a0, divisionText
    syscall
    
    div.d $f4, $f20, $f22     # $f4 = firstNum / secondNum
    j checkOperationResult

checkOperationResult:
    # Sprawdź czy wynik jest prawidłowy
    mov.d $f0, $f4  # przygotuj argument
    jal checkIfNumberIsValid
    beq $v0, 0, handleErrorOverflow  # jeśli nieprawidłowy, pokaż błąd przepełnienia
    j displayResult

displayResult:
    # Wyświetl tekst wyniku
    li $v0, 4
    la $a0, resultText
    syscall
    
    # Wyświetl liczbę zmiennoprzecinkową podwójnej precyzji
    li $v0, 3
    mov.d $f12, $f4
    syscall
    
    j promptForContinuation

promptForContinuation:
getContinuationInput:
    # Zapytaj czy kontynuować
    li $v0, 4
    la $a0, continuePrompt
    syscall
    
    # Wczytaj odpowiedź
    li $v0, 12             # syscall dla wczytania chara
    syscall
    
    # Wczytaj pierwszy znak z bufora
    move $s1, $v0 # Zapisz odpowiedź w $s1
    
    # Sprawdź czy to 'T' lub 't' (tak)
    lb $t1, charTUpper
    beq $s1, $t1, main
    
    lb $t1, charTLower
    beq $s1, $t1, main
    
    # Sprawdź czy to 'N' lub 'n' (nie)
    lb $t1, charNUpper
    beq $s1, $t1, exitProgram
    
    lb $t1, charNLower
    beq $s1, $t1, exitProgram
    
    # Jeśli żaden nie pasuje, wyświetl błąd i pytaj ponownie
    li $v0, 4
    la $a0, errorContinue
    syscall
    j getContinuationInput

# Obsługa błędów
handleErrorInvalidChoice:
    li $v0, 4
    la $a0, errorInvalidChoice
    syscall
    j getOperation

handleFirstNumberError:
    li $v0, 4
    la $a0, errorNumberRange
    syscall
    j readFirstNumber

handleInvalidFirstInput:
    li $v0, 4
    la $a0, errorInvalidInput
    syscall
    j readFirstNumber # Wróć do wczytywania liczb

handleSecondNumberError:
    li $v0, 4
    la $a0, errorNumberRange
    syscall
    j readSecondNumber
    
handleInvalidSecondInput:
    li $v0, 4
    la $a0, errorInvalidInput
    syscall
    j readSecondNumber # Wróć do wczytywania liczb

handleErrorDivisionByZero:
    li $v0, 4
    la $a0, errorDivisionByZero
    syscall
    j promptForContinuation

handleErrorOverflow:
    li $v0, 4
    la $a0, errorOverflow
    syscall
    j promptForContinuation

exitProgram:
    
    # Zakończ program
    li $v0, 10
    syscall

# OBSŁUGA WYJĄTKÓW SYSTEMOWYCH

.kdata
    overflowKernelMessage: .asciiz "WYJATEK: Przepelnienie arytmetyczne wykryte przez procesor!\n"

.ktext 0x80000180
kernelEntry:
    # Pobierz wartość z rejestru przyczyny i skopiuj do $k0
    mfc0 $k0, $13
    
    # Maskuj wszystkie bity oprócz kodu wyjątku (bity 2-6)
    andi $k1, $k0, 0x00007c
    
    # Przesuń o dwa bity w prawo aby otrzymać kod wyjątku
    srl $k1, $k1, 2
    
    # Teraz $k0 = wartość rejestru przyczyny
    #       $k1 = kod wyjątku

handleException:
    # Sprawdź typ wyjątku na podstawie kodu w $k1
    # (wyjątek przepełnienia ma kod 12)
    beq $k1, 12, handleOverflowException
    
    # Inne wyjątki
    j handleGenericException

handleOverflowException:
    # Użyj systemowego wywołania MARS 4 (wydrukuj string)
    li $v0, 4
    la $a0, overflowKernelMessage
    syscall
    li $v1, 0 # 0 - wyjątek przepełnienie
    
    j returnFromException

handleGenericException:
    # Obsługa innych wyjątków
    li $v1, 1 # Zwracamy 1 - co będzie oznaczać wyjątek ogólny
    
    j returnFromException

returnFromException:
    # Gdy wystąpi wyjątek, wartość licznika programu ($pc)
    # jest automatycznie zapisywana w ECP (Exception Program Counter)
    # czyli rejestr $14 w Koprocesorze 0
    
    # Pobierz wartość ECP (adres instrukcji powodującej wyjątek)
    mfc0 $k0, $14
    
    # Zwiększ ECP o 4, aby przejść do następnej instrukcji
    # (unikamy zapętlenia na tej samej instrukcji)
    addi $k0, $k0, 4
    mtc0 $k0, $14
    
    # Użyj instrukcji eret (Exception Return) aby ustawić licznik programu
    # na wartość zapisaną w rejestrze ECP (rejestr 14 w koprocesorze 0)
    eret
