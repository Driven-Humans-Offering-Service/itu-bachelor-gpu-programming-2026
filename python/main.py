import argparse
import logging
import os

from compile import compile_java
import matrix_generation as mg
import verify as v

logging.basicConfig(
    level=logging.INFO,  # minimum level to display
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

rootFolder = ""

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
        default="Driven Humans Offering Service",
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
        "--verify",
        "-v",
        dest="verify",
        help="Whether or not to verify the resulting matrices against the java implementation",
        action="store_true",
    )

    _ = parser.add_argument(
        "--benchmark",
        "-b",
        dest="benchmark",
        help="Whether or not to benchmark the different matrix operations",
        action="store_true",
    )

    _ = parser.add_argument(
        "--compile",
        "-c",
        dest="compile",
        help="Whether or not to compile all the files",
        nargs="*",
        default=[],
    )

    return parser.parse_args()

def get_files_containg(root, matchCase):
    lst = []                
    for dirpath, dirname, filenames in os.walk(root):
        for filename in filenames:
            if matchCase in filename.lower():
                lst.append(os.path.join(dirpath, filename))
    return lst

def get_files_with_extention(files, extention):
    return filter(lambda x : extention in x, files)


def compile_lang_arg(files, arg2):
    srcPath = os.path.join(rootFolder, "./src")
    match arg2:
        case "java":
            raise NotImplementedError
        case "j":
            java_files =  get_files_with_extention(files, ".java")
            for java_file in java_files:
                compile_java(java_file) 
        case _:
            print(f"No such lang {arg2}")


def main():
    args = setupArguments()
    global rootFolder
    ownFolder = os.path.dirname(os.path.abspath(__file__)) 
    rootFolder = os.path.abspath(os.path.join(ownFolder, "../"))

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    logging.debug("entering main")

    if args.amount_of_matrices != -1:
        logging.debug("generating matrices")
        mg.generate_matrices(args.amount_of_matrices, args.seed)
        logging.debug("done generation matrices")

    if args.compile != None:
        if len(args.compile) >= 3:
            print("Please only provide at most two arguments to compile")
            exit(1)
        if args.compile == []:
            args.compile = ["all"]

        srcFolder = os.path.join(rootFolder, "./src")
        match args.compile[0]:
            case "all":
                raise NotImplementedError
            case "add":
                files = get_files_containg(srcFolder, "addition")
                compile_lang_arg(files, args.compile[1]) 
            case "multiply":
                raise NotImplementedError
            case "inverse":
                raise NotImplementedError
            case _:
                print("Please supply one of all, add, multiply, or inverse")
                exit(1)

    if args.verify and args.benchmark:
        logging.debug("verify and benchmark implementations")
        logging.debug("running benchmark")
        # run benchmrk with time and resultoutput
        logging.debug("done running benchmark")
        logging.debug("verifying implementations")
        v.verify_implementations()
        logging.debug("done verifying implementations")

    elif args.verify:
        logging.debug("running the implementations")
        # run with resultoutput
        logging.debug("finished running implementations")
        logging.debug("verifying implementations")
        v.verify_implementations()
        logging.debug("done verifying implementations")

    elif args.benchmark:
        logging.debug("running benchmark")
        # run benchmrk with time
        logging.debug("done running benchmark")

    logging.debug("exiting main")


if __name__ == "__main__":
    main()
