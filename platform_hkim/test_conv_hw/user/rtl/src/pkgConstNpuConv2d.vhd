--------------------------------------------------------------------------------
--
-- Copyright(c) 2024 Electronics and Telecommunications Research Institute(ETRI)
-- All Rights Reserved.
--
-- Following acts are STRICTLY PROHIBITED except when a specific prior written
-- permission is obtained from ETRI or a separate written agreement with ETRI
-- stipulates such permission specifically:
--   a) Selling, distributing, sublicensing, renting, leasing, transmitting,
--      redistributing or otherwise transferring this software to a third party;
--   b) Copying, transforming, modifying, creating any derivatives of, reverse 
--      engineering, decompiling, disassembling, translating, making any attempt
--      to discover the source code of, the whole or part of this software 
--      in source or binary form;
--   c) Making any copy of the whole or part of this software other than one 
--      copy for backup purposes only; and
--   d) Using the name, trademark or logo of ETRI or the names of contributors 
--      in order to endorse or promote products derived from this software.
--
-- This software is provided "AS IS," without a warranty of any kind.
-- ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING
-- ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR
-- NON-INFRINGEMENT,ARE HEREBY EXCLUDED. IN NO EVENT WILL ETRI(OR ITS LICENSORS,
-- IF ANY) BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR FOR DIRECT, 
-- INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE DAMAGES, HOWEVER 
-- CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF ETRI 
-- HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
--
-- Any permitted redistribution of this software must retain the copyright 
-- notice, conditions, and disclaimer as specified above.
--
--------------------------------------------------------------------------------
-- Copyright Human Body Communication 2024, All rights reserved.
-- AI Edge SoC Research Section, AI SoC Research Division,
-- Artificial Intelligence Research Laboratory
-- Electronics and Telecommunications Research Institute (ETRI)
--------------------------------------------------------------------------------

--==============================================================================
-- File Name : pkgConstNpuConv2d.vhd
--==============================================================================
-- Rev.      Des.    Function
-- V210000   hkim    Package for pkgConstNpuConv2d
--
--                    |<------------------- image width --------------------->|
--                    |<-------- image buffer ------->|                       |
--                    |<------ kernel ------>|        |                       |
--                    |<-- kernel buf -->|   |        |                       |
--   -----------------+------------------+---+--------+-----------------------+
--    |    |   |   |  |                  |   |        |                       |
--    |    |   |  ker |                  |   |        |                       |
--    |    |   |  nel |  kernel_buffer   |   |        |                       |
--    |    |  ker buf |                  |   |        |                       |
--    |    |  nel  |  |                  |   |        |                       |
--    |        |  ----+------------------+   |        |                       |
--    |   img  |      |                      |        |                       |
--        buf  |      |      kernel          |        |                       |
--   img      --------+----------------------+        |                       |
--  height |          |                               |                       |
--         |          |       image buffer            |                       |
--    |    |          |                               |                       |
--    |  -------------+-------------------------------+                       |
--    |               |                                                       |
--    |               |                                                       |
--    |               |                       image                           |
--    |               |                                                       |
--    |               |                                                       |
--   -----------------+-------------------------------------------------------+
--==============================================================================

--==============================================================================
LIBRARY std;    USE std.textio.all;                     -- for Text
LIBRARY ieee;   USE ieee.std_logic_1164.all;
                --USE ieee.std_logic_textio.all;          -- for Text
                --USE ieee.std_logic_unsigned.all;        -- for unsigned
                --USE ieee.std_logic_arith.conv_std_logic_vector;
                USE ieee.numeric_std.all;               -- for sfixed
                USE ieee.math_real.all;
                --USE ieee.fixed_pkg.all;
--==============================================================================

--==============================================================================
PACKAGE pkgConstNpuConv2d IS

  ------------------------------------------------------------------------------
  -- Constant
  ------------------------------------------------------------------------------
  -- IMAGE
  CONSTANT IMAGE_WIDTH            : NATURAL :=     8;  -- Image Width, Real  -> convert to a variable later
  CONSTANT IMAGE_HEIGHT           : NATURAL :=     8;  -- Image Height, Real -> convert to a variable later
  CONSTANT IMAGE_BUF_WIDTH        : NATURAL :=    14;  -- Image Buffer Width,  HW
  CONSTANT IMAGE_BUF_HEIGHT       : NATURAL :=    14;  -- Image Buffer Height, HW
  CONSTANT IMAGE_BUF_BITSIZE      : NATURAL :=    32;  -- Image Buffer Element Bit Size (32-bit 2's complement)
  CONSTANT IMAGE_BUF_WIDTH_BITSIZE  : NATURAL :=   8;
  CONSTANT IMAGE_BUF_HEIGHT_BITSIZE : NATURAL :=   8;
  --CONSTANT IMAGE_BUF_WIDTH_BITSIZE  : POSITIVE := POSITIVE(ceil(log2(real(IMAGE_BUF_WIDTH+1))));
  --CONSTANT IMAGE_BUF_HEIGHT_BITSIZE : POSITIVE := POSITIVE(ceil(log2(real(IMAGE_BUF_HEIGHT+1))));

  -- KERNEL
  CONSTANT KERNEL_ORDER           : NATURAL :=     0;  -- Kernel Buffer Order, 0=Normal, 1=Inverse
  CONSTANT KERNEL_WIDTH           : NATURAL :=     3;  -- Kernel Width,  Real -> convert to a variable later
  CONSTANT KERNEL_HEIGHT          : NATURAL :=     3;  -- Kernel Height, Real -> convert to a variable later
  CONSTANT KERNEL_BUF_WIDTH       : NATURAL :=     7;  -- Kernel Buffer Width,  HW
  CONSTANT KERNEL_BUF_HEIGHT      : NATURAL :=     7;  -- Kernel Buffer Height, HW
  CONSTANT KERNEL_BUF_BITSIZE     : NATURAL :=    32;  -- Kernel Buffer Element Bit Size (32-bit 2's complement)
  CONSTANT KERNEL_BUF_WIDTH_BITSIZE  : NATURAL :=  8;
  CONSTANT KERNEL_BUF_HEIGHT_BITSIZE : NATURAL :=  8;
  --CONSTANT KERNEL_BUF_WIDTH_BITSIZE  : POSITIVE := POSITIVE(ceil(log2(real(KERNEL_BUF_WIDTH+1))));
  --CONSTANT KERNEL_BUF_HEIGHT_BITSIZE : POSITIVE := POSITIVE(ceil(log2(real(KERNEL_BUF_HEIGHT+1))));

  -- PADDING
  CONSTANT PADDING                : NATURAL :=     0;  -- Padding Amount; 0=Off;
  CONSTANT PADDING_TYPE           : NATURAL :=     0;  -- Padding Type (TBD)

  -- STRIDE
  CONSTANT STRIDE_WIDTH           : NATURAL :=     1;  -- Stride Width (TBD)
  CONSTANT STRIDE_HEIGHT          : NATURAL :=     1;  -- Stride Height (TBD)

  -- OUTPUT : O = floor{ ( image + 2 x padding - kernel ) / stride } + 1
  CONSTANT OUTPUT_WIDTH           : POSITIVE := POSITIVE( floor( ( real(IMAGE_WIDTH     ) +(2.0)*real(PADDING) -real(KERNEL_WIDTH     ) ) / real(STRIDE_WIDTH ) ) +1.0 );
  CONSTANT OUTPUT_HEIGHT          : POSITIVE := POSITIVE( floor( ( real(IMAGE_HEIGHT    ) +(2.0)*real(PADDING) -real(KERNEL_HEIGHT    ) ) / real(STRIDE_HEIGHT) ) +1.0 );
  --CONSTANT OUTPUT_BUF_WIDTH       : POSITIVE := POSITIVE( floor( ( real(IMAGE_BUF_WIDTH ) +(2.0)*real(PADDING) -real(KERNEL_BUF_WIDTH ) ) / real(STRIDE_WIDTH ) ) +1.0 );
  CONSTANT OUTPUT_BUF_HEIGHT      : POSITIVE := POSITIVE( floor( ( real(IMAGE_BUF_HEIGHT) +(2.0)*real(PADDING) -real(KERNEL_BUF_HEIGHT) ) / real(STRIDE_HEIGHT) ) +1.0 );
  CONSTANT OUTPUT_BUF_WIDTH       : NATURAL := 8;
  CONSTANT OUTPUT_BUF_BITSIZE     : NATURAL := IMAGE_BUF_BITSIZE;
  CONSTANT OUTPUT_BUF_WIDTH_BITSIZE : POSITIVE := IMAGE_BUF_BITSIZE + KERNEL_BUF_BITSIZE + INTEGER(ceil(log2(real(IMAGE_BUF_WIDTH)))) + INTEGER(ceil(log2(real(KERNEL_BUF_HEIGHT))));
  --CONSTANT OUTPUT_BUF_WIDTH_BITSIZE : POSITIVE := IMAGE_BUF_BITSIZE + KERNEL_BUF_BITSIZE + INTEGER(ceil(log2(real(KERNEL_BUF_WIDTH)))) + INTEGER(ceil(log2(real(KERNEL_BUF_HEIGHT))));
  --CONSTANT variableName   : POSITIVE := POSITIVE(ceil(log2(real(variable2))));  -- bit size of variable2
  --CONSTANT variableName   : std_logic_vector( 7 downto 0) := "11110000";
  CONSTANT MAX_OUTPUT_NUM         : NATURAL :=     8; -- for Platform

  -- ADDER TREE 1
  CONSTANT ADD_TREE_NUM_INPUT     : NATURAL  := KERNEL_BUF_WIDTH; -- Number of input for adder tree
  CONSTANT ADD_TREE_BITSIZE_IN    : NATURAL  := 8;                -- Input bit size of adder tree
  CONSTANT ADD_TREE_NUM_STAGE     : POSITIVE := POSITIVE(ceil(log2(real(ADD_TREE_NUM_INPUT))));
  CONSTANT ADD_TREE_BITSIZE_OUT   : NATURAL  := ADD_TREE_BITSIZE_IN + ADD_TREE_NUM_STAGE;

  ------------------------------------------------------------------------------
  -- Record Type
  ------------------------------------------------------------------------------
  --TYPE typeName IS RECORD
  --  item1  : INTEGER;
  --  item2  : INTEGER;
  --END RECORD;

  ------------------------------------------------------------------------------
  -- Function
  ------------------------------------------------------------------------------
  --FUNCTION afunctionName( aIn : in sfixed; aIpfTypeIn : in ipfType;
  --                        bIn : in sfixed; bIpfTypeIn : in ipfType;
  --                                         oIpfTypeIn : in ipfType) RETURN sfixed;

END PACKAGE;

PACKAGE BODY pkgConstNpuConv2d IS
  ------------------------------------------------------------------------------
  -- Function Body
  ------------------------------------------------------------------------------
  --FUNCTION afunctionName( aIn : in sfixed; aIpfTypeIn : in ipfType;
  --                        bIn : in sfixed; bIpfTypeIn : in ipfType;
  --                                         oIpfTypeIn : in ipfType) RETURN sfixed IS
  --  CONSTANT aSfixedType : fixedType := ipfType2FixedType(aIpfTypeIn);
  --  CONSTANT bSfixedType : fixedType := ipfType2FixedType(bIpfTypeIn);
  --  CONSTANT cSfixedType : fixedType := ipfType2FixedType(cIpfTypeIn);
  --  VARIABLE aSfixed     : sfixed(aSfixedType.fixedLeft downto aSfixedType.fixedRight);
  --  VARIABLE bSfixed     : sfixed(bSfixedType.fixedLeft downto bSfixedType.fixedRight);
  --  VARIABLE tmpSfixed   : sfixed((aSfixed'high + bSfixed'high +1) downto (aSfixed'low + bSfixed'low));
  --  variable cSfixed     : sfixed(cSfixedType.fixedLeft downto cSfixedType.fixedRight);
  --BEGIN
  --  tmpSfixed := aIn * bIn;
  --  cSfixed := resize(tmpSfixed, cSfixed);
  --  RETURN cSfixed;
  --END afunctionName;
  ------------------------------------------------------------------------------
END PACKAGE BODY;
--==============================================================================
