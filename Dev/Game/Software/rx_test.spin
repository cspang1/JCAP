{{
        File:     txrx.spin
        Author:   Connor Spangler
        Date:     5/9/2018
        Version:  1.0
        Description: 
                  This file contains the PASM code defining a test transmission routine
}}

CON
  ' Clock settings
  _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
  _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

  ' Game settings
  NUM_SPRITES = 64

OBJ
  vga_rx        : "vga_rx"      ' Import graphics reception system
  vga_render    : "vga_render"  ' Import VGA render system
  vga_display   : "vga_display" ' Import VGA display system

VAR
  ' Video system pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system
  long  scanline_buff_base_     ' Register in Main RAM containing the scanline buffer
  long  gfx_buffer_base_        ' Register in Main RAM containing the graphics buffer

PUB main | time, indx
' Initialize pointers 
  cur_scanline_base_ := @cur_scanline                   ' Point current scanline base to current scanline
  scanline_buff_base_ := @scanline_buff                 ' Point video buffer base to video buffer
  'gfx_buffer_base_ := @gfx_buff                         ' Point graphics buffer base to graphics buffer
  gfx_buffer_base_ := @gfx_buff_tmp                     ' Point graphics buffer base to graphics buffer

  vga_render.start(@cur_scanline_base_)                 ' Start renderers
  vga_display.start(@cur_scanline_base_)                ' Start display driver
  vga_rx.start(@gfx_buffer_base_)                       ' Start video data RX driver

DAT

cur_scanline  long      0       ' Current scanline being rendered
scanline_buff long      0[80]   ' Video buffer

{{
              Graphics Buffer Layout:
              $0000 - $01FF     Tile Color Palettes     }
              $0200 - $03FF     Sprite Color Palettes   }___ Transfered
              $0400 - $04FF     Sprite Attribute Table  }     from CPU
              $0500 - $0E5F     Tile Map                }
              -------------
              $0E60 - $2E59     Tile Palettes           }___ Stored statically
              $2E60 - $4E59     Sprite Palettes         }       within GPU
}}
gfx_buff      long      0[((32*16)*2+(64*4)+(40*30*2))/4]

gfx_buff_tmp

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

              long      0[120]

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

              long      0[120]

              ' Sprite attribute table
sprite_atts   long      0[64]

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

tp_fill       long      0[2008]

sprite_palettes
              ' Ship sprite
sprite_ship   long      $0_0_0_0_1_0_0_0        ' Sprite 0
              long      $0_0_0_1_1_1_0_0
              long      $0_0_0_0_1_0_0_0
              long      $0_0_0_0_1_0_0_0
              long      $0_0_0_1_1_1_0_0
              long      $0_0_1_2_2_2_1_0
              long      $0_4_1_3_3_3_1_6
              long      $0_4_1_0_3_0_1_6

              ' Rock sprite
sprite_rock   long      $0_0_0_0_0_0_0_0        ' Sprite 1
              long      $4_4_0_0_0_0_0_0
              long      $1_1_1_0_0_0_0_0
              long      $0_3_2_1_0_0_1_0
              long      $3_3_2_1_1_1_1_1
              long      $0_3_2_1_0_0_1_0
              long      $1_1_1_0_0_0_0_0
              long      $6_6_0_0_0_0_0_0

              ' Blank sprite
sprite_blank  long      $5_5_5_5_5_5_5_5        ' Sprite 2
              long      $F_F_F_F_F_F_F_F
              long      $4_4_4_4_4_4_4_4
              long      $F_F_F_F_F_F_F_F
              long      $6_6_6_6_6_6_6_6
              long      $F_F_F_F_F_F_F_F
              long      $8_8_8_8_8_8_8_8
              long      $F_F_F_F_F_F_F_F

sp_fill       long      0[2024]
