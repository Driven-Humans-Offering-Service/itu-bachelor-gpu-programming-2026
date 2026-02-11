import logging
import os
import statistics as s

from run import run_file
from utils import rootFolder


def analyse_data(type, size, times, lang):
    logging.debug(f"Creating time data file for: {type}_{size}")
    with open(f"{rootFolder}/data/time/bench_{type}_{size}_{lang}", "w") as f:
        strippeddata = list(map(lambda x: x.strip(), times))
        timedata = list(map(int, strippeddata))
        avg = s.mean(timedata)
        f.write(f"{avg} " + " ".join(strippeddata))


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
    for file in files:
        logging.debug(f"Running for file: {file}")
        lsinput = os.listdir(os.path.join(rootFolder, "./data/input"))
        different = filter(lambda s: "_0_" in s, lsinput)
        sizes = map(lambda d: d.split("_")[-1], different)
        sorted_sizes = sorted(sizes, key=lambda sz: int(sz))
        for size in sorted_sizes:
            times = []
            logging.debug(f"Running for size: {size}")
            for i in range(0, 50):
                # logging.debug(f"Running {i}. iteration")
                input0 = rootFolder + f"/data/input/matrix_0_{size}"
                input1 = rootFolder + f"/data/input/matrix_1_{size}"
                times.append(run_file(file, ["--time", input0, input1]))

            type = os.path.splitext(os.path.basename(file))[0]
            lang = file.split("/")[-2]
            logging.debug(f"Starting data analysis on: {type}_{size}")
            analyse_data(type, size, times, lang)
            logging.debug(f"Finished data analysis on: {type}_{size}")


def benchmark(what):
    logging.debug("Running files")
    run_files(get_files(what))
    logging.debug("Done running files")
