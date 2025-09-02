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
-- File Name : pkgTypeNpuConv2d.vhd
--==============================================================================
-- Rev.      Des.    Function
-- V210000   hkim    Package for pkgTypeNpuConv2d
--==============================================================================

--==============================================================================
LIBRARY std;    USE std.textio.all;
LIBRARY ieee;   USE ieee.std_logic_1164.all;
                USE ieee.numeric_std.all;
                USE ieee.math_real.all;
LIBRARY work;   USE work.pkgConstNpuConv2d.all;
--==============================================================================

--==============================================================================
PACKAGE pkgTypeNpuConv2d IS
  ------------------------------------------------------------------------------
  -- Arrays
  TYPE imgBufArrayType    IS ARRAY (NATURAL RANGE<>) OF std_logic_vector(IMAGE_BUF_BITSIZE-1  downto 0);
  TYPE kerBufArrayType    IS ARRAY (NATURAL RANGE<>) OF std_logic_vector(KERNEL_BUF_BITSIZE-1 downto 0);
  TYPE outBufArrayType    IS ARRAY (NATURAL RANGE<>) OF std_logic_vector(OUTPUT_BUF_BITSIZE-1 downto 0);
  TYPE bufSigArrayType    IS ARRAY (NATURAL RANGE<>) OF std_logic;
  -- 1D Arrays
  TYPE imgBufArray1DType  IS ARRAY (NATURAL RANGE<>) OF imgBufArrayType(0 TO IMAGE_BUF_WIDTH-1);
  TYPE kerBufArray1DType  IS ARRAY (NATURAL RANGE<>) OF kerBufArrayType(0 TO KERNEL_BUF_WIDTH-1);
  ------------------------------------------------------------------------------
END PACKAGE;
--============================================================================

--============================================================================
PACKAGE BODY pkgTypeNpuConv2d IS
END PACKAGE BODY;
--==============================================================================
