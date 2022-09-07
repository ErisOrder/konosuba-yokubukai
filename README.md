# Building
Run `python make.py make -xd`

`-x` option to build scripts

`-d` option to build other data

Built mod will be in `build`

# Data manipulation

## PSB
PSB Key: 

    38757621acf82

PSB compiling:

    python make.py man psb -c <name>_info.psb.m.json <out_folder>

PSB decompiling:

    python make.py man psb -d <name>_info.psb.m <out_folder>

## Script
Script compiling:

    python make.py man script -c <src.nut> <out.nut.m>

Script decompiling:

    python make.py man script -d <bin.nut.m> <src.nut>

Script compare:

    python make.py script --cmp <module> <function>
    python make.py script --bincmp <module> <function>

compare requires installed git