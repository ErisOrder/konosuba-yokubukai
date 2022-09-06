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

parser_script = subparsers.add_parser("script", help="compare scripts")
parser_script.add_argument("--cmp", type=str, help="module: compile and decompile and compare with src")
parser_script.add_argument("--bincmp", type=str, help="module: compile and compare with original binary")

parser_man = subparsers.add_parser("man", help="data manipulation")
man_subparsers = parser_man.add_subparsers()

parser_psb = man_subparsers.add_parser("psb", help="manipulate psb")
parser_psb.add_argument("input", type=str, help="input json or binary")
parser_psb.add_argument("output", type=str, help="output folder or binary")
parser_psb.add_argument("-c", action="store_true", help="compile (build)")
parser_psb.add_argument("-d", action="store_true", help="decompile (build)")

parser_man_script = man_subparsers.add_parser("script", help="manipulate scripts")
parser_man_script.add_argument("input_dir", type=str, help="input source or binary folder")
parser_man_script.add_argument("output_dir", type=str, help="output source or binary folder")
parser_man_script.add_argument("-c", action="store_true", help="compile scripts")
parser_man_script.add_argument("-d", action="store_true", help="decompile scripts")
parser_man_script.add_argument("-r", type=str, help="folder for redecompiled scripts (-cd for roundtrip)")

# config
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


def build_psb(src, dst):
    print(f"building {src}")
    result = run_single(PSB_BUILD_PATH, "info-psb", "-k", PSB_KEY, "-p", "win", src)
    if result:
        psb_name = os.path.split(src)[1].split("_")[0]
        files_to_move = [
            f"{psb_name}_info.psb.m",
            f"{psb_name}_body.bin"
        ]
        for file in files_to_move:
            shutil.move(file, f"{dst}/{file}")
        print(f"{src} built succesfully")
    else:
        print(f"failed to build {src}")


def decompile_psb(src, dst):
    print(f"decompiling {src}")
    result = run_single(PSB_DECOMPILE_PATH, "info-psb", "-k", PSB_KEY, src)
    if result:
        root_dir = os.path.split(src)[0]
        psb_name = os.path.split(src)[1].split("_")[0]
        files_to_move = [
            psb_name,
            f"{psb_name}_info.psb.m.json",
            f"{psb_name}_info.psb.m.resx.json"
        ]
        for file in files_to_move:
            shutil.move(f"{root_dir}/{file}", f"{dst}/{file}")
        print(f"{src} decompiled succesfully")
    else:
        print(f"failed to decompile {src}")


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
    ensure_path(f"{tmp_path}/script")
    changed = False
    for script_file in os.listdir(SCRIPTS_SRC):
        src_path = f"{SCRIPTS_SRC}/{script_file}"
        out_path = f"{tmp_path}/script/{script_file}.m"
        if hash_store.check_changed(src_path) or not os.path.exists(out_path):
            compile_script(src_path, out_path)
            hash_store.update_file(src_path)
            changed = True
    hash_store.save()
    if changed:
        ensure_path(FILES_ROOT)
        info_json = "script_info.psb.m.json"
        shutil.copy(f"{SCRIPT_JSON}/{info_json}", tmp_path)
        shutil.copy(f"{SCRIPT_JSON}/script_info.psb.m.resx.json", tmp_path)
        build_psb(f"{tmp_path}/{info_json}", f"{FILES_ROOT}")


def compare_scripts(module, binary):
    tmp_path = f"{TMP_ROOT}/cmp"
    ensure_path(tmp_path)
    original_path = f"{SCRIPTS_ORIG}/{module}.nut.m"
    src_path = f"{SCRIPTS_SRC}/{module}.nut"

    if not os.path.exists(original_path) or not os.path.exists(src_path):
        print("no such module")
        return

    compiled_path = f"{tmp_path}/{module}.nut.m"
    compile_script(src_path, compiled_path)

    if binary:
        run_single(NUTCRACKER_PATH, "-cmp", original_path, compiled_path)
        return

    redecompiled_path = f"{tmp_path}/{module}.nut"
    decompile_script(compiled_path, redecompiled_path)
    run_single("git", "diff", "--no-index", "--", src_path, redecompiled_path)


def make_main(args):
    global hash_store

    if args.c:
        clean()

    ensure_path(BUILD_ROOT)
    hash_store = HashStorage(CACHE_FILE)

    if args.x:
        compile_scripts()

    hash_store.save()

    if not args.t and os.path.exists(TMP_ROOT):
        shutil.rmtree(TMP_ROOT)


def script_main(args):

    if args.bincmp:
        compare_scripts(args.bincmp, True)
        return

    if args.cmp:
        compare_scripts(args.cmp, False)
        return


def man_script_main(args):

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


def psb_main(args):

    if args.c and args.d:
        print("choose one action")
        return

    ensure_path(args.output)

    if args.d:
        decompile_psb(args.input, args.output)
        return

    if args.c:
        build_psb(args.input, args.output)
        return


if __name__ == "__main__":
    parser_make.set_defaults(func=make_main)
    parser_script.set_defaults(func=script_main)
    parser_man_script.set_defaults(func=man_script_main)
    parser_psb.set_defaults(func=psb_main)
    argss = parser.parse_args()
    if "func" not in argss:
        parser.print_help()
    else:
        argss.func(argss)