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
-- File Name : c2dImgBufLine.vhd
--==============================================================================
-- Rev.       Des.  Function
-- V241202    hkim  Image Line Buffer
-- V241223    hkim  port imgBufOutValid is added
-- V241224    hkim  process for imgBufRdEn is added
-- V241227    hkim  Code revision
-- V250106    hkim  imgBufOutValid is revised
-- V250114    hkim  Effect of imgBufRdEn is removed
--==============================================================================

--==============================================================================
LIBRARY ieee;   USE ieee.std_logic_1164.all;
                --USE ieee.std_logic_unsigned.all;
                --USE ieee.std_logic_arith.conv_std_logic_vector;
                USE ieee.numeric_std.all;                       -- shift_right(), shift_left()
                USE ieee.math_real.all;
                --USE ieee.fixed_pkg.all;
LIBRARY work;   USE work.pkgConstNpuConv2d.all;
                USE work.pkgTypeNpuConv2d.all;
                USE work.pkgFuncNpuConv2d.all;
--==============================================================================

--==============================================================================
ENTITY c2dImgBufLine IS
GENERIC(
  numOfInput      : NATURAL := 8;   -- number of input    , IMAGE_BUF_WIDTH
  sizeOfBitIn     : NATURAL := 8    -- bit size of input  , IMAGE_BUF_BITSIZE
);
PORT(
  imgBufFull      : out std_logic;
  imgBufEmpty     : out std_logic;
  imgBufOutValid  : out std_logic;
  imgBufLineOut   : out std_logic_vector(numOfInput*sizeOfBitIn-1 downto 0);
  imgBufInit      : in  std_logic;
  imgBufLdEn      : in  std_logic;
  imgBufRdEn      : in  std_logic;
  imgBufLineIn    : in  std_logic_vector(           sizeOfBitIn-1 downto 0);
  clk             : in  std_logic;
  resetB          : in  std_logic
);
END;
--==============================================================================

--==============================================================================
ARCHITECTURE rtl OF c2dImgBufLine IS
  ------------------------------------------------------------------------------
  -- COMPONENT DECLARATION
  ------------------------------------------------------------------------------
  -- COMPONENT END

  ------------------------------------------------------------------------------
  -- SIGNAL DECLARATION
  ------------------------------------------------------------------------------
  -- TYPE imgBufArrayType IS ARRAY (NATURAL RANGE<>) OF std_logic_vector(IMAGE_BUF_BITSIZE-1 downto 0);
  SIGNAL imageBufI    : imgBufArrayType(0 TO numOfInput-1);
  SIGNAL elemCntI     : NATURAL RANGE 0 TO IMAGE_BUF_WIDTH-1;
  SIGNAL imgBufFullI  : std_logic;
  SIGNAL imgBufEmptyI : std_logic;
  SIGNAL outValidI    : std_logic;  ---V241223
  CONSTANT  zeroSlv   : std_logic_vector(sizeOfBitIn-1 downto 0) :=(others=>'0');
  ---V241227 : SIGNAL elemCntI     : NATURAL RANGE 0 TO numOfInput-1;

BEGIN
  ------------------------------------------------------------------------------
  -- SIGNAL GENERATION
  ------------------------------------------------------------------------------
  -- END GENERATE

  ------------------------------------------------------------------------------
  -- SIGNAL CONNECTION
  ------------------------------------------------------------------------------
  imgBufFull  <=imgBufFullI;
  imgBufEmpty <=imgBufEmptyI;
  imgBufOutValid  <=outValidI; ---V250106
  ---V250106 : imgBufOutValid  <=outValidI OR imgBufFullI; ---V241227
  ---V241227 : imgBufOutValid  <=outValidI;  ---V241223
  -- END CONNECTION

  ------------------------------------------------------------------------------
  -- PORT MAPPING
  ------------------------------------------------------------------------------
  -- END MAPPING

  ------------------------------------------------------------------------------
  -- PROCESSES
  ------------------------------------------------------------------------------
  imgBufP : PROCESS(all)
  BEGIN
    if resetB='0' then
      FOR i IN 0 TO numOfInput-1 LOOP imageBufI <=(others=>zeroSlv); END LOOP;
    elsif rising_edge(clk) then
      if (imgBufInit) then  -- Initialization
        FOR i IN 0 TO numOfInput-1 LOOP imageBufI <=(others=>zeroSlv); END LOOP;
      elsif (imgBufLdEn) then -- Load Kernel Data, V250114
        imageBufI(numOfInput-1) <=imgBufLineIn;
        FOR i IN 0 TO (numOfInput-2) LOOP imageBufI(i) <=imageBufI(i+1); END LOOP;
      end if;
    end if;
  END PROCESS;
      ---V250114 : elsif (imgBufLdEn OR imgBufRdEn) then -- Load Kernel Data, V241227
      ---V241227 : elsif (imgBufLdEn) then -- Load Kernel Data
      ---V241223 : elsif (imgBufRdEn) then -- Array to Vector
      ---V241223 :   imgBufLineOut <=arrayToVector( imageBufI, numOfInput, sizeOfBitIn );

  elemCntIP : PROCESS(all)
  BEGIN
    if resetB='0' then elemCntI <=0;
    elsif (rising_edge(clk)) then
      if (imgBufInit) then elemCntI <=0;
      elsif (imgBufLdEn) then -- increase, V250114
        if elemCntI=IMAGE_BUF_WIDTH-1 then elemCntI <=0;  ---V241227
        else elemCntI <=elemCntI +1; end if;
      end if;
    end if;
  END PROCESS;
      ---V250114 : elsif (imgBufLdEn OR imgBufRdEn) then -- increase, V241227
        ---V241227 : if elemCntI=numOfInput-1 then elemCntI <=0;
      ---V241227 : elsif (imgBufLdEn) then -- increase
      ---V241223 : elsif (imgBufRdEn) then -- decrease
      ---V241223 :   if elemCntI=0 then elemCntI <=numOfInput-1;
      ---V241223 :   else elemCntI <=elemCntI -1; end if;

  ---V231223
  imgBufLineOutP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufLineOut <=(others=>'0');
    elsif rising_edge(clk) then
      if (imgBufRdEn) then
          imgBufLineOut <=arrayToVector( imageBufI, numOfInput, sizeOfBitIn );
      end if;
    end if;
  END PROCESS;
        ---V241227 : if (elemCntI > KERNEL_BUF_WIDTH-1) then
        ---V241227 : end if;

  ---V250114
  outValidIP : PROCESS(all)
  BEGIN
    if resetB='0' then outValidI <='0';
    elsif rising_edge(clk) then
      outValidI <=imgBufRdEn;
    end if;
  END PROCESS;
  ---V250114 : ---V241223
  ---V250114 : outValidIP : PROCESS(all)
  ---V250114 : BEGIN
  ---V250114 :   if resetB='0' then outValidI <='0';
  ---V250114 :   elsif rising_edge(clk) then
  ---V250114 :     if (imgBufRdEn) then
  ---V250114 :       if (elemCntI > KERNEL_BUF_WIDTH-1) then outValidI <='1';
  ---V250114 :       else outValidI <='0'; end if;
  ---V250114 :     else outValidI <='0'; end if;
  ---V250114 :   end if;
  ---V250114 : END PROCESS;

  imgBufFullEmptyP : PROCESS(all)
  BEGIN
    ---V241227
    if elemCntI > KERNEL_BUF_WIDTH-1 then imgBufFullI <='1'; imgBufEmptyI <='0';
    else                                  imgBufFullI <='0'; imgBufEmptyI <='1'; end if;
    ---V241227 : if elemCntI=KERNEL_BUF_WIDTH-1 then
    ---V241227 :   if (imgBufLdEn='1') then imgBufFullI <='0'; imgBufEmptyI <='0'; -- To Be Revised
    ---V241227 :   else                     imgBufFullI <='1'; imgBufEmptyI <='0';
    ---V241227 :   end if;
    ---V241227 : else imgBufFullI <='0'; imgBufEmptyI <='1'; end if;
  END PROCESS;
      ---V241223 : if (imgBufLdEn='1') AND (imgBufRdEn='1') then imgBufFullI <='0'; imgBufEmptyI <='0';
  --imgBufFullEmptyP : PROCESS(all)
  --BEGIN
  --  if resetB='0' then imgBufFullI <='0'; imgBufEmptyI <='0';
  --  elsif (rising_edge(clk)) then
  --    if (imgBufInit) then imgBufFullI <='0'; imgBufEmptyI <='0';
  --    elsif elemCntI=KERNEL_BUF_WIDTH-1 then
  --      if (imgBufLdEn='1') AND (imgBufRdEn='1') then imgBufFullI <='0'; imgBufEmptyI <='0';
  --      else                                            imgBufFullI <='1'; imgBufEmptyI <='0';
  --      end if;
  --    else imgBufFullI <='0'; imgBufEmptyI <='1';
  --    end if;
  --  end if;
  --END PROCESS;

  ------------------------------------------------------------------------------

  -- synthesis translate_off
  ------------------------------------------------------------------------------
  -- TDD
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- synthesis translate_on
END rtl;
--==============================================================================
