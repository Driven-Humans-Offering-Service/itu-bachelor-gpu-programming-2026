import logging
import os
import shutil

from utils import rootFolder

def remove_recursivly(path):
    logging.debug(f"Trying to delete{path}")
    if os.path.exists(path):
        shutil.rmtree(path)
        logging.debug(f"Deleted {path}")
        return
    logging.debug(f"Failed to delete {path}")


def clean():
    folders = ["build", "data"]

    for folder in folders:
        path = os.path.join(rootFolder, folder)
        remove_recursivly(path)


    return
