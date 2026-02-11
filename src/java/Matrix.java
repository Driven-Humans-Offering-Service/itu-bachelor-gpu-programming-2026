import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Paths;

public class Matrix {

    public float[][] m;

    public Matrix(String filename) throws IOException {
        byte[] bytes = Files.readAllBytes(Paths.get(filename));

        ByteBuffer buffer = ByteBuffer.wrap(bytes);
        buffer.order(ByteOrder.LITTLE_ENDIAN);

        int N = buffer.getInt();
        m = readMatrix(buffer, N);
    }

    private float[][] readMatrix(ByteBuffer br, int size)
            throws IOException {
        float[][] matrix = new float[size][size];
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                matrix[i][j] = br.getFloat();
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
