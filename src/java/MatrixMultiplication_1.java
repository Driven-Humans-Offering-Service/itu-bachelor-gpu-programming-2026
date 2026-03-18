import java.io.IOException;
import java.util.Arrays;

public class MatrixMultiplication_0 {

    public static int hasArgument(String[] args, String arg) {
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals(arg))
                return i;
        }
        return -1;
    }

    public static float[][] multiplyMatricies(
            float[][] matrix_1,
            float[][] matrix_2) {
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

        Matrix.sharedMain((m1, m2) -> {
            return multiplyMatricies(m1, m2);
        }, args);
    }
}
