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



#include <ifScrubDataSpec.H>

// Global static pointer used to ensure a single instance of the class.
EngdPublicScrubData* EngdPublicScrubData::cv_Instance = NULL;  

/** This function is called to create an instance of the class. 
    Calling the constructor publicly is not allowed. The constructor 
    is private and is only called by this Instance function.
*/
EngdPublicScrubData* EngdPublicScrubData::Instance()
{
    return cv_Instance ? cv_Instance : (cv_Instance = new EngdPublicScrubData);
}


/**
 * Given hex/binary data, fills in the bitBasis & bitValid ecmdDataBuffers in an
 *    engdSpyData_t object.
 *
 * @param uint32_t i_start - Starting bit position for data
 * @param uint32_t i_length - Bit length of data (if don't care, will be
 *                            approximated from char length of data)
 * @param string i_data - Hex/binary data (must prefix with 0x/0b respectively)
 *
 * @return bool - Returns true if setting of data accomplished without error
 */
bool engdSpyData_t::setBuffer(uint32_t i_start, uint32_t i_length,
                            string i_data)
{
    bool success = true;
    bool getLenFromData = (i_length == ENGD_DC_VALUE);
    uint32_t ecmdRc = ECMD_DBUF_SUCCESS;
    uint32_t digitCount;

    size_t cpA;  // Character position value
    uint32_t i;
    
    cout << hex;

    do
    {
        if (i_data[0] == '0')
        {
            // Figure number of digits to convert (disregarding 0x or 0b)
            digitCount = i_data.length() - 2;
        
            // Adjust buffer lengths if specified by user
            if (! getLenFromData)
            {
                i = i_start + i_length;
                if (i > bitBasis.getBitLength())
                {
                    bitBasis.growBitLength(i);
                    bitValid.growBitLength(i);
                    bitValid.setBit(i_start, i_length);
                }
            }
        
            if (i_data[1] == 'b')
            {   // Found Binary Data
                cpA = i_data.find_first_not_of("01", 2);
                if (cpA != string::npos)
                {
                    ILOG(P5MSG) << "Invalid digit in binary string: " << i_data << endl;
                    success = false;
                    break;
                }
                
                // Before insert, must update Basis/Valid lengths
                if (getLenFromData)
                {
                    bitBasis.growBitLength(i_start + digitCount);
                    bitValid.growBitLength(i_start + digitCount);
                    bitValid.setBit(i_start, digitCount);
                }
                
                // Insert bits into buffer, skipping over "0b"
                bitBasis.insertFromBin(i_data.c_str()+2, i_start);
                
                break;
            }
            else if (toupper(i_data[1]) == 'X')
            {   // Found Hex Data

                // Convert to uppercase cuz it simplifies things
                transform(i_data.begin(), i_data.end(), i_data.begin(), engdUpper());
                cpA = i_data.find_first_not_of("0123456789ABCDEF", 2);
                
                if (cpA != string::npos)
                {
                    ILOG(P5MSG) << "Invalid digit in hex string: " << i_data << endl;
                    success = false;
                    // Set error indicator
                    break;
                }
                
                // Before insert, must update Basis/Valid lengths
                if (getLenFromData)
                {
                    uint32_t x = digitCount*4;  // 4 bits/digit
                    bitBasis.growBitLength(i_start + x);
                    bitValid.growBitLength(i_start + x);
                    bitValid.setBit(i_start, x);
                }
                
                // Insert hex data into buffer, skipping over "0x"
                if (getLenFromData)
                    ecmdRc = bitBasis.insertFromHexLeft(i_data.c_str()+2, i_start);
                else
                    ecmdRc = bitBasis.insertFromHexLeft(i_data.c_str()+2, i_start, i_length);
                
                if (ecmdRc == ECMD_DBUF_INVALID_DATA_FORMAT)
                {
                    ILOG(P5MSG) << "Invalid hex data: " << i_data << endl;
                    success = false;
                    break;
                }
                else if (ecmdRc != ECMD_DBUF_SUCCESS)
                {
                    ILOG(ERMSG) << "E[1000] **Error** Bad rc from insertFromHexLeft with this data: " << i_data << endl;
                    success = false;
                    break;
                }
                
                // Update bitValid, disregarding "0x"
                if (getLenFromData)
                {
                    i = (i_data.length()-2)*4;  // #bits to put in bitBasis buf
                    bitValid.growBitLength(i_start + i);
                    bitValid.setBit(i_start, i);
                }
            }
        }  // Starts with 0
        else
            success = false;
        
    } while (0);
    
    cout << dec;
 
    return success;   
}


bool fsiCmpAscending(const engdBitSpec_t& lhs, const engdBitSpec_t& rhs)
{
    return lhs > rhs;
}
bool jtagCmpDescending(const engdBitSpec_t& lhs, const engdBitSpec_t& rhs)
{
    return lhs < rhs;
}

bool (*g_cmpFuncPtr)(const engdBitSpec_t&, const engdBitSpec_t&) = NULL;


ostream& operator<<(ostream& ostr, const engdBitSpec_t& rhs)
{
    uint32_t bitValue = (rhs.cv_bitspec & 0x10000000) >> 28;
    ostr << (rhs.cv_bitspec & 0x0fffffff) << ':' << bitValue;
    return ostr;
}
