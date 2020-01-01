%{
#include "globals.h"
#include "midcode.h"
#include "emitter.h"
#include "regalloc.h"
#include <ctype.h>
#include <bsd/string.h>

/* Workspaces used by the 8080 code generator:
 *
 * 0 = variables (this one always is)
 * 1, 2, 3 = unused
 */

struct subarch
{
    int id;
};

static int id = 1;

enum
{
    REG_A = 1<<0,
    REG_B = 1<<1,
    REG_D = 1<<2,
    REG_H = 1<<3,
    REG_BC = 1<<4,
    REG_DE = 1<<5,
    REG_HL = 1<<6,

    REG_16 = REG_BC | REG_DE | REG_HL,
    REG_8 = REG_A | REG_B | REG_D | REG_H
};

#define E emitter_printf

void arch_init_types(void)
{
	make_number_type("uint32", 4, false);
	make_number_type("int32", 4, true);
	intptr_type = make_number_type("uint16", 2, false);
	make_number_type("int16", 2, true);
	uint8_type = make_number_type("uint8", 1, false);
	make_number_type("int8", 1, true);

	add_alias(NULL, "intptr", intptr_type);

	/* Registers C and E are not used by the code generator. This is so
	 * we can push and pop any 8-bit value and have them all interoperate ---
	 * so, AF, BC, DE use A, B, D respectively. */

    regalloc_add_register("a", REG_A, REG_A);
    regalloc_add_register("b", REG_B, REG_B | REG_BC);
    regalloc_add_register("d", REG_D, REG_D | REG_DE);
    regalloc_add_register("h", REG_H, REG_H | REG_HL);
    regalloc_add_register("b", REG_BC, REG_B | REG_BC);
    regalloc_add_register("d", REG_DE, REG_D | REG_DE);
    regalloc_add_register("h", REG_HL, REG_H | REG_HL);
}

static const char* regnamelo(reg_t id)
{
    switch (id)
    {
        case REG_BC: return "c";
        case REG_DE: return "e";
        case REG_HL: return "l";
    }
    assert(false);
    return NULL;
}

static reg_t eightbitof(reg_t r)
{
	switch (r)
	{
		case REG_BC: return REG_B;
		case REG_DE: return REG_D;
		case REG_HL: return REG_H;
	}
	assert(false);
	return 0;
}

void arch_init_subroutine(struct subroutine* sub)
{
    sub->arch = calloc(1, sizeof(struct subarch));
    sub->arch->id = id++;
}

void arch_init_variable(struct symbol* var)
{
	/* All variables get allocated from workspace 0. */
	current_sub->workspace[0] += var->u.var.type->u.type.width;
}

void arch_emit_comment(const char* text, ...)
{
    va_list ap;
    va_start(ap, text);
    emitter_printf("\t; ");
    emitter_vprintf(text, ap);
    emitter_printf("\n");
    va_end(ap);
}

void arch_load_const(reg_t id, int32_t num)
{
    if (id & REG_16)
        E("\tlxi %s, %d\n", regname(id), num & 0xffff);
    else
	{
		if ((id == REG_A) && (num == 0))
			E("\txor a\n");
		else
			E("\tmvi %s, %d\n", regname(id), num & 0xff);
	}
}

void arch_load_var(reg_t id, struct symbol* sym, int32_t off)
{
    assert(id & (REG_HL|REG_A));
    if (id & REG_HL)
        E("\tlhld %s\n", symref(sym, off));
    else
        E("\tlda %s\n", symref(sym, off));
}

void arch_push(reg_t id)
{
    E("\tpush %s\n", (id == REG_A) ? "psw" : regname(id));
}

void arch_pop(reg_t id)
{
    E("\tpop %s\n", (id == REG_A) ? "psw" : regname(id));
}

void arch_copy(reg_t src, reg_t dest)
{
    if (src & REG_16)
        E("\tmov %s, %s\n", regnamelo(dest), regnamelo(src));
    E("\tmov %s, %s\n", regname(dest), regname(src));
}

reg_t arch_save(reg_t reg, reg_t forbidden)
{
    arch_emit_comment("attempting to save 0x%x anywhere except 0x%x", reg, forbidden);

    if ((reg == REG_HL) && !(forbidden & REG_DE))
    {
        E("\txchg\n");
        return REG_DE;
    }
    if ((reg == REG_DE) && !(forbidden & REG_HL))
    {
        E("\txchg\n");
        return REG_HL;
    }
    if (reg & REG_8)
    {
        reg_t candidates = REG_8 & ~forbidden;
        reg_t dest = 1;
        while (dest)
        {
            if (candidates & dest)
            {
                arch_copy(reg, dest);
                return dest;
            }
            dest <<= 1;
        }
    }

    return 0;
}

%}

statement: STARTFILE
{
    emitter_open_chunk();
    E("\textrn add4\n");
    E("\textrn sub4\n");
    E("\textrn neg4\n");
    E("\textrn cpy4\n");
    E("\textrn asl1\n");
    E("\textrn asl2\n");
	E("\textrn lsr1\n");
	E("\textrn lsr2\n");
	E("\textrn lsr4\n");
	E("\textrn asr1\n");
	E("\textrn asr2\n");
	E("\textrn cmpu4\n");
    emitter_close_chunk();
}

statement: ENDFILE;

statement: STARTSUB:s
{
    emitter_open_chunk();
    E("\n");
    E("; %s\n", $s.sub->name);
    E("\tcseg\n");
    if ($s.sub->externname)
        E("\tpublic %s\n", $s.sub->externname);
    E("%s:\n", subref($s.sub));

    if ($s.sub->inputparameters != 0)
    {
        E("\tpop b\n");
        for (int i=$s.sub->inputparameters-1; i>=0; i--)
        {
			struct symbol* param = $s.sub->namespace.firstsymbol;
			for (int j=0; j<i; j++)
				param = param->next;

			if (param->u.var.type->u.type.width == 1)
			{
				E("\tpop psw\n");
				E("\tsta %s\n", symref(param, 0));
			}
			else
			{
				E("\tpop h\n");
				E("\tshld %s\n", symref(param, 0));
			}
        }
        E("\tpush b\n");
    }
}

statement: ENDSUB:s
{
	E("end_%s:\n", subref($s.sub));
	if ($s.sub->outputparameters != 0)
	{
		E("\tpop h\n");
		E("\txchg\n"); /* put return address in DE */

		for (int i=0; i<$s.sub->outputparameters; i++)
		{
			struct symbol* param = $s.sub->namespace.firstsymbol;
			for (int j=0; j<(i + $s.sub->inputparameters); j++)
				param = param->next;

			if (param->u.var.type->u.type.width == 1)
			{
				E("\tlda %s\n", symref(param, 0));
				E("\tpush psw\n");
			}
			else
			{
				E("\tlhld %s\n", symref(param, 0));
				E("\tpush h\n");
			}
		}

		E("\txchg\n");
		E("\tpchl\n");
	}
	else
		E("\tret\n");

    E("\tdseg\n");
	E("w%d: ds %d\n", $s.sub->arch->id, $s.sub->workspace[0]);
    emitter_close_chunk();
}

// --- Core conversions --------------------------------------------------

address: ADDRESS:s
{
	$$.sym = $s.sym;
	$$.off = 0;
}

constant: CONSTANT:c
{
	$$.off = $c.value;
}

reg1: reg1a;
reg1: reg1bdh;
reg2: reg2hl;
reg2: reg2bcde;

reg1a: reg1
{ regalloc_push(regalloc_pop(REG_A)); }

reg1bdh: reg1
{ regalloc_push(regalloc_pop(REG_B | REG_D | REG_H)); }

reg2hl: reg2
{ regalloc_push(regalloc_pop(REG_HL)); }

reg2bcde: reg2
{ regalloc_push(regalloc_pop(REG_BC | REG_DE)); }

%{
	static void loadaddress(reg_t mask, struct symbol* sym, int off)
	{
		reg_t r = regalloc_alloc(mask);
		E("\tlxi %s, %s\n", regname(r), symref(sym, off));
		regalloc_push(r);
	}
%}
