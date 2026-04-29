import logging
import os
import statistics as s
import platform
import subprocess

from run import run_file
from utils import filter_files, filter_files_by_iteration, filter_files_by_operation, get_files_for_lang_arg, rootFolder

def write_times_to_file(f, times):
    strippeddata = list(map(lambda x: x.strip(), times))
    timedata = list(map(int, strippeddata))
    avg = s.mean(timedata)
    f.write(f"{avg} " + " ".join(strippeddata))

def get_cpu():
    result = subprocess.run(
        'lscpu | grep "Model name"',
        shell=True,
        capture_output=True,
        text=True
    )

    cpu_name = result.stdout.strip().split(":")[1].strip()
    return cpu_name

def get_gpu():
    result = subprocess.run(
        [
            "nvidia-smi",
            "--query-gpu=name,memory.total,memory.used,utilization.gpu",
            "--format=csv,noheader,nounits",
        ],
        capture_output=True,
        text=True
    )

    gpus = []

    for line in result.stdout.strip().split("\n"):
        name, mem_total, mem_used, util = line.split(", ")
        gpus.append(name)

    return gpus


def analyse_data(type, size, times, lang, cuda_kernel_times, iteration):
    logging.debug(f"Creating time data file for: {type}_{size}_{iteration}")
    hardware = ""
    if len(cuda_kernel_times) == 0:
        hardware = get_cpu()
    else:
        hardware = get_gpu()[0]
    
    print(hardware)
    hardware = hardware.replace(" ", "ø")
    with open(f"{rootFolder}/data/time/bench_{type}_{size}_{lang}_{iteration}_{hardware}", "w") as f:
        write_times_to_file(f, times)
        if len(cuda_kernel_times) != 0:
            f.write("\n")
            write_times_to_file(f, cuda_kernel_times)



def get_files(type, iterations=1):
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
        iteration = os.path.basename(file).split(".")[0].split("_")[-1]
        sizes = map(lambda d: d.split("_")[-1], different)
        sorted_sizes = sorted(sizes, key=lambda sz: int(sz))
        for size in sorted_sizes:
            times = []
            cuda_kernel_times = []
            logging.debug(f"Running for size: {size}")
            type = os.path.splitext(os.path.basename(file))[0]
            lang = file.split("/")[-2]
            for i in range(0, 10):
                # logging.debug(f"Running {i}. iteration")
                input0 = rootFolder + f"/data/input/matrix_0_{size}"
                input1 = rootFolder + f"/data/input/matrix_1_{size}"
                res = run_file(file, ["--time", input0, input1])
                if lang == "cuda":
                    res_split = res.split("\n")
                    times.append(res_split[0])
                    cuda_kernel_times.append(res_split[1])
                    continue
                times.append(res)

            logging.debug(f"Starting data analysis on: {type}_{size}")
            analyse_data(type, size, times, lang, cuda_kernel_times, iteration)
            logging.debug(f"Finished data analysis on: {type}_{size}")


def benchmark(args):
    logging.debug("Running files")
    #run_files(get_files(args[0]))
    files = filter_files("build", args)
    run_files(files)
    
    logging.debug("Done running files")
