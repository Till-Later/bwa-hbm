from Bcolors import Bcolors

class ScreenPrinter:
    linesPerIndex = 11
    prefix = f"{Bcolors.OKBLUE}>{Bcolors.ENDC}"

    def __init__(self, outputList, index):
        self.outputList = outputList
        self.index = index
        for i in range(
            self.linesPerIndex * self.index,
            self.linesPerIndex * self.index + self.linesPerIndex,
        ):
            self.outputList[i] = f"{self.prefix}\n"

    def setHeader(self, line):
        self.outputList[self.linesPerIndex * self.index] = f"{line}\n"

    def printLine(self, line):
        self.outputList.pop(self.linesPerIndex * self.index + 1)
        self.outputList.insert(
            self.linesPerIndex * self.index + self.linesPerIndex - 1,
            f"{self.prefix} {line}\n",
        )
