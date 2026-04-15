import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.function.BiFunction;

public class Matrix {

    public float[][] m;

    public Matrix(int size) {
        m = new float[size][size];
    }

    public Matrix(String filename) throws IOException {
        byte[] bytes = Files.readAllBytes(Paths.get(filename));

        ByteBuffer buffer = ByteBuffer.wrap(bytes);
        buffer.order(ByteOrder.LITTLE_ENDIAN);

        int N = buffer.getInt();
        m = readMatrix(buffer, N);
    }

    private float[][] readMatrix(ByteBuffer br, int size) throws IOException {
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

    public boolean isInvertible() {
        for (int i = 0; i < m.length; i++) {
            if (Math.abs(m[i][i]) < 1e-6f) { // near-zero threshold for floats
                return false;
            }
        }
        return true;
    }

    public static void outputMatrix(float[][] matrix, String path)
            throws IOException {
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

    public static int hasArgument(String[] args, String arg) {
        for (int i = 0; i < args.length; i++) {
            if (args[i].equals(arg))
                return i;
        }
        return -1;
    }

    public static void sharedMain(BiFunction<float[][], float[][], float[][]> main, String[] args) throws IOException {
        long before_load = System.nanoTime();
        Matrix m1 = new Matrix(args[args.length - 2]);
        Matrix m2 = new Matrix(args[args.length - 1]);
        long after_load = System.nanoTime();

        long before = System.nanoTime();
        float[][] result = main.apply(m1.m, m2.m);
        long after = System.nanoTime();
        long runtime = after - before;

        if (hasArgument(args, "--time") >= 0) {
            System.out.println(runtime);
        }
        if (hasArgument(args, "--loadtime") >= 0) {
            System.out.println(after_load - before_load);
        }
        if (hasArgument(args, "--printresult") >= 0) {
            Matrix.printMatrix(result);
        }
        int outputResult = hasArgument(args, "--outputresult");
        if (outputResult > -1) {
            Matrix.outputMatrix(result, args[outputResult + 1]);
        }
    }
}
