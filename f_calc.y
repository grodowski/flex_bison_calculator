%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Data structures */
typedef enum {cons, var_ident, oper, fptr, func, cond} nodetype;

struct expr {
  nodetype type;
  union {
    double val; // for cons
    int index; // for var_ident and f_ident
    struct {
		char op;
		struct expr *arg1;
		struct expr *arg2;
    } op; // for oper / fptr uses operands for arguments
	struct {
		int var_1; // index of allocated variable 1
		int var_2; // index of allocated variable 2
		int n_args; // 0,1,2
		struct expr *body;
	} func; // a function definition (func)	
	struct {
		struct expr *c_expr;
		struct expr *t_expr;
		struct expr *f_expr;
	} cond; // for cond
  };
};

double variables[100]; // array of variables
struct expr* functions[100]; // expr

/* Functions and helpers */
double set_var(int idx, double val);
struct expr* define_operator_expr(char oper, struct expr *arg1, struct expr *arg2);
double compute_expr(struct expr* expr);
double compute_func(int funcptr, struct expr *arg1, struct expr *arg2);
void define_func_2(int f_index, struct expr *body, int arg1_idx, int arg2_idx);
void define_func_1(int f_index, struct expr *body, int arg1_idx);
void define_func_0(int f_index, struct expr *body);

%}

%union {
	double d;
	int i;
	struct expr *e;
}

%left '+' '-'
%left '*' '/' '%'
%left EQL LTE GTE LT GT
%left AND OR
%left NOT UNARY_MINUS UNARY_PLUS


%token <d>		NUM
%token <i>		ID
%token <d>		DEF

%type <d>		expr define define_func // do not return anything
%type <e>		cond num_expr

%%

expr	 	: expr define '\n' { printf("Variable updated.\n"); }
			| expr define_func '\n' { printf("Functions updated.\n"); }
			| expr cond '\n' { printf("%f\n", compute_expr($2)); }
			| expr '\n'
			| { /* empty */ } ;

define		: ID '=' cond { set_var($1, compute_expr($3)); } ; 

define_func	: DEF ID '(' ID ',' ID ')' cond { define_func_2($2, $8, $4, $6); } // two arguments
			| DEF ID '(' ID ')' cond { define_func_1($2, $6, $4); } // one argument
			| DEF ID '(' ')' cond { define_func_0($2, $5); } // no arguments
			; 

cond		: num_expr '?' cond ':' cond { $$ = (struct expr*)malloc(sizeof(struct expr));
				$$->type=cond;
				printf("t: %f\n", compute_expr($3));
				printf("f: %f\n", compute_expr($5));
				$$->cond.c_expr = $1;
				$$->cond.t_expr = $3;
				$$->cond.f_expr = $5; 
			}
		| num_expr { $$ = $1; } ;

num_expr	: NUM { $$=(struct expr*)malloc(sizeof(struct expr));
		        	$$->type=cons;
					$$->val=$1;
				}
			| ID  { $$=(struct expr*)malloc(sizeof(struct expr));
			        $$->type=var_ident;
					$$->index=$1;
				}
			| ID '(' num_expr ',' num_expr ')' {
					$$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=fptr;
					$$->index=$1;
					$$->op.arg1=$3;
					$$->op.arg2=$5;
				}
			| ID '(' num_expr ')' { 
					$$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=fptr;
					$$->index=$1;
					$$->op.arg1=$3;
				}
			| ID '(' ')' {
					$$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=fptr;
					$$->index=$1;
				}
			| '-' num_expr %prec UNARY_MINUS { $$ = define_operator_expr('-', 0, $2); }
			| '+' num_expr %prec UNARY_PLUS  { $$ = define_operator_expr('+', 0, $2); }
			| num_expr '+' num_expr { $$ = define_operator_expr('+', $1, $3); }
			| num_expr '-' num_expr { $$ = define_operator_expr('-', $1, $3); }
			| num_expr '*' num_expr { $$ = define_operator_expr('*', $1, $3); }
			| num_expr '/' num_expr { $$ = define_operator_expr('/', $1, $3); }
			| num_expr LT num_expr { $$ = define_operator_expr('<', $1, $3); }
			| num_expr GT num_expr { $$ = define_operator_expr('>', $1, $3); }
			| num_expr EQL num_expr { $$ = define_operator_expr('e', $1, $3); }
			| num_expr LTE num_expr { $$ = define_operator_expr('l', $1, $3); }
			| num_expr GTE num_expr { $$ = define_operator_expr('g', $1, $3); }
			| num_expr AND num_expr { $$ = define_operator_expr('a', $1, $3); }
			| num_expr OR num_expr { $$ = define_operator_expr('o', $1, $3); }
			| NOT num_expr { $$ = define_operator_expr('n', 0, $2); }
			| '(' num_expr ')' { $$ = $2;} ;

%%

void define_func_2(int f_index, struct expr *body, int arg1_idx, int arg2_idx) {
	struct expr *my_f;
	functions[f_index] = my_f = (struct expr*)malloc(sizeof(struct expr));
	my_f->type = func;
	my_f->func.body = body;
	my_f->func.var_1 = arg1_idx;
	my_f->func.var_2 = arg2_idx;
	my_f->func.n_args = 2;
}

void define_func_1(int f_index, struct expr *body, int arg1_idx) {
	struct expr *my_f;
	functions[f_index] = my_f = (struct expr*)malloc(sizeof(struct expr));
	my_f->type = func;
	my_f->func.body = body;
	my_f->func.var_1 = arg1_idx;
	my_f->func.n_args = 1;
}

void define_func_0(int f_index, struct expr *body) {
	struct expr *my_f;
	functions[f_index] = my_f = (struct expr*)malloc(sizeof(struct expr));
	my_f->type = func;
	my_f->func.body = body;
	my_f->func.n_args = 0;
}

struct expr* define_operator_expr(char o, struct expr *arg1, struct expr *arg2) {
	struct expr *ptr = (struct expr*)malloc(sizeof(struct expr));
	ptr->type = oper;	
	ptr->op.op = o;
	ptr->op.arg1 = arg1;
	ptr->op.arg2 = arg2;
	return ptr;
}

double compute_expr(struct expr* expr) {
	double a = 0, b = 0;	
	switch (expr->type) {
		case cond:
			printf("Calculating conditional");
			if (compute_expr(expr->cond.c_expr))
				return compute_expr(expr->cond.t_expr);
			else
				return compute_expr(expr->cond.f_expr);
		case oper: 
			if (expr->op.arg1 != NULL) 
				a = compute_expr(expr->op.arg1);
			if (expr->op.arg2 != NULL) 
				b = compute_expr(expr->op.arg2);
			switch(expr->op.op) {
				case '+': return a + b;
				case '-': return a - b;
				case '*': return a * b;
				case '/': return a / b;
				case '<': return a < b;
				case '>': return a > b;
				case 'e': return a == b;
				case 'l': return a <= b;
				case 'g': return a >= b;
				case 'a': return a && b;
				case 'o': return a || b;
				case 'n': return !b;
				default:
					fprintf(stderr, "Unknown: %c\n", expr->op.op);
					exit(1);
			}
 		case cons:
			return expr->val;
		case var_ident:
	 		return variables[expr->index];
		case fptr:
			return compute_func(expr->index, expr->op.arg1, expr->op.arg2); 
		default: 
			printf("Not implemented action!");
	}
}

double compute_func(int funcptr, struct expr *arg1, struct expr *arg2) {
	struct expr *func = functions[funcptr];
	
	char error = 0;
	switch (func->func.n_args) {
		case 0:
			if (arg1 || arg2) error = 1;
			break;
		case 1:
			if (!arg1 || arg2) error = 1;
			break;
		case 2:
			if (!arg1 || !arg2) error = 1;
			break;
	}
	if (error) {
		printf("Error! Wrong number of arguments!\n");
		return 0;
	}

	double temp_vars[100];
	memcpy(temp_vars, variables, sizeof(double)*100);

	double a = 0, b = 0;
	if (arg1 != NULL) a = compute_expr(arg1);
	if (arg2 != NULL) b = compute_expr(arg2);
	
	if (func->func.n_args == 1 || func->func.n_args == 2) 
		variables[func->func.var_1] = a;
	if (func->func.n_args == 2) 
		variables[func->func.var_2] = b;

	double result = compute_expr(func->func.body);
	
	memcpy(variables, temp_vars, sizeof(double)*100);			
	return result;
}

double set_var(int idx, double val) { 
	variables[idx] = val;
	return val;
}

main() { 
	yyparse(); 
}

yyerror(char *s) { 
	fprintf(stderr, "%s\n", s);
}

