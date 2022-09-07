
PSB_KEY = "38757621acf82"

NUTCRACKER_PATH = "tools/nutcracker.exe"
SQ_PATH = "tools/sq.exe"
PSB_DECOMPILE_PATH = "tools/FreeMoteToolkit/PsbDecompile.exe"
PSB_BUILD_PATH = "tools/FreeMoteToolkit/PsBuild.exe"

BUILD_ROOT = "build"
TMP_ROOT = f"{BUILD_ROOT}/tmp"
FILES_ROOT = f"{BUILD_ROOT}/windata"

CACHE_FILE = f"{BUILD_ROOT}/cache.json"

SCRIPTS_ORIG = "script/original"
SCRIPTS_SRC = "script/src"
SCRIPT_JSON = "script/psb-json"

SCRIPTS_WHITELIST = [

]

SCRIPTS_TEST_WHITELIST = [
    "main"
]

SCRIPTS_WORKING = [
    "action",
    "application",
    "baselayer",
    "basepicture",
    "basiclayer",
    "basicpicture",
    "basicrender",
    "basictext",
    "confirmdialog",
    "debug",            # ?
    "dmmauth",
    "doublepicture",
    "envenv",
    # "envplayer",
    "envsystem",
    # "exception",
    "fontinfo",
    "gestureinfo",
    "include",
    "init",
    # "main",
    "minigame",
    "motionpanel",
    "override",
    "savesystem",       # ?
    "selectdialog",
    "sound",
    "spec",
    "spec_ps3",
    "spec_ps4",
    "spec_psp",
    "spec_vita",
    "spec_win",
    "spec_x360",
    "startup",
    "system",
    "text",
    "title",
    "tus",
    # "util",
    "world",
]