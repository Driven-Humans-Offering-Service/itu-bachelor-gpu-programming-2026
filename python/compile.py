
import os
import subprocess


def compile_java(file):
    subprocess.Popen(["javac", "-d", "./build/java", file, "./src/java/Matrix.java" ])

def get_cuda_and_c_command(compiler, file, util_files, lang):
    outputName = os.path.splitext(os.path.basename(file))[0] + ".out"
    cmd = [compiler, "-O3"]
    cmd += util_files
    cmd.append(file)
    cmd.append("-lm")
    cmd.append("-o")
    cmd.append(f"./build/{lang}/{outputName}")
    return cmd

def compile_c(file, util_files):
    cmd = get_cuda_and_c_command("gcc", file, util_files, "c")
    subprocess.Popen(cmd)

def compile_cuda(file, util_files):
    cmd = get_cuda_and_c_command("nvcc", file, util_files, "cuda")
    subprocess.Popen(cmd)
