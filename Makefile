.PHONY: all
all:
	@cat matrices/matrix_0_5120x5120.csv matrices/matrix_1_5120x5120.csv | java addition/MatrixAddition.java --time
	gcc -O3 ./addition/matrix_addition.c -o addition/MatrixAddition.out
	./addition/MatrixAddition.out ./matrices/matrix_0_5120x5120.csv matrices/matrix_1_5120x5120.csv
