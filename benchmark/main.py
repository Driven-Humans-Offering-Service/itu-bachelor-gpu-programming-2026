import random as rand
from pathlib import Path


def generateMatrix(n):
    with open(f"../matrices/matrix_{n}x{n}.csv", "w") as f:
        f.write(f"{n}\n")
        for i in range(0,n):
            for j in range(0,n):
                f.write(f"{rand.uniform(0,10)},")
            f.write("\n")

def main():
    if not Path("../matrices/matrix_20x20.csv").exists():
        print("generating matrices")
        rand.seed("Driven Humans Offering Service")
        i = 20
        for _ in range(0,9):
            generateMatrix(i)
            i*=2
    print("done!")


if __name__ == "__main__":
    main()

            
