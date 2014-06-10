%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Data structures */
typedef enum {cons, var_ident, f_ident, oper, func} nodetype;

struct expr {
  nodetype type;
  union {
    double val; // for cons
    int index; // for var_ident and f_ident
    struct {
      char op;
      struct expr *arg1;
      struct expr *arg2;
    } op; // for oper
	struct {
		struct expr *arg1;
		struct expr *arg2;
		int n_args; // 0,1,2
	} funcptr; // for f_ident
	struct {
		int var_1; // index of allocated variable 1
		int var_2; // index of allocated variable 2
		int n_args; // 0,1,2
		struct expr *body;
	} func; 	
  };
};

double variables[100]; // array of variables
struct expr* functions[100]; // expr

/* Functions and helpers */
double set_var(int idx, double val);

double compute_expr(struct expr* expr);
double compute_func(int funcptr, struct expr *arg1, struct expr *arg2);

void define_func_2(int f_index, struct expr *body, int arg1_idx, int arg2_idx);
void define_func_1(int f_index, struct expr *body, int arg1_idx);
void define_func_0(int f_index, struct expr *body);

%}

%union {
	double d;
	int index;
	struct expr *e;
}

%left '+' '-'
%left '*' '/' '%'
%left UNARY_MINUS UNARY_PLUS


%token <d>		NUM
%token <index>	ID
%token <d>		DEF

%type <d>		expr define define_func // do not return anything
%type <e>		num_expr

%%

expr	 	: expr define '\n' { printf("Variable updated.\n"); }
			| expr define_func '\n' { printf("Functions updated.\n"); }
			| expr num_expr '\n' { printf("%f\n", compute_expr($2)); }
			| expr '\n'
			| { /* empty */ } ;

define		: ID '=' num_expr { set_var($1, compute_expr($3)); } ; 

define_func	: DEF ID '(' ID ',' ID ')' num_expr { define_func_2($2, $8, $4, $6); } // two arguments
			| DEF ID '(' ID ')' num_expr { define_func_1($2, $6, $4); } // one argument
			| DEF ID '(' ')' num_expr { define_func_0($2, $5); } // no arguments

num_expr	: NUM { $$=(struct expr*)malloc(sizeof(struct expr));
		        	$$->type=cons;
					$$->val=$1;
					printf("Reading NUM: %f\n", $1);
				}
			| ID  { $$=(struct expr*)malloc(sizeof(struct expr));
			        $$->type=var_ident;
					$$->index=$1;
				}
			| ID '(' num_expr ',' num_expr ')' { (struct expr*)malloc(sizeof(struct expr);
					$$->type=cons;
					$$->val=compute_func($1, $3, $5);
				}
			| ID '(' num_expr ')' { (struct expr*)malloc(sizeof(struct expr);
					$$->type=cons;
					$$->val=compute_func($1, $3, NULL);
				}
			| ID '(' ')' { (struct expr*)malloc(sizeof(struct expr);
					$$->type=cons;
					$$->val=compute_func($1, NULL, NULL);
				}
			| '-' num_expr %prec UNARY_MINUS { $$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=oper;
					$$->op.op='-';
					$$->op.arg2=$2;
				}
			| '+' num_expr %prec UNARY_PLUS  { $$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=oper;
					$$->op.op='+';
					$$->op.arg2=$2;
				}
			| num_expr '+' num_expr { $$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=oper;
					$$->op.op='+';
					$$->op.arg1=$1;
					$$->op.arg2=$3;
				}
			| num_expr '-' num_expr { $$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=oper;
					$$->op.op='-';
					$$->op.arg1=$1;
					$$->op.arg2=$3;
				}
			| num_expr '*' num_expr { $$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=oper;
					$$->op.op='*';
					$$->op.arg1=$1;
					$$->op.arg2=$3;
				}
			| num_expr '/' num_expr { $$ = (struct expr*)malloc(sizeof(struct expr));
					$$->type=oper;
					$$->op.op='/';
					$$->op.arg1=$1;
					$$->op.arg2=$3;
				}
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

double compute_expr(struct expr* expr) {
	double a = 0, b = 0;	
	switch (expr->type) {
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
				default:
					fprintf(stderr, "Unknown: %c\n", expr->op.op);
					exit(1);
			}
 		case cons:
			return expr->val;
		case var_ident:
	 		return variables[expr->index];
		case f_ident:
			// Might be an error ---->
			return compute_func(functions[expr->index], expr->funcptr.arg1, expr->funcptr.arg2);
		default: 
			printf("Not implemented action!");
	}
}

// should pass arg1 arg2? can possibly take out of funcptr?
double compute_func(int funcptr, struct expr *arg1, struct expr *arg2) {
	/* Copy 'stack' */
	double temp_vars[100];
	memcpy(temp_vars, variables, sizeof(double)*100);

	/* Compute arg1 and arg2 as a and b */
	double a = 0, b = 0;
	if (arg1 != NULL) a = compute_expr(arg1);
	if (arg2 != NULL) b = compute_expr(arg2);
	struct expr *func = functions[funcptr];
	
	/* Store results in the variables array */
	variables[func.func->var_1] = a;
	variables[func.func->var_2] = b;

	/* Eval function body (using the variables array) */
	double result = compute_expr(func.func->body);
	
	/* Restore 'stack' */
	memcpy(variables, temp_vars, sizeof(double)*100);		
	
	/* Return result */
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

