import subprocess
import multiprocessing


def run_single(program_path, *args):
    proc_args = (program_path,) + args
    out = subprocess.call(proc_args)
    return out == 0


def run_pool(func, args, processors):
    pool = multiprocessing.Pool(processors)
    pool.starmap(func, args)
