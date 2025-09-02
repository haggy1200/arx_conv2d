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
-- File Name : pkgFuncNpuConv2d.vhd
--==============================================================================
-- Rev.      Des.    Function
-- V210000   hkim    Package for pkgFuncNpuConv2d
--==============================================================================

--==============================================================================
LIBRARY std;    USE std.textio.all;
LIBRARY ieee;   USE ieee.std_logic_1164.all;
                USE ieee.numeric_std.all;
                USE ieee.math_real.all;
LIBRARY work;   USE work.pkgConstNpuConv2d.all;
                USE work.pkgTypeNpuConv2d.all;
--==============================================================================

--==============================================================================
PACKAGE pkgFuncNpuConv2d IS
  --============================================================================
  -- Function Declaration
  --============================================================================
  -- ARRAY-to-VECTOR (Overloaded)
  FUNCTION arrayToVector( arrayIn  : imgBufArrayType;  arraySize : NATURAL; elemWidth : POSITIVE) RETURN std_logic_vector;
  FUNCTION arrayToVector( arrayIn  : kerBufArrayType;  arraySize : NATURAL; elemWidth : POSITIVE) RETURN std_logic_vector;
  FUNCTION arrayToVector( arrayIn  : outBufArrayType;  arraySize : NATURAL; elemWidth : POSITIVE) RETURN std_logic_vector;
  -- VECTOR-To-ARRAY (Overloaded)
  FUNCTION vectorToArray( vectorIn : std_logic_vector; arraySize : NATURAL; elemWidth : POSITIVE) RETURN imgBufArrayType;
  FUNCTION vectorToArray( vectorIn : std_logic_vector; arraySize : NATURAL; elemWidth : POSITIVE) RETURN kerBufArrayType;
  FUNCTION vectorToArray( vectorIn : std_logic_vector; arraySize : NATURAL; elemWidth : POSITIVE) RETURN outBufArrayType;
  -- Power-of-Two Number
  FUNCTION getPowerOfTwo(numOfIn : NATURAL) RETURN NATURAL;
  -- Binary Tree Depth
  FUNCTION getTreeDepth(numOfIn  : NATURAL) RETURN NATURAL;
  -- Binary Tree Output Bit
  FUNCTION getTreeOutBitWidth(numOfIn : NATURAL; elemWidth : NATURAL) RETURN NATURAL;
  -- Bit Width Calculation
  FUNCTION getBitWidth(sizeIn : NATURAL) RETURN NATURAL;
  --============================================================================
END PACKAGE;

PACKAGE BODY pkgFuncNpuConv2d IS
  --============================================================================
  -- Function Body
  --============================================================================
  -- ARRAY-to-VECTOR : arrayIn -> vectorOut
  ------------------------------------------------------------------------------
  -- [elemWidth-1:0][elemWidth-1:0]...[elemWidth-1:0] --> [arraySize*elemWidth-1 : 0]
  -- oTemp( 1*elemWidth-1 downto           0 ) := arrayIn( arrayIn'LEFT   );
  -- oTemp( 2*elemWidth-1 downto 1*elemWidth ) := arrayIn( arrayIn'LEFT+1 );
  -- oTemp( 3*elemWidth-1 downto 2*elemWidth ) := arrayIn( arrayIn'LEFT+2 );
  -- ...
  -- Element 'arrayIn(arrayIn'LEFT)' is located to the LSB-side
  ------------------------------------------------------------------------------
  FUNCTION arrayToVector( arrayIn       : imgBufArrayType;                          -- input buffer array
                          arraySize     : NATURAL;
                          elemWidth     : POSITIVE) RETURN std_logic_vector IS
    VARIABLE vectorOut : std_logic_vector(arraySize*elemWidth-1 downto 0);
  BEGIN
    FOR i IN 0 TO arraySize-1 LOOP
      vectorOut((i+1)*elemWidth-1 downto i*elemWidth) := arrayIn(arrayIn'LEFT+i);
    END LOOP;
    RETURN vectorOut;
  END FUNCTION;

  FUNCTION arrayToVector( arrayIn       : kerBufArrayType;                          -- kernel buffer array
                          arraySize     : NATURAL;
                          elemWidth     : POSITIVE) RETURN std_logic_vector IS
    VARIABLE vectorOut : std_logic_vector(arraySize*elemWidth-1 downto 0);
  BEGIN
    FOR i IN 0 TO arraySize-1 LOOP
      vectorOut((i+1)*elemWidth-1 downto i*elemWidth) := arrayIn(arrayIn'LEFT+i);
    END LOOP;
    RETURN vectorOut;
  END FUNCTION;

  FUNCTION arrayToVector( arrayIn       : outBufArrayType;                          -- output buffer array
                          arraySize     : NATURAL;
                          elemWidth     : POSITIVE) RETURN std_logic_vector IS
    VARIABLE vectorOut : std_logic_vector(arraySize*elemWidth-1 downto 0);
  BEGIN
    FOR i IN 0 TO arraySize-1 LOOP
      vectorOut((i+1)*elemWidth-1 downto i*elemWidth) := arrayIn(arrayIn'LEFT+i);
    END LOOP;
    RETURN vectorOut;
  END FUNCTION;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- VECTOR-to-ARRAY : vectorIn -> arrayOut
  ------------------------------------------------------------------------------
  -- [arraySize*elemWidth-1:0] --> [elemtWidth-1:0][elemtWidth-1:0]...[elemtWidth-1:0]
  -- oTemp(0) := vectorIn( 1*elemWidth-1 downto   elemWidth );
  -- oTemp(1) := vectorIn( 2*elemWidth-1 downto 1*elemWidth );
  -- oTemp(2) := vectorIn( 3*elemWidth-1 downto 2*elemWidth );
  -- ...
  ------------------------------------------------------------------------------
  FUNCTION vectorToArray( vectorIn      : std_logic_vector;
                          arraySize     : NATURAL;
                          elemWidth     : POSITIVE) RETURN imgBufArrayType IS
    VARIABLE arrayOut : imgBufArrayType(0 to arraySize-1);
  BEGIN
    FOR i IN 0 to arraySize-1 LOOP
      arrayOut(i) := vectorIn( (i+1)*elemWidth-1 downto i*elemWidth );
    END LOOP;
    RETURN arrayOut;
  END FUNCTION;

  FUNCTION vectorToArray( vectorIn      : std_logic_vector;
                          arraySize     : NATURAL;
                          elemWidth     : POSITIVE) RETURN kerBufArrayType IS
    VARIABLE arrayOut : kerBufArrayType(0 to arraySize-1);
  BEGIN
    FOR i IN 0 to arraySize-1 LOOP
      arrayOut(i) := vectorIn( (i+1)*elemWidth-1 downto i*elemWidth );
    END LOOP;
    RETURN arrayOut;
  END FUNCTION;

  FUNCTION vectorToArray( vectorIn      : std_logic_vector;
                          arraySize     : NATURAL;
                          elemWidth     : POSITIVE) RETURN outBufArrayType IS
    VARIABLE arrayOut : outBufArrayType(0 to arraySize-1);
  BEGIN
    FOR i IN 0 to arraySize-1 LOOP
      arrayOut(i) := vectorIn( (i+1)*elemWidth-1 downto i*elemWidth );
    END LOOP;
    RETURN arrayOut;
  END FUNCTION;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Power-of-2 Calculation
  ------------------------------------------------------------------------------
  FUNCTION getPowerOfTwo(numOfIn : NATURAL) RETURN NATURAL IS
    VARIABLE powerOfTwo : NATURAL;
  BEGIN
    if (numOfIn=0) then powerOfTwo := 1;
    else                powerOfTwo := POSITIVE(2**(log2(real(numOfIn)))); end if;
    RETURN powerOfTwo;
  END FUNCTION;

  ------------------------------------------------------------------------------
  -- Binary Tree Depth Calculation
  ------------------------------------------------------------------------------
  FUNCTION getTreeDepth(numOfIn : NATURAL) RETURN NATURAL IS
    VARIABLE treeDepth : NATURAL;
  BEGIN
    if (numOfIn=0) then treeDepth :=0;
    else                treeDepth :=POSITIVE(ceil(log2(real(numOfIn)))); end if;
    RETURN treeDepth;
  END FUNCTION;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Binary Tree Output Bit Width Calculation
  ------------------------------------------------------------------------------
  FUNCTION getTreeOutBitWidth(numOfIn : NATURAL; elemWidth : NATURAL) RETURN NATURAL IS
    VARIABLE treeOutBitWidth : NATURAL;
    VARIABLE treeDepth       : NATURAL;
  BEGIN
    if (numOfIn=0) then treeDepth :=0;
    else                treeDepth :=POSITIVE(ceil(log2(real(numOfIn)))); end if;
    if (numOfIn>0) then treeOutBitWidth := elemWidth + treeDepth;
    else                treeOutBitWidth := elemWidth; end if;
    RETURN treeOutBitWidth;
  END FUNCTION;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Bit Width Calculation
  ------------------------------------------------------------------------------
  FUNCTION getBitWidth(sizeIn : NATURAL) RETURN NATURAL IS
    VARIABLE bitWidth : NATURAL;
  BEGIN
    if (sizeIn=0) then bitWidth :=0;
    else               bitWidth :=POSITIVE(ceil(log2(real(sizeIn)))); end if;
    RETURN bitWidth;
  END FUNCTION;
  ------------------------------------------------------------------------------
  --============================================================================
END PACKAGE BODY;
--==============================================================================
