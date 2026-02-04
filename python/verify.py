import os


def read_matrix(filename):
    matrix = []
    with open(filename, "r") as f:
        firstline = True
        for line in f.readlines():
            if firstline:
                firstline = False
                continue
            matrix.append(list(map(float, line.strip().split(" "))))
    return matrix


def verify(filename1, filename2):
    ma1 = read_matrix(filename1)
    ma2 = read_matrix(filename2)

    size = len(ma1)
    if size != len(ma2):
        print("matrix sizes not equal")
        return False

    for i in range(0, size):
        for j in range(0, size):
            if ma1[i][j] != ma2[i][j]:
                return False

    return True


def verify_implementations():
    verify_path = os.path.dirname(os.path.abspath(__file__))
    matrices_path = os.path.abspath(os.path.join(verify_path, "../matrices"))
    for file in os.listdir(matrices_path):
        if file.startswith("res") and (file.endswith("cuda") or file.endswith("c")):
            parts = file.split("_")
            operation = parts[1]
            size = parts[2]
            if not verify(file, f"res_{operation}_{size}_java"):
                return False
    return True
