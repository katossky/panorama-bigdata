import json
from random import randint, choice, triangular
from time import time_ns


class Reccord():
    index = 0

    def __init__(self):
        self.Creation_Time = int(time()*10**9) - randint(0, 10**9)
        self.Arrival_Time = int(time()*10**9)
        self.Device = None
        self.Index = None
        self.Model = None
        self.User = None
        self.gt = None
        self.x = None
        self.y = None
        self.z = None

        if randint(0, 100) < 99:
            self.normal_reccord()
        else :
            print("An error occurd")


    def normal_reccord(self):
        self.Device = "nexus4_%s" % randint(1, 2)
        Reccord.index += 1
        self.Index = Reccord.index
        self.Model = "nexus4"
        self.User = choice(list(map(chr, range(97, 123))))
        self.gt = choice(
            ["stand", "sit", "walk", "stairsdown", "unknown", "stairsup",
             "bike", "run"])
        self.x = triangular(-1, 1, 0.5)
        self.y = triangular(-0.3, 0.2, 0)
        self.z = triangular(1, 3, 1.1)


    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          sort_keys=True, indent=None)


if __name__ == '__main__':
    reccord = Reccord()
    print(reccord.toJSON())
