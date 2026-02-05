import os
import statistics as s

from main import rootFolder
from run import *


def analyse_data(times):
    avg = s.mean(times)
    print(avg)


def get_files(type):
    builddir = os.path.abspath(os.path.join(rootFolder, "./build"))
    files = []
    match type:
        case "all":
            files = get_files("java") + get_files("c") + get_files("cuda")
        case "java":
            javadir = os.path.abspath(os.path.join(builddir, "./java"))
            files = map(lambda name: os.path.join(javadir, name), os.listdir(javadir))
            files = filter(
                lambda f: "matrix" != os.path.splitext(os.path.basename(f))[0].lower(),
                files,
            )
        case "c":
            cdir = os.path.abspath(os.path.join(builddir, "./c"))
            files = map(lambda name: os.path.join(cdir, name), os.listdir(cdir))
        case "cuda":
            cudadir = os.path.abspath(os.path.join(builddir, "./cuda"))
            files = map(lambda name: os.path.join(cudadir, name), os.listdir(cudadir))
        case "addition":
            files = filter(
                lambda f: (
                    "addition" == os.path.splitext(os.path.basename(f))[0].lower()
                ),
                get_files("all"),
            )
        case "multiplication":
            files = filter(
                lambda f: (
                    "multiplication" == os.path.splitext(os.path.basename(f))[0].lower()
                ),
                get_files("all"),
            )
        case "inversion":
            files = filter(
                lambda f: (
                    "inversion" == os.path.splitext(os.path.basename(f))[0].lower()
                ),
                get_files("all"),
            )
        case _:
            print("not a recognised benchmark argument")
            exit(1)
    return files


def run_files(files):
    times = []
    for file in files:
        times_for_file = []
        for _ in range(0, 50):
            times_for_file.append(run_file(file, ""))
        times.append((os.path.basename(file), times_for_file))


def benchmark(what):
    times = run_files(get_files(what))
    analyse_data(times)
