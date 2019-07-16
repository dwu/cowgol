%{
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include "globals.h"

#define YYDEBUG 1
#include "parser.h"

int32_t number;

struct subroutine* current_sub;
struct argumentsspec* current_call;
int current_label = 1;
int break_label;

static struct symbol* intptr_type;
static struct symbol* uint8_type;

static bool is_ptr(struct symbol* sym);
static bool is_num(struct symbol* sym);

static void expr_add(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs);
static void expr_sub(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs);
static void expr_mul(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs);
static void expr_div(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs);
static void expr_rem(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs);
static void cond_equals(int truelabel, int falselabel, struct exprnode* lhs, struct exprnode* rhs);
static void cond_lessthan(int truelabel, int falselabel, struct exprnode* lhs, struct exprnode* rhs);
static void cond_greaterthan(int truelabel, int falselabel, struct exprnode* lhs, struct exprnode* rhs);

static struct symbol* add_new_symbol(const char* name);
static struct symbol* lookup_symbol(const char* name);
static void init_var(struct symbol* sym, struct symbol* type);
static struct symbol* make_pointer_type(struct symbol* type);

static void resolve_expression_type(struct exprnode* node, struct symbol* type);
static void unescape(char* string);

%}

%token VAR SUB TYPE END LOOP WHILE IF THEN BREAK ASM
%token ID NUMBER STRING
%token ASSIGN

%type <symbol> newid;
%type <symbol> oldid;
%type <symbol> typeref;
%type <expr> expression;
%type <labels> LOOP;
%type <labels> WHILE;
%type <labels> IF;

%left LTOP LEOP GTOP GEOP EQOP NEOP
%left '+' '-'
%left '*' '/' '%'

%union {
	struct symbol* symbol;
	struct exprnode expr;
	struct looplabels labels;
	struct argumentsspec argsspec;
}

%%

program
	: statements
		{
			printf(" ret\n");
			printf("w_%s: ds %d\n", current_sub->name, current_sub->workspace);
		}
	;

statements
	: /* empty */
	| statement statements
	;

statement
	: ';'
	| VAR newid ':' typeref ASSIGN expression ';'
		{
			$2->kind = VAR;
			init_var($2, $4);
			resolve_expression_type(&$6, $4);
			arch_assign_var($2);
		}
	| VAR newid ASSIGN expression ';'
		{
			$2->kind = VAR;
			if (!$4.type)
				fatal("types cannot be inferred for numeric constants");
			init_var($2, $4.type);
			resolve_expression_type(&$4, $4.type);
			arch_assign_var($2);
		}
	| SUB newid
		{
			struct subroutine* sub = calloc(1, sizeof(struct subroutine));
			sub->name = $2->name;
			sub->parent = current_sub;
			sub->label_after = current_label++;
			sub->old_break_label = break_label;
			break_label = 0;

			$2->kind = SUB;
			$2->u.sub = sub;

			current_sub = sub;
		}
		parameterlist
		{
			arch_subroutine_prologue();
		}
		statements
		{
			arch_subroutine_epilogue();
			break_label = current_sub->old_break_label;
			current_sub = current_sub->parent;
		}
		END SUB
	| LOOP
		{
			$1.looplabel = current_label++;
			$1.exitlabel = current_label++;
			$1.old_break_label = break_label;
			break_label = $1.exitlabel;
			arch_emit_label($1.looplabel);
		}
		statements END LOOP
		{
			arch_emit_jump($1.looplabel);
			arch_emit_label($1.exitlabel);
			break_label = $1.old_break_label;
		}
	| IF
		{
			$1.truelabel = current_label++;
			$1.falselabel = current_label++;
			$1.looplabel = 0;
		}
		conditional
		THEN
		{
			arch_emit_label($1.truelabel);
		}
		statements
		{
			arch_emit_label($1.falselabel);
		}
		END IF
	| WHILE
		{
			$1.truelabel = current_label++;
			$1.falselabel = current_label++;
			$1.looplabel = current_label++;
			$1.old_break_label = break_label;
			break_label = $1.falselabel;
			arch_emit_label($1.looplabel);
		}
		conditional
		{
			arch_emit_label($1.truelabel);
		}
		LOOP statements END LOOP
		{
			arch_emit_jump($1.looplabel);
			arch_emit_label($1.falselabel);
			break_label = $1.old_break_label;
		}
	| BREAK ';'
		{
			if (!break_label)
				fatal("nothing to break from");
			arch_emit_jump(break_label);
		}
	| ASM {
		arch_asm_start();
		}
		asms ';'
		{
			arch_asm_end();
		}
	| oldid argumentlist ';'
		{
			if ($1->kind != SUB)
				fatal("expected '%s' to be a subroutine", $1->name);
			arch_emit_call($1->u.sub);
		}
	| oldid ASSIGN expression ';'
		{
			if ($1->kind != VAR)
				fatal("expected '%s' to be a variable", $1->name);

			resolve_expression_type(&$3, $1->u.var.type);
			arch_assign_var($1);
		}
	| '[' expression ']' ASSIGN expression ';'
		{
			if (!$2.type->u.type.pointingat)
				fatal("expected LHS to be a pointer");

			resolve_expression_type(&$5, $2.type->u.type.pointingat);
			arch_assign_ptr($2.type);
		}
	;

newid
	: ID { $$ = add_new_symbol(yytext); }
	;

oldid
	: ID { $$ = lookup_symbol(yytext); }
	;

parameterlist
	: '(' parameters ')'
	;

parameters
	: parameter
	| parameter ',' parameters
	;

parameter
	: newid ':' typeref
		{
			$1->kind = VAR;
			init_var($1, $3);
			current_sub->inputparameters++;
		}
	;

argumentlist
	: '('
		{
			struct argumentsspec* spec = calloc(1, sizeof(struct argumentsspec));
			spec->sub = $<symbol>0->u.sub;
			spec->number = 0;
			spec->param = spec->sub->firstsymbol;
			spec->previous_call = current_call;
			current_call = spec;
		}
		arguments ')'
		{
			if (current_call->number != current_call->sub->inputparameters)
				fatal("expected %d parameters but only got %d",
					current_call->sub->inputparameters, current_call->number);
			current_call = current_call->previous_call;
		}
	;

arguments
	: argument
	| argument ',' arguments
	;

argument
	: expression
		{
			if (current_call->number == current_call->sub->inputparameters)
				fatal("too many input parameters");

			struct symbol* param = current_call->param;
			current_call->param = param->next;
			current_call->number++;

			resolve_expression_type(&$1, param->u.var.type);
			arch_push_input_param(param->u.var.type);
		}
	;

typeref
	: oldid
		{
			$$ = $1;
			if ($$->kind != TYPE)
				fatal("expected '%s' to be a type", $1->name);
		}
	| '[' typeref ']'
		{ $$ = make_pointer_type($2); }
	;

expression
	: NUMBER
		{
			$$.type = NULL;
			$$.value = number;
		}
	| STRING
		{
			unescape(yytext);
			arch_push_string_constant(yytext);
			$$.type = make_pointer_type(uint8_type);
		}
	| oldid
		{
			if ($1->kind != VAR)
				fatal("expected '%s' to be a variable", $1->name);

			arch_push_value($1);
			$$.type = $1->u.var.type;
		}
	| '[' expression ']'
		{
			if (!$2.type->u.type.pointingat)
				fatal("attempt to dereference a non-pointer");

			arch_dereference($2.type);
			$$.type = $2.type->u.type.pointingat;
		}
	| '(' expression ')'
		{ $$ = $2; }
	| '-' expression
		{ 
			struct exprnode e;
			e.type = NULL;
			e.value = 0;
			expr_sub(&$$, &e, &$2);
		}
	| expression '+' expression
		{ expr_add(&$$, &$1, &$3); }
	| expression '-' expression
		{ expr_sub(&$$, &$1, &$3); }
	| expression '*' expression
		{ expr_mul(&$$, &$1, &$3); }
	| expression '/' expression
		{ expr_div(&$$, &$1, &$3); }
	| expression '%' expression
		{ expr_rem(&$$, &$1, &$3); }
	;

conditional
	: expression EQOP expression
		{ cond_equals($<labels>-1.truelabel, $<labels>-1.falselabel, &$1, &$3); }
	| expression NEOP expression
		{ cond_equals($<labels>-1.falselabel, $<labels>-1.truelabel, &$1, &$3); }
	| expression LTOP expression
		{ cond_lessthan($<labels>-1.truelabel, $<labels>-1.falselabel, &$1, &$3); }
	| expression GEOP expression
		{ cond_lessthan($<labels>-1.falselabel, $<labels>-1.truelabel, &$1, &$3); }
	| expression GTOP expression
		{ cond_greaterthan($<labels>-1.truelabel, $<labels>-1.falselabel, &$1, &$3); }
	| expression LEOP expression
		{ cond_greaterthan($<labels>-1.falselabel, $<labels>-1.truelabel, &$1, &$3); }
	;

asm
	: STRING
		{
			unescape(yytext);
			arch_asm_string(yytext);
		}
	| oldid
		{
			if ($1->kind != VAR)
				fatal("you can only emit references to variables");
			arch_asm_symbol($1);
		}
	; 

asms
	: asm
	| asm ',' asms
	;

%%

void fatal(const char* s, ...)
{
	va_list ap;
	va_start(ap, s);
	fprintf(stderr, "Error: ");
	vfprintf(stderr, s, ap);
	fprintf(stderr, "\n");
	va_end(ap);
	exit(1);
}

void trace(const char* s, ...)
{
	va_list ap;
	va_start(ap, s);
	fprintf(stderr, "Log: ");
	vfprintf(stderr, s, ap);
	fprintf(stderr, "\n");
	va_end(ap);
}

const char* aprintf(const char* s, ...)
{
	va_list ap;

	va_start(ap, s);
	int len = vsnprintf(NULL, 0, s, ap) + 1;
	va_end(ap);

	char* buffer = malloc(len);
	va_start(ap, s);
	vsnprintf(buffer, len, s, ap);
	va_end(ap);

	return buffer;
}

static bool is_ptr(struct symbol* sym)
{
	if (!sym || (sym->kind != TYPE))
		return false;
	return sym->u.type.pointingat;
}

static bool is_num(struct symbol* sym)
{
	if (!sym)
		return true; /* for numeric constants */
	if (sym->kind != TYPE)
		return false;
	/* For now */
	return !sym->u.type.pointingat;
}

static void expr_add(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!lhs->type && !rhs->type)
	{
		dest->type = NULL;
		dest->value = lhs->value + rhs->value;
	}
	else
	{
		if (is_ptr(lhs->type) && is_ptr(rhs->type))
			fatal("you cannot add two pointers together");
		else if (is_ptr(rhs->type))
			fatal("add numbers to pointers, not vice versa");

		if (lhs->type && !rhs->type)
		{
			arch_add_const(lhs->type, rhs->value);
			dest->type = lhs->type;
		}
		else if (!lhs->type && rhs->type)
		{
			arch_add_const(rhs->type, lhs->value);
			dest->type = rhs->type;
		}
		else if ((lhs->type == rhs->type) ||
                 (is_ptr(lhs->type) && (rhs->type == intptr_type)))
		{
			arch_add(lhs->type);
			dest->type = lhs->type;
		}
		else
			fatal("you tried to add a %s and a %s", lhs->type->name, rhs->type->name);
	}
}

static void expr_sub(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!lhs->type && !rhs->type)
	{
		dest->type = NULL;
		dest->value = lhs->value - rhs->value;
	}
	else
	{
		if (is_ptr(rhs->type))
			fatal("subtract numbers from pointers, not vice versa");

		if (lhs->type && !rhs->type)
		{
			arch_add_const(lhs->type, -rhs->value);
			dest->type = lhs->type;
		}
		else if (!lhs->type && rhs->type)
		{
			arch_subfrom_const(rhs->type, lhs->value);
			dest->type = rhs->type;
		}
		else if ((lhs->type == rhs->type) && is_ptr(lhs->type))
		{
			arch_sub(lhs->type);
			dest->type = intptr_type;
		}
		else if ((lhs->type == rhs->type) ||
                 (is_ptr(lhs->type) && (rhs->type == intptr_type)))
		{
			arch_sub(lhs->type);
			dest->type = lhs->type;
		}
		else
			fatal("you tried to add a %s and a %s", lhs->type->name, rhs->type->name);
	}
}

static void expr_mul(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!is_num(lhs->type) || !is_num(rhs->type))
		fatal("multiplication only works on numbers");

	if (!lhs->type && !rhs->type)
	{
		dest->type = NULL;
		dest->value = lhs->value * rhs->value;
	}
	else
	{
		if (lhs->type && !rhs->type)
		{
			if (rhs->value == 0)
			{
				dest->type = NULL;
				dest->value = 0;
			}
			else
			{
				if (rhs->value != 1)
					arch_mul_const(lhs->type, rhs->value);
				dest->type = lhs->type;
			}
		}
		else if (!lhs->type && rhs->type)
			expr_mul(dest, rhs, lhs);
		else if (lhs->type == rhs->type)
		{
			arch_mul(lhs->type);
			dest->type = intptr_type;
		}
		else
			fatal("you tried to multiply a %s and a %s", lhs->type->name, rhs->type->name);
	}
}

static void expr_div(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!is_num(lhs->type) || !is_num(rhs->type))
		fatal("division only works on numbers");

	if (!rhs->type && (rhs->value == 0))
		fatal("division by zero");

	if (!lhs->type && !rhs->type)
	{
		dest->type = NULL;
		dest->value = lhs->value / rhs->value;
	}
	else
	{
		if (lhs->type && !rhs->type)
		{
			if (rhs->value != 1)
				arch_div_const(lhs->type, rhs->value);
			dest->type = lhs->type;
		}
		else if (!lhs->type && rhs->type)
		{
			arch_div_const_by(rhs->type, lhs->value);
			dest->type = rhs->type;
		}
		else if (lhs->type == rhs->type)
		{
			arch_div(lhs->type);
			dest->type = intptr_type;
		}
		else
			fatal("you tried to divide a %s and a %s", lhs->type->name, rhs->type->name);
	}
}

static void expr_rem(struct exprnode* dest, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!is_num(lhs->type) || !is_num(rhs->type))
		fatal("modulus only works on numbers");

	if (!rhs->type && (rhs->value == 0))
		fatal("division by zero");

	if (!lhs->type && !rhs->type)
	{
		dest->type = NULL;
		dest->value = lhs->value % rhs->value;
	}
	else
	{
		if (lhs->type && !rhs->type)
		{
			if (rhs->value != 1)
				arch_rem_const(lhs->type, rhs->value);
			dest->type = lhs->type;
		}
		else if (!lhs->type && rhs->type)
		{
			arch_rem_const_by(rhs->type, lhs->value);
			dest->type = rhs->type;
		}
		else if (lhs->type == rhs->type)
		{
			arch_rem(lhs->type);
			dest->type = intptr_type;
		}
		else
			fatal("you tried to use modulus on a %s and a %s", lhs->type->name, rhs->type->name);
	}
}

static void cond_equals(int truelabel, int falselabel, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!lhs->type && !rhs->type)
		arch_emit_jump((lhs->value == rhs->value) ? truelabel : falselabel);
	else if (lhs->type && !rhs->type)
		arch_cmp_equals_const(lhs->type, truelabel, falselabel, rhs->value);
	else if (!lhs->type && rhs->type)
		arch_cmp_equals_const(rhs->type, truelabel, falselabel, lhs->value);
	else if (lhs->type == rhs->type)
		arch_cmp_equals(lhs->type, truelabel, falselabel);
	else
		fatal("you tried to compare a %s and a %s", lhs->type->name, rhs->type->name);
}

static void cond_lessthan(int truelabel, int falselabel, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!lhs->type && !rhs->type)
		arch_emit_jump((lhs->value < rhs->value) ? truelabel : falselabel);
	else if (lhs->type && !rhs->type)
		arch_cmp_lessthan_const(lhs->type, truelabel, falselabel, rhs->value);
	else if (!lhs->type && rhs->type)
		arch_cmp_greaterthan_const(rhs->type, truelabel, falselabel, lhs->value);
	else if (lhs->type == rhs->type)
		arch_cmp_lessthan(lhs->type, truelabel, falselabel);
	else
		fatal("you tried to compare a %s and a %s", lhs->type->name, rhs->type->name);
}

static void cond_greaterthan(int truelabel, int falselabel, struct exprnode* lhs, struct exprnode* rhs)
{
	if (!lhs->type && !rhs->type)
		arch_emit_jump((lhs->value < rhs->value) ? truelabel : falselabel);
	else if (lhs->type && !rhs->type)
		arch_cmp_greaterthan_const(lhs->type, truelabel, falselabel, rhs->value);
	else if (!lhs->type && rhs->type)
		arch_cmp_lessthan_const(rhs->type, truelabel, falselabel, lhs->value);
	else if (lhs->type == rhs->type)
		arch_cmp_greaterthan(lhs->type, truelabel, falselabel);
	else
		fatal("you tried to compare a %s and a %s", lhs->type->name, rhs->type->name);
}

void varaccess(const char* opcode, struct symbol* var)
{
	printf(" %s w_%s+%d ; %s\n",
		opcode, var->u.var.sub->name, var->u.var.offset,
		var->name);
}

static struct symbol* add_new_symbol(const char* name)
{
	struct symbol* sym;
	
	if (name)
	{
		sym = current_sub->firstsymbol;
		while (sym)
		{
			if (strcmp(sym->name, name) == 0)
				fatal("symbol '%s' is already defined", name);
			sym = sym->next;
		}
	}

	sym = calloc(1, sizeof(struct symbol));
	sym->name = name ? strdup(name) : NULL;

	if (name)
	{
		if (!current_sub->lastsymbol)
			current_sub->firstsymbol = current_sub->lastsymbol = sym;
		else
		{
			current_sub->lastsymbol->next = sym;
			current_sub->lastsymbol = sym;
		}
	}
	return sym;
}

static struct symbol* lookup_symbol(const char* name)
{
	struct subroutine* scope = current_sub;
	while (scope)
	{
		struct symbol* sym = scope->firstsymbol;
		while (sym)
		{
			if (strcmp(sym->name, name) == 0)
				return sym;
			sym = sym->next;
		}
		scope = scope->parent;
	}

	fatal("symbol '%s' not found", name);
	return NULL;
}

static void init_var(struct symbol* sym, struct symbol* type)
{
	sym->u.var.type = type;
	sym->u.var.sub = current_sub;
	sym->u.var.offset = current_sub->workspace;
	current_sub->workspace += type->u.type.width;
}

static void resolve_expression_type(struct exprnode* node, struct symbol* type)
{
	if (!node->type)
	{
		vpush_const(node->value);
		node->type = type;
		return;
	}

	if (node->type != type)
		fatal("type mismatch: expression was a '%s', used when a '%s' was expected",
			node->type->name, type->name);
}

static struct symbol* make_pointer_type(struct symbol* type)
{
	if (type->u.type.pointerto)
		return type->u.type.pointerto;
	else
	{
		struct symbol* ptr = add_new_symbol(NULL);
		ptr->name = aprintf("[%s]", type->name);
		ptr->kind = TYPE;
		ptr->u.type.width = 2;
		ptr->u.type.pointingat = type;
		type->u.type.pointerto = ptr;
		return ptr;
	}
}

static void unescape(char* string)
{
	char* pin = string;
	char* pout = string;
	char c = *pin++;
	for (;;)
	{
		if (c == '\\')
		{
			c = *pin++;
			switch (c)
			{
				case 'n': c = '\n'; break;
				case 'r': c = '\r'; break;
				case '"': c = '"'; break;
				case '\\': c = '\\'; break;
				default: fatal("unknown string escape");
			}
		}
		*pout++ = c;
		if (!c)
			break;
		c = *pin++;
	}
}

int main(int argc, const char* argv[])
{
	current_sub = calloc(1, sizeof(struct subroutine));
	current_sub->name = "__main";

	struct symbol* s;
	s = add_new_symbol("uint16");
	s->kind = TYPE;
	s->u.type.width = 2;
	intptr_type = s;

	s = add_new_symbol("int16");
	s->kind = TYPE;
	s->u.type.width = 2;
	s->u.type.issigned = true;

	s = add_new_symbol("uint8");
	s->kind = TYPE;
	s->u.type.width = 1;

	s = add_new_symbol("int8");
	s->kind = TYPE;
	s->u.type.width = 1;
	s->u.type.issigned = true;

	yydebug = 0;

	arch_file_prologue();
	yyparse();
	arch_file_epilogue();

	return 0;
}

