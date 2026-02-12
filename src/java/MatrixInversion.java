import java.io.IOException;
import java.util.Arrays;

public class MatrixInversion {

    public static int hasArgument(String[] args, String arg) {
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals(arg)) return i;
        }
        return -1;
    }

    public static Matrix[] getLUDecomposition(float[][] a) {
        int N = a.length;
        Matrix l = new Matrix(N);
        Matrix u = new Matrix(N);

        // By default everything in the array is 0.0
        float[][] alpha = l.m;
        float[][] beta = u.m;

        for (int i = 0; i < N; i++) {
            alpha[i][i] = 1;
        }

        for (int j = 0; j < N; j++) {
            for (int i = 0; i <= j; i++) {
                float sum = 0.0f;
                for (int k = 0; k < i; k++) {
                    sum += alpha[i][k] * beta[j][k];
                }
                beta[j][i] = a[i][j] - sum;

                for (int z = j + 1; z < N; z++) {
                    sum = 0;
                    for (int k = 0; k < j; k++) {
                        sum += alpha[z][k] * beta[j][k];
                    }
                    alpha[z][j] = (1 / beta[j][j]) * (a[z][j] - sum);
                }
            }
        }

        transposeMatrix(beta);

        return new Matrix[] { l, u };
    }

    public static void transposeMatrix(float[][] m) {
        for (int i = 0; i < m.length; i++) {
            for (int j = 0; j < i; j++) {
                float tmp = m[i][j];
                m[i][j] = m[j][i];
                m[j][i] = tmp;
            }
        }
    }

    public static void main(String[] args) throws IOException {
        Matrix matrix = new Matrix(args[args.length - 2]);

        long before = System.nanoTime();
        Matrix[] matrices = getLUDecomposition(matrix.m);
        Matrix l = matrices[0];
        Matrix u = matrices[1];
        long after = System.nanoTime();
        long runtime = after - before;

        if (Arrays.stream(args).anyMatch("--time"::equals)) {
            System.out.println(runtime);
        }
        if (Arrays.stream(args).anyMatch("--printResult"::equals)) {
            Matrix.printMatrix(l.m);
            Matrix.printMatrix(u.m);
        }
        // int outputResult = hasArgument(args, "--outputresult");
        // if (outputResult > -1) {
        //     Matrix.outputMatrix(result, args[outputResult + 1]);
        // }
    }
}
