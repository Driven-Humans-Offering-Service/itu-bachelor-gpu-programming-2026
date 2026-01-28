import argparse
import random as rand


def generateMatrix(n, num):
    with open(f"../matrices/matrix_{num}_{n}x{n}.csv", "w") as f:
        f.write(f"{n}\n")
        for i in range(0, n):
            for j in range(0, n):
                f.write(f"{rand.uniform(0, 10)},")
            f.write("\n")


def setupArguments():
    parser = argparse.ArgumentParser(description="Benchmarking tool for bachelor")
    _ = parser.add_argument(
        "--genMatricies",
        "-gm",
        dest="amountOfMatricies",
        type=int,
        default=-1,
        help="Amount of matricies to create, every new one doubles in size",
    )
    _ = parser.add_argument(
            "--seed",
            "-s",
            dest="seed",
            type=str,
            default="Driven Humans Offering Service",
            help="Seed to be used to generate random numbers for the matricies",
    )

    return parser.parse_args()


def main():
    args = setupArguments()

    if args.amountOfMatricies != -1:
        print("generating matrices")
        rand.seed(args.seed)
        i = 20
        for _ in range(0, args.amountOfMatricies):
            generateMatrix(i, 0)
            generateMatrix(i, 1)
            i *= 2
    print("done!")


if __name__ == "__main__":
    main()
