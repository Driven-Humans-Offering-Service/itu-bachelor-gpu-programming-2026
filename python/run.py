import os
import subprocess
from utils import get_filename, get_files_containg, rootFolder


def is_java_program(file: str):
    return file.endswith(".class")
    
def run_file(file, args):
    cmd = []
    if is_java_program(file):
        cmd.append("java")
        cmd.append("-cp")
        cmd.append("build/java")
        file_name = get_filename(file) 
        cmd.append(file_name)
    else:
        cmd.append(file)
    for arg in args:
        cmd.append(arg)
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.stderr != "":
        print(f"Tried to run the following command:\n{cmd}\n\nGot error:\n{res.stderr}")
        exit(1)
    return res.stdout


def run_lang_arg(files, test_file):
    global rootFolder
    input_folder = os.path.join(rootFolder, "./data/input")
    input_files = get_files_containg(input_folder, test_file) 
    for file in files:
        args = []
        args.append("--time")
        args.append(input_files[0])
        args.append(input_files[1])
        res = run_file(file, args)
        print(f"Ran {file} with result:\n{res}")


def run_type(type, lang, size):
    global rootFolder
    build_folder = ""
    if lang == "all":
        for tp in ["java","cuda","c"]:
            build_folder = os.path.join(rootFolder, f"./build/{tp}")
            files = get_files_containg(build_folder, type)
            run_lang_arg(files, size) 
    else:
        build_folder = os.path.join(rootFolder, f"./build/{lang}")
        files = get_files_containg(build_folder, type)
        run_lang_arg(files, size) 

def run(args):

    match args[0]:
        case "all":
            run_type("addition", args[1], args[2])
            run_type("multiplication", args[1], args[2])
            run_type("inversion", args[1], args[2])
        case "add":
            run_type("addition", args[1], args[2])
        case "multiply":
            run_type("multiplication", args[1], args[2])
        case "inverse":
            run_type("inversion", args[1], args[2])
        case _:
            print("Please supply one of all, add, multiply, or inverse")
            exit(1)
        
