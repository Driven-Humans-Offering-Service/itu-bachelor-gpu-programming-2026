import os.path
import re
from os import listdir
from os.path import isfile, join

import matplotlib.pyplot as plt
from utils import rootFolder

from data import BenchmarkData


def visualise(args):
    name = args[0]
    filenames = args[1:]
    data = {}
    kernel_data = {}
    files = get_files(filenames)
    for file in files:
        cuda_file = "cuda" in file
        filename_with_path = os.path.join(rootFolder, f"data/time/{file}")
        underscore_split = filename_with_path.split("_")
        hardware = " ".join(underscore_split[-1].split("ø"))
        iteration = int(underscore_split[-2])
        language = underscore_split[-3]
        size = int(underscore_split[-4])
        algorithm = get_algorithm(underscore_split[-6])
        bm = BenchmarkData(hardware, str(iteration), algorithm, language)
        bm_obj = data.get(bm.description(), bm)
        bm_obj_kernel = ""
        bm_kernel = ""
        if cuda_file:
            bm_kernel = BenchmarkData(hardware, str(iteration), algorithm, language, True)
            bm_obj_kernel = kernel_data.get(bm_kernel.description(), bm_kernel)
        with open(filename_with_path, "r") as f:
            time = float(f.readline().split(" ")[0])/10**9
            bm_obj.appendx(size)
            bm_obj.appendy(time)
            if cuda_file:
                time = float(f.readline().split(" ")[0])/10**9
                bm_obj_kernel.appendx(size)
                bm_obj_kernel.appendy(time)  

        data[bm.description()] = bm_obj
        if cuda_file:
            kernel_data[bm_kernel.description()] = bm_obj_kernel
    plot(data.values(), name)
    if len(kernel_data.values()) >= 1:
        plot(kernel_data.values(), name, True)

def get_files(regexes):
    dataPath = os.path.join(rootFolder, "data/time")
    data_files = [f for f in listdir(dataPath) if isfile(join(dataPath, f))]
    files = []
    for file in data_files:
        for regex in regexes:
            match = re.search(regex, file)
            if match:
                files.append(file)
    return files

    


def get_algorithm(str):
    if "addition" in str.lower():
        return "addition"
    elif "multiplication" in str.lower():
        return "multiplication"
    elif "inversion" in str.lower():
        return "inversion"
    else:
        raise Exception("Unknown algorithm")


def plot(values, name, cuda_time = False):
    fig, ax = plt.subplots(figsize=(12, 7))
    sorted_values = sorted(values, key=lambda x: (x.language, x.iteration))
    cmap = plt.get_cmap("tab20")
    colours = [cmap(i) for i in range(len(sorted_values))]
    for i, bm in enumerate(sorted_values):
        sorted_pairs = sorted(zip(bm.x, bm.y), key=lambda x: x[0])
        bm.x, bm.y = zip(*sorted_pairs)
        ax.plot(bm.x, bm.y, color=colours[i], label=bm.description(),
                linewidth=2, alpha=0.85)
    ax.set_yscale("log")
    ax.set_xscale("log")
    ax.set_xlabel("Matrix side length", fontsize=13)
    ax.set_ylabel("Time [s]", fontsize=13)
    if cuda_time:
        name = name + " - Kernel Time"
    ax.set_title(name, fontsize=16, fontweight="bold", pad=15)
    ax.legend(
        loc="upper left",
        borderaxespad=0,
        fontsize=9,
        framealpha=0.9,
        facecolor="#ededed",
    )
    ax.grid(True, which="both", linestyle="--", linewidth=0.5, alpha=0.7)
    ax.tick_params(axis="both", labelsize=11)
    plt.tight_layout()
    filename = "fig.png" if not cuda_time else "fig-kernel.png"
    plt.savefig(filename, dpi=150, bbox_inches="tight")
    plt.show()
