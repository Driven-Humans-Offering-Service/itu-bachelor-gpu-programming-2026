import logging
import os
import subprocess

from utils import filter_files, filter_files_by_iteration, filter_files_by_operation, get_files_containg, get_files_for_lang_arg, rootFolder


def get_files_with_extention(files, extention):
    return list(filter(lambda x :  x.endswith(extention), files))


def compile_lang_arg(files, arg2):
    global rootFolder
    srcPath = os.path.join(rootFolder, "./src")
    c_util_files = get_files_containg(os.path.join(srcPath, "utilities"), ".c")
    processes = []
    match arg2:
        case "java":
            java_files =  get_files_with_extention(files, ".java")
            for java_file in java_files:
                logging.debug(f"Compiling {java_file}")
                p = compile_java(java_file) 
                processes.append(p)
                logging.debug(f"Done compiling {java_file}")
        case "c":
            c_files = get_files_with_extention(files, ".c")
            for file in c_files:
                logging.debug(f"Compiling {file}")
                p = compile_c(file, c_util_files)
                processes.append(p)
                logging.debug(f"Done compiling {file}")
        case "cuda":
            cuda_files = get_files_with_extention(files, ".cu")
            for file in cuda_files:
                logging.debug(f"Compiling {file}")
                p = compile_cuda(file, c_util_files)
                processes.append(p)
                logging.debug(f"Done compiling {file}")
        case "all":
            compile_lang_arg(files, "java")
            compile_lang_arg(files, "c")
            compile_lang_arg(files, "cuda")
        case _:
            print(f"No such lang {arg2}")
    for p in processes:
        p.wait()

def compile_type(srcFolder, type, args):
    files = get_files_containg(srcFolder, type)
    compile_lang_arg(files, args) 


def compile_java(file):
    build_path = os.path.join(rootFolder, "./build/java")
    matrix_path = os.path.join(rootFolder, "./src/java/Matrix.java")
    return subprocess.Popen(["javac", "-d", build_path, file, matrix_path ])

def get_cuda_and_c_command(compiler, file, util_files, lang):
    outputName = os.path.splitext(os.path.basename(file))[0] + ".out"
    outputPath = os.path.join(rootFolder, f"./build/{lang}/{outputName}")
    cmd = [compiler, "-O3"]
    cmd += util_files
    cmd.append(file)
    cmd.append("-lm")
    cmd.append("-o")
    cmd.append(outputPath)
    return cmd

def compile_c(file, util_files):
    cmd = get_cuda_and_c_command("gcc", file, util_files, "c")
    return subprocess.Popen(cmd)

def compile_cuda(file, util_files):
    cmd = get_cuda_and_c_command("nvcc", file, util_files, "cuda") 
    cmd.append("-DCUDA_CODE");
    cmd.append("-Xcompiler=-O3")
    return subprocess.Popen(cmd)

def compile_files(files):
    global rootFolder
    srcPath = os.path.join(rootFolder, "./src")
    c_util_files = get_files_containg(os.path.join(srcPath, "utilities"), ".c")
    processes = []
    for file in files:
        file_lang = file.split("/")[-2]
        if "java" == file_lang:
            processes.append(compile_java(file))
        elif "cuda" == file_lang:
            processes.append(compile_cuda(file, c_util_files))
        elif "c" == file_lang:
            processes.append(compile_c(file, c_util_files))
    for p in processes:
        p.wait()


def compile(args):
    files = filter_files("src", args)
    compile_files(files)
    
