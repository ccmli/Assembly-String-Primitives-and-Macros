TITLE String Primitives and Macros     (String_Primitives_and_Macros.asm)

; Description: This program implements string processing macros and procedures to 
;              handle user input and display, as well as conversion of ASCII strings 
;              to numeric values and vice versa. It includes macros "mGetString" to 
;              retrieve user input and "mDisplayString" to display strings. 
;              Additionally, procedures "ReadVal" and "WriteVal" are implemented to 
;              convert between ASCII strings and numeric values. The main test program
;              utilizes these procedures to gather and display 10 valid integers, 
;              computing their sum and average, while adhering to parameter passing 
;              conventions, proper memory addressing, and code organization. The program
;              ensures input validation, error handling, and efficient memory management 
;              through the use of macros and procedures.

INCLUDE Irvine32.inc

; Macro definitions

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt, reads a string from the user input, and stores it in memory.
;
; Preconditions: All arguments must be initialized.
;
; Receives:
;   promptAdd: Address of the prompt message to display.
;   inputAddr: Address where the user input string will be stored.
;   maxLen: Maximum length of the input string to read.
;	charEnter: number of characters entered
;
; Returns:
;	inputAddr			: The user input is stored at the corresponding address offset.
;	charEnter			: The number of characters entered by the user.
; -----------------------------------------
mGetString	MACRO promptAddr:REQ, inputAddr:REQ, maxLen:REQ, charEnter:REQ
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX

	mDisplayString	promptAddr
	MOV	EDX, inputAddr
	MOV	ECX, maxLen
	CALL	ReadString
	MOV	charEnter, EAX			; Store the number of characters entered

	POP	EAX
	POP	ECX
	POP	EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays a null-terminated string to the console.
;
; Preconditions: The argument string must be initialized.
;
; Receives:
;   strAddr: Address of the null-terminated string to be displayed.
;
; -----------------------------------------
mDisplayString	MACRO strAddr:REQ
	PUSH	EDX
	MOV	EDX, strAddr
	CALL	WriteString
	POP	EDX
ENDM

; Constant
MAX_INPUT_LEN = 12
MAX_INPUT = 10

.data
intro_1			BYTE	"Project 6: Designing low-level I/O procedures by Chungman Chan",10,0
intro_2			BYTE	"Please enter 10 signed decimal integers, ensuring that each number is within the range of a 32-bit register. ",10,0
intro_3			BYTE	"Once you've entered the numbers, the program will generate a list showing the integers, their total sum, and their average value.",10,0
extraCred		BYTE	"**EC1: Number each line of user input and display a running subtotal of the user’s valid numbers. These displays must use WriteVal. (1 pt)",10,0
prompt			BYTE	"Please enter an signed number: ",0
retry			BYTE	"Please try again: ",0
error			BYTE	"ERROR: The input is invalid or the number is too large! ",10,0
resultArr		BYTE	10,"You entered numbers:",0
resultSum		BYTE	"The sum of numbers: ",0
resultAvg		BYTE	"The truncated average: ",0
goodbye			BYTE	"Thank you for using the program. Goodbye!",0
totalPrompt		BYTE	"The running subtotal is: ", 0
input			BYTE	MAX_INPUT_LEN DUP(0),0		; null-terminated string
inputNum		SDWORD	0
inputArr		SDWORD	MAX_INPUT DUP(?)			; array with size of MAX_INPUT
outputArr		BYTE	MAX_INPUT_LEN DUP(0),0	
bytesRead		DWORD	0
numSum			SDWORD	0
numAvg			SDWORD	0
sign			DWORD	0							; 0 = no sign, 1 = sign
comma			BYTE	", ",0
dot				BYTE	". ",0
runningTotal	SDWORD	0
minNeg32		BYTE	"-2147483648",0

.code
main PROC
	; introduction
	PUSH	OFFSET extraCred
	PUSH	OFFSET intro_1
	PUSH	OFFSET intro_2
	PUSH	OFFSET intro_3
	CALL	Introduction

	; move MAX_INPUT into ECX as counter
	MOV		ECX, MAX_INPUT
	MOV		EBX, 1
	_GetVal:
	PUSH	OFFSET minNeg32
	PUSH	EBX
	PUSH	OFFSET outputArr
	CALL	WriteVal
	mDisplayString	OFFSET dot

	; get user's input
	PUSH	OFFSET input
	PUSH	OFFSET inputNum
	PUSH	MAX_INPUT_LEN
	PUSH	OFFSET prompt
	PUSH	OFFSET error
	PUSH	OFFSET retry
	CALL	ReadVal

	; add the number to the array
	PUSH	inputNum
	PUSH	OFFSET inputArr
	PUSH	ECX
	PUSH	MAX_INPUT
	CALL	addList
	INC	EBX

	; calculate the running total
	MOV	EAX, runningTotal
	ADD	EAX, inputNum
	MOV	runningTotal, EAX
	
	; display the running total
	mDisplayString	OFFSET totalPrompt
	PUSH	OFFSET minNeg32
	PUSH	runningTotal
	PUSH	OFFSET outputArr
	CALL	WriteVal
	CALL	CrLf

	DEC	ECX
	JNZ	_GetVal

	; after gathering 10 inputs, print the array
	PUSH	OFFSET minNeg32
	PUSH	OFFSET comma
	PUSH	OFFSET outputArr
	PUSH	MAX_INPUT
	PUSH	OFFSET resultArr
	PUSH	OFFSET inputArr
	CALL	DisplayNumArray

	; display the sum of the array and truancated average
	PUSH	OFFSET minNeg32
	PUSH	OFFSET resultAvg
	PUSH	OFFSET outputArr
	PUSH	OFFSET resultSum
	PUSH	MAX_INPUT
	PUSH	OFFSET inputArr
	CALL	CalculationResult

	; farewell user
	mDisplayString OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; Additional Procedures

; ---------------------------------------------------------------------------------
; Name: Introduction
;
; Displays introduction messages about the program
;
; Receives:
; [EBP+20] = address of the extra credit message
; [EBP+16] = title of the program
; [EBP+12] = address of the introduction message 1
; [EBP+8] = address of the introduction message 2
; ---------------------------------------------------------------------------------
Introduction PROC
	PUSH	EBP
	MOV		EBP, ESP
	mDisplayString [EBP+16]
	CALL	CrLf
	mDisplayString [EBP+12]
	mDisplayString [EBP+8]
	mDisplayString [EBP+20]
	CALL	CrLf
	POP		EBP
	RET		16
Introduction ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Reads a valid numeric input from the user and converts it to an integer value. 
; It handles positive/negative signs and checks for validity of the input.
;
; Preconditions: All arguments must be initialized.
;
; Postconditions: 
;	[EBP+28] will be changed
;	All used registers will be restored to their original values
;
; Receives:
; [EBP+32] = bytes read
; [EBP+28] = address of the string
; [EBP+24] = value of the valid number
; [EBP+20] = number of max length of the string
; [EBP+16] = address of prompt message
; [EBP+12] = address of error message
; [EBP+8] =  address of retry meesage
;
; Returns: 
;	[EBP+28] will be changed(a signed number will be saved)
; ---------------------------------------------------------------------------------
ReadVal	PROC
	PUSH	EBP
	MOV	EBP, ESP
	PUSHAD
	
	MOV	EAX, [EBP+28]
	XOR	EAX, EAX
	mGetString [EBP+16], [EBP+28], [EBP+20], [EBP+32] 	; get the number input, [EBP+28] will be changed after mGetString
	JZ	_InvalidNum
	MOV	EAX, [EBP+32]
	CMP	EAX, 11
	JG	_InvalidNum

	_GetNewNum:
	MOV	EBX, 1						; store the sign into EBX, 1 = positve, -1 = negative
	XOR	EAX, EAX
	XOR	EDX, EDX

	MOV	ESI, [EBP+28]					; save string in ESI
	MOV	ECX, 0

	_GetNum:
	LODSB
	CMP	AL, 0						; check if current character is null
	JE	_EndLoop					; yes: terminate the loop

	CMP	ECX, [EBP+20]
	JGE	_InvalidNum
	CMP	ECX, 0						; check if ECX is 0 (1st character)
	JE	_FirstDigit					; yes: jump to check sign/ no sign
	JMP	_CheckValid	

	_FirstDigit:
	CMP	AL, 43						; check if first digit is positive sign
	JE	_MoveToNext
	CMP	AL, 45						; check if first digit is negative sign
	JE	_SetSign
	JMP	_CheckValid

	_SetSign:
	MOV	EBX, -1
	JMP	_MoveToNext

	_CheckValid:
	CMP	AL, 48						; check if the character is smaller than '0'
	JL	_InvalidNum				
	CMP 	AL, 57						; check if the character is larger than '9'
	JG	_InvalidNum

	_ConvertToNum:
	; EDX = EAX * 10 + ECX
	PUSH	ECX
	SUB	AL, 48					
	MOVZX	ECX, AL
	MOV	EAX, EDX
	XOR	EDX, EDX					; clear EDX

	IMUL	EAX, 10
	JO	_LargerThan32			
	ADD	EAX, ECX
	JO	_LargerThan32
	MOV	EDX, EAX					; current number will be save in EDX
	POP	ECX	
	JMP	_MoveToNext

	_MoveToNext:
	ADD	ECX, 1
	JMP	_GetNum

	_LargerThan32:
	POP	ECX
	MOV	EDX, EAX
	CMP	EDX, 80000000h					; check if EDX is currently 80000000h
	JNE	_InvalidNum					; no: invalid number
	CMP	EBX, -1						; check if sign is negative
	JNE	_InvalidNum					; no: invalid number
	JMP	_EndLoopFromNeg32				; yes: jump to display the negative num result for -(2^31)

	_InvalidNum:
	mDisplayString [EBP+12]
	MOV	EAX, [EBP+28]
	XOR	EAX, EAX					; clear the value in the string
	mGetString [EBP+8], [EBP+28], [EBP+20], [EBP+32]
	JZ	_InvalidNum
	MOV	EAX, [EBP+32]
	CMP	EAX, 10
	JG	_InvalidNum
	JMP	_GetNewNum

	_EndLoop:
	IMUL	EDX, EBX

	_EndLoopFromNeg32:
	MOV	EAX, EDX
	MOV	ESI, [EBP+24]
	MOV	[ESI], EAX
	POPAD
	POP	EBP
	RET	28

ReadVal	ENDP

; ---------------------------------------------------------------------------------
; Name: addList
;
; Adds a signed number to an array at a specified index.
;
; Preconditions: 
;   The array is of type SDWORD.
;   The counter and maximum number of input are valid and consistent.
;
; Postconditions: 
;	The specified signed number is added to the array at the specified index.
;	All used registers will be restored to their original values
;
; Receives:
; [EBP+20] = value of a signed number to be added
; [EBP+16] = address of the array
; [EBP+12] = the counter of the numbers
; [EBP+8] = the maximum number of input
;
; ---------------------------------------------------------------------------------
addList	PROC
	PUSH	EBP
	MOV	EBP, ESP
	PUSHAD

	MOV	EAX, [EBP+8]					; maximum number of input into EAX
	MOV	EBX, [EBP+12]					; counter
	SUB	EAX, EBX					; max - counter = index of the number should be in
	IMUL	EAX, 4						; calculate the address of each index

	MOV	ESI, [EBP+16]
	ADD	ESI, EAX
	MOV	EAX, [EBP+20]
	MOV	[ESI], EAX

	POPAD
	POP	EBP
	RET	16


addList ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts an input signed integer to its string representation and displays 
; it on the console.
;
; Preconditions: 
;   The input number has to be SDWORD.
;
; Postconditions: 
;	 All used registers will be restored to their original values
;
; Receives:
; [EBP+16] = minimum of the 32 register signed int (-2147483648)
; [EBP+12] = value of the number to be converted and displayed
; [EBP+8] = address of output string buffer
;
; ---------------------------------------------------------------------------------

WriteVal PROC
	PUSH	EBP
	MOV	EBP, ESP
	PUSHAD

	PUSH	EAX
	PUSH	ECX
	MOV	EDI, [EBP+8]
	MOV	ECX, 12
	MOV	AL, 0

	; Loop to fill buffer with zeros
	_FillWithZeros:
		STOSB
		LOOP	_FillWithZeros
	POP	ECX
	POP	EAX

	MOV	ECX, 0						; Initialize ECX to store the number of digits
	MOV	EAX, [EBP+12]					; Load the value of the number to be converted
	MOV	EDI, [EBP+8]					; Load the address of the output string buffer
	TEST	EAX, EAX					; check if the input number is negative
	JS	_IsNegative
	JMP	_PrepToConvert

	_IsNegative:
	CMP	EAX, 80000000h					; Check if the value is -2147483648
	JE	_PrintNeg32

	PUSH	EAX
	XOR	EAX, EAX
	MOV	AL, 45
	MOV	[EDI], AL
	INC	EDI
	POP	EAX
	NEG	EAX						; Convert the negative value to positive
	JMP	_PrepToConvert

	_PrintNeg32:
	MOV	EDX, [EBP+16]					; Load the address of the string for -2147483648
	mDisplayString EDX
	JMP	_EndLoop

	_PrepToConvert:
	MOV	EBX, 10						; EBX used as divisor
	XOR	EDX, EDX

	_ConvertToStr:
	CDQ
	IDIV	EBX
	PUSH	EDX						; Push the remainder onto the stack
	INC	ECX
	CMP	EAX, 0						; Check if quotient is zero
	JE	_PutIntoString
	JMP	_ConvertToStr


	_PutIntoString:
	XOR	EAX, EAX
	POP	EAX
	ADD	AL, 48						; Convert remainder to ASCII character
	STOSB
	LOOP	_PutIntoString

	_PrintString:
	mDisplayString [EBP+8]					; Display the converted string

	_EndLoop:
	POPAD
	POP	EBP
	RET	12
WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: DisplayNumArray
;
; Displays an array of signed doubleword (SDWORD) numbersseparated by commas.
;
; Preconditions: 
;	The array is type SDWORD.
;
; Postconditions: 
;	 All used registers will be restored to their original values
;
; Receives:
; [EBP+28] = minimum of the 32 register signed int (-2147483648)
; [EBP+24] = Comma character to use for separation
; [EBP+20] = Address of the output string buffer
; [EBP+16] = Length of the number array
; [EBP+12] = Address of the prompt message
; [EBP+8] = Address of the number array
;
; ---------------------------------------------------------------------------------
DisplayNumArray PROC
	PUSH	EBP
	MOV	EBP, ESP
	PUSHAD

	mDisplayString [EBP+12]
	CALL	CrLf

	MOV	ESI, [EBP+8]					; Load the address of the number array
	MOV	ECX, [EBP+16]					; Load the length of the number array
	DEC	ECX
	MOV	EBX, 0
	_PrintArray:
	LODSD							; Load the next SDWORD from the array

	; Call WriteVal to convert and display the number
	PUSH	[EBP+28]
	PUSH	EAX
	PUSH	[EBP+20]
	CALL	WriteVal
	mDisplayString [EBP+24]
	LOOP	_PrintArray

	; Call WriteVal to convert and display the last number
	LODSD
	PUSH	[EBP+28]
	PUSH	EAX
	PUSH	[EBP+20]
	CALL	WriteVal

	POPAD
	POP	EBP
	RET	24
DisplayNumArray ENDP

; ---------------------------------------------------------------------------------
; Name: CalculationResult
;
; Calculates the sum and average of an array of signed doubleword (SDWORD) numbers 
; and displays the results.
;
; Preconditions: 
;	The array is type SDWORD.
;
; Postconditions: 
;	 All used registers will be restored to their original values
;
; Receives:
; [EBP+28] = minimum of the 32 register signed int (-2147483648)
; [EBP+24] = address of the result prompt(for average)
; [EBP+20] = output of the string
; [EBP+16] = address of the result prompt(for sum)
; [EBP+12] = length of the array
; [EBP+8] = address of the number array
; 
; ---------------------------------------------------------------------------------
CalculationResult	PROC
	PUSH	EBP
	MOV	EBP, ESP
	PUSHAD
	
	MOV	EAX, 0
	MOV	ESI, [EBP+8]					; put address of the number array into ESI
	MOV	ECX, [EBP+12]					; set ECX as counter

	_AddSum:
	ADD	EAX, [ESI]
	ADD	ESI, 4
	LOOP	_AddSum
	
	CALL	CrLf

    ; Print the sum by using WriteVal
	mDisplayString [EBP+16]
	PUSH	[EBP+28]
	PUSH	EAX
	PUSH	[EBP+20]
	CALL	WriteVal				

	; Calculate the average
	MOV	EBX, [EBP+12]
	CDQ
	IDIV	EBX

	CALL	CrLf

    ; Print the truncated average by using WriteVal
	mDisplayString [EBP+24]
	PUSH	[EBP+28]
	PUSH	EAX
	PUSH	[EBP+20]
	CALL	WriteVal				
	CALL	CrLf

	POPAD
	POP	EBP
	RET	24
CalculationResult ENDP


END main
