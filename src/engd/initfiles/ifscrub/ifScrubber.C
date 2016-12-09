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
//        F720242   wfenlon   08/26/09  Created
//  @01   D724558   wfenlon   09/18/09  Fix JTAG bug, add multicasting bit for
//                                      Thi, and update logging/output calls
//  @02   D750007   wfenlon   04/20/10  Change max verbosity from 5 to 8
//  @03   F750357   wfenlon   05/18/10  VPO & Model EC updates
//  @04   F858677   dpeterso  09/19/12  Updates for p8
//  @05   F861608   dpeterso  11/19/12  Updates for centaur
//  @06   F866182   dpeterso  01/03/13  Support for 'env' as static init
//  @08   F868940   dpeterso  01/30/13  Fold flush parm & dump ring into single parm
//  @0A   D908472   dpeterso  12/03/13  Store affected rings names for build verification
//        D954830   maploetz  03/12/15  Added Naples chip
// End Change Log *****************************************************

#include <netinet/in.h>  // For htonl, ntohl
#include <iomanip>    // for setw
#include <iostream>   // for cout, endl
#include <ifScrubFileSpec.H>
#include <ifScrubber.H>


/**
 * Show usage if user requests it (-h) or problem with args
*/
void showUsage()
{
    cout << "Usage:" << endl;
    cout << "  ifScrubber chipType ecVal <options>" << endl;
    cout << "Where:" << endl;
    cout << "  chipType is one of: p5ioc2, p7, supernova, or torrent" << endl;
    cout << "  ecVal = ec value as it appears in spydef & scandef filenames" << endl;
    cout << "And <options> are optional filename overrides (defaults in parens):" << endl;
    cout << "  -s iplmode: HBI or RUNTIME" << endl;
    cout << "  -e env: U (for sim) or W (for hdw - default)" << endl;   //@06a
    cout << "  -c cFn: config name (ifscrub/ifScrubber.config)" << endl;
    cout << "  -i iFn: initfile name (<chipType>.initfile)" << endl;
    cout << "  -y yFn: spydef filename (<chipType>_<ecVal>.spydef)" << endl;
    cout << "  -n nFn: scandef filename (<chipType>_<ecVal>.scandef)" << endl;
    cout << "  -r rFn: reduced initfile name (<chipType>_<ecVal>.initfile)" << endl;
    cout << "  -m mFn: ring image filename (<chipID>_<4-digit Ec>_static_rings.dat)" << endl;
    cout << "          (For example - 20F9_0010_static_rings.dat)" << endl;
    cout << "  -l lFn: log filename (<chipType>_<ecVal>.ifScrubber.log)" << endl;
    cout << "  -d ringName: output ecmd ringdump-compatible file for ringName (and flush ring)" << endl;
    cout << "  -g gFn: affected ring list filename (used for build verification to ensure all required rings are generated)" << endl;	// @0Aa
    cout << "  -a aFn: ascii ring dump (/tmp/<chipType>.ringdata)" << endl;
    cout << "  -v #: Output verbosity level, from 0 (none) to 4 (max)" << endl;
}

int parseInputArgs(int argc, char *argv[])
{
    int32_t thisOpt;
    bool optUsage = false;
    uint32_t verbSel;
    int rc = 0;
    string fnStr;
    
    do
    {
        if (argc < 3)
        {
          // Not enough args
          optUsage = true;
        }
        else
        {
            // Required first arg is chip string
            P_ChipStr = argv[1];
            
            // Required second arg is ec string
            P_ArgvEcStr = argv[2];  // @03c - was P_EcStr
            
            // @03a - below
            if (P_ArgvEcStr.length() == 6)
            {   // This is a 6-digit model (or sim) EC
                // EC used for if-stmt evals is found in 2nd/3rd digits
                P_EvalEcStr = P_ArgvEcStr.substr(1, 2);
            }
            else
            {
                P_EvalEcStr = P_ArgvEcStr;
            }
            // @03a - above
            
            // Need numeric version of ec string for evaluating conditions
            P_EcValue = hexStrtoul(P_EvalEcStr);  // @03c - was P_EcStr
        
            // Check for valid chip type
            // @03c next - add p7p term
            // @04c next - add s1 and p8 term
	    // @05c next - add centaur term
            if (P_ChipStr != "p5ioc2" && P_ChipStr != "p7" && P_ChipStr != "p7p" && P_ChipStr != "s1" && P_ChipStr != "p8" &&
                P_ChipStr != "supernova" && P_ChipStr != "torrent" && P_ChipStr != "centaur" && P_ChipStr != "n1") 
            {
                rc = 1;
                ILOG(ERMSG) << "E[1027] **Error** Unsupported chip type: " << P_ChipStr << endl;
                break;
            }
        }
        
        // Remaining args are optional...
        while(-1 != (thisOpt = getopt(argc, argv, "s:c:i:y:n:l:r:m:d:a:e:g:v:h?"))) // @08c @0Ac
        {
            switch(thisOpt)
            {
            case 'c':
                P_CnfgFile.setFn(optarg);
                break;
            case 'i':
                P_InitFile.setFn(optarg);
                break;
            case 'y':
                P_SpydFile.setFn(optarg);
                break;
            case 'n':
                P_ScndFile.setFn(optarg);
                break;
            case 'l':
                P_LogFn = optarg;
                break;
            case 'r':
                P_ReducedFn = optarg;
                break;
            case 'm':
                P_RingImgFn = optarg;
                break;
            case 'd':
                P_RingToDump = optarg;
                P_MimicEcmdRingDump = true;
               break;
            case 'a':
                P_AsciiRingFn = optarg;
                P_DumpAsciiRingData = true; 
                break;
            case 's':  // @04a - add iplmode parm
                P_IplModeFilter = true;
                P_IplModeStr = optarg;
                break;
            case 'e':  // @06a - add environment parm
                P_EnvFilter = optarg;  //@06a 
                break;                 //@06a
            case 'g':  // @0Aa - add ring list filename
                P_RingListFn = optarg;  //@0Aa 
                break;                 //@0Aa
            case 'v':  // @02c - chg max verbosity level from 5 to 8
                verbSel = decStrtoul(optarg);
                if (verbSel <= 8)
                    g_VBMask = VBM_LE8 >> (8-verbSel);
                break;
            case 'h':
            case '?':
                optUsage = true;
                break;
            }
        }

        if (optUsage)
        {
            showUsage();
            rc = 22;
            break;
        }
        
        if (P_CnfgFile.noFnSet())
            P_CnfgFile.setFn("ifscrub/ifScrubber.config");
        if (P_InitFile.noFnSet())
        {
            fnStr = "initfiles/" + P_ChipStr + ".initfile";
            P_InitFile.setFn(fnStr.c_str());
        }
        if (P_SpydFile.noFnSet())
        {
            fnStr = "figspy/" + P_ChipStr + '_' + P_ArgvEcStr + ".spydef";  // @03c - was P_EcStr
            P_SpydFile.setFn(fnStr.c_str());
        }
        if (P_ScndFile.noFnSet())
        {
            fnStr = "scandef/" + P_ChipStr + '_' + P_ArgvEcStr + ".scandef";  // @03c - was P_EcStr
            P_ScndFile.setFn(fnStr.c_str());
        }
        if (P_LogFn.empty())
            P_LogFn = P_ChipStr + '_' + P_ArgvEcStr + ".ifScrubber.log";  // @03c - was P_EcStr
        if (P_EnvFilter.empty())          // @06a Environment not specified 
            P_EnvFilter = "W";            // @06a Default to hardware ('W') 
        if (P_ReducedFn.empty())
            P_ReducedFn = P_ChipStr + '_' + P_ArgvEcStr + ".initfile";  // @03c - was P_EcStr
        if (P_RingImgFn.empty())
        {
            string chipIdStr, padEC = P_ArgvEcStr;  // @03c - was P_EcStr
            
            // Translate chip type to chip ID string
            if (P_ChipStr == "p7")
                chipIdStr = "20F9";
            else if (P_ChipStr == "p7p")   // @03a
                chipIdStr = "20E8";        // @03a
            else if (P_ChipStr == "p8")   // @04a
                chipIdStr = "20EA";        // @04a
            else if (P_ChipStr == "s1")   // @04a
                chipIdStr = "20EF";        // @04a
            else if (P_ChipStr == "p5ioc2")
                chipIdStr = "1061";
            else if (P_ChipStr == "supernova")
                chipIdStr = "60FD";
            else if (P_ChipStr == "torrent")
                chipIdStr = "10FC";
            else if (P_ChipStr == "centaur") // @05a
                chipIdStr = "60E9";          // @05a
            
            // Pad EC value on left with zeros to get 4-digit string
            // @03c - Only do this if NOT a model/sim EC
            if (P_ArgvEcStr.length() < 4)
                padEC.insert(0, 4-P_ArgvEcStr.length(), '0');  // @03c - was P_EcStr
        
            P_RingImgFn = chipIdStr + '_' + padEC + "_static_rings.dat";
        }
        
    #ifdef FILEDBG
        if (P_LogData.openTheLog(P_LogFn.c_str()))
        {
            ILOG(INMSG) << "Entering ifScrubber..." << endl;
            ILOG(P3MSG) << "Successfully opened " << P_LogFn << '!' << endl;
        }
        else
        {
            // Can't output this to the log file we just failed to open!
            cout << "**Error** Unable to open file: " << P_LogFn << endl;
            rc = 2;
            break;
        }
    #else
        // If FILEDBG not defined, send the file output to the bit bucket
        P_LogData.openTheLog("/dev/null");
        ILOG(INMSG) << "Entering ifScrubber..." << endl;
    #endif
               
        // Set up some particulars based on FSI vs JTAG
        if (P_ChipStr == "p5ioc2")
        {
            P_FSItype = false;
            g_cmpFuncPtr = &jtagCmpDescending;
        }
        else
        {
            P_FSItype = true;
            g_cmpFuncPtr = &fsiCmpAscending;
        }
    } while (0);
    
    return rc;
}


/**
 * Parse the initfile: The first of 3 major functions called from main().
 *
 * @return void
 */

/**
 * Parse the spydef: The second of 3 major functions called from main().
 *
 * @return void
 */

// *********************************************************************
// Process .scandef, the last of 3 engd files to process.
// *********************************************************************
/**
 * Parse the scandef: The last of 3 major functions called from main().
 *
 * @return void 
 */

// *********************************************************************
// ***** Main
// *********************************************************************
int main(int argc, char *argv[])
{
    uint32_t rc = 0;
    
    do
    {
        // *********************************************************************
        // ***** Process the command line args
        // *********************************************************************
        rc = parseInputArgs(argc, argv);
        
        if (P_LogData.isCriticalError() || rc != 0)
        {
            ILOG(ERMSG) << "Failure in parseInputArgs!" << endl;
            break;
        }
        
        // *********************************************************************
        // ***** Process the initfile
        // *********************************************************************
        processInitfile();
        
        if (P_LogData.isCriticalError())
        {
            rc = 3;
            break;
        }

        // *********************************************************************
        // ***** Process the config file
        // *********************************************************************
        
        processConfig();
        
        if (P_LogData.isCriticalError())
        {
            rc = 4;
            break;
        }

        // *********************************************************************
        // ***** Process the spydef
        // *********************************************************************
        
        processSpydef();
        
        if (P_LogData.isCriticalError())
        {
            rc = 5;
            break;
        }

        // *********************************************************************
        // ***** Process the scandef
        // *********************************************************************
        
        processScandef();
        
        if (P_LogData.isCriticalError())
            rc = 6;
        
    } while (0);

    ILOG(INMSG) << "Exiting ifScrubber, rc = " << rc << endl;

    return rc;
}

