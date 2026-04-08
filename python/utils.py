from collections import defaultdict
import os
rootFolder = ""
default_rand_seed = "Driven Humans Offering Service"

def setup():
    global rootFolder
    ownFolder = os.path.dirname(os.path.abspath(__file__)) 
    rootFolder = os.path.abspath(os.path.join(ownFolder, "../"))

def get_filename(file: str):
     return os.path.splitext(os.path.basename(file))[0]

def get_files_containg(root, matchCase):
    lst = []                
    for dirpath, dirname, filenames in os.walk(root):
        for filename in filenames:
            if matchCase in filename.lower():
                lst.append(os.path.join(dirpath, filename))
    return lst

def get_testfile_of_size(root, size: int):
    lst = []                
    for dirpath, dirname, filenames in os.walk(root):
        for filename in filenames:
            found_size = int(filename.split("_")[2])
            if found_size == size:
                lst.append(os.path.join(dirpath, filename))
    return lst


def get_files_for_lang_arg(folder, lang):
    global rootFolder
    files = []
    if lang == "all":
        for tp in ["java","cuda","c"]:
            lang_folder = os.path.join(rootFolder, f"./{folder}/{tp}")
            files += get_files_containg(lang_folder, "")
    else:
        lang_folder = os.path.join(rootFolder, f"./{folder}/{lang}")
        files = get_files_containg(lang_folder, "")
    return files

def filter_files_by_operation(files: list[str], op: str):
    op = op.lower()
    if op == "all":
        addition_files = filter_files_by_operation(files, "addition")
        multiplication_files = filter_files_by_operation(files, "multiplication")
        inversion_files = filter_files_by_operation(files, "inversion")
        return addition_files + multiplication_files + inversion_files
    return list(filter(lambda file: op in file.lower(), files))

def filter_files_by_iteration(files: list[str], iterations: int):
    m = defaultdict(int)
    ending = {}
    new_files: list[str] = []
    for file in files:
        split = file.split("_")
        file_name = "_".join(split[:-1])
        current_it = int(split[-1].split(".")[0])
        current_max = m[file_name]
        if current_it > current_max:
            m[file_name] = current_it

        ending[file_name] = "." + split[-1].split(".")[1]
    for file in m:
        for i in range(0, iterations):
            num = m[file] - i
            if num < 0:
                break
            new_files.append(file + "_" + str(num) + ending[file])
    return new_files

def filter_files(folder, args):
    iteration = 1 if len(args) < 3 else args[2]
    files = get_files_for_lang_arg(folder, args[0]) 
    files = filter_files_by_operation(files, args[1])
    files = filter_files_by_iteration(files, int(iteration))
    return files

setup()
