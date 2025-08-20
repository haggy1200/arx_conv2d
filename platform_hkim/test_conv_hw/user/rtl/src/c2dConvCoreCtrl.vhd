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
-- File Name : c2dConvCoreCtrl.vhd
--==============================================================================
-- Rev.       Des.  Function
-- V250109    hkim  Function Description
-- V250114    hkim  Timing is tuned
--                  port convCoreEnd is added
-- V250115    hkim  output number claculation is revised
-- V250116    hkim  Variables for HW and SW are distingushed clearly
--                  KERNEL_WIDTH, KERNEL_HEIGHT, IMAGE_WIDTH, IMAGE_HEIGHT are changed to input port
-- V250117    hkim  Output height number counter is added
-- V250120    hkim  State 'ker*' and 'img*' are combined
-- V250530    hkim  Clean up the unused code
-- V250602    hkim  End of 2DConv is added
-- V250818    hkim  MAX_OUTPUT_NUM is applied for the Platform
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
ENTITY c2dConvCoreCtrl IS
PORT(
  endOfConv2D     : out std_logic;  ---V250602
  extraOutEn      : out std_logic;  ---V250818
  kerBufInit      : out std_logic;
  kerBufLdEn      : out std_logic;
  kerBufRdEn      : out std_logic;
  imgBufInit      : out std_logic;
  imgBufLdEn      : out std_logic;
  imgBufRdEn      : out std_logic;
  addTreeEn       : out std_logic;  -- TBD
  outHeightCnt    : out std_logic_vector(IMAGE_BUF_HEIGHT_BITSIZE-1 downto 0);  ---V250117
  npuStart        : in  std_logic;  -- NPU Start
  convCoreEnd     : in  std_logic;  ---V250114
  convCoreValid   : in  std_logic;
  imgBufFull      : in  std_logic;
  imgBufEmpty     : in  std_logic;
  kerBufFull      : in  std_logic;
  kernelWidth     : in  std_logic_vector(KERNEL_BUF_WIDTH_BITSIZE-1 downto 0);  ---V250116 : START
  kernelHeight    : in  std_logic_vector(KERNEL_BUF_HEIGHT_BITSIZE-1 downto 0);
  imageWidth      : in  std_logic_vector(IMAGE_BUF_WIDTH_BITSIZE-1 downto 0);
  imageHeight     : in  std_logic_vector(IMAGE_BUF_HEIGHT_BITSIZE-1 downto 0);  ---V250116 : END
  clk             : in  std_logic;
  resetB          : in  std_logic
);
END;
--==============================================================================

--==============================================================================
ARCHITECTURE rtl OF c2dConvCoreCtrl IS
  ------------------------------------------------------------------------------
  -- COMPONENT DECLARATION
  ------------------------------------------------------------------------------
  -- COMPONENT END

  ------------------------------------------------------------------------------
  -- SIGNAL DECLARATION
  ------------------------------------------------------------------------------
  -- FSM Example
  TYPE CTRL_STT_MAIN IS (
    idleStt,                        -- IDLE State
    waitStartStt,                   -- Wait 2D Conv NPU Start State
    calcOutNumStt,                  -- Output Number Calculation State, V250116

    imgBufInitStt,                  -- Image Buffer Initialization State
    imgBufLdStt,                    -- Image BUffer Load State

    waitDoneStt,                    -- Wait Done State
    calcParaStt,                    -- Parameter calculation state, V250117
    chkEndStt,                      -- Check End State
    extraChkStt,                    -- Extra Check State, V250818
    extraOutStt,                    -- Extra Output State, V250818

    restStt,                        -- Rest State
    postStt                         -- Post State
  );
  SIGNAL  ctrlMainSttI    : CTRL_STT_MAIN;
    ---V250120 : kerBufInitStt,                  -- Kernel Buffer Initialization State
    ---V250120 : kerBufLdStt,                    -- Kernel Buffer Data Load State
    ---V250120 : kerBufLdEndStt,                 -- Kernel Buffer Load End State
    --imgBufRdStt,                    -- Image Buffer Data Read State

  ---V250530 : CONSTANT OUTNUM_WIDTH : NATURAL := IMAGE_WIDTH - KERNEL_WIDTH + 1;  ---V250116
  ---V250530 : CONSTANT OUTNUM_HEIGHT: NATURAL := IMAGE_HEIGHT- KERNEL_HEIGHT+ 1;  ---V250117
  ---V250116 : CONSTANT OUTNUM_WIDTH : NATURAL := IMAGE_BUF_WIDTH - KERNEL_WIDTH + 1;  ---V250115
  ---V250115 : CONSTANT OUTNUM_WIDTH : NATURAL := IMAGE_BUF_WIDTH - KERNEL_BUF_WIDTH + 1;

  SIGNAL  kerBufInitI     : std_logic;
  SIGNAL  kerBufLdStartI  : std_logic;
  SIGNAL  kerBufLdEnI     : std_logic;
  SIGNAL  kerBufLdCntI    : NATURAL RANGE 0 TO KERNEL_BUF_WIDTH-1;
  SIGNAL  kerBufLdEndI    : std_logic;
  SIGNAL  kerBufRdEnI     : std_logic;
  SIGNAL  imgBufInitI     : std_logic;
  SIGNAL  imgBufLdStartI  : std_logic;
  SIGNAL  imgBufLdEnI     : std_logic;
  SIGNAL  imgBufLdCntI    : NATURAL RANGE 0 TO IMAGE_BUF_WIDTH; ---V250114
  SIGNAL  imgBufLdEndI    : std_logic;
  SIGNAL  imgBufRdStartI  : std_logic;
  SIGNAL  imgBufRdEnI     : std_logic;
  SIGNAL  imgBufRdCntI    : NATURAL RANGE 0 TO IMAGE_BUF_WIDTH; ---V250116
  SIGNAL  imgBufRdEndI    : std_logic;
  SIGNAL  addTreeEnI      : std_logic;
  SIGNAL  outNumWidthI    : NATURAL RANGE 0 TO IMAGE_BUF_WIDTH; ---V250114
  SIGNAL  outNumHeightI   : NATURAL RANGE 0 TO IMAGE_BUF_HEIGHT; ---V250117
  SIGNAL  outHeightCntI   : NATURAL RANGE 0 TO IMAGE_BUF_HEIGHT; ---V250117
  SIGNAL  endOfConv2DI    : std_logic;                          ---V250602
  SIGNAL  extraOutEnI     : std_logic;                          ---V250818
  ---V250116 : SIGNAL  imgBufRdCntI    : NATURAL RANGE 0 TO OUTNUM_WIDTH;
  ---V250114 : SIGNAL  imgBufLdCntI    : NATURAL RANGE 0 TO IMAGE_BUF_WIDTH-1;

  -- SIGNAL END

BEGIN
  ------------------------------------------------------------------------------
  -- SIGNAL GENERATION
  ------------------------------------------------------------------------------
  -- END GENERATE

  ------------------------------------------------------------------------------
  -- SIGNAL CONNECTION
  ------------------------------------------------------------------------------
  endOfConv2D     <=endOfConv2DI; ---V250602
  extraOutEn      <=extraOutEnI;  ---V250818
  -- Kernel Buffer
  kerBufInit      <=kerBufInitI;
  kerBufLdEn      <=kerBufLdEnI;
  kerBufRdEn      <=kerBufRdEnI;
  -- Image Buffer
  imgBufInit      <=imgBufInitI;
  imgBufLdEn      <=imgBufLdEnI;
  imgBufRdEn      <=imgBufRdEnI;
  addTreeEn       <=addTreeEnI;
  outHeightCnt    <=std_logic_vector(to_unsigned(outHeightCntI, IMAGE_BUF_HEIGHT_BITSIZE));  ---V250117
  -- END CONNECTION

  ------------------------------------------------------------------------------
  -- PORT MAPPING
  ------------------------------------------------------------------------------
  -- END MAPPING

  ------------------------------------------------------------------------------
  -- PROCESSES
  ------------------------------------------------------------------------------
  mainFsmP : PROCESS(all)
  BEGIN
    if resetB='0' then  ctrlMainSttI <=idleStt;
    elsif rising_edge(clk) then

      case ctrlMainSttI is

        when  idleStt           => ctrlMainSttI <=waitStartStt;       -- IDLE State

        when  waitStartStt      =>
                if npuStart='1' then ctrlMainSttI <=calcOutNumStt;    -- Wait 2D Conv NPU Start State, V250116
                else                 ctrlMainSttI <=waitStartStt;
                end if;
                ---V250116 : if npuStart='1' then ctrlMainSttI <=kerBufInitStt;    -- Wait 2D Conv NPU Start State

        when  calcOutNumStt     => ctrlMainSttI <=imgBufInitStt;      -- Output Number Calculation State, V250120
        ---V250120 : when  calcOutNumStt     => ctrlMainSttI <=kerBufInitStt;      -- Output Number Calculation State, V250116

        ---V250120 : when  kerBufInitStt     => ctrlMainSttI <=kerBufLdStt;        -- Kernel Buffer Initialization State

        ---V250120 : when  kerBufLdStt       =>                                    -- Kernel Buffer Load State
        ---V250120 :         if kerBufLdCntI=to_integer(unsigned(kernelWidth))-1 then ctrlMainSttI <=kerBufLdEndStt;  ---V250116
        ---V250120 :         else                                                     ctrlMainSttI <=kerBufLdStt;
        ---V250120 :         end if;
        ---V250120 :         ---V250116 : if kerBufLdCntI=KERNEL_WIDTH-1 then ctrlMainSttI <=kerBufLdEndStt;  ---V250115
        ---V250120 :         ---V250115 : if kerBufLdCntI=KERNEL_BUF_WIDTH-1 then ctrlMainSttI <=kerBufLdEndStt;

        ---V250120 : when  kerBufLdEndStt    => ctrlMainSttI <=imgBufInitStt;      -- Kernel Buffer Load End State

        when  imgBufInitStt     => ctrlMainSttI <=imgBufLdStt;        -- Image Buffer Initialization State

        when  imgBufLdStt       =>                                    -- Image BUffer Initial Load State
                if imgBufLdCntI=to_integer(unsigned(imageWidth))-1 then ctrlMainSttI <=waitDoneStt;  ---V250116
                else                                                    ctrlMainSttI <=imgBufLdStt;
                end if;
                ---V250116 : if imgBufLdCntI=IMAGE_WIDTH-1 then ctrlMainSttI <=waitDoneStt;  ---V250116
                ---V250116 : if imgBufLdCntI=IMAGE_BUF_WIDTH-1 then ctrlMainSttI <=waitDoneStt;

        --when  imgBufRdStt       => ctrlMainSttI <=waitDoneStt;        -- Image Buffer Data Read State
        --        if imgBufLdCntI=IMAGE_BUF_WIDTH-1 then ctrlMainSttI <=waitDoneStt;  -- to be revised(output number)
        --        else                                   ctrlMainSttI <=imgBufRdStt;
        --        end if;

        when  waitDoneStt       => ---V250114 : ctrlMainSttI <=chkEndStt;          -- Wait Done State
                if convCoreEnd='1' then ctrlMainSttI <=calcParaStt;   ---V250117
                else                    ctrlMainSttI <=waitDoneStt;
                end if;                                               ---V250114 : END
                ---V250117 : if convCoreEnd='1' then ctrlMainSttI <=chkEndStt;     ---V250114 : START

        when  calcParaStt       => ctrlMainSttI <=chkEndStt;          -- Parameter calculation state, V250117

        when  chkEndStt         => ---V250117 : ctrlMainSttI <=restStt;            -- Check End State
                if outHeightCntI=outNumHeightI then ctrlMainSttI <=extraChkStt;   ---V250818
                else                                ctrlMainSttI <=imgBufInitStt; ---V250120
                end if;
                ---V250818 : if outHeightCntI=outNumHeightI then ctrlMainSttI <=restStt;       ---V250117
                ---V250120 : else                                ctrlMainSttI <=kerBufInitStt; ---V250117

        ---V250818
        when  extraChkStt       =>
                if outHeightCntI=MAX_OUTPUT_NUM then ctrlMainSttI <=restStt;
                else                                 ctrlMainSttI <=extraOutStt; end if;

        when  extraOutStt       => ctrlMainSttI <=extraChkStt;

        when  restStt           => ctrlMainSttI <=postStt;            -- Rest State
        when  postStt           => ctrlMainSttI <=idleStt;            -- Post State

      end case;
    end if;
  END PROCESS;

  ---V250116
  outNumWidthIP : PROCESS(all)
  BEGIN
    if resetB='0' then outNumWidthI <=0;
                       outNumHeightI <=0; ---V250117
    elsif rising_edge(clk) then
      if ctrlMainSttI=calcOutNumStt then
        outNumWidthI <=to_integer(unsigned(imageWidth)) - to_integer(unsigned(kernelWidth)) + 1;
        outNumHeightI <=to_integer(unsigned(imageHeight)) - to_integer(unsigned(kernelHeight)) + 1; ---V250117
      end if;
    end if;
  END PROCESS;
        ---V250116 : outNumWidthI <=IMAGE_WIDTH - KERNEL_WIDTH + 1;

  ---V250120 : -- Kernel Buffer Initialization
  ---V250120 : kerBufInitIP : PROCESS(all)
  ---V250120 : BEGIN
  ---V250120 :   if resetB='0' then kerBufInitI <='0';
  ---V250120 :   elsif rising_edge(clk) then
  ---V250120 :     if ctrlMainSttI=kerBufInitStt then kerBufInitI <='1';
  ---V250120 :     else                               kerBufInitI <='0'; end if;
  ---V250120 :   end if;
  ---V250120 : END PROCESS;

  ---V250120 : -- Kernel Buffer Load Start
  ---V250120 : kerBufLdStartIP : PROCESS(all)
  ---V250120 : BEGIN
  ---V250120 :   if resetB='0' then kerBufLdStartI <='0';
  ---V250120 :   elsif rising_edge(clk) then
  ---V250120 :     kerBufLdStartI <=kerBufInitI;
  ---V250120 :   end if;
  ---V250120 : END PROCESS;

  ---V250120 : -- Kernel Buffer Load Enable
  ---V250120 : kerBufLdEnIP : PROCESS(all)
  ---V250120 : BEGIN
  ---V250120 :   if resetB='0' then kerBufLdEnI <='0';
  ---V250120 :   elsif rising_edge(clk) then
  ---V250120 :     if ctrlMainSttI=kerBufLdStt then kerBufLdEnI <='1';
  ---V250120 :     else kerBufLdEnI <='0'; end if;
  ---V250120 :   end if;
  ---V250120 : END PROCESS;

  ---V250120 : -- Kernel Buffer Load Counter
  ---V250120 : kerBufLdCntIP : PROCESS(all)
  ---V250120 : BEGIN
  ---V250120 :   if resetB='0' then kerBufLdCntI <=0;
  ---V250120 :   elsif rising_edge(clk) then
  ---V250120 :     if ctrlMainSttI=kerBufLdStt then
  ---V250120 :       if kerBufLdCntI=to_integer(unsigned(kernelWidth))-1 then kerBufLdCntI <=0;
  ---V250120 :       else kerBufLdCntI <=kerBufLdCntI +1; end if;
  ---V250120 :     else kerBufLdCntI <=0; end if;
  ---V250120 :   end if;
  ---V250120 : END PROCESS;
        ---V250116 : if kerBufLdCntI=KERNEL_WIDTH-1 then kerBufLdCntI <=0; ---V250115
        ---V250115 : if kerBufLdCntI=KERNEL_BUF_WIDTH-1 then kerBufLdCntI <=0;

  -- Kernel Buffer Load End
  kerBufLdEndIP : PROCESS(all)
  BEGIN
    if resetB='0' then kerBufLdEndI <='0';
    elsif rising_edge(clk) then
      if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=to_integer(unsigned(kernelWidth))-1 then kerBufLdEndI <='1';  ---V250120
      else kerBufLdEndI <='0'; end if;
    end if;
  END PROCESS;
      ---V250120 : if ctrlMainSttI=kerBufLdStt AND kerBufLdCntI=to_integer(unsigned(kernelWidth))-1 then kerBufLdEndI <='1';  ---V250116
      ---V250116 : if ctrlMainSttI=kerBufLdStt AND kerBufLdCntI=KERNEL_WIDTH-1 then kerBufLdEndI <='1';  ---V250115
      ---V250115 : if ctrlMainSttI=kerBufLdStt AND kerBufLdCntI=KERNEL_BUF_WIDTH-1 then kerBufLdEndI <='1';

  -- Kernel Buffer Read Enable
  kerBufRdEnIP : PROCESS(all)
  BEGIN
    if resetB='0' then kerBufRdEnI <='0';
    elsif rising_edge(clk) then
      kerBufRdEnI <=kerBufLdEndI; ---V250120
    end if;
  END PROCESS;
      ---V250120 : if ctrlMainSttI=kerBufLdEndStt then kerBufRdEnI <='1';
      ---V250120 : else kerBufRdEnI <='0'; end if;

  -- Image Buffer Initialization
  imgBufInitIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufInitI <='0';
                       kerBufInitI <='0'; ---V250120
    elsif (rising_edge(clk)) then
      if ctrlMainSttI=imgBufInitStt then imgBufInitI <='1';
                                         kerBufInitI <='1'; ---V250120 : START
      else                               imgBufInitI <='0';
                                         kerBufInitI <='0';
      end if;                                               ---V250120 : END
    end if;
  END PROCESS;
      ---V250120 : else                               imgBufInitI <='0'; end if;

  -- Image Buffer Load Start
  imgBufLdStartIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufLdStartI <='0';
                       kerBufLdStartI <='0';  ---V250120
    elsif rising_edge(clk) then
      imgBufLdStartI <=imgBufInitI;
      kerBufLdStartI <=kerBufInitI; ---V250120
    end if;
  END PROCESS;

  -- Image Buffer Load Enable
  imgBufLdEnIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufLdEnI <='0';
                       kerBufLdEnI <='0'; ---V250120
    elsif rising_edge(clk) then
      if ctrlMainSttI=imgBufLdStt then imgBufLdEnI <='1';
        if imgBufLdCntI <= to_integer(unsigned(kernelWidth))-1 then kerBufLdEnI <='1';         ---V250120 : START
        else                                                        kerBufLdEnI <='0'; end if;
      else imgBufLdEnI <='0'; kerBufLdEnI <='0'; end if;                                       ---V250120 : END
    end if;
  END PROCESS;
      ---V250120 : else imgBufLdEnI <='0'; end if;

  -- Image Buffer Load Counter
  imgBufLdCntIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufLdCntI <=0;
    elsif rising_edge(clk) then
      if ctrlMainSttI=imgBufLdStt then
        if imgBufLdCntI=to_integer(unsigned(imageWidth)) then imgBufLdCntI <=0;  ---V250116
        else imgBufLdCntI <=imgBufLdCntI +1; end if;
      else imgBufLdCntI <=0; end if;
    end if;
  END PROCESS;
        ---V250116 : if imgBufLdCntI=IMAGE_WIDTH then imgBufLdCntI <=0;  ---V250116
        ---V250116 : if imgBufLdCntI=IMAGE_BUF_WIDTH then imgBufLdCntI <=0;  ---V250114
        ---V250114 : if imgBufLdCntI=IMAGE_BUF_WIDTH-1 then imgBufLdCntI <=0;

  imgBufLdEndIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufLdEndI <='0';
    elsif rising_edge(clk) then
      if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=to_integer(unsigned(imageWidth))-1 then imgBufLdEndI <='1'; ---V250116
      else imgBufLdEndI <='0'; end if;
    end if;
  END PROCESS;
      ---V250116 : if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=IMAGE_WIDTH-1 then imgBufLdEndI <='1'; ---V250116
      ---V250116 : if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=IMAGE_BUF_WIDTH-1 then imgBufLdEndI <='1';

  imgBufRdStartIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufRdStartI <='0';
    elsif rising_edge(clk) then
      if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=to_integer(unsigned(kernelWidth)) then imgBufRdStartI <='1';  ---V250116
      else imgBufRdStartI <='0'; end if;
    end if;
  END PROCESS;
      ---V250116 : if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=KERNEL_WIDTH then imgBufRdStartI <='1';  ---V250115
      ---V250115 : if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=KERNEL_BUF_WIDTH then imgBufRdStartI <='1';  ---V250114
      ---V250114 : if ctrlMainSttI=imgBufLdStt AND imgBufLdCntI=KERNEL_BUF_WIDTH-1 then imgBufRdStartI <='1';

  -- Image Buffer Read Enable Counter
  imgBufRdCntIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufRdCntI <=0;
    elsif rising_edge(clk) then
      if ctrlMainSttI=imgBufInitStt then imgBufRdCntI <=0;
      elsif ctrlMainSttI=imgBufLdStt OR ctrlMainSttI=waitDoneStt then ---V250114
        if imgBufLdCntI > to_integer(unsigned(kernelWidth))-1 then ---V250116
          if imgBufRdCntI=outNumWidthI then imgBufRdCntI <=outNumWidthI;  ---V250116
          else imgBufRdCntI <=imgBufRdCntI+1; end if;
        else imgBufRdCntI <=0; end if;
      else imgBufRdCntI <=0; end if;
    end if;
  END PROCESS;
        ---V250116 : if imgBufLdCntI > KERNEL_WIDTH-1 then ---V250115
          ---V250116 : if imgBufRdCntI=OUTNUM_WIDTH then imgBufRdCntI <=OUTNUM_WIDTH;
        ---V250115 : if imgBufLdCntI > KERNEL_BUF_WIDTH-1 then ---V250114
      ---V250114 : elsif ctrlMainSttI=imgBufLdStt then
        ---V250114 : if imgBufLdCntI >= KERNEL_BUF_WIDTH-1 then

  -- Image Buffer Read Enable
  imgBufRdEnIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufRdEnI <='0';
    elsif rising_edge(clk) then
      if ctrlMainSttI=imgBufLdStt OR ctrlMainSttI=waitDoneStt then  ---V250114
        if imgBufLdCntI > to_integer(unsigned(kernelWidth))-1 then imgBufRdEnI <='1';  ---V250116
        elsif imgBufRdCntI=outNumWidthI then imgBufRdEnI <='0'; end if; ---V250116
      else imgBufRdEnI <='0'; end if;
    end if;
  END PROCESS;
        ---V250116 : if imgBufLdCntI > KERNEL_WIDTH-1 then imgBufRdEnI <='1';  ---V250115
        ---V250116 : elsif imgBufRdCntI=OUTNUM_WIDTH then imgBufRdEnI <='0'; end if;
        ---V250115 : if imgBufLdCntI > KERNEL_BUF_WIDTH-1 then imgBufRdEnI <='1';  ---V250114
      ---V250114 : if ctrlMainSttI=imgBufLdStt then
        ---V250114 : if imgBufLdCntI >= KERNEL_BUF_WIDTH-1 then imgBufRdEnI <='1';

  -- Image Buffer Read End
  imgBufRdEndIP : PROCESS(all)
  BEGIN
    if resetB='0' then imgBufRdEndI <='0';
    elsif rising_edge(clk) then
      if imgBufRdCntI = outNumWidthI-1 then imgBufRdEndI <='1'; ---V250114
      else imgBufRdEndI <='0'; end if;
    end if;
  END PROCESS;
      ---V250116 : if imgBufRdCntI = OUTNUM_WIDTH-1 then imgBufRdEndI <='1'; ---V250114
      ---V250114 : if ctrlMainSttI=imgBufLdStt AND imgBufRdCntI = OUTNUM_WIDTH-1 then imgBufRdEndI <='1';

  -- Adder Tree Enable
  addTreeEnIP : PROCESS(all)
  BEGIN
    if resetB='0' then addTreeEnI <='0';
    elsif rising_edge(clk) then
      addTreeEnI <=imgBufRdEnI;
    end if;
  END PROCESS;

  ---V250117
  outHeightCntIP : PROCESS(all)
  BEGIN
    if resetB='0' then outHeightCntI <=0;
    elsif rising_edge(clk) then
      if ctrlMainSttI=idleStt OR ctrlMainSttI=waitStartStt then outHeightCntI <=0;
      elsif ctrlMainSttI=calcParaStt OR ctrlMainSttI=extraOutStt then ---V250818
        if outHeightCntI=MAX_OUTPUT_NUM then outHeightCntI <=0;       ---V250818
        else outHeightCntI <=outHeightCntI +1; end if;
      end if;
    end if;
  END PROCESS;
      ---V250818 : elsif ctrlMainSttI=calcParaStt then
      ---V250818 :   if outHeightCntI=outNumHeightI then outHeightCntI <=0;

  ---V250602
  endOfConv2DIP : PROCESS(all)
  BEGIN
    if resetB='0' then endOfConv2DI <='0';
    elsif rising_edge(clk) then
      if ctrlMainSttI=restStt then endOfConv2DI <='1';
      else endOfConv2DI <='0'; end if;
    end if;
  END PROCESS;

  ---V250818
  extraOutEnP : PROCESS(all)
  BEGIN
    if resetB='0' then extraOutEnI <='0';
    elsif rising_edge(clk) then
      if ctrlMainSttI=extraOutStt then extraOutEnI <='1';
      else                             extraOutEnI <='0'; end if;
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
