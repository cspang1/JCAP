CON
    ' Game settings
    NUM_TILE_COLOR_PALETTES = 2     ' Number of tile color palettes
    NUM_SPRITE_COLOR_PALETTES = 2   ' Number of sprite color palettes
    NUM_SPRITES = 64                ' Number of sprites in sprite attribute table
    VIS_TILE_MAP_WIDTH = 40         ' Number of visible horizontal tiles in tile map
    VIS_TILE_MAP_HEIGHT = 30        ' Number of visible vertical tiles in tile map
    MEM_TILE_MAP_WIDTH = 56         ' Number of visible horizontal tiles in tile map
    MEM_TILE_MAP_HEIGHT = 30        ' Number of visible vertical tiles in tile map
    NUM_TILE_PALETTES = 5           ' Number of tile palettes
    NUM_SPRITE_PALETTES = 3         ' Number of sprite palettes

    ' Display system attributes
    GFX_BUFFER_SIZE = 1+((MEM_TILE_MAP_WIDTH*MEM_TILE_MAP_HEIGHT)*2+(NUM_TILE_COLOR_PALETTES+NUM_SPRITE_COLOR_PALETTES)*16+NUM_SPRITES*4)/4   ' Number of LONGs in graphics resources buffer
    VID_BUFFER_SIZE = 80                                                                                                                    ' Number of scanline segments in video buffer

PUB null