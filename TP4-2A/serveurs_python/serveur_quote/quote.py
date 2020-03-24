import json


class Quote():
    def __init__(self, character, quote):
        self.character = character
        self.quote = quote

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
                          ensure_ascii=False,
                          sort_keys=True, indent=None)
