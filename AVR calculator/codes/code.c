#define F_CPU 16000000UL // Define clock frequency (16 MHz)
#include <avr/io.h>
#include <util/delay.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>   // For sprintf()
#include <stdlib.h>  // For atof()
#include <ctype.h>   // For isdigit()
#include <math.h>    // For trigonometric and power functions
// TYPEDEFS
typedef uint8_t byte;
#define min(a, b) ((a) < (b) ? (a) : (b))
// LCD Pin Definitions
#define LCD_RS PD0  // RS pin
#define LCD_E  PD1  // Enable pin
#define DAT4   PD2  // Data pin D4
#define DAT5   PD3  // Data pin D5
#define DAT6   PD4  // Data pin D6
#define DAT7   PD5  // Data pin D7

// Keypad Row Pins (Arduino pins 6, 7, 8, 9)
#define ROW1 PD6  // Arduino pin 6
#define ROW2 PD7  // Arduino pin 7
#define ROW3 PB0  // Arduino pin 8
#define ROW4 PB1  // Arduino pin 9

// Keypad Column Pins (Arduino pins 10, 11, 12)
#define COL1 PB2  // Arduino pin 10
#define COL2 PB3  // Arduino pin 11
#define COL3 PB4  // Arduino pin 12

// Keypad Layout
const char keys[4][3] = {
    {'1', '2', '3'},  // Row 1
    {'4', '5', '6'},  // Row 2
    {'7', '8', '9'},  // Row 3
    {'A', '0', 'C'}   // Row 4 (A = Backspace, 0 = 0, C = Operator Button)
};

// Operators
const char operators[] = {'+', '-', '', '/', '.', '^'}; // Use '^' for ''
uint8_t operatorIndex = 0; // Tracks the current operator in the cycle
uint8_t exprIndex = 0;
// Trigonometric Functions
const char* trigFunctions[] = {"sn", "cs", "tn", "as", "ac", "at", "lg", "ln", "ex"};
uint8_t trigFunctionIndex = 0; // Tracks the current trigonometric function in the cycle

// Constants
#define PI 3.14159265358979323846
#define E 2.71828182845904523536

// Function Prototypes
void PulseEnableLine();
void SendNibble(uint8_t data);
void SendByte(uint8_t data);
void LCD_Cmd(uint8_t cmd);
void LCD_Char(uint8_t ch);
void LCD_Init();
void LCD_Clear();
int precedence(char op);
void LCD_Message(const char *text);
char getKeyPressed();
void handleKeyPress(char key);
void toggleOperatorMode();
bool isOperator(char c);
void toggleTrigMode();
void handleParenthesisButton();
float applyOperation(float a, float b, char op);
void handleConstantsButton();
float evaluateExpression(char *expr);
float evalBasicMath(char *expr);
void calculateResult();
void resetCalculator();
void evaluateTrigFunctions(char *expr);
// Trigonometric Functions
float sin_euler(float x);
float cos_euler(float x);
float tan_euler(float x);

// Inverse Trigonometric Functions
float asin_euler(float x);
float acos_euler(float x);
float atan_euler(float x);

// Exponential and Logarithmic Functions
float exp_euler(float x);
float ln_euler(float x);
float log_euler(float x);
float string_to_float(const char *str) {
    return atof(str);
}

void float_to_string(float num, int precision, char *buffer) {
    dtostrf(num, 4, precision, buffer);
}
// Power Function
float power(float base, float exponent);
// Global variables
char expression[32] = ""; // Stores the input expression
bool resultDisplayed = false; // Tracks if the result is displayed
void append_char(char c) {
    if (resultDisplayed) { 
        // If new input is given after result, reset expression
        exprIndex = 0;
        resultDisplayed = false;
    }
    
    // Add character to expression
    if (exprIndex < sizeof(expression) - 1) {
        expression[exprIndex++] = c;
        expression[exprIndex] = '\0';
    }

    LCD_Init();
}


bool isOpenParenthesis = true;  // Tracks if the next parenthesis should be '('
bool isEInserted = false;  // Tracks if 'e' was last inserted

// Main Function
int main(void) {
    // Set PortD and PortB pins as outputs for LCD and keypad
    DDRD = 0xFF; // Set PD0-PD7 as outputs (LCD and keypad rows)
    DDRB = 0x03; // Set PB0-PB1 as outputs (keypad rows), PB2-PB4 as inputs (keypad columns)
    // Set PC3 as input with pull-up resistor
    DDRC &= ~((1 << PC2) | (1 << PC3) | (1 << PC4)); // Set PC2, PC3, and PC4 as inputs
    PORTC |= (1 << PC2) | (1 << PC3) | (1 << PC4);   // Enable pull-up resistors on PC2, PC3, and PC4
// Check if the A3 button is pressed (calculate result)
    
    // Enable pull-up resistors on column pins
    PORTB |= (1 << COL1) | (1 << COL2) | (1 << COL3);

    // Set PC2 (A2), PB5 (Parenthesis Button), and PC4 (Constants Button) as inputs with pull-up resistors
    
    DDRB &= ~(1 << PB5); // Set PB5 as input
    PORTB |= (1 << PB5); // Enable pull-up resistor on PB5

    // Initialize LCD
    LCD_Init();

    // Display a message
    LCD_Message("Enter Number:");

    while (1) {
        // Check if the A2 button is pressed (trigonometric mode)
        if (!(PINC & (1 << PC2))) { // If PC2 is LOW (button pressed)
            _delay_ms(20); // Debounce delay (20ms)
            if (!(PINC & (1 << PC2))) { // Confirm button press
                toggleTrigMode(); // Toggle trigonometric mode
                while (!(PINC & (1 << PC2))) {} // Wait for button release
                _delay_ms(20); // Debounce delay after release
            }
        }
        if (!(PINC & (1 << PC3))) {  // If PC3 is LOW (button pressed)
            _delay_ms(20);  // Debounce delay
            if (!(PINC & (1 << PC3))) {  // Confirm button press
                calculateResult();  // Calculate and display the result
                while (!(PINC & (1 << PC3))) {}  // Wait for button release
                _delay_ms(20);  // Debounce delay after release
            }
        }

        // Check if the Parenthesis button is pressed (PB5)
        if (!(PINB & (1 << PB5))) { // If PB5 is LOW (button pressed)
            _delay_ms(20); // Debounce delay (20ms)
            if (!(PINB & (1 << PB5))) { // Confirm button press
                handleParenthesisButton(); // Handle parenthesis button press
                while (!(PINB & (1 << PB5))) {} // Wait for button release
                _delay_ms(20); // Debounce delay after release
            }
        }

        // Check if the Constants button is pressed (PC4)
        if (!(PINC & (1 << PC4))) { // If PC4 is LOW (button pressed)
            _delay_ms(20); // Debounce delay (20ms)
            if (!(PINC & (1 << PC4))) { // Confirm button press
                handleConstantsButton(); // Handle constants button press
                while (!(PINC & (1 << PC4))) {} // Wait for button release
                _delay_ms(20); // Debounce delay after release
            }
        }

        // Check keypad for key presses
        char key = getKeyPressed(); // Get the pressed key
        if (key != '\0') {         // If a key is pressed
            handleKeyPress(key);   // Handle the key press
            _delay_ms(300);        // Debounce delay
            
        }
    }
}

// Function to handle key presses
void handleKeyPress(char key) {
    switch (key) {
        case 'A':  // Backspace
            if (strlen(expression) > 0) {
                expression[strlen(expression) - 1] = '\0';  // Remove last character
            }
            break;
        case 'C':  // Operator Button
            toggleOperatorMode(); // Cycle through operators
            break;
        default:  // Numbers (0-9) and other characters
            strncat(expression, &key, 1);  // Append the key to the expression

            // Reset operatorIndex when a number is entered
            operatorIndex = 0;

            // Reset trigFunctionIndex when a number is entered
            trigFunctionIndex = 0;
            break;
    }
    LCD_Clear();
    LCD_Message(expression);  // Update the LCD display
}

// Function to toggle operator mode
void toggleOperatorMode() {
    // Reset trigFunctionIndex when an operator is entered
    trigFunctionIndex = 0;

    // If the last character in expression is an operator, replace it
    if (strlen(expression) > 0 && isOperator(expression[strlen(expression) - 1])) {
        expression[strlen(expression) - 1] = '\0';  // Remove last operator
    }

    // Add the new operator
    strncat(expression, &operators[operatorIndex], 1);  // Append the operator

    // Cycle to the next operator for the next press
    operatorIndex = (operatorIndex + 1) % 6;

    LCD_Clear();
    LCD_Message(expression);  // Update the LCD display
}
// Function to toggle trigonometric mode
void toggleTrigMode() {
    // Reset operatorIndex when a trigonometric function is entered
    operatorIndex = 0;

    // Check if the last part of the expression is a trigonometric function
    for (uint8_t i = 0; i < 9; i++) {  // 9 functions in total
        uint8_t funcLength = strlen(trigFunctions[i]);
        if (strlen(expression) >= funcLength + 1) { // +1 for the '('
            // Compare the last part of the expression with the trigonometric function
            if (strncmp(expression + strlen(expression) - funcLength - 1, trigFunctions[i], funcLength) == 0 &&
                expression[strlen(expression) - 1] == '(') {
                // Remove the existing trigonometric function
                expression[strlen(expression) - funcLength - 1] = '\0';
                break; // Exit the loop once a match is found
            }
        }
    }

    // Append the new trigonometric function and an opening parenthesis
    strcat(expression, trigFunctions[trigFunctionIndex]); // Append function name
    strcat(expression, "("); // Append opening parenthesis

    // Increase the parenthesis count
    isOpenParenthesis = false;

    // Cycle to the next trigonometric function for the next press
    trigFunctionIndex = (trigFunctionIndex + 1) % 9;

    // Update the LCD display
    LCD_Clear();
    LCD_Message(expression);
}

// Function to handle parenthesis button press
void handleParenthesisButton() {
    if (isOpenParenthesis) {
        strcat(expression, "(");  // Append '('
    } else {
        strcat(expression, ")");  // Append ')'
    }

    // Toggle the state
    isOpenParenthesis = !isOpenParenthesis;

    // Update the LCD display
    LCD_Clear();
    LCD_Message(expression);
}

// Function to handle constants button press
void handleConstantsButton() {
    // If the last character is 'e' or 'pi', remove it
    if (strlen(expression) > 0 && (expression[strlen(expression) - 1] == 'e' || 
        strncmp(expression + strlen(expression) - 2, "pi", 2) == 0)) {
        expression[strlen(expression) - (expression[strlen(expression) - 1] == 'e' ? 1 : 2)] = '\0';
    }

    // Toggle between 'e' and 'pi'
    if (isEInserted) {
        strcat(expression, "pi");  // Append 'pi'
    } else {
        strcat(expression, "e");   // Append 'e'
    }

    // Toggle the state
    isEInserted = !isEInserted;

    // Update the LCD display
    LCD_Clear();
    LCD_Message(expression);
}

// Function to check if a character is an operator
bool isOperator(char c) {
    return (c == '+' || c == '-' || c == '*' || c == '/' || c == '.' || c == '^');
}

// Function to scan the keypad and return the pressed key
char getKeyPressed() {
    // Activate each row and check columns
    for (uint8_t row = 0; row < 4; row++) {
        switch (row) {
            case 0: PORTD &= ~(1 << ROW1); break; // Activate ROW1 (PD6)
            case 1: PORTD &= ~(1 << ROW2); break; // Activate ROW2 (PD7)
            case 2: PORTB &= ~(1 << ROW3); break; // Activate ROW3 (PB0)
            case 3: PORTB &= ~(1 << ROW4); break; // Activate ROW4 (PB1)
        }
        _delay_us(10); // Debounce delay

        // Check columns
        if (!(PINB & (1 << COL1))) { // Check COL1 (PB2)
            _delay_ms(50); // Debounce delay
            if (!(PINB & (1 << COL1))) { // Confirm key press
                // Deactivate the row
                switch (row) {
                    case 0: PORTD |= (1 << ROW1); break;
                    case 1: PORTD |= (1 << ROW2); break;
                    case 2: PORTB |= (1 << ROW3); break;
                    case 3: PORTB |= (1 << ROW4); break;
                }
                return keys[row][0]; // Return the corresponding key
            }
        }
        if (!(PINB & (1 << COL2))) { // Check COL2 (PB3)
            _delay_ms(50); // Debounce delay
            if (!(PINB & (1 << COL2))) { // Confirm key press
                // Deactivate the row
                switch (row) {
                    case 0: PORTD |= (1 << ROW1); break;
                    case 1: PORTD |= (1 << ROW2); break;
                    case 2: PORTB |= (1 << ROW3); break;
                    case 3: PORTB |= (1 << ROW4); break;
                }
                return keys[row][1]; // Return the corresponding key
            }
        }
        if (!(PINB & (1 << COL3))) { // Check COL3 (PB4)
            _delay_ms(50); // Debounce delay
            if (!(PINB & (1 << COL3))) { // Confirm key press
                // Deactivate the row
                switch (row) {
                    case 0: PORTD |= (1 << ROW1); break;
                    case 1: PORTD |= (1 << ROW2); break;
                    case 2: PORTB |= (1 << ROW3); break;
                    case 3: PORTB |= (1 << ROW4); break;
                }
                return keys[row][2]; // Return the corresponding key
            }
        }

        // Deactivate the row
        switch (row) {
            case 0: PORTD |= (1 << ROW1); break;
            case 1: PORTD |= (1 << ROW2); break;
            case 2: PORTB |= (1 << ROW3); break;
            case 3: PORTB |= (1 << ROW4); break;
        }
    }
    return '\0'; // No key pressed
}

// LCD Functions
void PulseEnableLine() {
    PORTD |= (1 << LCD_E);  // Set E high
    _delay_us(1);           // Wait 1 microsecond
    PORTD &= ~(1 << LCD_E); // Set E low
    _delay_us(100);         // Wait 100 microseconds
}

void SendNibble(uint8_t data) {
    PORTD &= 0x03; // Clear data lines (PD2-PD5)
    PORTD |= ((data & 0x0F) << 2); // Set data lines (PD2-PD5)
    PulseEnableLine(); // Clock the data into the LCD
}

void SendByte(uint8_t data) {
    SendNibble(data >> 4); // Send upper 4 bits
    SendNibble(data);      // Send lower 4 bits
}

void LCD_Cmd(uint8_t cmd) {
    PORTD &= ~(1 << LCD_RS); // RS = 0 for command
    SendByte(cmd); // Send the command
}

void LCD_Char(uint8_t ch) {
    PORTD |= (1 << LCD_RS); // RS = 1 for data
    SendByte(ch); // Send the character
}

void LCD_Init() {
    // Wait for the LCD to power up
    _delay_ms(50);

    // Set 4-bit mode
    SendNibble(0x03); // Initialization sequence
    _delay_ms(5);
    SendNibble(0x03);
    _delay_us(100);
    SendNibble(0x03);
    _delay_us(100);
    SendNibble(0x02); // Set 4-bit mode
    _delay_us(100);

    // Complete initialization
    LCD_Cmd(0x28); // 4-bit mode, 2 lines, 5x8 font
    LCD_Cmd(0x0C); // Display on, cursor off, blink off
    LCD_Cmd(0x06); // Increment cursor, no display shift
    LCD_Cmd(0x01); // Clear display
    _delay_ms(2);  // Wait for clear command to complete
}

void LCD_Clear() {
    LCD_Cmd(0x01); // Send the clear display command
    _delay_ms(2);  // Wait for the command to complete
}

void LCD_Message(const char *text) {
    while (*text) // Do until null character
        LCD_Char(*text++); // Send char & update char pointer
}
void replaceConstants(char *expr) {
    char *pos;

    // Replace 'e' with its value
    while ((pos = strstr(expr, "e")) != NULL) {
        char temp[32];
        strcpy(temp, expr + (pos - expr) + 1); // Copy the rest of the string
        sprintf(expr + (pos - expr), "%.6f%s", E, temp); // Replace 'e' with its value
    }

    // Replace 'pi' with its value
    while ((pos = strstr(expr, "pi")) != NULL) {
        char temp[32];
        strcpy(temp, expr + (pos - expr) + 2); // Copy the rest of the string
        sprintf(expr + (pos - expr), "%.6f%s", PI, temp); // Replace 'pi' with its value
    }
}
float evaluateExpression(char *expr) {
    // Debug: Print the original expression
    LCD_Clear();
    LCD_Message("Original: ");
    LCD_Message(expr);
    _delay_ms(2000);

    // Check if the expression starts with a trigonometric function
    if (strncmp(expr, "sn", 2) == 0 || strncmp(expr, "cs", 2) == 0 || strncmp(expr, "tn", 2) == 0) {
        // Extract the function name (first 2 characters)
        char func[3];
        strncpy(func, expr, 2);
        func[2] = '\0'; // Null-terminate the string

        // Debug: Print the function name
        LCD_Clear();
        LCD_Message("Func: ");
        LCD_Message(func);
        _delay_ms(2000);

        // Find the opening and closing parentheses
        int openParen = 2; // Position of '(' (after the function name)
        int closeParen = openParen + 3; // Position of ')'

        // Find the closing parenthesis
        while (expr[closeParen] != ')' && expr[closeParen] != '\0') {
            closeParen++;
        }
        if (expr[closeParen] != ')') return NAN; // Invalid syntax

        // Extract the argument inside the parentheses
        char arg[16];
        strncpy(arg, expr + openParen + 3, closeParen - (openParen + 1));
        arg[closeParen - (openParen + 3)] = '\0';

        // Debug: Print the argument
        LCD_Clear();
        LCD_Message("Arg: ");
        LCD_Message(arg);
        _delay_ms(2000);

        // Evaluate the argument
        float argValue = atof(arg); // Convert argument to float

        // Apply the trigonometric function
        float result = 0;
        if (strcmp(func, "sn") == 0) result = sin_euler(argValue); // sin function
        else if (strcmp(func, "cs") == 0) result = cos_euler(argValue); // cos function
        else if (strcmp(func, "tn") == 0) result = tan_euler(argValue); // tan function

        // Debug: Print the result of the function
        LCD_Clear();
        LCD_Message("Func Result: ");
        char resultStr[16];
        dtostrf(result, 6, 3, resultStr);
        LCD_Message(resultStr);
        _delay_ms(2000);

        // Replace the function call with the result
        char temp[32];
        strcpy(temp, expr + closeParen + 1); // Copy the rest of the string
        sprintf(expr, "%.6f%s", result, temp); // Replace the function call
    }

    // Evaluate basic math operations
    return evalBasicMath(expr);
}
void calculateResult() {
     // Don't evaluate empty input

    LCD_Clear();
    LCD_Message("Evaluating...");
    _delay_ms(1000);  // Simulate delay for evaluation

    // Step 1: Replace constants (e and pi) with their values
    replaceConstants(expression);

    // Step 2: Evaluate trigonometric functions
    evaluateTrigFunctions(expression);

    // Step 3: Evaluate basic arithmetic operations
    float result = evalBasicMath(expression);

    // Step 4: Check if result is valid
    if (isnan(result) || isinf(result)) {
        LCD_Clear();
        LCD_Message("Error!");
        return;
    }

    // Step 5: Convert result to string
    char resultStr[16];
    dtostrf(result, 6, 3, resultStr);  // Convert float to string with 3 decimal places

    // Step 6: Store result as new expression for further calculations
    strcpy(expression, resultStr);
    exprIndex = strlen(expression);

    // Step 7: Display the result
    LCD_Clear();
    LCD_Message("Result: ");
    LCD_Message(resultStr);

    resultDisplayed = true;  // Set the flag to indicate result is displayed
}

// Function to reset the calculator
void resetCalculator() {
    LCD_Clear();
    LCD_Message("Enter Number:");
    memset(expression, 0, sizeof(expression)); // Clear the expression
    resultDisplayed = false;

    // Reset operatorIndex and trigFunctionIndex
    operatorIndex = 0;
    trigFunctionIndex = 0;
}
// Function to evaluate the expression (basic math and trigonometric functions)
void evaluateTrigFunctions(char *expr) {
    char buffer[32];      // Buffer for extracted function argument
    char resultBuffer[16]; // Buffer to store computed result as a string
    int start, openParen, closeParen;

    // Loop through supported trigonometric functions
    for (uint8_t i = 0; i < 9; i++) {
        char *pos = strstr(expr, trigFunctions[i]);  // Search in expr
        while (pos != NULL) {
            start = pos - expr;
            openParen = start + strlen(trigFunctions[i]);
            closeParen = openParen + 1;

            // Find the closing parenthesis
            while (expr[closeParen] != ')' && expr[closeParen] != '\0') {
                closeParen++;
            }
            if (expr[closeParen] != ')') return; // Invalid syntax

            // Extract the argument inside parentheses
            strncpy(buffer, expr + openParen + 1, closeParen - (openParen + 1));
            buffer[closeParen - (openParen + 1)] = '\0';

            // Convert to float and evaluate
            float argValue = string_to_float(buffer);
            float result = 0;
            if (strcmp(trigFunctions[i], "sn") == 0) result = sin_euler(argValue);
            else if (strcmp(trigFunctions[i], "cs") == 0) result = cos_euler(argValue);
            else if (strcmp(trigFunctions[i], "tn") == 0) result = tan_euler(argValue);
            else if (strcmp(trigFunctions[i], "as") == 0) result = asin_euler(argValue);
            else if (strcmp(trigFunctions[i], "ac") == 0) result = acos_euler(argValue);
            else if (strcmp(trigFunctions[i], "at") == 0) result = atan_euler(argValue);
            else if (strcmp(trigFunctions[i], "lg") == 0) result = log_euler(argValue);
            else if (strcmp(trigFunctions[i], "ln") == 0) result = ln_euler(argValue);
            else if (strcmp(trigFunctions[i], "ex") == 0) result = exp_euler(argValue);

            // Convert result to string
            float_to_string(result, 6, resultBuffer);

            // Replace the function call in expr with the result
            memmove(expr + start + strlen(resultBuffer), expr + closeParen + 1, strlen(expr) - closeParen);
            memcpy(expr + start, resultBuffer, strlen(resultBuffer));

            // Display updated expression on LCD
            LCD_Clear();
            LCD_Message(expr);

            // Find next occurrence of trig function
            pos = strstr(expr, trigFunctions[i]);
        }
    }
}



// Function to return the precedence of an operator
int precedence(char op) {
    if (op == '+' || op == '-') return 1;
    if (op == '*' || op == '/') return 2;
    return 0;
}

// Function to apply an operation
float applyOperation(float a, float b, char op) {
    switch (op) {
        case '+': return a + b;
        case '-': return a - b;
        case '*': return a * b;
        case '/': return a / b;
        default: return 0; // Invalid operator
    }
}
// Function to evaluate basic math operations (+, -, *, /, ^)
float evalBasicMath(char *expr) {
    float numbers[16];  // Stack to hold numbers
    char operators[16]; // Stack to hold operators
    int numTop = -1, opTop = -1; // Stack pointers

    for (int i = 0; expr[i] != '\0'; i++) {
        // If the character is a digit or '.', extract the number
        if (isdigit(expr[i]) || expr[i] == '.') {
            char numStr[16];
            int j = 0;
            while (isdigit(expr[i]) || expr[i] == '.') {
                numStr[j++] = expr[i++];
            }
            numStr[j] = '\0';
            numbers[++numTop] = atof(numStr); // Push the number onto the stack
            i--; // Adjust index after extracting the number
        }
        // If the character is an operator, push it onto the operator stack
        else if (expr[i] == '+' || expr[i] == '-' || expr[i] == '*' || expr[i] == '/' || expr[i] == '^') {
            while (opTop >= 0 && precedence(operators[opTop]) >= precedence(expr[i])) {
                // Pop the operator and numbers, perform the operation, and push the result
                float b = numbers[numTop--];
                float a = numbers[numTop--];
                char op = operators[opTop--];
                numbers[++numTop] = applyOperation(a, b, op);
            }
            operators[++opTop] = expr[i]; // Push the current operator onto the stack
        }
    }

    // Perform remaining operations in the stacks
    while (opTop >= 0) {
        float b = numbers[numTop--];
        float a = numbers[numTop--];
        char op = operators[opTop--];
        numbers[++numTop] = applyOperation(a, b, op);
    }

    // The final result is the only number left in the stack
    return numbers[numTop];
}

float sin_euler(float x) {
   x = x * PI / 180;  // Convert degrees to radians
    float y = x;
    for (int i = 0; i < 10; i++) {
        y -= (y - x + (y * y * y) / 6 - (y * y * y * y * y) / 120);
    }
    return y;

}
float cos_euler(float x) {
    x = x * PI / 180;  // Convert degrees to radians
    float y = 1;
    for (int i = 0; i < 10; i++) {
        y -= (y - 1 + (x * x) / 2 - (x * x * x * x) / 24);
    }
    return y;
}
float tan_euler(float x) {
    return sin_euler(x) / cos_euler(x);
}
float asin_euler(float x) {
    if (x < -1 || x > 1) {
        return 0;  // Error, asin is only valid for x in [-1, 1]
    }

    float y = x;
    float epsilon = 0.0001;
    int maxIterations = 10;

    for (int i = 0; i < maxIterations; i++) {
        float sin_y = sin_euler(y);
        float cos_y = cos_euler(y);
        float delta = (sin_y - x) / cos_y;
        y = y - delta;

        if (delta < 0 ? -delta : delta < epsilon) {  // abs(delta)
            break;
        }
    }

    return y * 180.0 / PI;  // Convert radians to degrees
}
float acos_euler(float x) {
    return (90 - asin_euler(x));
}
float atan_euler(float x) {
    if (x > 1) {
        return (PI / 2 - atan_euler(1 / x)) * 180 / PI;
    } else if (x < -1) {
        return (-PI / 2 - atan_euler(1 / x)) * 180 / PI;
    }

    float result = 0;
    float term = x;
    int n = 1;

    while (term > 0.00001 ? term : -term > 0.00001) {  // abs(term)
        result += term;
        n += 2;
        term = -term * x * x / n;
    }

    return result * 180 / PI;  // Convert radians to degrees
}
float exp_euler(float x) {
    float result = 1;
    float term = 1;
    int n = 1;

    while (term > 0.00001) {
        term *= x / n;
        result += term;
        n++;
    }

    return result;
}
float ln_euler(float x) {
    if (x <= 0) return NAN;  // Logarithm is undefined for non-positive numbers

    // Normalize x to the range (0, 2)
    float k = 0;
    while (x > 2) {
        x /= E;
        k++;
    }
    while (x < 1) {
        x *= E;
        k--;
    }

    // Compute ln(x) using the Taylor series
    float y = (x - 1) / (x + 1);
    float y2 = y * y;
    float result = 0;
    float term = y;
    int n = 1;

    while (term > 0.00001 ? term : -term > 0.00001) {  // abs(term)
        result += term / n;
        term *= y2;
        n += 2;
    }

    return 2 * result + k;
}
// Function to compute power (base^exponent)
float power(float base, float exponent) {
    if (exponent == 0) return 1;  // Any number to the power of 0 is 1

    // Handle negative exponents
    if (exponent < 0) {
        base = 1 / base;
        exponent = -exponent;
    }

    // Handle fractional exponents using logarithms and exp
    if (exponent != (int)exponent) {
        return exp_euler(exponent * ln_euler(base));
    }

    // Handle positive integer exponents
    float result = 1;
    for (int i = 0; i < exponent; i++) {
        result *= base;
    }
    return result;
}
float log_euler(float x) {
    if (x <= 0) return NAN;  // Logarithm is undefined for non-positive numbers
    return ln_euler(x) / ln_euler(10.0f);  // Use 10.0f for float precision
}
