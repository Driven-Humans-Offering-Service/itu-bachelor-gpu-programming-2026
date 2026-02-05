import random as rand

from utils import rootFolder

def generate_matrix(n, num):
    with open(f"{rootFolder}/data/input/matrix_{num}_{n}", "w") as f:
        f.write(f"{n}\n")
        for _ in range(0, n):
            for _ in range(0, n):
                f.write(f"{rand.uniform(0, 10)} ")
            f.write("\n")


def generate_matrices(amount, seed):
    rand.seed(seed)
    i = 20
    for _ in range(0, amount):
        generate_matrix(i, 0)
        generate_matrix(i, 1)
        i *= 2
