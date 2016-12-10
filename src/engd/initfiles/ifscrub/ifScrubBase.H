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
//  @02   D750007   wfenlon   04/20/10  Add case insensitive functions
//  @10   D901675   dpeterso  10/09/13  Increase max number of tokens from 8 to 20
// End Change Log *****************************************************

#ifndef IFSCRUBBASE_H
#define IFSCRUBBASE_H

#include <stdint.h>	// for uint32_t
#include <string>
#include <string.h>   // Needed for memcpy?!
#include <stdio.h>    // For strtoul
#include <stdlib.h>   // For strtoul
#include <iostream>   // For streambuf
#include <fstream>    // For streambuf/ofstream/ostream

using namespace std;

// Forward declare
class LogItStream;

#define BASICDBG
#define FILEDBG
#define MAX_LINE_TOKENS 20

struct tokenInfo_t
{
    string::size_type position;
    uint32_t          length;
    char              delimeter;
};


class EngdBaseFile
{
    public:
        // Methods...
        EngdBaseFile() {}
        virtual ~EngdBaseFile();
        void setFn(const char * i_fn) {cv_fn = i_fn;}
        string getFn() {return cv_fn;}
        bool noFnSet() {return cv_fn.empty();}
        void processFile(LogItStream & i_log);
        virtual bool locateFragment() = 0;
        virtual void digestData() = 0;
        bool getTangibleLine(size_t & o_firstNonWS, uint32_t * o_numLines = NULL, streampos * o_linePos = NULL);
        streampos tellG() {return cv_inStream.tellg();}
        istream & seekG(streamoff off, ios_base::seekdir dir)
            {return cv_inStream.seekg(off, dir);}
        bool isEOF() {return cv_inStream.eof();}
        istream & getLINE (string & s) {return getline(cv_inStream, s);}

        // getTok functions -- All inlined below
        string::size_type getTokPos(uint32_t index);
        string getTokStr(uint32_t index);
        char getTokDel(uint32_t index);

        uint32_t parseLineTokens(const string & i_delimChars, const uint32_t i_max);

        bool getDelimitedString(const string & i_string, size_t i_startOffset,
                                string i_delimCharSet, string i_skipCharSet,
                                string & o_dString, size_t & o_nextAfterSkip);
    protected:
        string    cv_fn;
        ifstream  cv_inStream;
        string    cv_line;
        tokenInfo_t cv_tokenInfo[MAX_LINE_TOKENS];
};


// Define function for use with transform to convert strings to uppercase
struct engdUpper
{
  int operator()(int c)
  {
    return std::toupper((unsigned char)c);
  }
};


uint32_t hexStrtoul(const string & i_hexStr);

uint32_t decStrtoul(const string & i_decStr);

uint32_t binStrtoul(const string & i_binStr);


// ---------- INLINES ---------------
inline uint32_t hexStrtoul(const string & i_hexStr)
{
    return strtoul(i_hexStr.c_str(), NULL, 16);
}

inline uint32_t decStrtoul(const string & i_decStr)
{
    return strtoul(i_decStr.c_str(), NULL, 10);
}

inline uint32_t binStrtoul(const string & i_binStr)
{
    return strtoul(i_binStr.c_str(), NULL, 2);
}

inline string::size_type EngdBaseFile::getTokPos(uint32_t index)
{
    return (cv_tokenInfo+index)->position;
}

inline string EngdBaseFile::getTokStr(uint32_t index)
{
    tokenInfo_t * tok = cv_tokenInfo+index;
    return cv_line.substr(tok->position, tok->length);
}

inline char EngdBaseFile::getTokDel(uint32_t index)
{
    return (cv_tokenInfo+index)->delimeter;
}

// @02a - below
inline bool chrEqCaseIn(const char c1, const char c2)
{
    return (toupper(c1) == toupper(c2));
}

inline bool strEqCaseIn(const string s1, const string s2)
{
    return (s1.length() == s2.length()) && equal(s1.begin(), s1.end(), s2.begin(), chrEqCaseIn);
}
// @02a - above

// -----------------------------------------------------------------------------
// Debug/Logging code below

enum Verbosity
{
    NOMSG = 0,  // Suppress
    ERMSG = 1,  // Error
    INMSG = 2,  // Informational
    P3MSG = 3,  // Misc priority 3
    P4MSG = 4,  // Misc priority 4
    P5MSG = 5,  // Misc priority 5
    P6MSG = 6,  // Misc priority 6
    P7MSG = 7,  // Misc priority 7
    P8MSG = 8   // Misc priority 8
};

enum  // Verbosity mask values
{
    VBM_EQ0 = 0x00000000,  // Setting for cmdline arg: -v 0 (NO output)
    VBM_LE1 = 0x00000100,  // Setting for cmdline arg: -v 1 (error output)
    VBM_LE2 = 0x00000300,  // Default, Same as cmdline arg: -v 2 (informational)
    VBM_LE3 = 0x00000700,  // Setting for cmdline arg: -v 3 (debug)
    VBM_LE4 = 0x00000F00,  // Setting for cmdline arg: -v 4 (debug)
    VBM_LE5 = 0x00001F00,  // Setting for cmdline arg: -v 5 (debug)
    VBM_LE6 = 0x00003F00,  // Setting for cmdline arg: -v 6 (debug)
    VBM_LE7 = 0x00007F00,  // Setting for cmdline arg: -v 7 (debug)
    VBM_LE8 = 0x0000FF00,  // Setting for cmdline arg: -v 8 (debug)
    // Debug enums next; can be <OR>'d together to from any combo of levels
    VBM_EQ1 = 0x00000100,
    VBM_EQ2 = 0x00000200,
    VBM_EQ3 = 0x00000400,
    VBM_EQ4 = 0x00000800,
    VBM_EQ5 = 0x00001000,    
    VBM_EQ6 = 0x00002000,
    VBM_EQ7 = 0x00004000,
    VBM_EQ8 = 0x00008000
};

extern uint32_t g_VBMask;

class LogStreamBuf : public streambuf
{
public:
    // ctor
    LogStreamBuf () :
      cv_buf(0), cv_buflen(256), cv_verbosity(INMSG), cv_criticalError(false)
    {
        // Create the buffer
        cv_buf = new char_type[cv_buflen];
        setp(cv_buf, cv_buf + cv_buflen);
    }

    bool openLogFile(const char* logpath)
    {
        cv_logFile.open(logpath, ios::out);
        if (! cv_logFile)
            return false;
        else
            return true;
    }

    // Free the buffer
    ~LogStreamBuf ()
    {
        delete[] cv_buf;
#ifdef FILEDBG
        cv_logFile.close();        
#endif
    }

    // Set the verbosity to be used on the next call to sync()
    void set_verbosity (Verbosity v)
    {
        cv_verbosity = v;
    }
    
    // Check for critical error
    bool isCriticalError() {return cv_criticalError;}

private:
    int sync ()
    {
        cv_criticalError = cv_criticalError || (cv_verbosity == ERMSG);
        
        if ((0x00000080 << cv_verbosity) & g_VBMask)
        {
            char msgType[] = " EI...";
          
            // wfdbg - change next 3 stmts from cerr to cout
            cout << "IfScrub" << cv_verbosity << '.' << *(msgType+cv_verbosity) << "> ";
          
            cout.write(pbase(), pptr() - pbase());
          
            cout.flush();
          
#ifdef FILEDBG
            // Skip "IfScrub" prefix -- redundant when logging to file
            cv_logFile << cv_verbosity << '.' << *(msgType+cv_verbosity) << "> ";

            cv_logFile.write(pbase(), pptr() - pbase());

            // Flush output
            cv_logFile.flush();
#endif
        }
    
        // Reset the buffer
        setp(pbase(), epptr());
        return 0;
    }

    // Out of space, so grow the buffer
    int overflow (int c)
    {
        // Allocate more space, copy existing data into it, and swap
        // it with old buffer
        char_type * tempBuf = new char_type[cv_buflen + 256];
        memcpy(tempBuf, cv_buf, cv_buflen);
        delete[] cv_buf;
        cv_buf = tempBuf;

        // Lastly, put c into buffer
        sputc(c);
        return 0;
    }

    // The buffer
    char_type* cv_buf;
    
    // The buffer length
    size_t cv_buflen;

    // Current verbosity
    Verbosity cv_verbosity;

    // The log file
    ofstream cv_logFile;
    
    // Sticky error flag
    bool cv_criticalError;
};


class LogItStream : public ostream
{
public:
    // ctor
    LogItStream () :
        ostream(&cv_buf), cv_buf() {}
    
    // Open the log file
    bool openTheLog(const char* logfile)
    {
        return cv_buf.openLogFile(logfile);
    }

    // set verbosity
    void set_verbosity (Verbosity v)
    {
        cv_buf.set_verbosity(v);
    }
    
    // Check for critical error
    bool isCriticalError() {return cv_buf.isCriticalError();}

private:
    // The LogStreamBuf object
    LogStreamBuf cv_buf;
};

// Set the verbosity for a LogItStream/LogStreamBuf
// This needs to be a global function rather than a member to avoid C++'s type
// resolution of overloaded functions.
LogItStream& operator<< (LogItStream& ls, Verbosity v);



#endif  // IFSCRUBBASE_H
