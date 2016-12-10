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



#ifndef __VSBE_BSSCAN_H
#define __VSBE_BSSCAN_H

// $Id: bsscan.H,v 1.1 2011/09/19 00:25:31 jeshua Exp $

/// \file bsscan.H
/// \brief A hack to intercept scan operations and make them broadside

#include "bus.H"

namespace vsbe {
    
    class Bsscan;
    
    /// PIB base address of PIB range mapped by Bsscan
    const uint32_t BSSCAN_PIB_BASE = 0x00038000;

    /// Number of PIB addresses mapped by Bsscan
    const int BSSCAN_PIB_SIZE = (0x00040000 - 0x00038000);

    // The base address for each chiplet
    const uint32_t EX00_PIB_BASE = 0x10000000;
    const uint32_t EX01_PIB_BASE = 0x11000000;
    const uint32_t EX02_PIB_BASE = 0x12000000;
    const uint32_t EX03_PIB_BASE = 0x13000000;
    const uint32_t EX04_PIB_BASE = 0x14000000;
    const uint32_t EX05_PIB_BASE = 0x15000000;
    const uint32_t EX06_PIB_BASE = 0x16000000;
    const uint32_t EX07_PIB_BASE = 0x17000000;
    const uint32_t EX08_PIB_BASE = 0x18000000;
    const uint32_t EX09_PIB_BASE = 0x19000000;
    const uint32_t EX10_PIB_BASE = 0x1A000000;
    const uint32_t EX11_PIB_BASE = 0x1B000000;
    const uint32_t EX12_PIB_BASE = 0x1C000000;
    const uint32_t EX13_PIB_BASE = 0x1D000000;
    const uint32_t EX14_PIB_BASE = 0x1E000000;
    const uint32_t EX15_PIB_BASE = 0x1F000000;
}


/// Map PIB accesses to CFAM accesses

class
vsbe::Bsscan : public PibSlave {

public:

    ////////////////////////////// Creators //////////////////////////////

    Bsscan();

    virtual ~Bsscan();


    //////////////////////////// Manipulators ////////////////////////////

    /// Bsscan operation
    ///
    /// \param[in,out] io_transaction A PIB transaction object
    ///
    /// This object converts PIB transactions in a certain range in the
    /// virtual environment to broadside getRing and putRing operations,
    /// returning the FAPI return code from the translated calls.
    ///
    /// \retval rc The fapi::ReturnCode returned by the underlying
    /// getRing() or putRing() call.
    fapi::ReturnCode
    operation(Transaction& io_transaction);


    ///////////////////////////// Safety //////////////////////////////////

private:
    Bsscan(const Bsscan& rhs);
    Bsscan& operator=(const Bsscan& rhs);
};

#endif  // __VSBE_BSSCAN_H
