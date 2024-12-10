.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD

INCLUDE Irvine32.inc
INCLUDE Macros.inc

.data
	BUFSIZE = 5000
	filename    BYTE	"text_blocks.txt", 0	; Name of the file to read
	filename2	BYTE	"words.txt", 0			
    text_block  BYTE	BUFSIZE DUP(0)			; Buffer to store file contents
	user_input	BYTE	BUFSIZE DUP(0)			; to store user input
    bytesRead   DWORD	?						; To store the number of bytes read
	correct_char BYTE	0
	WPM			BYTE	0
	ACCURACY	BYTE	0
	
	start_time	DWORD	?
	end_time	DWORD	?
	prev_time	DWORD	?

	max_row		BYTE	?
	max_col		BYTE	?

	max_words = 15
	rows_apart = 4
	wait_time = 350			; time delay between each words falling
	words		BYTE	"hello", 0, "waterbottle", 0, "great", 0 ,"computer", 0, "assembly", 0, "fields", 0, "clear", 0, "blue", 0, "sky", 0, "gentle", 0, 
						"winds", 0, "whispered", 0, "through", 0, "golden", 0, "stalks", 0
	rows		SBYTE	max_words DUP(0)
	cols		BYTE	max_words DUP(0)
	game_over	BYTE	0
	correct_char1 BYTE	0
	target_word	BYTE	0
	last_score	BYTE	0
	high_score	BYTE	0

.code
main PROC
start:
	call	Randomize				; Seeds random number generator
	mov		eax, 0
	
	mWriteLn "(1) Basic Typing Test"
	call	Crlf
	mWriteLn "(2) Typing Game"
	call	Crlf
	mWriteLn "(3) Show Statistics"
	call	Crlf
	mWrite	"Enter your selection: "

	call	ReadInt					; stores the user input in al
	call	MyGetMaxXY				; stores max xy value into max_row and max_col

	cmp		eax, 1					; run basic typing test program
	je		btt
	cmp		eax, 2					; run falling words game program
	je		tg
	cmp		eax, 3					; run falling words game program
	je		stat
	cmp		eax, 27					
	je		quit
	mWriteLn "Invalid Selection."	; when user inputs anything else other than 1 and 2
	jmp		quit					; quits the program

btt: 
	call	Clrscr
	call	basic_typing_test
	call	Clrscr
	jmp		stat
tg:
	call	Clrscr
	call	typing_game
stat:
	call	show_statistics
	call	Crlf
	mWriteLn "Press ESC to exit..."
	mWriteLn "Press anything to go back to menu..."

LookForKey:
	mov		eax, 100
	call	Delay
	call	ReadKey
	jz		LookForKey
	cmp		al, 27
	je		quit
	call	Clrscr
	jmp		start

quit:
	call	Clrscr
	call	CloseFile					; Close the file
	INVOKE ExitProcess, 0
main ENDP

MyGetMaxXY PROC
	; ---- initialize max_row and max_col ----
	push	eax
	push	edx

	call	GetMaxXY				; al = max_row, dl = max_col
	mov		max_row, al
	mov		max_col, dl		
	
	pop		edx
	pop		eax
	ret
MyGetMaxXY ENDP

; --------------- BASIC TYPING TEST PROGRAM 
basic_typing_test PROC
	; Open the file
    mov		edx, OFFSET filename		; Address of the file name
    call	OpenInputFile				; Opens the file for reading

    mov		ecx, BUFSIZE				; Address of the text_block
    mov		edx, OFFSET text_block			; Size of the text_block
    call	ReadFromFile				; Read data from the file
	jc		show_error_message			; jump if there is an error in reading file
	jmp		no_error
show_error_message:
	mWriteLn "ERROR IN READING THE FILE"
	jmp		exit_program
no_error:
    mov		bytesRead, eax				; Store the number of bytes read
    ; Close the file
    mov		edx, ebx					; File handle

    ; Display the contents of the text_block
    mov		edx, OFFSET text_block		; Address of the text_block
    call	WriteString					; Output the string

	; store the start time
	call	GetMseconds
	mov		start_time, eax

	mov		esi, OFFSET text_block
	mov		edi, OFFSET user_input
	mGotoxy 0,0
gameloop:
LookForKey:
	mov		eax, 10
	call	Delay
    call	ReadKey         ; look for keyboard input
    jz		LookForKey      ; no key pressed yet

	cmp		al, 8			; is a backspace
	je		backspace
	cmp		al, 1Bh			; is ESC key
	je		exit_program
	mov		[edi], al
	inc		edi
	call	print_text
	jmp		nobackspace
backspace:
	cmp		edi, OFFSET user_input		; Ensure edi doesn't go out of bounds
    jle		nobackspace
	dec		edi
	mov		BYTE PTR [edi], 0

	call	print_text
	jmp		nobackspace
nobackspace:
	mov		eax, edi
	sub		eax, OFFSET user_input
	cmp		eax, bytesRead
	jb		gameloop
	call	GetMseconds
	mov		end_time, eax

exit_program:
	mov		eax, white+(black*16)
	call	SetTextColor
	call	Crlf
	call	calc_stat

	; clear user_input buffer
	mov		edx, OFFSET user_input
	cmp		BYTE PTR [edx], 0
	je		finish
	mov		BYTE PTR [edx], 0
	inc		edx
finish:

	ret
basic_typing_test ENDP


print_text PROC
	pushad
	mov		dx, 0				; dh=row, dl=col
	mGotoxy	dl, dh
	mov		ebx, 0
	push	eax					; in case if al = backspace
print:
	mov		al, user_input[ebx]
	cmp		al, 0				; if there's nothing to print from start
	je		skip_print

	cmp		al, text_block[ebx]		; compare the user input with text
	jne		incorrect

	mov		eax, green+(black*16)
	jmp		skip_incorrect
incorrect:
	mov		eax, red+(black*16)
skip_incorrect:
	call	SetTextColor
	mov		eax, 0
	mov		al, user_input[ebx]
	call	WriteChar

	inc		dl
	cmp		dl, max_col
	ja		updaterow
	jmp		noupdaterow
updaterow:
	inc		dh
	mov		dl, 0
noupdaterow:

	inc		ebx
	cmp		user_input[ebx], 0
	jne		print
skip_print:
	pop		eax
	cmp		al, 8h					; if backspace is pressed
	je		backspace
	jmp		notbackspace
backspace:
	mov		eax, white+(black*16)
    call	SetTextColor
    mov		eax, 0
    mov		al, text_block[ebx]
    call	WriteChar
	mGotoxy dl, dh
notbackspace:
	popad
	ret
print_text ENDP

; -- calculates the stat
calc_stat PROC
    mov     edx, 0					; index for user_input
    mov		ecx, 0					; count of total characters typed

L1:
	mov		al, user_input[edx]
    cmp     user_input[edx], 0		; check for null terminator
    je      done_loop				; exit loop if end of input
    inc     ecx						; increment total character count

    cmp     al, text_block[edx]			; compare input with reference
    jne     incorrect				; jump if incorrect
    inc     correct_char			; increment correct character count

incorrect:
    inc     edx						; move to the next index
    jmp     L1						; repeat the loop

done_loop:
	push	ecx

    ; Calculate WPM
    mov     eax, end_time
    sub     eax, start_time			; calculate elapsed time
    mov     ecx, 60000				; convert milliseconds to minutes
    div     cl

	mov		ebx, 0
    mov     bl, al				; store minutes elapsed in ebx
    mov		al, correct_char
	mov		ah, 0
    mov     cl, 5
    div     cl						; calculate words (chars/5)
	mov		ah, 0
    div     bl						; calculate WPM (words/minutes)
    mov     WPM, ah					; store the result in WPM

	pop		ecx						; total characters typed
    ; Calculate accuracy
	mov		eax, 0
    mov		al, correct_char
    test    ecx, ecx				; check if total characters are zero
    je      handle_zero_chars		; handle edge case if no input
    div     cl						; correct / Total = Accuracy

	cmp		al, 1					; store quotient:remainder (al:ah)
	je		hundredpercent
	mov		ACCURACY, ah
	jmp		nothundred
hundredpercent:
	mov		ACCURACY, 100
nothundred:
    jmp     finish

handle_zero_chars:
    mov     ACCURACY, 0

finish:
    ; Display results
    mWrite	"Words Per Minute: "
	movzx	eax, WPM
    call	WriteDec
    call	Crlf

    mWrite	"Accuracy: "
	movzx	eax, ACCURACY
    call	WriteDec
    mWrite	"%"
    call	Crlf

	ret
calc_stat ENDP


; --------------- TYPING GAME PROGRAM 
typing_game PROC
	mov		last_score, 0
	mov		game_over, 0
	mov		target_word, 0

	call	GetMseconds
	mov		start_time, eax
	mov		prev_time, eax

	; initialize columns
	mov		ecx, 0
init_col:
	mov		eax, ecx
	mov		edx, OFFSET words
	call	count_size
	mov		al, max_col
	sub		eax, ebx
	call	RandomRange
	mov		cols[ecx], al

	inc		ecx
	cmp		ecx, max_words
	jb		init_col

	; initialize rows  - inc row every 'word_wait' miliseconds
	; rows apart can be depending on the max_words
	mov		ecx, 0
	mov		eax, 0
init_row:
	mov		rows[ecx], al
	inc		ecx
	sub		al, rows_apart

	cmp		ecx, max_words
	jb		init_row

	mov		edi, OFFSET user_input
gameLoop:
	mov		eax, 10
	call	Delay
	call	ReadKey
	jz		LookForKey			; no key pressed yet
	mov		BYTE PTR [edi], al

	cmp		al, 8h				; is backspace
	je		backspace
	inc		edi
	jmp		nobackspace
backspace:
	mov		BYTE PTR [edi], 0
	cmp		edi, OFFSET user_input		; backspace is pressed at the start of word
	je		LookForKey
	dec		edi
	mov		BYTE PTR [edi], 0

	cmp		BYTE PTR user_input[0], 0
	jne		nobackspace
	call	set_new_target

nobackspace:
	call	print_words
LookForKey:
	call	GetMseconds
	mov		ebx, eax
	sub		eax, prev_time
	cmp		eax, wait_time
	jb		gameLoop

	mov		prev_time, ebx
	call	print_words

	call	update_rows

	cmp		game_over, 0
	je		gameLoop

	; update highscore
	mov		al, last_score
	cmp		al, high_score
	jbe		nohighscore
	mov		high_score, al
nohighscore:
	ret
typing_game ENDP

update_rows PROC
	; update rows
	mov		ecx, 0
update:

	; if it touches the ground, it's game over
	mov		bl, rows[ecx]
	cmp		bl, max_row
	jne		gameContinue
	mov		game_over, 1
gameContinue:
	inc		rows[ecx]
	inc		ecx
	cmp		ecx, max_words
	jb		update
	ret
update_rows ENDP

; --- print all the words at their corresponding positions
print_words PROC
	call	Clrscr

	push	edx
	push	ecx
	push	ebx
	push	eax

	call	set_new_target
	mov		ecx, 0				; keeps track of the words
printing:
	mov		edx, OFFSET words
	mov		eax, ecx			; parameter as n-th word, later, store count_size
	call	count_size

	cmp		rows[ecx], 0		; if row is a negative number, skip printing
	jl		skip_print

	; print the characters of the word
	mGotoxy cols[ecx], rows[ecx]
	call	WriteString

	; skip the entire printChar loop, if it's other than the target word
	cmp		cl, target_word
	jne		skip_print

	mov		eax, ebx				; store size of the word in eax
	mov		ebx, 0
	mov		correct_char1, 0
printChar:
	cmp		user_input[ebx], 0
	je		skip_print

	push	eax						; store size of the word in stack
	mov		eax, ebx
	add		al, cols[ecx]
	mGotoxy al, rows[ecx]

	mov		eax, 0
	mov		al, BYTE PTR [edx]
	cmp		al, user_input[ebx]
	je		correct
	mov		eax, red+(black*16)
	call	SetTextColor
	jmp		incorrect
correct:
	inc		correct_char1
	mov		eax, green+(black*16)
	call	SetTextColor
incorrect:
	pop		eax						; retrieve word size for a moment
	push	eax
	cmp		ebx, eax
	mov		eax, 0
	mov		al, user_input[ebx]
	call	WriteChar

skipbackspace:
	mov		eax, white+(black*16)
	call	SetTextColor

	inc		edx
	inc		ebx
	pop		eax							; retrieve the size of the word
	cmp		ebx, eax
	jb		printChar

	; the correct chars have to match the word size to successfully delete a word
	cmp		correct_char1, al			; eax still has the word size
	jne		skip_print					; you are not done for this word
	inc		last_score

	; deleting the word, update it with new one
	; find smallest row value in rows, subtract it with rows_apart, and assign it as new row to new word
	push	eax							; saving word size in stack for later
	push	ecx							; making sure ecx value is not lost
	mov		ecx, 0
	mov		al, rows[ecx]
smallestRow:
	cmp		al, rows[ecx]
	jle		noupdate
	mov		al, rows[ecx]
noupdate:
	inc		ecx
	cmp		ecx, max_words
	jb		smallestRow
	pop		ecx							; retrieve ecx value
	; I should have smallest row value in eax here
	sub		al, rows_apart
	mov		rows[ecx], al

	; randomizing the column again
	pop		eax							; retrieve word size into eax again
	mov		ebx, eax
	mov		al, max_col
	sub		eax, ebx					; max_column - word_size
	call	RandomRange
	mov		cols[ecx], al				; stores new random column value

	; change the word to something else here


	; empty your user_input 
	push	ecx
	mov		ecx, 0
emptyBuffer:
	mov		BYTE PTR user_input[ecx], 0
	inc		ecx
	cmp		user_input[ecx], 0			; clear everything until null char reached
	jne		emptyBuffer
	mov		edi, OFFSET user_input
	pop		ecx

	; set a new target
	call	set_new_target

skip_print:
	inc		ecx
	cmp		ecx, max_words
	jb		printing

	pop		eax
	pop		ebx
	pop		ecx
	pop		edx
	ret
print_words ENDP

set_new_target PROC
	pushad

	; if user_input[0] is blank, just...
	; set new target based on the word with highest row (most bottom place)
	cmp		user_input[0], 0
	je		done
	cmp		user_input[1], 0
	jne		done

	; if user_input[0] is not blank, 
	; find target based on what word matches the first char
	; if you can't, go with the bottom-most word

	call	find_bottom_most
	mov		bl, target_word		; if you start from target_word and rotate right, each word's row will be decreasing (from bottom to top) 
	mov		ecx, max_words
finding:
	cmp		rows[ebx], 0
	jl		notfound				; do not consider targetting words with negative row
	push	ebx
	mov		eax, ebx				; eax = n-th word
	mov		edx, OFFSET words
	call	count_size				; returns edx at the start of n-th word
	pop		ebx
	
	mov		al, user_input[0]
	cmp		al, BYTE PTR [edx]
	jne		notfound
	mov		target_word, bl
	jmp		done
notfound:
	inc		ebx
	cmp		ebx, max_words
	jne		no_reset_ebx
	mov		ebx, 0					; resets ebx to rotate back to start of array
no_reset_ebx:
	loop	finding
	
done:
	popad
	ret
set_new_target ENDP

; RETURN:	index of bottom most word stored in target_word
find_bottom_most PROC
	mov		ebx, 0						; index of word with max row
	mov		ecx, 0						; index of word
	mov		eax, 0						; placeholder
find:
	mov		al, rows[ecx]
	cmp		al, rows[ebx]				; if rows[ecx] > rows[ebx] 
	jle		noupdate					;		ebx = ecx
	mov		ebx, ecx
noupdate:
	inc		ecx
	cmp		ecx, max_words
	jb		find
	mov		target_word, bl
	ret
find_bottom_most ENDP

; Parameters: EAX = N-th Word
;			  EDX = ptr to the start of words array
; Return:	  EBX = size of the word
; Extra:	It leaves your edx at the start of the n-th word
count_size PROC
	; make edx pointing to the n-th word
	push	ecx
	cmp		eax, 0
	je		firstWord
	mov		ecx, 0
countloop:
	cmp		BYTE PTR [edx], 0
	jne		nextChar
	inc		ecx
nextChar:
	inc		edx
	cmp		ecx, eax
	jb		countloop
firstWord:
	
	push	edx
	; count the size of the word
	mov		ebx, 0
	cmp		BYTE PTR [edx], 0			; nothing exist
	je		quit
counting:
	inc		ebx
	inc		edx
	cmp		BYTE PTR [edx], 0
	jne		counting

quit:
	pop		edx
	pop		ecx
	ret
count_size ENDP



; --------------- SHOW STATISTICS PROGRAM
show_statistics PROC
	call	Clrscr
	; Display results
	mWriteLn "<Basic Typing Test>"
    mWrite	"Words Per Minute: "
	movzx	eax, WPM
    call	WriteDec
    call	Crlf

    mWrite	"Accuracy: "
	movzx	eax, ACCURACY
    call	WriteDec
    mWrite	"%"
    call	Crlf
	call	Crlf

	mWriteLn "<Falling Word Game>"
	mWrite	"High Score: "
	mov		al, high_score
	call	WriteDec
	call	Crlf
	mWrite	"Last Score: "
	mov		al, last_score
	call	WriteDec
	call	Crlf

	ret
show_statistics ENDP

END main
