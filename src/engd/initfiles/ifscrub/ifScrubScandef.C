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




// Change Log *********************************************************
//
//  Flag  def/feat  Userid    Date      Description
//  ----  --------  --------  --------  --------------------------------
//   @03  F750357   wfenlon   05/18/10  VPO & Model EC updates
//   dgxx D754106   dgilbert  06/23/10  Fix warnings
//   @04  F858677   dpeterso  10/18/12  Add P8 processing
//   @06  F866181   dpeterso  01/10/13  Handle inversion flag
//   @07  F866846   dpeterso  01/23/13  Redo ring dump logic - parity bits not set
//   @08  F868940   dpeterso  02/05/13  Generate flush ring with init rings and combine flush & dump parms 
//   @09  F870527   dpeterso  02/19/13  Inversion mask calculation wrong for parity bit 
//   @0A  F890900   dpeterso  07/11/13  Add gptr 'care mask' support 
//   @0B  D893871   dpeterso  07/30/13  Special case gptr rings for centaur 
//   @0C  D902451   dpeterso  11/07/13  Inversion mask on output parity bits not working
// End Change Log *****************************************************

#include <ifScrubDataSpec.H>
#include <netinet/in.h>  // For htonl, ntohl
#include <iomanip>
#include <sstream>

bool EngdScandefFile::locateFragment()
{
    size_t cpA = string::npos;  // Character position

    while (getTangibleLine(cpA))
    {
        if (cv_line.substr(0,14) == "BEGIN Scanring")
            break;
    }
                
    // Strip off leading whitespace
    if (cpA != string::npos)
        cv_line.erase(0, cpA);
    // Don't strip off trailing comments, cuz some spys have '#' in them!
    
    return (! cv_inStream.eof());
}


void EngdScandefFile::digestData()
{
    int rc = 0;
    ofstream ringImageFile;
    uint32_t sriOffset = 0;
    ofstream srdFile, srdBinFile, srdFlushBinFile, asciiDataFile;  // @07c @08c
    ecmdDataBuffer rdBitData;	// ring dump bit data @07a
    ecmdDataBuffer invBitData;	// inversion mask dump bit data @0Ca
    bool skipRing;
    size_t cpA;
    string ringName;
    uint32_t ringAddr = 0, ringLength = 0;
    uint32_t numTokens;
    engdRingModMap_t::iterator modMapIter;
    ecmdDataBuffer ringBitData;
    uint32_t byteLen, wordLen;
    uint32_t tmpWord;
    bool dumpThisRing = false;
    bool gptrRing = false;					// gptr ring flag @0Aa
    engdBitStorePtr_t careBitsPtr;				// 'care mask' data for gptr ring @0Aa
    vector<engdBitSpec_t>::iterator parityVecIter;
    
    do
    {
        // What is this first section of code for?!
        // cpA = cv_scandefFn.find_last_of('/');  // Seek to end of path
        // if (cpA != string::npos)
        //     cpA++;
        // else
        //     cpA = 0;

        ringImageFile.open(P_RingImgFn.c_str(), ios::out | ios::binary);
        if (ringImageFile.good())
        { 
            ILOG(P3MSG) << "Successfully opened file for write: " << P_RingImgFn << '!' << endl;
        }
        else
        {
            ILOG(ERMSG) << "E[1018] **Error** Unable to open file for write: " << P_RingImgFn << endl;
            rc = 2;
            break;
        }
        
        if (P_MimicEcmdRingDump)
        {
            // @03c next - P_EcStr -> P_ArgvEcStr
            // @04c don't store in /tmp and add IPLMODE and flush if specified to file name
	    string iplModeTok = P_IplModeStr;
	    if (P_IplModeStr != "")
	    {
		iplModeTok = iplModeTok + '.';
	    }
	    string srDumpFn = P_ChipStr + '.' + P_ArgvEcStr + '.' + iplModeTok + P_RingToDump + ".srd"; //@08c
            srdFile.open(srDumpFn.c_str());
            if (srdFile.good())
            { 
                ILOG(P3MSG) << "Successfully opened file for write: " << srDumpFn << '!' << endl;
            }
            else
            {
                ILOG(ERMSG) << "E[1019] **Error** Unable to open file for write: " << srDumpFn << endl;
                rc = 3;
                break;
            }
	    string srBinDumpFn = P_ChipStr + '.' + P_ArgvEcStr + '.' + iplModeTok + P_RingToDump + ".bin.srd"; //@08c
            srdBinFile.open(srBinDumpFn.c_str(), ios::out | ios::binary);
            if (srdBinFile.good())
            { 
                ILOG(P3MSG) << "Successfully opened file for write: " << srBinDumpFn << '!' << endl;
            }
            else
            {
                ILOG(ERMSG) << "E[1019] **Error** Unable to open file for write: " << srBinDumpFn << endl;
                rc = 3;
                break;
            }
	    string srFlushBinDumpFn = P_ChipStr + '.' + P_ArgvEcStr + '.' + iplModeTok + P_RingToDump + ".flush.bin.srd";  //@08a
            srdFlushBinFile.open(srFlushBinDumpFn.c_str(), ios::out | ios::binary); //@08a
            if (srdBinFile.good())			//@08a
            { 
                ILOG(P3MSG) << "Successfully opened file for write: " << srFlushBinDumpFn << '!' << endl; //@08a
            }
            else					//@08a
            {
                ILOG(ERMSG) << "E[1019] **Error** Unable to open file for write: " << srFlushBinDumpFn << endl; //@08a
                rc = 3;					//@08a
                break;					//@08a
            }
        }
        
        if (P_DumpAsciiRingData)
        {   
            string adFn = P_AsciiRingFn;
            
            asciiDataFile.open(adFn.c_str());
            if (asciiDataFile.good())
            { 
                ILOG(P3MSG) << "Successfully opened file for write: " << adFn << '!' << endl;
            }
            else
            {
                ILOG(ERMSG) << "E[1020] **Error** Unable to open file for write: " << adFn << endl;
                rc = 4;
                break;
            }
        }
               

        // Skip over first word, containing validity flag, til all rings written
        ringImageFile.seekp(sizeof(uint32_t), ios_base::beg);
        
        // Write out the number of rings
        tmpWord = htonl(P_RingModMap.size());
        ringImageFile.write((char *)&tmpWord, sizeof(uint32_t));
        sriOffset += 2 * sizeof(uint32_t);
        
        uint32_t imgBitOff;
        bool imgBitChg = false;
        
        while (locateFragment())
        {   // Foreach fragment ...
        
            skipRing = false;
            // Grab the ring name, address, and Length here
            // Loop til first bit definition found
            while (getTangibleLine(cpA) && cpA == 0)
            {
                numTokens = parseLineTokens("={,}", 2);
                if (numTokens == 2)
                {
                    switch (getTokStr(0).at(0))
                    {
                    case 'N':
                        if (getTokStr(0) == "Name")
                            ringName = getTokStr(1);
                        modMapIter = P_RingModMap.find(ringName);
                        if (modMapIter == P_RingModMap.end())
                        {
                            // This ring not in the map; Skip it!
                            skipRing = true;
                        }
			// gptr rings require special processing (except on centaur)
			if ((ringName == P_RingToDump) && (ringName.find("gptr") != string::npos) && (P_ChipStr != "centaur"))	// @0Aa @0Bc
			{
			    gptrRing = true;					// @0Aa
			    DLOG(P3MSG) << "Processing gptr ring " << ringName << endl;
			}
			break;
                    case 'A':
                        if (getTokStr(0) == "Address")
                            ringAddr = hexStrtoul(getTokStr(1));
                        break;
                    case 'L':
                        if (getTokStr(0) == "Length")
			    ringLength = decStrtoul(getTokStr(1));
			break;
                    default:
                        // Don't care
                        break;
                    }
                    
                    if (skipRing)
                        break;
                }
                
            }
            
            if (skipRing)
                continue;
            
            if (P_MimicEcmdRingDump)
                dumpThisRing = (ringName == P_RingToDump);

	    // p8 delta scan tool requires start record with ring length and syntax version(?) @04a
	    if (P_MimicEcmdRingDump && dumpThisRing)
	    {
		// gptr ring 'care mask' is the entire set of bits affected in this ring both data and parity bits
		// so we save a copy of the original ring data and parity data to set this special mask 
		if (gptrRing)								// @0Aa
		{
	            // Gptr rings are 2x their defined length
		    ringLength = ringLength*2;						// @0Aa
		    careBitsPtr = new engdBitStore_t;					// @0Aa
		    careBitsPtr->bitQData = modMapIter->second->bitQData;		// @0Aa
		    careBitsPtr->parityData = modMapIter->second->parityData;		// @0Aa
		}
		srdFile << "START" << setw(8) << setfill('0') << hex << ringLength << "0000000200000000" << endl;
		srdFile << "ADDRESS" << setw(8) << setfill('0') << hex << ringAddr << endl; // @08a
		srdBinFile << "START" << setw(8) << uppercase << setfill('0') << hex << ringLength << "0000000200000000" << endl; // @07a
		srdFlushBinFile << "START" << setw(8) << uppercase << setfill('0') << hex << ringLength << "0000000200000000" << endl; // @08a
	    }
                
            // At this point, the following is known:
            // - This ring has modifications stored in the ringModMap
            // - modMapIter->second points to the BitStore containing the modifications
            // - ringAddr contains the primary ring addr for this ring
            // - ringLength contains the length of this ring in bits
            // - The first bit definition line is in cv_line (global line string)
        
            imgBitOff = 0;
            
            DLOG(P5MSG) << "* * * * * * * * * * * * * * * * * * *\nFound ring "
                 << ringName << ", Addr = 0x" << setw(8) << setfill('0') << hex << ringAddr << ", len = " << dec << ringLength << endl;
            
            // DLOG(P6MSG) << "..Bit modification count for ring " << ringName << " is " << modMapIter->second->bitQData.size() << endl;
            
            // @01a - For core rings, turn on bit 1 to indicate multicasting
            if ((ringAddr & 0x0F000000) == 0x08000000)
            {
                ringAddr |= 0x40000000;
            }
            
            // Save ring addr in 1st word of ring record
            tmpWord = htonl(ringAddr);
            ringImageFile.write((char *)&tmpWord, sizeof(uint32_t));
            // Save ring len in 2nd word of ring record
            tmpWord = htonl(ringLength);
            ringImageFile.write((char *)&tmpWord, sizeof(uint32_t));
            sriOffset += 2 * sizeof(uint32_t);
            // imgBitOff += 64;
            // The ring image data will be rounded up to nearest byte, so calc here
            byteLen = (ringLength %  8) ? (ringLength /  8) + 1 :  ringLength /  8;
            // The code below works with full words, however, so calc here
            wordLen = (ringLength % 32) ? (ringLength / 32) + 1 :  ringLength / 32;
            rc = ringBitData.setWordLength(wordLen);
            if (rc != ECMD_DBUF_SUCCESS)
            {
                // Unable to allocate ecmdDataBuffer for ring
                ILOG(ERMSG) << "E[1021] **Error** ecmdDataBuffer Allocation error!" << endl;
                rc = 3;
                break;
            }

            rc = rdBitData.setWordLength(wordLen);	// @07a
            if (rc != ECMD_DBUF_SUCCESS)		// @07a
            {
                // Unable to allocate ecmdDataBuffer for ring
                ILOG(ERMSG) << "E[1021] **Error** ecmdDataBuffer Allocation error!" << endl; // @07a
                rc = 3;					// @07a
                break;					// @07a
            }

            rc = invBitData.setWordLength(wordLen);	// @0Ca
            if (rc != ECMD_DBUF_SUCCESS)		// @0Ca
            {
                // Unable to allocate ecmdDataBuffer for ring
                ILOG(ERMSG) << "E[1021] **Error** ecmdDataBuffer Allocation error!" << endl; // @0Ca
                rc = 3;					// @0Ca
                break;					// @0Ca
            }
        
            if (P_DumpAsciiRingData)
            {
                asciiDataFile << "* * * * * * * * * * * * * * * * * * * * * * * " << endl;
                asciiDataFile << "For ring addr 0x" << hex << setw(8) << setfill('0') << ringAddr << ":  Storing " <<
                            dec << ringLength << " bits of data in " << byteLen << " bytes of buffer" << endl;
            }
            
            uint32_t bitCount;
            uint32_t ringBitAddr;
            int upDown;
            uint32_t invMask;
            uint32_t i;
            uint32_t wordNum, wordData, bitInWord, switchBit;
            uint32_t prevBitInWord = 99;
            string imgBits(128, '.');
            bool allowDataSave;
            string latchStr;
            string bitModKey;
            char bitValue;           //@06a
            bool shortForm = false;  //dgxx -fix warning
            
            
            if (P_MimicEcmdRingDump && dumpThisRing)
            {
                numTokens = parseLineTokens("", 5);
                if (numTokens == 5)
                {
                    latchStr = getTokStr(4);
                    if (latchStr.find_last_of(')') != string::npos)
                    {
                        latchStr.replace(latchStr.length()-1, 1, 1, '.');
                        shortForm = false;
                    }
                    else
                    {
                        latchStr += '=';
                        shortForm = true;
                    }
                }
            }
            else
            {
                numTokens = parseLineTokens("", 4);
            }
            
            if (P_FSItype)
            {
                ringBitAddr = 0;
                upDown    = 1;
                wordNum   = 0;
                bitInWord = 0;
                switchBit = 31;
            }
            else
            {
                if (numTokens < 4)
                {
                    // Problem parsing, skip to next frag
                    ILOG(ERMSG) << "E[1022] **Error** Unable to find 3 tokens on JTAG line: " << cv_line << endl;
                    break;
                }
                
                // For JTAG, starting addr = first JTAG_addr - first bit_count + 1
                uint32_t maxAddr = decStrtoul(getTokStr(2));
                ringBitAddr = maxAddr - decStrtoul(getTokStr(0)) + 1;
                DLOG(P5MSG) << "ringBitAddr = " << dec << ringBitAddr << endl;
                upDown    = -1;
                wordNum   = ((maxAddr + 32)/32) - 1;
                bitInWord = ringBitAddr%32;
                switchBit = 0;
            }
            DLOG(P5MSG) << "@@a- - - - - - Starting ringBitAddr for ring " << ringName << " = " << dec << ringBitAddr << endl;
            
            imgBitChg  = false;
            
            allowDataSave = false;
                
            wordData = 0;
            do
            {
                bitCount = decStrtoul(getTokStr(0));
                // invMask = getTokStr(3).at(0) - '0';
                
                if (P_MimicEcmdRingDump && dumpThisRing)
                {
                    if (! shortForm)
                        srdFile << latchStr + "0b";
                    else
                        srdFile << latchStr + '.';
                }
            
                for (i=0; i<bitCount; ++i, ringBitAddr += upDown)
                {   // For each bit in latch
                
                    if (allowDataSave && (ringBitAddr % 128) == 0)
                    {
                        if (imgBitChg)
                        {
                            for (uint32_t j = 96; j > 0; j -= 32)
                            {
                                imgBits.insert(j, 1, ' ');
                            }
                        
                            if (0)  // dbgPlus
                            {
                            DLOG(P5MSG) << "@@a        :---+---:---+---:---+---:---+---#:---+---:---+---:---+---:---+---#:---+---:---+---:---+---:---+---#:---+---:---+---:---+---:---+---" << endl;
                            DLOG(P5MSG) << "@@a" << setw(6) << setfill('0') << hex << imgBitOff/8 << ": " << imgBits << endl;
                            }
                            imgBits.assign(132, '.');
                            imgBitChg = false;
                            
                            // Prevent imgBits from growing by 3 on every pass
                            imgBits.erase(128);
                        }
                        imgBitOff += 128;
                    }
                
                    if (prevBitInWord == switchBit)
                    {
                        // At this point, we have just passed a word boundary,
                        // so save the previous word of data
                        if (0)  // dbgPlus
                        {
                            DLOG(P5MSG) << "@@a1 Storing word[" << 
                             wordNum << "] = 0x" << hex << setw(8) << setfill('0') << wordData <<
                             ".  NEXT ringBitAddr = " << dec << ringBitAddr << endl;
                        }
                        if (wordNum > ringBitData.getWordLength()) // wfdbg - new check and code
                        {
                            ILOG(ERMSG) << "E[1023] * * ecmdDataBuffer overflow: wordlen = " << ringBitData.getWordLength() << endl;
                            break;
                        }
                        else
                        {
                            ringBitData.setWord(wordNum, wordData); // wfdbg - existing code
                        }
                        wordNum += upDown;
                        bitInWord = 31 - switchBit;  // 31 -> 0 or 0 -> 31
                        wordData = 0;
                    }
                    
#if 0                    
                    if(bitInWord == 31 && prevBitInWord != 0)
                    {
                        ILOG(ERMSG) << "E[1023] * * Skip Error 1! prev b.i.w = " << dec << prevBitInWord << ", curr b.i.w. = " << bitInWord << endl;
                    }
                    else if (bitInWord == 31 && prevBitInWord == 0)
                    {}  // All is well -- this is a normal case
                    else if (bitInWord != (prevBitInWord - 1))
                    {
                        ILOG(ERMSG) << "E[1024] * * Skip Error 2! prev b.i.w = " << dec << prevBitInWord << ", curr b.i.w. = " << bitInWord << endl;
                    }
#endif                    
                        
                    prevBitInWord = bitInWord;
                    	
                    if (modMapIter->second->bitQData.top().getAddress() == ringBitAddr)
                    {
                        // Found matching address in RingMods BitQ
                        // Retrieve the bit value
                        if (modMapIter->second->bitQData.top().getValue())
                        {
                            wordData |= 0x80000000 >> bitInWord; 
			}

			invMask = getTokStr(3).at(0) - '0';	// Get inversion flag  @06a
			// Figure out bit value based on original value and inversion mask
                        if ((!modMapIter->second->bitQData.top().getValue() && !invMask) ||
			   (modMapIter->second->bitQData.top().getValue() && invMask))	// @06a 08c
                        {
                            bitValue = '0';			// Bit value zero @06a
			}
			else
			{
                            bitValue = '1';			// Bit value non-zero @06a
			}
			if (P_MimicEcmdRingDump && dumpThisRing)
			{   
			    srdFile << bitValue;		// Write calculated bit value @06c
			    bitModKey += '^';			
                            imgBits[ringBitAddr % 128] = bitValue; // Add to image bits @06c
			    if (bitValue == '1')		// Set bin for binary ring dump @07a
			    {
				rdBitData.setBit(ringBitAddr);	// @07a
			    }
                        }
                        
                        imgBitChg = true;
                        
                        // Done with this modification, pop it off the queue
                        if (modMapIter->second->bitQData.size())
                        {
                            modMapIter->second->bitQData.pop();
                        }
                        else
                        {
                            ILOG(ERMSG) << "E[1026] **Error** Attempt to pop value off EMPTY BitQ!" << endl;
                        }
		    }
                    else
                    {
                        // This bit NOT in RingMods BitQ
                        invMask = getTokStr(3).at(0) - '0'; // Get inversion mask @0Ca
                        if (invMask)						//@0Ca
                        {							//@0Ca
			    invBitData.setBit(ringBitAddr); // Save inversion mask@0Ca
                        //    wordData |= 0x80000000 >> bitInWord;	@09d
                        }							//@0Ca
                            
                        if (P_MimicEcmdRingDump && dumpThisRing)
                        {   // Do not invert ecmd-style ringdump data
                            srdFile << '0';
                            bitModKey += '-';
                        }
                    }
                    
                    allowDataSave = true;
                    bitInWord += upDown;
                }   // For each bit in latch
                
                if (P_LogData.isCriticalError())  // wfdbg add
                    break;
                
                getLINE(cv_line);
                if (P_MimicEcmdRingDump && dumpThisRing)
                {
                    if (! shortForm)
                        srdFile << " @RD@1" << endl << latchStr + "::" + bitModKey + " @RD@2" << endl;
                    else
                        srdFile << " @RD@1" << endl << latchStr + ':' + bitModKey + " @RD@2" << endl;
                    bitModKey.erase();
                    numTokens = parseLineTokens("", 5);
                    if (numTokens == 5)
                    {
                        latchStr = getTokStr(4);
                        if (latchStr.find_last_of(')') != string::npos)
                        {
                            latchStr.replace(latchStr.length()-1, 1, 1, '.');
                            shortForm = false;
                        }
                        else
                        {
                            latchStr += '=';
                            shortForm = true;
                        }
                    }
                }
                else
                {
                    numTokens = parseLineTokens("", 4);
                }
                
	    } while ((! isEOF()) && (numTokens >= 4));

            if (P_FSItype || ringBitAddr < ringBitData.getBitLength())
            {
                // dbgPlus
		if (0) { DLOG(P5MSG) << "2 Storing word[" << wordNum << "] = 0x"
                     << hex << setw(8) << wordData << ".  NEXT ringBitAddr = "
		  << dec << ringBitAddr << endl; }
                if (wordNum > ringBitData.getWordLength()) // wfdbg - new check and code
                {
                    ILOG(ERMSG) << "E[1024] * * ecmdDataBuffer overflow: wordlen = " << ringBitData.getWordLength() << endl;
                    break;
                }
                else
                {
                    ringBitData.setWord(wordNum, wordData);  // wfdbg - existing code
                }
            }
            
            DLOG(P6MSG) << "EORing, ringBitAddr = " << dec << ringBitAddr << endl;
            
            // Basic data collection is now complete for this ring, but before
            // saving the ring image, we must calculate any needed parity
            uint32_t paritySum = 0;
            uint32_t rangeStart;
            
            parityVecIter = modMapIter->second->parityData.begin();
            DLOG(P6MSG) << "- - - - - Start parity loop for ring " << ringName <<
                 ", and parityData sz = " << dec << modMapIter->second->parityData.size() << endl;
            while (parityVecIter != modMapIter->second->parityData.end())
            {
                if (parityVecIter->isBitParInput())
                {   // Process input parity bit(s)
                    if (parityVecIter->isParBitRange())
                    {     // Process a range of bits
                          rangeStart = parityVecIter->getAddress();
                          uint32_t rangeLength = (parityVecIter+1)->getLength();	 // @0Ca
			  for (uint32_t j = rangeStart; j < rangeStart+rangeLength; j++)  //@0Ca
			  {   // Process each input parity bit in the range		    @0Ca
			      if ((!(invBitData.getBit(j)) && (ringBitData.isBitSet(j))) ||
			  	  ((invBitData.getBit(j)) && !(ringBitData.isBitSet(j))))  //@0Ca
			      {
			  	  paritySum++;						  // @0Ca
			  	  DLOG(P5MSG) << "- - - - - Adding range bit to parity sum.  Addr = " << j <<  endl;						// @0Ca
			      }								  // @0Ca
			  }
			      
			  parityVecIter++;
                          //paritySum += ringBitData.getNumBitsSet(rangeStart, parityVecIter->getLength()); @0Cd
                   }
                    else
                    {     // Process a single input parity bit
                          if ((!(invBitData.getBit(parityVecIter->getAddress())) && (ringBitData.isBitSet(parityVecIter->getAddress()))) || ((invBitData.getBit(parityVecIter->getAddress())) && !(ringBitData.isBitSet(parityVecIter->getAddress()))))  // @0Ca
			  {
                              paritySum++;
 			  DLOG(P5MSG) << "- - - - - Adding single bit to parity sum.  Addr = " << parityVecIter->getAddress() <<  endl;			// @0Ca
			  }								 // @0Ca
                    }
                }
		else 
                {     // Calculate output parity bit and save it to buffer
		      // Retrieve inversion mask bit to factor into setting of parity bit
		      invMask = invBitData.getBit(parityVecIter->getAddress());		// @0Ca
		      if (invMask)		// Output parity should be inverted	// @0Ca		
		      {
			  DLOG(P5MSG) << "- - - - - Inver. mask set for output parity addr = " << parityVecIter->getAddress() <<  endl;			// @0Ca
			  paritySum+=1;		// Add 1 to parity sum to invert parity setting @0Ca
		      }									// @0Ca
                      if (parityVecIter->isEvenParity())
                      {   // Even parity
                          if (paritySum%2)
                          {
                              ringBitData.setBit(parityVecIter->getAddress());
                              rdBitData.setBit(parityVecIter->getAddress());		// @07a
                         }
                          else
                          {
                              ringBitData.clearBit(parityVecIter->getAddress());
                              rdBitData.clearBit(parityVecIter->getAddress());		// @07a
                          }
                      }
                      else
                      {   // Odd parity
                         if (paritySum%2)
                          {
                              ringBitData.clearBit(parityVecIter->getAddress());
                              rdBitData.clearBit(parityVecIter->getAddress());		// @07a
                          }
                          else
                          {
                              ringBitData.setBit(parityVecIter->getAddress());
			      rdBitData.setBit(parityVecIter->getAddress());		// @07a
                         }
                      }
                      
                      // Done with current parity calc, reset sum for next loop
                      paritySum = 0;
                }
                
                // Advance to next parity element
                parityVecIter++;
            }
            
            DLOG(P3MSG) << "Writing " << ringName << " ring image to file at byte offset = " << dec << sriOffset << endl;
            
            // Last data for this ring has been written, so write it out to file!
            // May have extra length since working with words, so shrink it down
            ringBitData.shrinkBitLength(8 * byteLen);
            rdBitData.shrinkBitLength(8 * byteLen);					// 07a
            
            DLOG(P5MSG) << "Ring[" << ringName << dec << "] bitLen[" << ringLength << "] byteLen[" << byteLen
                 << "] addr[" << hex << setw(8) << setfill('0') << ringAddr << "] offset[" << dec << sriOffset << ']' << endl;
            // And store it to file - eCMD version.  This does htonl on all words.
            ringBitData.writeFileStream(ringImageFile);
            sriOffset += ringBitData.getByteLength();

	    if (dumpThisRing)					// @07a
	    {

		if (gptrRing)							// @0Aa
		{
		    // Set care mask primary data and parity data
		    // Set primary data
		    bitCount = careBitsPtr->bitQData.size();			// @0Aa
		    for (i=0; i<bitCount; ++i)					// @0Aa
		    {
			// Set bit in care mask (second half of the double size ring)
			rdBitData.setBit((ringLength/2)+(careBitsPtr->bitQData.top().getAddress())); // @0Aa
		        // Advance to next address 				   @0Aa
			careBitsPtr->bitQData.pop();				// @0Aa
		    }

		    // Set parity data
		    parityVecIter = careBitsPtr->parityData.begin();		// @0Aa
		    while (parityVecIter != careBitsPtr->parityData.end())	// @0Aa
		    {
			// Only need to set output parity bits
			if (!parityVecIter->isBitParInput())			// @0Aa 
			{     // Set bit in care mask (second half of the double size ring)
			    rdBitData.setBit((ringLength/2)+(parityVecIter->getAddress()));	// @0Aa
			}
		        // Advance to next parity element			   @0Aa
			parityVecIter++;					// @0Aa
		    }
		    delete careBitsPtr;						// @0Aa
		}

		string wordOfZeros = "00000000";		// @08a
		int nibLen = (ringLength+3)/4;			// @07a
		int lastWordLen = nibLen % 8;			// Remainder of # nibbles / 8 nibbles/word @07a
		if (! lastWordLen) {lastWordLen = 8;}		// Set width to 8 for if not partial word @07a
		// Dump length = # nibbles + 1 space/line end per word (8 nibbles) + start and end line lengths
		int ringDumpLen = nibLen + (nibLen+7)/8 + 34;	// @07a

		stringstream lineOut, flushLineOut;		// @07a @08c
		lineOut.str("");				// @07a
		flushLineOut.str("");				// @08a
		// Write ring words to dump file
		for (i=0; i+1 < (int)wordLen; ++i)		// @07a
		{
		    // Concatenate each word to line buffer
		    lineOut << setw(8) << setfill('0') << uppercase << hex  << rdBitData.getWord(i); // @07a
		    flushLineOut << wordOfZeros;		// Flush ring is all zeros		@08a
		    // Write line every 8 words
		    if ((i+1) % 8)				// @07a
		    {
			lineOut << " ";				// Separate words on a line with a space @07a
			flushLineOut << " ";			// Separate words on a line with a space @08a
		    }
		    else
		    {
			srdBinFile << lineOut.str() << endl;	// Add line end and write to file @07a
			lineOut.str("");			// Clear line buffer @07a
			srdFlushBinFile << flushLineOut.str() << endl;	// Add line end and write to file @08a
			flushLineOut.str("");			// Clear line buffer @08a
		    }
		}
		lineOut << setw(lastWordLen) << setfill('0') << uppercase << hex << rdBitData.getWord(i); // @07a
		srdBinFile << lineOut.str() << endl;		// Add line end and write to file @07a
		flushLineOut << wordOfZeros.substr(0,lastWordLen); // @08a
		srdFlushBinFile << flushLineOut.str() << endl;	// Add line end and write to file @08a


		DLOG(P5MSG) << "ringDumpLen" << hex << ringDumpLen << endl; // @07a
		srdBinFile << "END" << endl;			//                                         @07a
		srdBinFile << "BEGIN";				//					   @07a
		srdFlushBinFile << "END" << endl;		//                                         @08a
		srdFlushBinFile << "BEGIN";			// The last line of file contains bin data @08a
		uint64_t tmpString = 0;				// dump length seems to be the only one    @07a
		tmpString = 0x0000000000000000;			// that ever changes                       @07a
		srdBinFile.write((char *)&tmpString, 7);	//                                         @07a
		srdBinFile << "END";				// @07a
		srdFlushBinFile.write((char *)&tmpString, 7);	// @08a
		srdFlushBinFile << "END";			// @08a

		tmpString = htonl(ringDumpLen);			// @07a
		tmpString <<= 8;				// @07a
		srdBinFile.write((char *)&tmpString, 6);	// @07a
		srdFlushBinFile.write((char *)&tmpString, 6);	// @08a

		tmpString = 0x0000000000020000;			// @07a
		srdBinFile.write((char *)&tmpString, 3);	// @07a
		srdFlushBinFile.write((char *)&tmpString, 3);	// @08a

	    }

	    if (P_DumpAsciiRingData)
		asciiDataFile << ringBitData.genHexLeftStr().c_str() << endl;

	    DLOG(P5MSG) << setw(6) << setfill('0') << imgBitOff << ": " << imgBits << '$' << endl;

        }   // Foreach fragment
        
        // Write first word of image to indicate it is valid
        ringImageFile.seekp(0, ios_base::beg);
        tmpWord = htonl(0xAABBCCDD);
        ringImageFile.write((char *)&tmpWord, sizeof(uint32_t)) ;

    } while (0);


    if (rc != 2)
        ringImageFile.close();
    if (P_MimicEcmdRingDump && rc != 3)
    {
        srdFile.close();
	srdBinFile.close();
	srdFlushBinFile.close(); //@08a
    }
    if (P_DumpAsciiRingData && rc != 4)
        asciiDataFile.close();
    
    return;
}
