import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.StringTokenizer;

public class Main {

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

	public static void main(String[] args) {

		// Create a FastReader instance for input
		FastReader s = new FastReader();
		float[][] inputMatrix;
		final int N = s.nextInt();
		inputMatrix = new float[N][N];
		for (int i = 0; i < N; i++) {
			for (int j = 0; j < N; j++) {
				inputMatrix[i][j] = (float) s.nextDouble();
			}
		}

	}
}
