import os
rootFolder = ""

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

setup()
