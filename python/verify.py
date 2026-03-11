import logging
import os

from utils import rootFolder


def read_matrix(filename):
    matrix = []
    with open(filename, "r") as f:
        firstline = True
        for line in f.readlines():
            if firstline:
                firstline = False
                continue
            matrix.append(list(map(float, line.strip().split(" "))))
    return matrix


def verify(filename1, filename2):
    ma1 = read_matrix(filename1)
    ma2 = read_matrix(filename2)

    size = len(ma1)
    if size != len(ma2):
        print("matrix sizes not equal")
        return False

    for i in range(0, size):
        for j in range(0, size):
            difference = abs(ma1[i][j] - ma2[i][j])/(abs(ma1[i][j]) + abs(ma2[i][j]))
            if difference > 10 ** (-5):
                logging.debug(f"{ma1[i][j]} != {ma2[i][j]}")
                return False

    return True


def verify_implementations():
    matrices_path = os.path.abspath(os.path.join(rootFolder, "./data/output"))
    for file in os.listdir(matrices_path):
        if file.startswith("res") and (file.endswith("cuda") or file.endswith("c")):
            logging.debug(f"Verifying file {file}")
            parts = file.split("_")
            operation = parts[1]
            size = parts[2]
            if int(size) >= 640:
                logging.debug(f"Skipping file {file} since size is too big")
                continue
            file = os.path.join(matrices_path, file)
            javaPath = os.path.join(matrices_path, f"res_{operation}_{size}_java")
            res = verify(file, javaPath)
            logging.debug(f"Done verifying file {file} is correct {res}")
            if not res:
                return False
    return True
