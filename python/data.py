
class BenchmarkData:
    def __init__(self, hardware, iteration, algorithm, language, cuda_time = False):
        self.hardware = hardware
        self.iteration = iteration
        self.algorithm = algorithm
        self.language = language
        self.cuda_time = cuda_time
        self.x = []
        self.y = []

    def description(self):
        return self.hardware + " " + self.iteration +  " " + self.algorithm +  " " + self.language + (" Kernel time" if self.cuda_time else "")

    def appendx(self, x):
        self.x.append(x)

    def appendy(self, y):
        self.y.append(y)
