 {{
        File:     game.spin
        Author:   Connor Spangler
        Date:     11/3/2017
        Version:  1.0
        Description: 
                  This file contains the PASM code defining a test arcade game
}}

CON
  _clkmode = xtal1 + pll16x                       ' Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000

  ' Constants defining screen dimensions
  vTilesH = 10                                          ' Number of visible tiles horizontally                                          
  vTilesV = 10                                          ' Number of visible tiles vertically

  ' Constants defining memory tile palette
  tSizeH = 16                                           ' Width of tiles in pixels 
  tSizeV = 16                                           ' Height of tiles in pixels

  ' Constants defining memory tile map
  tMapSizeH = 16                                        ' Horizontal tile map size in words
  tMapSizeV = 15                                        ' Vertical tile map size in words

  ' Constants defining calculated attributes
  sMaxH = (tMapSizeH - vTilesH) * 2                     ' Maximum horizontal scroll in words
  sMaxV = tMapSizeV - vTilesV                           ' Maximum vertical scroll

OBJ
  input : "input"
  vga : "vga"
  
VAR
  ' Graphic resources pointers
  long  tile_map_base_          ' Register pointing to base of tile maps
  long  tile_palette_base_      ' Register pointing to base of tile palettes
  long  color_palette_base_     ' Register pointing to base of color palettes

  ' Game resource pointers
  long  input_state_base_       ' Register in Main RAM containing state of inputs
  long  cur_pos_base_           ' Current horizontal tile position

PUB main
  tile_map_base_ := @tile_maps                          ' Point tile map base to base of tile maps
  tile_palette_base_ := @tile_palettes                  ' Point tile palette base to base of tile palettes
  color_palette_base_ := @color_palettes                ' Point color palette base to base of color palettes
  input_state_base_ := @input_states                    ' Point input stat base to base of input states
  cur_pos_base_ := @position                            ' Point current position base to base of positions                
  
  'vga.start(@tile_map_base_)                            ' Start VGA engine
  input.start(@input_state_base_)                       ' Start input system                        
  cognew(@game, @input_state_base_)                     ' Start game
  cognew(@testing, cur_pos_base_+4)                       ' Test game  
DAT
        org             0
game    ' Initialize variables
        mov             isbase, par             ' Load Main RAM tile map base address into input state base
        mov             pbase,  par             ' Load Main RAM tile map base address into position base
        add             pbase,  #4              ' Point position pointer to its Main RAM register
        rdlong          isbase, isbase          ' Load input state base pointer
        rdlong          pbase,  pbase           ' Load position base pointer
        mov             xbase,  pbase           ' Set horizontal position base address
        mov             ybase,  pbase           ' Set vertical position base address       
        add             ybase,  #4              ' Increment vertical position base address

        ' Initialize game map attributes
        mov             xpos,   #0              ' Initialize horizontal position
        mov             ypos,   #0              ' Initialize vertical position        
        mov             xbound, #tMapSizeH      ' Initialize left boundry of tile map
        mov             ybound, #tMapSizeV      ' Initialize right boundry of tile map

        ' Scroll tile map
:read   rdword          istate, isbase          ' Read input states from Main RAM
:left   test            btn1,   istate wc       ' Test button 1 pressed
        if_c  mov       pstateL,#1              ' Set pressed state 1 to 1 if so
        if_c  jmp       #:right                 ' And continue to next input
        cmp             pstateL,#1 wz           ' Otherwise test if button 1 was previously pressed
        if_nz jmp       #:right                 ' If not continue to next input
        mov             pstateL,#0              ' Otherwise reset pressed 1 state
        cmp             zero,   xpos wc         ' Test if at far left of tile map
        if_c  sub       xpos,   #1              ' If not decrement horizontal position
:right  test            btn2,   istate wc       ' Test button 2 pressed
        if_c  mov       pstateR,#1              ' Set pressed state 2 to 1 if so
        if_c  jmp       #:up                    ' And continue to next input
        cmp             pstateR,#1 wz           ' Otherwise test if button 2 was previously pressed
        if_nz jmp       #:up                    ' If not continue to next input
        mov             pstateR,#0              ' Otherwise reset pressed 2 state
        cmp             xpos,   xbound wc       ' Test if at far right of tile map
        if_c  add       xpos,   #1              ' If not increment horizontal position
:up     test            btn3,   istate wc       ' Test button 3 pressed
        if_c  mov       pstateU,#1              ' Set pressed state 3 to 1 if so
        if_c  jmp       #:down                  ' And continue to next input
        cmp             pstateU,#1 wz           ' Otherwise test if button 3 was previously pressed
        if_nz jmp       #:down                  ' If not continue to next input
        mov             pstateU,#0              ' Otherwise reset pressed 3 state
        cmp             zero,   ypos wc         ' Test if at top of tile map
        if_c  sub       ypos,   #1              ' If not decrement vertical position
:down   test            btn4,   istate wc       ' Test button 4 pressed
        if_c  mov       pstateD,#1              ' Set pressed state 4 to 1 if so
        if_c  jmp       #:write                 ' And continue to writing positions
        cmp             pstateD,#1 wz           ' Otherwise test if button 4 was previously pressed
        if_nz jmp       #:write                 ' If not continue to writing positions
        mov             pstateD,#0              ' Otherwise reset pressed 4 state
        cmp             ypos,   ybound wc       ' Test if at top of tile map
        if_c  add       ypos,   #1              ' If not increment vertical position     
:write  wrlong          xpos,   xbase           ' Write tile map pointer to tile map base
        wrlong          ypos,   ybase           ' Write tile map pointer to tile map base
        jmp             #:read                  ' Return to reading inputs

' Input attributes
btn1          long      |< 7    ' Button 1 location in input states
btn2          long      |< 6    ' Button 2 location in input states
btn3          long      |< 5    ' Button 3 location in input states
btn4          long      |< 4    ' Button 4 location in input states
pstateL       long      0       ' State of left input button
pstateR       long      0       ' State of right input button
pstateU       long      0       ' State of left input button
pstateD       long      0       ' State of right input button
zero          long      0       ' Register containing zero value

' Registers
isbase        res       1       ' Pointer to input state base in Main RAM        
pbase         res       1       ' Pointer to position base in Main RAM      
xbase         res       1       ' Pointer to position base in Main RAM      
ybase         res       1       ' Pointer to position base in Main RAM      
istate        res       1       ' Register containing input states
xpos          res       1       ' Register containing horizontal game position
ypos          res       1       ' Register containing vertical game position
xbound        res       1       ' Register containing horizontal boundry of tile map
ybound        res       1       ' Register containing vertical boundry of tile map

        fit
DAT
         org             0
 {{
 The "testing" routine tests the behavior of the "input" routine via the DE0-Nano LEDs
 }}
 testing or              dira,   Pin_LED         ' Set LED output pins
 {{
 The "loop" subroutine infinitely loops to display either input_state or tilt_state to the LEDs
 }}        
 :loop   mov             pptr,   par             ' Load Main RAM input_state address into iptr
         rdlong          ps,     pptr            ' Read input_state from Main RAM                                                        
         shl             ps,     #16             ' Shift input_state to LED positions
         mov             ledout, Pin_LED         ' Combine chosen display state with current outputs        
         xor             ledout, xormask
         and             ledout, outa
         or              ledout, ps
         mov             outa,   ledout          ' Display chosen state on LEDs                                           
         jmp             #:loop                  ' Loop infinitely
 Pin_LED       long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' DE0-Nano LED pin bitmask
 xormask       long      $FFFFFFFF                                                                       ' XOR bitmask to control outputs
 pptr          res       1                                                                               ' Pointer to input_state register in Main RAM
 ps            res       1                                                                               ' Register holding input_state
 ledout        res       1                                                                               ' Register holding final output state
         fit        
DAT
tile_maps
              '         |<------------------visible on screen-------------------------------->|<------ to right of screen ---------->|
              ' column     0      1      2      3      4      5      6      7      8      9   |  10     11     12     13     14     15
              ' just the maze
tile_map0     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 1
              word      $00_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$01_01,$01_01,$01_01,$00_00,$00_01                 ' row 2
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_01                 ' row 3
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_01                 ' row 4
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 5
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 6
              word      $00_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_01                 ' row 7
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$00_00,$01_01,$00_01                 ' row 8
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 9
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 10
              word      $00_01,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01                 ' row 11
              word      $00_01,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01                 ' row 12
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus dots
tile_map1     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 2
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 3
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 4
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 5
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 6
              word      $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 7
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 8
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 9
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 10
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 11
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 12
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus powerpills
tile_map2     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 2
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 3
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 4
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 5
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 6
              word      $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 7
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 8
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 9
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 10
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 11
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 12
              word      $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus powerpills (alt color)
tile_map3     word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 0
              word      $01_01,$01_04,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_04,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 1
              word      $01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 2
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 3
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 4
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 5
              word      $01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 6
              word      $01_01,$01_02,$01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 7
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 8
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 9
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 10
              word      $01_01,$01_02,$01_02,$01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02                 ' row 11
              word      $01_01,$01_02,$01_02,$01_01,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02                 ' row 12
              word      $01_01,$01_04,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_04,$01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02                 ' row 13
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 14

              ' maze designed for 10x10 tile screen
tile_map4     word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $01_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 1
              word      $01_01,$00_02,$00_01,$00_01,$00_01,$00_02,$00_01,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 2
              word      $01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 3
              word      $01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 4
              word      $01_01,$00_02,$00_01,$00_01,$00_02,$00_01,$00_01,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 5
              word      $01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 6
              word      $01_01,$00_02,$00_01,$00_02,$00_01,$00_01,$00_02,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 7
              word      $01_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 8
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$00_01,$00_01                 ' row 9
              word      $01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 10
              word      $01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 11
              word      $01_01,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 12
              word      $01_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 13
              word      $01_01,$01_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

tile_palettes
              ' empty tile
tile_blank    long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' box tile
tile_box      long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' tile 1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1

              ' dot tile
tile_dot      long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 2
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long      %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long      %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long      %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' power-up tile
tile_pup      long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 3
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long      %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long      %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long      %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long      %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long      %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long      %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long      %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long      %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long      %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' power-up tile
tile_pup2     long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 4
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_3_3_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_3_2_2_3_0_0_0_0_0_0
              long      %%0_0_0_0_0_3_2_2_2_2_3_0_0_0_0_0
              long      %%0_0_0_0_3_2_2_2_2_2_2_3_0_0_0_0
              long      %%0_0_0_3_2_2_2_2_2_2_2_2_3_0_0_0
              long      %%0_0_3_2_2_2_2_2_2_2_2_2_2_3_0_0
              long      %%0_0_3_2_2_2_2_2_2_2_2_2_2_3_0_0
              long      %%0_0_0_3_2_2_2_2_2_2_2_2_3_0_0_0
              long      %%0_0_0_0_3_2_2_2_2_2_2_3_0_0_0_0
              long      %%0_0_0_0_0_3_2_2_2_2_3_0_0_0_0_0
              long      %%0_0_0_0_0_0_3_2_2_3_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_3_3_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

tile_maps_8bit
              '         |<------------------visible on screen-------------------------------->|<------ to right of screen ---------->|
              ' column     0      1      2      3      4      5      6      7      8      9   |  10     11     12     13     14     15
              ' just the maze
tile_map8     word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 0
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$01_01,$01_01,$01_01,$00_01,$00_02                 ' row 2
              word      $00_04,$00_03,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_04,$00_03                 ' row 3
              word      $00_01,$00_02,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_00,$00_01,$00_02                 ' row 4
              word      $00_04,$00_03,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$00_04,$00_03                 ' row 5
              word      $00_01,$00_02,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_02                 ' row 6
              word      $00_04,$00_03,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_04,$00_03                 ' row 7
              word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 8
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 9
              word      $00_01,$00_02,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 10
              word      $00_04,$00_03,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01                 ' row 11
              word      $00_01,$00_02,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01                 ' row 12
              word      $00_04,$00_03,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 13
              word      $00_01,$00_02,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

tile_palettes_8bit
              ' empty tile
tile_blank8   word      %%1_0_0_0_0_2_0_0                       ' tile 0
              word      %%0_0_0_0_3_0_0_0
              word      %%0_2_0_0_0_0_0_3
              word      %%0_0_0_0_0_0_0_0
              word      %%0_0_0_2_0_0_0_0
              word      %%0_0_0_0_0_0_0_0
              word      %%0_1_0_0_0_0_0_0
              word      %%0_0_0_0_2_0_0_0

              ' upper left corner of box
tile_box_tl   word      %%1_1_1_1_1_1_1_1                       ' tile 1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1

              ' upper right corner of box
tile_box_tr   word      %%1_1_1_1_1_1_1_1                       ' tile 2
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3

              ' bottom right corner of box
tile_box_br   word      %%1_3_3_3_3_3_3_3                       ' tile 3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_1_1_1_1_1_1_1

              ' bottom left corner of box
tile_box_bl   word      %%3_3_3_3_3_3_3_1                       ' tile 4
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%1_1_1_1_1_1_1_1

color_palettes
              ' Test palettes
c_palette1    long      %11000011_00110011_00011111_00000011                    ' palette 0 - background and wall tiles, 0-black,
                                                                                ' 1-blue, 2-red, 3-white
c_palette2    long      %00000011_00110011_11111111_11000011                    ' palette 1 - background and wall tiles, 0-black,

input_states
              ' Input states
control_state word      0       ' Control states
tilt_state    word      0       ' Tilt shift state 

position
              ' Current position
cur_pos_x     long      0       ' Current horizontal tile position       
cur_pos_y     long      0       ' Current vertical tile position       