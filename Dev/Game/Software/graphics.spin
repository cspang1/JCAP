{{
        File:     graphics.spin
        Author:   Connor Spangler
        Date:     11/3/2017
        Version:  2.0
        Description: 
                  This file contains the PASM code defining a test arcade game
}}

CON
  ' Clock settings
  _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
  _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz    

OBJ          
  vga_render    : "vga_render"  ' Import VGA display system
  vga_display   : "vga_display" ' Import VGA display system
  input         : "input"       ' Import input system
  
VAR
  ' Video resource pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system
  long  video_buffer_base_      ' Registers in Main RAM containing the scanline buffer

  ' Graphics resource pointers
  long  tile_map_base_          ' Register pointing to base of tile maps
  long  tile_palette_base_      ' Register pointing to base of tile palettes
  long  tcolor_palette_base_    ' Register pointing to base of tile color palettes
  long  sprite_att_base_        ' Register pointing to base of sprite attribute table
  long  sprite_palette_base_    ' Register pointing to base of sprite palettes
  long  scolor_palette_base_    ' Register pointing to base of sprite color palettes

  ' Game resource pointers
  long  input_state_base_       ' Register in Main RAM containing state of inputs

PUB main
  ' Initialize pointers
  cur_scanline_base_ := @cur_scanline                   ' Point current scanline to current scanline
  video_buffer_base_ := @video_buffer                   ' Point video buffer to base of video buffer
  tile_map_base_ := @tile_maps                          ' Point tile map base to base of tile maps
  tile_palette_base_ := @tile_palettes                  ' Point tile palette base to base of tile palettes
  tcolor_palette_base_ := @tile_color_palettes          ' Point tile color palette base to base of tile color palettes
  sprite_att_base_ := @sprite_atts                      ' Point sprite attribute table base to base of sprite attribute table
  sprite_palette_base_ := @sprite_palettes              ' Point sprite palette base to base of sprite palettes
  scolor_palette_base_ := @sprite_color_palettes        ' Point sprite color palette base to base of sprite color palettes
  input_state_base_ := @input_states                    ' Point input stat base to base of input states

  ' Start video system
  vga_render.start(@cur_scanline_base_)                 ' Start renderers
  vga_display.start(@cur_scanline_base_)                ' Start display driver

  ' Start input system
  input.start(@input_state_base_)                       ' Start input system

  ' Start test system
  'cognew(@tester, sprite_att_base_)
      
DAT
        org             0

tester  mov             time,   cnt
        add             time,   delay
loop    mov             temp,   par
        wrlong          satt0,  temp
        add             temp,   #4
        wrlong          satt1,  temp
        add             temp,   #4
        wrlong          satt2,  temp
        add             temp,   #4
        wrlong          satt3,  temp
        add             temp,   #4
        wrlong          satt4,  temp
        add             temp,   #4
        wrlong          satt5,  temp
        add             temp,   #4
        wrlong          satt6,  temp
        add             temp,   #4
        wrlong          satt7,  temp

        waitcnt         time,   delay
        mov             temp,   satt2
        shr             temp,   #7
        and             temp,   #255
        add             temp,   #1
        and             temp,   #255
        cmp             temp,   #240 wz
        if_z  mov       temp,   #249
        shl             temp,   #7
        and             satt2,  ymask
        or              satt2,  temp

        mov             temp,   satt2
        shr             temp,   #15             ' Shift horizontal position to LSB
        and             temp,   #511            ' Mask out horizontal position
        add             temp,   #1
        and             temp,   #511
        cmp             temp,   #320 wz
        if_z  mov       temp,   #505
        shl             temp,   #15
        and             satt2,  xmask
        or              satt2,  temp

        mov             temp,   satt3
        shr             temp,   #7
        and             temp,   #255
        add             temp,   #1
        and             temp,   #255
        cmp             temp,   #240 wz
        if_z  mov       temp,   #249
        shl             temp,   #7
        and             satt3,  ymask
        or              satt3,  temp

        mov             temp,   satt3
        shr             temp,   #15             ' Shift horizontal position to LSB
        and             temp,   #511            ' Mask out horizontal position
        add             temp,   #1
        and             temp,   #511
        cmp             temp,   #320 wz
        if_z  mov       temp,   #505
        shl             temp,   #15
        and             satt3,  xmask
        or              satt3,  temp

        mov             temp,   satt4
        shr             temp,   #7
        and             temp,   #255
        add             temp,   #1
        and             temp,   #255
        cmp             temp,   #240 wz
        if_z  mov       temp,   #249
        shl             temp,   #7
        and             satt4,  ymask
        or              satt4,  temp

        mov             temp,   satt4
        shr             temp,   #15             ' Shift horizontal position to LSB
        and             temp,   #511            ' Mask out horizontal position
        add             temp,   #1
        and             temp,   #511
        cmp             temp,   #320 wz
        if_z  mov       temp,   #505
        shl             temp,   #15
        and             satt4,  xmask
        or              satt4,  temp

        jmp             #loop

'                            sprite         x position       y position    color v h size
'                       |<------------->|<--------------->|<------------->|<--->|-|-|<->|
'                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
satt0         long      %0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
satt1         long      %0_0_0_0_0_0_0_0_0_0_0_0_0_1_0_0_0_1_0_0_0_1_0_0_0_0_0_0_0_0_0_0
satt2         long      %0_0_0_0_0_0_0_0_0_1_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
satt3         long      %0_0_0_0_0_0_0_0_0_0_0_0_1_1_0_0_0_0_1_1_1_1_0_0_0_0_0_0_0_0_0_0
satt4         long      %0_0_0_0_0_0_0_0_0_0_0_1_0_0_0_0_0_1_0_1_0_0_0_1_1_0_0_0_0_0_0_0
satt5         long      %0_0_0_0_0_0_0_0_0_0_1_1_0_1_0_0_0_0_1_1_0_1_0_1_1_0_0_0_0_0_0_0
satt6         long      %0_0_0_0_0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0_0_0_0_0
satt7         long      %0_0_0_0_0_0_0_0_0_1_0_1_1_1_1_1_1_0_0_1_1_1_1_1_1_0_0_0_0_0_0_0

ymask         long      %1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_0_0_0_0_0_0_0_0_1_1_1_1_1_1_1
xmask         long      %1_1_1_1_1_1_1_1_0_0_0_0_0_0_0_0_0_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1

delay         long      2000000

time          res       1
temp          res       1

        fit

DAT
cur_scanline  long      0       ' Current scanline being rendered
video_buffer  long      0[80]   ' Video buffer

tile_maps
              ' Main tile map
tile_map0     word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 0
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 1
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 2
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 3
              word      $00_01,$00_02,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$00_01,$00_02                 ' row 4
              word      $00_04,$00_03,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$00_04,$00_03                 ' row 5
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 6
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 7
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 8
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 9
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 10
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$00_04,$00_03                 ' row 11
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$00_01,$00_02                 ' row 12
              word      $00_04,$00_03,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 13
              word      $00_01,$00_02,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 14
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 15
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 16
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 17
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 18
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 19
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 20
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 21
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 22
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 23
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 24
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 25
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 26
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 27
              word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 28
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 29

tile_palettes
              ' Empty tile
tile_blank    long      $0_0_0_0_0_0_0_0        ' Tile 0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0

              ' Upper left corner of box
tile_box_tl   long      $1_1_1_1_1_1_1_1        ' Tile 1
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2

              ' Upper right corner of box
tile_box_tr   long      $1_1_1_1_1_1_1_1        ' Tile 2
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1

              ' Bottom right corner of box
tile_box_br   long      $2_2_2_2_2_2_2_1        ' Tile 3
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $1_1_1_1_1_1_1_1

              ' Bottom left corner of box
tile_box_bl   long      $1_2_2_2_2_2_2_2        ' Tile 4
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_1_1_1_1_1_1_1

tile_color_palettes
              ' Tile color palettes
t_palette0    byte      %00000011,%11000011,%00001111,%11111111                    ' Tile color palette 0
              byte      %11110011,%00111111,%11001111,%11000011
              byte      %11010011,%00110111,%01001111,%01111011
              byte      %11010111,%01110111,%01011111,%00000011
t_palette1    byte      %00000011,%11110011,%11001111,%11000011                    ' Tile color palette 1
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011

sprite_atts
              ' Sprite attribute table
              long      0[8]    ' How many sprites supported?

sprite_palettes
              ' Ship sprite
sprite_ship   long      $0_0_0_0_1_0_0_0        ' Sprite 0
              long      $0_0_0_1_1_1_0_0
              long      $0_0_0_0_1_0_0_0
              long      $0_0_0_0_1_0_0_0
              long      $0_0_0_1_1_1_0_0
              long      $0_0_1_2_2_2_1_0
              long      $0_1_1_3_3_3_1_1
              long      $0_1_1_0_3_0_1_1

sprite_color_palettes
              ' Sprite color palettes
s_palette0    byte      %00000000,%00110011,%11000011,%11111111                    ' Tile color palette 0
              byte      %11110011,%00111111,%11001111,%11000011
              byte      %11010011,%00110111,%01001111,%01111011
              byte      %11010111,%01110111,%01011111,%00000011
s_palette1    byte      %00000000,%00110011,%11111111,%11000011                    ' Tile color palette 1
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011

input_states
              ' Input states
control_state word      0       ' Control states
tilt_state    word      0       ' Tilt shift state              