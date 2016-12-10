/* IBM_PROLOG_BEGIN_TAG                                                   */
/* This is an automatically generated prolog.                             */
/*                                                                        */
/* OpenPOWER Project                                                      */
/*                                                                        */
/* Contributors Listed Below - COPYRIGHT 2012,2016                        */
/* [+] International Business Machines Corp.                              */
/*                                                                        */
/*                                                                        */
/* Licensed under the Apache License, Version 2.0 (the "License");        */
/* you may not use this file except in compliance with the License.       */
/* You may obtain a copy of the License at                                */
/*                                                                        */
/*     http://www.apache.org/licenses/LICENSE-2.0                         */
/*                                                                        */
/* Unless required by applicable law or agreed to in writing, software    */
/* distributed under the License is distributed on an "AS IS" BASIS,      */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        */
/* implied. See the License for the specific language governing           */
/* permissions and limitations under the License.                         */
/*                                                                        */
/* IBM_PROLOG_END_TAG                                                     */




// ** WARNING : This file is maintained as part of the OCC firmware.  Do **
// ** not edit this file in the PMX area or the hardware procedure area  **
// ** as any changes will be lost.                                       **                                                    **

/// \file pore_inline_disassembler.c
/// \brief An inline disassembler for PgP/Stage1 PORE programs
///
/// This file requires APIs present in pore_inline_assembler.c, but not vice
/// versa.  For full documentation see the page \ref pore_inline_assembler.
///
/// \bug The disassembler does not check whether unused bits of the
/// instructions are zero, and does not check that register operands are legal
/// for the instruction.  

#include "pore_inline.h"

// The OCC environment does not include <stdio.h>
#ifdef __SSX__
#include "ssx_io.h"
#else
#include <stdio.h>
#endif

// I really don't know why this is necessary - somehow GCC does not know that
// uint64_t is the same as unsigned long long on Intel 64-bit platforms, and
// the printf() format checker issues a warning.

#define ULL(x) ((unsigned long long)(x))


// From a uint32_t, extract a big-endian bit x[i] as either 0 or 1

#define BE_BIT_32(x, i) (((x) >> (31 - (i))) & 1)


// From a uint32_t, extract big-endian bits x[first:last] as unsigned to
// create a uint32_t.

#define BE_BITS_32_UNSIGNED(x, first, last) \
    (((x) >> (31 - (last))) & (0xffffffff >> (32 - (last - first + 1))))


// From a uint32_t, extract big-endian bits x[first:last] as signed to create
// an int32_t.

#define BE_BITS_32_SIGNED(x, first, last) \
    (((x) & (1 << (31 - (first)))) ? \
     (BE_BITS_32_UNSIGNED(x, first, last) | (0xffffffff << (31 - first))) : \
     BE_BITS_32_UNSIGNED(x, first, last))


// To consider: This is a sparse table - storage space could be reduced by
// replacing this with an indirect table - i.e., a table of bytes that are
// indices into the actual table of strings.

PORE_STATIC const char* pore_opcode_strings[128] = {
    "?", 			/* 0x00 */
    "waits", 			/* 0x01 */
    "trap", 			/* 0x02 */
    "?", 			/* 0x03 */
    "?", 			/* 0x04 */
    "?", 			/* 0x05 */
    "?", 			/* 0x06 */
    "?", 			/* 0x07 */
    "?", 			/* 0x08 */
    "?", 			/* 0x09 */
    "?", 			/* 0x0a */
    "?", 			/* 0x0b */
    "?", 			/* 0x0c */
    "?", 			/* 0x0d */
    "?", 			/* 0x0e */
    "nop", 			/* 0x0f */
    "bra", 			/* 0x10 */
    "?", 			/* 0x11 */
    "braz", 			/* 0x12 */
    "branz", 			/* 0x13 */
    "bsr", 			/* 0x14 */
    "ret", 			/* 0x15 */
    "?", 			/* 0x16 */
    "?", 			/* 0x17 */
    "?", 			/* 0x18 */
    "?", 			/* 0x19 */
    "?", 			/* 0x1a */
    "?", 			/* 0x1b */
    "brad", 			/* 0x1c */
    "bsrd", 			/* 0x1d */
    "?", 			/* 0x1e */
    "loop", 			/* 0x1f */
    "?", 			/* 0x20 */
    "?", 			/* 0x21 */
    "?", 			/* 0x22 */
    "add", 			/* 0x23 */
    "adds", 			/* 0x24 */
    "and", 			/* 0x25 */
    "or", 			/* 0x26 */
    "xor", 			/* 0x27 */
    "subs", 			/* 0x28 */
    "sub", 			/* 0x29 */
    "neg", 			/* 0x2a */
    "?", 			/* 0x2b */
    "mr", 			/* 0x2c */
    "?", 			/* 0x2d */
    "rols", 			/* 0x2e */
    "?", 			/* 0x2f */
    "ls", 			/* 0x30 */
    "?", 			/* 0x31 */
    "ld", 			/* 0x32 */ /* ld0 */
    "?", 			/* 0x33 */
    "?", 			/* 0x34 */
    "?", 			/* 0x35 */
    "ld", 			/* 0x36 */ /* ld1 */
    "?", 			/* 0x37 */
    "?", 			/* 0x38 */
    "std", 			/* 0x39 */ /* std0 */
    "std", 			/* 0x3a */ /* std1 */
    "?", 			/* 0x3b */
    "?", 			/* 0x3c */
    "?", 			/* 0x3d */
    "?", 			/* 0x3e */
    "?", 			/* 0x3f */
    "?", 			/* 0x40 */
    "?", 			/* 0x41 */
    "?", 			/* 0x42 */
    "?", 			/* 0x43 */
    "?", 			/* 0x44 */
    "?", 			/* 0x45 */
    "?", 			/* 0x46 */
    "?", 			/* 0x47 */
    "?", 			/* 0x48 */
    "?", 			/* 0x49 */
    "?", 			/* 0x4a */
    "?", 			/* 0x4b */
    "?", 			/* 0x4c */
    "?", 			/* 0x4d */
    "?", 			/* 0x4e */
    "hooki", 			/* 0x4f */
    "?", 			/* 0x50 */
    "braia", 			/* 0x51 */
    "?", 			/* 0x52 */
    "?", 			/* 0x53 */
    "?", 			/* 0x54 */
    "?", 			/* 0x55 */
    "cmpibraeq",		/* 0x56 */
    "cmpibrane",		/* 0x57 */
    "cmpibsreq",		/* 0x58 */
    "?", 			/* 0x59 */
    "?", 			/* 0x5a */
    "?", 			/* 0x5b */
    "?", 			/* 0x5c */
    "?", 			/* 0x5d */
    "?", 			/* 0x5e */
    "?", 			/* 0x5f */
    "andi", 			/* 0x60 */
    "ori", 			/* 0x61 */
    "xori", 			/* 0x62 */
    "?", 			/* 0x63 */
    "?", 			/* 0x64 */
    "?", 			/* 0x65 */
    "?", 			/* 0x66 */
    "?", 			/* 0x67 */
    "?", 			/* 0x68 */
    "?", 			/* 0x69 */
    "?", 			/* 0x6a */
    "?", 			/* 0x6b */
    "?", 			/* 0x6c */
    "?", 			/* 0x6d */
    "?", 			/* 0x6e */
    "?", 			/* 0x6f */
    "?", 			/* 0x70 */
    "li", 			/* 0x71 */
    "?", 			/* 0x72 */
    "ldandi", 			/* 0x73 */ /* ld0andi */

#ifdef IGNORE_HW274735

    // BSI and BCI are normally redacted due to HW274735

    "bsi",                      /* 0x74 */
    "bci",                      /* 0x75 */

#else

    "?", 			/* 0x74 */
    "?", 			/* 0x75 */

#endif // IGNORE_HW274735

    "?", 			/* 0x76 */
    "ldandi", 			/* 0x77 */ /* ld1andi */
    "sti", 			/* 0x78 */
    "?", 			/* 0x79 */
    "?", 			/* 0x7a */
    "?", 			/* 0x7b */
    "scand", 			/* 0x7c */
    "", 			/* 0x7d */
    "?", 			/* 0x7e */
    "?"				/* 0x7f */
};


/// Install and decode an instruction into the PoreInlineDissassembly object
///
/// \param dis A PoreInlineDisassembly structure to contain the disassembled
/// instruction.
///
/// \param instruction The initial (or only) 32 bits of a PORE instruction
///
/// For simplicity, instructions are currently (almost) fully decoded for all
/// possible formats. It is up to the application using this API to further
/// decode the actual opcode to determine which of these fields are valid for
/// the current instruction.
///
/// To simplify parity calculations the \a imd64 field is cleared here. A
/// companion API pore_inline_decode_imd64() is used to decode the final 64
/// bits of long instructions.
///
/// This API is designed to be called independently of the full disassembler,
/// in which case any fields of \a dis not explicitly set will be undefined.

void
pore_inline_decode_instruction(PoreInlineDisassembly* dis, uint32_t instruction)
{
    dis->instruction = instruction;

    // Generic decoding

    dis->opcode           = BE_BITS_32_UNSIGNED(instruction, 0, 6);
    dis->long_instruction = BE_BIT_32(instruction, 0);
    dis->parity           = BE_BITS_32_UNSIGNED(instruction, 7, 7);
    dis->memory_space     = BE_BIT_32(instruction, 8);
    dis->update           = BE_BIT_32(instruction, 8);
    dis->capture          = BE_BIT_32(instruction, 9);
    dis->imd16            = BE_BITS_32_SIGNED(instruction, 16, 31);
    dis->scan_length      = BE_BITS_32_UNSIGNED(instruction, 16, 31);
    dis->imd20            = BE_BITS_32_SIGNED(instruction, 12, 31);
    dis->imd24            = BE_BITS_32_UNSIGNED(instruction, 8, 31);
    dis->impco20          = BE_BITS_32_SIGNED(instruction, 12, 31);
    dis->impco24          = BE_BITS_32_SIGNED(instruction, 8, 31);
    dis->r0               = BE_BITS_32_UNSIGNED(instruction, 8, 11);
    dis->r1               = BE_BITS_32_UNSIGNED(instruction, 12, 15);
    dis->imd64            = 0;

    // imA24 decoding

    if (dis->memory_space) {
        dis->base_register = 
            BE_BIT_32(instruction, 9) ? A1 : A0;
        dis->memory_offset = BE_BITS_32_UNSIGNED(dis->instruction, 10, 31);
    } else {
        dis->base_register = 
            BE_BIT_32(instruction, 9) ? P1 : P0;
        dis->pib_offset = BE_BITS_32_UNSIGNED(dis->instruction, 12, 31);
    }
}

    
/// Install and decode an imd64 into a PoreInlineDissassembly object
///
/// \param dis A PoreInlineDisassembly structure to contain the disassembled
/// data
///
/// \param imd64 The final 64 bits of a 12-byte PORE instruction
///
/// For simplicity, instructions are currently (almost) fully decoded for all
/// possible formats. It is up to the application to determine which if any of
/// these fields are valid for the current instruction.
///
/// This API is designed to be called independently of the full disassembler,
/// in which case any fields of \a dis not explicitly set will be undefined.

void
pore_inline_decode_imd64(PoreInlineDisassembly* dis, uint64_t imd64)
{
    dis->imd64 = imd64;
    dis->scan_select = imd64 >> 32;
    dis->scan_offset = imd64 & 0xffffffff;
}


// Get the 64-bit immediate from the context if required.  Also update the
// string-form suffix buffer if we're operating in listing mode.

PORE_STATIC int
pore_get_imd64(PoreInlineContext *ctx, PoreInlineDisassembly *dis,
               char **suffix, char *suffix_buffer)
{
    if (ctx->remaining < 8) {
	ctx->error = PORE_INLINE_NO_MEMORY;
    } else {

	pore_inline_decode_imd64(dis, pore_inline_host64(ctx->lc_address));
	
	if (ctx->options & PORE_INLINE_LISTING_MODE) {
	    sprintf(suffix_buffer, "\n%08x %08x\n%08x %08x",
		    ctx->lc, (uint32_t)(dis->imd64 >> 32),
		    ctx->lc + 4, (uint32_t)(dis->imd64 & 0xffffffff));
	    *suffix = suffix_buffer;
	}

	pore_inline_context_bump(ctx, 8);
    }
    return ctx->error != 0;
}


// By default branches are printed as relative to the current PC.  In
// listing mode branches are to absolute location counters.

PORE_STATIC char *
pore_branch_target(PoreInlineContext *ctx, 
                   char *target, PoreInlineLocation lc, int32_t offset)
{
    if (ctx->options & PORE_INLINE_LISTING_MODE) {
	sprintf(target, "0x%08x", (PoreInlineLocation)(lc + offset));
    } else {
	sprintf(target, "(. + %d)", offset);
    }
    return target;
}


// Disassemble in data-disassembly mode.  The disassembly includes a character
// dump as a comment.

PORE_STATIC void
pore_disassemble_data(PoreInlineContext* ctx, PoreInlineDisassembly* dis)
{
    char directive[30], c[8], data[17];
    int i, bytes;

    if (ctx->remaining == 0) {
        ctx->error = PORE_INLINE_NO_MEMORY;

    } else if ((ctx->remaining < 4) || ((ctx->lc % 4) != 0)) {

        dis->data = *((uint8_t*)(ctx->lc_address));
        dis->data_size = 1;
        sprintf(data, "%02x              ", (uint8_t)(dis->data));
        c[0] = *((char*)(ctx->lc_address));
        c[0] = isprint(c[0]) ? c[0] : '.';

        sprintf(directive, "\t.byte\t0x%02x              \t// %c", 
                (uint8_t)(dis->data), c[0]);

    } else if ((ctx->options & PORE_INLINE_8_BYTE_DATA) &&
               (ctx->remaining >= 8) && ((ctx->lc % 8) == 0)) {

        dis->data = pore_inline_host64(ctx->lc_address);
        dis->data_size = 8;
        sprintf(data, "%016llx", (unsigned long long)(dis->data));
        for (i = 0; i < 8; i++) {
            c[i] = *((char*)(ctx->lc_address + i));
            c[i] = isprint(c[i]) ? c[i] : '.';
        }
        
        sprintf(directive, "\t.quad\t0x%016llx\t// %c%c%c%c%c%c%c%c", 
                (unsigned long long)(dis->data),
                c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7]);

    } else {                    /* Known to be at least 4-bytes and aligned */

        dis->data = pore_inline_host32(ctx->lc_address);
        dis->data_size = 4;
        sprintf(data, "%08llx        ", (unsigned long long)(dis->data));
        for (i = 0; i < 4; i++) {
            c[i] = *((char*)(ctx->lc_address + i));
            c[i] = isprint(c[i]) ? c[i] : '.';
        }
        
        sprintf(directive, "\t.long\t0x%08x\t// %c%c%c%c", 
                (uint32_t)(dis->data),
                c[0], c[1], c[2], c[3]);
    }        

    if (ctx->error == 0) {

        if (ctx->options & PORE_INLINE_LISTING_MODE) {
            bytes = snprintf(dis->s, 
                             PORE_INLINE_DISASSEMBLER_STRING_SIZE,
                             "%08x %s%s",
                             ctx->lc, data, directive);
        } else {
            bytes = snprintf(dis->s, 
                             PORE_INLINE_DISASSEMBLER_STRING_SIZE,
                             "%s",
                             directive);
        }

        if (bytes >= PORE_INLINE_DISASSEMBLER_STRING_SIZE) {
            ctx->error = PORE_INLINE_DISASSEMBLY_OVERFLOW;
        } else {
            pore_inline_context_bump(ctx, dis->data_size);
        }
    }
}


/// Disassemble the next PORE instruction (or data) from a context
///
/// \param ctx A PoreInlineContext initialized with a host memory area
/// containing the PORE code (or data) to disassemble.
///
/// \param dis A PoreInlineDisassembly structure to contain the disassembled
/// code (or data). See the usage notes below.
///
/// Calling this API disassembles the next instruction (or data) in the host
/// memory context (\a ctx), and updates the user-supplied disassembly
/// structure (\a dis) with the result.  The initial comments refer to the
/// normal case that text (code) is being disassembled.
///
/// The \a dis structure contains both binary and string forms of the
/// disassembly.  The binary form is decoded into a number of fields of the \a
/// dis structure.  The string form is stored as \a dis->s.  By default the
/// string form is suitable to be printed and used as the input to the
/// assembler.  If the option PORE_INLINE_LISTING_MODE is present in the
/// context, then the string form is generated in a way suitable for printing
/// as a disassembly listing.
///
/// Note that the disassembly string is \e not terminated by a newline.
/// However also note that in listing mode, the disassembly string \a will
/// contain embedded newlines for long instructions.
///
/// If using the binary disassembly, it is up to the caller to determine which
/// of the many overlapping fields are actually valid based on the opcode.
/// This is done by reference to the PgP PORE specification, and by examining
/// the source code of the disassembler.  The \a dis object is not cleared
/// between disassembly of multiple instructions.  The caller should assume
/// that any of the binary fields that are not part of the current disassembly
/// contain garbage.  Only the following fields of the \a dis object are
/// guaranteed to be valid after every successful call:
///
/// - \a dis->opcode : The 7-bit PORE opcode
/// - \a dis->parity : The parity bit.  
/// - \a dis->s : The string form of the disassembly
///
/// Note that the disassembler will not work well if data is mixed with code,
/// as the data may or may not appear to be legal PORE instructions. By
/// default, if an illegal PORE instruction is encountered, the disassembler
/// will refuse to disassemble the instruction and return the error
/// PORE_INLINE_UNKNOWN_OPCODE.  However, if the option
/// PORE_INLINE_DISASSEMBLE_UNKNOWN appears in the context then an
/// unrecognized opcode will be disassembled as if it were 4 bytes of data.
///
/// See \ref pore_inline_assembler for example code.
///
/// If the option PORE_INLINE_DISASSEMBLE_DATA is present in the context, then
/// the disassembler will disassemble as data.  If the context is 8-byte
/// aligned and contains at least 8 bytes, then the next 8 bytes are
/// disassembled as a .quad directive.  Otherwise odd bytes are disassembled
/// as .byte directives.  If disassembling as data, then dis->data contains
/// the data in host byte order, and dis->data_size is either 1 or 8 and
/// indicates the size of the disassembeld data.
///
/// \retval 0 Success.
///
/// \retval code A non-zero error code is returned in the event of an error.
/// The error code is also stored in the \a error field of the context.  In
/// the event of an error, the \a ctx argument is not changed except for
/// updating the \a error field.

// This function works by doing a generic binary disassembly, then creates
// several strings that are concatenated together to produce the final string
// disassembly:
//
// prefix         : Optional location counter and disassembly
// opcode         : Sourced directly from pore_opcode_strings[]
// operand[0,1,2] : As required
// suffix         : Optional disassembly of 64-bit immediates
//
// Some instructions also need to populate specific binary disassembly fields.
//
// To consider: It may be possible to reduce the stack-based data storage
// requirements and improve efficiency of the disassembly string generation by
// creating the disassembly string in place, rather than by creating and then
// later assembling the individual pieces of the string. It's not clear
// whether this would be a win for code size, though.

int
pore_inline_disassemble(PoreInlineContext *ctx, PoreInlineDisassembly *dis)
{
    int error;
    char **register_strings;
    char *prefix, *operand[5], *suffix;
    char prefix_string[20], suffix_string[40];
    char target_string[20], operand_string[5][20];
    char offset_string[20], unknown_string[20];
    PoreInlineLocation lc;
    const char *tab = "\t", *empty = "", *halt = "halt";
    const char *binary[2] = {"0", "1"};
    const char *opcode;
    int bytes;
    
    // See comments above for pore_inline_register_strings ...

    register_strings = (char **)pore_inline_register_strings;

    ctx->error = 0;
    pore_inline_context_copy(&(dis->ctx), ctx);
    dis->is_data = 0;

    if (ctx->options & PORE_INLINE_DISASSEMBLE_DATA) {
        pore_disassemble_data(ctx, dis);
        dis->is_data = 1;

    } else if (((ctx->lc % 4) != 0) || (((ctx->lc_address) % 4) != 0)) {
	ctx->error = PORE_INLINE_ALIGNMENT_ERROR;

    } else if (ctx->remaining < 4) {
	ctx->error = PORE_INLINE_NO_MEMORY;

    } else {

	// In listing mode the string prefix consists of the location counter
	// and instruction, otherwise it's simply a tab.  The suffix is set to
	// the default empty string here and will be reset for instructions
	// with 64-bit immediates.

	lc = ctx->lc;
        pore_inline_decode_instruction(dis, 
                                       pore_inline_host32(ctx->lc_address));

	if (ctx->options & PORE_INLINE_LISTING_MODE) {
	    sprintf(prefix_string, "%08x %08x\t", 
		    ctx->lc, dis->instruction);
	    prefix = prefix_string;
	} else {
	    prefix = (char *)tab; // Compiler requires cast
	}
	suffix = (char *)empty; // Compiler requires cast

	pore_inline_context_bump(ctx, 4);

	// Also for simplicity, string forms are assembled using standard
	// templates, based on the number of operands.  The string form of the
	// opcode may be overwritten for special forms.

	operand[0] = 0;
	operand[1] = 0;
	operand[2] = 0;
	operand[3] = 0;
	operand[4] = 0;

        opcode = pore_opcode_strings[dis->opcode];

        // Disassemble

	switch (dis->opcode) {

	case PGAS_OPCODE_NOP:
	case PGAS_OPCODE_TRAP:
	case PGAS_OPCODE_RET:

	    break;
	    
        case PGAS_OPCODE_HOOKI:

	    if (pore_get_imd64(ctx, dis, &suffix, suffix_string) == 0) {
                operand[0] = &(operand_string[0][0]);
                operand[1] = &(operand_string[1][0]);
                sprintf(operand[0], "%d", dis->imd24);
                sprintf(operand[1], "0x%016llx", ULL(dis->imd64));
            }
	    break;
	    
	case PGAS_OPCODE_WAITS:

            if (dis->imd24 == 0) {
                opcode = halt;
            } else {
                operand[0] = &(operand_string[0][0]);
                sprintf(operand[0], "%d", dis->imd24);
            }
	    break;

	case PGAS_OPCODE_BRA:
	case PGAS_OPCODE_BSR:
	case PGAS_OPCODE_LOOP:

	    operand[0] = 
		pore_branch_target(ctx, target_string, lc, dis->impco24 * 4);
	    break;

	case PGAS_OPCODE_BRAZ:
	case PGAS_OPCODE_BRANZ:

	    operand[0] = register_strings[dis->r0];
	    operand[1] = 
		pore_branch_target(ctx, target_string, lc, dis->impco20 * 4);
	    break;

	case PGAS_OPCODE_CMPIBRAEQ:
	case PGAS_OPCODE_CMPIBRANE:
	case PGAS_OPCODE_CMPIBSREQ:

            // D0 is the implied first operand

	    if (pore_get_imd64(ctx, dis, &suffix, suffix_string) == 0) {
                operand[0] = register_strings[D0];
		operand[1] = 
		    pore_branch_target(ctx, target_string, lc, 
                                       dis->impco24 * 4);
		operand[2] = &(operand_string[2][0]);
		sprintf(operand[2], "0x%016llx", ULL(dis->imd64));
	    }
	    break;

	case PGAS_OPCODE_BRAI:

            // Always disassembled as BRAIA address_space, offset

	    if (pore_get_imd64(ctx, dis, &suffix, suffix_string) == 0) {
		operand[0] = &(operand_string[0][0]);
		operand[1] = &(operand_string[1][0]);
		sprintf(operand[0], "0x%04x", 
                        (uint32_t)((dis->imd64 >> 32) & 0xffff));
		sprintf(operand[1], "0x%08x",
                        (uint32_t)(dis->imd64 & 0xffffffff));
	    }
	    break;

	case PGAS_OPCODE_BRAD:
	case PGAS_OPCODE_BSRD:

	    operand[0] = register_strings[dis->r0];
	    break;

	case PGAS_OPCODE_ANDI:
	case PGAS_OPCODE_ORI:
	case PGAS_OPCODE_XORI:

	    if (pore_get_imd64(ctx, dis, &suffix, suffix_string) == 0) {
		operand[0] = register_strings[dis->r0];
		operand[1] = register_strings[dis->r1];
		operand[2] = &(operand_string[2][0]);
		sprintf(operand[2], "0x%016llx", ULL(dis->imd64));
	    }
	    break;

	case PGAS_OPCODE_AND:
	case PGAS_OPCODE_OR:
	case PGAS_OPCODE_XOR:
	case PGAS_OPCODE_ADD:
	case PGAS_OPCODE_SUB:

            // Disassembled as e.g., ADD D0, D0, D1

	    operand[0] = register_strings[dis->r0];
            operand[1] = register_strings[D0];
            operand[2] = register_strings[D1];
	    break;

	case PGAS_OPCODE_ADDS:
	case PGAS_OPCODE_SUBS:

            // Disassembled as e.g., ADDS D0, D0, 10

	    operand[0] = register_strings[dis->r0];
	    operand[1] = register_strings[dis->r0];
	    operand[2] = &(operand_string[1][0]);
	    sprintf(operand[2], "%d", dis->imd16);
	    break;

	case PGAS_OPCODE_NEG:

	    operand[0] = register_strings[dis->r0];
	    operand[1] = register_strings[dis->r1];
	    break;

	case PGAS_OPCODE_MR:

	    operand[0] = register_strings[dis->r0];
	    operand[1] = register_strings[dis->r1];
	    break;

	case PGAS_OPCODE_ROLS:

	    operand[0] = register_strings[dis->r0];
	    operand[1] = register_strings[dis->r1];
	    operand[2] = &(operand_string[2][0]);
	    sprintf(operand[2], "%d", dis->imd16);
	    break;

	case PGAS_OPCODE_LS:

	    operand[0] = register_strings[dis->r0];
	    operand[1] = &(operand_string[1][0]);
	    sprintf(operand[1], "%d", dis->imd20);
	    break;

	case PGAS_OPCODE_LI:

	    if (pore_get_imd64(ctx, dis, &suffix, suffix_string) == 0) {
		operand[0] = register_strings[dis->r0];
		operand[1] = &(operand_string[1][0]);
		sprintf(operand[1], "0x%016llx", ULL(dis->imd64));
	    }
	    break;

        case PGAS_OPCODE_LD0:
        case PGAS_OPCODE_LD1:
        case PGAS_OPCODE_LD0ANDI:
        case PGAS_OPCODE_LD1ANDI:
        case PGAS_OPCODE_STD0:
        case PGAS_OPCODE_STD1:
        case PGAS_OPCODE_STI:

#ifdef IGNORE_HW274735

        // BSI and BCI are normally redacted as instructions due to
        // HW274735. If found they will disassemble as data.

        case PGAS_OPCODE_BSI:
        case PGAS_OPCODE_BCI:

#endif // IGNORE_HW274735

	    if (dis->memory_space) {
                sprintf(offset_string, "0x%06x", dis->memory_offset);
	    } else {
                sprintf(offset_string, "0x%08x", dis->pib_offset);
	    }    
		
	    switch (dis->opcode) {

	    case PGAS_OPCODE_LD0:
	    case PGAS_OPCODE_LD0ANDI:
	    case PGAS_OPCODE_STD0:

                operand[0] = register_strings[D0];
                operand[1] = offset_string;
                operand[2] = register_strings[dis->base_register];
                break;

	    case PGAS_OPCODE_LD1:
	    case PGAS_OPCODE_LD1ANDI:
	    case PGAS_OPCODE_STD1:

                operand[0] = register_strings[D1];
                operand[1] = offset_string;
                operand[2] = register_strings[dis->base_register];
                break;
                
            case PGAS_OPCODE_STI:

                operand[0] = offset_string;
                operand[1] = register_strings[dis->base_register];
                break;

#ifdef IGNORE_HW274735

            case PGAS_OPCODE_BSI:
            case PGAS_OPCODE_BCI:
            
                operand[0] = register_strings[D0];
                operand[1] = offset_string;
                operand[2] = register_strings[dis->base_register];
                break;

#endif // IGNORE_HW274735

            }

            switch (dis->opcode) {

	    case PGAS_OPCODE_LD0ANDI:
	    case PGAS_OPCODE_LD1ANDI:

#ifdef IGNORE_HW274735

            case PGAS_OPCODE_BSI:
            case PGAS_OPCODE_BCI:

#endif // IGNORE_HW274735
                
                pore_get_imd64(ctx, dis, &suffix, suffix_string);
                operand[3] = (&(operand_string[3][0]));
		sprintf(operand[3], "0x%016llx", ULL(dis->imd64));
                break;

            case PGAS_OPCODE_STI:

                pore_get_imd64(ctx, dis, &suffix, suffix_string);
                operand[2] = (&(operand_string[2][0]));
		sprintf(operand[2], "0x%016llx", ULL(dis->imd64));
                break;
            }
            break;

        case PGAS_OPCODE_SCAND:

            pore_get_imd64(ctx, dis, &suffix, suffix_string);

            operand[0] = (char *)binary[dis->update];
            operand[1] = (char *)binary[dis->capture];
            operand[2] = &(operand_string[2][0]);
            operand[3] = &(operand_string[3][0]);
            operand[4] = &(operand_string[4][0]);

            sprintf(operand[2], "0x%04x", dis->scan_length);
            sprintf(operand[3], "0x%08x", dis->scan_select);
            sprintf(operand[4], "0x%08x", dis->scan_offset);

            break;


	default:
            if (ctx->options & PORE_INLINE_DISASSEMBLE_UNKNOWN) {

                sprintf(unknown_string, ".long 0x%08x", dis->instruction);
                opcode = (const char*)(&unknown_string);
                dis->is_data = 1;
                dis->data = dis->instruction;
                dis->data_size = 4;

            } else {
                ctx->error = PORE_INLINE_UNKNOWN_OPCODE;
            }
	}

	// Optional parity check

	if ((ctx->error == 0) &&
	    (ctx->options & PORE_INLINE_CHECK_PARITY) &&
	    (pore_inline_parity(dis->instruction, dis->imd64) != 1)) {
	    ctx->error = PORE_INLINE_PARITY_ERROR;
	}

	// Creation of the string format, based on the number of operands

	if ((ctx->error == 0) || (ctx->error == PORE_INLINE_UNKNOWN_OPCODE)) {
	    if (operand[0] == 0) {
		bytes = snprintf(dis->s, 
				 PORE_INLINE_DISASSEMBLER_STRING_SIZE,
				 "%s%s%s",
				 prefix,
				 opcode,
				 suffix);
	    } else if (operand[1] == 0) {
		bytes = snprintf(dis->s, 
				 PORE_INLINE_DISASSEMBLER_STRING_SIZE,
				 "%s%s\t%s%s",
				 prefix,
				 opcode,
				 operand[0],
				 suffix);
	    } else if (operand[2] == 0) {
		bytes = snprintf(dis->s, 
				 PORE_INLINE_DISASSEMBLER_STRING_SIZE,
				 "%s%s\t%s, %s%s",
				 prefix,
				 opcode,
				 operand[0],
				 operand[1],
				 suffix);
	    } else if (operand[3] == 0) {
		bytes = snprintf(dis->s, 
				 PORE_INLINE_DISASSEMBLER_STRING_SIZE,
				 "%s%s\t%s, %s, %s%s",
				 prefix,
				 opcode,
				 operand[0],
				 operand[1],
				 operand[2],
				 suffix);
	    } else if (operand[4] == 0) {
		bytes = snprintf(dis->s, 
				 PORE_INLINE_DISASSEMBLER_STRING_SIZE,
				 "%s%s\t%s, %s, %s, %s%s",
				 prefix,
				 opcode,
				 operand[0],
				 operand[1],
				 operand[2],
				 operand[3],
				 suffix);

	    } else {
		bytes = snprintf(dis->s, 
				 PORE_INLINE_DISASSEMBLER_STRING_SIZE,
				 "%s%s\t%s, %s, %s, %s, %s%s",
				 prefix,
				 opcode,
				 operand[0],
				 operand[1],
				 operand[2],
				 operand[3],
				 operand[4],
				 suffix);

	    }
	    if (bytes >= PORE_INLINE_DISASSEMBLER_STRING_SIZE) {
		ctx->error = PORE_INLINE_DISASSEMBLY_OVERFLOW;
	    }
	} 
    }

    // In the event of an error we need to set the context back as it was,
    // save for the error.

    if (ctx->error != 0) {
	error = ctx->error;
	pore_inline_context_copy(ctx, &(dis->ctx));
	ctx->error = error;
    }

    return ctx->error;
}
	    



	    
	    

	    

	    

	    
	    
	    
	    

	    
	    
	    
	    
	
	

	
