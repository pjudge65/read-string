TITLE String Primitives and Macros     (Proj6_judgep.asm)

; Author: Peter Judge
; Last Modified: 6/5/22
; OSU email address: judgep@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 6/5/22
; Description: This project contains procedures and macros that allow a user to convert a 
;              string array to an SDWORD representation, and vice versa. 
INCLUDE Irvine32.inc



;------------------------------------------------------------
; name: mGetString

; Takes user string input and saves it to a byte array

; Preconditions: NONE

; Receives:
; offset_prompt = OFFSET of byte string prompt to display before input
; user_input = address of byte array to save input at
; input_length = the length of the buffer allowed for input

; Returns: user inputted string saved to user_input
;          length of user input saved in bytes_read
;--------------------------------------------------------------------

mGetString	MACRO	offset_prompt, user_input, input_length, bytes_read
	;displays prompt by reference
	PUSH	EDX
	PUSH    ECX
	MOV		EDX, offset_prompt
	CALL	WriteString
	MOV		EDX, user_input
	; input_length is the number of non-terminator bytes possible to enter - must add 1 to incorporate terminator
	MOV		ECX, input_length
	CALL	ReadString
	MOV		bytes_read, EAX
	POP		ECX
	POP     EDX
ENDM

;------------------------------------------------------------
; name: mDisplayString

; Takes the address offset of a byte string and prints the string to console

; Preconditions: NONE

; Receives:
; string_print = address offset of string to print

; Returns:
; string printed to console
;--------------------------------------------------------------------
mDisplayString	MACRO	string_print
	PUSH	EDX
	MOV		EDX, string_print
	CALL	WriteString
	POP		EDX
ENDM

	
MAXSIZE = 33
MININPUT = -2147483648			;max values for 32 bit sdwords are -2^31 to 2^31-1
MAXINPUT = 2147483647
INPUTBUFFER = 16

.data
; (insert variable definitions here)

title_main			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,
							"Written by: Peter Judge",0
instruct_str		BYTE	"Please provide 10 signed decimal integers.",13,10,
							"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw",13,10,
							"numbers I will display a list of the integers, their sum, and their average value",0
input_prompt		BYTE	"Please enter a signed number: ",0
error_str			BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,
							"Please try again: ",0


input_str			BYTE	INPUTBUFFER DUP(0)		;user String
input_str_len		DWORD	?
array_inputs		SDWORD	10 DUP(0)				; array of strings to save user input on (to convert from and to ascii)
input_length_read	DWORD	?
neg_flag			SDWORD  0
output_str			BYTE	INPUTBUFFER DUP(0)



.code
main PROC

	mDisplayString	OFFSET title_main
	CALL			CrLf
	CALL			CrLf
	mDisplayString	OFFSET instruct_str
	CALL			CrLf



; Get 10 valid integers from the user using ReadVal in a loop 
	MOV		ECX, 10
	MOV		EDI, OFFSET array_inputs		;first values saved at the first element of array_inputs
_loop_input:
	PUSH	neg_flag
	PUSH	EDI
	PUSH	OFFSET error_str				
	PUSH	OFFSET input_prompt
	PUSH	OFFSET input_str
	PUSH	OFFSET input_length_read
	CALL	ReadVal
	ADD		EDI, 4							; iterate through EDI to populate the array with user inputs
	LOOP	_loop_input


; Display the integers
	MOV		ESI, OFFSET array_inputs
	PUSH	OFFSET output_str
	PUSH	ESI
	CALL	WriteVal
; Display the sum


	Invoke ExitProcess,0	; exit to operating system
main ENDP





;------------------------------------------------------------
; name: ReadVal

; uses the mGetString macro to get user input in the form of a string of digits
; Converts (using string primitives) the string of ascii digits to its numeric value representation (SDWORD)
; Validates that the user input is a valid number(no letters, symbols, etc)
; stores value in a memory variable

; Preconditions: NONE

; Receives:
; EBP + 8] =  OFFSET input_length_read
; [EBP+12] = OFFSET input_str
; [EBP+16] = OFFSET input_prompt
; [EBP + 20] = OFFSET error_str
; [EBP+24 = EDI (OFFSET array_inputs)		
; [EBP + 28] = value of neg_flag


; Returns: array_inputs array filled with user inputted values
;--------------------------------------------------------------------


ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	MOV		EDX, [EBP + 16]			; offset of prompt to write
	MOV		EDI, [EBP+24]			; memory location to save user input
	MOV		EBX, [EBP+8]			; input length (bytes_read)
	PUSH	ECX
	PUSH	ESI
	PUSH	EDI						; saves the inital value at EDI

	

_get_input:
	mGetString [EBP+16], [EBP+12], INPUTBUFFER, EBX
	

_continue_invalid:
	MOV		ESI, [EBP+12]			;offset input_str


	; loading up each ascii number
	MOV		ECX, EBX
	MOV		EBX, [EBP + 28]			; EBX = neg_flag

	; neg_flag behavior: 0 means we're checking first digit.
	;					 -1 means we've checked first digit and it's not negative
	;					 1 means we've checked first digit and it was negative

_process_string:
	CLD
	MOV		EAX, 0
	LODSB							;puts the first byte into AL

	CMP		EBX, 0
	JNE		_check_invalids		
							

	CMP		AL, 45					; checks if AL is equal to negative sign
	JNE		_check_invalids
	SUB		ECX, 1					; we need to move to next LODSB
	LODSB
	MOV		EBX, 1					; flags the negative sign 
	JMP		_neg_conversion

_check_invalids:
	CMP		AL, 48
	JL		_invalid
	CMP		AL, 57
	JG	    _invalid
	CMP		EBX, 1
	JE		_neg_conversion
	JMP		_conversion


_return_conv:

	LOOP	_process_string
	JMP		_end

_conversion:
	PUSH	EBX						; push the neg_flag status
	SUB		AL, 48
	PUSH	EAX						; saves AL value on the stack
	MOV		EAX, [EDI]				; we keep the 'numInt' value saved in our array. EAX = 'numInt'

	MOV		EBX, 10
	MOV		EDX, 0
	MUL		EBX						;EAX = (10*numInt) MUL Multiplies AL by the operand. Stores in AL
	CMP		EDX, 0
	JNE		_invalid

	MOV		EBX, EAX				; EBX = (10*numInt)
	POP		EAX
	ADD		EAX, EBX				;EAX = 10 * numInt + (numChar - 48)

	; if EAX overflows at this point, then the input is invalid
	JO		_invalid
	MOV		[EDI], EAX
	POP		EBX
	MOV		EBX, -1
	JMP		_return_conv

_neg_conversion:
	PUSH	EBX						;push neg_flag 
	SUB		AL, 48
	PUSH	EAX
	MOV		EAX, [EDI]
	MOV	    EBX, 10
	MOV		EDX, 0
	IMUL	EBX

	MOV		EBX, EAX
	POP		EAX
	SUB		EBX, EAX
	JO		_invalid
	MOV		[EDI], EBX
	POP		EBX						; pop neg_flag status into EBX

	JMP		_return_conv




_invalid:
	MOV		EDX, [EBP + 20]			;offset error_str

	PUSH	EBX
	MOV		EBX, 0
	MOV		[EDI], EBX
	MOV		ESI, EBX
	POP		EBX
	MOV		EDI, [EBP + 24]
	mGetString EDX, [EBP+12], INPUTBUFFER, EBX

	JMP _continue_invalid

_end:
	POP EDI
	POP ESI
	POP ECX
	POP EBP
	RET 28
ReadVal	ENDP



;------------------------------------------------------------
; name: WriteVal

; uses the mWriteString macro to print our user inputted string


; Preconditions: NONE

; Receives:
; EBP + 8] =  memory offset of SDWORD number representation to read from
; [EBP + 12] = memory offset of byte string array to write to

; Returns: SDWORD number printed to console as string
;--------------------------------------------------------------------

WriteVal	PROC
	PUSH	EBP
	MOV		EBP, ESP
	MOV		ESI, [EBP + 8]			;memory location to read from
	MOV		EDI, [EBP + 12]			;string to write to
	MOV		ECX, INPUTBUFFER

	MOV		EAX, [ESI]				;copies source number into EAX

	CMP		EAX, 0					; EAX holds the big SDWORD value

	SUB		ECX, 1
	ADD		EDI, ECX
	STD
_convert_to_ascii:
	MOV		EDX, 0
	MOV		EBX, 10					; divide by 10 in the algorithm
	DIV		EBX						; divide SDWORD by 10. SDWORD/10 in EAX, character in EDX
	ADD		EDX, 48					; EDX holds ascii representation of the letter'
	PUSH	EAX
	MOV		EAX, 0
	MOV		EAX, EDX
	STOSB
	POP		EAX
	LOOP	_convert_to_ascii


	mDisplayString [EBP + 12]


	POP		EBP
	RET		8
WriteVal	ENDP

END main
