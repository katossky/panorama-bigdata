## TP noté

Votre but est de construire la première brique dans un tableau de bord pour Wikimédia, la maison mère de Wikipédia, afin de surveiller les articles de l'encyclopédie et de la défendre contre les pillages.

Wikimédia publie un flux de tous les changements qui ont lieu sur l'ensemble des plate-formes à l'adresse suivante: `https://stream.wikimedia.org/v2/stream/recentchange`. Le format n'est pas adapté à Spark alors, comme précédemment, vous devez lancer un serveur qui lit, convertit et transfère le flux vers un port local auquel Spark peut s'abonner:

Chaque changement est un object JSON de la forme suivante:

```json
{
   "$schema":"/mediawiki/recentchange/1.0.0",
   "id":1243377776,
   "type":"categorize",
   "namespace":14,
   "title":"Category:NA-importance India articles",
   "comment":"[[:Category talk:1990s in Goa]] added to category",
   "timestamp":1585047749,
   "user":"Jevansen",
   "bot":false,
   "server_url":"https://en.wikipedia.org",
   "server_name":"en.wikipedia.org",
   "server_script_path":"/w",
   "wiki":"enwiki",
   "parsedcomment":"<a href=\"/wiki/Category_talk:1990s_in_Goa\" title=\"Category talk:1990s in Goa\">Category talk:1990s in Goa</a> added to category"
}
```

Les variables qui nous intéressent sont: `title` (nom de la page), `user` (nom de l'utilisateur), `bot` (est-ce un robot qui a produit le changement), `timestamp` (à quel moment le changement a-t-il été produit), `wiki` (quel site de l'écosystème Wikimédia a été modifié).

1. Stockez ces informations (et uniquement celles-ci) dans un DataSet qui se mettra à jour toutes les 5 secondes
2. Combien de changements sont advenus depuis le début de notre abonnement, sur chaque site de Wikimédia? (vous afficherez le résultat dans la console)
3. Restreignez vous aux données de Wikipédia en français (`wiki=="frwiki"`). Maintenez à jour un DataSet qui donne le nombre d'édition (`type=="edit"`) dans une fenêtre glissante d'une heure calculée toutes les 5 minutes
4. En raison d'un risque élevé de pillage des pages suite à un événement majeur en Haute-Garonne, Wikimédia souhaite mettre en place un suivi des modifications des pages Wikipédia sur ce département. Le fichier `hte-garonne.csv` contient la liste des communes de Haute-Garonne (`communeLabel`), ainsi que le nom de la page Wikipédia correspondante (`articleName`) telle que figurant sur la base de données Wikidata[^1]. Combien de modifications ont été effectuées sur l'une de ces pages depuis le début de l'abonnement?

**Vous rendrez votre code au format `.py` sous Moodle.**

[^1]: La requête pour obtenir ces données depuis `https://query.wikidata.org` est la suivante:

```sparql
SELECT ?commune ?communeLabel ?articleName WHERE {
  
  ?commune p:P31 ?estCommune.    # P31 = est une instance de
  ?estCommune ps:P31 wd:Q484170. # Q484170 = commune de France
  ?commune wdt:P131 wd:Q12538.   # P131 = est situé dans ; Q12538 = Haute-Garonne
  MINUS{?estCommune pq:P582 ?dateDeFinCommune.} # P582 = a pour date de fin (cas des anciennes communes)
  
  ?article schema:about ?commune.
  ?article schema:isPartOf <https://fr.wikipedia.org/>.
  ?article schema:name ?articleName.
  
  SERVICE wikibase:label { bd:serviceParam wikibase:language "fr". }
  
}
```