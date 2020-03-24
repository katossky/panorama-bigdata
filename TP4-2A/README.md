# TP4 Big Data : Traiter des flux de données avec Spark

## 0. Mise en place

Pour ce dernier TP, vous allez utiliser Spark en local sur **votre VM ensai**. Vous trouverez sur Moodle une archive TP4 qui contient l'intégralité des fichiers utiles pour le TP. Téléchargez et décompressez la. Vous allez obtenir les fichiers suivants

- `serveurs_pythons`,  qui contient les codes qui vont créer des flux de données
- `données utilisateur`, qui contient des données statiques utiles dans le TP
- `README.md`, qui est le sujet du TP au format markdown

1. Allez dans le dossier `serveurs_pythons` et tapez `cmd` dans la barre d'adresse. Cela va vous ouvrir un invite de commande windows.

![ouvrir un terminal](https://raw.githubusercontent.com/katossky/panorama-bigdata/master/img/ouvrir_terminal.png)

2. Installez les packages python nécessaire au fonctionnement des serveurs

   ````
   pip install -r requirements.txt --user --proxy http://pxcache-02.ensai.fr:3128
   ````

3. Lancez le serveur `server1`:

   ````
   python serveur_iot_1\server1.py
   ````

   Gardez ce terminal ouvert ! Vous allez y voir apparaître les données au fur et à mesure qu'elles sont générées. Ce script python envoie des données sur le port `9999` de votre ordinateur.

4. Ouvrez un second terminal, depuis lequel vous lancez pyspark. Tout au long du TP vous garderez les terminaux ouverts, l'un qui génère les données, l'un qui réalise les traitements.

   ````
   %SPARK_HOME%/bin/pyspark --master local[4]
   ````

**Explications:**
   - `%SPARK_HOME%/bin/pyspark` : on exécute le programme `pyspark`
   - `--master local[4]` : on spécifie l'adresse du master ; `local` signifie que l'on va créer un cluster local ; `[4]` qu'on va demander 4 fils d'exécution distincts (qui pourront s'exécuter sur 4 processeurs distincts). Pour se connecter à un cluster existant, il suffirait de remplacer `local[4]` par l'adresse IP du master du cluster.

- :construction: **Fixation du nombre de partitions pour la phase de _shuffle_** Une _partition_ est, en Spark, le nom d'un bloc de données. Par défaut, Spark utilise 200 partitions (200 blocs) lors d'une phase de _shuffle_. Nos mini-batchs de données seront tellement petits que cela n'a pas grand sens ici, et cela risque au contraire de ralentir les traitements.

  ````
spark.conf.set("spark.sql.shuffle.partitions", 5)
  ````

  > :thinking: La phase de _shuffle_ consiste à ré-ordonner les données selon leur clef, entre une étape _map_ et une étape _reduce_. Par exemple, si vous comptez le nombre d'observations dans le groupe dans chaque groupe `g`, l'étape _map_ consiste à compter le nombre de membres du groupe dans un bloc: `{g1:5, g2:10, g4:1, g5:3}` pour un bloc, `{g1:1, g2:2, g3:23, g5:12}` pour un autre. L'étape _shuffle_ consiste à réorganiser les résultats intermédiaires en de nouveaux blocs, avec les mêmes clés au même endroit: `{g1:5, g1:1, g2:10, g2:2}` pour un bloc, `{g4:1, g5:3, g3:23, g5:12}.` pour un autre. De cette façon, l'étape _reduce_ est considérablement accélérée.

- :package: Importer les fonctions nécessaires pour la suite du TP

  ````python
  from time import sleep
  from pyspark.sql.functions import from_json, window, col, expr
  from pyspark.sql.types import StructType, StringType, LongType, DoubleType, ShortType
  ````




## 1. Spark et les flux de données

**Les flux de données sont arrivés progressivement dans Spark.** En 2012, la fonctionalité de traitement de flux de données (Spark Streaming, ou encore DStreams) est ajoutée à Spark, et rend possible le traitement de flux de données avec des fonctions hauts niveaux (comme _map_ et _reduce_). En 2016 une nouvelle interface (ou API) est ajoutée, Structured Streaming, qui se base sur les DataFrames Spark et permet de manipuler des flux de données comme si des tableaux de données classiques.

![data stream](https://databricks.com/wp-content/uploads/2016/07/image01-1.png)

Traiter des données en flux oblige à les traiter au fil de l'eau. Quand une nouvelle observation est disponible, elle est traitée. Le traitement n'a donc pas réellement de fin, et la notion de "résultat" n'a pas grande sens: le résultat est mis à jour en permanence. Par exemple si vous comptez le nombre de tweets produits par heure avec un système de stream, tant qu'une heure n'est pas terminée vous allez avoir un nombre de tweets produit pour l'heure en cours qui augmente. Mais même à la fin de l'heure en question, certains tweets qui n'auront pas eu le temps de vous parvenir vont continuer à arriver, en retard. Peut-être que tel serveur a temporairement retenu une partie du traffic pendant qu'il redémarait?

Les flux de données, ou _streams_, sont très utilisés. Voici quelques cas d'utilisation :

- **Alertes et notifications :** détection de fraude bancaire en temps réel ; suivi d'un réseau électrique grâce à des compteurs intelligents ; accompagnement médical d'une personne via des appareils de mesure connectés, etc.
- **Rapports en temp réel :** nombre d'utilisateur par minute d'un site ; portée d'une nouvelle campagne de publicité ; gestion automatique d'un portefeuille d'actions, etc.
- **ELT (extract transform load) incrémental :** des données non structurées arrivent en permanence et il faut les traiter (filtrer, mettre en forme) avant de les intégrer dans le système d'information de l'entreprise
- **Online machine learning :** des données sont transmises en permanence à un algorithme de machine learning qui améliore ses performences dynamiquement.

Traiter des données en flux présente malheureusement de nombreuses difficultés. En effet puisque le traitement n'a pas de fin, stocker les données indéfiniment génère nécessairement un problème de mémoire à terme. De même, traiter un évènement unique est simple, mais comment traiter une chaîne d'évènements ? (Ex: comment déclencher une alerte si on reçoit les valeurs 5, puis 6, puis 3 à la suite.) Dans un traitement classique, il suffirait de classer les données en fonction d'une variable temporelle mais, à cause la latence dans les transferts, il est possible de recevoir les données dans un ordre différent de l'émission!

Spark offre deux manière de traiter un flux de données: soit enregistrement par enregistrement (_**one record at a time**_), soit par ensemble d'enregistrements arrivés dans une fenêtre de temps (_**micro batching**_).

- Le _**one record at a time**_ assure un faible délai entre l'arrivée d'un enregistrement et son traitement (**faible latence**), au prix d'une limite dans le débit maximal de données à traiter. Autrement dit, ce type de traitement est tout-ou-rien: tant que la quantité de données est faible, les données sont traitées en temps réel ; si le débit excède les capacités de traitement, le système sera incapable de les gérer et le temps réel sera perdu.
- Le _**micro batching**_, quant à lui, traite les données toutes les `t` secondes. Cela veut dire que certaines données ne seront pas traitées immédiatement, mais avec le bénéfice de pouvoir affronter des débits beaucoup plus élevés. C'est le traitement généralement privilégié.

> Pour avoir le meilleur arbitrage latence / débit, le mieux est de diminuer la taille des micro-batchs jusqu'au moment où traiter un batch prend exactement le même temps que les données pour arriver. À partir de là, on remote légèrement la taille des micro-batchs pour atteindre à un point "optimal" entre débit et latence.

## 2. Traiter des données depuis un flux TCP

Dans cette partie du TP vous allez traiter des données type IoT (*Internet of Things*). Les données sont simulées par le serveur `server1`, et essaie d'imiter les données produites par une série de montres connectées. Les données, au format JSON, contiennent diverses données sur les propritétaires des montres :

````js
{
"Arrival_Time": 1584786731698422519,
"Creation_Time": 1584786731485499800,
"Device": "nexus4_2",
"Index": 1039,
"Model": "nexus4",
"User": "b",
"gt": "null",
"x": 0.5642892523651901,
"y": -0.05573411422345695,
"z": 1.136185983195746
}
````

- :computer: Vérifiez que votre serveur `server1` est toujours en activité. Si ce n'est pas le cas, retournez à la mise en place. Ce script python envie des données sur le port `9999` de votre ordinateur. Même si les données sont générées sur votre ordinateur, Spark va s'y connecter comme si elles étaient produite par un service distant.

- :sparkles: Vérifiez que votre autre terminal, qui exécute Spark, est toujours actif. Si ce n'est pas le cas, retournez à la mise en place.

- :signal_strength: Ouvrir le flux TCP ([pour plus d'info sur les sources possibles](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#input-sources))

  ````python
  tcp_stream = spark\
  	.readStream\
      .format("socket")\
      .option("host", "127.0.0.1")\
      .option("port", "9999")\
      .load()
  ````

  - `format("socket")` : spécifie que le flux proviendra d'une socket TCP (pour faire très simple on récupéré des données produites par un serveur). Ce format de fichier est déconseillé pour des applications _en production_[^1] car toute données perdues le sera définitivement. Il n'est pas possible de en cas de redémarrage suite à une erreur de demander les messages des X dernières  minutes. Une façon plus sûre de transmettre un flux de donnée serait d'ajouter des fichiers continuellement dans un dossier (dans ce cas la Spark ne se connecte pas à internet) ou d'utiliser un service dédié comme Kafka ([plus d'info](https://kafka.apache.org/)).
  - `option("host", "127.0.0.1")` : votre ordinateur, vu depuis votre ordinateur, possède l'adresse IP `127.0.0.1`. Pour se connecter à une source distante, il suffirait de remplacer cette adresse IP par celle de la source.
  - `option("port", "9999")`  : la source utilise le port 9999. Ce choix est purement conventionnel mais (1) il doit être le même pour l'émetteur et le récepteur et (2) il est déconseillé d'utiliser des ports "connus" pour éviter tout usage conflictuel du même port. Des exemples de ports connus sont les ports 20 et 21 utilisé pour les transferts de fichier FTP, 80 et 443 pour HTTP et HTTPS respectivement — voir [ici](https://fr.wikipedia.org/wiki/Liste_de_ports_logiciels) pour une liste exhaustive.
  - `load()` : on ouvre le flux
  
[^1]: En production = en utilisation permanente, active. La production s'oppose au développement (la phase de construction d'un programme ou d'une application.)

  > :thinking: Il ne se passe rien!? C'est normal! N'oubliez pas que Spark pratique l'évaluation paresseusex (_lazy evaluation_) : comme on n'utilise pas la source de données, il ne s'y connecte pas.

- :printer: Afficher quelques données

  ````python
  raw_data_console = tcp_stream\
  	.writeStream\
      .format('console')\
      .option('truncate', 'false')\
      .trigger(processingTime='3 seconds')\
      .start()
  
  sleep(10)               # attendre 10 seconde pour voir la console évoluer
  raw_data_console.stop() # fermer le stream.
  # Si le stream continue après 10 secondes,
  # c'est que vous n'avez pas validé la commande!
  # Appuyez sur la touche "entrée".
  ````

  - *writeStream* : on va produire un stream
  - *format('console')* : que l'on écrit dans la console
  - *option('truncate', 'false')* : les colonnes sont affichée en entier. Vous pouvez tester sans pour voir la différence
  - *trigger(processingTime='3 seconds')* : on traite les données par paquet de 3 seconde. Vous pouvez faire varier ce nombre
  - *start()* : on dit (enfin) au stream de commencer

- :printer: Afficher le schéma des données

  ````python
  tcp_stream.schema
  ````

  Voilà la sortie que vous devez obtenir :

  ````
  StructType(List(StructField(value,StringType,true)))
  ````
  
  Qu'est-ce que cela veut dire?
  ````
  StructType(
  
    List( # Liste de vos colones
  
      StructField(value, StringType, true) # Une seule colonne de type string
    
    )
  )
  ````

  Autrement dit, **les données ne sont pas correctement lues**. Chaque ligne est lue comme une seule grande chaîne de caractères. Pour bien les traiter, nous devons appliquer le bon **schéma**.

- :arrow_forward: Définir le schéma de nos données

  ````python
  schema_iot = StructType()\
      .add('Arrival_Time',  LongType(),   True)\
      .add('Creation_Time', LongType(),   True)\
      .add('Device',        StringType(), True)\
      .add('Index',         LongType(),   True)\
      .add('Model',         StringType(), True)\
      .add('User',          StringType(), True)\
      .add('gt',            StringType(), True)\
      .add('x',             DoubleType(), True)\
      .add('y',             DoubleType(), True)\
      .add('z',             DoubleType(), True)
  ````

  Comme les données proviennent d'un flux on ne peut pas inférer le schéma, donc on le définit à la main. Le `True` à la fin de chaque ligne spécifie que l'on accepte les valeurs `null` (plus de détails [dans la documentation](https://spark.apache.org/docs/2.3.0/api/python/pyspark.sql.html#pyspark.sql.types.StructType)).

- :point_down: Appliquer le schéma

  ````python
  iot_data = tcp_stream.selectExpr('CAST(value AS STRING)')\
      .select(from_json('value', schema_iot).alias('json'))\
      .select('json.*')
  ````

  Pour appliquer le schéma on va appliquer une transformation à nos données.

  - `selectExpr('CAST(value AS STRING)')` : convertir la colonne `value` en chaîne de caractères. C'est théoriquement déjà le cas, mais l'expliciter limite les erreurs.
  - `select(from_json('value', schema).alias('json'))` : on applique notre schéma à la colonne `value`, et on appelle cette nouvelle colonne `json`.
  - `select('json.*')` : on récupère uniquement les données de la colonne `json`.

- ✅ Tester

  ````python
  iot_data_console = iot_data\
    .writeStream\
  	.format('console')\
  	.trigger(processingTime='5 seconds')\
  	.start()
  
  sleep(10)
  iot_data_console.stop() # copier aussi la ligne vide en-dessous!
  
  ````

  Ces commandes affichent dans la console le flux toutes les 5 secondes pendant 10 sec. (Comme précédemment, si le flux continue, c'est que vous n'avez pas tapé `Entrée` après la dernière instruction. Par ailleurs, si les données sont toujours illisibles, élargissez la console Python!)

- :sparkles: Il existe d'autres format d'output que la console pour les flux de données, comme les formats fichiers (`csv`, `json`, etc.), le format mémoire ou le format Kafka. Dans la console, les données ne peuvent pas être utilisées par d'autres processus, ce qui est un problème pour la création d'une vraie application. À la place, nous allons enregistrer nos données en mémoire, ce qui nous permet d'utiliser nos données plus tard.
  
  > **Remarque:** le format mémoire est utiliser ici par soucis de facilité. En pratique, il n'est utilisé que pour le déboggage. En effet, une telle façon de procéder n'est possible que tant que les données n'excèdent pas les capacités physiques de l'ordinateur, puisque les données doivent tenir en mémoire! Mais alors pourquoi utiliser Spark dans ce cas?

  ````python
  # La même chose mais ou on garde les données en mémoire pour les requêter plus tard.
  iot_data_memory = iot_data\
      .writeStream\
      .format("memory")\
      .queryName("iot_data")\
      .start()
  
  # La partie requêtage. On va afficher les donner toutes les secondes. Remarquez que le stream dans la requête sql est le nom de la requête données plus haut.
  for x in range(10):
      spark.sql("SELECT * FROM iot_data").show()
      sleep(1)
  
  
  iot_data_memory.stop()
  
  ````

  - `format("memory")` : on stocke les données en mémoire dans un DataSet
  - `queryName("iot_data")` : on donne un nom à la requête pour la réutiliser par la suite.

- :x: Compter le nombre de ligne avec des erreurs.

  Notre chaîne de traitement peut rencontrer des erreurs (caractères spéciaux ou autres problèmes de conversion...). Nous allons les compter le nombre de ligne avec une erreur, c'est-à-dire les variables qui ne sont pas renseignées à l'issu du traitement (`null` en SQL).

  ````python
  # On compte les input en erreur (tous les champs  sont null sauf arrival et creation time). On affiche directement le résultat en console
  errorCount = iot_data\
      .withColumn("error", expr("CASE WHEN Device IS NULL AND Index  IS NULL AND Model IS NULL AND User IS NULL AND gt IS NULL THEN TRUE ELSE FALSE END"))\
      .groupBy("error")\
      .count()\
      .writeStream\
      .format("console")\
      .outputMode("complete")\
      .start()
  
  sleep(10)
  errorCount.stop()
  ````

  - `withColumn(...)` : on crée une colonnes error à partir d'une requête SQL

  - `groupBy("error")` : on fait un groupe by sur la colonne error

  - `count()` : on compte le nombre de ligne groupées

  - `outputMode("complete")` : à chaque nouveau mini-batch on met à jour l'intégralité des données en mémoire. Cela est utile quand on s'attend à ce que les données évolue au fil du temps (comme lors d'un comptage). Il existe deux autres mode :

    - `"update"` : seule les lignes modifiées sont mises à jour. Cependant, la sortie choisie doit supporter les opération de mise à jour de ligne (ce qui n'est pas le cas de la mémoire car spark stocke l'objet comme un DataSet, et que les dataSets sont *immuables*). La console, par contre, peut utiliser le mode _update_.
    - `"append"` : on ajoute les résultats comme de nouvelles lignes ; les résultats précédents ne sont pas supprimés (comportement par défaut)

    Les choses se compliquent puisque certaines sorties autorisent certaines méthodes ou non en fonction des opérations effectuées. Avec le cas des méthodes d'aggrégation (compter, faire une moyenne par groupe, etc.) on a par exemple le tableau suivant[^12]:

    | Format  | Agrégation | Mode             |
    | ------- | ---------- | ---------------- |
    | Console | Oui        | update, complete |
    | Console | Non        | complete, append |
    | Memory  | Oui        | complete         |
    | Memory  | Non        | append, complete |
    
[^12]: Plus d'informations [dans la documentation spark](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#output-modes).

- :hocho: Filtrer les lignes avec erreur. Ici, on considèrera qu'une ligne doit être écartée si une des variables n'est pas renseignée.

  ````python
  iot_filtered = iot_data\
      .na.drop("any")
  ````

  - `na.drop("any")` : on filtre toutes les lignes qui on une valeur manquante (`null` en SQL) dans n'importe quelle colonne. Il aurait été possible de ne supprimer les observations avec _uniquement_ des valeurs manquantes avec `na.drop("all")` ou de spécifier un ensemble de colonnes à considérer dans l'opération de filtrage avec `na.drop("<any or all>", subset=["col1", "col2"])`.

- :ok: Tester que les erreurs sont bien filtrées
  
  A partir de maintenant nous utiliserons `iot_filtered` en entrée de tous nos traitements.

  ````python
  errorCount = iot_filtered \
      .withColumn("error", expr("CASE WHEN Device IS NULL AND Index  IS NULL AND Model IS NULL AND User IS NULL AND gt IS NULL THEN TRUE ELSE FALSE END"))\
      .groupBy("error")\
      .count()\
      .writeStream\
      .format("console")\
      .outputMode("complete")\
      .start()
     
  sleep(10)
  errorCount.stop()
  ````

  Remarquez que la seule différence avec le comptage précédent est les données en entrée.

- :runner: Compter le nombre de chaque activité

  ````python
  activityCounts = iot_filtered.groupBy("gt").count()
  
  activityCount_stream = activityCounts\
      .writeStream\
      .format("memory")\
      .outputMode("complete") \
      .queryName("activityCount_stream")\
      .trigger(processingTime='2 seconds')\
      .start()
  
  # Toutes les secondes pendant 10 secondes
  # Remarquez qu'une fois sur deux rien ne se passe. En effet
  # nous venons de spécifier une exécution toutes les 2 secondes
  # (processingTime='2 seconds' ci dessus).
  for x in range(10):
      spark.sql("SELECT * FROM activityCount_stream").show()
      sleep(1)
  
  activityCount_stream.stop()
  ````

  ````python
  # Le même conde avec une écriture dans la console et une format d'output update.
  activityCount_stream = activityCounts\
      .writeStream\
      .format("console")\
      .outputMode("update") \
      .trigger(processingTime='2 seconds')\
      .start()
      
  activityCount_stream.stop()
  ````

- :small_red_triangle_down: Filtrer et sélectionner certaines infos

  ````python
  only_stairs_activity = iot_filtered\
      .withColumn("is_stair_activity", expr("gt like '%stairs%'"))\
      .where("is_stair_activity")\
      .select("gt", "model", "arrival_time", "creation_time")\
      .writeStream\
      .queryName("only_stairs_activity")\
      .format("memory")\
      .start()
  
  for x in range(5):
      spark.sql("SELECT * FROM only_stairs_activity").show()
      sleep(1)
  
  only_stairs_activity.stop()
  ````

  - *withColumn("contains_stairs", expr("gt like '%stairs%'"))* : on crée un colonne stairs qui vaut TRUE si la colonne gt contient la chaîne de caractère "stairs" et FALSE sinon
  - *where("contains_stairs")* : on garde que les lignes aves stairs == TRUE
  - *select("gt", "model", "arrival_time", "creation_time")* : on garde que les colonnes gt, model, arrival_time et creation_time

- :bar_chart: Quelques stats ([pour plus d'info](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#handling-late-data-and-watermarking))

  ````python
  deviceMobileStats = iot_filtered\
      .select("x", "y", "z", "gt", "model")\
      .cube("gt", "model")\
      .avg()\
      .writeStream\
      .queryName("deviceMobileStats")\
      .format("memory")\
      .outputMode("complete")\
      .start()
  
  for x in range(10):
      spark.sql("SELECT * FROM deviceMobileStats").show()
      sleep(1)
  
  deviceMobileStats.stop()
  
  ````

  La fonction cube prend une liste de colonnes en entrée (ici `gt` et `model`) et va faire tous les croisements possibles de ces variables et calculer les statistiques demandées (ici la moyenne) sur toutes les autres dimensions. Dans le tableau en sortie vous allez voir des valeurs `null` pour `gt` et `model`. Cela signifie que les moyennes ont été calculées sans prendre en compte cette dimension.

- :hourglass: Utiliser les timestamps pour traiter les données en série temporelle ([pour plus d'info](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#handling-late-data-and-watermarking))

  - Conversion en timestamp

    ````python
    iot_filtered_withEventTime = iot_filtered.selectExpr(
        "*",
        "cast(cast(Creation_Time as double)/1000000000 as timestamp) as event_time"
    )
    ````

    Mais que se passes-t-il ici?

    ````python
    # DO NOT COPY ! THIS IS ONLY PEDAGOGICAL !
    
    # 1. creation_time est de type "double"
    creation_time_as_double = cast(Creation_Time as double)
    
    # 2. diviser par 10^9 pour avoir le temps en seconde
    # puis convertir au format "timestamp"
    cast(creation_time_as_double/1000000000 as timestamp)
    ````

  - On compte les évènements qui arrivent dans une fenêtre de 5 secondes. Sauf que comme un reçoit un flux de données le temps qui nous importe n'est pas le temps d'arrivé mais le temps de création de la données (ici `event_time`). En effet les données n'arrivent pas forcément dans leur ordre de création à cause du temps de transmission.

    ````python
    event_time = iot_filtered_withEventTime\
        .groupBy(window(col("event_time"), "5 seconds"))\
        .count()\
        .writeStream\
        .queryName("event_per_window")\
        .format("memory")\
        .outputMode("complete")\
        .start()
    
    for x in range(20):
        spark.sql("SELECT * FROM event_per_window").show(50,False)
        sleep(1)
    
    event_time.stop()
    
    ````

  - On compte les évènements qui arrivent dans une fenêtre de 10 secondes avec des fenêtres toutes les 5 secondes

    ![siding windows](https://spark.apache.org/docs/latest/img/structured-streaming-window.png)
    
    ````python
    event_sliding_windows = iot_filtered_withEventTime\
        .groupBy(window(col("event_time"), "10 seconds", "5 seconds"))\
        .count()\
        .writeStream\
        .queryName("event_per_window")\
        .format("memory")\
        .outputMode("complete")\
        .start()
    
    for x in range(20):
        spark.sql("SELECT * FROM event_per_window").show(50,False)
        sleep(1)
    
    event_sliding_windows.stop()
    
    ````

- :crossed_flags: Spark propose la possibilité de joindre un flux de données avec des données statiques

     ````python
     #Code pour charger un fichier csv
     userData = spark.read.format("csv")\
         .option("header", "true")\
         .option("sep", ";")\
         .option("inferSchema", "true")\
         .load("chemin/de/mon/fichier/données utilisateurs.csv")
     
     # On fait la jointure sur la colonne data, on ne souhaite pas avoir les colonnes "Arrival_Time", "Creation_Time", "Index", "x", "y", "z"
     streamWithUserData = iot_filtered\
         .drop("Arrival_Time", "Creation_Time", "Index", "x", "y", "z")\
         .join(userData, ["User"])\
         .writeStream\
         .queryName("streamWithUserData")\
         .format("memory")\
         .start()
     
     
     for x in range(10):
         spark.sql("SELECT * FROM streamWithUserData").show(50,False)
         sleep(1)
     
     streamWithUserData.stop()
     ````
     
     Une jointure avec une fonction agrégation
     
     ````python
     deviceMobileStatsUser = iot_filtered\
         .join(userData, ["User"])\
         .groupBy("User", "FirstName","LastName")\
    	.count()\
        .writeStream\
        .queryName("stat_user")\
        .format("memory")\
        .outputMode("complete")\
        .start()
     
     # Le code suivant donne le même résultat (mais le plan d'exécution est différent)
    deviceMobileStatsUser = iot_filtered\
    	.groupBy("User")\
        .count()\
        .join(userData, ["User"])\
        .writeStream\
        .queryName("stat_user")\
        .format("memory")\
        .outputMode("complete")\
        .start()
     
         
    for x in range(5):
    	spark.sql("SELECT * FROM stat_user").show(50,False)
    	sleep(1)
     
    deviceMobileStatsUser.stop()
    ````
    
     
<!--
- :crossed_swords: Il est également possible de faire des jointures entre streams ([pour plus d'info](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#stream-stream-joins))

     Pensez à lancer le server2 dans serveurs_python/serveur_iot_2

     ````python
     # Définition d'un nouveau stream
     tcp_stream2 = spark\
     	.readStream\
         .format("socket")\
         .option("host", "127.0.0.1")\
         .option("port", "10000")\
         .load()
     
     # Schema
     schema_iot_2 = StructType()\
         .add('Arrival_Time',LongType(),True)\
         .add('Creation_Time',LongType(),True)\
         .add('Device',StringType(),True)\
         .add('Index',LongType(),True)\
         .add('Model',StringType(),True)\
         .add('User',StringType(),True)\
         .add('bpm',ShortType(),True)\
     
     # Mise au format plus filtrage
     filtered_iot_2 = tcp_stream2.selectExpr('CAST(value AS STRING)')\
         .select(from_json('value', schema_iot_2).alias('json'))\
         .select('json.*')\
         .na.drop("any")
     
     # Jointure des deux flux selon la variable User
     join_iot = iot_filtered.join(filtered_iot_2, "User").writeStream\
         .format("console")\
         .trigger(processingTime='10 seconds')\
         .start()
         
     join_iot.stop()
     ````

     > :thinking: Si vous faite bien attention joindre un flux avec un flux et joindre un flux avec des données statiques se font de la même façon car Spark manipule des DataFrame dans les deux cas.

- :european_castle: Compter des mots de citations (Pour le fun)

     > :exclamation: On rentre dans les requêtes vraiment complexes donc ne passez pas beaucoup de temps sur cette partie

     Lancer le fichier server_kaamelott.py. Ce serveur envoie des citations de kaamelott aux clients qui s'y connectent (il communique sur l'host 127.0.0.1 et le port 10001). Voici un exemple de donnée qu'il envoie :
     
     ````js
{"character": "Karadoc", "quote": "Quand je pense à la chance que vous avez de faire partie d'un clan dirigé par des cerveaux du combat psychologique, qui se saignent... aux quatre parfums du matin au soir ! !"}
     ````

     Et voici la requête pour obtenir le nombre de mot reçus par personnage
     
     ````python
     #Connextion au stream
     kaamelott_stream = spark.readStream.format("socket").option("host", "127.0.0.1").option("port", "10001").load()
     
     #Schéma
     schema_kaamelott = StructType()\
         .add('character',StringType(),True)\
         .add('quote',StringType(),True)\
     
     #Application du schéma
     kaamelott_df = kaamelott_stream.selectExpr('CAST(value AS STRING)')\
         .select(from_json('value', schema_kaamelott).alias('json'))\
         .select('json.*')
     
     # Le comptage de mots
     # explode/split -> créent plusieurs lignes à partir d'une ligne (ici on coupe les mots avec split et on fait une ligne par mot de la citation)
     # groupBy/count : on compte
     words = kaamelott_df.select(kaamelott_df.character,
         explode(
             split(kaamelott_df.quote, ' ')
            ).alias('word')
          )\
         .groupBy(kaamelott_df.character)\
         .count()\
         .writeStream\
         .format("console")\
         .outputMode("complete")\
         .trigger(processingTime='5 seconds')\
    .start()
    ````
    
-->

## À vous de jouer!

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
4. En raison d'un risque élévé de pillage des pages suite à un événement majeur en Haute-Garonne, Wikimédia souhaite mettre en place un suivi des modifications des pages Wikipédia sur ce département. Le fichier `hte-garonne.csv` contient la liste des communes de Haute-Garonne (`communeLabel`), ainsi que le nom de la page Wikipédia correspondante (`articleName`) telle que figurant sur la base de données Wikidata[^3]. Combien de modifications ont été effectuées sur l'une de ces pages depuis le début de l'abonnement?

**Vous rendrez votre code au format `.py` sous Moodle.**

[^3]: La requête pour obtenir ces données depuis `https://query.wikidata.org` est la suivante:

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

## Pour plus d'information :

- [La doc spark officielle](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#input-sources)
- ZAHARIA, B. C. M. (2018). *Spark: the Definitive Guide*. , O'Reilly Media, Inc. https://proquest.safaribooksonline.com/9781491912201
- https://databricks.com/blog/2018/03/13/introducing-stream-stream-joins-in-apache-spark-2-3.html
- https://databricks.com/blog/2016/07/28/structured-streaming-in-apache-spark.html
- https://databricks.com/blog/2015/07/30/diving-into-apache-spark-streamings-execution-model.html