
import subprocess


def compile_java(file):
    subprocess.Popen(["javac", "-d", "./build/java", file, "./src/java/Matrix.java" ])
def compile_c(path):
    raise NotImplementedError
def compile_cuda(path):
    raise NotImplementedError
