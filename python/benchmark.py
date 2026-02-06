import logging
import os
import statistics as s

from run import run_file
from utils import rootFolder


def analyse_data(times):
    for run in times:
        logging.debug(f"Creating time data file for: {run[0] + run[1]}")
        with open(f"{rootFolder}/data/time/bench_{run[0]}_{run[1]}", "w") as f:
            timedata = map(int, run[2].split(" ").strip())
            avg = s.mean(timedata)
            f.write(f"{avg} " + run[2])


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
                    "addition" in os.path.splitext(os.path.basename(f))[0].lower()
                ),
                get_files("all"),
            )
        case "multiplication":
            files = filter(
                lambda f: (
                    "multiplication" in os.path.splitext(os.path.basename(f))[0].lower()
                ),
                get_files("all"),
            )
        case "inversion":
            files = filter(
                lambda f: (
                    "inversion" in os.path.splitext(os.path.basename(f))[0].lower()
                ),
                get_files("all"),
            )
        case _:
            print("not a recognised benchmark argument")
            exit(1)
    return list(files)


def run_files(files):
    times = []
    for file in files:
        logging.debug(f"Running for file: {file}")
        times_for_file = []
        lsinput = os.listdir(os.path.join(rootFolder, "./data/input"))
        different = filter(lambda s: "_0_" in s, lsinput)
        sizes = map(lambda d: d.split("_")[-1], different)
        for size in sizes:
            logging.debug(f"Running for size: {size}")
            for i in range(0, 50):
                # logging.debug(f"Running {i}. iteration")
                input0 = rootFolder + f"/data/input/matrix_0_{size}"
                input1 = rootFolder + f"/data/input/matrix_1_{size}"
                times_for_file.append(run_file(file, ["--time", input0, input1]))
            times.append(
                (os.path.splitext(os.path.basename(file))[0], size, times_for_file)
            )
    return times


def benchmark(what):
    logging.debug("Running files")
    times = run_files(get_files(what))
    logging.debug("Done running files")
    logging.debug("Starting data analysis")
    analyse_data(times)
    logging.debug("Done with data analysis")
