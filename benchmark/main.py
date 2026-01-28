import random as rand
from pathlib import Path
import argparse


def generateMatrix(n, num):
    with open(f"../matrices/matrix_{num}_{n}x{n}.csv", "w") as f:
        f.write(f"{n}\n")
        for i in range(0,n):
            for j in range(0,n):
                f.write(f"{rand.uniform(0,10)},")
            f.write("\n")

def setupArguments():
    parser = argparse.ArgumentParser(description='Benchmarking tool for bachelor')
    _ = parser.add_argument("--genMatricies", "-gm", dest="amountOfMatricies", type=int, default=-1, help="Amount of matricies to create, every new one doubles in size")

    return parser.parse_args()

def main():

    args = setupArguments()
    
    if args.amountOfMatricies != -1:
        print("generating matrices")
        rand.seed("Driven Humans Offering Service")
        i = 20
        for _ in range(0, args.amountOfMatricies):
            generateMatrix(i, 0)
            generateMatrix(i, 1)
            i*=2
    print("done!")


if __name__ == "__main__":
    main()

            
