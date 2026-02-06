import os
rootFolder = ""

def setup():
    global rootFolder
    ownFolder = os.path.dirname(os.path.abspath(__file__)) 
    rootFolder = os.path.abspath(os.path.join(ownFolder, "../"))

def get_filename(file: str):
     return os.path.splitext(os.path.basename(file))[0]

setup()
