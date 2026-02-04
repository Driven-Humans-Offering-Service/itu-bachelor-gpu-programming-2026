.PHONY: setup old

compile:
	@mkdir -p build/java build/c build/cuda
	@javac -d build/java ./src/java/Matrix.java ./src/java/MatrixAddition.java 
	@gcc -O3 ./src/utilities/matrix.c ./src/c/matrix_addition.c -o ./build/c/matrix_addition.out
	@nvcc -O3 ./src/utilities/matrix.c ./src/cuda/matrix_addition.cu -o ./build/cuda/matrix_addition.out

old:
	@cat matrices/matrix_0_5120x5120.csv matrices/matrix_1_5120x5120.csv | java addition/MatrixAddition.java --time
	gcc -O3 ./addition/matrix_addition.c -o addition/MatrixAddition.out
	./addition/MatrixAddition.out ./matrices/matrix_0_5120x5120.csv matrices/matrix_1_5120x5120.csv
