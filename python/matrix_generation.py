import logging
import random as rand
import struct
from io import BytesIO

from utils import rootFolder


def generate_matrix(n, num):
    logging.debug(f"Generating matrix: {0}_{n}")
    buffer = BytesIO()
    buffer.write(struct.pack("<i", n))
    for _ in range(0, n):
        for _ in range(0, n):
            buffer.write(struct.pack("<f", rand.uniform(0, 10)))

    with open(f"{rootFolder}/data/input/matrix_{num}_{n}", "wb") as f:
        f.write(buffer.getvalue())


def generate_matrices(amount, seed):
    rand.seed(seed)
    i = 20
    for _ in range(0, amount):
        generate_matrix(i, 0)
        generate_matrix(i, 1)
        i *= 2
