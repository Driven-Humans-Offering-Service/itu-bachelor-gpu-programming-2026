import argparse
import logging
import os
from pathlib import Path

import visualization as vi
import compile as c
import matrix_generation as mg
import verify as ve
import run as r
import benchmark as b
import clean as cl
import setup as s

from utils import default_rand_seed, rootFolder

logging.basicConfig(
    level=logging.INFO,  # minimum level to display
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


def setupArguments():
    parser = argparse.ArgumentParser(description="Benchmarking tool for bachelor")
    _ = parser.add_argument(
        "--genmatrices",
        "-gm",
        dest="amount_of_matrices",
        type=int,
        default=-1,
        help="Amount of matricies to create, every new one doubles in size",
    )
    _ = parser.add_argument(
        "--seed",
        "-s",
        dest="seed",
        type=str,
        default=default_rand_seed,
        help="Seed to be used to generate random numbers for the matricies",
    )

    _ = parser.add_argument(
        "--debug",
        "-d",
        dest="debug",
        help="Whether or not to print logging statements to stdout",
        action="store_true",
    )

    _ = parser.add_argument(
        "--visualize",
        "-vi",
        dest="visualize",
        help="Whether or not to visualize the resulting matrices",
        nargs="*",
    )

    _ = parser.add_argument(
        "--verify",
        "-ve",
        dest="verify",
        help="Whether or not to verify the resulting matrices against the java implementation",
        action="store_true",
    )

    _ = parser.add_argument(
        "--benchmark",
        "-b",
        dest="benchmark",
        help="Whether or not to benchmark the different matrix operations",
        nargs="*",
    )

    _ = parser.add_argument(
        "--compile",
        "-c",
        dest="compile",
        help="Whether or not to compile all the files",
        nargs="*",
    )

    _ = parser.add_argument(
        "--run",
        "-r",
        dest="run",
        help="Whether or not to run all the files",
        nargs="*",
    )

    _ = parser.add_argument(
            "--clean",
            "-cl",
            dest="clean",
            help="Whether to remove all generated files and directories",
            action="store_true"
            )

    _ = parser.add_argument(
            "--setup",
            "-st",
            dest="setup",
            help="Whether to setup folder structure",
            action="store_true"
            )

    return parser.parse_args()


def main():
    args = setupArguments()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)


    logging.debug("entering main")

    if args.setup:
        logging.debug("Setting up directories")
        s.setup()
        logging.debug("Finished setting up directories")

    if args.amount_of_matrices != -1:
        logging.debug("generating matrices")
        mg.generate_matrices(args.amount_of_matrices, args.seed)
        logging.debug("done generation matrices")

    data_output_path = os.path.join(rootFolder, "./data/output")

    if not Path.exists(Path(data_output_path)):
        should_setup = input("It does not seem like the project it set up with input files, do you wish to setup folder structure?[Y/n]")
        if should_setup != "n":
            logging.debug("Setting up folder structure")
            s.setup()
            logging.debug("Finished up folder structure")

    if args.clean:
        logging.debug("Cleaning up")
        cl.clean()
        logging.debug("Finished cleaning directories")



    if args.compile != None:
       logging.debug("Trying to compile")
       c.compile(args.compile) 
       logging.debug("Done compiling")

    if args.run != None:
       logging.debug("Trying to run")
       r.run(args.run) 
       logging.debug("Done running")

    if args.verify and args.benchmark:
        logging.debug("verify and benchmark implementations")
        logging.debug("running benchmark")
        # run benchmrk with time and resultoutput
        logging.debug("done running benchmark")
        logging.debug("verifying implementations")
        ve.verify_implementations()
        logging.debug("done verifying implementations")

    elif args.verify:
        logging.debug("running the implementations")
        # run with resultoutput

        langs = ["java", "cuda", "c"]
        types = ["addition", "multiplication", "inversion"]
        matrices_path = os.path.abspath(os.path.join(rootFolder, "./data/input"))
        for file in os.listdir(matrices_path):
            if not file.startswith("matrix"):
                continue
            file_split = file.split("_") 
            if int(file_split[1]) == 1:
                continue
            size = int(file_split[2])
            if size >= 640:
                continue
            for lang in langs:
                for type in types:
                    args = ["outputresult", f"./data/output/res_{type}_{size}_{lang}"]
                    r.run_type(type, lang, size, args)

        logging.debug("finished running implementations")
        logging.debug("verifying implementations")
        ve.verify_implementations()
        logging.debug("done verifying implementations")

    elif args.visualize:
        logging.debug("running visualization")
        vi.visualise(args.visualize)
        logging.debug("done running visualization")

    elif args.benchmark:
        logging.debug("running benchmark")
        b.benchmark(args.benchmark)
        logging.debug("done running benchmark")

    logging.debug("exiting main")


if __name__ == "__main__":
    main()
