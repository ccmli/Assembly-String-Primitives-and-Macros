# CS271 Project 6: String Processing and Number Conversion

## Description

This program implements string processing macros and procedures to handle user input and display, as well as conversion of ASCII strings to numeric values and vice versa. It includes macros "mGetString" to retrieve user input and "mDisplayString" to display strings. Additionally, procedures "ReadVal" and "WriteVal" are implemented to convert between ASCII strings and numeric values. The main test program utilizes these procedures to gather and display 10 valid integers, computing their sum and average, while adhering to parameter passing conventions, proper memory addressing, and code organization. The program ensures input validation, error handling, and efficient memory management through the use of macros and procedures.

## Macro Definitions

### `mGetString`

Displays a prompt, reads a string from the user input, and stores it in memory.

**Receives:**  
- `promptAddr`: Address of the prompt message to display.
- `inputAddr`: Address where the user input string will be stored.
- `maxLen`: Maximum length of the input string to read.
- `charEnter`: Number of characters entered by the user.

### `mDisplayString`

Displays a null-terminated string to the console.

**Receives:**  
- `strAddr`: Address of the null-terminated string to be displayed.

## Main Procedure

- Display introduction messages.
- Get 10 signed decimal integers from the user.
- Calculate the sum and average of the numbers.
- Display the entered numbers, their sum, and truncated average.
- Display the running subtotal of valid numbers.

## Additional Procedures

- `Introduction`: Display introduction messages about the program.
- `ReadVal`: Read a valid numeric input from the user and convert it to an integer value.
- `addList`: Add a signed number to an array at a specified index.
- `WriteVal`: Convert an input signed integer to its string representation and display it.
- `DisplayNumArray`: Display an array of signed integers separated by commas.
- `CalculationResult`: Calculate the sum and average of an array of signed integers and display the results.

## How to Run

1. Assemble and link the program using the Irvine32 library.
2. Execute the compiled program.
3. Follow the on-screen prompts to enter 10 valid signed decimal integers.
4. The program will display the entered numbers, their sum, and truncated average.

## Notes

- Ensure that each entered number is within the range of a 32-bit register.
- The program includes error handling for invalid input and efficient memory management.
- The running subtotal of valid numbers is displayed using the WriteVal procedure.
