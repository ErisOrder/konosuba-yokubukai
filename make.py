import os
import shutil
import argparse


from common.process import run_single
from common.cache import HashStorage
from config import *

# argparse
parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers()

parser_make = subparsers.add_parser("make", help="build mod")
parser_make.add_argument("-c", action="store_true", help="force clean")
parser_make.add_argument("-x", action="store_true", help="make scripts")
parser_make.add_argument("-T", action="store_true", help="make test whitelist scripts from source")
parser_make.add_argument("-A", action="store_true", help="make all working scripts from source")
parser_make.add_argument("-d", action="store_true", help="make data")
parser_make.add_argument("-t", action="store_true", help="do not delete tmp folder")

parser_script = subparsers.add_parser("script", help="disassemble and compare scripts")
parser_script.add_argument("module", type=str, help="script module in script/src")
parser_script.add_argument("function_name", type=str, help="function to disassemble ('main' for whole file)")
parser_script.add_argument("--cmp", action="store_true", help="compile and decompile and compare with src")
parser_script.add_argument("--bincmp", action="store_true", help="compile and compare with original binary")
parser_script.add_argument("-r", action="store_true", help="show redecompiled output")

parser_man = subparsers.add_parser("man", help="data manipulation")
man_subparsers = parser_man.add_subparsers()

parser_psb = man_subparsers.add_parser("psb", help="manipulate psb")
parser_psb.add_argument("input", type=str, help="input json or binary")
parser_psb.add_argument("output", type=str, help="output folder or binary")
parser_psb.add_argument("-c", action="store_true", help="compile (build)")
parser_psb.add_argument("-d", action="store_true", help="decompile (build)")

parser_man_script = man_subparsers.add_parser("script", help="manipulate scripts")
parser_man_script.add_argument("input", type=str, help="input source or binary file")
parser_man_script.add_argument("output", type=str, help="output source or binary file")
parser_man_script.add_argument("-c", action="store_true", help="compile script")
parser_man_script.add_argument("-d", action="store_true", help="decompile script")
parser_man_script.add_argument("-r", type=str, help="filename for redecompiled script (-cd for roundtrip)")


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
    result = run_single(SQ_PATH, "-c", "-d", "-o", dst, src)
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


def compile_scripts(whitelist: list[str]):
    print("compiling scripts...")
    tmp_path = f"{TMP_ROOT}/scripts"
    ensure_path(f"{tmp_path}/script")
    ensure_path(f"{tmp_path}/custom")
    changed = False
    for script_file in os.listdir(SCRIPTS_SRC):
        orig_path = f"{SCRIPTS_ORIG}/{script_file}.m"
        src_path = f"{SCRIPTS_SRC}/{script_file}"
        out_path = f"{tmp_path}/script/{script_file}.m"

        if script_file.split(".")[0] in whitelist:
            if hash_store.check_changed(src_path) or hash_store.check_changed(out_path):
                tmp_path_custom = f"{tmp_path}/custom/{script_file}"
                data = f'this.printf("custom {script_file} loaded\\n");\n' + open(src_path).read()
                with open(tmp_path_custom, 'w') as tmpfile:
                    tmpfile.write(data)
                compile_script(tmp_path_custom, out_path)
                hash_store.update_file(src_path)
                changed = True
        else:
            if hash_store.check_changed(orig_path) or hash_store.check_changed(out_path):
                print(f"copying {script_file}.m from original folder")
                shutil.copy(orig_path, out_path)
                hash_store.update_file(orig_path)
                changed = True
        hash_store.update_file(out_path)

    hash_store.save()

    if changed:
        ensure_path(FILES_ROOT)
        info_json = "script_info.psb.m.json"
        shutil.copy(f"{SCRIPT_JSON}/{info_json}", tmp_path)
        shutil.copy(f"{SCRIPT_JSON}/script_info.psb.m.resx.json", tmp_path)
        build_psb(f"{tmp_path}/{info_json}", f"{FILES_ROOT}")


def decompile_fun(binary_path, func, out=None):
    if out:
        run_single(NUTCRACKER_PATH, "-d", func, "-o", out, binary_path)
    else:
        run_single(NUTCRACKER_PATH, "-d", func, binary_path)


def recompile_script(module, binary):
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
        return compiled_path, original_path

    redecompiled_path = f"{tmp_path}/{module}.nut"
    decompile_script(compiled_path, redecompiled_path)
    return src_path, redecompiled_path


def git_diff(file1, file2, word_diff=False):
    return run_single("git", "diff", "--no-index", f"--word-diff={'color' if word_diff else 'none'}", "--", file1, file2)


def make_main(args):
    global hash_store

    if args.c:
        clean()

    ensure_path(BUILD_ROOT)
    hash_store = HashStorage(CACHE_FILE)

    if args.x:
        whitelist = SCRIPTS_WHITELIST
        if args.T:
            whitelist = SCRIPTS_TEST_WHITELIST
        if args.A:
            whitelist = SCRIPTS_WORKING
        compile_scripts(whitelist)

    hash_store.save()

    if not args.t and os.path.exists(TMP_ROOT):
        shutil.rmtree(TMP_ROOT)


def script_main(args):

    if args.bincmp:
        tmp_file = f"{TMP_ROOT}/cmp/{args.module}.{args.function_name}.nut"
        tmp_file_r = f"{TMP_ROOT}/cmp/{args.module}.{args.function_name}.rec.nut"
        recompiled_path, orig_path = recompile_script(args.module, True)
        decompile_fun(orig_path, args.function_name, tmp_file)
        decompile_fun(recompiled_path, args.function_name, tmp_file_r)
        git_diff(tmp_file, tmp_file_r, True)
        return

    if args.cmp:
        src_path, redecompiled_path = recompile_script(args.module, False)
        git_diff(src_path, redecompiled_path)
        return

    if args.r:
        path, _ = recompile_script(args.module, True)
    else:
        path = f"{SCRIPTS_ORIG}/{args.module}.nut.m"
    decompile_fun(path, args.function_name)
    return


def man_script_main(args):

    if args.c and args.d and not args.r:
        print("please specify name for redecompiled script with -r <file>")
        return

    if args.c:
        root_dir = os.path.split(args.output)[0]
        ensure_path(root_dir)
        compile_script(args.input, args.output)
        args.input = args.output

    if args.r:
        args.output = args.r

    if args.d:
        root_dir = os.path.split(args.output)[0]
        ensure_path(root_dir)
        decompile_script(args.input, args.output)


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