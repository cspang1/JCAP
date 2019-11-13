{{
        File:     cpu.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code defining a JCAP CPU
}}

CON
    ' Clock settings
    _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
    _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

    ' Pin settings
    VS_PIN = 14
    TX_PIN = 15

    ' Test settings
    NUM_SEA_LINES = 56
OBJ
    system        : "system"      ' Import system settings
    gfx_tx        : "tx"          ' Import graphics transmission system
    input         : "input"       ' Import input system

VAR
    ' Game resource pointers
    long    input_state_base_       ' Register in Main RAM containing state of inputs
    long    gfx_resources_base_     ' Register in Main RAM containing base of graphics resources
    long    gfx_buffer_size_        ' Container for graphics resources buffer size

    ' TEST RESOURCE POINTERS
    long    satts[system#SAT_SIZE]
    long    plxvars[NUM_SEA_LINES]

PUB main | time,trans,cont,temp,x,y,z,q
    ' Set unused pin states
    dira[3..7]~~
    dira[8..13]~~
    dira[16..27]~~
    outa[3..7]~
    outa[8..13]~
    outa[16..27]~

    ' Initialize variables
    input_state_base_ := @input_states                    ' Point input state base to base of input states
    gfx_resources_base_ := @tile_color_palettes           ' Set graphics resources base to start of tile color palettes
    gfx_buffer_size_ := system#GFX_BUFFER_SIZE                   ' Set graphics resources buffer size

    ' Start subsystems
    trans := constant(NEGX|TX_PIN)                              ' link setup
    gfx_tx.start(@trans, VS_PIN, TX_PIN)                    ' Start graphics resource transfer system
    repeat while trans
    input.start(@input_state_base_)                       ' Start input system

    '     sprite         x position       y position    color v h size
    '|<------------->|<--------------->|<------------->|<--->|-|-|<->|
    ' 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    '|----spr<<24----|------x<<15------|-----y<<7------|c<<4-|8|4|x-y|

    temp := 0
    x := 16 ' starting horizontal pos
    y := 128 'starting vertical pos
    z := 1 'sprites per line
    q := 1 'n lines
    repeat q
        repeat z
            satts[temp] := (0 << 24) | (x << 15) | (y << 7) | 2 | 1
            x += 16
            temp += 1
        y += 16
        x := 16
    repeat system#SAT_SIZE-z*q
        satts[temp] := (0 << 15) | (0 << 7)
        temp += 1
    longmove(@sprite_atts, @satts, system#SAT_SIZE)

    ' Setup parallaxing
    longfill(@plx_pos, 0, system#NUM_PARALLAX_REGS)
    long[@plx_pos][0] := 0
    x := 79
    repeat temp from 1 to NUM_SEA_LINES
        if (temp-1)//2 == 0
            plxvars[temp-1] := temp-1+148
        else
            plxvars[temp-1] := temp-1
        long[@plx_pos][temp] := x
        x += 1 
    long[@plx_pos][NUM_SEA_LINES+1] := x

    time := cnt

    ' Main game loop
    repeat
        waitcnt(Time += clkfreq/60) ' Strictly for sensible sprite speed
        trans := constant(system#GFX_BUFFER_SIZE << 16) | @plx_pos{0}            ' register send request
        if time//4 == 0
          long[@t_palette1][2] <-= 8
        repeat temp from 1 to NUM_SEA_LINES
            plxvars[temp-1] := plxvars[temp-1] + 2
            x := sin(plxvars[temp-1],(temp-1)//4)
            if x < 0
                x += 447
            long[@plx_pos][temp] := (long[@plx_pos][temp] & $FFFFF) | (x << 20)
        x := word[@control_state][0] & $5000
        y := word[@control_state][0] & $A000
        if x == $4000 or x == $1000
            left_right(x)
        if y == $8000 or y == $2000
            up_down(y)
        cont := tilt_state
        if (tilt_state & 1) == 1
            longfill(@sprite_atts, 0, system#SAT_SIZE)

pri left_right(x_but) | x,dir,mir,temp,xsp
    x := long[@sprite_atts][0]
    temp := x & %00000000000000000111111111111011
    dir := 0 << 24
    x >>= 15
    x &= %111111111
    xsp := long[@plx_pos][0] >> 20
    if x_but == $1000
        mir := 0
        x := (x + 1) & %111111111
        if xsp == 447
            long[@plx_pos][0] &= $FFFFF
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFFFF) | ((xsp + 1) << 20)
    if x_but == $4000
        mir := 1 << 2
        x := (x - 1) & %111111111
        if xsp == 0
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFFFF) | (447 << 20)
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFFFF) | ((xsp - 1) << 20)
    if temp & 2 == 2
        if x == 336
            x := 1
        elseif x == 0
            x := 335
    else
        if x == 336
            x := 9
        elseif x == 8
            x := 335
    x <<= 15
    temp |= (x | mir | dir)
    longmove(@sprite_atts, @temp, 1)

pri up_down(y_but) | y,dir,mir,temp,ysp
    y := long[@sprite_atts][0]
    temp := y & %00000000111111111000000001110111
    dir := 0 << 24
    y >>= 7
    y &= %11111111
    ysp := (long[@plx_pos][0] & $FFF00) >> 8
    if y_but == $2000
        mir := 1 << 3
        y := (y + 1) & %11111111
        if ysp == 271
            long[@plx_pos][0] &= $FFF000FF
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFF000FF) | ((ysp + 1) << 8)
    if y_but == $8000
        mir := 0
        y := (y - 1) & %11111111
        if ysp == 0
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFF000FF) | (271 << 8)
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFF000FF) | ((ysp - 1) << 8)
    if temp & 1 == 1
        if y == 255
            y := 1
        elseif y == 0
            y := 254
    else
        if y == 255
            y := 9
        elseif y == 8
            y := 254
    y <<= 7
    temp |= (y | mir | dir)
    longmove(@sprite_atts, @temp, 1)

pri sin(degree, range) : s | c,z,angle
  angle := (degree*91)~>2  ' *22.75
  c := angle & $800
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s
  return (s*range)~>16     ' return sin = -range..+range

DAT
input_states
              ' Input states
control_state   word    0   ' Control states
tilt_state      word    0   ' Tilt shift state

plx_pos         long    0[system#NUM_PARALLAX_REGS]   ' Parallax array (x[31:20]|y[19:8]|i[7:0] where 'i' is scanline index)

tile_color_palettes
            ' Tile color palettes
t_palette0  byte    %00000000,$FD {SUN EDGE},$FD {in sun},$3B {SKY BLUE}                    ' Tile color palette 0
            byte    $64 {brown gnd},$E0 {1st purple},$E1,$E2
            byte    $E3,$F3,$FA,$FE
            byte    $FF,$DF,$7F,$1F
t_palette1  byte    $FF,$3B,$37,$33                    ' Tile color palette 1
            byte    $2F,$9F,%00000000,%00000000
            byte    $2F,$33,$37,$3B
            byte    %00000000,%00000000,%00000000,%00000000

sprite_color_palettes
            ' Sprite color palettes
s_palette0  byte    %00000000,%11100000,%01001000,%11111010                    ' Tile color palette 0
            byte    %11110011,%00111111,%11001111,%11000011
            byte    %11010011,%00110111,%01001111,%01111011
            byte    %11010111,%01110111,%01011111,%00000011
s_palette1  byte    %00000011,%00110011,%11111111,%11000011                    ' Tile color palette 1
            byte    %00000011,%00110011,%11111111,%11000011
            byte    %00000011,%00110011,%11111111,%11000011
            byte    %00000011,%00110011,%11111111,%11000011

            ' Sprite attribute table
sprite_atts long    0[system#SAT_SIZE]

tile_maps
            ' Main tile map
            '       |--0---|--1---|--2---|--3---|--4---|--5---|--6---|--7---|--8---|--9---|--10--|--11--|--12--|--13--|--14--|--15--|--16--|--17--|--18--|--19--|--20--|--21--|--22--|--23--|--24--|--25--|--26--|--27--|--28--|--29--|--30--|--31--|--32--|--33--|--34--|--35--|--36--|--37--|--38--|--39--| |--40--|--41--|--42--|--43--|--44--|--45--|--46--|--47--|--48--|--49--|--50--|--51--|--52--|--53--|--54--|--55--|
tile_map0   word{0} $00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,{}$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C    ' 0
            word{1} $00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,{}$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C,$00_1C    ' 1
            word{2} $00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,{}$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22,$00_22    ' 2
            word{3} $00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,{}$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D,$00_1D    ' 3
            word{4} $00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_0D,$00_0E,$00_1A,$00_19,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,{}$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23,$00_23    ' 4
            word{5} $00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_0A,$00_0B,$00_0C,$00_02,$00_02,$00_18,$00_17,$00_16,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,{}$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E,$00_1E    ' 5
            word{6} $00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_08,$00_09,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_15,$00_14,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,{}$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24,$00_24    ' 6
            word{7} $00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_06,$00_07,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_13,$00_12,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,{}$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F,$00_1F    ' 7
            word{8} $00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_05,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_11,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,{}$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20,$00_20    ' 8
            word{9} $00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_03,$00_04,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_10,$00_0F,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,{}$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21,$00_21    ' 9
            word{10}$01_25,$01_26,$01_26,$01_25,$01_27,$01_25,$01_25,$01_27,$01_25,$01_26,$01_26,$01_25,$01_27,{}$01_2D,$01_2E,$01_30,$01_29,$01_29,$01_29,$01_29,$01_29,$01_29,$01_29,$01_29,$01_34,$01_32,$01_31{},$01_25,$01_27,$01_25,$01_25,$01_27,$01_25,$01_26,$01_26,$01_25,$01_27,$01_25,$01_25,$01_27,{}$01_25,$01_26,$01_26,$01_25,$01_27,$01_25,$01_25,$01_27,$01_25,$01_26,$01_26,$01_25,$01_27,$01_25,$01_25,$01_27    ' 10
            word{11}$01_36,$01_37,$01_37,$01_35,$01_36,$01_28,$01_36,$01_36,$01_28,$01_28,$01_35,$01_36,$01_35,{}$01_36,$01_28,$01_2F,$01_30,$01_29,$01_29,$01_29,$01_29,$01_29,$01_29,$01_34,$01_33,$01_37,$01_37{},$01_37,$01_35,$01_28,$01_37,$01_36,$01_28,$01_28,$01_37,$01_37,$01_28,$01_35,$01_36,$01_36,{}$01_28,$01_35,$01_36,$01_35,$01_36,$01_37,$01_36,$01_37,$01_36,$01_35,$01_35,$01_36,$01_28,$01_36,$01_35,$01_35    ' 11
            word{12}$01_37,$01_35,$01_28,$01_36,$01_28,$01_36,$01_35,$01_37,$01_36,$01_36,$01_35,$01_37,$01_35,{}$01_35,$01_28,$01_37,$01_2F,$01_30,$01_29,$01_29,$01_29,$01_29,$01_34,$01_33,$01_35,$01_28,$01_28{},$01_36,$01_35,$01_37,$01_37,$01_35,$01_36,$01_28,$01_35,$01_35,$01_35,$01_36,$01_36,$01_36,{}$01_28,$01_37,$01_37,$01_35,$01_37,$01_36,$01_35,$01_28,$01_37,$01_35,$01_36,$01_36,$01_37,$01_35,$01_36,$01_28    ' 12
            word{13}$01_36,$01_36,$01_28,$01_28,$01_37,$01_37,$01_36,$01_36,$01_36,$01_35,$01_36,$01_28,$01_35,{}$01_37,$01_36,$01_28,$01_28,$01_2F,$01_30,$01_29,$01_29,$01_34,$01_33,$01_36,$01_28,$01_28,$01_37{},$01_37,$01_28,$01_35,$01_28,$01_37,$01_28,$01_36,$01_37,$01_28,$01_35,$01_35,$01_36,$01_35,{}$01_28,$01_37,$01_28,$01_36,$01_28,$01_28,$01_28,$01_35,$01_28,$01_28,$01_37,$01_28,$01_36,$01_28,$01_28,$01_37    ' 13
            word{14}$01_28,$01_28,$01_37,$01_36,$01_35,$01_35,$01_36,$01_28,$01_37,$01_36,$01_37,$01_35,$01_37,{}$01_36,$01_36,$01_28,$01_35,$01_35,$01_2F,$01_30,$01_34,$01_33,$01_36,$01_37,$01_36,$01_37,$01_36{},$01_37,$01_35,$01_28,$01_35,$01_36,$01_35,$01_36,$01_28,$01_28,$01_35,$01_36,$01_35,$01_35,{}$01_36,$01_36,$01_35,$01_28,$01_35,$01_28,$01_28,$01_36,$01_35,$01_36,$01_37,$01_36,$01_36,$01_37,$01_37,$01_28    ' 14
            word{15}$01_37,$01_35,$01_28,$01_36,$01_36,$01_37,$01_37,$01_28,$01_35,$01_35,$01_28,$01_36,$01_28,{}$01_37,$01_28,$01_28,$01_37,$01_35,$01_28,$01_2F,$01_33,$01_35,$01_28,$01_37,$01_37,$01_35,$01_36{},$01_36,$01_28,$01_37,$01_28,$01_37,$01_37,$01_28,$01_36,$01_37,$01_37,$01_36,$01_37,$01_28,{}$01_35,$01_36,$01_37,$01_28,$01_37,$01_36,$01_28,$01_28,$01_36,$01_35,$01_37,$01_28,$01_35,$01_28,$01_36,$01_28    ' 15
            word{16}$01_35,$01_28,$01_28,$01_37,$01_36,$01_37,$01_35,$01_35,$01_36,$01_35,$01_35,$01_35,$01_35,{}$01_37,$01_35,$01_35,$01_36,$01_28,$01_37,$01_36,$01_37,$01_35,$01_37,$01_35,$01_28,$01_28,$01_28{},$01_37,$01_36,$01_37,$01_37,$01_35,$01_36,$01_36,$01_35,$01_36,$01_36,$01_35,$01_37,$01_28,{}$01_36,$01_35,$01_28,$01_37,$01_35,$01_37,$01_36,$01_28,$01_37,$01_28,$01_36,$01_36,$01_35,$01_35,$01_35,$01_36    ' 16
            word{17}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_3B,$01_3A,$01_3B,$01_3A,$01_3B,$01_3A,$01_3B,$01_3A,$01_3B,$01_3A,$01_3B,$01_3A,$01_3B,$01_3A,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 17
            word{18}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 18
            word{19}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 19
            word{20}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 20
            word{21}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 21
            word{22}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 22
            word{23}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 23
            word{24}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 24
            word{25}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 25
            word{26}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 26
            word{27}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 27
            word{28}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 28
            word{29}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$01_39,$01_38,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 29

            word{30}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 30
            word{31}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 31
            word{32}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 32
            word{33}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,{}$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B,$00_1B    ' 33
            '       |--0---|--1---|--2---|--3---|--4---|--5---|--6---|--7---|--8---|--9---|--10--|--11--|--12--|--13--|--14--|--15--|--16--|--17--|--18--|--19--|--20--|--21--|--22--|--23--|--24--|--25--|--26--|--27--|--28--|--29--|--30--|--31--|--32--|--33--|--34--|--35--|--36--|--37--|--38--|--39--| |--40--|--41--|--42--|--43--|--44--|--45--|--46--|--47--|--48--|--49--|--50--|--51--|--52--|--53--|--54--|--55--|