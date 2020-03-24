"""
Script pour récupérer les citations d'Arthur dans Kaamelott
"""
from random import shuffle

import requests
import bs4 as BeautifulSoup
import codecs
from quote import Quote

urls = {"Arthur " : 'https://fr.wikiquote.org/wiki/Kaamelott/Arthur',
        "Kadoc": 'https://fr.wikiquote.org/wiki/Kaamelott/Kadoc',
        "Karadoc":'https://fr.wikiquote.org/wiki/Kaamelott/Karadoc',
        "Lancelot":'https://fr.wikiquote.org/wiki/Kaamelott/Lancelot',
        "Léodagan":'https://fr.wikiquote.org/wiki/Kaamelott/L%C3%A9odagan',
        "Loth":'https://fr.wikiquote.org/wiki/Kaamelott/Loth',
        "Maitre d'arme":'https://fr.wikiquote.org/wiki/Kaamelott/Le_ma%C3'
                        '%AEtre_d%E2%80%99armes',
        "Mélagant":'https://fr.wikiquote.org/wiki/Kaamelott/M%C3%A9l%C3'
                   '%A9agant'
        }
quotes = []
for personnage in urls:

    page = requests.get(urls[personnage])
    soup = BeautifulSoup.BeautifulSoup(page.text.encode('utf-8'), 'html.parser')
    temp_quotes = soup.find_all("div", {"class": "citation"})
    quotes_str = map(lambda  qte : Quote(personnage, qte.get_text().replace(
        u'\xa0', u' ')), temp_quotes)
    quotes.extend(quotes_str)

print(quotes[0].toJSON())

shuffle(quotes)
with codecs.open("quote.json", "w", "utf-8") as file: # Use file to refer to
    # the file object
    for quote in quotes :
         file.write(quote.toJSON()+"\n")
