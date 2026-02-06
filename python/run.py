import os
import subprocess
from utils import get_filename


def is_java_program(file: str):
    return file.endswith(".class")
    
def run_file(file, args):
    cmd = []
    if is_java_program(file):
        cmd.append("java")
        cmd.append("-cp")
        cmd.append("-cp")
        cmd.append("build/java")
        file_name = get_filename(file) 
        cmd.append(file_name)
    else:
        cmd.append(file)
    for arg in args:
        cmd.append(arg)
    return subprocess.run(cmd, capture_output=True).stdout
        
