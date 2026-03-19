
class BenchmarkData:
    def __init__(self, hardware, size, iteration, algorithm, language):
        self.hardware = hardware
        self.size = size
        self.iteration = iteration
        self.algorithm = algorithm
        self.language = language
        self.x = []
        self.y = []

    def __hash__(self):
        return hash(self.hardware + self.size + self.iteration + self.algorithm + self.language)