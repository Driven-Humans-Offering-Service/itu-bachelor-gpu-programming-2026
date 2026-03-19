
class BenchmarkData:
    def __init__(self, hardware, iteration, algorithm, language):
        self.hardware = hardware
        self.iteration = iteration
        self.algorithm = algorithm
        self.language = language
        self.x = []
        self.y = []

    def description(self):
        return self.hardware + self.iteration + self.algorithm + self.language

    def appendx(self, x):
        self.x.append(x)

    def appendy(self, y):
        self.y.append(y)