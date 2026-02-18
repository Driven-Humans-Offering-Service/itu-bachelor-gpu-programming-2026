
import os
from matrix_generation import generate_matrices
from utils import default_rand_seed, rootFolder
from pathlib import Path

def create_dir_and_subdirs(dirs):
    parent_dir = os.path.join(rootFolder, dirs[0])
    Path(parent_dir).mkdir(parents=True, exist_ok=True)
    for dir in dirs[1:]:
        path = os.path.join(parent_dir, dir)
        Path(path).mkdir(parents=True, exist_ok=True)

def setup():
    build_dirs = ["build", "c","cuda","java"]
    data_dirs = ["data", "input","output","time"]
    
    create_dir_and_subdirs(build_dirs)
    create_dir_and_subdirs(data_dirs)

    matrix_path = os.path.join(rootFolder, "./data/input/matricies/matrix_0_20")
    if not Path.exists(Path(matrix_path)):
        should_gen_matricies = input("Input data not generated should it be generated?[Y/n]")
        if should_gen_matricies.lower() != "n":
            generate_matrices(9, default_rand_seed)


    
    


