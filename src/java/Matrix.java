import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class Matrix {

    public float[][] m;

    public Matrix(String filename) throws IOException {
        File f = new File(filename);
        BufferedReader br = new BufferedReader(new FileReader(f));

        int N = Integer.parseInt(br.readLine().strip());
        m = readMatrix(br, N);
    }

    private float[][] readMatrix(BufferedReader br, int size)
            throws IOException {
        float[][] matrix = new float[size][size];
        for (int i = 0; i < size; i++) {
            String[] line = br.readLine().strip().split(" ");
            for (int j = 0; j < size; j++) {
                matrix[i][j] = Float.parseFloat(line[j]);
            }
        }
        return matrix;
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

    public static void outputMatrix(float[][] matrix, String path) throws IOException {
        File f = new File(path);
        BufferedWriter writer = new BufferedWriter(new FileWriter(f));

        for (int i = 0; i < matrix.length; i++) {
            StringBuilder sb = new StringBuilder();
            for (int j = 0; j < matrix.length; j++) {
                float num = matrix[i][j];
                sb.append(num);
                sb.append(" ");
            }
            sb.append("\n");
            writer.write(sb.toString());
        }

        writer.close();

    }
}
