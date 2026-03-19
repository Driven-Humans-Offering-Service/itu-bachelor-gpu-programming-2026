import os.path

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

from data import BenchmarkData
from utils import rootFolder


def visualise(args):
    filenames = args
    global rootFolder
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
        bm = BenchmarkData(hardware, iteration, algorithm, language)
        bm_obj = data.get(bm.description(), bm)
        with open(filename_with_path, "r") as f:
            time = float(f.readline().split(" ")[0])
            bm_obj.appendx(size)
            bm_obj.appendy(time)

    sub_plots(data)

def get_algorithm(str):
    if str.lower().contains("addition"):
        return "addition"
    elif str.lower().contains("multiplication"):
        return "multiplication"
    elif str.lower().contains("inversion"):
        return "inversion"
    else:
        raise Exception("Unknown algorithm")

def scatter_plot(xvalues, yvalues):
    plt.scatter(yvalues, xvalues)
    plt.show()

colours = ["red", "green", "blue", "black", "cyan", "magenta", "yellow", "pink"]

def sub_plots(data):

    plt.subplot(1, 1, 1)
    for hardware, (xvalues, yvalues), i in data:
        plt.plot(xvalues, yvalues, color=colours[i], label=hardware)
    plt.show()
