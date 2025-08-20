--------------------------------------------------------------------------------
--
-- Copyright(c) 2025 Electronics and Telecommunications Research Institute(ETRI)
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
-- Copyright Human Body Communication 2025, All rights reserved.
-- AI Edge SoC Research Section, AI SoC Research Division,
-- Artificial Intelligence Research Laboratory
-- Electronics and Telecommunications Research Institute (ETRI)
--------------------------------------------------------------------------------

--==============================================================================
-- File Name : c2dConvTop.vhd
--==============================================================================
-- Rev.       Des.  Function
-- V250113    hkim  Conv Top
-- V250114    hkim  end signal is added to c2dConvCore, c2dConvCoreCtrl
-- V250115    hkim  Code tuning
-- V250116    hkim  KERNEL_WIDTH, KERNEL_HEIGHT, IMAGE_WIDTH, IMAGE_HEIGHT are changed to input port
--                  c2dConvInput module is added
-- V250117    hkim  GENERIC statement is removed for synthesis
--                  outNumHeight is added
-- V250120    hkim  Output data bit width parameter is applied
-- V250526    hkim  Module c2dTransBuf is added
--                  Top ports are revised for integration to ARX platform
-- V250602    hkim  End of 2DConv is added for ARX Platform
--                  c2dOutBuf is added for ARX Platform
-- V250818    hkim  MAX_OUTPUT_NUM is applied for the Platform
--==============================================================================

--==============================================================================
LIBRARY ieee;   USE ieee.std_logic_1164.all;
                USE ieee.numeric_std.all;                       -- shift_right(), shift_left()
                USE ieee.math_real.all;
LIBRARY work;   USE work.pkgConstNpuConv2d.all;
                USE work.pkgTypeNpuConv2d.all;
                USE work.pkgFuncNpuConv2d.all;
--==============================================================================
                --USE ieee.std_logic_unsigned.all;
                --USE ieee.std_logic_arith.conv_std_logic_vector;
                --USE ieee.fixed_pkg.all;
                ---V250526 : USE work.pkgTestData.all;

--==============================================================================
ENTITY c2dConvTop IS
PORT(
  endOfConv2D     : out std_logic;  ---V250602
  convCoreValid   : out std_logic;
  convCoreOut     : out std_logic_vector(OUTPUT_BUF_WIDTH*OUTPUT_BUF_BITSIZE-1 downto 0);  ---V250120
  kerInBufLdInit  : in  std_logic;                                              -- Kernel load init, V250526 : START
  kerInBufLdEn    : in  std_logic;
  kerInBufLdEnd   : in  std_logic;
  kerInBufDataIn  : in  std_logic_vector(KERNEL_BUF_WIDTH*KERNEL_BUF_BITSIZE-1 downto 0);
  imgInBufLdInit  : in  std_logic;
  imgInBufLdEn    : in  std_logic;
  imgInBufLdEnd   : in  std_logic;
  imgInBufDataIn  : in  std_logic_vector(IMAGE_BUF_WIDTH*IMAGE_BUF_BITSIZE-1 downto 0);
  numKernelWidth  : in  std_logic_vector(7 downto 0);
  numKernelHeight : in  std_logic_vector(7 downto 0);
  numImageWidth   : in  std_logic_vector(7 downto 0);
  numImageHeight  : in  std_logic_vector(7 downto 0);                           ---V250526 : END
  numOutWidth     : in  std_logic_vector(7 downto 0);
  numOutHeight    : in  std_logic_vector(7 downto 0);
  npuStart        : in  std_logic;
  clk             : in  std_logic;
  resetB          : in  std_logic
);
END;
--==============================================================================
  ---V250526 : npuConvStart    : in  std_logic;
  ---V250526 : kernelWidth     : in  std_logic_vector(KERNEL_BUF_WIDTH_BITSIZE-1 downto 0);  ---V250116 : START
  ---V250526 : kernelHeight    : in  std_logic_vector(KERNEL_BUF_HEIGHT_BITSIZE-1 downto 0);
  ---V250526 : imageWidth      : in  std_logic_vector(IMAGE_BUF_WIDTH_BITSIZE-1 downto 0);
  ---V250526 : imageHeight     : in  std_logic_vector(IMAGE_BUF_HEIGHT_BITSIZE-1 downto 0);  ---V250116 : END
  ---V250120 : convCoreOut     : out std_logic_vector(IMAGE_BUF_BITSIZE+KERNEL_BUF_BITSIZE+INTEGER(ceil(log2(real(KERNEL_BUF_WIDTH))))+INTEGER(ceil(log2(real(KERNEL_BUF_HEIGHT))))-1 downto 0);
  ---V250117 : GENERIC(
  ---V250117 :   numOfWidth      : NATURAL := 8;   -- number of WIDTH    , KERNEL_BUF_WIDTH
  ---V250117 :   numOfHeight     : NATURAL := 8;   -- number of HEIGHT   , KERNEL_BUF_HEIGHT
  ---V250117 :   sizeOfBitImgIn  : NATURAL := 8;   -- bit size of image  , IMAGE_BUF_BITSIZE
  ---V250117 :   sizeOfBitKerIn  : NATURAL := 8    -- bit size of kernel , KERNEL_BUF_BITSIZE
  ---V250117 : );
  ---V250117 : convCoreOut     : out std_logic_vector(sizeOfBitImgIn+sizeOfBitKerIn+INTEGER(ceil(log2(real(numOfWidth))))+INTEGER(ceil(log2(real(numOfHeight))))-1 downto 0);

--==============================================================================
ARCHITECTURE rtl OF c2dConvTop IS
  ------------------------------------------------------------------------------
  -- COMPONENT DECLARATION
  ------------------------------------------------------------------------------
  ---V250526
  COMPONENT c2dTransBuf
  GENERIC(
    numOfWidth      : NATURAL := 8;   -- number of BUF_WIDTH  , HW
    numOfHeight     : NATURAL := 8;   -- number of BUF_HEIGHT , HW
    numOfHeightOut  : NATURAL := 8;   -- number of BUF_HEIGHT for Output
    sizeOfBitIn     : NATURAL := 8;   -- bit size
    sizeOfBitCnt    : NATURAL := 8
  );
  PORT(
    outValid        : out std_logic;
    bufLineOut      : out std_logic_vector(numOfHeightOut*sizeOfBitIn-1 downto 0);
    bufLdInit       : in  std_logic;
    bufLdEn         : in  std_logic;
    bufLdEnd        : in  std_logic;
    bufRdInit       : in  std_logic;
    bufRdEn         : in  std_logic;
    bufLineIn       : in  std_logic_vector(numOfWidth*sizeOfBitIn-1 downto 0);
    numRow          : in  std_logic_vector(7 downto 0); -- from mi_info or mk_info
    outHeightCnt    : in  std_logic_vector(sizeOfBitCnt-1 downto 0);
    clk             : in  std_logic;
    resetB          : in  std_logic
  );
  END COMPONENT;

  COMPONENT c2dConvCore
  GENERIC(
    numOfWidth      : NATURAL := 8;   -- number of WIDTH    , KERNEL_BUF_WIDTH
    numOfHeight     : NATURAL := 8;   -- number of HEIGHT   , KERNEL_BUF_HEIGHT
    sizeOfBitImgIn  : NATURAL := 8;   -- bit size of image  , IMAGE_BUF_BITSIZE
    sizeOfBitKerIn  : NATURAL := 8    -- bit size of kernel , KERNEL_BUF_BITSIZE
  );
  PORT(
    convCoreEnd     : out std_logic;  ---V250114
    convCoreValid   : out std_logic;
    convCoreOut     : out std_logic_vector(sizeOfBitImgIn+sizeOfBitKerIn+INTEGER(ceil(log2(real(numOfWidth))))+INTEGER(ceil(log2(real(numOfHeight))))-1 downto 0);
    kerBufFull      : out std_logic;
    imgBufFull      : out std_logic;
    imgBufEmpty     : out std_logic;
    kerBufInit      : in  std_logic;
    kerBufLdEn      : in  std_logic;
    kerBufRdEn      : in  std_logic;
    kerBufLineIn    : in  std_logic_vector(numOfHeight*sizeOfBitKerIn-1 downto 0);
    imgBufInit      : in  std_logic;
    imgBufLdEn      : in  std_logic;
    imgBufRdEn      : in  std_logic;
    imgBufLineIn    : in  std_logic_vector(numOfHeight*sizeOfBitImgIn-1 downto 0);
    addTreeEn       : in  std_logic;  -- TBD
    clk             : in  std_logic;
    resetB          : in  std_logic
  );
  END COMPONENT;

  COMPONENT c2dConvCoreCtrl
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
  END COMPONENT;

  COMPONENT ipFifo
  GENERIC(
    sizeOfWidth     : NATURAL := 8;
    sizeOfDepth     : NATURAL := 8
  );
  PORT(
    outQ            : out std_logic_vector(sizeOfWidth-1 downto 0);
    inA             : in  std_logic_vector(sizeOfWidth-1 downto 0);
    enable          : in  std_logic;
    clk             : in  std_logic;
    resetB          : in  std_logic
  );
  END COMPONENT;

  ---V250602
  COMPONENT c2dOutBuf
  GENERIC(
    numOfData       : NATURAL := 8;   -- number of data
    sizeOfBitIn     : NATURAL := 8;   -- input bit size
    sizeOfBitOut    : NATURAL := 8    -- output bit size
  );
  PORT(
    outValid        : out std_logic;
    bufOut          : out std_logic_vector(numOfData*sizeOfBitOut-1 downto 0);
    bufInit         : in  std_logic;
    bufEn           : in  std_logic;
    bufIn           : in  std_logic_vector(sizeOfBitIn-1 downto 0);
    endOfRow        : in  std_logic;
    numRow          : in  std_logic_vector(7 downto 0);
    clk             : in  std_logic;
    resetB          : in  std_logic
  );
  END COMPONENT;

  -- ---V250116
  -- COMPONENT c2dConvInput
  -- GENERIC(
  --   numOfWidth      : NATURAL := 8;   -- number of WIDTH    , KERNEL_BUF_WIDTH
  --   numOfHeight     : NATURAL := 8;   -- number of HEIGHT   , KERNEL_BUF_HEIGHT
  --   sizeOfBitImgIn  : NATURAL := 8;   -- bit size of image  , IMAGE_BUF_BITSIZE
  --   sizeOfBitKerIn  : NATURAL := 8    -- bit size of kernel , KERNEL_BUF_BITSIZE
  -- );
  -- PORT(
  --   kerBufLineIn    : out std_logic_vector(numOfHeight*sizeOfBitKerIn-1 downto 0);
  --   imgBufLineIn    : out std_logic_vector(numOfHeight*sizeOfBitImgIn-1 downto 0);
  --   kerBufInit      : in  std_logic;
  --   kerBufLdEn      : in  std_logic;
  --   kerBufRdEn      : in  std_logic;
  --   imgBufInit      : in  std_logic;
  --   imgBufLdEn      : in  std_logic;
  --   imgBufRdEn      : in  std_logic;
  --   kernelWidth     : in  std_logic_vector(KERNEL_BUF_WIDTH_BITSIZE-1 downto 0);
  --   kernelHeight    : in  std_logic_vector(KERNEL_BUF_HEIGHT_BITSIZE-1 downto 0);
  --   imageWidth      : in  std_logic_vector(IMAGE_BUF_WIDTH_BITSIZE-1 downto 0);
  --   imageHeight     : in  std_logic_vector(IMAGE_BUF_HEIGHT_BITSIZE-1 downto 0);
  --   outHeightCnt    : in  std_logic_vector(IMAGE_BUF_HEIGHT_BITSIZE-1 downto 0);  ---V250117
  --   clk             : in  std_logic;
  --   resetB          : in  std_logic
  -- );
  -- END COMPONENT;
  -- COMPONENT END

  ------------------------------------------------------------------------------
  -- SIGNAL DECLARATION
  ------------------------------------------------------------------------------
  SIGNAL  kerBufInit      : std_logic;
  SIGNAL  kerBufLdEn      : std_logic;
  SIGNAL  kerBufRdEn      : std_logic;
  SIGNAL  imgBufInit      : std_logic;
  SIGNAL  imgBufLdEn      : std_logic;
  SIGNAL  imgBufRdEn      : std_logic;
  SIGNAL  addTreeEn       : std_logic;  -- TBD
  SIGNAL  imgBufFull      : std_logic;
  SIGNAL  imgBufEmpty     : std_logic;
  SIGNAL  kerBufFull      : std_logic;
  SIGNAL  kerBufLineIn    : std_logic_vector(IMAGE_BUF_HEIGHT*KERNEL_BUF_BITSIZE-1 downto 0);  ---V250117
  SIGNAL  imgBufLineIn    : std_logic_vector(IMAGE_BUF_HEIGHT*IMAGE_BUF_BITSIZE-1 downto 0);   ---V250117
  SIGNAL  sigFifoInI      : std_logic_vector(6 downto 0);
  SIGNAL  sigFifoOutI     : std_logic_vector(6 downto 0);
  SIGNAL  kerBufInitI     : std_logic;
  SIGNAL  kerBufLdEnI     : std_logic;
  SIGNAL  kerBufRdEnI     : std_logic;
  SIGNAL  imgBufInitI     : std_logic;
  SIGNAL  imgBufLdEnI     : std_logic;
  SIGNAL  imgBufRdEnI     : std_logic;
  SIGNAL  addTreeEnI      : std_logic;
  SIGNAL  convCoreEndI    : std_logic;  ---V250114
  SIGNAL  outHeightCntI   : std_logic_vector(IMAGE_BUF_HEIGHT_BITSIZE-1 downto 0);  ---V250117
  ---V250526
  SIGNAL  inBufImgValidI  : std_logic;
  SIGNAL  inBufKerValidI  : std_logic;
  SIGNAL  bufLineOutImgI  : std_logic_vector(IMAGE_BUF_WIDTH*IMAGE_BUF_BITSIZE-1 downto 0);
  SIGNAL  bufLineOutKerI  : std_logic_vector(KERNEL_BUF_WIDTH*KERNEL_BUF_BITSIZE-1 downto 0);
  SIGNAL  kernelWidth     : std_logic_vector(KERNEL_BUF_WIDTH_BITSIZE-1 downto 0);
  SIGNAL  kernelHeight    : std_logic_vector(KERNEL_BUF_HEIGHT_BITSIZE-1 downto 0);
  SIGNAL  imageWidth      : std_logic_vector(IMAGE_BUF_WIDTH_BITSIZE-1 downto 0);
  SIGNAL  imageHeight     : std_logic_vector(IMAGE_BUF_HEIGHT_BITSIZE-1 downto 0);
  SIGNAL  convCoreOutI    : std_logic_vector(IMAGE_BUF_BITSIZE+KERNEL_BUF_BITSIZE+INTEGER(ceil(log2(real(IMAGE_BUF_WIDTH))))+INTEGER(ceil(log2(real(KERNEL_BUF_HEIGHT))))-1 downto 0);
  SIGNAL  convCoreValidI  : std_logic;
  SIGNAL  extraOutEnI     : std_logic; ---V250818
  SIGNAL  convCoreValidO  : std_logic;
  ---V250117 : SIGNAL  kerBufLineIn    : std_logic_vector(numOfHeight*sizeOfBitKerIn-1 downto 0);
  ---V250117 : SIGNAL  imgBufLineIn    : std_logic_vector(numOfHeight*sizeOfBitImgIn-1 downto 0);
  -- SIGNAL END

BEGIN
  ------------------------------------------------------------------------------
  -- SIGNAL GENERATION
  ------------------------------------------------------------------------------
  -- END GENERATE

  ------------------------------------------------------------------------------
  -- SIGNAL CONNECTION
  ------------------------------------------------------------------------------
  sigFifoInI <= kerBufInit &
                kerBufLdEn &
                kerBufRdEn &
                imgBufInit &
                imgBufLdEn &
                imgBufRdEn &
                addTreeEn;

  kerBufInitI <=sigFifoOutI(6);
  kerBufLdEnI <=sigFifoOutI(5);
  kerBufRdEnI <=sigFifoOutI(4);
  imgBufInitI <=sigFifoOutI(3);
  imgBufLdEnI <=sigFifoOutI(2);
  imgBufRdEnI <=sigFifoOutI(1);
  addTreeEnI  <=sigFifoOutI(0);

  ---V250818
  convCoreValid <=convCoreValidO OR extraOutEnI;  ---V250818

  ---V250530 : ---V250525
  ---V250530 : kernelWidth  <=numKernelWidth;
  ---V250530 : kernelHeight <=numKernelHeight;
  ---V250530 : imageWidth   <=numImageWidth;
  ---V250530 : imageHeight  <=numImageHeight;
  
  --convCoreOutI <=std_logic_vector(to_signed(to_integer(signed(convCoreOutI)), OUTPUT_BUF_WIDTH_BITSIZE));
  ---V250602 : convCoreOut <=convCoreOutI(convCoreOutI'LEFT) & convCoreOutI(OUTPUT_BUF_WIDTH_BITSIZE-2 downto 0);
  -- END CONNECTION

  ------------------------------------------------------------------------------
  -- PORT MAPPING
  ------------------------------------------------------------------------------
  ---V250526
  i00_c2dTransBuf : c2dTransBuf -- for IMAGE BUFFER
  GENERIC MAP(
    numOfWidth      => IMAGE_BUF_WIDTH  , -- number of BUF_WIDTH  , HW
    numOfHeight     => IMAGE_BUF_HEIGHT , -- number of BUF_HEIGHT , HW
    numOfHeightOut  => IMAGE_BUF_HEIGHT ,
    sizeOfBitIn     => IMAGE_BUF_BITSIZE,
    sizeOfBitCnt    => 8
  )
  PORT MAP(
    outValid        => OPEN            ,
    bufLineOut      => imgBufLineIn    ,  -- to ConvCore
    bufLdInit       => imgInBufLdInit  ,  -- from ARX Platform
    bufLdEn         => imgInBufLdEn    ,
    bufLdEnd        => imgInBufLdEnd   ,
    bufLineIn       => imgInBufDataIn  ,
    numRow          => imageHeight     ,  -- width = height in thic case
    bufRdInit       => imgBufInit      ,  -- from Controller
    bufRdEn         => imgBufLdEn      ,
    outHeightCnt    => (others=>'0')   ,
    clk             => clk             ,
    resetB          => resetB
  );
  i01_c2dTransBuf : c2dTransBuf -- for KERNEL BUFFER
  GENERIC MAP(
    numOfWidth      => KERNEL_BUF_WIDTH  , -- number of BUF_WIDTH  , HW
    numOfHeight     => KERNEL_BUF_HEIGHT , -- number of BUF_HEIGHT , HW
    numOfHeightOut  => IMAGE_BUF_HEIGHT  ,
    sizeOfBitIn     => KERNEL_BUF_BITSIZE,
    sizeOfBitCnt    => 8
  )
  PORT MAP(
    outValid        => OPEN            ,
    bufLineOut      => kerBufLineIn    ,  -- to ConvCore
    bufLdInit       => kerInBufLdInit  ,  -- from ARX Platform
    bufLdEn         => kerInBufLdEn    ,
    bufLdEnd        => kerInBufLdEnd   ,
    bufLineIn       => kerInBufDataIn  ,
    numRow          => kernelHeight    ,  -- width = height in thic case
    bufRdInit       => kerBufInit      ,  -- from Controller
    bufRdEn         => kerBufLdEn      ,
    outHeightCnt    => outHeightCntI   ,
    clk             => clk             ,
    resetB          => resetB
  );

  i0_c2dConvCore : c2dConvCore
  GENERIC MAP(
    numOfWidth      => KERNEL_BUF_WIDTH   ,
    numOfHeight     => IMAGE_BUF_HEIGHT   , ---V250530
    sizeOfBitImgIn  => IMAGE_BUF_BITSIZE  ,
    sizeOfBitKerIn  => KERNEL_BUF_BITSIZE
  )
    ---V240530 : numOfHeight     => KERNEL_BUF_HEIGHT  ,
  PORT MAP(
    convCoreEnd     => convCoreEndI    ,  ---V250114
    convCoreValid   => convCoreValidI  ,
    convCoreOut     => convCoreOutI    ,
    kerBufFull      => kerBufFull      ,
    imgBufFull      => imgBufFull      ,
    imgBufEmpty     => imgBufEmpty     ,
    kerBufInit      => kerBufInitI     ,  -- from Signal FIFO(delayed)
    kerBufLdEn      => kerBufLdEnI     ,
    kerBufRdEn      => kerBufRdEnI     ,
    kerBufLineIn    => kerBufLineIn    ,
    imgBufInit      => imgBufInitI     ,
    imgBufLdEn      => imgBufLdEnI     ,
    imgBufRdEn      => imgBufRdEnI     ,
    imgBufLineIn    => imgBufLineIn    ,
    addTreeEn       => addTreeEnI      ,
    clk             => clk             ,
    resetB          => resetB
  );
    ---V250602 : convCoreValid   => convCoreValid   ,

  i1_c2dConvCoreCtrl : c2dConvCoreCtrl
  PORT MAP(
    endOfConv2D     => endOfConv2D     ,  ---V250602
    extraOutEn      => extraOutEnI     ,  ---V250818
    kerBufInit      => kerBufInit      ,
    kerBufLdEn      => kerBufLdEn      ,
    kerBufRdEn      => kerBufRdEn      ,
    imgBufInit      => imgBufInit      ,
    imgBufLdEn      => imgBufLdEn      ,
    imgBufRdEn      => imgBufRdEn      ,
    addTreeEn       => addTreeEn       ,
    outHeightCnt    => outHeightCntI   ,  ---V250117
    npuStart        => npuStart        ,
    convCoreEnd     => convCoreEndI    ,  ---V250114
    convCoreValid   => convCoreValid   ,
    imgBufFull      => imgBufFull      ,
    imgBufEmpty     => imgBufEmpty     ,
    kerBufFull      => kerBufFull      ,
    kernelWidth     => kernelWidth     , ---V250116 : START
    kernelHeight    => kernelHeight    ,
    imageWidth      => imageWidth      ,
    imageHeight     => imageHeight     , ---V250116 : END
    clk             => clk             ,
    resetB          => resetB
  );

  -- Signal FIFO
  i2_ipFifo : ipFifo
  GENERIC MAP(
    sizeOfWidth     => 7,
    sizeOfDepth     => 1
  )
  PORT MAP(
    outQ            => sigFifoOutI     ,
    inA             => sigFifoInI      ,
    enable          => '1'             ,
    clk             => clk             ,
    resetB          => resetB
  );

  ---V250530 : for timing control with ARX platform
  capt1P : PROCESS(all)
  BEGIN
    if resetB='0' then 
      kernelWidth  <=(others=>'0');
      kernelHeight <=(others=>'0');
      imageWidth   <=(others=>'0');
      imageHeight  <=(others=>'0');
    elsif rising_edge(clk) then
      if imgInBufLdInit='1' then
        kernelWidth  <=numKernelWidth;
        kernelHeight <=numKernelHeight;
        imageWidth   <=numImageWidth;
        imageHeight  <=numImageHeight;
      end if;
    end if;
  END PROCESS;

  ---V250602
  i3_c2dOutBuf : c2dOutBuf
  GENERIC MAP(
    numOfData       => OUTPUT_BUF_WIDTH   ,
    sizeOfBitIn     => OUTPUT_BUF_WIDTH_BITSIZE ,
    sizeOfBitOut    => OUTPUT_BUF_BITSIZE
  )
  PORT MAP(
    outValid        => convCoreValidO  ,  ---V250818
    bufOut          => convCoreOut     ,
    bufInit         => imgBufInit      ,
    bufEn           => convCoreValidI  ,
    bufIn           => convCoreOutI    ,
    endOfRow        => convCoreEndI    ,
    numRow          => numOutWidth     ,
    clk             => clk             ,
    resetB          => resetB
  );
    ---V250818 : outValid        => convCoreValid   ,


  -----V250116
  --i_c2dConvInput : c2dConvInput
  --GENERIC MAP(
  --  numOfWidth      => KERNEL_BUF_WIDTH   ,
  --  numOfHeight     => KERNEL_BUF_HEIGHT  ,
  --  sizeOfBitImgIn  => IMAGE_BUF_BITSIZE  ,
  --  sizeOfBitKerIn  => KERNEL_BUF_BITSIZE
  --)
  --PORT MAP(
  --  kerBufLineIn    => kerBufLineIn    ,
  --  imgBufLineIn    => imgBufLineIn    ,
  --  kerBufInit      => kerBufInit      ,  -- from Controller
  --  kerBufLdEn      => kerBufLdEn      ,
  --  kerBufRdEn      => kerBufRdEn      ,
  --  imgBufInit      => imgBufInit      ,
  --  imgBufLdEn      => imgBufLdEn      ,
  --  imgBufRdEn      => imgBufRdEn      ,
  --  kernelWidth     => kernelWidth     ,
  --  kernelHeight    => kernelHeight    ,
  --  imageWidth      => imageWidth      ,
  --  imageHeight     => imageHeight     ,
  --  outHeightCnt    => outHeightCntI   , ---V250117
  --  clk             => clk             ,
  --  resetB          => resetB
  --);
  -- END MAPPING

  ------------------------------------------------------------------------------
  -- PROCESSES
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  -- synthesis translate_off
  ------------------------------------------------------------------------------
  -- TDD
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- synthesis translate_on
END rtl;
--==============================================================================
