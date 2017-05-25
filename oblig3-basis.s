#########################
#OBLIGATORISK OPPGAVE 3 #
#PER CARLSEN            #
#INF2270                #
#########################

#For aa kompilere, bruk gcc -m32 oblig3-basis.s test-oblig3.c -o x
#For aa kjoere, bruk ./x
		.extern	fread, fwrite

	.text
	.globl	readbyte
 # Navn:	readbyte
 # Synopsis:	Leser en byte fra en binÃ¦rfil.
 # C-signatur: 	int readbyte (FILE *f)
 # Registre:
	
readbyte:
	pushl	%ebp		# Standard funksjonsstart
	movl	%esp,%ebp	#

	push	$0		# Lag plass til char c
	leal	0(%esp),%edx	# 

	pushl	8(%ebp)		# Push arg 4
	push	$1		# ..og 3
	push	$1		# ..og 2
	pushl	%edx		# ..og 1
	
	call	fread		# Les
	
	cmpl	$0,%eax		# Sjekk resultat fra fread
	jle	neg_status	# if(status <= 0) gaa til neg_status
	jmp	pos_status	# else

neg_status:			# return -1
	movl 	$-1,%eax
	jmp	ret

pos_status:			# return (int)c
	movl	16(%esp),%eax	# Flytt c til eax 
	jmp 	ret

ret:
	addl	$20,%esp
	popl	%ebp		# Standard
	ret			# retur.


	
	
	.globl	readutf8char
 # Navn:	readutf8char
 # Synopsis:	Leser et Unicode-tegn fra en binÃ¦rfil.
 # C-signatur: 	long readutf8char (FILE *f)
 # Registre:
	
readutf8char:
	pushl	%ebp		# Standard funksjonsstart
	movl	%esp,%ebp	#

	pushl	%esi		# Brukes som loop counter senere
	push 	8(%ebp)		# Legg parameter paa stakk
	call	readbyte	# Les 8 forste bit
	
	movl	%eax,%ebx	# Lagre originalverdi
	cmp	$-1,%ebx	# EOF
	jle	return		# Return -1

	shrl	$3,%ebx		# Shift 3 til hoyre
		
	cmpl	$30,%ebx	# Sjekk om 8 bit
	jge	read32bit	# Hopp til bolk for aa haandtere

	cmpl	$28,%ebx	# Sjekk om 16 bit
	jge	read24bit	# Hopp til bolk for aa haandtere

	cmpl	$24,%ebx	# Sjekk om 24 bit
	jge	read16bit	# Hopp til bolk for aa haandtere

	jmp	read8bit	# 32 bit

read32bit:
	movl	$3,%esi		# Loop counter
	andl	$7,%eax		# Fjerne fortegnsbit (11110)
	movl	%eax,%ebx	# Flytt returnverdi til ebx
	jmp 	readloop	# Hopp til loop

read24bit:
	movl	$2,%esi		# Loop counter
	andl	$15,%eax	# Fjerne fortegnsbit (1110)
	movl	%eax,%ebx	# Flytt returnverdi til ebx
	jmp 	readloop	# Hopp til loop
			
read16bit:
	movl	$1,%esi		# Loop counter
	andl	$31,%eax	# Fjerne fortegsbit (110)
	movl	%eax,%ebx	# Flytt returnverdi til ebx
	jmp 	readloop	# Hopp til loop
	
read8bit:
	addl	$4,%esp		# Standard
	popl	%esi
	popl	%ebp		# retur
	ret
	
readloop:
	call 	readbyte	
	andl	$63,%eax	# Fjerne fortegnsbit (10)
	sall	$6,%ebx		# Lag plass til 6 nye bit
	addl	%eax,%ebx	# Flytt over
	decl	%esi		# i--
	cmp	$0,%esi		# if(i==0){
	jz	return		# return }
	jmp 	readloop	# else <loop>

return:
	movl	%ebx,%eax	# Flytt svar til eax
	addl	$4,%esp		
	popl	%esi
	popl	%ebp		# Standard
	ret			# retur.



	

	.globl	writebyte
 # Navn:	writebyte
 # Synopsis:	Skriver en byte til en binÃ¦rfil.
 # C-signatur: 	void writebyte (FILE *f, unsigned char b)
 # Registre:
	
writebyte:
	pushl	%ebp		# Lagre forrige base pointer
	movl	%esp,%ebp	# Flytt til ebp siden esp endrer seg

	push	8(%ebp)		# Legg argument 4 på stakk
	push	$1		# Push arg 3
	push	$1		# ..og 2
	
	leal	12(%ebp),%eax	# Legg parameter 1 på stakk
	pushl	%eax
	
	call	fwrite		# Skriv
	
	addl	$16,%esp	# Flytt peker (rydd stakken)
	popl	%ebp		# Flytt forrige base pointer tilbake til ebp
	ret			# retur.

	
	.globl	writeutf8char
 # Navn:	writeutf8char
 # Synopsis:	Skriver et tegn kodet som UTF-8 til en binÃ¦rfil.
 # C-signatur: 	void writeutf8char (FILE *f, unsigned long u)
 # Registre:
	
writeutf8char:
	pushl	%ebp		# Standard funksjonsstart
	movl	%esp,%ebp	#

	cmpl 	$127,12(%ebp)	# 4 bit
	jle	write1b		# 

	cmpl 	$2047,12(%ebp)	# 8 bit
	jle	write2b		#

	cmpl 	$65535,12(%ebp)	# 12 bit
	jle	write3b		#

	jmp	write4b		# 16 bit (>12)

write1b:			# (00) 0 	- (7F) 127	
	push	12(%ebp)	# Returner samme tall som kommer inn. xxxx = 0xxxx
	push 	8(%ebp)
	call 	writebyte
	addl	$8,%esp
	popl	%ebp
	ret
	
write2b:			# (0080) 128 	- (07FF) 2047
	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	shrl	$6,%ebx		# Shift hoyre, ende opp med 5 forste bit
	addl	$192,%ebx	# Legg til 110
	push	%ebx		
	push	8(%ebp)
	call 	writebyte

	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	andl	$63,%ebx	# Null ut alt annet enn 6 siste bit
	addl	$128,%ebx	# Legg til 10
	push	%ebx
	push	8(%ebp)
	call 	writebyte

	addl	$16,%esp
	popl	%ebp
	ret			#return

write3b:			# (0800) 2048 	- (FFFF) 65535
	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	shrl	$12,%ebx	# Shift hoyre, ende opp med 4 forste bit
	addl	$224,%ebx	# Legg til 1110
	push	%ebx		
	push	8(%ebp)
	call 	writebyte

	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	shrl	$6,%ebx		# Bli kvitt bakerste bit
	andl	$63,%ebx	# Null ut alt annet enn 6 siste bit
	addl	$128,%ebx	# Legg til 10
	push	%ebx
	push	8(%ebp)
	call 	writebyte

	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	andl	$63,%ebx	# Null ut alt annet enn 6 siste bit
	addl	$128,%ebx	# Legg til 10
	push	%ebx
	push	8(%ebp)
	call 	writebyte

	addl	$24,%esp
	popl	%ebp
	ret			#return
	
write4b:			# (1000) 65536 	- (1FFFFF) 2097151
	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	shrl	$18,%ebx	# Shift hoyre, ende opp med 3 forste bit
	addl	$240,%ebx	# Legg til 11110
	push	%ebx		
	push	8(%ebp)
	call 	writebyte

	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	shrl	$12,%ebx	# Bli kvitt bakerste bit
	andl	$63,%ebx	# Null ut alt annet enn 6 siste bit
	addl	$128,%ebx	# Legg til 10
	push	%ebx
	push	8(%ebp)
	call 	writebyte

	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	shrl	$6,%ebx		# Bli kvitt bakerste bit
	andl	$63,%ebx	# Null ut alt annet enn 6 siste bit
	addl	$128,%ebx	# Legg til 10
	push	%ebx
	push	8(%ebp)
	call 	writebyte

	movl	12(%ebp),%ebx	# Flytt til ebx (spare originalverdi)
	andl	$63,%ebx	# Null ut alt annet enn 6 siste bit
	addl	$128,%ebx	# Legg til 10
	push	%ebx
	push	8(%ebp)
	call 	writebyte

	addl	$32,%esp
	popl	%ebp
	ret			#return
	
	
#sal - venstre (antall shift, register)
#shr - hoyre (antall shift, register)
	
#btr bts
