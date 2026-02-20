import java.io.IOException;
import java.util.Arrays;

public class MatrixInversion {

    public static int hasArgument(String[] args, String arg) {
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals(arg))
                return i;
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
            }
            for (int i = j + 1; i < N; i++) {
                float sum = 0;
                var alpha_p = alpha[i];
                var beta_p = beta[j];
                for (int k = 0; k < j; k++) {
                    sum += alpha_p[k] * beta_p[k];
                }
                alpha[i][j] = (1 / beta[j][j]) * (a[i][j] - sum);
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

    public static float[] findY(float[][] alpha, float[] b) {
        int N = alpha.length;
        float[] y = new float[N];

        y[0] = b[0] / alpha[0][0];

        for (int i = 1; i < N; i++) {
            float sum = 0.0f;
            for (int j = 0; j < i; j++) {
                sum += alpha[i][j] * y[j];
            }
            y[i] = (b[i] - sum) / alpha[i][i];
        }

        return y;
    }

    public static float[] findX(float[][] beta, float[] y) {
        int N = beta.length;
        float[] x = new float[N];

        x[N - 1] = y[N - 1] / beta[N - 1][N - 1];

        for (int i = N - 2; i >= 0; i--) {

            float sum = 0.0f;

            for (int j = i; j < N; j++) {
                sum += beta[i][j] * x[j];
            }

            x[i] = (y[i] - sum) / beta[i][i];
        }

        return x;

    }

    public static float[][] getIdentityMatrix(int N) {
        float[][] E = new float[N][N];

        for (int i = 0; i < N; i++) {
            E[i][i] = 1;
        }
        return E;
    }

    public static float[][] inverse(float[][] alpha, float[][] beta) {
        int N = alpha.length;

        float[][] E = getIdentityMatrix(N);

        float[][] X = new float[N][N];

        for (int i = 0; i < N; i++) {
            float[] y = findY(alpha, E[i]);
            System.out.print("[");
            for (int j = 0; j < N; j++)
                System.out.print(y[j] + ", ");
            System.out.println("]");
            X[i] = findX(beta, y);
        }

        transposeMatrix(X);

        return X;

    }

    public static void main(String[] args) throws IOException {
        Matrix matrix = new Matrix(args[args.length - 2]);

        long before = System.nanoTime();
        Matrix[] matrices = getLUDecomposition(matrix.m);
        Matrix l = matrices[0];
        Matrix u = matrices[1];
        float[][] X = inverse(l.m, u.m);
        long after = System.nanoTime();
        long runtime = after - before;

        if (Arrays.stream(args).anyMatch("--time"::equals)) {
            System.out.println(runtime);
        }
        if (Arrays.stream(args).anyMatch("--printresult"::equals)) {
            Matrix.printMatrix(l.m);
            Matrix.printMatrix(u.m);
            Matrix.printMatrix(X);
        }
        // int outputResult = hasArgument(args, "--outputresult");
        // if (outputResult > -1) {
        // Matrix.outputMatrix(result, args[outputResult + 1]);
        // }
    }
}
