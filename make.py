import os
import shutil
import argparse


from common.process import run_single
from common.cache import HashStorage

# argparse
parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers()

parser_make = subparsers.add_parser("make", help="build mod")
parser_make.add_argument("-c", action="store_true", help="force clean")
parser_make.add_argument("-x", action="store_true", help="make scripts")
parser_make.add_argument("-d", action="store_true", help="make data")
parser_make.add_argument("-t", action="store_true", help="do not delete tmp folder")

parser_script = subparsers.add_parser("script", help="compile/decompile scripts")
parser_script.add_argument("input_dir", type=str, help="input source or binary folder")
parser_script.add_argument("output_dir", type=str, help="output source or binary folder")
parser_script.add_argument("-c", action="store_true", help="compile scripts")
parser_script.add_argument("-d", action="store_true", help="decompile scripts")
parser_script.add_argument("-r", type=str, help="folder for redecompiled scripts (-cd for roundtrip)")


# config
PSB_KEY = "38757621acf82"

NUTCRACKER_PATH = "tools/nutcracker.exe"
SQ_PATH = "tools/sq.exe"
PSB_DECOMPILE_PATH = "tools/FreeMoteToolkit/PsbDecompile.exe"
PSB_COMPILE_PATH = "tools/FreeMoteToolkit/PsbCompile.exe"

BUILD_ROOT = "build"
TMP_ROOT = f"{BUILD_ROOT}/tmp"
FILES_ROOT = f"{BUILD_ROOT}/windata"

CACHE_FILE = f"{BUILD_ROOT}/cache.json"

SCRIPTS_SRC = f"script/src"

hash_store: HashStorage


def ensure_path(path):
    os.makedirs(path, exist_ok=True)


def clean():
    print("cleaning...")
    if os.path.exists(BUILD_ROOT):
        shutil.rmtree(BUILD_ROOT)


def check_dir(directory):
    changed = False
    for file in os.listdir(directory):
        filepath = f"{directory}/{file}"
        if not os.path.isdir(filepath) and hash_store.check_changed(filepath):
            hash_store.update_file(filepath)
            changed = True
    return changed


def compile_script(src, dst):
    print(f"compiling {src}")
    result = run_single(SQ_PATH, "-c", "-o", dst, src)
    if result:
        print(f"{src} compiled succesfully")
    else:
        print(f"failed to compile {src}")


def decompile_script(src, dst):
    print(f"decompiling {src}")
    result = run_single(NUTCRACKER_PATH, "-o", dst, src)
    if result:
        print(f"{src} decompiled succesfully")
    else:
        print(f"failed to decompile {src}")


def compile_scripts():
    print("compiling scripts...")
    tmp_path = f"{TMP_ROOT}/scripts"
    ensure_path(tmp_path)
    for script_file in os.listdir(SCRIPTS_SRC):
        src_path = f"{SCRIPTS_SRC}/{script_file}"
        out_path = f"{tmp_path}/{script_file}.m"
        if hash_store.check_changed(src_path) or not os.path.exists(out_path):
            compile_script(src_path, out_path)
            hash_store.update_file(src_path)
    hash_store.save()


def make_main(args):
    global hash_store

    ensure_path(BUILD_ROOT)
    hash_store = HashStorage(CACHE_FILE)

    if args.c:
        clean()

    if args.x:
        compile_scripts()

    if not args.t:
        shutil.rmtree(TMP_ROOT)

    hash_store.save()


def script_main(args):

    if args.c and args.d and not args.r:
        print("please specify folder for redecompiled scripts with -r <dir>")
        return

    if args.c:
        ensure_path(args.output_dir)
        for scr_file in os.listdir(args.input_dir):
            src_path = f"{args.input_dir}/{scr_file}"
            dst_path = f"{args.output_dir}/{scr_file}.m"
            compile_script(src_path, dst_path)
        args.input_dir = args.output_dir

    if args.r:
        args.output_dir = args.r

    if args.d:
        ensure_path(args.output_dir)
        for scr_file in os.listdir(args.input_dir):
            src_path = f"{args.input_dir}/{scr_file}"
            dst_path = f"{args.output_dir}/{scr_file[:-2]}"  # remove .m
            decompile_script(src_path, dst_path)


if __name__ == "__main__":
    parser_make.set_defaults(func=make_main)
    parser_script.set_defaults(func=script_main)
    argss = parser.parse_args()
    if "func" not in argss:
        parser.print_help()
    else:
        argss.func(argss)