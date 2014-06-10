%{
#include <stdio.h>
#include <stdlib.h>
#include "f_calc.tab.h"

char* dict[100];
int dict_size = 0;

int dict_find(const char* var_name) {
	int i;
	for(i = 0; i < dict_size; i++) 
		if (strcmp(var_name, dict[i]) == 0)
			return i;
	dict[dict_size] = (char*)malloc(strlen(var_name) + 1);
	strncpy(dict[dict_size], var_name, strlen(var_name) + 1);
	return dict_size++;
}

%}

NUM			-?([0-9]+|[0-9]*\.[0-9]+)
DEF			"def"
ID			([a-zA-Z]|_)+

%%

{NUM} 		{ yylval.d = atof(yytext); return NUM; }
{DEF}		{ return DEF; }
{ID}		{ yylval.i = dict_find(yytext); } 

[ ] 		// nothing
[\n]|. 		{ return yytext[0]; }

%%  
