import java.io.IOException;
import java.util.Arrays;

public class MatrixAddition {

    public static long runtime;

    public static float[][] addMatricies(
        float[][] matrix_1,
        float[][] matrix_2
    ) {
        float[][] result = new float[matrix_1.length][matrix_1.length];
        long before = System.nanoTime();
        for (int i = 0; i < matrix_2.length; i++) {
            for (int j = 0; j < matrix_2.length; j++) {
                result[i][j] = matrix_1[i][j] + matrix_2[i][j];
            }
        }
        long after = System.nanoTime();
        runtime = after - before;
        return result;
    }

    public static void main(String[] args) throws IOException {
        Matrix m1 = new Matrix(args[args.length - 2]);
        Matrix m2 = new Matrix(args[args.length - 1]);

        float[][] result = addMatricies(m2.m, m1.m);

        if (Arrays.stream(args).anyMatch("--time"::equals)) {
            System.out.println(runtime);
        }
        if (Arrays.stream(args).anyMatch("--printResult"::equals)) {
            Matrix.printMatrix(result);
        }
    }
}
