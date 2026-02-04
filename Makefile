.PHONY: setup

compile:
	@mkdir -p build/java build/c build/cuda
	@javac -d build/java ./src/java/Matrix.java ./src/java/MatrixAddition.java 
	@gcc -O3 ./src/utilities/utils.c ./src/utilities/matrix.c ./src/c/matrix_addition.c -o ./build/c/matrix_addition.out
	@nvcc -O3 ./src/utilities/utils.c ./src/utilities/matrix.c ./src/cuda/matrix_addition.cu -o ./build/cuda/matrix_addition.out

