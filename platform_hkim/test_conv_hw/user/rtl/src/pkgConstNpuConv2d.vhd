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
-- V250818   hkim    Package for pkgConstNpuConv2d
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
                USE ieee.numeric_std.all;
                USE ieee.math_real.all;
--==============================================================================

--==============================================================================
PACKAGE pkgConstNpuConv2d IS

  ------------------------------------------------------------------------------
  -- Constant
  ------------------------------------------------------------------------------
  -- IMAGE
  CONSTANT IMAGE_BUF_WIDTH        : NATURAL :=     8;  -- Image Buffer Width,  HW
  CONSTANT IMAGE_BUF_HEIGHT       : NATURAL :=     8;  -- Image Buffer Height, HW
  CONSTANT IMAGE_BUF_BITSIZE      : NATURAL :=    32;  -- Image Buffer Element Bit Size (32-bit 2's complement)

  CONSTANT IMAGE_WIDTH            : NATURAL :=     8;  -- Image Width, Real  -> convert to a variable later
  CONSTANT IMAGE_HEIGHT           : NATURAL :=     8;  -- Image Height, Real -> convert to a variable later
  CONSTANT IMAGE_BUF_WIDTH_BITSIZE  : NATURAL :=   8;
  CONSTANT IMAGE_BUF_HEIGHT_BITSIZE : NATURAL :=   8;

  -- KERNEL
  CONSTANT KERNEL_BUF_WIDTH       : NATURAL :=     3;  -- Kernel Buffer Width,  HW
  CONSTANT KERNEL_BUF_HEIGHT      : NATURAL :=     3;  -- Kernel Buffer Height, HW
  CONSTANT KERNEL_BUF_BITSIZE     : NATURAL :=    32;  -- Kernel Buffer Element Bit Size (32-bit 2's complement)

  CONSTANT KERNEL_ORDER           : NATURAL :=     0;  -- Kernel Buffer Order, 0=Normal, 1=Inverse
  CONSTANT KERNEL_WIDTH           : NATURAL :=     3;  -- Kernel Width,  Real -> convert to a variable later
  CONSTANT KERNEL_HEIGHT          : NATURAL :=     3;  -- Kernel Height, Real -> convert to a variable later
  CONSTANT KERNEL_BUF_WIDTH_BITSIZE  : NATURAL :=  8;
  CONSTANT KERNEL_BUF_HEIGHT_BITSIZE : NATURAL :=  8;

  -- OUTPUT : O = floor{ ( image + 2 x padding - kernel ) / stride } + 1
  CONSTANT OUTPUT_BUF_WIDTH       : NATURAL :=     8;
  CONSTANT OUTPUT_BUF_BITSIZE     : NATURAL := IMAGE_BUF_BITSIZE;
  CONSTANT MAX_OUTPUT_NUM         : NATURAL :=     8; -- for Platform

  -- PADDING
  CONSTANT PADDING                : NATURAL :=     0;  -- Padding Amount; 0=Off;
  CONSTANT PADDING_TYPE           : NATURAL :=     0;  -- Padding Type (TBD)

  -- STRIDE
  CONSTANT STRIDE_WIDTH           : NATURAL :=     1;  -- Stride Width (TBD)
  CONSTANT STRIDE_HEIGHT          : NATURAL :=     1;  -- Stride Height (TBD)

  CONSTANT OUTPUT_WIDTH           : POSITIVE := POSITIVE( floor( ( real(IMAGE_WIDTH     ) +(2.0)*real(PADDING) -real(KERNEL_WIDTH     ) ) / real(STRIDE_WIDTH ) ) +1.0 );
  CONSTANT OUTPUT_HEIGHT          : POSITIVE := POSITIVE( floor( ( real(IMAGE_HEIGHT    ) +(2.0)*real(PADDING) -real(KERNEL_HEIGHT    ) ) / real(STRIDE_HEIGHT) ) +1.0 );
  CONSTANT OUTPUT_BUF_HEIGHT      : POSITIVE := POSITIVE( floor( ( real(IMAGE_BUF_HEIGHT) +(2.0)*real(PADDING) -real(KERNEL_BUF_HEIGHT) ) / real(STRIDE_HEIGHT) ) +1.0 );
  CONSTANT OUTPUT_BUF_WIDTH_BITSIZE : POSITIVE := IMAGE_BUF_BITSIZE + KERNEL_BUF_BITSIZE + INTEGER(ceil(log2(real(IMAGE_BUF_WIDTH)))) + INTEGER(ceil(log2(real(KERNEL_BUF_HEIGHT))));

  -- ADDER TREE 1
  CONSTANT ADD_TREE_NUM_INPUT     : NATURAL  := KERNEL_BUF_WIDTH; -- Number of input for adder tree
  CONSTANT ADD_TREE_BITSIZE_IN    : NATURAL  := 8;                -- Input bit size of adder tree
  CONSTANT ADD_TREE_NUM_STAGE     : POSITIVE := POSITIVE(ceil(log2(real(ADD_TREE_NUM_INPUT))));
  CONSTANT ADD_TREE_BITSIZE_OUT   : NATURAL  := ADD_TREE_BITSIZE_IN + ADD_TREE_NUM_STAGE;
  ------------------------------------------------------------------------------
END PACKAGE;

PACKAGE BODY pkgConstNpuConv2d IS
END PACKAGE BODY;
--==============================================================================
