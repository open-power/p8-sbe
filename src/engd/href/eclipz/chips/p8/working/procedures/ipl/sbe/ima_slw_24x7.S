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



//PORE "24x7" IMA firmware code to configure the chip pmulets to count:
//
//
//
//output format
//
//Time-of-Day (SCOM) [ 8 bytes ]
//Update Count  [ 8 bytes ]
//Accumulated Measurement Period [ 8 bytes ]
//Accumulated pmulet-0 event-0 [ 8 bytes ]
//Accumulated pmulet-0 event-1 [ 8 bytes ]
//Accumulated pmulet-0 event-2 [ 8 bytes ]
//Accumulated pmulet-0 event-3 [ 8 bytes ]
//Last Update Period [ 8 bytes ]
//Last pmulet-0 event-0 increment [ 8 bytes ]
//Last pmulet-0 event-1 increment [ 8 bytes ]
//Last pmulet-0 event-2 increment [ 8 bytes ]
//Last pmulet-0 event-3 increment [ 8 bytes ]
//Time-of-day (picket) [ 8 bytes ]
//3 x 8 bytesunused after TOD (Picket) for making 16 bytes or 1 cache line size	
//
//IMA Groups and events with posting locations
//
//0x320000,TOD
//0x320008,Update Count 0 
//0x320010,Measuring period 0 ACC
//0x320018,PM_PB_CYC ACC
//0x320020,PM_MCD_CHECK_RTY_DINC ACC
//0x320028,PM_PB_INT_DATA_XFER ACC
//0x320030,PM_PB_EXT_DATA_XFER ACC
//0x320038,Measuring period 0
//0x320040,PM_PB_CYC 
//0x320048,PM_MCD_CHECK_RTY_DINC 
//0x320050,PM_PB_INT_DATA_XFER 
//0x320058,PM_PB_EXT_DATA_XFER 
//0x320060,TOD
//0x320080,TOD
//0x320088,Update Count 1 
//0x320090,Measuring period 1 ACC
//0x320098,PM_PB_SYS_PUMP ACC
//0x3200A0,PM_PB_NODE_PUMP ACC
//0x3200A8,PM_PB_SYS_PUMP_RTY ACC
//0x3200B0,PM_PB_NODE_PUMP_RTY ACC
//0x3200B8,Measuring period 1
//0x3200C0,PM_PB_SYS_PUMP 
//0x3200C8,PM_PB_NODE_PUMP
//0x3200D0,PM_PB_SYS_PUMP_RTY 
//0x3200D8,PM_PB_NODE_PUMP_RTY 
//0x3200E0,TOD
//0x320100,TOD
//0x320108,Update Count 2 
//0x320110,Measuring period 2 ACC
//0x320118,PM_MCS_UP_128B_DATA_XFER_MC0 ACC
//0x320120,PM_MCS_UP_128B_DATA_XFER_MC1 ACC
//0x320128,PM_MCS_UP_128B_DATA_XFER_MC2 ACC
//0x320130,PM_MCS_UP_128B_DATA_XFER_MC3 ACC
//0x320138,Measuring period 2
//0x320140,PM_MCS_UP_128B_DATA_XFER_MC0 
//0x320148,PM_MCS_UP_128B_DATA_XFER_MC1 
//0x320150,PM_MCS_UP_128B_DATA_XFER_MC2
//0x320158,PM_MCS_UP_128B_DATA_XFER_MC3
//0x320160,TOD
//0x320180,TOD
//0x320188,Update Count 2 
//0x320190,Measuring period 2 ACC
//0x320198,PM_MCS_DOWN_128B_DATA_XFER_MC0 ACC
//0x3201A0,PM_MCS_DOWN_128B_DATA_XFER_MC1 ACC
//0x3201A8,PM_MCS_DOWN_128B_DATA_XFER_MC2 ACC
//0x3201B0,PM_MCS_DOWN_128B_DATA_XFER_MC3 ACC
//0x3201B8,Measuring period 2
//0x3201C0,PM_MCS_DOWN_128B_DATA_XFER_MC0 
//0x3201C8,PM_MCS_DOWN_128B_DATA_XFER_MC1 
//0x3201D0,PM_MCS_DOWN_128B_DATA_XFER_MC2
//0x3201D8,PM_MCS_DOWN_128B_DATA_XFER_MC3
//0x3201E0,TOD
//0x320200,TOD
//0x320208,Update Count 4 
//0x320210,Measuring period 4 ACC
//0x320218,PM_XLINK0_IN_DATA_CYC ACC
//0x320220,PM_XLINK1_IN_DATA_CYC ACC
//0x320228,PM_XLINK3_IN_DATA_CYC ACC
//0x320230,PM_XLINK_CYCLES ACC
//0x320238,Measuring period 4
//0x320240,PM_XLINK0_IN_DATA_CYC
//0x320248,PM_XLINK1_IN_DATA_CYC
//0x320250,PM_XLINK3_IN_DATA_CYC
//0x320258,PM_XLINK_CYCLES
//0x320260,TOD
//0x320280,TOD
//0x320288,Update Count 5 
//0x320290,Measuring period 5 ACC
//0x320298,PM_XLINK0_IN_IDL_CYC ACC
//0x3202A0,PM_XLINK1_IN_IDL_CYC ACC
//0x3202A8,PM_XLINK3_IN_IDL_CYC ACC
//0x3202B0,
//0x3202B8,Measuring period 5
//0x3202C0,PM_XLINK0_IN_IDL_CYC
//0x3202C8,PM_XLINK1_IN_IDL_CYC
//0x3202D0,PM_XLINK3_IN_IDL__CYC
//0x3202D8,PM_XLINK_CYCLES
//0x3202E0,TOD
//0x320300,TOD
//0x320308,Update Count 6 
//0x320310,Measuring period 6 ACC
//0x320318,PM_ALINK0_IN_DATA_CYC ACC
//0x320320,PM_ALINK1_IN_DATA_CYC ACC
//0x320328,PM_ALINK2_IN_DATA_CYC ACC
//0x320330,PM_ALINK_CYCLES ACC
//0x320338,Measuring period 6 
//0x320340,PM_ALINK0_IN_DATA_CYC
//0x320348,PM_ALINK1_IN_DATA_CYC
//0x320350,PM_ALINK2_IN_DATA_CYC
//0x320358,PM_ALINK_CYCLES
//0x320360,TOD
//0x320380,TOD
//0x320388,Update Count 7 
//0x320390,Measuring period 7 ACC
//0x320398,PM_ALINK0_IN_IDL_CYC ACC
//0x3203A0,PM_ALINK1_IN_IDL_CYC ACC
//0x3203A8,PM_ALINK2_IN_IDL_CYC ACC
//0x3203B0,PM_ALINK_CYCLES ACC
//0x3203B8,Measuring period 7
//0x3203C0,PM_ALINK0_IN_IDL_CYC
//0x3203C8,PM_ALINK1_IN_IDL_CYC
//0x3203D0,PM_ALINK2_IN_IDL_CYC
//0x3203D8,PM_ALINK_CYCLES
//0x3203E0,TOD
//0x320400,TOD
//0x320408,Update Count 8 
//0x320410,Measuring period 8 ACC
//0x320418,PM_PHB_ANY_DMA_RCV_PHB0 ACC
//0x320420,PM_PHB_CYC_CNT_PHB0 ACC
//0x320428,PM_PHB_ANY_TCE_MISS_PHB0 ACC
//0x320430,PM_PHB_MSI_INTR_PHB0 ACC
//0x320438,Measuring period 8 
//0x320440,PM_PHB_ANY_DMA_RCV_PHB0
//0x320448,PM_PHB_CYC_CNT_PHB0
//0x320450,PM_PHB_ANY_TCE_MISS_PHB0
//0x320458,PM_PHB_MSI_INTR_PHB0
//0x320460,TOD
//0x320480,TOD
//0x320488,Update Count 9 
//0x320490,Measuring period 9 ACC
//0x320498,PM_PHB_ANY_DMA_RCV_PHB1 ACC
//0x3204A0,PM_PHB_CYC_CNT_PHB1 ACC
//0x3204A8,PM_PHB_ANY_TCE_MISS_PHB1 ACC
//0x3204B0,PM_PHB_MSI_INTR_PHB1 ACC
//0x3204B8,Measuring period 9
//0x3204C0,PM_PHB_ANY_DMA_RCV_PHB1
//0x3204C8,PM_PHB_CYC_CNT_PHB1 
//0x3204D0,PM_PHB_ANY_TCE_MISS_PHB1
//0x3204D8,PM_PHB_MSI_INTR_PHB1
//0x3204E0,TOD
//0x320500,TOD
//0x320508,Update Count 10 
//0x320510,Measuring period 10 ACC
//0x320518,PM_PHB_ANY_DMA_RCV_PHB2 ACC
//0x320520,PM_PHB_CYC_CNT_PHB2 ACC
//0x320528,PM_PHB_ANY_TCE_MISS_PHB2 ACC
//0x320530,PM_PHB_MSI_INTR_PHB2 ACC
//0x320538,Measuring period 10
//0x320540,PM_PHB_ANY_DMA_RCV_PHB2
//0x320548,PM_PHB_CYC_CNT_PHB2
//0x320550,PM_PHB_ANY_TCE_MISS_PHB2
//0x320558,PM_PHB_MSI_INTR_PHB2
//0x320560,TOD
//
//
.nolist

// #include "pgas.h"
#include "p8_sbe.H"
// #include "p8_slw.H"
// #include "proc_slw.H"
// #include "common_ecids.H"

#include "p8_homer_map.h" 

#include <pts.h> 
	.list
	.oci

.ptsGlobalFunction ima_24x7_reset
.ptsGlobalFunction ima_24x7_pibErrorHandle 

//------------------------------------------------------------------------------
// Number of 8 byte posting locations used. Used for initialization.
//
.set NUM_8_BYTE_POSTS_USED, 200
//
// From  "p8_homer_map.h"
//
//.set posting_start,  HOMER_SLW_24X7_COUNTER_OFFSET_ADDR
//.set scratch_start,  HOMER_SLW_24X7_SCRATCH_OFFSET_ADDR
.set posting_start,  0x00320000
.set scratch_start,  0x00350000
.set DEBUG_SCOM_SCRATCH,  0x00360000
//
//error handling related fields
//
// chiplet addresses for error handling
CONST_UINT64_T( PMU_PB_0X02010Cxx       , ULL(0X02010C00) );
CONST_UINT64_T( PMU_MC0_0x020118xx      , ULL(0x02011800) );
CONST_UINT64_T( PMU_MC1_0x020119xx      , ULL(0x02011900) );
CONST_UINT64_T( PMU_MC2_0x02011cxx      , ULL(0x02011c00) );
CONST_UINT64_T( PMU_MC3_0x02011dxx      , ULL(0x02011d00) );
CONST_UINT64_T( PMU_X_0x04010cxx        , ULL(0x04010c00) );
CONST_UINT64_T( PMU_A_0x080108xx        , ULL(0x08010800) );
CONST_UINT64_T( PMU_PHB0_0x090120xx     , ULL(0x09012000) );
CONST_UINT64_T( PMU_PHB1_0x090124xx     , ULL(0x09012400) );
CONST_UINT64_T( PMU_PHB2_0x090128xx     , ULL(0x09012800) );
CONST_UINT64_T( PMU_MCD_0x020134xx     	, ULL(0x02013400) );
//
//Masks for marking bad units
.set BAD_PB, 0x1
.set BAD_MC0, 0x2
.set BAD_MC1, 0x4
.set BAD_MC2, 0x8
.set BAD_MC3, 0x10
.set BAD_X, 0x20
.set BAD_A, 0x40
.set BAD_PHB0, 0x80
.set BAD_PHB1, 0x100
.set BAD_PHB2, 0x200
.set BAD_MCD, 0x400
//
//address to store unit_validity_tracker
.set unit_validity_tracker, 0x0039FC20
.set DEBUG_SCOM_PB, 0x0039FC28
.set DEBUG_SCOM_MC0, 0x0039FC30
.set DEBUG_SCOM_MC1, 0x0039FC38
.set DEBUG_SCOM_MC2, 0x0039FC40
.set DEBUG_SCOM_MC3, 0x0039FC48
.set DEBUG_SCOM_X, 0x0039FC50
.set DEBUG_SCOM_A, 0x0039FC58
.set DEBUG_SCOM_PHB0, 0x0039FC60
.set DEBUG_SCOM_PHB1, 0x0039FC68
.set DEBUG_SCOM_PHB2, 0x0039FC70
.set DEBUG_SCOM_MCD, 0x0039FC78
// masks and shifts for counter extraction from pmulet
//
.set mask_start, 0
.set mask_end, 15
.set count0_shift, 0
.set count1_shift, 16
.set count2_shift, 32
.set count3_shift, 48
//
.set chip_TOD, 0x0
.set cnpm_p0, 0x8
.set cnpm_p1, 0x10
.set cnpm_p2, 0x18
.set cnpm_p3, 0x20
.set cnpm_p0_c0, 0x28
.set cnpm_p0_c1, 0x30
.set cnpm_p0_c2, 0x38
.set cnpm_p0_c3, 0x40
.set cnpm_p1_c0, 0x48
.set cnpm_p1_c1, 0x50
.set cnpm_p1_c2, 0x58
.set cnpm_p1_c3, 0x60
.set cnpm_p2_c0, 0x68
.set cnpm_p2_c1, 0x70
.set cnpm_p2_c2, 0x78
.set cnpm_p2_c3, 0x80
.set cnpm_p3_c0, 0x88
.set cnpm_p3_c1, 0x90
.set cnpm_p3_c2, 0x98
.set cnpm_p3_c3, 0xA0
//
.set xlink_p0, 0xA8
.set xlink_p1, 0xB0
.set xlink_p0_c0, 0xB8
.set xlink_p0_c1, 0xC0
.set xlink_p0_c2, 0xC8
.set xlink_p0_c3, 0xD0
.set xlink_p1_c0, 0xD8
.set xlink_p1_c1, 0xE0
.set xlink_p1_c2, 0xE8
.set xlink_p1_c3, 0xF0
//
.set alink_p0, 0xF8
.set alink_p1, 0x100
.set alink_p0_c0, 0x108
.set alink_p0_c1, 0x110
.set alink_p0_c2, 0x118
.set alink_p0_c3, 0x120
.set alink_p1_c0, 0x128
.set alink_p1_c1, 0x130
.set alink_p1_c2, 0x138
.set alink_p1_c3, 0x140
//
.set phb0_c0, 0x148
.set phb0_c1, 0x150
.set phb0_c2, 0x158
.set phb0_c3, 0x160
//
.set phb1_c0, 0x168
.set phb1_c1, 0x170
.set phb1_c2, 0x178
.set phb1_c3, 0x180
//
.set phb2_c0, 0x188
.set phb2_c1, 0x190
.set phb2_c2, 0x198
.set phb2_c3, 0x1A0
//
//friendly names for grp fields
//
.set g0_0, GRP0_0_TOD
.set g0_1, GRP0_1_UPDATE_COUNT
.set g0_2, GRP0_2_MEAS_PRD_ACC
.set g0_3, GRP0_3_PM_PB_CYC_ACC
.set g0_4, GRP0_4_PM_MCD_CHECK_RTY_DINC_ACC
.set g0_5, GRP0_5_PM_PB_INT_DATA_XFER_ACC
.set g0_6, GRP0_6_PM_PB_EXT_DATA_XFER_ACC
.set g0_7, GRP0_7_MEAS_PRD
.set g0_8, GRP0_8_PM_PB_CYC
.set g0_9, GRP0_9_PM_MCD_CHECK_RTY_DINC
.set g0_10, GRP0_10_PM_PB_INT_DATA_XFER
.set g0_11, GRP0_11_PM_PB_EXT_DATA_XFER
.set g0_12, GRP0_12_TOD
//   
.set g1_0, GRP1_0_TOD
.set g1_1, GRP1_1_UPDATE_COUNT
.set g1_2, GRP1_2_MEAS_PRD_ACC
.set g1_3, GRP1_3_PM_PB_SYS_PUMP_ACC
.set g1_4, GRP1_4_PM_PB_NODE_PUMP_ACC
.set g1_5, GRP1_5_PM_PB_SYS_PUMP_RTY_ACC
.set g1_6, GRP1_6_PM_PB_NODE_PUMP_RTY_ACC
.set g1_7, GRP1_7_MEAS_PRD
.set g1_8, GRP1_8_PM_PB_SYS_PUMP
.set g1_9, GRP1_9_PM_PB_NODE_PUMP
.set g1_10, GRP1_10_PM_PB_SYS_PUMP_RTY
.set g1_11, GRP1_11_PM_PB_NODE_PUMP_RTY
.set g1_12, GRP1_12_TOD
//   
.set g2_0, GRP2_0_TOD
.set g2_1, GRP2_1_UPDATE_COUNT
.set g2_2, GRP2_2_MEAS_PRD_ACC
.set g2_3, GRP2_3_PM_MCS_UP_128B_DATA_XFER_MC0_ACC
.set g2_4, GRP2_4_PM_MCS_UP_128B_DATA_XFER_MC1_ACC
.set g2_5, GRP2_5_PM_MCS_UP_128B_DATA_XFER_MC2_ACC
.set g2_6, GRP2_6_PM_MCS_UP_128B_DATA_XFER_MC3_ACC
.set g2_7, GRP2_7_MEAS_PRD
.set g2_8, GRP2_8_PM_MCS_UP_128B_DATA_XFER_MC0
.set g2_9, GRP2_9_PM_MCS_UP_128B_DATA_XFER_MC1
.set g2_10, GRP2_10_PM_MCS_UP_128B_DATA_XFER_MC2
.set g2_11, GRP2_11_PM_MCS_UP_128B_DATA_XFER_MC3
.set g2_12, GRP2_12_TOD
//   
.set g3_0, GRP3_0_TOD
.set g3_1, GRP3_1_UPDATE_COUNT
.set g3_2, GRP3_2_MEAS_PRD_ACC
.set g3_3, GRP3_3_PM_MCS_DOWN_128B_DATA_XFER_MC0_ACC
.set g3_4, GRP3_4_PM_MCS_DOWN_128B_DATA_XFER_MC1_ACC
.set g3_5, GRP3_5_PM_MCS_DOWN_128B_DATA_XFER_MC2_ACC
.set g3_6, GRP3_6_PM_MCS_DOWN_128B_DATA_XFER_MC3_ACC
.set g3_7, GRP3_7_MEAS_PRD
.set g3_8, GRP3_8_PM_MCS_DOWN_128B_DATA_XFER_MC0
.set g3_9, GRP3_9_PM_MCS_DOWN_128B_DATA_XFER_MC1
.set g3_10, GRP3_10_PM_MCS_DOWN_128B_DATA_XFER_MC2
.set g3_11, GRP3_11_PM_MCS_DOWN_128B_DATA_XFER_MC3
.set g3_12, GRP3_12_TOD
//   
.set g4_0, GRP4_0_TOD
.set g4_1, GRP4_1_UPDATE_COUNT
.set g4_2, GRP4_2_MEAS_PRD_ACC
.set g4_3, GRP4_3_PM_XLINK0_IN_DATA_CYC_ACC
.set g4_4, GRP4_4_PM_XLINK1_IN_DATA_CYC_ACC
.set g4_5, GRP4_5_PM_XLINK3_IN_DATA_CYC_ACC
.set g4_6, GRP4_6_PM_XLINK_CYCLES_ACC
.set g4_7, GRP4_7_MEAS_PRD
.set g4_8, GRP4_8_PM_XLINK0_IN_DATA_CYC
.set g4_9, GRP4_9_PM_XLINK1_IN_DATA_CYC
.set g4_10, GRP4_10_PM_XLINK3_IN_DATA_CYC
.set g4_11, GRP4_11_PM_XLINK_CYCLES
.set g4_12, GRP4_12_TOD
//   
.set g5_0, GRP5_0_TOD
.set g5_1, GRP5_1_UPDATE_COUNT
.set g5_2, GRP5_2_MEAS_PRD_ACC
.set g5_3, GRP5_3_PM_XLINK0_IN_IDL_CYC_ACC
.set g5_4, GRP5_4_PM_XLINK1_IN_IDL_CYC_ACC
.set g5_5, GRP5_5_PM_XLINK3_IN_IDL_CYC_ACC
.set g5_6, GRP5_6_PM_XLINK_CYCLES_ACC
.set g5_7, GRP5_7_MEAS_PRD
.set g5_8, GRP5_8_PM_XLINK0_IN_IDL_CYC
.set g5_9, GRP5_9_PM_XLINK1_IN_IDL_CYC
.set g5_10, GRP5_10_PM_XLINK3_IN_IDL__CYC
.set g5_11, GRP5_11_PM_XLINK_CYCLES
.set g5_12, GRP5_12_TOD
//   
.set g6_0, GRP6_0_TOD
.set g6_1, GRP6_1_UPDATE_COUNT
.set g6_2, GRP6_2_MEAS_PRD_ACC
.set g6_3, GRP6_3_PM_ALINK0_IN_DATA_CYC_ACC
.set g6_4, GRP6_4_PM_ALINK1_IN_DATA_CYC_ACC
.set g6_5, GRP6_5_PM_ALINK2_IN_DATA_CYC_ACC
.set g6_6, GRP6_6_PM_ALINK_CYCLES_ACC
.set g6_7, GRP6_7_MEAS_PRD
.set g6_8, GRP6_8_PM_ALINK0_IN_DATA_CYC
.set g6_9, GRP6_9_PM_ALINK1_IN_DATA_CYC
.set g6_10, GRP6_10_PM_ALINK2_IN_DATA_CYC
.set g6_11, GRP6_11_PM_ALINK_CYCLES
.set g6_12, GRP6_12_TOD
//   
.set g7_0, GRP7_0_TOD
.set g7_1, GRP7_1_UPDATE_COUNT
.set g7_2, GRP7_2_MEAS_PRD_ACC
.set g7_3, GRP7_3_PM_ALINK0_IN_IDL_CYC_ACC
.set g7_4, GRP7_4_PM_ALINK1_IN_IDL_CYC_ACC
.set g7_5, GRP7_5_PM_ALINK2_IN_IDL_CYC_ACC
.set g7_6, GRP7_6_PM_ALINK_CYCLES_ACC
.set g7_7, GRP7_7_MEAS_PRD
.set g7_8, GRP7_8_PM_ALINK0_IN_IDL_CYC
.set g7_9, GRP7_9_PM_ALINK1_IN_IDL_CYC
.set g7_10, GRP7_10_PM_ALINK2_IN_IDL_CYC
.set g7_11, GRP7_11_PM_ALINK_CYCLES
.set g7_12, GRP7_12_TOD
//   
.set g8_0, GRP8_0_TOD
.set g8_1, GRP8_1_UPDATE_COUNT
.set g8_2, GRP8_2_MEAS_PRD_ACC
.set g8_3, GRP8_3_PM_PHB_ANY_DMA_RCV_PHB0_ACC
.set g8_4, GRP8_4_PM_PHB_CYC_CNT_PHB0_ACC
.set g8_5, GRP8_5_PM_PHB_ANY_TCE_MISS_PHB0_ACC
.set g8_6, GRP8_6_PM_PHB_MSI_INTR_PHB0_ACC
.set g8_7, GRP8_7_MEAS_PRD
.set g8_8, GRP8_8_PM_PHB_ANY_DMA_RCV_PHB0
.set g8_9, GRP8_9_PM_PHB_CYC_CNT_PHB0
.set g8_10, GRP8_10_PM_PHB_ANY_TCE_MISS_PHB0
.set g8_11, GRP8_11_PM_PHB_MSI_INTR_PHB0
.set g8_12, GRP8_12_TOD
//   
.set g9_0, GRP9_0_TOD
.set g9_1, GRP9_1_UPDATE_COUNT
.set g9_2, GRP9_2_MEAS_PRD_ACC
.set g9_3, GRP9_3_PM_PHB_ANY_DMA_RCV_PHB1_ACC
.set g9_4, GRP9_4_PM_PHB_CYC_CNT_PHB1_ACC
.set g9_5, GRP9_5_PM_PHB_ANY_TCE_MISS_PHB1_ACC
.set g9_6, GRP9_6_PM_PHB_MSI_INTR_PHB1_ACC
.set g9_7, GRP9_7_MEAS_PRD
.set g9_8, GRP9_8_PM_PHB_ANY_DMA_RCV_PHB1
.set g9_9, GRP9_9_PM_PHB_CYC_CNT_PHB1
.set g9_10, GRP9_10_PM_PHB_ANY_TCE_MISS_PHB1
.set g9_11, GRP9_11_PM_PHB_MSI_INTR_PHB1
.set g9_12, GRP9_12_TOD
//   
.set g10_0, GRP10_0_TOD
.set g10_1, GRP10_1_UPDATE_COUNT
.set g10_2, GRP10_2_MEAS_PRD0_ACC
.set g10_3, GRP10_3_PM_PHB_ANY_DMA_RCV_PHB2_ACC
.set g10_4, GRP10_4_PM_PHB_CYC_CNT_PHB2_ACC
.set g10_5, GRP10_5_PM_PHB_ANY_TCE_MISS_PHB2_ACC
.set g10_6, GRP10_6_PM_PHB_MSI_INTR_PHB2_ACC
.set g10_7, GRP10_7_MEAS_PRD0
.set g10_8, GRP10_8_PM_PHB_ANY_DMA_RCV_PHB2
.set g10_9, GRP10_9_PM_PHB_CYC_CNT_PHB2
.set g10_10, GRP10_10_PM_PHB_ANY_TCE_MISS_PHB2
.set g10_11, GRP10_11_PM_PHB_MSI_INTR_PHB2
.set g10_12, GRP10_12_TOD
//

        // Error codes

        UNHANDLED_SCOM_ERROR = 1
        ILLEGAL_COMMAND      = 2

.set cb_base, 0x0039FC00
.set cb_0, 0x0
.set cb_1, 0x8
.set cb_2, 0x10
//------------------------------------------------------------------------------
//
.macro clear_posting
la      A0, posting_start
ls	CTR, NUM_8_BYTE_POSTS_USED
123:	sti	0x0, A0, ZEROS
	adds	A0, A0, 0x8
	loop 123b
.endm
//
.macro update_cb_status
//check the command
        la	A0, cb_base
        ld	D0, cb_1 , A0
        // Mainline Commands
        cmpibraeq D0, eval_state,          0x0
        cmpibraeq D0, loop_resume,         0x1
        cmpibraeq D0, loop_pause,          0x2
        cmpibraeq D0, loop_clear,          0x3
        // ?? Where is command 4 ??
        // Error injection into the 24x7 thread
        cmpibraeq D0, bad_instruction,     0x5
        cmpibraeq D0, bad_scom,            0x6
        cmpibraeq D0, bad_oci,             0x7
        cmpibraeq D0, double_fault,        0x8  
        // Error injection into the PTS scheduler   
        cmpibraeq D0, pts_bad_instruction, 0x9
        cmpibraeq D0, pts_bad_scom,        0xa
        cmpibraeq D0, pts_bad_oci,         0xb
        cmpibraeq D0, pts_double_fault,    0xc     
        // Special operations
        cmpibraeq D0, clear_latency_stats, 0xd
        
        ptsTerminate rc=ILLEGAL_COMMAND
//
//change the state to paused and clear command
loop_pause:
        la	A0, cb_base
	sti cb_0, A0, 0x2
	sti cb_1, A0, 0x0
	bra eval_state
//
//resume paused collection
loop_resume:
        la	A0, cb_base
	sti cb_0, A0, 0x1
	sti cb_1, A0, 0x0
	bra eval_state
//
loop_clear:
//change state to initializing
	//sti cb_0, A0, 0x0
//clear postings
	clear_posting
//clear counters by reading the pmulets
	get_pmulets_cnpm
	get_pmulets_xlink
	get_pmulets_alink
	//get_pmulets_PHB
        la	A0, cb_base
	sti cb_1, A0, 0x0
	bra eval_state
//
//evaluate current state 
//and modify loop behaviour
//
eval_state:
//load current state
	la	A0, cb_base
        ld	D0, cb_0 , A0
//check if current state is "paused = 0x2"
	cmpibraeq D0, paused,           0x2
//check if state is initializing
	cmpibraeq D0, initializing,     0x0
//check if state is running
	cmpibraeq D0, running,     	0x1
paused:
//branch to the end of the program (delay according to speed setting)
	la A0, posting_start
	bra loop_end
//
initializing:
//change status to running = 0x1
	sti cb_0, A0, 0x1
//
running:
	la A0, posting_start
.endm
//

        // Error injection into the 24x7 thread. Each test has a final
        // branch-to-self to catch cases where the errors are not detected
        // (which should not happen). 

bad_instruction:
        .long   0               # 0 is an illegal instruction
        bra     .

bad_scom:
        ls      P0, 0
        ld      D0, 0, P0       # getscom 0x0, illegal
        bra     .

bad_oci:
        la      A0, 0xfff00000  # Illegal OCI address in SRAM space
        ld      D0, 0, A0
        bra     .

double_fault:
        li      D0, 0x00008000fff00000
        la      A0, 0x40040040  # SLW Table Base Address
        std     D0, 0, A0       # Branch table base is now illegal
        mr      A0, D0
        ld      D0, 0, A0       # OCI error to illegal branch table
        bra     .

        // Errors can also be injected into PTS by writing the command field
        // of the state. These errors will get picked up on the next system
        // call. Note that the command is defined as a left-justified byte.

pts_bad_instruction:
        ls      D0, PTS_INJECT_INSTRUCTION_ERROR
        bra     1f
pts_bad_scom:
        ls      D0, PTS_INJECT_SCOM_ERROR
        bra     1f
pts_bad_oci:  
        ls      D0, PTS_INJECT_OCI_ERROR
        bra     1f
pts_double_fault:         
        ls      D0, PTS_INJECT_DOUBLE_FAULT
        bra     1f
1:
        la      A0, G_pts_slwState
        sldi    D0, D0, 56
        std     D0, PTS_STATE_COMMAND, A0
        la      A0, cb_base
        bra     loop_resume

        // Special operation:Clear thread latency statistics
clear_latency_stats:
        
#if CONFIGURE_PTS_STATS

        mr      A0, SPRG0
        sti     PTS_THREAD_MAX_LATENCY, A0, 0
        la      A0, cb_base
        
#endif
        bra     loop_resume
        
.macro set_config_cnpm
//
//load the unit_validity_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//check if PB is marked bad in the Unit_validity_tracker
//and skip PB config in that case.
//
andi 	D0, D1, BAD_PB
cmpibraeq D0, skip_PB_conf, BAD_PB
//
//store the PB config values into corresponding SCOM addresses
//
lpcs	P0, PMU_CNPM_PB_PMU_0X02010C68
sti 	PMU_CNPM_PB_PMU_0X02010C68, P0, PMU_CNPM_PB_PMU_CONF
sti	PMU_CNPM_PB_SEL_0X02010C69, P0, PMU_CNPM_PB_SEL_CONF
//
skip_PB_conf:
	//set mc3 regs
	andi 	D0, D1, BAD_MC3
	cmpibraeq D0, skip_MC3_conf, BAD_MC3
	lpcs	P0, MC3_MCS1_MCMODE2_0X02011D89
	sti 	MC3_MCS1_MCMODE2_0X02011D89, P0, MC3_MCS1_MCMODE2_CONF 
	sti	MC3_MCS0_MCMODE2_0X02011D09, P0, MC3_MCS0_MCMODE2_CONF 
	sti	MC3_MCS1_MCEBUSEN_0X02011D1B, P0, MC3_MCS1_MCEBUSEN_CONF
	sti	MC3_MCS0_MCEBUSEN_0X02011D9B, P0, MC3_MCS0_MCEBUSEN_CONF
skip_MC3_conf:
	//Set mc2 regs
	andi 	D0, D1, BAD_MC2
	cmpibraeq D0, skip_MC2_conf, BAD_MC2
	lpcs	P0, MC2_MCS1_MCMODE2_0X02011C89
	sti	MC2_MCS1_MCMODE2_0X02011C89, P0, MC2_MCS1_MCMODE2_CONF 
	sti	MC2_MCS0_MCMODE2_0X02011C09, P0, MC2_MCS0_MCMODE2_CONF 
	sti	MC2_MCS1_MCEBUSEN_0X02011C1B, P0, MC2_MCS1_MCEBUSEN_CONF
	sti	MC2_MCS0_MCEBUSEN_0X02011C9B, P0, MC2_MCS0_MCEBUSEN_CONF
skip_MC2_conf:
	//Set mc1 regs
	andi 	D0, D1, BAD_MC1
	cmpibraeq D0, skip_MC1_conf, BAD_MC1
	lpcs	P0, MC1_MCS1_MCMODE2_0X02011989
	sti	MC1_MCS1_MCMODE2_0X02011989, P0, MC1_MCS1_MCMODE2_CONF 
	sti	MC1_MCS0_MCMODE2_0X02011909, P0, MC1_MCS0_MCMODE2_CONF 
	sti	MC1_MCS1_MCEBUSEN_0X0201191B, P0, MC1_MCS1_MCEBUSEN_CONF
	sti	MC1_MCS0_MCEBUSEN_0X0201199B, P0, MC1_MCS0_MCEBUSEN_CONF
skip_MC1_conf:
	//Set mc0 regs
	andi 	D0, D1, BAD_MC0
	cmpibraeq D0, skip_MC0_conf, BAD_MC0
	lpcs	P0, MC0_MCS1_MCMODE2_0X02011889
	sti	MC0_MCS1_MCMODE2_0X02011889, P0, MC0_MCS1_MCMODE2_CONF 
	sti	MC0_MCS0_MCMODE2_0X02011809, P0, MC0_MCS0_MCMODE2_CONF 
	sti	MC0_MCS1_MCEBUSEN_0X0201181B, P0, MC0_MCS1_MCEBUSEN_CONF
	sti	MC0_MCS0_MCEBUSEN_0X0201189B, P0, MC0_MCS0_MCEBUSEN_CONF
skip_MC0_conf:
	//set mcd Reg
	andi 	D0, D1, BAD_MCD
	cmpibraeq D0, skip_MCD_conf, BAD_MCD
	lpcs	P0, PMU_CNPM_MCD_SEL_0x02013416
	sti	PMU_CNPM_MCD_SEL_0x02013416, P0, PMU_CNPM_MCD_SEL_CONF 
skip_MCD_conf:
	la      A0, posting_start
.endm
//
.macro set_config_xlink
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//check if X is marked bad in the Unit_validity_tracker
//and skip X config in that case.
//
andi 	D0, D1, BAD_X
cmpibraeq D0, skip_XLINK_conf, BAD_X
lpcs	P0, PMU_XLINK_CTRL_0X04010C0F
sti     PMU_XLINK_CTRL_0X04010C0F, P0, PMU_XLINK_CTRL_CONF
skip_XLINK_conf:
	la      A0, posting_start
.endm
//
.macro set_config_alink
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//check if A is marked bad in the Unit_validity_tracker
//and skip A config in that case.
//
andi 	D0, D1, BAD_A
cmpibraeq D0, skip_ALINK_conf, BAD_A
lpcs	P0, PMU_ALINK_CTRL0_0X0801080F
sti	PMU_ALINK_CTRL0_0X0801080F, P0, PMU_ALINK_CTRL0_CONF
sti	PMU_ALINK_CTRL1_0X0801080E, P0, PMU_ALINK_CTRL1_CONF
skip_ALINK_conf:
	la      A0, posting_start
.endm
//
.macro set_config_phb
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//check if PHB0 is marked bad in the Unit_validity_tracker
//and skip PHB0 config in that case.
andi 	D0, D1, BAD_PHB0
cmpibraeq D0, skip_PHB0_conf, BAD_PHB0
//
lpcs	P0, PMU_PHB0_CTRL_0X09012010
sti	PMU_PHB0_CTRL_0X09012010, P0, PMU_PHB0_CTRL_CONF 
//	
skip_PHB0_conf:
	//
	//check if PHB1 is marked bad in the Unit_validity_tracker
	//and skip PHB1 config in that case.
	//
	andi 	D0, D1, BAD_PHB1
	cmpibraeq D0, skip_PHB1_conf, BAD_PHB1
	//
	lpcs	P0, PMU_PHB1_CTRL_0X09012410
	sti	PMU_PHB1_CTRL_0X09012410, P0, PMU_PHB1_CTRL_CONF 
	//	
skip_PHB1_conf:
	//
	//check if PHB2 is marked bad in the Unit_validity_tracker
	//and skip PHB2 config in that case.
	//
	andi 	D0, D1, BAD_PHB2
	cmpibraeq D0, skip_PHB2_conf, BAD_PHB2
	//
	lpcs	P0, PMU_PHB2_CTRL_0X09012810
	sti	PMU_PHB2_CTRL_0X09012810, P0, PMU_PHB2_CTRL_CONF
skip_PHB2_conf:
	la      A0, posting_start
.endm
//
.macro check_config_cnpm
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//
//check if PB is marked bad in the Unit_validity_tracker
//and skip PB config in that case.
//
andi 	D0, D1, BAD_PB
cmpibraeq D0, skip_PB_conf, BAD_PB
//
//check if PB is marked bad in the Unit_validity_tracker
//and skip PB config in that case.
//
andi 	D0, D1, BAD_PB
cmpibraeq D0, skip_PB_check, BAD_PB
//
//compare to see if configs are correct
//
lpcs	P0, PMU_CNPM_PB_PMU_0X02010C68
ld	D0, PMU_CNPM_PB_PMU_0X02010C68, P0 
cmpibrane D0, initialize, PMU_CNPM_PB_PMU_CONF
ld 	D0, PMU_CNPM_PB_SEL_0X02010C69, P0
cmpibrane D0, initialize, PMU_CNPM_PB_SEL_CONF
//
skip_PB_check:
//
	andi 	D0, D1, BAD_MC3
	cmpibraeq D0, skip_MC3_check, BAD_MC3
	lpcs	P0, MC3_MCS1_MCMODE2_0X02011D89
	ld 	D0, MC3_MCS1_MCMODE2_0X02011D89, P0 
	cmpibrane D0, initialize, MC3_MCS1_MCMODE2_CONF
	ld 	D0, MC3_MCS0_MCMODE2_0X02011D09, P0
	cmpibrane D0, initialize, MC3_MCS0_MCMODE2_CONF 
	ld 	D0, MC3_MCS1_MCEBUSEN_0X02011D1B, P0
	cmpibrane D0, initialize, MC3_MCS1_MCEBUSEN_CONF
	ld 	D0, MC3_MCS0_MCEBUSEN_0X02011D9B, P0
	cmpibrane D0, initialize, MC3_MCS0_MCEBUSEN_CONF
//
skip_MC3_check:
//
	andi 	D0, D1, BAD_MC2
	cmpibraeq D0, skip_MC2_check, BAD_MC2
	lpcs	P0, MC2_MCS1_MCMODE2_0X02011C89
	ld	 D0, MC2_MCS1_MCMODE2_0X02011C89, P0
	cmpibrane D0, initialize, MC2_MCS1_MCMODE2_CONF 
	ld 	D0, MC2_MCS0_MCMODE2_0X02011C09, P0
	cmpibrane D0, initialize, MC2_MCS0_MCMODE2_CONF 
	ld 	D0, MC2_MCS1_MCEBUSEN_0X02011C1B, P0
	cmpibrane D0, initialize, MC2_MCS1_MCEBUSEN_CONF
	ld 	D0, MC2_MCS0_MCEBUSEN_0X02011C9B, P0
	cmpibrane D0, initialize, MC2_MCS0_MCEBUSEN_CONF
//
skip_MC2_check:
//	
	andi 	D0, D1, BAD_MC1
	cmpibraeq D0, skip_MC1_check, BAD_MC1
	lpcs	P0, MC1_MCS1_MCMODE2_0X02011989
	ld 	D0, MC1_MCS1_MCMODE2_0X02011989, P0
	cmpibrane D0, initialize, MC1_MCS1_MCMODE2_CONF 
	ld 	D0, MC1_MCS0_MCMODE2_0X02011909, P0
	cmpibrane D0, initialize, MC1_MCS0_MCMODE2_CONF 
	ld 	D0, MC1_MCS1_MCEBUSEN_0X0201191B, P0
	cmpibrane D0, initialize, MC1_MCS1_MCEBUSEN_CONF
	ld 	D0, MC1_MCS0_MCEBUSEN_0X0201199B, P0
	cmpibrane D0, initialize, MC1_MCS0_MCEBUSEN_CONF
//
skip_MC1_check:
//
	andi 	D0, D1, BAD_MC0
	cmpibraeq D0, skip_MC0_check, BAD_MC0
	lpcs	P0, MC0_MCS1_MCMODE2_0X02011889
	ld 	D0, MC0_MCS1_MCMODE2_0X02011889, P0
	cmpibrane D0, initialize, MC0_MCS1_MCMODE2_CONF 
	ld 	D0, MC0_MCS0_MCMODE2_0X02011809, P0
	cmpibrane D0, initialize, MC0_MCS0_MCMODE2_CONF 
	ld 	D0, MC0_MCS1_MCEBUSEN_0X0201181B, P0
	cmpibrane D0, initialize, MC0_MCS1_MCEBUSEN_CONF
	ld 	D0, MC0_MCS0_MCEBUSEN_0X0201189B, P0
	cmpibrane D0, initialize, MC0_MCS0_MCEBUSEN_CONF
//
skip_MC0_check:
//
	andi 	D0, D1, BAD_MCD
	cmpibraeq D0, skip_MCD_check, BAD_MCD
	lpcs	P0, PMU_CNPM_MCD_SEL_0x02013416
	ld 	D0, PMU_CNPM_MCD_SEL_0x02013416, P0
	cmpibrane D0, initialize, PMU_CNPM_MCD_SEL_CONF
//
skip_MCD_check:
	la      A0, posting_start
//
.endm
//
.macro check_config_xlink 
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
andi 	D0, D1, BAD_X
//
//check if X is marked bad in the Unit_validity_tracker
//and skip X config in that case.
//
cmpibraeq D0, skip_XLINK_check, BAD_X
lpcs	P0, PMU_XLINK_CTRL_0X04010C0F
ld 	D0, PMU_XLINK_CTRL_0X04010C0F, P0
cmpibrane D0, initialize, PMU_XLINK_CTRL_CONF
//
skip_XLINK_check:
	la      A0, posting_start
.endm
//
.macro check_config_alink 
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
andi 	D0, D1, BAD_A
//
//check if A is marked bad in the Unit_validity_tracker
//and skip A config in that case.
//
cmpibraeq D0, skip_ALINK_check, BAD_A
lpcs	P0, PMU_ALINK_CTRL0_0X0801080F
ld 	D0, PMU_ALINK_CTRL0_0X0801080F, P0
cmpibrane D0, initialize, PMU_ALINK_CTRL0_CONF
ld 	D0, PMU_ALINK_CTRL1_0X0801080E, P0
cmpibrane D0, initialize, PMU_ALINK_CTRL1_CONF
//
skip_ALINK_check:
	la      A0, posting_start
//
.endm
//
.macro  check_config_phb
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//check if PHB0 is marked bad in the Unit_validity_tracker
//and skip PHB0 config in that case.
//
andi 	D0, D1, BAD_PHB0
cmpibraeq D0, skip_PHB0_check, BAD_PHB0
lpcs	P0, PMU_PHB0_CTRL_0X09012010
ld 	D0, PMU_PHB0_CTRL_0X09012010, P0
cmpibrane D0, initialize, PMU_PHB0_CTRL_CONF	
//	
skip_PHB0_check:
	//
	//check if PHB1 is marked bad in the Unit_validity_tracker
	//and skip PHB1 config in that case.
	//
	andi 	D0, D1, BAD_PHB1
	cmpibraeq D0, skip_PHB1_check, BAD_PHB1
	// 
	ld 	D0, PMU_PHB1_CTRL_0X09012410, P0 
	cmpibrane D0, initialize, PMU_PHB1_CTRL_CONF
//
skip_PHB1_check:
	//
	//check if PHB2 is marked bad in the Unit_validity_tracker
	//and skip PHB2 config in that case.
	//
	andi 	D0, D1, BAD_PHB2
	cmpibraeq D0, skip_PHB2_check, BAD_PHB2
	//
	lpcs	P0, PMU_PHB2_CTRL_0X09012810
	ld 	D0, PMU_PHB2_CTRL_0X09012810, P0
	cmpibrane D0, initialize, PMU_PHB2_CTRL_CONF
skip_PHB2_check:
	la      A0, posting_start
//
.endm
//
.macro get_tod
lpcs	P1, TOD_VALUE_REG_00040020
ld	D0, TOD_VALUE_REG_00040020, P1
std	D0, chip_TOD, A1
.endm
//
.macro get_pmulets_cnpm
lpcs	P0, PMU_CNPM_CNT0_0X02010C54
ld	D0, PMU_CNPM_CNT0_0X02010C54, P0
std	D0, cnpm_p0, A1
ld	D0, PMU_CNPM_CNT1_0X02010C55, P0
std	D0, cnpm_p1, A1
ld	D0, PMU_CNPM_CNT2_0X02010C56, P0
std	D0, cnpm_p2, A1
ld	D0, PMU_CNPM_CNT3_0X02010C57, P0
std	D0, cnpm_p3, A1
.endm
//
.macro get_pmulets_xlink
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//check if X is marked bad in the Unit_validity_tracker
//and skip X config in that case.
//
andi 	D0, D1, BAD_X
cmpibraeq D0, 123f, BAD_X
//
lpcs	P0, PMU_XLINK_CNT0_0X04010C10
ld	D0, PMU_XLINK_CNT0_0X04010C10, P0
std	D0, xlink_p0, A1
ld	D0, PMU_XLINK_CNT1_0X04010C11, P0
std	D0, xlink_p1, A1
123:
	la      A0, posting_start	
.endm
//
.macro get_pmulets_alink
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//check if A is marked bad in the Unit_validity_tracker
//and skip A config in that case.
//
andi 	D0, D1, BAD_A
cmpibraeq D0, 123f, BAD_A
lpcs	P0, PMU_ALINK_CNT0_0X08010810
ld	D0, PMU_ALINK_CNT0_0X08010810, P0
std	D0, alink_p0, A1
ld	D0, PMU_ALINK_CNT1_0X08010811, P0
std	D0, alink_p1, A1
123:
	la      A0, posting_start
.endm
//
.macro get_pmulets_PHB
//
//load the unit_validty_tracker vector from memory
//
la 	A0, unit_validity_tracker
ld 	D1, 0x0, A0
//
//check if PHB0 is marked bad in the Unit_validity_tracker
//and skip PHB0 collect in that case.
andi 	D0, D1, BAD_PHB0
cmpibraeq D0, 1f, BAD_PHB0
//
lpcs	P0, PMU_PHB0_CNT0_0X09012011
ld	D0, PMU_PHB0_CNT0_0X09012011, P0
std	D0, phb0_c0, A1
sti	PMU_PHB0_CNT0_0X09012011, P0, ZEROS
ld	D0, PMU_PHB0_CNT1_0X09012012, P0
std	D0, phb0_c1, A1
sti	PMU_PHB0_CNT1_0X09012012, P0, ZEROS
ld	D0, PMU_PHB0_CNT2_0X09012013, P0
std	D0, phb0_c2, A1
sti	PMU_PHB0_CNT2_0X09012013, P0, ZEROS
ld	D0, PMU_PHB0_CNT3_0X09012014, P0
std	D0, phb0_c3, A1
sti	PMU_PHB0_CNT3_0X09012014, P0, ZEROS
//
1:
	//
	//check if PHB1 is marked bad in the Unit_validity_tracker
	//and skip PHB1 collect in that case.
	//
	andi 	D0, D1, BAD_PHB1
	cmpibraeq D0, 2f, BAD_PHB1
	//
	lpcs	P0, PMU_PHB1_CNT0_0X09012411
	ld	D0, PMU_PHB1_CNT0_0X09012411, P0
	std	D0, phb1_c0, A1
	sti	PMU_PHB1_CNT0_0X09012411, P0, ZEROS
	ld	D0, PMU_PHB1_CNT1_0X09012412, P0
	std	D0, phb1_c1, A1
	sti	PMU_PHB1_CNT1_0X09012412, P0, ZEROS
	ld	D0, PMU_PHB1_CNT2_0X09012413, P0
	std	D0, phb1_c2, A1
	sti	PMU_PHB1_CNT2_0X09012413, P0, ZEROS
	ld	D0, PMU_PHB1_CNT3_0X09012414, P0
	std	D0, phb1_c3, A1
	sti	PMU_PHB1_CNT3_0X09012414, P0, ZEROS
//
2:
	//
	//check if PHB2 is marked bad in the Unit_validity_tracker
	//and skip PHB2 config in that case.
	//
	andi 	D0, D1, BAD_PHB2
	cmpibraeq D0, 3f, BAD_PHB2
	//
	lpcs	P0, PMU_PHB2_CNT0_0X09012811
	ld	D0, PMU_PHB2_CNT0_0X09012811, P0
	std	D0, phb2_c0, A1
	sti	PMU_PHB2_CNT0_0X09012811, P0, ZEROS
	ld	D0, PMU_PHB2_CNT1_0X09012812, P0
	std	D0, phb2_c1, A1
	sti	PMU_PHB2_CNT1_0X09012812, P0, ZEROS
	ld	D0, PMU_PHB2_CNT2_0X09012813, P0
	std	D0, phb2_c2, A1
	sti	PMU_PHB2_CNT2_0X09012813, P0, ZEROS
	ld	D0, PMU_PHB2_CNT3_0X09012814, P0
	std	D0, phb2_c3, A1
	sti	PMU_PHB2_CNT3_0X09012814, P0, ZEROS
3:
	la      A0, posting_start
.endm
//
.macro extract_counters_from_pmulet, pmulet, counter0, counter1, counter2, counter3
ld 	D0, (\pmulet), A1
rldinm	D1, D0, count0_shift, mask_start, mask_end
//multiply by 2^16 for prescalar, so shift right 32 instead of 48
rotrdi  D1, D1, 32
std	D1, (\counter0), A1
rldinm	D1, D0, count1_shift, mask_start, mask_end
//multiply by 2^16 for prescalar, so shift right 32 instead of 48
rotrdi  D1, D1, 32
std	D1, (\counter1), A1
rldinm	D1, D0, count2_shift, mask_start, mask_end
//multiply by 2^16 for prescalar, so shift right 32 instead of 48
rotrdi  D1, D1, 32
std	D1, (\counter2), A1
rldinm	D1, D0, count3_shift, mask_start, mask_end
//multiply by 2^16 for prescalar, so shift right 32 instead of 48
rotrdi  D1, D1, 32
std	D1, (\counter3) , A1
.endm
//
.macro post_tod dest
ld 	D0, chip_TOD, A1
std	D0, (\dest), A0
.endm
//
.macro post src_meas_prd, src_cnt0, src_cnt1, src_cnt2, src_cnt3, dest_meas_prd, dest_cnt0, dest_cnt1, dest_cnt2, dest_cnt3 
ld 	D0, (\src_meas_prd), A1
std	D0, (\dest_meas_prd), A0
ld 	D0, (\src_cnt0), A1
std	D0, (\dest_cnt0), A0
ld 	D0, (\src_cnt1), A1
std	D0, (\dest_cnt1), A0
ld 	D0, (\src_cnt2), A1
std	D0, (\dest_cnt2), A0
ld 	D0, (\src_cnt3), A1
std	D0, (\dest_cnt3), A0
.endm
//
//
.macro post_atomic src_meas_prd, src_cnt0, src_cnt1, src_cnt2, src_cnt3, upd_cnt, dest_meas_prd, dest_cnt0, dest_cnt1, dest_cnt2, dest_cnt3
ptsMainstoreAtomicAdd
la      A0, posting_start
la      A1, scratch_start
sti	(\upd_cnt), A0, 0x1
ld 	D0, (\src_meas_prd), A1
std	D0, (\dest_meas_prd), A0
ld 	D0, (\src_cnt0), A1
std	D0, (\dest_cnt0), A0
ld 	D0, (\src_cnt1), A1
std	D0, (\dest_cnt1), A0
ld 	D0, (\src_cnt2), A1
std	D0, (\dest_cnt2), A0
ld 	D0, (\src_cnt3), A1
std	D0, (\dest_cnt3), A0
ptsMainstoreDefault
la      A0, posting_start
la      A1, scratch_start
.endm
//
//
// all Chip pmulet reg SCOM addresses follow:
CONST_UINT64_T( PMU_CNPM_PB_PMU_0X02010C68       , ULL(0X02010C68) );
CONST_UINT64_T( PMU_CNPM_CNT0_0X02010C54         , ULL(0X02010C54) );
CONST_UINT64_T( PMU_CNPM_CNT1_0X02010C55         , ULL(0X02010C55) );
CONST_UINT64_T( PMU_CNPM_CNT2_0X02010C56         , ULL(0X02010C56) );
CONST_UINT64_T( PMU_CNPM_CNT3_0X02010C57         , ULL(0X02010C57) );
// PB Sel
CONST_UINT64_T( PMU_CNPM_PB_SEL_0X02010C69       , ULL(0X02010C69) );
// MCMODE2 REGS
CONST_UINT64_T( MC3_MCS1_MCMODE2_0X02011D89      , ULL(0X02011D89) );
CONST_UINT64_T( MC3_MCS0_MCMODE2_0X02011D09      , ULL(0X02011D09) );
CONST_UINT64_T( MC2_MCS1_MCMODE2_0X02011C89      , ULL(0X02011C89) );
CONST_UINT64_T( MC2_MCS0_MCMODE2_0X02011C09      , ULL(0X02011C09) );
CONST_UINT64_T( MC1_MCS1_MCMODE2_0X02011989      , ULL(0X02011989) );
CONST_UINT64_T( MC1_MCS0_MCMODE2_0X02011909      , ULL(0X02011909) );
CONST_UINT64_T( MC0_MCS1_MCMODE2_0X02011889      , ULL(0X02011889) );
CONST_UINT64_T( MC0_MCS0_MCMODE2_0X02011809      , ULL(0X02011809) );
// MCEBUSEN REGS
CONST_UINT64_T( MC3_MCS1_MCEBUSEN_0X02011D1B     , ULL(0X02011D1B) );
CONST_UINT64_T( MC3_MCS0_MCEBUSEN_0X02011D9B     , ULL(0X02011D9B) );
CONST_UINT64_T( MC2_MCS1_MCEBUSEN_0X02011C1B     , ULL(0X02011C1B) );
CONST_UINT64_T( MC2_MCS0_MCEBUSEN_0X02011C9B     , ULL(0X02011C9B) );
CONST_UINT64_T( MC1_MCS1_MCEBUSEN_0X0201191B     , ULL(0X0201191B) );
CONST_UINT64_T( MC1_MCS0_MCEBUSEN_0X0201199B     , ULL(0X0201199B) );
CONST_UINT64_T( MC0_MCS1_MCEBUSEN_0X0201181B     , ULL(0X0201181B) );
CONST_UINT64_T( MC0_MCS0_MCEBUSEN_0X0201189B     , ULL(0X0201189B) );
// MCD Event Sel
CONST_UINT64_T( PMU_CNPM_MCD_SEL_0x02013416      , ULL(0x02013416) );
// X-link
CONST_UINT64_T( PMU_XLINK_CTRL_0X04010C0F  	 , ULL(0X04010C0F) );
CONST_UINT64_T( PMU_XLINK_CNT0_0X04010C10  	 , ULL(0X04010C10) );
CONST_UINT64_T( PMU_XLINK_CNT1_0X04010C11  	 , ULL(0X04010C11) );
// A-Link
CONST_UINT64_T( PMU_ALINK_CTRL0_0X0801080F  	 , ULL(0X0801080F) );
CONST_UINT64_T( PMU_ALINK_CTRL1_0X0801080E  	 , ULL(0X0801080E) );
CONST_UINT64_T( PMU_ALINK_CNT0_0X08010810  	 , ULL(0X08010810) );
CONST_UINT64_T( PMU_ALINK_CNT1_0X08010811  	 , ULL(0X08010811) );
// PHB 0
CONST_UINT64_T( PMU_PHB0_CTRL_0X09012010         , ULL(0X09012010) );
CONST_UINT64_T( PMU_PHB0_CNT0_0X09012011         , ULL(0X09012011) );
CONST_UINT64_T( PMU_PHB0_CNT1_0X09012012         , ULL(0X09012012) );
CONST_UINT64_T( PMU_PHB0_CNT2_0X09012013         , ULL(0X09012013) );
CONST_UINT64_T( PMU_PHB0_CNT3_0X09012014         , ULL(0X09012014) );
// PHB 1
CONST_UINT64_T( PMU_PHB1_CTRL_0X09012410         , ULL(0x09012410) );	
CONST_UINT64_T( PMU_PHB1_CNT0_0X09012411         , ULL(0x09012411) );	
CONST_UINT64_T( PMU_PHB1_CNT1_0X09012412         , ULL(0x09012412) );	
CONST_UINT64_T( PMU_PHB1_CNT2_0X09012413         , ULL(0x09012413) );
CONST_UINT64_T( PMU_PHB1_CNT3_0X09012414         , ULL(0x09012414) );
// PHB 2	
CONST_UINT64_T( PMU_PHB2_CTRL_0X09012810         , ULL(0x09012810) );
CONST_UINT64_T( PMU_PHB2_CNT0_0X09012811         , ULL(0x09012811) );	
CONST_UINT64_T( PMU_PHB2_CNT1_0X09012812         , ULL(0x09012812) );	
CONST_UINT64_T( PMU_PHB2_CNT2_0X09012813         , ULL(0x09012813) );
CONST_UINT64_T( PMU_PHB2_CNT3_0X09012814         , ULL(0x09012814) );
//
//define scratch space
CONST_UINT64_T( HOMER_SLW_24X7_SCRATCH_OFFSET_ADDR         , ULL(0x00350000) );
//
CONST_UINT64_T( ZEROS			   , ULL(0X0000000000000000) );
//
// Hard coded configurations for nest counters follow:
//
//CNPM CONF
CONST_UINT64_T( PMU_CNPM_PB_PMU_CONF       , ULL(0x8055eaaaaa2a0000) );
// PB Sel Conf
CONST_UINT64_T( PMU_CNPM_PB_SEL_CONF       , ULL(0x0b00500000f0f0f0) );
// MCMODE2 REGS CONF
CONST_UINT64_T( MC3_MCS1_MCMODE2_CONF      , ULL(0X0000000000000000) );
CONST_UINT64_T( MC3_MCS0_MCMODE2_CONF      , ULL(0X0000000000000000) );
CONST_UINT64_T( MC2_MCS1_MCMODE2_CONF      , ULL(0X0000000000000000) );
CONST_UINT64_T( MC2_MCS0_MCMODE2_CONF      , ULL(0X0000000000000000) );
CONST_UINT64_T( MC1_MCS1_MCMODE2_CONF      , ULL(0X0000000000000000) );
CONST_UINT64_T( MC1_MCS0_MCMODE2_CONF      , ULL(0X0000000000000000) );
CONST_UINT64_T( MC0_MCS1_MCMODE2_CONF      , ULL(0X0000000000000000) );
CONST_UINT64_T( MC0_MCS0_MCMODE2_CONF      , ULL(0X0000000000000000) );
// MCEBUSEN REGS CONF
CONST_UINT64_T( MC3_MCS1_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
CONST_UINT64_T( MC3_MCS0_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
CONST_UINT64_T( MC2_MCS1_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
CONST_UINT64_T( MC2_MCS0_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
CONST_UINT64_T( MC1_MCS1_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
CONST_UINT64_T( MC1_MCS0_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
CONST_UINT64_T( MC0_MCS1_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
CONST_UINT64_T( MC0_MCS0_MCEBUSEN_CONF     , ULL(0x0010060080000000) );
// MCD Event Sel CONF
CONST_UINT64_T( PMU_CNPM_MCD_SEL_CONF      , ULL(0X0000014030000000) );
// X-link CONF
CONST_UINT64_T( PMU_XLINK_CTRL_CONF  	   , ULL(0X18001195bc19dfe1) );
// A-Link CONF
//CONST_UINT64_T( PMU_ALINK_CTRL0_CONF  	   , ULL(0X7BF2800000000000) );
CONST_UINT64_T( PMU_ALINK_CTRL0_CONF  	   , ULL(0XABE1800000000000) );
//CONST_UINT64_T( PMU_ALINK_CTRL1_CONF  	   , ULL(0X10116AE280000000) );
CONST_UINT64_T( PMU_ALINK_CTRL1_CONF  	   , ULL(0x22A589CD80000000) );
// PHB 0,1,2 CONF
CONST_UINT64_T( PMU_PHB0_CTRL_CONF         , ULL(0x800002010b060000) );
CONST_UINT64_T( PMU_PHB1_CTRL_CONF         , ULL(0x800002010b060000) );	
CONST_UINT64_T( PMU_PHB2_CTRL_CONF         , ULL(0x800002010b060000) );
//
//offsets for posting area
//
CONST_UINT32_T( GRP0_0_TOD					,ULL( 0x00000000 ) );
CONST_UINT32_T( GRP0_1_UPDATE_COUNT 				,ULL( 0x00000008 ) );
CONST_UINT32_T( GRP0_2_MEAS_PRD_ACC				,ULL( 0x00000010 ) );
CONST_UINT32_T( GRP0_3_PM_PB_CYC_ACC				,ULL( 0x00000018 ) );
CONST_UINT32_T( GRP0_4_PM_MCD_CHECK_RTY_DINC_ACC		,ULL( 0x00000020 ) );
CONST_UINT32_T( GRP0_5_PM_PB_INT_DATA_XFER_ACC			,ULL( 0x00000028 ) );
CONST_UINT32_T( GRP0_6_PM_PB_EXT_DATA_XFER_ACC			,ULL( 0x00000030 ) );
CONST_UINT32_T( GRP0_7_MEAS_PRD					,ULL( 0x00000038 ) );
CONST_UINT32_T( GRP0_8_PM_PB_CYC 				,ULL( 0x00000040 ) );
CONST_UINT32_T( GRP0_9_PM_MCD_CHECK_RTY_DINC 			,ULL( 0x00000048 ) );
CONST_UINT32_T( GRP0_10_PM_PB_INT_DATA_XFER 			,ULL( 0x00000050 ) );
CONST_UINT32_T( GRP0_11_PM_PB_EXT_DATA_XFER 			,ULL( 0x00000058 ) );
CONST_UINT32_T( GRP0_12_TOD					,ULL( 0x00000060 ) );
//
CONST_UINT32_T( GRP1_0_TOD					,ULL( 0x00000080 ) );
CONST_UINT32_T( GRP1_1_UPDATE_COUNT 				,ULL( 0x00000088 ) );
CONST_UINT32_T( GRP1_2_MEAS_PRD_ACC				,ULL( 0x00000090 ) );
CONST_UINT32_T( GRP1_3_PM_PB_SYS_PUMP_ACC			,ULL( 0x00000098 ) );
CONST_UINT32_T( GRP1_4_PM_PB_NODE_PUMP_ACC			,ULL( 0x000000A0 ) );
CONST_UINT32_T( GRP1_5_PM_PB_SYS_PUMP_RTY_ACC			,ULL( 0x000000A8 ) );
CONST_UINT32_T( GRP1_6_PM_PB_NODE_PUMP_RTY_ACC			,ULL( 0x000000B0 ) );
CONST_UINT32_T( GRP1_7_MEAS_PRD					,ULL( 0x000000B8 ) );
CONST_UINT32_T( GRP1_8_PM_PB_SYS_PUMP 				,ULL( 0x000000C0 ) );
CONST_UINT32_T( GRP1_9_PM_PB_NODE_PUMP				,ULL( 0x000000C8 ) );
CONST_UINT32_T( GRP1_10_PM_PB_SYS_PUMP_RTY 			,ULL( 0x000000D0 ) );
CONST_UINT32_T( GRP1_11_PM_PB_NODE_PUMP_RTY 			,ULL( 0x000000D8 ) );
CONST_UINT32_T( GRP1_12_TOD					,ULL( 0x000000E0 ) );
//
CONST_UINT32_T( GRP2_0_TOD					,ULL( 0x00000100 ) );
CONST_UINT32_T( GRP2_1_UPDATE_COUNT 				,ULL( 0x00000108 ) );
CONST_UINT32_T( GRP2_2_MEAS_PRD_ACC				,ULL( 0x00000110 ) );
CONST_UINT32_T( GRP2_3_PM_MCS_UP_128B_DATA_XFER_MC0_ACC		,ULL( 0x00000118 ) );
CONST_UINT32_T( GRP2_4_PM_MCS_UP_128B_DATA_XFER_MC1_ACC	,ULL( 0x00000120 ) );
CONST_UINT32_T( GRP2_5_PM_MCS_UP_128B_DATA_XFER_MC2_ACC	,ULL( 0x00000128 ) );
CONST_UINT32_T( GRP2_6_PM_MCS_UP_128B_DATA_XFER_MC3_ACC		,ULL( 0x00000130 ) );
CONST_UINT32_T( GRP2_7_MEAS_PRD					,ULL( 0x00000138 ) );
CONST_UINT32_T( GRP2_8_PM_MCS_UP_128B_DATA_XFER_MC0 		,ULL( 0x00000140 ) );
CONST_UINT32_T( GRP2_9_PM_MCS_UP_128B_DATA_XFER_MC1 		,ULL( 0x00000148 ) );
CONST_UINT32_T( GRP2_10_PM_MCS_UP_128B_DATA_XFER_MC2		,ULL( 0x00000150 ) );
CONST_UINT32_T( GRP2_11_PM_MCS_UP_128B_DATA_XFER_MC3		,ULL( 0x00000158 ) );
CONST_UINT32_T( GRP2_12_TOD					,ULL( 0x00000160 ) );
//
CONST_UINT32_T( GRP3_0_TOD					,ULL( 0x00000180 ) );
CONST_UINT32_T( GRP3_1_UPDATE_COUNT 				,ULL( 0x00000188 ) );
CONST_UINT32_T( GRP3_2_MEAS_PRD_ACC				,ULL( 0x00000190 ) );
CONST_UINT32_T( GRP3_3_PM_MCS_DOWN_128B_DATA_XFER_MC0_ACC	,ULL( 0x00000198 ) );
CONST_UINT32_T( GRP3_4_PM_MCS_DOWN_128B_DATA_XFER_MC1_ACC	,ULL( 0x000001A0 ) );
CONST_UINT32_T( GRP3_5_PM_MCS_DOWN_128B_DATA_XFER_MC2_ACC	,ULL( 0x000001A8 ) );
CONST_UINT32_T( GRP3_6_PM_MCS_DOWN_128B_DATA_XFER_MC3_ACC	,ULL( 0x000001B0 ) );
CONST_UINT32_T( GRP3_7_MEAS_PRD					,ULL( 0x000001B8 ) );
CONST_UINT32_T( GRP3_8_PM_MCS_DOWN_128B_DATA_XFER_MC0 		,ULL( 0x000001C0 ) );
CONST_UINT32_T( GRP3_9_PM_MCS_DOWN_128B_DATA_XFER_MC1 		,ULL( 0x000001C8 ) );
CONST_UINT32_T( GRP3_10_PM_MCS_DOWN_128B_DATA_XFER_MC2		,ULL( 0x000001D0 ) );
CONST_UINT32_T( GRP3_11_PM_MCS_DOWN_128B_DATA_XFER_MC3		,ULL( 0x000001D8 ) );
CONST_UINT32_T( GRP3_12_TOD					,ULL( 0x000001E0 ) );
//
CONST_UINT32_T( GRP4_0_TOD					,ULL( 0x00000200 ) );
CONST_UINT32_T( GRP4_1_UPDATE_COUNT 				,ULL( 0x00000208 ) );
CONST_UINT32_T( GRP4_2_MEAS_PRD_ACC				,ULL( 0x00000210 ) );
CONST_UINT32_T( GRP4_3_PM_XLINK0_IN_DATA_CYC_ACC		,ULL( 0x00000218 ) );
CONST_UINT32_T( GRP4_4_PM_XLINK1_IN_DATA_CYC_ACC		,ULL( 0x00000220 ) );
CONST_UINT32_T( GRP4_5_PM_XLINK3_IN_DATA_CYC_ACC		,ULL( 0x00000228 ) );
CONST_UINT32_T( GRP4_6_PM_XLINK_CYCLES_ACC			,ULL( 0x00000230 ) );
CONST_UINT32_T( GRP4_7_MEAS_PRD					,ULL( 0x00000238 ) );
CONST_UINT32_T( GRP4_8_PM_XLINK0_IN_DATA_CYC			,ULL( 0x00000240 ) );
CONST_UINT32_T( GRP4_9_PM_XLINK1_IN_DATA_CYC			,ULL( 0x00000248 ) );
CONST_UINT32_T( GRP4_10_PM_XLINK3_IN_DATA_CYC			,ULL( 0x00000250 ) );
CONST_UINT32_T( GRP4_11_PM_XLINK_CYCLES				,ULL( 0x00000258 ) );
CONST_UINT32_T( GRP4_12_TOD					,ULL( 0x00000260 ) );
//
CONST_UINT32_T( GRP5_0_TOD					,ULL( 0x00000280 ) );
CONST_UINT32_T( GRP5_1_UPDATE_COUNT 				,ULL( 0x00000288 ) );
CONST_UINT32_T( GRP5_2_MEAS_PRD_ACC				,ULL( 0x00000290 ) );
CONST_UINT32_T( GRP5_3_PM_XLINK0_IN_IDL_CYC_ACC			,ULL( 0x00000298 ) );
CONST_UINT32_T( GRP5_4_PM_XLINK1_IN_IDL_CYC_ACC			,ULL( 0x000002A0 ) );
CONST_UINT32_T( GRP5_5_PM_XLINK3_IN_IDL_CYC_ACC			,ULL( 0x000002A8 ) );
CONST_UINT32_T( GRP5_6_PM_XLINK_CYCLES_ACC			,ULL( 0x000002B0 ) );
CONST_UINT32_T( GRP5_7_MEAS_PRD					,ULL( 0x000002B8 ) );
CONST_UINT32_T( GRP5_8_PM_XLINK0_IN_IDL_CYC			,ULL( 0x000002C0 ) );
CONST_UINT32_T( GRP5_9_PM_XLINK1_IN_IDL_CYC			,ULL( 0x000002C8 ) );
CONST_UINT32_T( GRP5_10_PM_XLINK3_IN_IDL__CYC			,ULL( 0x000002D0 ) );
CONST_UINT32_T( GRP5_11_PM_XLINK_CYCLES				,ULL( 0x000002D8 ) );
CONST_UINT32_T( GRP5_12_TOD					,ULL( 0x000002E0 ) );
//
CONST_UINT32_T( GRP6_0_TOD					,ULL( 0x00000300 ) );
CONST_UINT32_T( GRP6_1_UPDATE_COUNT 				,ULL( 0x00000308 ) );
CONST_UINT32_T( GRP6_2_MEAS_PRD_ACC				,ULL( 0x00000310 ) );
CONST_UINT32_T( GRP6_3_PM_ALINK0_IN_DATA_CYC_ACC		,ULL( 0x00000318 ) );
CONST_UINT32_T( GRP6_4_PM_ALINK1_IN_DATA_CYC_ACC		,ULL( 0x00000320 ) );
CONST_UINT32_T( GRP6_5_PM_ALINK2_IN_DATA_CYC_ACC		,ULL( 0x00000328 ) );
CONST_UINT32_T( GRP6_6_PM_ALINK_CYCLES_ACC			,ULL( 0x00000330 ) );
CONST_UINT32_T( GRP6_7_MEAS_PRD 				,ULL( 0x00000338 ) );
CONST_UINT32_T( GRP6_8_PM_ALINK0_IN_DATA_CYC			,ULL( 0x00000340 ) );
CONST_UINT32_T( GRP6_9_PM_ALINK1_IN_DATA_CYC			,ULL( 0x00000348 ) );
CONST_UINT32_T( GRP6_10_PM_ALINK2_IN_DATA_CYC			,ULL( 0x00000350 ) );
CONST_UINT32_T( GRP6_11_PM_ALINK_CYCLES				,ULL( 0x00000358 ) );
CONST_UINT32_T( GRP6_12_TOD					,ULL( 0x00000360 ) );
//
CONST_UINT32_T( GRP7_0_TOD					,ULL( 0x00000380 ) );
CONST_UINT32_T( GRP7_1_UPDATE_COUNT 				,ULL( 0x00000388 ) );
CONST_UINT32_T( GRP7_2_MEAS_PRD_ACC				,ULL( 0x00000390 ) );
CONST_UINT32_T( GRP7_3_PM_ALINK0_IN_IDL_CYC_ACC			,ULL( 0x00000398 ) );
CONST_UINT32_T( GRP7_4_PM_ALINK1_IN_IDL_CYC_ACC			,ULL( 0x000003A0 ) );
CONST_UINT32_T( GRP7_5_PM_ALINK2_IN_IDL_CYC_ACC			,ULL( 0x000003A8 ) );
CONST_UINT32_T( GRP7_6_PM_ALINK_CYCLES_ACC			,ULL( 0x000003B0 ) );
CONST_UINT32_T( GRP7_7_MEAS_PRD					,ULL( 0x000003B8 ) );
CONST_UINT32_T( GRP7_8_PM_ALINK0_IN_IDL_CYC			,ULL( 0x000003C0 ) );
CONST_UINT32_T( GRP7_9_PM_ALINK1_IN_IDL_CYC			,ULL( 0x000003C8 ) );
CONST_UINT32_T( GRP7_10_PM_ALINK2_IN_IDL_CYC			,ULL( 0x000003D0 ) );
CONST_UINT32_T( GRP7_11_PM_ALINK_CYCLES				,ULL( 0x000003D8 ) );
CONST_UINT32_T( GRP7_12_TOD					,ULL( 0x000003E0 ) );
//
CONST_UINT32_T( GRP8_0_TOD					,ULL( 0x00000400 ) );
CONST_UINT32_T( GRP8_1_UPDATE_COUNT 				,ULL( 0x00000408 ) );
CONST_UINT32_T( GRP8_2_MEAS_PRD_ACC				,ULL( 0x00000410 ) );
CONST_UINT32_T( GRP8_3_PM_PHB_ANY_DMA_RCV_PHB0_ACC		,ULL( 0x00000418 ) );
CONST_UINT32_T( GRP8_4_PM_PHB_CYC_CNT_PHB0_ACC			,ULL( 0x00000420 ) );
CONST_UINT32_T( GRP8_5_PM_PHB_ANY_TCE_MISS_PHB0_ACC		,ULL( 0x00000428 ) );
CONST_UINT32_T( GRP8_6_PM_PHB_MSI_INTR_PHB0_ACC			,ULL( 0x00000430 ) );
CONST_UINT32_T( GRP8_7_MEAS_PRD 				,ULL( 0x00000438 ) );
CONST_UINT32_T( GRP8_8_PM_PHB_ANY_DMA_RCV_PHB0			,ULL( 0x00000440 ) );
CONST_UINT32_T( GRP8_9_PM_PHB_CYC_CNT_PHB0			,ULL( 0x00000448 ) );
CONST_UINT32_T( GRP8_10_PM_PHB_ANY_TCE_MISS_PHB0		,ULL( 0x00000450 ) );
CONST_UINT32_T( GRP8_11_PM_PHB_MSI_INTR_PHB0			,ULL( 0x00000458 ) );
CONST_UINT32_T( GRP8_12_TOD					,ULL( 0x00000460 ) );
//
CONST_UINT32_T( GRP9_0_TOD					,ULL( 0x00000480 ) );
CONST_UINT32_T( GRP9_1_UPDATE_COUNT 				,ULL( 0x00000488 ) );
CONST_UINT32_T( GRP9_2_MEAS_PRD_ACC				,ULL( 0x00000490 ) );
CONST_UINT32_T( GRP9_3_PM_PHB_ANY_DMA_RCV_PHB1_ACC		,ULL( 0x00000498 ) );
CONST_UINT32_T( GRP9_4_PM_PHB_CYC_CNT_PHB1_ACC			,ULL( 0x000004A0 ) );
CONST_UINT32_T( GRP9_5_PM_PHB_ANY_TCE_MISS_PHB1_ACC		,ULL( 0x000004A8 ) );
CONST_UINT32_T( GRP9_6_PM_PHB_MSI_INTR_PHB1_ACC			,ULL( 0x000004B0 ) );
CONST_UINT32_T( GRP9_7_MEAS_PRD					,ULL( 0x000004B8 ) );
CONST_UINT32_T( GRP9_8_PM_PHB_ANY_DMA_RCV_PHB1			,ULL( 0x000004C0 ) );
CONST_UINT32_T( GRP9_9_PM_PHB_CYC_CNT_PHB1 			,ULL( 0x000004C8 ) );
CONST_UINT32_T( GRP9_10_PM_PHB_ANY_TCE_MISS_PHB1		,ULL( 0x000004D0 ) );
CONST_UINT32_T( GRP9_11_PM_PHB_MSI_INTR_PHB1			,ULL( 0x000004D8 ) );
CONST_UINT32_T( GRP9_12_TOD					,ULL( 0x000004E0 ) );
//
CONST_UINT32_T( GRP10_0_TOD					,ULL( 0x00000500 ) );
CONST_UINT32_T( GRP10_1_UPDATE_COUNT 				,ULL( 0x00000508 ) );
CONST_UINT32_T( GRP10_2_MEAS_PRD0_ACC				,ULL( 0x00000510 ) );
CONST_UINT32_T( GRP10_3_PM_PHB_ANY_DMA_RCV_PHB2_ACC		,ULL( 0x00000518 ) );
CONST_UINT32_T( GRP10_4_PM_PHB_CYC_CNT_PHB2_ACC			,ULL( 0x00000520 ) );
CONST_UINT32_T( GRP10_5_PM_PHB_ANY_TCE_MISS_PHB2_ACC		,ULL( 0x00000528 ) );
CONST_UINT32_T( GRP10_6_PM_PHB_MSI_INTR_PHB2_ACC		,ULL( 0x00000530 ) );
CONST_UINT32_T( GRP10_7_MEAS_PRD0				,ULL( 0x00000538 ) );
CONST_UINT32_T( GRP10_8_PM_PHB_ANY_DMA_RCV_PHB2			,ULL( 0x00000540 ) );
CONST_UINT32_T( GRP10_9_PM_PHB_CYC_CNT_PHB2			,ULL( 0x00000548 ) );
CONST_UINT32_T( GRP10_10_PM_PHB_ANY_TCE_MISS_PHB2		,ULL( 0x00000550 ) );
CONST_UINT32_T( GRP10_11_PM_PHB_MSI_INTR_PHB2			,ULL( 0x00000558 ) );
CONST_UINT32_T( GRP10_12_TOD					,ULL( 0x00000560 ) );

//-------------------------------------------------------------------------------------
ima_24x7_pibErrorHandle:
	la A0,0xDEADBEEF
//	bra .
//	bra initialize
//load the debug register to D0, and extract the failing address
//use content of SPRG0 as base and PTS_THREAD_DBG0 as index
	la A0, unit_validity_tracker
	ld D1, 0x0, A0
	mr A0, SPRG0
//load the exact failing SCOM address to D0
	ld D0, PTS_THREAD_DBG0, A0
//store the failing SCOM address to scratch memory
	la A0, DEBUG_SCOM_SCRATCH
        extrdi  D0, D0, 32, 0
	std D0, 0, A0
//
	mr A0, SPRG0
	ldandi D0, PTS_THREAD_DBG0, A0, 0xFFFFFF0000000000
        extrdi  D0, D0, 32, 0
	cmpibraeq D0, err_PB, PMU_PB_0X02010Cxx
	cmpibraeq D0, err_MC0, PMU_MC0_0x020118xx
	cmpibraeq D0, err_MC1, PMU_MC1_0x020119xx
	cmpibraeq D0, err_MC2, PMU_MC2_0x02011cxx
	cmpibraeq D0, err_MC3, PMU_MC3_0x02011dxx
	cmpibraeq D0, err_X, PMU_X_0x04010cxx
	cmpibraeq D0, err_A, PMU_A_0x080108xx
	cmpibraeq D0, err_PHB0, PMU_PHB0_0x090120xx
	cmpibraeq D0, err_PHB1, PMU_PHB1_0x090124xx
	cmpibraeq D0, err_PHB2, PMU_PHB2_0x090128xx
	cmpibraeq D0, err_MCD, PMU_MCD_0x020134xx
// fall through leads to termination
	ptsTerminate rc=UNHANDLED_SCOM_ERROR
//
//err loop entry points follow
	err_PB:
		ori D1, D1, BAD_PB
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_PB
		std D0, 0, A0
		bra err_end
	err_MC0:
		ori D1, D1, BAD_MC0
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_MC0
		std D0, 0, A0
		bra err_end
	err_MC1:
		ori D1, D1, BAD_MC1
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_MC1
		std D0, 0, A0
		bra err_end
	err_MC2:
		ori D1, D1, BAD_MC2
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_MC2
		std D0, 0, A0
		bra err_end
	err_MC3:
		ori D1, D1, BAD_MC3
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_MC3
		std D0, 0, A0
		bra err_end
	err_X:
		ori D1, D1, BAD_X
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_X
		std D0, 0, A0
		bra err_end
	err_A:
		ori D1, D1, BAD_A
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_A
		std D0, 0, A0
		bra err_end
	err_PHB0:
		ori D1, D1, BAD_PHB0
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_PHB0
		std D0, 0, A0
		bra err_end
	err_PHB1:
		ori D1, D1, BAD_PHB1
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_PHB1
		std D0, 0, A0
		bra err_end
	err_PHB2:
		ori D1, D1, BAD_PHB2
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_PHB2
		std D0, 0, A0
		bra err_end
	err_MCD:
		ori D1, D1, BAD_MCD
//load the offending SCOM from scratch to store in well defined debug area
		la A0, DEBUG_SCOM_SCRATCH
		ld D0, 0, A0
		la A0, DEBUG_SCOM_MCD
		std D0, 0, A0
		bra err_end
//store the unit validity vector
	err_end:
		la A0, unit_validity_tracker
		std D1, 0x0, A0 
//make a system call to signal recovery is complete, restore address
//registers and continue
                ptsYield
		la A0, posting_start
		la A1, scratch_start
//exit the error handler
		bra initialize	
//
ima_24x7_reset:
//inserting illegal to see if it enters here and halts.
//.long 0
//
//clear the posting area
//
	clear_posting
//change control block status to initializing
//initialize the control block
	la A0, cb_base
	sti cb_0, A0, 0x0
	sti cb_1, A0, 0x0
	sti cb_2, A0, 0x0
//
//PHB is not to be collected due to HW bug
//so mark it bad in unit validity tracker
//
	la A0, unit_validity_tracker
        ld D1, 0x0, A0
	ori D1, D1, BAD_PHB0
	ori D1, D1, BAD_PHB1
	ori D1, D1, BAD_PHB2
	la A0, unit_validity_tracker
        std D1, 0x0, A0
	la A0, posting_start
	la A1, scratch_start
//
//set all configurations. loops here if config check fails anywhere.
//
initialize:	
	set_config_cnpm
	ptsYield
	la A0, posting_start
	la A1, scratch_start
	set_config_xlink
	set_config_alink
	ptsYield
	la A0, posting_start
	la A1, scratch_start
//commenting out PHB due to HW bug
//	set_config_phb
//
// sleep for 50 ms 	
	ptsSleepConstant PTS_MILLISECONDS(50),A1, A0
//
//
	la      A1, scratch_start
//test read of pmulets
	get_pmulets_cnpm
	get_pmulets_xlink
	get_pmulets_alink
collect:
	la      A0, posting_start
        la      A1, scratch_start
	update_cb_status
	check_config_cnpm
	check_config_xlink
	check_config_alink
//	check_config_phb
	la      A0, posting_start
        la      A1, scratch_start
//
//cnpm - 4 groups
//
// read TOD
	get_tod
//read cnpm pmulets and put them in scaratch
	get_pmulets_cnpm
//get pmulets from scratch, split into counters and store to scratch
	extract_counters_from_pmulet cnpm_p0, cnpm_p0_c0, cnpm_p0_c1, cnpm_p0_c2, cnpm_p0_c3
	extract_counters_from_pmulet cnpm_p1, cnpm_p1_c0, cnpm_p1_c1, cnpm_p1_c2, cnpm_p1_c3
	extract_counters_from_pmulet cnpm_p2, cnpm_p2_c0, cnpm_p2_c1, cnpm_p2_c2, cnpm_p2_c3
	extract_counters_from_pmulet cnpm_p3, cnpm_p3_c0, cnpm_p3_c1, cnpm_p3_c2, cnpm_p3_c3
//post data for the 4 cnpm groups- grp 0,1,2,3
//post TOD for grp0
	post_tod g0_0
//post last samples for grp0
	post cnpm_p0_c0, cnpm_p0_c0, cnpm_p0_c1, cnpm_p3_c0, cnpm_p3_c1, g0_7, g0_8, g0_9, g0_10, g0_11
//post accumulated values for grp0
	post_atomic cnpm_p0_c0, cnpm_p0_c0, cnpm_p0_c1, cnpm_p3_c0, cnpm_p3_c1, g0_1, g0_2, g0_3, g0_4, g0_5, g0_6
//post TOD for end picket for grp0
	post_tod g0_12
//
//post TOD for grp1
	post_tod g1_0
//post last samples for grp1
	post cnpm_p0_c0, cnpm_p1_c0, cnpm_p1_c1, cnpm_p2_c0, cnpm_p2_c1, g1_7, g1_8, g1_9, g1_10, g1_11
//post accumulated values for grp1
	post_atomic cnpm_p0_c0, cnpm_p1_c0, cnpm_p1_c1, cnpm_p2_c0, cnpm_p2_c1, g1_1, g1_2, g1_3, g1_4, g1_5, g1_6
//post TOD for end picket for grp1
	post_tod g1_12					
//
//post TOD for grp2
	post_tod g2_0
//post last samples for grp2
	post cnpm_p0_c0, cnpm_p3_c2, cnpm_p1_c2, cnpm_p0_c2, cnpm_p2_c2, g2_7, g2_8, g2_9, g2_10, g2_11
//post accumulated values for grp1
	post_atomic cnpm_p0_c0, cnpm_p3_c2, cnpm_p1_c2, cnpm_p0_c2, cnpm_p2_c2, g2_1, g2_2, g2_3, g2_4, g2_5, g2_6
//post TOD for end picket for grp2
	post_tod g2_12	
//
//post TOD for grp3
	post_tod g3_0
//post last samples for grp3
	post cnpm_p0_c0, cnpm_p3_c3, cnpm_p1_c3, cnpm_p0_c3, cnpm_p2_c3, g3_7, g3_8, g3_9, g3_10, g3_11
//post accumulated values for grp1
	post_atomic cnpm_p0_c0, cnpm_p3_c3, cnpm_p1_c3, cnpm_p0_c3, cnpm_p2_c3, g3_1, g3_2, g3_3, g3_4, g3_5, g3_6
//post TOD for end picket for grp3
	post_tod g3_12
//Yield
	ptsYield
	la A0, posting_start
	la A1, scratch_start
//
//Xlink - 2 groups
//
// read TOD
	get_tod
//read xlink pmulets and put them in scaratch
	get_pmulets_xlink
//get pmulets from scratch, split into counters and store to scratch
	extract_counters_from_pmulet xlink_p0, xlink_p0_c0, xlink_p0_c1, xlink_p0_c2, xlink_p0_c3
	extract_counters_from_pmulet xlink_p1, xlink_p1_c0, xlink_p1_c1, xlink_p1_c2, xlink_p1_c3
//post data for the 2 xlink groups- grp 4,5
//post TOD for grp4
	post_tod g4_0
//post last samples for grp4
	post xlink_p0_c3, xlink_p0_c0, xlink_p0_c1, xlink_p0_c2, xlink_p0_c3, g4_7, g4_8, g4_9, g4_10, g4_11
//post accumulated values for grp4
	post_atomic xlink_p0_c3, xlink_p0_c0, xlink_p0_c1, xlink_p0_c2, xlink_p0_c3, g4_1, g4_2, g4_3, g4_4, g4_5, g4_6
//post TOD for end picket for grp4
	post_tod g4_12
//
//post TOD for grp5
	post_tod g5_0
//post last samples for grp5
	post xlink_p1_c3, xlink_p1_c0, xlink_p1_c1, xlink_p1_c2, xlink_p1_c3, g5_7, g5_8, g5_9, g5_10, g5_11
//post accumulated values for grp5
	post_atomic xlink_p1_c3, xlink_p1_c0, xlink_p1_c1, xlink_p1_c2, xlink_p1_c3, g5_1, g5_2, g5_3, g5_4, g5_5, g5_6
//post TOD for end picket for grp5
	post_tod g5_12	
//
//alink - 2 groups
//
// read TOD
	get_tod
//read alink pmulets and put them in scaratch
	get_pmulets_alink
//get pmulets from scratch, split into counters and store to scratch
	extract_counters_from_pmulet alink_p0, alink_p0_c0, alink_p0_c1, alink_p0_c2, alink_p0_c3
	extract_counters_from_pmulet alink_p1, alink_p1_c0, alink_p1_c1, alink_p1_c2, alink_p1_c3
//post data for the 2 alink groups- grp 6,7
//post TOD for grp6
	post_tod g6_0
//post last samples for grp6
	post alink_p0_c3, alink_p0_c0, alink_p0_c1, alink_p0_c2, alink_p0_c3, g6_7, g6_8, g6_9, g6_10, g6_11
//post accumulated values for grp6
	post_atomic alink_p0_c3, alink_p0_c0, alink_p0_c1, alink_p0_c2, alink_p0_c3, g6_1, g6_2, g6_3, g6_4, g6_5, g6_6
//post TOD for end picket for grp6
	post_tod g6_12
//
//post TOD for grp7
	post_tod g7_0
//post last samples for grp7
	post alink_p1_c3, alink_p1_c0, alink_p1_c1, alink_p1_c2, alink_p1_c3, g7_7, g7_8, g7_9, g7_10, g7_11
//post accumulated values for grp7
	post_atomic alink_p1_c3, alink_p1_c0, alink_p1_c1, alink_p1_c2, alink_p1_c3, g7_1, g7_2, g7_3, g7_4, g7_5, g7_6
//post TOD for end picket for grp7
	post_tod g7_12
//Yield
	ptsYield
	la A0, posting_start
	la A1, scratch_start
//
//PHB - 3 groups
//
// read TOD
//	get_tod
//read PHB pmulets and put them in scaratch. No need to extract as only 1 48-bit counter per pmulet.
//        get_pmulets_PHB
//post data for the 3 PHB groups corresponding to PHB0,1,2 - grp 8,9,10
//post TOD for grp8
//	post_tod g8_0
//post last samples for grp8
//	post phb0_c2, phb0_c0, phb0_c1, phb0_c2, phb0_c3, g8_7, g8_8, g8_9, g8_10, g8_11
//post acc value same as above
//	post_atomic phb0_c2, phb0_c0, phb0_c1, phb0_c2, phb0_c3, g8_1, g8_2, g8_3, g8_4, g8_5, g8_6
//	ld 	D0, g8_1, A0
//	adds	D0, D0, 1
//	std	D0, g8_1, A0
//post TOD for end picket for grp8
//	post_tod g8_12
//
//post TOD for grp9
//	post_tod g9_0
//post last samples for grp9
//	post phb1_c2, phb1_c0, phb1_c1, phb1_c2, phb1_c3, g9_7, g9_8, g9_9, g9_10, g9_11
//post acc value same as above
//	post_atomic phb1_c2, phb1_c0, phb1_c1, phb1_c2, phb1_c3, g9_1, g9_2, g9_3, g9_4, g9_5, g9_6
//	ld 	D0, g9_1, A0
//	adds	D0, D0, 1
//	std	D0, g9_1, A0
//post TOD for end picket for grp9
//	post_tod g9_12
//
//post TOD for grp10
//	post_tod g10_0
//post last samples for grp10
//	post phb2_c2, phb2_c0, phb2_c1, phb2_c2, phb2_c3, g10_7, g10_8, g10_9, g10_10, g10_11
//post acc value same as above
//	post_atomic phb2_c2, phb2_c0, phb2_c1, phb2_c2, phb2_c3, g10_1, g10_2, g10_3, g10_4, g10_5, g10_6
//	ld 	D0, g10_1, A0
//	adds	D0, D0, 1
//	std	D0, g10_1, A0
//post TOD for end picket for grp10
//	post_tod g10_12	
//Yield
	ptsYield
	la A0, posting_start
	la A1, scratch_start
//
//Yield
//	
loop_end:
	la A0, cb_base
	ld	D0, cb_2, A0
	cmpibraeq D0, loop_1000ms, 0x7
	cmpibraeq D0, loop_256ms, 0x6
	cmpibraeq D0, loop_64ms, 0x5
	cmpibraeq D0, loop_16ms, 0x4
	cmpibraeq D0, loop_4ms, 0x3
	cmpibraeq D0, loop_1ms, 0x2
	cmpibraeq D0, loop_256us, 0x1
	ptsSleepConstant PTS_MICROSECONDS(128),A1, A0
	bra loop_back
loop_256us:
	ptsSleepConstant PTS_MICROSECONDS(256),A1, A0
	bra loop_back
loop_1ms:
	ptsSleepConstant PTS_MILLISECONDS(1),A1, A0
	bra loop_back
loop_4ms:
	ptsSleepConstant PTS_MILLISECONDS(4),A1, A0
	bra loop_back
loop_16ms:
	ptsSleepConstant PTS_MILLISECONDS(16),A1, A0
	bra loop_back
loop_64ms:
	ptsSleepConstant PTS_MILLISECONDS(64),A1, A0
	bra loop_back
loop_256ms:
	ptsSleepConstant PTS_MILLISECONDS(256),A1, A0
	bra loop_back
loop_1000ms:
	ptsSleepConstant PTS_MILLISECONDS(1000),A1, A0
//
// loop back.
//
loop_back:
	la A0, posting_start
//	bra .
	bra collect

.ptsEpilogue ima_24x7_reset
