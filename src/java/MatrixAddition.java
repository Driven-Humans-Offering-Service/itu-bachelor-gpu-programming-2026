import java.io.IOException;
import java.util.Arrays;

public class MatrixAddition {

    public static long runtime;

    public static int hasArgument(String[] args, String arg) {
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals(arg))
                return i;
        }
        return -1;
    }

    public static float[][] addMatricies(
            float[][] matrix_1,
            float[][] matrix_2) {
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
        long before_load = System.nanoTime();
        Matrix m1 = new Matrix(args[args.length - 2]);
        Matrix m2 = new Matrix(args[args.length - 1]);
        long after_load = System.nanoTime();

        float[][] result = addMatricies(m2.m, m1.m);

        if (Arrays.stream(args).anyMatch("--time"::equals)) {
            System.out.println(runtime);
        }
        if (Arrays.stream(args).anyMatch("--loadtime"::equals)) {
            System.out.println(after_load - before_load);
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
