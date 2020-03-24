import json
from random import randint, choice
from time import time


class ReccordKamaelott():

    def __init__(self):
        self.Creation_Time = int(time()*10**9) - randint(0, 10**9)
        self.Arrival_Time = int(time()*10**9)
        self.quote = choice(list(map(chr, range(97, 123))))


    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          sort_keys=True, indent=None)

