import os.path

import matplotlib.pyplot as plt
from utils import rootFolder

from data import BenchmarkData


def visualise(args):
    filenames = args
    data = {}
    for file in filenames:
        print(file)
        filename_with_path = os.path.join(rootFolder, f"data/time/{file}")
        underscore_split = filename_with_path.split("_")
        hardware = " ".join(underscore_split[-1].split("ø"))
        iteration = int(underscore_split[-2])
        language = underscore_split[-3]
        size = int(underscore_split[-4])
        algorithm = get_algorithm(underscore_split[-6])
        bm = BenchmarkData(hardware, str(iteration), algorithm, language)
        bm_obj = data.get(bm.description(), bm)
        with open(filename_with_path, "r") as f:
            time = float(f.readline().split(" ")[0])/10**9
            bm_obj.appendx(size)
            bm_obj.appendy(time)
        data[bm.description()] = bm_obj
    plot(data)

def get_algorithm(str):
    if "addition" in str.lower():
        return "addition"
    elif "multiplication" in str.lower():
        return "multiplication"
    elif "inversion" in str.lower():
        return "inversion"
    else:
        raise Exception("Unknown algorithm")

colours = ["red", "green", "blue", "black", "cyan", "magenta", "yellow", "pink"]

def plot(data):
    i = 0
    print(data)
    for bm in data.values():
        plt.plot(bm.x, bm.y, color=colours[i % len(colours)], label=bm.description())
        i += 1
    plt.xlabel("size")
    plt.ylabel("time [s]")
    plt.legend(loc="upper left")
    plt.title("Benchmark")
    plt.show()
