# Introduction #

This documents describes the standards that all new or modified code should conform to.


# Details #
  * Every `*`.gsc file must contain a license header.
  * No file may contain tab characters.
  * Use four (4) spaces for indentation.
  * The opening brace of a block must be on the same line as the opening statement, with two exceptions:
    1. The opening brace for a function definition must be in the zeroeth column of the next line
    1. If conditional tests are wrapped to multiple lines, the opening brace should be on the next line, and at the same indentation level as the opening statement
  * Each conditional should be wrapped in its own parentheses
  * Do not use whitespace after an opening parenthesis or before a closing parenthesis.
  * Explicit braces must be used for every block--implicit braces must not be used as they lead to buggy code.
  * Function definitions must be documented.
  * Function definitions must have a debugging statement as the first line of the function.
  * Variable names should be long and meaningful.  Avoid abbreviations.  Single character variable names should not be used, except in the case of well-known mathematics or scientific variables.
  * Variable names should be camel-cased: myAwesomeVariable
  * Nested loop counters should follow the i, j, k convention, unless the specifics of the case make another convention the better choice.
  * Else if statements should be written without vertical whitespace.
  * Code and documentation must be in English, with correct grammar and spelling.  Spelling variations in the various flavors of English is OK, i.e. 'colour' does not need to be changed to 'color'.
  * Avoid naked numbers where practical.  Instead, assign the number to a meaningful variable name.  If a number has associated units, use a short comment to indicate the units of measurement, i.e. ` velocity = 12.3; // m/s`

# Examples #
### Single Short Statement Conditional Blocks ###
```
    if (myFlag) {return true;}
    else {return false;}
```
### Multiple Wrapped Conditionals ###
```
    if ((myFlag) ||
        (isPlayerCool))
    {
        doSomething();
        doSomethingElse();
    }
```
### Multiple Statement Block ###
```
    if (myFlag) {
        doSomething();
        doSomethingElse();
    }
```
### If/Else If/Else Statement ###
```
    if (myFlag) {
        doSomething();
    } else if (self.isAlive) {
        doSomethingElse();
    } else {return false;}
```
### Function Definition ###
```
/**
 * @brief Does something really cool to a player's name
 *
 * @param name string The name of the player
 * @param color string The color of the player's name
 * 
 * @returns boolean true if the we did something cool to a player's name, false otherwise
 */
myCoolFunction(name, color)
{
    debugPrint("in _myCodeFile::myCoolFunction()", "fn", level.nonVerbose);

    if (color == "red") {return doSomething(name);}
    else {return false;}
}
```