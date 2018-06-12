{{
        File:     vga_display.spin
        Author:   Connor Spangler
        Date:     1/23/2018
        Version:  1.1
        Description: 
                  This file contains the PASM code to drive a VGA signal using video data
                  from hub RAM
}}

VAR
  long  cog_                    ' Variable containing ID of display cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  
PUB start(varAddrBase) : status                         ' Function to start vga driver with pointer to Main RAM variables
  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address

  ' Start VGA driver
  ifnot cog_ := cognew(@vga, var_addr_base_) + 1        ' Initialize cog running "vga" routine with reference to start of variable registers
    return FALSE                                        ' Graphics system failed to initialize

  return TRUE                                           ' Graphics system successfully initialized

PUB stop                                                ' Function to stop VGA driver
    if cog_                                             ' If cog is running
      cogstop(cog_~ - 1)                                ' Stop the cog
  
DAT
        org             0
vga           
        ' Initialize variables
        mov             clptr,  par             ' Initialize pointer to current scanline
        mov             vbptrs, par             ' Initialize pointer to video buffer
        add             vbptrs, #4              ' Point video buffer pointer to video buffer
        rdlong          clptr,  clptr           ' Load current scanline memory location
        rdlong          vbptrs, vbptrs          ' Load video buffer memory location
        mov             cursl,  #0              ' Initialize current scanline
        wrlong          cursl,  clptr           ' Set initial scanline in Main RAM
        mov             lptr,   #2              ' Initialize line pointer
        mov             scnptr, numSegs         ' Initialize segment pointer

        ' Generate scancode               
:rdlng  mov             scancode+0, iR          ' Move rdlong instruction
:wvid   mov             scancode+1, iW          ' Move waitvid instruction
        add             :rdlng, d1              ' Increment next rdlong instruction move
        add             :wvid,  d1              ' Increment next waitvid instruction move
        add             iR,     #1              ' Increment next memory location
:vmmov  mov             vbptrs+1, vbptrs+0      ' Copy memory location to next
:vminc  add             vbptrs+1, #4            ' Increment Main RAM location
        add             :vmmov, d0s0            ' Increment next Main RAM move
        add             :vminc, d0              ' Increment next Main RAM location
        djnz            scnptr, #:rdlng         ' Repeat for all parts of scanline
        mov             scancode+160+0, iS+0    ' Move HSync instructions
        mov             scancode+160+1, iS+1    ' |
        mov             scancode+160+2, iS+2    ' |
        mov             scancode+160+3, iS+3    ' |
        mov             scancode+160+4, iS+4    ' |
        mov             scancode+160+5, iS+5    ' |
        mov             scancode+160+6, iS+6    ' |
        mov             scancode+160+7, iS+7    ' |
        mov             scancode+160+8, iS+8    ' |
        mov             scancode+160+9, iS+9    ' |
        mov             scancode+160+10, iS+10  ' |
        mov             scancode+160+11, iS+11  ' |
        mov             scancode+160+12, iJ     ' Move return jump instruction

        ' Setup and start video generator
        or              dira,   vgapin          ' Set video generator output pins
        or              dira,   vspin           ' Set VSync signal output pin
        or              dira,   sigpin          ' Set data ready signal output pin
        or              dira,   syncpin         ' Set sync output pins
        or              outa,   syncpin         ' Drive sync pins high
        mov             frqa,   pllfreq         ' Set Counter A frequency
        mov             ctra,   CtrCfg          ' Set Counter A control register
        rdlong          cnt,    #0              ' Retrive system clock
        shr             cnt,    #10             ' Set-up ~1ms wait
        add             cnt,    cnt             ' Add 1ms wait
        waitcnt         cnt,    #0              ' Allow PLL to settle
        mov             vcfg,   VidCfg          ' Configure and start video generator
        
        ' Display vertical sync area
video   or              outa,   vspin           ' Drive vertical sync signal pin high
        mov             vptr,   numFP           ' Initialize vertical sync pointer        
:fporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        andn            outa,   vspin           ' Drive vertical sync signal pin low
        waitvid         sColor, pPixel          ' Display blank active video line
        ' EXOTIC HSYNC HERE...
        mov             vscl,   HVidScl         ' Set video scale for HSync
        'waitvid         sColor, hPixel          ' Horizontal sync
        ' ... TO HERE
        djnz            vptr,   #:fporch        ' Display front porch lines           
        mov             vptr,   numVS           ' Initialize vertical sync pointer        
:vsync  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vPixel          ' Display blank active VSync video line
        ' EXOTIC HSYNC HERE (w/ VSync accounted for)...
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hvPixel         ' Horizontal + vertical sync
        ' ... TO HERE
        djnz            vptr,   #:vsync         ' Display vertical sync lines 
        mov             vptr,   numBP           ' Initialize vertical sync pointer        
:bporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, pPixel          ' Display blank active video line
        ' EXOTIC HSYNC HERE...
        mov             vscl,   HVidScl         ' Set video scale for HSync
        'waitvid         sColor, hPixel          ' Horizontal sync
        ' ... TO HERE
        cmp             vptr,   dataSig wz      ' Check if graphics data ready
        if_z  or        outa,   sigpin          ' Signal data ready
        djnz            vptr,   #:bporch        ' Display back porch lines 
        andn            outa,   sigpin          ' Disable data ready signal

        ' Display active video
active  mov             vscl,   VVidScl         ' Set video scale for visible video
        jmp             #scancode               ' Display line
scanret djnz            lptr,   #active         ' Display same line twice
        mov             lptr,   #2              ' Reset line pointer             
        add             cursl,  #1              ' Increment current scanline
        wrlong          cursl,  clptr           ' Set current scanline in Main RAM                
        cmp             cursl,  numLines wz     ' Check if at bottom of screen
        if_nz jmp       #active                 ' Continue displaying remaining scanlines 
        mov             cursl,  #0              ' Reset current scanline
        wrlong          cursl,  clptr           ' Set initial scanline in Main RAM
        jmp             #video                  ' Return to start of display

' Config values
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' VGA output pins
sigpin        long      |< 26                                                                           ' Data ready signal pin
vspin         long      |< 27                                                                           ' VSync signal output pin
pllfreq       long      259917792                                                                       ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_010_0_11111111                                      ' Video generator configuration
VVidScl       long      %000000000000_00000010_000000001000                                             ' Video generator visible video scale register
HVidScl       long      %000000000000_00010000_000010100000                                             ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                                             ' Video generator blank line scale register

' Video Generator inputs
vPixel        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
hvPixel       long      %%0_0_0_0_0_0_1_1_1_0_0_0_0_0_0_1                       ' HVSync pixels

' Video attributes
numFP         long      10      ' Number of vertical front porch lines                        
numVS         long      2       ' Number of vertical sync lines                        
numBP         long      33      ' Number of vertical back porch lines
numLines      long      240     ' Number of rendered lines
numSegs       long      80      ' Number of scanline segments
dataSig       long      15      ' Back porch scanline to signal render cogs

' TESTING
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
cPixel        long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' Porch color blank pixels
pPixel        long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Porch sync blank pixels
hsPixel       long      %%2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2                       ' HSync sync blank pixels
fphScale      long      %000000000000_00000000_000000001000                     ' Video generator scale for half of front porch
hsScale       long      %000000000000_00000000_000001100000                     ' Video generator scale for horizontal sync
bphScale      long      %000000000000_00000000_000000011000                     ' Video generator scale for horizontal sync
SyncCfg       long      %0_01_1_0_0_000_00000000000_011_0_11111111              ' Video generator sync pins configuration
hsncpin       long      |< 24                                                   ' Horizontal sync pins
vsncpin       long      |< 25                                                   ' Vertical sync pin
syncpin       long      |< 24 | |< 25                                           ' Sync pins

' Instructions used to generate scancode
iR            rdlong    pixels, vbptrs+0        ' Load next pixels
iW            waitvid   pixels, #%%3210         ' Display pixels
iS            mov       vscl,   fphScale        ' Set vieo generator scale to half front porch
              waitvid   sColor, cPixel          ' Display first half of front porch
              mov       vcfg,   SyncCfg         ' Set video configuration to control sync pins
              waitvid   sColor, pPixel          ' Display second half of front porch
              andn      outa,   syncpin         ' Hand sync pin control to video generator
              mov       vscl,   hsScale         ' Set video generator scale to horizontal sync
              waitvid   sColor, hsPixel         ' Display horizontal sync
              mov       vscl,   bphScale        ' Set video generator scale to half back porch
              waitvid   sColor, pPixel          ' Display first half of back porch
              or        outa,   syncpin         ' Take sync pin control back from video generator
              waitvid   sColor, cPixel          ' Display second half of back porch
              mov       vcfg,   VidCfg          ' Set video configuration to control color pins
iJ            jmp       #scanret                ' Return to rest of display

' Other values
d0s0          long      1 << 9 + 1              ' Value to increment source and destination registers         
d0            long      1 << 9                  ' Value to increment destination register
d1            long      1 << 10                 ' Value to incrememnt destination register by 2

' Scancode buffer
scancode      long      0[80*2+13]              ' Buffer containing display scancode
vbptrs        long      0[80]                   ' Buffer containing Main RAM video buffer memory locations

' Frame pointers
lptr          res       1       ' Current line being rendered
vptr          res       1       ' Current vertical sync line being rendered

' Other pointers
scnptr        res       1       ' Pointer to current scancode section being generated
clptr         res       1       ' Pointer to location of current scanline in Main RAM
cursl         res       1       ' Container for current scanline
pixels        res       1       ' Container for currently rendering pixels

        fit