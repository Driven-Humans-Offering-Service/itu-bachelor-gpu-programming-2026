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


def get_files_for_lang_arg(lang):
    global rootFolder
    build_folder = ""
    files = []
    if lang == "all":
        for tp in ["java","cuda","c"]:
            build_folder = os.path.join(rootFolder, f"./build/{tp}")
            files = get_files_containg(build_folder, type)
    else:
        build_folder = os.path.join(rootFolder, f"./build/{lang}")
        files = get_files_containg(build_folder, type)
    return files

setup()
