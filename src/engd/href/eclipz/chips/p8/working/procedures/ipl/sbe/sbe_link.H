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



#ifndef __SBE_LINK_H
#define __SBE_LINK_H

// $Id: sbe_link.H,v 1.13 2012/10/30 15:30:07 koenig Exp $

/// \file sbe_link.H
/// \brief Constants required for linking SBE code images
///
/// This header contains those cpp manifest constants required for processing
/// the linker scripts used to generate SBE code images.  They may also be
/// useful for PORE assembler programming so they are included in sbe.H as
/// well.

/// The link address of OTPROM code as a byte-address
///
/// The OTPROM can be addressed both as an I2C slave and as a direct PIB
/// slave.  The I2C slave is at PIB local address 0x0 and the PIB memory
/// interface is at local address 0x8000.  SBE/IPL uses the PIB addressing
/// mode, so the OTPROM image is linked at 0x40000 (the byte-address
/// equivalent of 0x8000).
#define OTPROM_ORIGIN 0x40000

/// The amount of memory contained in each OTPROM macro
#define OTPROM_BLOCK_SIZE 4096

/// The amount of memory reserved for OTPROM code
///
/// This amount is exclusive of physical OTPROM memory reserved for compressed
/// scan ring images.
#define OTPROM_CODE_SIZE (1 * OTPROM_BLOCK_SIZE)

#ifndef CENTAUR

/// The link address of the P8 SBE Base image
///
/// PORE hardware translation keys off of the high-order 2 bits of the 32-bit
/// address offset, and relocatable PORE code is linked at 0x80000000.  This
/// 1GB segment is chosen because it is not mapped on the OCI, so any
/// untranslated escapes from Sleep/Winkle code produce bus errors.
#define SBE_BASE_ORIGIN 0x80000000

#else

/// The link address of the Centaur SBE base image
///
/// Since Centaur only runs from virtual PNOR, there is no need for virtual
/// addressing and it can be linked and loaded at 0
#define SBE_BASE_ORIGIN 0

#endif // Centaur

/// The physical address offset where SBE-SEEPROM code is loaded
///
/// This address *must* be a constant known to the OTPROM code.
#define SBE_SEEPROM_LOAD_ADDRESS 0x2000

/// The MRR to use for execution from SEEPROM.
///
/// Since SBE_BASE_ORIGIN and SBE_SEEPROM_LOAD_ADDRESS are constants, the MRR
/// setting is also a constant.
#define SBE_SEEPROM_MRR \
    (((SBE_BASE_ORIGIN & 0xc0000000) << 2) |    \
     ((SBE_SEEPROM_LOAD_ADDRESS - SBE_BASE_ORIGIN) & 0xffffffff))

/// The link address of the PIBMEM image
#define PIBMEM_ORIGIN 0

/// The amount of space available in the PIBMEM, in bytes (3KB)
#define PIBMEM_SIZE (3 * 1024)

/// The offset (in bytes) of the .fixed section in P8/Centaur SBE-XIP images
#define SBE_XIP_FIXED_OFFSET 512

#endif  // __SBE_LINK_H

