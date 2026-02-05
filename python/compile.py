import logging
import os
import subprocess

from utils import rootFolder

def get_files_containg(root, matchCase):
    lst = []                
    for dirpath, dirname, filenames in os.walk(root):
        for filename in filenames:
            if matchCase in filename.lower():
                lst.append(os.path.join(dirpath, filename))
    return lst

def get_files_with_extention(files, extention):
    return list(filter(lambda x :  x.endswith(extention), files))


def compile_lang_arg(files, arg2):
    global rootFolder
    srcPath = os.path.join(rootFolder, "./src")
    c_util_files = get_files_containg(os.path.join(srcPath, "utilities"), ".c")
    match arg2:
        case "java":
            java_files =  get_files_with_extention(files, ".java")
            for java_file in java_files:
                logging.debug(f"Compiling {java_file}")
                compile_java(java_file) 
                logging.debug(f"Done compiling {java_file}")
        case "c":
            c_files = get_files_with_extention(files, ".c")
            for file in c_files:
                logging.debug(f"Compiling {file}")
                compile_c(file, c_util_files)
                logging.debug(f"Done compiling {file}")
        case "cuda":
            cuda_files = get_files_with_extention(files, ".cu")
            for file in cuda_files:
                logging.debug(f"Compiling {file}")
                compile_cuda(file, c_util_files)
                logging.debug(f"Done compiling {file}")
        case "all":
            compile_lang_arg(files, "java")
            compile_lang_arg(files, "c")
            compile_lang_arg(files, "cuda")
        case _:
            print(f"No such lang {arg2}")

def compile_type(srcFolder, type, args):
    files = get_files_containg(srcFolder, type)
    compile_lang_arg(files, args) 


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


def compile(args):
    if len(args) >= 3:
        print("Please only provide at most two arguments to compile")
        exit(1)
    if args == []:
        args = ["all"]

    srcFolder = os.path.join(rootFolder, "./src")
    
    if len(args) == 1:
        args.append("all")

    match args[0]:
        case "all":
            compile_type(srcFolder, "addition", args[1])
            compile_type(srcFolder, "multiplication", args[1])
            compile_type(srcFolder, "inversion", args[1])
        case "add":
            compile_type(srcFolder, "addition", args[1])
        case "multiply":
            compile_type(srcFolder, "multiplication", args[1])
        case "inverse":
            compile_type(srcFolder, "inversion", args[1])
        case _:
            print("Please supply one of all, add, multiply, or inverse")
            exit(1)
