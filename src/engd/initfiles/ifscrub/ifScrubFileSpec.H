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



#ifndef IFSCRUBFILESPEC_H
#define IFSCRUBFILESPEC_H

// Change Log *********************************************************
//
//  Flag  def/feat  Userid    Date      Description
//  ----  --------  --------  --------  --------------------------------
//   @01  F858677   dpeterso  10/17/12  P8 updates - adding IPLMODE
// End Change Log *****************************************************

#include <ifScrubBase.H>

class EngdConfigFile : public EngdBaseFile
{
    public:
        EngdConfigFile() : EngdBaseFile() {}
        ~EngdConfigFile() {}
        bool locateFragment();
        void digestData();
};

class EngdInitFile : public EngdBaseFile
{
    public:
        EngdInitFile() : EngdBaseFile(), cv_filePosA(ios::beg), cv_filePosB(ios::beg)
        {}
        ~EngdInitFile() {}
        bool locateFragment();
        void digestData();
        bool getOutPending() {return cv_outputPending;}
        void setOutPending(bool newValue) {cv_outputPending = newValue;}
        bool matchConditionAndEc(const string & i_conditionStr, const uint32_t i_ecValue, const string & i_iplmodeStr, bool* isFatalErr); // @01c
        void writeReducedIF(char i_stopChar = '?');
        void saveFragStart() {cv_savePos = cv_filePosB;}
        streampos getFragStart() {return cv_savePos;}
        void advanceFilePos() {cv_filePosA = cv_filePosB = cv_inStream.tellg();}
        ifstream & streamRef() {return cv_inStream;}
    private:
        streampos cv_filePosA;
        streampos cv_filePosB;
        streampos cv_savePos;
        bool      cv_outputPending;
};

class EngdSpydefFile : public EngdBaseFile
{
    public:
        EngdSpydefFile() : EngdBaseFile() {}
        ~EngdSpydefFile() {}
        bool locateFragment();
        void digestData();
};

class EngdScandefFile : public EngdBaseFile
{
    public:
        EngdScandefFile() : EngdBaseFile() {}
        ~EngdScandefFile() {}
        bool locateFragment();
        void digestData();
};

#endif  // IFSCRUBFILESPEC_H
