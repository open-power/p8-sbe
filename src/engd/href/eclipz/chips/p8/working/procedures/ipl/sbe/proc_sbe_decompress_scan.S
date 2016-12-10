//------------------------------------------------------------------------------
// IBM_PROLOG_BEGIN_TAG
// This is an automatically generated prolog.
//
// OpenPOWER Project
//
// Contributors Listed Below - COPYRIGHT 2012,2016
// [+] International Business Machines Corp.
//
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied. See the License for the specific language governing
// permissions and limitations under the License.
//
// IBM_PROLOG_END_TAG
//------------------------------------------------------------------------------




/// \file proc_sbe_decompress_scan.S
/// \brief Run-length encoded decompression and scan on 4-bit data.
///
/// RS4 Compression Format
/// ======================
///
/// RS4 decompresses and scans a compressed scan string.  The string to be
/// decompressed and scanned is the difference between the current state of
/// the ring and the desired final state of the ring.  A run-time optimization
/// supports the case that the current state of the ring is known to be the
/// flush state. This algorithm is written to be executed from PIB-attached
/// memory.
///
/// The compressed data is treated as a string of 4-bit nibbles. When packaged
/// in the scan data structure however the string must begin on an 8-byte
/// boundary and is always read 8 bytes at a time.  In the scan data structure
/// the compressed strings are also padded with 0x0 nibbles to the next even
/// multiple of 8 bytes. The compressed string consists of control nibbles and
/// data nibbles.  The string format includes a special control/data sequence
/// that marks the end of the string and the final bits of scan data.
///
/// Runs of 0x0 nibbles (rotates) are encoded using a simple variable-length
/// integer encoding known as a "stop code".  This code treats each nibble in
/// a variable-length integer encoding as an octal digit (the low-order 3
/// bits) plus a stop bit (the high-order bit).  The examples below
/// illustrate the encoding.
///
///     1xxx            - Rotate 0bxxx       nibbles (0 - 7)
///     0xxx 1yyy       - Rotate 0bxxxyyy    nibbles (8 - 63)
///     0xxx 0yyy 1zzz  - Rotate 0bxxxyyyzzz nibbles (64 - 511)
///     etc.
///
/// A 0-length rotate (code 0b1000) is needed to resynchronize the state
/// machine in the event of long scans (see below), or a string that begins
/// with a non-0x0 nibble.
///
/// Runs of non-0x0 nibbles (scans) are inserted verbatim into the compressed
/// string after a control nibble indicating the number of nibbles of
/// uncompressed data.  If a run is longer than 15 nibbles, the compression
/// algorithm must insert a 0-length rotate and a new scan-length control
/// before continuing with the non-0 data nibbles.
///
///     xxxx - Scan 0bxxxx nibbles which follow, 0bxxxx != 0
///
/// The special case of a 0b0000 code where a scan count is expected marks the
/// end of the string.  The end of string marker is always followed by a
/// nibble that contains the terminal bit count in the range 0-3.  If the
/// length of the original binary string was not an even multiple of 4, then a
/// final nibble contains the final scan data left justified.
///
///     0000 00nn [ttt0] - Terminate 0bnn bits, data 0bttt0 if 0bnn != 0
///
///
/// BNF Grammar
/// ===========
///
/// Following is a BNF grammar for the strings accepted by the RS4
/// decompression and scan algorithm. The non-terminal symbols from the
/// grammar appear as labels (slightly modified) in the assembly code to
/// illustrate the structure of the state machine.  At a high level, the state
/// machine recognizes a series of 1 or more sequences of a rotate (R)
/// followed by a scan (S) or end-of-string marker (E), followed by the
/// terminal count (T) and optional terminal data (D).
///
///     (R S)* (R E) T D?

/*
<rs4_string>        ::= <rotate> <terminate> |
                        <rotate> <scan> <rs4_string>
<rotate>            ::= <octal_stop> |
		        <octal_go> <rotate>
<octal_go>          ::= '0x0' | ... | '0x7'
<octal_stop>        ::= '0x8' | ... | '0xf'
<scan> 	            ::= <scan_count(N)> <data(N)>
<scan_count(N)>     ::= * 0bnnnn, for N = 0bnnnn, N != 0 *
<data(N)>           ::= * N nibbles of uncompressed data *
<terminate>         ::= '0x0' <terminal_count(0)> |
                        '0x0' <terminal_count(T, T > 0)> <terminal_data(T)>
<terminal_count(T)> ::= * 0b00nn, for T = 0bnn *
<terminal_data(1)>  ::= '0x0' | '0x8'
<terminal_data(2)>  ::= '0x0' | '0x4' | '0x8' | '0xc'
<terminal_data(3)>  ::= '0x0' | '0x2' | '0x4' | ... | '0xe'
*/
////////////////////////////////////////////////////////////////////////////        
///
/// rs4(image)
/// rs4_chiplet(image, chiplet)
///
/// The decompression and scan algorithm has two entry points: rs4() uses the
/// chiplet Id encoded in the compressed scan data container, and
/// rs4_chiplet() requires the chiplet Id to be passed as P0.
///
/// At entry
/// ========
/// 
/// A0 : Pointer to the compressed ring image header, 8-byte aligned
///
/// P0 : (rs4_chiplet()) The chiplet to scan.  For multicast scanning this is
///      required to be the multicast-write chiplet Id for the group. The
///      caller takes responsibility for the correctness of multicast scanning.
///      If there are _any_ differences in the ring states of the chiplets in
///      the group the results of running proc_sbe_decompress_scan are
///      undefined. 
///
/// At exit
/// =======
///
/// A0, A1, D0, D1, P1, SPRG0, CTR and the ALU flags are destroyed by this
/// routine.
///
/// rs4() destroys P0 as well.
/// rs4_chiplet() leaves P0 invariant at exit.
///
/// During execution:
/// =================
///
/// 1 level of subroutine call is required.  Given the current 2-deep PORE
/// call stack, these entry points can only be called from the top level
/// (Stack Level 0).
///
/// Invariant Registers (after setup)
/// ---------------------------------
///
/// A0 : Used to address the image in memory.  During header processing A0
/// addresses the header. Once the header has been processed A0 always
/// contains the address of the _next_ doubleword to load into D1, i.e. it is
/// incremented after each data load.
///
/// P1 : Holds the pervasive chiplet Id of PIB-attached memory
///
/// CTR : Counts down the number of nibbles yet to be processed in the current
/// doubleword. See notes on the CTR invariant in the comments for the
/// subroutine next().
///
/// Multi-use registers
/// -------------------
///
/// P0 : Holds the pervasive chiplet Id of the chiplet being scanned.  The
/// default is for P0 to hold the write form of the chiplet Id. Whenever it is
/// necessary to read from the chiplet the read-form of the chiplet Id is
/// loaded, the read is done, and then the write form is reloaded.  The read
/// and write forms are only different for multicast cases. The read form is
/// always a multicast read-AND for the multicast case.
///
/// A1 : A1 holds the write-form of the chiplet ID during the P0 write/read
/// chiplet swaps mentioned above in the discussion of P0.
///
/// D0, D1 : Scratch
///
/// SPRG0 : Used as the accumulator for decoding the variable-length rotate
/// amounts, as temporary storage of bit counts during processing of
/// maximum-length rotations and as temporary storage of nibble-counts during
/// scanning.
///
/// Other invariants
/// ----------------
///
/// Scan-data operations (SCOM writes to 0xcc038www) complete immediately. All
/// rotations proceed via scan_rotate().  Since RS4 rings are only used during
/// IPL we elected not to implement the more complex scan-polling protocol
/// required for runtime scanning, although the code structure would allow the
/// polling protocol to be implemented opaquely in scan_rotate(). Therefore
/// whenever the scan-data code reads 0xcc038000 (a 0-length rotate to get the
/// current contents of the scan data register for read-modify-write) it is
/// known that the chiplet scan-engine is idle and the contents of the scan
/// data register are correct.
///
/// Note that rotation (rotldi) is used instead of shifting (shldi) if the
/// data being rotated is known to be masked, in order to avoid a redundant
/// masking operation.
///
////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
#include "p8_scan_compression.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pibmem

//------------------------------------------------------------------------------
// Global Data 
//------------------------------------------------------------------------------

        // Masks/values for when a data register contains a right-justified
        // multicast chiplet Id (P0/P1 image)

        .set    MULTICAST_BIT, BIT(57)
        .set    MULTICAST_TYPE_MASK, 0x38
        .set    MULTICAST_TYPE_WRITE, 0x28
        .set    MULTICAST_TYPE_READ_AND, 0x08


	// The maximum possible scan rotation, in bits.  The complement is
	// also used to mask the LD instruction used to implement the
	// rotation, so this constant must always be of the form 2**n - 1.
	// The maximum value is 2**12 - 1 (0xfff). The actual maximum value
	// depends on how the scan ratios are set up.  If the value is too
	// large then you will see a PCB timeout on a scan-rotate SCOM.

	.set	MAX_ROTATE_BITS, 0x07f

	.if	((((MAX_ROTATE_BITS + 1) & MAX_ROTATE_BITS) != 0) || \
		 (MAX_ROTATE_BITS <= 0) || (MAX_ROTATE_BITS > 0xfff))
	.error	"MAX_ROTATE_BITS must be of the form 2**n - 1, for 1 <= n <= 12"
	.endif
	

        

//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

	// This check word is the first 32 bits written to the scan data
	// register, and should be found in the scan data register at the
	// completion of the scan.

	.set	CHECK_WORD, 0xa5a55a5a00000000
	

	// This macro aliases LOOP in a more generic form - Branch if CTR Not
	// Zero and Decrement CTR.

	.macro	branzd, target:req
	loop	(\target)
	.endm


	// Scan set N bits from data left-justified in a data register

        .macro  scan, data:req, bits:req, chiplet:req
        std	(\data), (GENERIC_CLK_SCANDATA0_0x00038000 + (\bits)), \
		(\chiplet)
        .endm


        // Save the write chiplet Id and load the read chiplet Id

        .macro  load_read_chiplet, scratch:req
        ..data  \scratch
        mr      A1, P0
        ld      \scratch, read_chiplet, P1
        mr      P0, \scratch
        .endm


        // Restore the write chiplet Id

        .macro  restore_write_chiplet
        mr      P0, A1
        .endm

//------------------------------------------------------------------------------
// Procedure 
//------------------------------------------------------------------------------

#if COMPRESSED_SCAN_DATA_VERSION != 1
#error "This code assumes the CompressedScanData verson 1 layout"
#endif

	.ipl_text

	.global	proc_sbe_decompress_scan, proc_sbe_decompress_scan_chiplet

        //////////////////////////////////////////////////////////////////////
        // Entry Points + Header Processing
        //////////////////////////////////////////////////////////////////////

	.subroutine proc_sbe_decompress_scan, pibmem, "$Revision: 1.18 $"
	
rs4:
	// Load the chiplet ID from the container and fall through into the
	// next entry point.

	ld	D0, 16, A0
	mr	P0, D0

proc_sbe_decompress_scan_chiplet:	
rs4_chiplet:	
	POREVE_INF("Entering proc_sbe_decompress_scan_chiplet()");

	// Set up the P1 invariant (P1 == chiplet Id of PIBMEM)

	lpcs	P1, PIBMEM0_0x00080000

        // If P0 is not a multicast chiplet then the "read-form" is identical
        // to the write form.  Otherwise check to make sure this is a
        // multicast write, and if so, create a read-form as a multicast
        // read-AND. 

        mr      D1, P0
        andi    D0, D1, MULTICAST_BIT
        branz   D0, 1f    
        
        std     D1, read_chiplet, P1
        bra     2f
1:
        andi    D0, D1, MULTICAST_TYPE_MASK
        cmpibrane D0, not_multicast_write, MULTICAST_TYPE_WRITE
        andi    D0, D1, ~MULTICAST_TYPE_MASK
        ori     D0, D0, MULTICAST_TYPE_READ_AND
        std     D0, read_chiplet, P1
2:
        
	// Check the magic number.

        ld      D1, 0, A0
	extrdi	D0, D1 32, 0
        cmpibrane D0, magic_number_mismatch, RS4_MAGIC

	// Extract the size in bytes, check for validity, and store the number
	// of data doublewords for consistency checking.  Every RS4-compressed
	// string will contain at least 1 data doubleword.

	extrdi	D0, D1, 32, 32
	subs	D0, D0, COMPRESSED_SCAN_DATA_SIZE
	tfbule	D1, data_size_error
	srdi	D0, D0, 3
	std	D0, data_doublewords, P1

	// Extract the ring length and save it away for consistency
	// checking.

	ld	D0, 8, A0
	extrdi	D0, D0, 32, 32
	std	D0, ring_length, P1
	POREVE_INF("Original ring length = %d", (int)(io_pore.d0.read()));

        // Clear the scan rotate accomulator in the OPCG engine
        load_read_chiplet D1
	ldandi	D1, GENERIC_OPCG_CNTL0_0x00030002, P0, ~BITS(21, 43)
        restore_write_chiplet
        std     D1, GENERIC_OPCG_CNTL0_0x00030002, P0

        // Write the Scan Select Register (only the high-order 32 bits are
        // defined). Note that there is no requirement to restore or reprogram
        // the Scan Select Register once we're done.

	ld	D0, 16, A0
        std     D0, GENERIC_CLK_SCANSEL_0x00030007, P0

	// Store the flush-optimization flag and check the header version

	extrdi	D1, D0, 8, 40
	std	D1, flush_optimization, P1

	extrdi	D0, D0, 8, 32
	cmpibrane D0, header_version_mismatch, COMPRESSED_SCAN_DATA_VERSION

	// Prime the scan mechanism with the check word. The first 32-bits of
        // the ring data are always zero as a placeholder for the check word,
        // therefore the first operation of the compressed scan program will
        // always be a 32-bit or greater rotate to shift the checkword into
        // the ring. 

	li	D0, CHECK_WORD
	scan	D0, 0, P0

	// Initialize the A0 and CTR invariants and begin

	adds	A0, A0, 24
	ls	CTR, 0


        //////////////////////////////////////////////////////////////////////
        // Main Loop : <rs4_string>
        //////////////////////////////////////////////////////////////////////

rs4_string:

	// Clear the rotation accumulator

	ls	D0, 0
	mr	SPRG0, D0
	
rotate:
	// Invariant : SPRG0 contains the accumulated rotate count.
	
	// Extract and accumulate the next octal digit into D0, and save the
	// new count back in SPRG0.
	
	bsr	next		# D0 <- Next nibble left justified (unmasked)
	extrdi	D0, D0, 3, 1	# D0 <- low-order 3 bits, right just. (masked)
	mr	D1, SPRG0
	rotldi	D1, D1, 3	
	add	D0, D0, D1	
	mr	SPRG0, D0	# count <- (count * 8) + digit

	// If the STOP bit is not set then continue collecting the rotation
	// count.  Otherwise fall through with the final rotate count in D0.

	ldandi	D1, saved_data, P1, BIT(0)
	braz	D1, rotate

	// At this point D0 contains the rotate count in nibbles.  Convert this
	// into a bit count in D1, then decrement the saved ring length.

	rotldi	D1, D0, 2
	
	ld	D0, ring_length, P1
	sub	D0, D0, D1
	std	D0, ring_length, P1
	
long_rotate:
	// Invariant : D1 contains the remaining rotate count in bits.
	
	// Use logical AND to determine if the remaining bit count is greater
	// than the maximum supported bit rotation, which is known to be of
	// the form 2**n - 1.  If so, the remaining bit count less the max bit
	// count is computed into SPRG0, and scan_rotate() is called to rotate
	// the maximum length.

	andi	D0, D1, ~MAX_ROTATE_BITS
	braz	D0, short_rotate

	subs	D1, D1, MAX_ROTATE_BITS
	mr	SPRG0, D1	

	ls	D0, MAX_ROTATE_BITS
	bsr	scan_rotate			# D0 -> Rotate count
	mr	D1, SPRG0
	bra	long_rotate

short_rotate:
	// Invariant : D1 contains the remaining rotate count in bits.

	// Short-circuit 0-length rotation, otherwise handle a short rotate.

	braz	D1, scan
	mr	D0, D1
	bsr	scan_rotate			# D0 -> Rotate count

scan:
	// The scan count (in nibbles) is extracted into D0. A 0-length scan
	// marks the end of the string. 	

	bsr	next		# D0 <- Next nibble left justified (unmasked)
	extrdi	D0, D0, 4, 0
	braz	D0, terminate

	// The scan count in nibbles is moved to SPRG0 (invariant for
	// scan_loop and optimized_scan_loop). The scan count in bits is
	// subtracted from the ring_length.

	mr	SPRG0, D0
	rotldi	D1, D0, 2
	ld	D0, ring_length, P1
	sub	D0, D0, D1
	std	D0, ring_length, P1
	
	// Case split for general-purpose vs. optimized scanning. If the
	// remaining ring length D0 is < 32 we must do unoptimized scanning
	// anyway since the scan will overlap with the checkword as it rotates
	// out of the ring.

        andi    D0, D0, ~0x1f   # Quick compare D0 <= 31
        braz    D0, scan_loop            

        ld	D0, flush_optimization, P1
        branz	D0, optimized_scan_loop

scan_loop:	 
	// Invariant : SPRG0 contains the number of nibbles left to scan, and
	// SPRG0 is not 0.

	// This is a non-optimized scan loop.  Each nibble must be masked out
	// and XORed with the contents of the scan data register before writing
	// back the scan data register.

	bsr	next		# D0 <- Next nibble left justified (unmasked)
	extldi	D0, D0, 4, 0	# D0 <- Next nibble left justified (masked)

        load_read_chiplet D1
	ld	D1, GENERIC_CLK_SCANDATA0_0x00038000, P0
        restore_write_chiplet
        
	xor	D0, D0, D1
	scan	D0, 4, P0
	mr	D0, SPRG0
	subs	D0, D0, 1
	mr	SPRG0, D0
	branz	D0, scan_loop
	
	bra	rs4_string

optimized_scan_loop:	
	// Invariant : SPRG0 contains the number of nibbles left to scan, and
	// SPRG0 is not 0.

	// This is an optimized scan loop.  By definition, the scan data
	// register will always be 0 when processing a ring in scan-0 state.
	// This means we can simply write each masked nibble into the scan data
	// register. The optimization is not that great for this algorithm; it
	// is very important for the wiggle-flip format used at runtime
	// however. 

	bsr	next		# D0 <- Next nibble left justified (unmasked)
	extldi	D0, D0, 4, 0	# D0 <- Next nibble left justified (masked)
	scan	D0, 4, P0
	mr	D0, SPRG0
	subs	D0, D0, 1
	mr	SPRG0, D0
	branz	D0, optimized_scan_loop
	
	bra	rs4_string

terminate:	
	// Extract the terminal bit count into D1; If 0 we're done, otherwise
	// decrement the ring_length.
	
	bsr	next		# D0 <- Next nibble left justified (unmasked)
	extrdi	D1, D0, 2, 2	# D1 <- Low-order 2 bits of terminal count
	braz	D1, final_check

	ld	D0, ring_length, P1
	sub	D0, D0, D1
	std	D0, ring_length, P1

	// At this point the final nibble of the stream contains the final 1-3
	// bits of scan data. They are XORed with the scan data register and
	// scanned by cases. (We can't trash the scan data register since it
	// contains the checkword.) The terminal count (D1) must be stored in
        // SPRG0 temporarily.

	mr	SPRG0, D1
	bsr	next		# D0 <- Final nibble left justified (unmasked)
	extldi	D0, D0, 4, 0	# D0 <- Final nibble left justified (masked)

        load_read_chiplet D1
	ld	D1, GENERIC_CLK_SCANDATA0_0x00038000, P0
        restore_write_chiplet

	xor	D1, D0, D1

	mr	D0, SPRG0
        cmpibraeq D0, final1, 1
        cmpibraeq D0, final2, 2

final3:
        scan    D1, 3, P0
        bra     final_check
final2:
        scan    D1, 2, P0
        bra     final_check
final1: 
        scan    D1, 1, P0

final_check:		
	// The scan data register must contain the check word which should have
	// rotated through the ring

        load_read_chiplet D0
	ldandi	D0, GENERIC_CLK_SCANDATA0_0x00038000, P0, BITS(0, 32)
        restore_write_chiplet
        
	cmpibrane D0, checkword_error, CHECK_WORD
	

	// The number of data doublewords and the ring length must both have
	// decremented to 0.

	ld	D0, data_doublewords, P1
	branz	D0, data_size_error
	ld	D0, ring_length, P1
	branz	D0, ring_length_error
	

	// We always issue a "setpulse" (UpdateDR) as a final 0-length write
	// to the scan data register.  This is required for certain rings
	// (e.g., PLL rings) but does not hurt for the others.
	
	POREVE_INF("Issuing a 'setpulse' to complete the scan");
	li	D0, 0
	std	D0, GENERIC_CLK_SCAN_UPDATEDR_0x0003A000, P0
	

	// Nothing has to be 'torn down' - just exit.

	POREVE_INF("Exiting proc_sbe_decompress_scan_chiplet()");
	.end_subroutine proc_sbe_decompress_scan


        //////////////////////////////////////////////////////////////////////
        // next
        //////////////////////////////////////////////////////////////////////
	//
	// next() is a suroutine that effectively fetches and left-justifies
	// the next nibble to be processed into D0.  Doublewords are fetched
	// from (slow) SEEPROM only once, and stored in the variable saved_data
	// for nibble-wise processing.  Global invariants include that the CTR
	// always contains the number of nibbles left to be processed in the
	// saved data, and A0 contains a pointer to the next doubleword to
	// fetch from SEEPROM.
        //
        // The next nibble is returned from saved_data unless CTR goes to 0, in
        // which case the next dobubleword is fetched.  Because each caller
        // handles the next nibble in a slightly different way the nibble is
        // _not_ masked out.  This avoids wasted time since each caller
	// typically does custom masking of the nibble.
        //
        // This routine also tests and decrements the variable
        // data_doublewords as a consistency check. data_doublewords should
        // decrement to 0 exactly and only at the end of the decompress-scan.
        //
        // At Entry:
        // 
        // CTR : The number of nibbles left to process in saved_data
        // A0  : Points to the next doubleword to load from SEEPROM
        // P1  : The chiplet Id of the PIBMEM
        //
        // At Exit:
        // 
        // CTR : The number of nibbles left to process in saved_data
        // A0  : Points to the next doubleword to load from SEEPROM
        // D0  : Returns the next nibble left justified (but unmasked)
        // P1  : Unchanged
        
next:
	// Check for exhaustion of saved_data.  Note the side effect that CTR
	// is decremented by BRANZD (LOOP).
		
	branzd	get_next	
	
	// saved_data is exhausted.  Make the consistency check, load the
	// next doubleword from SEEPROM, and re-establish the CTR and A0
	// invariants. 

	ld	D0, data_doublewords, P1
	braz	D0, data_size_error
	subs	D0, D0, 1
	std	D0, data_doublewords, P1

	ld	D0, 0, A0
	std	D0, saved_data, P1
	adds	A0, A0, 8
	ls	CTR, 15
	ret

get_next:	
	// saved_data contains at least one more nibble.  Position the nibble
	// and update the saved_data.

	ld	D0, saved_data, P1
	rotldi	D0, D0, 4
	std	D0, saved_data, P1
	ret

	.epilogue next


        //////////////////////////////////////////////////////////////////////
        // scan_rotate
        //////////////////////////////////////////////////////////////////////
	//
	// scan_rotate() is a subrotine that implements scan rotation.  Since
	// rotate counts are actually encoded in the SCOM address,
	// scan_rotate() requires a self-modifying code sequence for peak
	// efficiency.
        //
        // At Entry:
        // 
        // D0 : The number of bits to rotate (0 to 2^13 - 1)
        // P0 : The chiplet Id of the chiplet being scanned
        // P1 : The chiplet Id of the PIBMEM
        //
        // At Exit:
        // 
        // D0, D1 : Destroyed
        // P0, P1 : Unchanged

	.global scan_rotate
scan_rotate:	
	// Insert the bit length into the low-order bits of the rotate
	// instruction

	ldandi	D1, rotate_sequence, P1, ~MAX_ROTATE_BITS
	add	D1, D0, D1
	std	D1, rotate_sequence, P1
        load_read_chiplet D0
	bra	rotate_instruction

	// The modified scan-rotate instruction is placed in the low-order 4
	// bytes of an 8-byte doubleword.  The code must be aligned such that
	// the modified instruction is not cached by the PORE instruction
	// buffer.  

	.balign	PORE_INSTRUCTION_BUFFER_SIZE
rotate_sequence:	
	nop
rotate_instruction:	
	ld	D0, GENERIC_CLK_SCANDATA0_0x00038000, P0

        restore_write_chiplet
	ret


        //////////////////////////////////////////////////////////////////////
        // Error handling
        //////////////////////////////////////////////////////////////////////

proc_sbe_decompress_scan_errors:

not_multicast_write:
        // A multicast group was not a multicast write group
	POREVE_ERR("%s: The chiplet to be scanned is a multicast chiplet, "
                   "however the type is not multicast write. P0 = %02x",
                   __FILE__, (int)(io_pore.p0.read()))
	reqhalt	RC_SBE_SCAN_MULTICAST_TYPE_ERROR
        
magic_number_mismatch:
	// The magic number in the scan container is not RS4_MAGIC
	POREVE_ERR("%s: The magic number in the scan container is not "
                   "RS4_MAGIC, found 0x%llX", 
                   __FILE__, io_pore.d0.read())
	reqhalt	RC_SBE_SCAN_MAGIC_MISMATCH
	
header_version_mismatch:
	// The header has an unexpected version number
	POREVE_ERR("%s: The header has an unexpected version number. "
                   "Expecting %d but found %d",
		   __FILE__,  \
                   COMPRESSED_SCAN_DATA_VERSION, (int)(io_pore.d0.read()))
	reqhalt RC_SBE_SCAN_HEADER_VERSION_ERROR

data_size_error:
	// Either there is no data or too much data, indicating a problem in
	// the header.
	POREVE_ERR("%s: Either there is no data or too much data, "
		   "indicating a problem in the header.",
                   __FILE__);
	reqhalt	RC_SBE_SCAN_DATA_SIZE_ERROR

ring_length_error:
	// The number of bits scanned does not match the ring length recorded
	//in the header.
	POREVE_ERR("%s: The number of bits scanned does not match the "
                   "ring length recorded in the header. Residue = %d",
		   __FILE__, (int)(io_pore.d0.read()))
	reqhalt RC_SBE_SCAN_RING_LENGTH_ERROR

checkword_error:
	// The check word did not rotate correctly through the ring
	POREVE_ERR("%s: Checkword error, expecting 0xa5a55a5a00000000, found "
		   "0x%016llx\n",
                   __FILE__, io_pore.d0.read());
	reqhalt RC_SBE_SCAN_CHECKWORD_ERROR

	.epilogue proc_sbe_decompress_scan_errors
	

        //////////////////////////////////////////////////////////////////////
        // Data
        //////////////////////////////////////////////////////////////////////

	.ipl_data

        // For unicast chiplets, this is identical to the incoming write-form
        // of the chiplet Id.  For multicast chiplets, this is the multicast
        // read-AND form of the multicast chiplet Id.
	.global read_chiplet
read_chiplet:
        .quad   0

	// The saved value of the data doubleword being operated on by the
	// algorithm. 
saved_data:
	.quad	0

	// The number of data doublewords remaining to be processed.  As a
	// consisteny check this value must decrement to 0 as each data
	// doubleword is processed.
data_doublewords:
	.quad	0

	// The length of the scan ring.  As a consistency check this value must
	// decrement to 0 as each bit is rotated/scanned.
ring_length:
	.quad	0

	// This decompress-scan can be optimized on the assumption that the
	// ring being modified is the flush state of the ring.
flush_optimization:
	.quad	0
