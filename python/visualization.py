import os.path

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from utils import rootFolder


def visualise(args):
    filenames = args
    global rootFolder
    data = {}
    for file in filenames:
        print(file)
        filename_with_path = os.path.join(rootFolder, f"data/time/{file}")
        hardware = " ".join(filename_with_path.split("_")[-1].split("ø"))
        y = "bloat"
        print(filename_with_path)
        x = filename_with_path.split("_")[-4]
        with open(filename_with_path, "r") as f:
            y = f.readline().split(" ")[0]

        data.append(
            (
                float(x),
                float(y),
                hardware,
            )
        )

    sub_plots(data)


def scatter_plot(xvalues, yvalues):
    plt.scatter(yvalues, xvalues)
    plt.show()


colours = ["red", "green", "blue", "cyan", "magenta", "yellow", "black", "pink"]


def sub_plots(data):
    plt.subplot(2, 2, 1)
    plt.plot(data[0][0], data[0][1], color=colours[0])
    plt.show()
