flex_bison_calculator
=====================

A calculator supporting variables, conditionals, loops and functions written in Flex and Bison.

Build it:

```
bison -v -d -of_calc.tab.c f_calc.y
flex f_calc.l
gcc lex.yy.c f_calc.tab.c -lfl -o f_calc
./f_calc
```

Sample: define factorial

```
#!bash
def f(x,y) x < y ? x * f(x + 1, y) : x
Functions updated.
some_var = 6
Variable updated.
f(1, some_var)
720.000000
```



