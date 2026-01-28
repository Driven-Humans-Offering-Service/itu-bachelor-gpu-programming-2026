import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.StringTokenizer;

public class MatrixAddition {

    // Taken from
    // https://www.geeksforgeeks.org/competitive-programming/fast-io-in-java-in-competitive-programming/
    // FastReader class for efficient input
    static class FastReader {

        // BufferedReader to read input
        BufferedReader b;

        // StringTokenizer to tokenize input
        StringTokenizer s;

        // Constructor to initialize BufferedReader
        public FastReader() {
            b = new BufferedReader(new InputStreamReader(System.in));
        }

        // Method to read the next token as a string
        String next() {
            while (s == null || !s.hasMoreElements()) {
                try {
                    s = new StringTokenizer(b.readLine());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            return s.nextToken();
        }

        // Method to read the next token as an integer
        int nextInt() {
            return Integer.parseInt(next());
        }

        // Method to read the next token as a long
        long nextLong() {
            return Long.parseLong(next());
        }

        // Method to read the next token as a double
        double nextDouble() {
            return Double.parseDouble(next());
        }

        // Method to read the next line as a string
        String nextLine() {
            String str = "";
            try {
                if (s.hasMoreTokens()) {
                    str = s.nextToken("\n");
                } else {
                    str = b.readLine();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            return str;
        }
    }

    public static final FastReader s = new FastReader();

    public static float[][] readMatrix(int size) {
        float[][] matrix = new float[size][size];
        for (int i = 0; i < size; i++) {
            String[] line = s.nextLine().split(",");
            for (int j = 0; j < size; j++) {
                matrix[i][j] = Float.parseFloat(line[j]);
            }
        }
        return matrix;
    }

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

    public static void printMatrix(float[][] matrix) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < matrix.length; i++) {
            sb.append("[ ");
            for (int j = 0; j < matrix.length; j++) {
                sb.append(matrix[i][j]);
                sb.append(", ");
            }
            sb.append("]\n");
        }
        System.out.println(sb.toString());
    }

    public static void main(String[] args) {
        // Create a FastReader instance for input
        final int N = s.nextInt();
        var inputMatrix_1 = readMatrix(N);
        s.nextInt();
        var inputMatrix_2 = readMatrix(N);
        var result = addMatricies(inputMatrix_1, inputMatrix_2);

        printMatrix(result);
    }
}
