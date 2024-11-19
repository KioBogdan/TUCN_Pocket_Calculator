.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;we include libraries and declare which functions to import
includelib msvcrt.lib
extern exit: proc
extern printf: proc
extern scanf: proc
extern strchr: proc
extern sscanf: proc
extern strlen: proc
extern gets: proc
extern strcmp: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;we declare the start symbol as public – this is where execution begins
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;program sections, data, and code
.data
format DB  13,10, "Introduceti o expresie:",13,10,0
formatE DB "Eroare! Expresie invalida",0
formatEA DB "Eroare! Impartire la zero!",0
formatIntroducere DB "Calculator de buzunar. Operatii implementate: +, -, *, /",0

formatOP DB "+-*/", 0
formatST DB "%s", 0
formatCitire2 DB "%d%c", 0
formatI DB "%d", 0
formatC DB "%c", 0
formatCitire DB "%c%d", 0
terminare_program DB "exit", 0

det_test DB 0
stare_curenta DB 0
stare_poz_2_stiva DB 5
stare_bot_stiva DB 0
er_z DB 0
nr_op DB 0
op DD 0
num DD 0
rez DD 0
rez_interm DD 0
string DB 0
.code

call_1_arg macro m,n
	push n
	call m
	add ESP, 4
endm

call_2_arg macro m,n,o
	push o
	push n
	call m
	add ESP, 8
endm

call_3_arg macro m,n,o,p
	push p
	push o
	push n
	call m
	add ESP, 12
endm

call_4_arg macro m,n,o,p,q
	push q
	push p
	push o 
	push n 
	call m 
	add ESP, 16
endm

operation proc
	xor EAX, EAX
	xor ECX, ECX
	pop ECX ;we retain the return address
	pop EAX
	push ECX ;and we bring it back in stack
	cmp EAX, 3Dh
	je equal
	cmp EAX, 2Bh
	je adding
	cmp EAX, 2Dh
	je substracting
	cmp EAX, 2Ah
	je multiplying
	mov stare_curenta, 4 ;operatorul /
	jmp fixing
equal:
	mov stare_curenta, 2 ;operatorul =
	jmp fixing
	
adding:
	mov stare_curenta, 0 ;operatorul +
	jmp fixing
	
substracting:
	mov stare_curenta, 1 ;operatorul -
	jmp fixing
	
multiplying:
	mov stare_curenta, 3 ; operatorul *
	
fixing:
	ret 
operation endp

;addition
adunare proc
	xor EAX, EAX
	xor EBX, EBX
	xor ECX, ECX
	pop ECX ;retinem adresa de intoarcere
	pop EAX
	pop EBX
	push ECX ;si o aducem inapoi in stiva
	add EAX, EBX
	mov rez_interm, EAX
	ret 
adunare endp

;multiplication
inmultire proc
	xor EAX, EAX
	xor EBX, EBX
	xor ECX, ECX
	pop ECX ;retinem adresa de intoarcere
	pop EAX
	pop EBX
	push ECX ;si o aducem inapoi in stiva
	mul EBX ;EAX = EAX*EBX
	mov rez_interm, EAX
	ret 
inmultire endp

;substraction
scadere proc
	xor EAX, EAX
	xor EBX, EBX
	xor ECX, ECX
	pop ECX ;retinem adresa de intoarcere
	pop EBX
	pop EAX
	push ECX ;si o aducem inapoi in stiva
	sub EAX, EBX
	mov rez_interm, EAX	
	ret 
scadere endp

;division
impartire proc
	xor EAX, EAX
	xor EBX, EBX
	xor ECX, ECX
	pop ECX ;we store the return address
	pop EBX
	pop EAX
	push ECX ;and we bring it back in the stack
	cmp EBX, 0
	je error_zero
	xor EDX, EDX
	cmp EAX, 0
	jl impart_neg ;we have division with sign
	div EBX ; EAX=EAX/EBX
	jmp zip
impart_neg:
	cdq ;loading the sign into the EDX register
	idiv EBX
zip:
	mov rez_interm, EAX
	jmp f
error_zero:
	mov er_z, 1
f:
	ret
impartire endp

calcul_operatie proc
	push EBP
	mov EBP, ESP
	xor EDI, EDI
	mov EDI, [EBP+8]
	xor ESI, ESI
	mov er_z, 0
	mov stare_curenta, 0
	mov stare_poz_2_stiva, 5
	mov stare_bot_stiva, 0 ;reinitializing the states
	
	call_3_arg sscanf, EDI, offset formatC, offset op ;we read a single character
	
	xor EAX, EAX
	mov EAX, op
	cmp op, 30h
	jl inceput_operatie
	cmp op, 39h
	jg inceput_operatie ;we compare the character with a digit; if it is not a digit, it means the expression starts with an operator
	
	call_4_arg sscanf, EDI, offset formatCitire2, offset num, offset op ;in this case, the expression begins with a number
	jmp next_op
	
	;otherwise, we push the value from res onto the stack and compute the specific operator
inceput_operatie:	
	mov EDI, [EDX]
	xor EAX, EAX
	mov EAX, rez
	push EAX 
	
	xor EAX, EAX
	mov EAX, op
	push EAX
	call operation ;call operation
	
	xor EAX, EAX
	mov AL, stare_curenta
	mov stare_bot_stiva, AL
	cmp stare_bot_stiva, 2
	jg prioritate_continua
	
	jmp calcul
	
next_op:
	mov rez, 0
	mov EDI, [EDX]
	xor ECX, ECX
	mov ECX, num
	push ECX
	
	xor EAX, EAX
	mov EAX, op
	push EAX
	call operation ;call operation

	xor EAX, EAX
	mov AL, stare_curenta
	mov stare_bot_stiva, AL ;we modify the states accordingly
	
	cmp stare_curenta, 2
	jg prioritate_continua ;we are dealing with a priority operator, so everything that follows will take precedence in the calculation
	cmp stare_curenta, 2
	je iesire_calcul ;we exit if we encounter the character equals '=' 
	
calcul:
	call_4_arg sscanf, EDI, offset formatCitire2, offset num, offset op ;we read in the format 'number operator'
	
	mov EDI, [EDX]
	xor EAX, EAX
	mov EAX, op
	push EAX
	call operation ;call operation
	
	xor EAX, EAX
	mov EAX, num
	push EAX ;we push the read value onto the stack
	
	xor EAX, EAX
	mov AL, stare_curenta
	mov stare_poz_2_stiva, AL ;change the states accordingly
	
	cmp stare_curenta, 2
	jg prioritate_continua ;we continue the prioritization criteria in the overall calculation
	cmp stare_curenta, 2
	je iesire_calcul ;we encountered equal character '=', jump to the end
	
	cmp stare_bot_stiva, 1
	je scadere_2_1 ;we reach this step if there is no higher-priority operator; now we define the operation

	;addition 
	call adunare
	jmp over_scadere
	
scadere_2_1:
	;substraction
	call scadere
over_scadere:
	mov stare_poz_2_stiva, 5 ;we reset the state of the second position in the stack
	xor EAX, EAX
	mov AL, stare_curenta
	mov stare_bot_stiva, AL ;change the states accordingly
	
	xor EAX, EAX
	mov EAX, rez_interm
	push EAX ;push on stack the resulted value
	jmp calcul
	
prioritate_continua:	
	call_4_arg sscanf, EDI, offset formatCitire2, offset num, offset op ;we read in the format 'number operator'
	
	mov EDI, [EDX]
	xor EAX, EAX
	mov EAX, num
	push EAX
	cmp stare_poz_2_stiva, 5 ;we don't have a second number; we check what would follow next
	je zulu
	cmp stare_poz_2_stiva, 3 ;otherwise, we determine the operation (* or /) 
	je inmultire_2
	;impartire
	call impartire
	jmp after
	
inmultire_2:
	call inmultire
	;inmultire
	jmp after
zulu:
	cmp stare_curenta, 3 ;what follows to be pushed onto the stack is a priority; we determine the operation.
	je inmultire_2
	call impartire
	;impartire
	
after:
	xor EAX, EAX
	mov EAX, op
	push EAX
	call operation ;call operation
	
	cmp stare_poz_2_stiva, 5 ;the case where we perform a calculation with only 2 elements on the stack
	je not_yet
	xor EAX, EAX
	mov AL, stare_curenta
	mov stare_poz_2_stiva, AL ;change the states accordingly
	jmp jul
not_yet:
	xor EAX, EAX
	mov AL, stare_curenta
	mov stare_bot_stiva, AL ;change the states accordingly
jul:	
	xor EAX, EAX
	mov EAX, rez_interm
	push EAX
	cmp stare_curenta, 2
	jg prioritate_continua ;the operator is prioritized, we continue reading
	
	cmp stare_curenta, 2
	je iesire_calcul ;we encountered the equals character '=', exit 
	cmp stare_poz_2_stiva, 5 
	je calcul ;we don't have 2 numbers entered on the stack, continuing to read
	cmp stare_bot_stiva, 1 
	je scadere_2 ;otherwise, we have 2 elements with + or - operators; we determine the operation
	;addition 
	call adunare
	jmp after_decrease
scadere_2:
	;substraction
	call scadere
after_decrease:
	xor EAX, EAX
	mov EAX, rez_interm
	push EAX ;retin pe stiva rezultatul 
	
	xor EAX, EAX
	mov AL, stare_curenta
	mov stare_bot_stiva, AL
	mov stare_poz_2_stiva, 5 ;change the states accordingly 
	jmp calcul 

iesire_calcul:
	cmp stare_poz_2_stiva, 2 ;at the output, there are two cases: either we had a partial value already stored on the stack and now store the last number from the expression
	;either the expression consisted of operands with the same value (only + and -; or only * and /); in this case, we have a single value stored on the stack
	jne out_fortat
	cmp stare_bot_stiva, 1
	je scadere_2_2
	
	;addition
	call adunare
	xor EAX, EAX
	mov EAX, rez_interm
	mov rez, EAX
	jmp af
	
scadere_2_2:
	;substraction 
	call scadere
	xor EAX, EAX
	mov EAX, rez_interm
	mov rez, EAX
	jmp af
out_fortat:
	xor EAX, EAX
	pop EAX
	mov rez, EAX
af:
	mov ESP, EBP
	pop EBP
	ret 4
calcul_operatie endp

;string checking
verificare proc
	push EBP
	mov EBP, ESP
	xor EDI, EDI
	mov EDI, [EBP+8]
	xor ESI, ESI
	
read:
	xor EAX, EAX
	xor ECX, ECX
	xor EDX, EDX
	xor EBX, EBX
	
	call_3_arg sscanf, EDI, offset formatC, offset op ;we read a single character
	
	push EDX ;we retain the pointer to the string after reading a character
	
	cmp op, 30h ;we check if the character read is a digit; if not, the expression starts with an operator
	jl ver_operator
	cmp op, 39h
	jg ver_operator
	pop EDX ;pop the old value from the stack, as the expression starts with an operator
	jmp next

ver_operator:
	xor EAX, EAX
	mov EAX, op
	push EAX
	xor EAX, EAX
	push offset formatOP
	call strchr
	add ESP, 8
	cmp EAX, 0 ;check if the character represents an operator; if not, it's an error
	je iesire
	
	;it's a valid operator, we continue reading
	xor EAX, EAX
	mov AL, nr_op
	add AL, 1
	mov nr_op, AL ;we count the operators, including the equals sign
	
	xor EDX, EDX
	pop EDX ;retain the pointer to the current position in the string after reading with the specified format
	mov EDI, [EDX]
	
next:
	xor EAX, EAX
	xor EDX, EDX
	call_3_arg sscanf, EDI, offset formatC, offset op ;read a single character and check if it is a digit
	
	cmp op, 30h
	jl iesire
	cmp op, 39h
	jg iesire ;error, we exit completely
	
	xor EDX, EDX
	call_4_arg sscanf, EDI, offset formatCitire2, offset num, offset op ;we read in the format 'number operator'
	
	push EDX ;store the pointer to the string after reading with the format
	
	cmp EAX, 2
	jl iesire ;we exit the check if it was not formatted correctly
	xor EAX, EAX
	push [EDX]
	call strlen
	add ESP, 4 
	cmp EAX, 0 ;we reached the last reading of 'number operator', and check if the operator is equal to '='
	je ver_sf
	
	;the part of validating the character corresponding to the operation
	xor EAX, EAX
	mov EAX, op
	push EAX
	xor EAX, EAX
	push offset formatOP
	call strchr
	add ESP, 8
	cmp EAX, 0
	je iesire
	xor EAX, EAX
	mov AL, nr_op
	add AL, 1
	mov nr_op, AL
	jmp salt_sir
	
ver_sf:
	cmp op, 3Dh
	jne iesire
	mov det_test, 1
	xor EAX, EAX
	mov AL, nr_op
	add AL, 1
	mov nr_op, AL
	jmp iesire
	
	;jump in the string
salt_sir:
	xor EDX, EDX
	pop EDX	
	mov EDI, [EDX]
	jmp next
	
iesire:
	mov ESP, EBP
	pop EBP
	ret 4
verificare endp 

;; main
start:
	call_1_arg printf, offset formatIntroducere ;introduction
	
citire:
	mov det_test, 0
	mov nr_op, 0
	
	call_1_arg printf, offset format ;menu
	
	;call_2_arg scanf, offset formatST, offset string
	call_1_arg gets, offset string ;string reading
	
	xor EAX, EAX
	call_2_arg strcmp, offset terminare_program, offset string ;comparing with exit string
	
	cmp EAX, 0
	je exit ;exiting the program
	
	push offset string
	call verificare ;string checking
	
	cmp det_test, 1
	je corect
	
failure:
	call_1_arg printf, offset formatE ;the expression is invalid
	jmp fin1
	
corect:
	cmp nr_op, 1 ;we cover the error: 33=
	jle failure
	push offset string
	call calcul_operatie
	cmp er_z, 1
	je eroare_zero
	xor EAX, EAX
	mov EAX, rez
	
	call_2_arg printf, offset formatI, EAX ;print the result

	jmp fin1
	
eroare_zero:
	call_1_arg printf, offset formatEA; division by zero error
	
fin1:
	jmp citire
	;end of program
	push 0
	call exit
end start
