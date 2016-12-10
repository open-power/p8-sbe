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



#ifndef __SBE_XIP_HEADER_H__
#define __SBE_XIP_HEADER_H__

#ifdef __ASSEMBLER__


/// \file sbe_xip_header.h
/// \brief SBE-XIP header assembler definition
///
/// The SBE-XIP header structure is defined as a macro.  Using the macro to
/// generate the .header section for an SBE-XIP binary requires specifying a
/// magic number, the link address, the entry point address and the final
/// image size.  The .header section must be linked at the link address of the
/// SBE-XIP image. The contents of the header are documented in
/// sbe_xip_image.h.

#include "sbe_common.H"
#include "sbe_xip_image.h"

#if SBE_XIP_HEADER_VERSION != 8
#error This code assumes the SBE-XIP header version 8 layout
#endif

	// Define a Section Table entry.  Unless a section is empty at image
	// build time, the linker script must define the *_offset and *_size
	// symbols. 

	.macro	SbeXipSection, s:req, alignment=1, empty=0
__\s\()_section:
	.if	\empty
		.long	0
		.long	0
	.else
		.long	_\s\()_offset
		.long	_\s\()_size
	.endif
		.byte	(\alignment)
                .byte	0, 0, 0
	.endm


	// Define an SBE-XIP header

	.macro	SbeXipHeader, magic, link_address, entry_point, image_size
	
	.section .header, "a", @progbits


	//////////////////////////////////////////////////////////////////////
	// Identification - 8-byte aligned; 8 Entries; TOC-Indexed
	//////////////////////////////////////////////////////////////////////

__magic:	
	.quad	(\magic)
__entry_offset:	
	.quad	((\entry_point) - (\link_address))
__link_address:
	.quada	(\link_address)
__pts_version:
#ifdef PTS_VERSION
        .quad   PTS_VERSION
#else
        .quad   0
#endif
__header_64_reserved:
	.quad	0, 0, 0, 0

	.xip_toc magic, SBE_XIP_UINT64, __magic
	.xip_toc entry_offset, SBE_XIP_UINT64, __entry_offset
	.xip_toc link_address, SBE_XIP_UINT64, __link_address	


        //////////////////////////////////////////////////////////////////////
        // Section Table - 8-byte aligned; 16 entries; Not TOC-Indexed
        //////////////////////////////////////////////////////////////////////

        SbeXipSection header
        SbeXipSection fixed,                8
        SbeXipSection fixed_toc,            8
        SbeXipSection ipl_text,             4
        SbeXipSection ipl_data,             8
        SbeXipSection text,                 4
        SbeXipSection data,                 8
        SbeXipSection toc,                  4
        SbeXipSection strings
        SbeXipSection halt,                 4, empty=1
        SbeXipSection pibmem0,              8, empty=1
        SbeXipSection dcrings,              8, empty=1
        SbeXipSection rings,                8, empty=1
        SbeXipSection slw,                128, empty=1
        SbeXipSection fit,                     empty=1
        SbeXipSection ffdc,                 8, empty=1


        //////////////////////////////////////////////////////////////////////
        // Other Information - 4-byte aligned; 8 entries; TOC-Indexed
        //////////////////////////////////////////////////////////////////////

__image_size:
	.long	(\image_size)
__build_date:
	.long	0
__build_time:
	.long	0
__header_32_reserved:
	.long	0, 0, 0, 0, 0

	.xip_toc image_size, SBE_XIP_UINT32, __image_size
	.xip_toc build_date, SBE_XIP_UINT32, __build_date
	.xip_toc build_time, SBE_XIP_UINT32, __build_time


        //////////////////////////////////////////////////////////////////////
        // Other Information - 1-byte aligned; 8 entries; TOC-Indexed
        //////////////////////////////////////////////////////////////////////

__header_version:
	.byte	SBE_XIP_HEADER_VERSION
__toc_normalized:
	.byte	0
__toc_sorted:
	.byte	0
__header_8_reserved:
	.byte	0, 0, 0, 0, 0

	.xip_toc header_version, SBE_XIP_UINT8, __header_version
	.xip_toc toc_normalized, SBE_XIP_UINT8, __toc_normalized
	.xip_toc toc_sorted, SBE_XIP_UINT8, __toc_sorted


        //////////////////////////////////////////////////////////////////////
        // Strings; 64 characters allocated; TOC-Indexed
        //////////////////////////////////////////////////////////////////////

__build_user:
	.asciz	"unknown        "         # 16 Characters allocated
__build_host:
	.asciz	"unknown                " # 24 characters allocated
__header_string_reserved:
	.space	24, 0

	.xip_toc build_user, SBE_XIP_STRING, __build_user
	.xip_toc build_host, SBE_XIP_STRING, __build_host


	.endm

#endif // __ASSEMBLER__

#endif // __SBE_XIP_HEADER_H__
