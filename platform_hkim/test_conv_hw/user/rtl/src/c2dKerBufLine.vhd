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
-- File Name : c2dKerBufLine.vhd
--==============================================================================
-- Rev.       Des.  Function
-- V241202    hkim  Kernel Line Buffer
-- V241226    hkim  port kerBufRdEn is added
--==============================================================================

--==============================================================================
LIBRARY ieee;   USE ieee.std_logic_1164.all;
                USE ieee.numeric_std.all;
                USE ieee.math_real.all;
LIBRARY work;   USE work.pkgConstNpuConv2d.all;
                USE work.pkgTypeNpuConv2d.all;
                USE work.pkgFuncNpuConv2d.all;
--==============================================================================

--==============================================================================
ENTITY c2dKerBufLine IS
GENERIC(
  numOfInput      : NATURAL := 8;   -- number of input    , KERNEL_BUF_WIDTH
  sizeOfBitIn     : NATURAL := 8    -- bit size of input  , KERNEL_BUF_BITSIZE
);
PORT(
  kerBufFull      : out std_logic;
  kerBufLineOut   : out std_logic_vector(numOfInput*sizeOfBitIn-1 downto 0);
  kerBufInit      : in  std_logic;
  kerBufLdEn      : in  std_logic;
  kerBufRdEn      : in  std_logic;
  kerBufLineIn    : in  std_logic_vector(           sizeOfBitIn-1 downto 0);
  clk             : in  std_logic;
  resetB          : in  std_logic
);
END;
--==============================================================================

--==============================================================================
ARCHITECTURE rtl OF c2dKerBufLine IS
  ------------------------------------------------------------------------------
  -- COMPONENT DECLARATION
  ------------------------------------------------------------------------------
  -- COMPONENT END

  ------------------------------------------------------------------------------
  -- SIGNAL DECLARATION
  ------------------------------------------------------------------------------
  SIGNAL kernelBufI   : kerBufArrayType(0 TO numOfInput-1);
  SIGNAL elemCntI     : NATURAL RANGE 0 TO numOfInput-1;
  SIGNAL kernelFullI  : std_logic;
  CONSTANT  zeroSlv   : std_logic_vector(sizeOfBitIn-1 downto 0) :=(others=>'0');

BEGIN
  ------------------------------------------------------------------------------
  -- SIGNAL GENERATION
  ------------------------------------------------------------------------------
  -- END GENERATE

  ------------------------------------------------------------------------------
  -- SIGNAL CONNECTION
  ------------------------------------------------------------------------------
  kerBufFull  <=kernelFullI;
  -- END CONNECTION

  ------------------------------------------------------------------------------
  -- PORT MAPPING
  ------------------------------------------------------------------------------
  -- END MAPPING

  ------------------------------------------------------------------------------
  -- PROCESSES
  ------------------------------------------------------------------------------
  kerBufP : PROCESS(all)
  BEGIN
    if resetB='0' then
      FOR i IN 0 TO numOfInput-1 LOOP kernelBufI <=(others=>zeroSlv); END LOOP;
    elsif rising_edge(clk) then
      if (kerBufInit) then  -- Initialization
        FOR i IN 0 TO numOfInput-1 LOOP kernelBufI <=(others=>zeroSlv); END LOOP;
      elsif (kerBufLdEn) then -- Load Kernel Data
        kernelBufI(numOfInput-1) <=kerBufLineIn;
        FOR i IN 0 TO (numOfInput-2) LOOP kernelBufI(i) <=kernelBufI(i+1); END LOOP;
      end if;
    end if;
  END PROCESS;

  elemCntIP : PROCESS(all)
  BEGIN
    if resetB='0' then elemCntI <=0;
    elsif (rising_edge(clk)) then
      if (kerBufInit) then elemCntI <=0;
      elsif (kerBufLdEn) then
        if elemCntI=numOfInput-1 then elemCntI <=0;
        else elemCntI <=elemCntI +1; end if;
      end if;
    end if;
  END PROCESS;

  kernelFullIP : PROCESS(all)
  BEGIN
    if resetB='0' then kernelFullI <='0';
    elsif (rising_edge(clk)) then
      if (kerBufInit) then kernelFullI <='0';
      elsif elemCntI=numOfInput-1 then kernelFullI <='1';
      end if;
    end if;
  END PROCESS;

  kerBufLineOutP : PROCESS(all)
  BEGIN
    if resetB='0' then kerBufLineOut <=(others=>'0');
    elsif rising_edge(clk) then
      if (kerBufRdEn) then
        kerBufLineOut <=arrayToVector( kernelBufI, numOfInput, sizeOfBitIn );
      end if;
    end if;
  END PROCESS;
  ------------------------------------------------------------------------------

  -- synthesis translate_off
  ------------------------------------------------------------------------------
  -- TDD
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- synthesis translate_on
END rtl;
--==============================================================================
