import os.path
import re
from os import listdir
from os.path import isfile, join

import matplotlib.pyplot as plt
from utils import rootFolder

from data import BenchmarkData


def visualise(args):
    filenames = args
    data = {}
    files = get_files(filenames)
    for file in files:
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

colours = ["red", "green", "blue", "black", "cyan", "magenta", "yellow", "pink"]

def plot(data):
    i = 0
    print(data)
    for bm in data.values():
        sorted_pairs = sorted(zip(bm.x, bm.y), key=lambda x: x[0])
        bm.x, bm.y = zip(*sorted_pairs)
        print(bm.x)
        print(bm.y)
        plt.plot(bm.x, bm.y, color=colours[i % len(colours)], label=bm.description())
        i += 1
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel("size")
    plt.ylabel("time [s]")
    plt.legend(loc="upper left")
    plt.title("Benchmark")
    plt.savefig("fig.png")
    plt.show()
