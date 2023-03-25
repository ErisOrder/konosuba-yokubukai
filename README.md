# Project
This repo oriented to assist translation of `Konosuba: Kono Yokubukai Game ni Shinpan o!`

If you want help or can provide english translation, please write an issue

## Building
Run `python make.py make -xd`

`-x` option to build scripts

`-d` option to build other data

Built mod will be in `build`

## Data manipulation

### PSB
PSB Key: 

    38757621acf82

PSB compiling:

    python make.py man psb -c <name>_info.psb.m.json <out_folder>

PSB decompiling:

    python make.py man psb -d <name>_info.psb.m <out_folder>

### Script
Script compiling:

    python make.py man script -c <src.nut> <out.nut.m>

Script decompiling:

    python make.py man script -d <bin.nut.m> <src.nut>

Script compare:

    python make.py script --cmp <module> <function>
    python make.py script --bincmp <module> <function>

compare requires installed git

### Font 
Individual font files extracted from `font_body.bin`

Font pack:

    python make.py man font -c <name>_info.psb.m.json <out_folder>

Font extract:

    python make.py man font -d <name>.psb.m <out_folder>

## Tools
- [scn-tool](https://github.com/storycraft/scn-tool)
- [FreeMote Toolkit](https://github.com/UlyssesWu/FreeMote)
- [NutCracker](https://github.com/nikvoid/NutCracker/tree/squirrel-32bit)
- [Squirrel 2.24 32bit compiler](http://squirrel-lang.org/)