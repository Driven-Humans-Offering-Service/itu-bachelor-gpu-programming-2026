import random as rand

def generateMatrix(n):
    with open(f"matrix_{n}x{n}.csv", "w") as f:
        for i in range(0,n):
            for j in range(0,n):
                f.write(f"{rand.uniform(0,10)},")
            f.write("\n")

def main():
    i = 20
    for _ in range(0,8):
        generateMatrix(i)
        i*=2
    print("Hello from benchmark!")


if __name__ == "__main__":
    main()

            
