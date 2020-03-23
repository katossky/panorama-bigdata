import json
from random import randint, choice, triangular
from time import time_ns


phrase = [
    "Si Monsieur et Madame préfèrent s'envoyer des fions dans l'intimité, "
    "je peux aussi me retirer",
    "Si monsieur et madame pouvaient remettre leurs roulages de galoches à "
    "plus tard, il me semblerait judicieux de foutre le camp d'ici au plus vite."
    ,"Excusez-moi, est-ce qu'à un seul moment, j'aurais par mégarde donné le moindre signe de vouloir discuter avec vous?"
    , "Votre frère il va attaquer un trirème avec une barque ?"
    , 

]

class ReccordKamaelott():

    def __init__(self):
        self.Creation_Time = time_ns() - randint(0, 10**-9)
        self.Arrival_Time = time_ns()
        self.quote = choice(list(map(chr, range(97, 123))))


    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          sort_keys=True, indent=None)

