import json
from random import randint, choice, triangular
from time import time


class Reccord2():
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
        self.Device = "smartWatchX%s" % randint(1, 12)
        Reccord2.index += 1
        self.Index = Reccord2.index
        self.Model = "smartWatch"
        self.User = choice(list(map(chr, range(97, 123))))
        self.bpm = randint(60, 200)

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          sort_keys=True, indent=None)


if __name__ == '__main__':
    reccord = Reccord2()
    print(reccord.toJSON())
