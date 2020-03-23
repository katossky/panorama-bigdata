import json
from random import randint, choice, triangular
from time import time_ns


class ReccordKamaelott():

    def __init__(self):
        self.Creation_Time = time_ns() - randint(0, 10**-9)
        self.Arrival_Time = time_ns()
        self.quote = choice(list(map(chr, range(97, 123))))


    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          sort_keys=True, indent=None)

