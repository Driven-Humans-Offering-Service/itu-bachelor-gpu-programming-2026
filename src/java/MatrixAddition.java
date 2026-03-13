import java.io.IOException;
import java.util.Arrays;

public class MatrixAddition {

    public static float[][] addMatricies(
            float[][] matrix_1,
            float[][] matrix_2) {
        float[][] result = new float[matrix_1.length][matrix_1.length];
        for (int i = 0; i < matrix_2.length; i++) {
            for (int j = 0; j < matrix_2.length; j++) {
                result[i][j] = matrix_1[i][j] + matrix_2[i][j];
            }
        }
        return result;
    }

    public static void main(String[] args) throws IOException {
        Matrix.sharedMain((m1, m2) -> {
            return addMatricies(m1, m2);
        }, args);
    }
}
