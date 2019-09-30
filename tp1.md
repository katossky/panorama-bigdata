# TP introduction à Apache Spark

Spark ( https://spark.apache.org/) est un framework open source de calcul distribué, il est aujourd'hui l'un des systèmes les plus populaires de ce domaine.

## Connexion au serveur

Lancer Putty depuis le menu démarrer.
**Host Name :** clust-n8

Dans la console qui s'afffiche, renseigner votre identifiant et mot de passe habituel.

Spark se lance en exécutant la commande :

- `/etc/spark/bin/spark-shell` (pour l'interface en Scala, l'interface native)
- `/etc/spark/bin/pyspark` (pour l'interface en Python)
- `/etc/spark/bin/sparkR`  (pour l'interface en R)

Pour ce TP nous travaillerons avec l'historique des vols de ligne aux États-Unis en Janvier 2018.
Les données peuvent être téléchargées depuis https://www.transtats.bts.gov/DL_SelectFields.asp?Table_ID=236&DB_Short_Name=On-Time


## Rappels sur le calcul distribué

## Exercice 1: Premiers contacts

### Spark-shell

Une fois *spark-shell* démarré, un environnement est proposé où il possible de taper du code Scala.
Une session *Spark* est l'interface privilégiée de programmation. Elle est accessible par le mot-clé `spark`.

Quelques commandes utiles pour *spark-shell* :

- `:quit` pour quitter *spark-shell*
- `:history` pour afficher les commandes précédemment entrées
- `:help` pour afficher la liste des commandes possibles
- `:type <variable>` pour afficher le type d'une variable

L'auto-complétion est disponible au sein du *spark-shell*. Par exemple en rentrant `spa` puis en appuyant sur TAB, *spark-shell* affiche les différentes possibilités.

### Spark UI

Lors du démarrage de spark-shell, une ligne de ce type est affichée `Spark context Web UI available at http://xxx.xxx.xxx.xx:xxxx`.
Ouvrir un navigateur à cette adresse permet d'afficher Spark UI.

### DataFrame

Exécutons maintenant la simple tâche de créer une plage de nombres.
Cette plage de nombres est juste comme une colonne dans un tableur :

`val myRange = spark.range(1000).toDF("number")`

Vous venez de lancer votre premier code Spark !
Nous avons créé une DataFrame d'une colonne contenant 1000 lignes avec des valeurs de 0 à 999.
Cette plage de nombre représente une collection distribuée.
Lors d'une exécution sur un cluster, chaque partie de cette plage de nombres existe sur un exécuteur différent.
C'est une DataFrame Spark.

Une DataFrame est donc une collection distribuée de données, et représente simplement un tableau organisé en ligne et en colonne.
Le concept de DataFrame n'est pas unique à Spark, celui-ci est présent en Python et R par exemple.
Au contraire de Python et R (dans la plupart des cas), une DataFrame Spark peut être répartie sur des centaines ou milliers d'ordinateurs.


La fonction `printSchema` affiche les noms des colonnes avec le type associé dans le console.

`myRange.printSchema()`

La fonction show() permet d'afficher les données.
Il est possible de passer un paramètre à show pour indiquer le nomdre de données à afficher.

`myRange.show()`


Dans Spark, les structures de données de base sont immuables, ce qui signifie qu'elles ne peuvent pas être modifiées après qu'elles aient été créées.
Pour "changer" une DataFrame, vous devez indiquer à Spark comment vous souhaitez la modifier pour faire ce que vous voulez.
Ces instructions sont appelées transformations.
Exécutons une transformation simple pour trouver tous les nombres pairs dans notre DataFrame actuelle :

`val divisBy2 = myRange.where("number % 2 = 0")`

**Q1.1** Observez *spark-shell* et Spark-UI en exécutant les instructions précédentes.

Les transformations nous permettent de construire notre plan de transformation logique.
Pour déclencher le calcul, nous menons une action.
Une action demande à Spark de calculer un résultat à partir d'une série de transformations.
L'action la plus simple est le comptage, qui nous donne le nombre total d'enregistrements dans la DataFrame :

`divisBy2.count()`

La réponse à cette instruction doit être 500.
Bien sûr, le comptage n'est pas la seule action.
Il existe des actions pour :

- visualiser des données dans la console
- collecter des données
- écrire dans des sources de données de sortie

En spécifiant cette action de comptage, nous avons lancé une tâche Spark qui exécute notre transformation de filtre, puis une agrégation qui effectue les comptages, et ensuite une collection, qui affiche notre résultat. 

**Q1.2** Observez spark-shell et Spark-UI en exécutant l'instruction précédente. Que constatez-vous ?

### Évaluation paresseuse

L'évaluation paresseuse (*lazy evaluation*) signifie que Spark attendra jusqu'au tout dernier moment pour exécuter le graphe des instructions de calcul.
Dans Spark, au lieu de modifier les données immédiatement lorsque vous exprimez une opération, vous construisez un plan de transformations que vous aimeriez appliquer aux données de base.
En attendant la dernière minute pour exécuter le code, Spark compile ce plan à partir de vos transformations brutes en un plan physique rationalisé qui s'exécutera aussi efficacement que possible sur l'ensemble du cluster.
Cela offre d'immenses avantages car Spark peut optimiser le processus de l'ensemble des flux de données d'un bout à l'autre.
Par exemple si nous construisons une grosse tâche Spark mais spécifions un filtre à la fin qui nous demande seulement de récupérer une seule ligne de nos données, la façon la plus efficace de l'exécuter est d'accéder à cette unique ligne dont nous avons besoin.
Spark va en fait optimiser cela pour nous en poussant le filtre vers le bas automatiquement.

### Spark et SQL

Dans cette partie, nous allons analyser les données de vols du _United States Bureau of Transportations statistics_.
Le CSV est nommé `2015-summary.csv` est est accessible dans le dossier `/projets/DataSpark`.

Spark inclut la capacité de lire et d'écrire à partir d'un grand nombre de sources de données.
Pour cela nous utiliserons un DataFrameReader (https://spark.apache.org/docs/latest/api/java/org/apache/spark/sql/DataFrameReader.html).
Nous allons spécifier le format de fichier ainsi que toutes les options que nous souhaitons.
Dans notre cas, nous voulons faire de l'inférence de schéma, ce qui signifie que Spark va déterminer automatiquement le type des données.
Pour obtenir l'information du schéma, Spark lit le début données et tente ensuite d'analyser les types dans ces lignes.
Les différents types de Spark sont disponibles ici : https://spark.apache.org/docs/latest/sql-reference.html#data-types
Nous voulons aussi spécifier que la première ligne du fichier est l'en-tête.

Cela donne la commande suivante :

```{scala}
val flight2015 = spark
	.read
	.option("inferSchema", "true")
	.option("header", "true")
	.csv("2015-summary.csv")
```

Nous pouvons maintenant faire des requêtes types SQL sur nos données.

Par exemple : 
```{scala}
flight2015
	.groupBy("DEST_COUNTRY_NAME")
	.count()
	.show(40)
```

Plus de documentation est disponible à l'adresse suivante : https://spark.apache.org/docs/2.3.0/sql-programming-guide.html

Les différentes fonctions nécessaires peuvent être importé selon :
```{scala}
import org.apache.spark.sql._
import sqlContext.implicits._
```

Pour chaque instruction , Spark élabore un plan pour la façon dont il exécutera cela dans l'ensemble du cluster.
Nous pouvons appeler `explain()` sur n'importe quel objet DataFrame pour voir comment Spark exécutera cette requête. Le texte de la console se lit de bas (première instruction effectuée) en haut (dernière instruction) :

```{scala}
flightData2015.sort("count").explain()
```

**Q1.3** Combien de pays sont desservis depuis les États-Unis?
<!-- flight2015.filter("ORIGIN_COUNTRY_NAME = 'United States'").count() -->

**Q1.4** Trouvez les 5 pays ayant le plus de vols vers les États-Unis. En utilisation la méthode `explain()`, observez le plan physique. Est-ce que le plan change si vous inversez les instructions?
<!-- flight2015.sort(desc("count")).filter("DEST_COUNTRY_NAME = 'United States'").show(5) -->

**Q1.5** Charger dans une dataframe les données du fichier sur les vols `2018-01-allFlights.csv`, situé dans le même dossier, dans une variable `flights2018`. Est-ce que les fonctions `read` sont évaluées paresseusement ? Listez les variables disponibles.

<!--
val flights2018 = spark.read.option("inferSchema", "true").option("header", "true").csv("/projets/DataSpark/2018-01-allFlights.csv")

flights2018.printSchema()
-->

**Pour patienter:** refaire les exercices en Python et en R

## Exercice 2: le principe map-reduce

Le principe _map-reduce_ est un sous-ensemble du calculs parallèle ou distribué. Il s'agit de décomposer un calcul long en:

1. une suite d'opérations sur un sous-ensemble des données, ne nécessitant pas de communication entre les processeurs de calcul (étape *map*)
2. la combinaison des résultats intermédiaires en un résultat final, selon le principe d'un accumulateur ; le résultat final est actualisé à chaque fois qu'un processeurs de l'étape intermédiaire termine son calcul (étape *reduce*).

Une analogie est le décompte des voix dans une élection, où l'on procède d'abord par un décompte par bureau de vote. Comme dans le cas d'une élection, la découpe du travail permet de revenir localement sur un sous-travail (ici, le décompte d'un bureau spécifique), sans compromettre le reste des opérations (le décompte dans les autres bureaux). Le principe *map-reduce* est dit "peu sensible aux erreurs" (EN: _fault-tolerant_): la panne d'un processeur/nœud ne compromet pas l'ensemble du calcul, et les calculs non effectués sont immédiatement transmis à d'autres processeurs/nœuds.

**Q.2.1.** Trouvez deux exemples de calculs faciles à paralléliser avec le principe _map-reduce_ et un exemple de calcul difficile ou impossible à paralléliser sur ce principe[^1]. <!-- Facile: moyenne, somme, techniques de Monte Carlo. Difficile: inversion de matrice. Impossible: travelling salesman. Opposition entre "embarassingly parallel problems" et "inherently sequential problems". -->

La méthode `count()` est elle-aussi une opération _map-reduce_. `flights2018.count()` est équivalent à:

```{scala}
flights2018
  .map(flight => 1)
  .reduce( (accumulator, value) => accumulator + value ) // syntaxe équivalente: .reduce(_+_)
```

**Q.2.2.** Pourquoi ce code produit-il le même résultat que `count`? Expliquez la syntaxe `flight => 1` et `(accumulator, value) => accumulator + value`. Comment appelle-t-on ce type d'objet en programmation?

<!-- Au fur et à mesure que les différentes sous-tâches ont fini leur exécution, `accumulator` se rapproche du résultat attendu. (En réalité l'opération `reduce` est le plus souvent commutative puisque le résultat final doit être le même quel que soit l'ordre d'exécution des tâches du `map`. La distinction formelle entre `accumulator` et `value` est donc plus pédagogique qu'autre chose.) -->

**Q.2.3.** Changez une ligne du code précédent pour calculer la distance totale parcourue par des avions de ligne au mois de janvier 2018. (La syntaxe Scala pour récupérer la propriété `p` de type `t` de la ligne `l` d'une _data-frame_ est `l.getAs[t]("p")`.)

<!-- flights2018.map(flight => flight.getAs[Double]("DISTANCE")).reduce( (accumulator, value) => accumulator + value ) -->

**Q.2.4.** Que fait la fonction suivante? Et le code qui suit?

```{scala}
def myFunction( a:Double, b:Double ) : Double = if(b > a) b else a

flights2018
  .map(flight => flight.getAs[Double]("ARR_DELAY"))
  .reduce( myFunction _ ) // Le _ force Scala à interpéter myFunction comme une fonction.
```
<!-- Il est possible d'utiliser des fonctions nommées dans l'étape reduce. 
flights2018.map(flight => flight.getAs[Double]("ARR_DELAY")).reduce( myFunction _ )
-->

**Q.2.5.** L'étape `map` peut renvoyer un n-uplet (EN: _tupple_) et l'opération `reduce` porter sur le n-uplet retourné par chaque processeur / nœud. Que fait le code suivant?

```{scala}
flights2018
  .map(flight => (flight.getAs[Double]("ARR_DELAY"), flight.getAs[java.sql.Date]("FL_DATE")))
  .reduce( (a, b) => if(a._1 > b._1) a else b )
```

<!-- flights2018.map(flight => (flight.getAs[Double]("ARR_DELAY"), flight.getAs[java.sql.Date]("FL_DATE"))).reduce( (a, b) => if(a._1 > b._1) a else b ) -->

**Remarque:** `a._1` permet d'accéder au premier élément du n-upplet `a`.

[^1]: https://softwareengineering.stackexchange.com/questions/144787/what-kind-of-problems-does-mapreduce-solve ; https://stackoverflow.com/questions/806569/whats-the-opposite-of-embarrassingly-parallel ; https://en.wikipedia.org/wiki/Embarrassingly_parallel

**Pour patienter:** refaire les exercices en Python et en R

<!--
flights2018
  .map(flight => flight.DEP_TIME)
  .sort()
  .reduce((a,b) => {println(b);return 1})
-->

<!-- oordre d'exécution-->
<!-- flatMap : reprgorammer la fonciton filter ? -->

## Exercice 3: transformation de données, mise en cache, arbitrage map-reduce

<!-- exécution sur quel processeur / noeud -->
<!-- montrer la duplication -->
<!-- montrer le choix de lieu de stockage -->
<!-- les différentes possibilités -->
<!-- temps d'exécution -->

**Q.3.1.** Créez un nombre aléatoire entre 0 et 1 pour chaque vol de la base de donnée. (Utilisez `scala.util.Random`.)

<!--
var numbers = flights2018.map(flight => scala.util.Random.nextFloat)
-->

**Q.3.2.** Calculez la moyenne de ces nombre, de façon locale. (Vous pouvez utiliser `collect()` pour récupérer un `array` en local.)

<!--
var local_numbers = numbers.collect()
local_numbers.sum / local_numbers.size
-->

**Q.3.3.** Calculez leur moyenne, de façon distribuée selon le schéma _map-reduce_. (Réfléchissez à comment aggréger les sous-calculs avec `reduce`.)

<!--
Solution facile:
var somme = numbers.reduce(_+_)
var count = numbers.count()
somme/count

Solutions difficile:
numbers.map( n => (n, 1) ).reduce( (a,b) => ((a._1*a._2+b._1*b._2)/(a._2+b._2), a._2+b._2) )
-->

**Q.3.4.** Combien de temps avez vous gagné? Pourquoi le résultat est-il différent? <!-- Ce n'est pas plus rapide. Spark pratique l'évaluation retardée (EN: _lazy evaluation_): les expressions sont gardées en forme littérale jusqu'à ce qu'une étape `reduce` soit appelée (`count` compte comme `reduce`). Du coup, la génération aléatoire est effectuée plusieurs fois. -->

**Q.3.5.** Il est possible de forcer l'évaluation d'un résultat intermédiaire avec les méthodes `cache()` et `persist()`. Cela est utile quand votre flux de donnees (EN: _data flow_) possède des "branches", c-à-d lorsqu'une étape de pré-traitement est réutilisée par plusieurs traitements en aval. En ne modifiant qu'une seule ligne de code, appliquez ce principe au calcul de moyenne précédent.

<!--
var numbers = flights2018.map(flight => scala.util.Random.nextFloat).cache()
var sum = numbers.reduce(_+_)
var count = numbers.count()
sum/count
numbers.map( n => (n, 1) ).reduce( (a,b) => ((a._1*a._2+b._1*b._2)/(a._2+b._2), a._2+b._2) )
// mêmes résultats maintenant
-->

**Q.3.6.** Répétez l'opération pour le calcul de la variance.

<!-- **Q.3.7.** La somme peut être réalisée soit dans l'étape _map_ (sur un seul processeur, donc séquentiellement) soit dans l'étape _reduce_ (parallélisé mais besoin de temps pour additionner). Essayer plusieurs façon de découper le data frame en évaluant le temps d'exécution. -->

## Pour approfondir/ réviser:

- Une série de billets introductifs en français:
    1. https://aseigneurin.github.io/2014/10/29/introduction-apache-spark.html
    2. https://aseigneurin.github.io/2014/11/01/initiation-mapreduce-avec-apache-spark.html
    3. https://aseigneurin.github.io/2014/11/06/mapreduce-et-manipulations-par-cles-avec-apache-spark.html
    
- "Quick start", sur le site officiel de Spark: https://spark.apache.org/docs/latest/quick-start.html

- Introduction à Scala: https://docs.scala-lang.org/tutorials/tour/tour-of-scala.html

- Spark: The Definitive Guide, by Bill Chambers and Matei Zaharia, O'Reilly.
