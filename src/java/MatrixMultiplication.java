import java.io.IOException;
import java.util.Arrays;

public class MatrixMultiplication {

    public static int hasArgument(String[] args, String arg) {
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals(arg)) return i;
        }
        return -1;
    }

    public static float[][] multiplyMatricies(
        float[][] matrix_1,
        float[][] matrix_2
    ) {
        float[][] result = new float[matrix_1.length][matrix_1.length];

        for (int i = 0; i < matrix_2.length; i++) {
            for (int k = 0; k < matrix_1.length; k++) {
                for (int j = 0; j < matrix_2.length; j++) {
                    result[i][j] += matrix_1[i][k] * matrix_2[k][j];
                }
            }
        }
        return result;
    }

    public static void main(String[] args) throws IOException {
        Matrix m1 = new Matrix(args[args.length - 2]);
        Matrix m2 = new Matrix(args[args.length - 1]);

        long before = System.nanoTime();
        float[][] result = multiplyMatricies(m2.m, m1.m);
        long after = System.nanoTime();
        long runtime = after - before;

        if (Arrays.stream(args).anyMatch("--time"::equals)) {
            System.out.println(runtime);
        }
        if (Arrays.stream(args).anyMatch("--printResult"::equals)) {
            Matrix.printMatrix(result);
        }
        int outputResult = hasArgument(args, "--outputresult");
        if (outputResult > -1) {
            Matrix.outputMatrix(result, args[outputResult + 1]);
        }
    }
}
