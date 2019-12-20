#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include "globals.h"
#include "emitter.h"
#include "midcode.h"
#include "compiler.h"
#include "parser.h"

struct includepath* includes;
static const char* inputfile;
static const char* outputfile;

void fatal(const char* s, ...)
{
	va_list ap;
	va_start(ap, s);
	fprintf(stderr, "%d: ", yylineno);
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

static void syntax_error(void)
{
	fatal("syntax error: cowc [-Ipath] <infile>");
}

static void add_include_path(const char* path)
{
	struct includepath* newinclude = calloc(sizeof(struct includepath), 1);
	newinclude->path = path;
	newinclude->next = includes;
	includes = newinclude;
}

static void parse_arguments(int argc, char* argv[])
{
	for (;;)
	{
		int opt = getopt(argc, argv, "I:");
		if (opt == -1)
			break;
		switch (opt)
		{
			case 'I':
				add_include_path(optarg);
				break;
			
			default:
				syntax_error();
		}
	}

	if ((argc - optind) != 2)
		syntax_error();
	inputfile = argv[optind+0];
	outputfile = argv[optind+1];
}

int main(int argc, char* argv[])
{
	parse_arguments(argc, argv);
	add_include_path("./");

	current_sub = calloc(1, sizeof(struct subroutine));
	current_sub->name = "__main";
	current_sub->externname = "cmain";

	include_file(open_file(inputfile));

	emitter_open(outputfile);
	emitter_open_chunk();

	midend_init();
	arch_init_types();
	arch_init_subroutine(current_sub);
	emit_mid_startfile();
	emit_mid_startsub(current_sub);

	void* parser = ParseAlloc(malloc);
	// ParseTrace(stderr, "P:");

	for (;;)
	{
		int token = yylex();
		if (!token)
			break;
		switch (token)
		{
			case NUMBER:
				Parse(parser, token, make_number_token(number));
				break;

			case ID:
			case STRING:
				Parse(parser, token, make_string_token(yytext));
				break;

			default:
				Parse(parser, token, NULL);
				break;
		}
	}
	Parse(parser, 0, NULL);

	emit_mid_endsub(current_sub);
	emit_mid_endfile();
    midend_flush(0);

	emitter_close_chunk();
	emitter_close();

	return 0;
}