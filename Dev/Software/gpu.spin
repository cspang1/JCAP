{{
        File:     gpu.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code defining a JCAP GPU
}}

CON
    ' Clock settings
    _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
    _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

    ' Pin settings
    VS_PIN = 0
    RX_PIN = 1

OBJ
    system        : "system"      ' Import system settings
    gfx_rx        : "rx"          ' Import graphics reception system
    vga_render    : "vga_render"  ' Import VGA render system
    vga_display   : "vga_display" ' Import VGA display system

VAR
    ' Video system pointers
    long  gfx_buffer_base_        ' Register pointing to graphics resources buffer
    long  gfx_buffer_size_        ' Size of the graphics buffer
    long  data_ready_base_        ' Register pointing to data status indicator
    long  cur_scanline_base_      ' Register pointing to current scanline being requested by the VGA Display system
    long  scanline_buff_base_     ' Register pointing to scanline buffer
    long  horizontal_position_    ' Register pointing to base of tile color palettes
    long  tcolor_palette_base_    ' Register pointing to base of tile color palettes
    long  scolor_palette_base_    ' Register pointing to base of sprite color palettes
    long  sprite_att_base_        ' Register pointing to base of sprite attribute table
    long  tile_map_base_          ' Register pointing to base of tile maps
    long  tile_palette_base_      ' Register pointing to base of tile palettes
    long  sprite_palette_base_    ' Register pointing to base of sprite palettes

PUB main | rx1, rx2
    ' Set unused pin states
    dira[2..15]~~
    dira[26..27]~~
    outa[2..15]~
    outa[26..27]~

    ' Initialize graphics system pointers
    gfx_buffer_base_ := @gfx_buff                                                   ' Point graphics buffer base to graphics buffer
    gfx_buffer_size_ := system#GFX_BUFFER_SIZE                                      ' Set the size of the graphics resources buffer
    cur_scanline_base_ := @cur_scanline                                             ' Point current scanline base to current scanline
    data_ready_base_ := @data_ready                                                 ' Point data ready base to data ready indicator
    scanline_buff_base_ := @scanline_buff                                           ' Point video buffer base to video buffer
    horizontal_position_ := gfx_buffer_base_                                        ' Point tile color palette base to base of tile color palettes
    tcolor_palette_base_ := horizontal_position_+system#NUM_PARALLAX_REGS*4         ' Point tile color palette base to base of tile color palettes
    scolor_palette_base_ := tcolor_palette_base_+system#NUM_TILE_COLOR_PALETTES*4*4 ' Point sprite color palette base to base of sprite color palettes
    sprite_att_base_ := scolor_palette_base_+system#NUM_SPRITE_COLOR_PALETTES*4*4   ' Point sprite attribute table base to base of sprite attribute table
    tile_map_base_ := sprite_att_base_+system#SAT_SIZE*4                            ' Point tile map base to base of tile maps
    tile_palette_base_ := @tile_palettes                                            ' Point tile palette base to base of tile palettes
    sprite_palette_base_ := @sprite_palettes                                        ' Point sprite palette base to base of sprite palettes

    ' Start subsystems
    rx1 := constant(NEGX|RX_PIN)
    rx2 := constant(system#GFX_BUFFER_SIZE << 16) | @gfx_buff
    gfx_rx.start(@rx1, VS_PIN, RX_PIN)                       ' Start video data RX driver
    repeat while rx1
    vga_display.start(@data_ready_base_)                  ' Start display driver
    vga_render.start(@data_ready_base_)                   ' Start renderers

DAT

              ' Graphics engine resources
data_ready    long      0                       ' Graphics data ready indicator
cur_scanline  long      0                       ' Current scanline being rendered
scanline_buff long      0[system#VID_BUFFER_SIZE]      ' Video buffer
gfx_buff      long      0[system#GFX_BUFFER_SIZE]      ' Graphics resources buffer

tile_palettes ' Tile # - relative x,y

              ' Empty tile
empty           long      $0_0_0_0_0_0_0_0        ' Tile 0
                long      $0_0_0_0_0_0_0_0
                long      $0_0_0_0_0_0_0_0
                long      $0_0_0_0_0_0_0_0
                long      $0_0_0_0_0_0_0_0
                long      $0_0_0_0_0_0_0_0
                long      $0_0_0_0_0_0_0_0
                long      $0_0_0_0_0_0_0_0

sky             long      $3_3_3_3_3_3_3_3        ' Tile 1
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

sun             long      $2_2_2_2_2_2_2_2        ' Tile 2 - inside sun
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $9_A_9_A_9_A_9_A        ' Tile 3 - 0,1
                long      $A_9_A_9_A_9_A_9
                long      $B_A_B_A_B_A_B_A
                long      $A_B_A_B_A_B_A_B
                long      $B_A_B_B_B_A_B_B
                long      $B_B_B_B_B_B_B_1
                long      $B_B_B_B_B_B_B_1
                long      $B_B_B_B_B_B_B_1

                long      $1_2_2_2_2_2_2_2        ' Tile 4 - 1,1
                long      $1_2_2_2_2_2_2_2
                long      $1_2_2_2_2_2_2_2
                long      $1_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $9_8_9_8_1_2_2_2        ' Tile 5 - 1,2
                long      $8_9_8_1_2_2_2_2
                long      $9_8_9_1_2_2_2_2
                long      $8_9_1_2_2_2_2_2
                long      $9_8_1_2_2_2_2_2
                long      $9_9_1_2_2_2_2_2
                long      $9_1_2_2_2_2_2_2
                long      $A_1_2_2_2_2_2_2

                long      $8_8_8_8_8_8_8_8        ' Tile 6 - 1,8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_1
                long      $8_8_8_8_8_8_1_2
                long      $8_8_8_8_8_8_1_2
                long      $8_8_8_8_8_1_2_2
                long      $8_8_8_8_1_2_2_2

                long      $8_1_2_2_2_2_2_2        ' Tile 7 - 2,3
                long      $1_2_2_2_2_2_2_2
                long      $1_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $7_8_7_8_7_8_7_8        ' Tile 8 - 2,4
                long      $8_7_8_7_8_7_8_7
                long      $7_8_7_8_7_8_7_1
                long      $8_7_8_7_8_7_1_2
                long      $7_8_8_8_7_1_2_2
                long      $8_8_8_8_1_2_2_2
                long      $8_8_8_1_2_2_2_2
                long      $8_8_1_2_2_2_2_2

                long      $7_1_1_2_2_2_2_2        ' Tile 9 - 3,4
                long      $1_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $7_7_7_7_7_7_7_7        ' Tile A - 3,5
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_1
                long      $7_7_7_7_7_7_1_2
                long      $7_7_7_7_1_1_2_2
                long      $7_7_7_1_2_2_2_2

                long      $7_7_7_7_7_7_7_7        ' Tile B - 4,5
                long      $7_7_7_7_7_7_1_1
                long      $7_7_7_1_1_1_2_2
                long      $7_1_1_2_2_2_2_2
                long      $1_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $1_1_1_1_2_2_2_2        ' Tile C - 5,5
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $6_7_6_7_6_7_6_7        ' Tile D - 5,6
                long      $7_6_7_6_7_6_7_6
                long      $6_7_6_7_6_7_6_7
                long      $7_6_7_6_7_6_7_6
                long      $6_7_7_7_6_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_1_1_1_1

                long      $6_7_6_7_6_7_6_7        ' Tile E - 6,6
                long      $7_6_7_6_7_6_7_6
                long      $6_7_6_7_6_7_6_7
                long      $7_6_7_6_7_6_7_6
                long      $6_7_7_7_6_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_1_1_1_1_1_1_1
                long      $1_2_2_2_2_2_2_2

sun2            long      $9_A_9_A_9_A_9_A        ' Tile 3 - 0,1
                long      $A_9_A_9_A_9_A_9
                long      $B_A_B_A_B_A_B_A
                long      $A_B_A_B_A_B_A_B
                long      $B_A_B_B_B_A_B_B
                long      $1_B_B_B_B_B_B_B
                long      $1_B_B_B_B_B_B_B
                long      $1_B_B_B_B_B_B_B

                long      $2_2_2_2_2_2_2_1        ' Tile 4 - 1,1
                long      $2_2_2_2_2_2_2_1
                long      $2_2_2_2_2_2_2_1
                long      $2_2_2_2_2_2_2_1
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $2_2_2_1_9_8_9_8        ' Tile 5 - 1,2
                long      $2_2_2_2_1_9_8_9
                long      $2_2_2_2_1_8_9_8
                long      $2_2_2_2_2_1_8_9
                long      $2_2_2_2_2_1_9_9
                long      $2_2_2_2_2_1_9_9
                long      $2_2_2_2_2_2_1_9
                long      $2_2_2_2_2_2_1_A

                long      $8_8_8_8_8_8_8_8        ' Tile 6 - 1,3
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $1_8_8_8_8_8_8_8
                long      $2_1_8_8_8_8_8_8
                long      $2_1_8_8_8_8_8_8
                long      $2_2_1_8_8_8_8_8
                long      $2_2_2_1_8_8_8_8

                long      $2_2_2_2_2_2_1_8        ' Tile 7 - 2,3
                long      $2_2_2_2_2_2_2_1
                long      $2_2_2_2_2_2_2_1
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $7_8_7_8_7_8_7_8        ' Tile 8 - 2,4
                long      $8_7_8_7_8_7_8_7
                long      $1_8_7_8_7_8_7_8
                long      $2_1_8_7_8_7_8_7
                long      $2_2_1_8_7_8_8_8
                long      $2_2_2_1_8_8_8_8
                long      $2_2_2_2_1_8_8_8
                long      $2_2_2_2_2_1_8_8

                long      $2_2_2_2_2_1_1_8        ' Tile 9 - 3,4
                long      $2_2_2_2_2_2_2_1
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $7_7_7_7_7_7_7_7        ' Tile A - 3,5
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $1_7_7_7_7_7_7_7
                long      $2_1_7_7_7_7_7_7
                long      $2_2_1_1_7_7_7_7
                long      $2_2_2_2_1_7_7_7

                long      $7_7_7_7_7_7_7_7        ' Tile B - 4,5
                long      $1_1_7_7_7_7_7_7
                long      $2_2_1_1_1_7_7_7
                long      $2_2_2_2_2_1_1_7
                long      $2_2_2_2_2_2_2_1
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $2_2_2_2_1_1_1_1        ' Tile C - 5,5
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $6_7_6_7_6_7_6_7        ' Tile D - 5,6
                long      $7_6_7_6_7_6_7_6
                long      $6_7_6_7_6_7_6_7
                long      $7_6_7_6_7_6_7_6
                long      $7_7_6_7_7_7_6_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $1_1_1_1_7_7_7_7

                long      $6_7_6_7_6_7_6_7        ' Tile E - 6,6
                long      $7_6_7_6_7_6_7_6
                long      $6_7_6_7_6_7_6_7
                long      $7_6_7_6_7_6_7_6
                long      $7_7_6_7_7_7_6_7
                long      $7_7_7_7_7_7_7_7
                long      $1_1_1_1_1_1_1_7
                long      $2_2_2_2_2_2_2_1

ground          long      $4_4_4_4_4_4_4_4        ' Tile 1B
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4

sky1            long      $5_5_5_5_5_5_5_5        ' Tile 1C
                long      $5_5_5_5_5_5_5_5
                long      $5_5_5_5_5_5_5_5
                long      $5_5_5_5_5_5_5_5
                long      $5_5_5_5_5_5_5_5
                long      $5_5_5_5_5_5_5_5
                long      $5_5_5_5_5_5_5_5
                long      $5_5_5_5_5_5_5_5

sky2            long      $6_6_6_6_6_6_6_6        ' Tile 1D
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6

sky3            long      $7_7_7_7_7_7_7_7        ' Tile 1E
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7

sky4            long      $8_8_8_8_8_8_8_8        ' Tile 1F
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8

sky5            long      $9_8_9_8_9_8_9_8        ' Tile 20
                long      $8_9_8_9_8_9_8_9
                long      $9_8_9_8_9_8_9_8
                long      $8_9_8_9_8_9_8_9
                long      $9_8_9_9_9_8_9_9
                long      $9_9_9_9_9_9_9_9
                long      $9_9_9_9_9_9_9_9
                long      $A_9_A_9_A_9_A_9

sky6            long      $9_A_9_A_9_A_9_A        ' Tile 21
                long      $A_9_A_9_A_9_A_9
                long      $B_A_B_A_B_A_B_A
                long      $A_B_A_B_A_B_A_B
                long      $B_A_B_B_B_A_B_B
                long      $B_B_B_B_B_B_B_B
                long      $C_B_C_B_C_B_C_B
                long      $C_C_C_C_C_C_C_C

skyt1           long      $5_6_5_6_5_6_5_6        ' Tile 22
                long      $6_5_6_5_6_5_6_5
                long      $5_6_5_6_5_6_5_6
                long      $6_5_6_5_6_5_6_5
                long      $5_6_6_6_5_6_6_6
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6
                long      $6_6_6_6_6_6_6_6

skyt2           long      $6_7_6_7_6_7_6_7        ' Tile 23
                long      $7_6_7_6_7_6_7_6
                long      $6_7_6_7_6_7_6_7
                long      $7_6_7_6_7_6_7_6
                long      $6_7_7_7_6_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7
                long      $7_7_7_7_7_7_7_7

skyt3           long      $7_8_7_8_7_8_7_8        ' Tile 24
                long      $8_7_8_7_8_7_8_7
                long      $7_8_7_8_7_8_7_8
                long      $8_7_8_7_8_7_8_7
                long      $7_8_8_8_7_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8
                long      $8_8_8_8_8_8_8_8

sea             long      $5_5_5_5_5_5_5_5        ' Tile 25
                long      $5_5_1_1_1_5_1_5
                long      $2_2_5_2_5_2_2_2
                long      $2_2_2_2_2_5_2_2
                long      $3_3_5_3_3_3_3_5
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

                long      $5_5_5_5_5_5_5_5        ' Tile 26
                long      $1_1_1_5_1_1_5_5
                long      $5_2_5_2_2_2_2_2
                long      $2_2_2_2_2_5_2_2
                long      $3_3_3_5_5_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

                long      $5_5_5_5_5_5_5_5        ' Tile 27
                long      $1_5_1_1_1_1_1_1
                long      $2_2_5_5_5_2_2_2
                long      $2_2_2_2_2_2_5_5
                long      $5_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

                long      $4_4_4_4_4_4_4_4        ' Tile 28
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4       

reflect         long      $0_0_5_0_5_5_0_5        ' Tile 29
                long      $5_5_5_0_0_5_5_5
                long      $5_0_5_5_5_5_0_5
                long      $5_5_5_0_0_0_5_5
                long      $0_0_5_5_5_5_5_0
                long      $5_0_5_5_0_0_5_0
                long      $5_5_0_5_5_0_5_5
                long      $0_0_5_0_0_5_5_5

                long      $1_1_1_1_1_1_1_1        ' Tile 2A
                long      $1_1_1_1_1_1_1_1
                long      $1_1_1_1_1_1_1_1
                long      $1_1_1_1_1_1_1_1
                long      $1_1_1_1_1_1_1_1
                long      $1_1_1_1_1_1_1_1
                long      $1_1_1_1_1_1_1_1
                long      $1_1_1_1_1_1_1_1

                long      $2_2_2_2_2_2_2_2        ' Tile 2B
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2

                long      $3_3_3_3_3_3_3_3        ' Tile 2C
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

ref_left        long      $5_5_5_5_0_0_5_5        ' Tile 2D
                long      $1_1_1_5_5_5_5_0
                long      $2_2_1_1_1_1_1_1
                long      $2_2_2_2_2_2_1_1
                long      $3_3_3_3_2_2_2_2
                long      $3_3_3_3_3_3_3_2
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

                long      $0_5_5_5_0_0_5_5        ' Tile 2E
                long      $5_5_0_5_5_5_5_5
                long      $1_1_1_1_1_1_0_5
                long      $1_1_1_1_1_1_1_1
                long      $2_2_2_2_2_2_1_1
                long      $2_2_2_2_2_2_2_2
                long      $3_3_3_3_3_3_2_2
                long      $3_3_3_3_3_3_3_3

                long      $3_3_2_2_1_1_5_5        ' Tile 2F
                long      $4_3_3_2_2_1_1_0
                long      $4_4_3_3_2_2_1_1
                long      $4_4_4_3_3_2_2_1
                long      $4_4_4_4_3_3_2_2
                long      $4_4_4_4_4_3_3_2
                long      $4_4_4_4_4_4_3_3
                long      $4_4_4_4_4_4_4_3

                long      $5_5_5_5_0_5_0_5        ' Tile 30
                long      $5_0_0_5_5_5_5_0
                long      $5_5_5_5_0_5_5_5
                long      $1_5_0_0_5_5_0_5
                long      $1_1_5_5_5_0_5_5
                long      $2_1_1_0_5_5_5_5
                long      $2_2_1_1_5_5_0_0
                long      $3_2_2_1_1_0_5_5

ref_right       long      $5_5_0_5_0_0_5_5        ' Tile 31
                long      $0_5_5_5_5_1_1_1
                long      $1_1_1_1_1_1_2_2
                long      $1_1_2_2_2_2_2_2
                long      $2_2_2_2_3_3_3_3
                long      $2_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

                long      $0_0_5_5_5_0_5_5        ' Tile 32
                long      $5_5_5_0_0_5_5_5
                long      $5_5_1_1_1_1_1_1
                long      $1_1_1_1_1_1_1_1
                long      $1_1_2_2_2_2_2_2
                long      $2_2_2_2_2_2_2_2
                long      $2_2_3_3_3_3_3_3
                long      $3_3_3_3_3_3_3_3

                long      $5_5_1_1_2_2_3_3        ' Tile 33
                long      $0_1_1_2_2_3_3_4
                long      $1_1_2_2_3_3_4_4
                long      $1_2_2_3_3_4_4_4
                long      $2_2_3_3_4_4_4_4
                long      $2_3_3_4_4_4_4_4
                long      $3_3_4_4_4_4_4_4
                long      $3_4_4_4_4_4_4_4

                long      $0_5_5_0_5_0_5_5        ' Tile 34
                long      $5_0_0_5_5_5_5_0
                long      $5_5_5_5_0_5_5_5
                long      $5_0_5_5_5_5_0_1
                long      $5_5_5_0_0_5_1_1
                long      $0_0_5_5_5_1_1_2
                long      $5_5_5_0_1_1_2_2
                long      $0_5_5_1_1_2_2_3

sea_spec_ref    long      $4_4_4_4_4_4_4_4        ' Tile 35
                long      $4_4_4_4_4_4_1_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_5_4_4_4_5
                long      $4_4_4_4_4_4_4_4

                long      $1_4_1_4_4_4_4_4        ' Tile 36
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_5_4_4_5_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_1_4_4_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_5_4_4

                long      $4_4_4_4_4_4_1_4        ' Tile 37
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_4_1
                long      $5_4_4_4_4_4_4_4
                long      $4_4_4_4_5_4_4_4
                long      $4_4_4_4_4_4_4_4
                long      $4_4_4_4_4_4_1_4
                long      $4_4_4_4_4_4_4_4

waterfall       long      $B_B_A_A_9_9_8_8        ' Tile 38
                long      $8_B_B_A_A_9_9_8
                long      $8_8_B_B_A_A_9_9
                long      $9_8_8_B_B_A_A_9
                long      $9_9_8_8_B_B_A_A
                long      $A_9_9_8_8_B_B_A
                long      $A_A_9_9_8_8_B_B
                long      $B_A_A_9_9_8_8_B

                long      $8_8_9_9_A_A_B_B        ' Tile 39
                long      $8_9_9_A_A_B_B_8
                long      $9_9_A_A_B_B_8_8
                long      $9_A_A_B_B_8_8_9
                long      $A_A_B_B_8_8_9_9
                long      $A_B_B_8_8_9_9_A
                long      $B_B_8_8_9_9_A_A
                long      $B_8_8_9_9_A_A_B

waterfall_top   long      $4_4_4_4_4_4_4_4        ' Tile 3A
                long      $B_4_A_4_8_4_8_4
                long      $4_A_4_9_4_8_4_8
                long      $B_A_8_8_9_8_8_8
                long      $9_A_A_9_8_8_8_8
                long      $B_8_A_8_8_8_8_8
                long      $B_A_8_9_9_8_8_8
                long      $B_A_A_9_9_8_8_8

                long      $4_4_4_4_4_4_4_4        ' Tile 3B
                long      $8_4_8_4_8_4_8_4
                long      $4_8_4_9_4_8_4_8
                long      $8_8_8_9_8_8_A_B
                long      $8_8_8_8_9_A_A_9
                long      $8_8_8_8_8_A_8_B
                long      $8_8_8_9_9_8_A_B
                long      $8_8_8_9_9_A_A_B

rock_wtfl_right long      $4_4_4_4_4_4_4_4        ' Tile 3C
                long      $8_4_8_4_8_4_8_4
                long      $4_8_4_8_4_F_F_F
                long      $8_8_8_9_F_E_E_E
                long      $8_8_8_F_E_E_D_D
                long      $8_8_8_8_F_E_D_C
                long      $8_8_8_F_E_E_E_E
                long      $8_8_8_F_E_D_E_C

                long      $4_4_4_4_4_4_4_4        ' Tile 3D
                long      $4_4_4_4_F_4_4_4
                long      $4_F_4_F_E_F_F_F
                long      $F_E_F_E_E_E_E_E
                long      $E_E_E_E_D_C_D_D
                long      $D_D_D_D_C_D_D_C
                long      $C_C_E_C_C_D_E_E
                long      $C_E_D_E_C_E_E_C

                long      $B_B_F_E_E_D_C_D        ' Tile 3E
                long      $8_B_B_F_E_C_C_E
                long      $8_8_F_E_E_D_D_D
                long      $9_8_8_F_E_E_D_C
                long      $9_9_8_F_E_D_D_E
                long      $A_9_9_8_F_E_C_E
                long      $A_A_9_F_E_E_C_C
                long      $B_A_A_F_E_D_D_D

                long      $C_C_E_C_C_C_E_C        ' Tile 3F
                long      $C_C_D_E_C_E_D_C
                long      $C_D_D_E_C_D_D_E
                long      $D_D_C_C_D_C_E_C
                long      $D_E_D_C_C_C_E_C
                long      $D_E_E_E_D_C_C_E
                long      $C_E_E_E_C_C_C_E
                long      $C_D_C_D_E_C_C_C

rock_wtfl_left  long      $4_4_4_4_4_4_4_4        ' Tile 40
                long      $4_8_4_8_4_8_4_8
                long      $F_F_F_4_8_4_8_4
                long      $E_E_E_F_9_8_8_8
                long      $D_D_E_E_F_8_8_8
                long      $C_D_E_F_8_8_8_8
                long      $E_E_E_E_F_8_8_8
                long      $C_E_D_E_F_8_8_8

                long      $4_4_4_4_4_4_4_4        ' Tile 41
                long      $4_4_4_F_4_4_4_4
                long      $F_F_F_E_F_4_F_4
                long      $E_E_E_E_E_F_E_F
                long      $D_D_C_D_E_E_E_E
                long      $C_D_D_C_D_D_D_D
                long      $E_E_D_C_C_E_C_C
                long      $C_E_E_C_E_D_E_C

                long      $D_C_D_E_E_F_B_B        ' Tile 42
                long      $E_C_C_E_F_B_B_8
                long      $D_D_D_E_E_F_8_8
                long      $C_D_E_E_F_8_8_9
                long      $E_D_D_E_F_8_9_9
                long      $E_C_E_F_8_9_9_A
                long      $C_C_E_E_F_9_A_A
                long      $D_D_D_E_F_A_A_B

                long      $C_E_C_C_C_E_C_C        ' Tile 43
                long      $C_D_E_C_E_D_C_C
                long      $E_D_D_C_E_D_D_C
                long      $C_E_C_D_C_C_D_D
                long      $C_E_C_C_C_D_E_D
                long      $E_C_C_D_E_E_E_D
                long      $E_C_C_C_E_E_E_C
                long      $C_C_C_E_D_C_D_C

wfall_split     long      $B_B_A_A_9_9_8_8        ' Tile 44
                long      $A_8_9_A_A_9_9_8
                long      $E_E_E_A_9_A_9_9
                long      $D_D_E_E_9_A_A_9
                long      $C_C_D_E_E_9_A_A
                long      $C_D_D_E_E_A_9_A
                long      $D_E_E_E_8_B_B_9
                long      $E_E_F_F_8_8_B_B

                long      $F_F_F_A_A_A_B_B        ' Tile 45
                long      $F_F_F_F_F_B_A_A
                long      $F_F_F_F_F_8_B_B
                long      $F_F_F_F_8_8_8_8
                long      $F_F_F_9_9_9_9_8
                long      $F_F_F_9_A_A_9_9
                long      $F_F_F_F_B_B_A_A
                long      $F_F_F_F_B_B_B_B

                long      $8_8_9_9_A_A_B_B        ' Tile 46
                long      $8_9_9_A_A_9_8_A
                long      $9_9_A_9_A_E_E_E
                long      $9_A_A_9_E_E_D_D
                long      $A_A_9_E_E_D_C_C
                long      $A_9_A_E_E_D_D_C
                long      $9_B_B_8_E_E_E_D
                long      $B_B_8_8_F_F_E_E

                long      $B_B_A_A_A_F_F_F        ' Tile 47
                long      $A_A_B_F_F_F_F_F
                long      $B_B_8_F_F_F_F_F
                long      $8_8_8_8_F_F_F_F
                long      $8_9_9_9_9_F_F_F
                long      $9_9_A_A_9_F_F_F
                long      $A_A_B_B_F_F_F_F
                long      $B_B_B_B_F_F_F_F

sprite_palettes
              ' Mario top left sprite
mario_tl      long      $0_0_0_0_0_1_1_1        ' Sprite 0
              long      $0_0_0_0_1_1_1_1
              long      $0_0_0_0_2_2_2_3
              long      $0_0_0_2_3_2_3_3
              long      $0_0_0_2_3_2_2_3
              long      $0_0_0_2_2_3_3_3
              long      $0_0_0_0_0_3_3_3
              long      $0_0_0_0_2_2_1_2

              ' Mario top right sprite
mario_tr      long      $1_1_0_0_0_0_0_0        ' Sprite 1
              long      $1_1_1_1_1_0_0_0
              long      $3_2_3_0_0_0_0_0
              long      $3_2_3_3_3_0_0_0
              long      $3_3_2_3_3_3_0_0
              long      $3_2_2_2_2_0_0_0
              long      $3_3_3_3_0_0_0_0
              long      $2_2_0_0_0_0_0_0

              ' Mario bottom left sprite
mario_bl      long      $0_0_0_2_2_2_1_2        ' Sprite 2
              long      $0_0_2_2_2_2_1_1
              long      $0_0_3_3_2_1_3_1
              long      $0_0_3_3_3_1_1_1
              long      $0_0_3_3_1_1_1_1
              long      $0_0_0_0_1_1_1_0
              long      $0_0_0_2_2_2_0_0
              long      $0_0_2_2_2_2_0_0

              ' Mario bottom right sprite
mario_br      long      $2_1_2_2_2_0_0_0        ' Sprite 3
              long      $1_1_2_2_2_2_0_0
              long      $1_3_1_2_3_3_0_0
              long      $1_1_1_3_3_3_0_0
              long      $1_1_1_1_3_3_0_0
              long      $0_1_1_1_0_0_0_0
              long      $0_0_2_2_2_0_0_0
              long      $0_0_2_2_2_2_0_0