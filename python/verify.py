import logging
import os
import math as m

from run import run_file
from utils import filter_files, get_iteration_from_file, get_operation_from_file, rootFolder


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


def verify(expected, actual):
    exp = read_matrix(expected)
    act = read_matrix(actual)

    size = len(exp)
    if size != len(act):
        print("matrix sizes not equal")
        return False

    for i in range(0, size):
        for j in range(0, size):
            #difference = abs(ma1[i][j] - ma2[i][j])/(abs(ma1[i][j]) + abs(ma2[i][j]))
            if act[i][j] == 0:
                if exp[i][j] != 0:
                    logging.debug(f"{exp[i][j]} != {act[i][j]}")
                    return False
                continue
            if not m.isclose(exp[i][j], act[i][j], rel_tol=1e-6, abs_tol=1e-9):
                logging.debug(f"{exp[i][j]} != {act[i][j]}")
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



def run_files(files):
    matrices_path = os.path.abspath(os.path.join(rootFolder, "./data/input"))
    for matrix in os.listdir(matrices_path):
        _, num, size = matrix.split("_");
        size = int(size)
        num = int(num)
        if size >= 640:
            continue
        input0 = rootFolder + f"/data/input/matrix_0_{size}"
        input1 = rootFolder + f"/data/input/matrix_1_{size}"
        for file in files:
            lang = file.split("/")[-2]
            operation = get_operation_from_file(file)
            iteration = get_iteration_from_file(file)
            outputFile = os.path.join(rootFolder, f"data/output/res_{operation}_{size}_{lang}_{iteration}")
            run_file(file, ["--outputresult", outputFile, input0, input1])

def get_res_files():
    res_path = os.path.abspath(os.path.join(rootFolder, "./data/output"))
    return list(filter(lambda file: file.startswith("res_"), os.listdir(res_path)))

def get_size_from_file(file):
    return file.split("_")[-3]

def verify1(args):
    files = filter_files("build", args)
    res_path = os.path.abspath(os.path.join(rootFolder, "./data/output"))
    run_files(files)
    result_files = get_res_files()
    java_files = filter(lambda file: "java" in file, result_files)
    not_java_files = filter(lambda file: not "java" in file, result_files)
    for file in not_java_files:
        size = get_size_from_file(file)
        op = get_operation_from_file(file)
        java_file = list(filter(lambda file: op in file and size in file, java_files))[0]
        verify(os.path.join(res_path, java_file), os.path.join(res_path, file))


