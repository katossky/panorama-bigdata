# TP4 Big Data : Traiter des flux de données avec Spark

## 0. Mise en place

Pour ce dernier TP, vous allez utiliser Spark en local sur **votre VM ensai**. Vous trouverez sur Moodle une archive TP4 qui contient l'intégralité des fichiers utiles pour le TP. Téléchargez et décompressez la. Vous allez obtenir 3 dossiers

- `server-python`,  qui contient les codes qui vont créer des flux de données
- `spark`, qui contient les fichiers nécessaires à faire fonctionner spark en local
- `data`, qui va contenir des données utilisées au cours du TP

Pour lancer spark 

````shell
%SPARK_HOME%/bin/pyspark --master local[4]
````

* %SPARK_HOME%/bin/pyspark : on exécute le fichier pyspark
* --master local[4] : on spécifie l'adresse du master. "local" signifie que l'on va créer un cluster local et  [4] qu'on va demander 4 threads. Pour se connecter à une cluster existant il suffirait de remplacer local[4] par l'adresse IP du master du cluster

> :coffee: Aide pyspark en console :
>
> - Pour coller utilisez maj+insert
> - Pour vider la console ctrl+l

## 1. Spark et les flux de données

En 2012, Spark Streaming est l'API DStreams est ajouté à Spark, et rend possible le traitement de flux de données avec des fonctions hauts niveaux (comme map et reduce). En 2016 une nouvelle API est ajoutée, Structured Streaming, qui se base sur les DataFrames Spark. À partir de là, un flux de données peut se manipuler comme un data frame classique. C'est l'API que nous allons utiliser pour ce TP. Vous allez voir les codes présentaient sont très proche de code pour traiter des données statiques.

![data stream](https://databricks.com/wp-content/uploads/2016/07/image01-1.png)

Pour rappel, traiter des données en flux consiste à les traiter au fil de l'eau. Quand une données (ou un groupe) est disponible il est traité, donc le traitement n'a pas réellement de fin, et il va produire plusieurs versions des données. Par exemple si vous comptez le nombre de tweets produit par heure avec un système de stream, tant qu'une heure n'est pas terminée vous allez avoir un nombre de tweets produit pour l'heure en cours qui augmente. Pire que ça, on peut partir du principe que certaines données vont arriver en retard, et peut-être que vous allez devoir mettre à jour une données passées. Voici quelques cas d'utilisation de traitement de flux de données :

- Alerte et notification : par exemple la détection de fraude bancaire en temps réel, détecter une surcharge dans un réseau électrique grâce à des compteurs intelligents, détecter l'état de santé d'une personne  qui se dégrade grâce aux données de sa montre connectée.
- Rapport en temp réel : nombre d'utilisateur par minute d'un site, portée d'une nouvelle campagne de publicité, gestion automatique d'un portefeuille d'actions
- ELT (extract transform load) incrémental : des données non structurées arrivent en permanence et il faut les traiter (filtrer, mettre en forme) avant de les intégrer dans le système d'information de l'entreprise
- Online machine learning : des données sont transmises en permanence à un algorithme de machine learning pour ce mettre à jour dynamiquement.

Si traiter des données en flux à des avantages, il a aussi avec un lot de défis. En effet comme le traitement n'a pas de fin, si on stocke les données infiniment un problème de mémoire va arriver. De même traiter un évènement spécifique est simple, mais comment traiter une chaîne d'évènement ? Par exemple déclencher une alerte si on reçoit les valeurs 5, puis 6, puis 3 à la suite. Dans un traitement classique il suffit ordonner temporellement les données, mais en flux à cause de la latence dans les transfert il est possible de recevoir un 3 puis un 5 et enfin le 6 alors que l'ordre d'envoi était 5, 6 et 3. Ces problèmes sont résolues dans Spark, mais il faut garder en tête que traiter un flux n'est pas aussi simple que traiter des données en batch. 

Spark offre deux manière de traiter un flux de données, enregistrement par enregistrement (*one record at a time*) ou par ensemble d'enregistrements arrivés dans une fenêtre de temps (*micro batching*). Le *one record at a time* assure une latence faible entre l'arrivé d'un enregistrement et son traitement, mais le débit maximal est souvent faible. En d'autres terme, tant que la quantité de données est assez faible elles sont traiter en temps réel, mais si trop de données arrivent le système sera incapable de les gérer et le temps réel sera perdu. Le *micro batch*ing  quant à lui attend un temps t avant de traiter les données, ce qui fait qu'au pire une donnée devra attendre t avant d'être traitée. Le débit de ces systèmes est beaucoup plus grand c'est pourquoi il est préféré.

> Pour avoir le meilleur arbitrage latence/débit le mieux à faire est de diminuer la taille des micro batch jusqu'à arrivé jusqu'au moment où traiter un micro batch prend plus temps que le générer. À partir de là, remontez la taille des micro batch et vous serez à un point "optimal" entre débit et latence.

## 2. Traiter des données depuis un flux TCP

Dans cette partie du TP vous allez traiter des données type IoT (*Internet of Things*).  Imaginez qu'elle proviennent de montres connectées qui vont vous fournir diverses données sur des utilisateurs. Voici un exemple de données que vous pouvez récupérer :

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

Bien sûr ces données sont générées aléatoirement et ne proviennent pas de vraies montres.

- :computer: Exécuter le fichier server1.py. 

  Pour cela allez dans le dossier server_python\serveur_iot_1puis taper "cmd" dans la barre d'adresse. Cela vous ouvrira l'invite de commande windows. Puis faites

  ````shell
  python server1.py
  ````

  Garde ce terminal toujours ouvert.

  Ce script python va envoyer des données sur le port 9999 de votre ordinateur. Même si les données sont générées sur votre ordinateur, Spark va s'y connecter comme si elles étaient produite par un service distant.

- :sparkles: Exécuter pyspark si ce n'est pas déjà fait

  ````shell
  %SPARK_HOME%/bin/pyspark --master local[4] 
  ````

- :construction: Fixer le nombre de partition lors de la phase de shuffle à 5 pour spark SQL. Sans cela, Spark va générer 200 partitions pour vos données et ralentir fortement les traitements en local. (Pour ceux qui veulent se rafraichir les idées sur la phase de _shuffle_ dans Spark, voir par exemple [ici](https://www.quora.com/What-is-a-Shuffle-operation-in-Spark)).


  > :thinking: La phase de shuffle consiste à mélanger les données selon leur clef et recréer des partition après chaque traitement. Cela permet, théoriquement, d'avoir un nombre de données similaire dans toutes les partitions et d'éviter un déséquilibre dans les tailles. Nous allons manipuler tellement peu de données que 200 partitions est beaucoup trop et va ralentir les trainements.

  ````
  spark.conf.set("spark.sql.shuffle.partitions", 5)
  ````

- :package: Importer les fonctions nécessaires pour la suite du TP

  ````python
  from time import sleep
  from pyspark.sql.functions import from_json, window, col, expr
  from pyspark.sql.types import StructType, StringType, LongType, DoubleType, ShortType
  ````

- :signal_strength: Ouvrir le flux TCP ([pour plus d'info sur les sources possibles](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#input-sources))

  ````python
  tcp_stream = spark\
  	.readStream\
      .format("socket")\
      .option("host", "127.0.0.1")\
      .option("port", "9999")\
      .load()
  ````

  - *format("socket")* : spécifie que le flux proviendra d'une socket TCP (pour faire très simple on récupéré des données produites par un serveur). Ce format de fichier est déconseillé pour des applications _en production_[^1] car toute données perdues le sera définitivement. Il n'est pas possible de en cas de redémarrage suite à une erreur de demander les messages des X dernières  minutes. _Une façon plus sûre de transmettre un flux de donnée serait d'ajouter des fichiers continuellement dans un dossier (dans ce cas la Spark ne se connecte pas à internet) ou d'utiliser un service dédié comme Kafka ([plus d'info](https://kafka.apache.org/))._
  - *option("host", "127.0.0.1")* : votre ordinateur, vu depuis votre ordinateur, possède l'adresse IP `127.0.0.1`. _Pour se connecter à une source distante, il suffirait de remplacer cette adresse IP par celle de la source._
  - *option("port", "9999")*  : la source utilise le port 9999. _Ce choix est purement conventionnel mais (1) il doit être le même pour l'émetteur et le récepteur et (2) il est déconseillé d'utiliser des ports "connus" (comme les ports 20 et 21 utilisé pour les transferts de fichier FTP, 80 et 443 pour HTTP et HTTPS respectivement, etc. — voir [ici](https://fr.wikipedia.org/wiki/Liste_de_ports_logiciels) pour une liste exhaustive) pour éviter tout usage conflictuel du même port._
  - *load()* : on ouvre le flux
  
[^1]: En production = en utilisation permanente, active. La production s'oppose au développement (la phase de construction d'un programme ou d'une application.)

  > :thinking: Ce code ne va rien faire car n'oubliez pas car Spark est paresseux (_lazy evaluation_): comme on n'utilise pas la source de données il ne s'y connecte pas.

- :printer: Afficher quelques données

  ````python
  raw_data_console = tcp_stream\
  	.writeStream\
      .format('console')\
      .option('truncate', 'false')\
      .trigger(processingTime='3 seconds')\
      .start()
  
  spark.streams.active #Voir la liste des streams en cours (c'est assez moche)
      
  sleep(10) # on attend 10 seconde pour voir la console évoluer
  raw_data_console.stop() # on ferme le stream. Si le stream continue après 10 secondes, c'est que vous n'avez pas validé la commande alors faite un "entrée"
  
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

  Voilà la sortie que vous devez obtenir (en moins claire) :

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

  Autrement dit, les données ne sont pas correctement lues. Chaque ligne est lue comme une seule grande chaîne de caractères. Pour bien les traiter, nous devons appliquer le bon "schéma".

- :arrow_forward: Définir le schéma de nos données

  ````python
  schema = StructType()\
      .add('Arrival_Time',LongType(),True)\
      .add('Creation_Time',LongType(),True)\
      .add('Device',StringType(),True)\
      .add('Index',LongType(),True)\
      .add('Model',StringType(),True)\
      .add('User',StringType(),True)\
      .add('gt',StringType(),True)\
      .add('x',DoubleType(),True)\
      .add('y',DoubleType(),True)\
      .add('z',DoubleType(),True)
  ````

  Comme les données proviennent d'un flux on ne peut pas inférer le schéma, donc on le définit à la main. Le True à la fin de chaque ligne spécifie que l'on accepte les valeurs null (plus de détails [dans la documentation](https://spark.apache.org/docs/2.3.0/api/python/pyspark.sql.html#pyspark.sql.types.StructType)).

- :point_down: Appliquer le schéma

  ````python
  iot_data = tcp_stream.selectExpr('CAST(value AS STRING)')\
      .select(from_json('value', schema).alias('json'))\
      .select('json.*')
  ````

  Pour appliquer le schéma on va appliquer une transformation à nos données.

  - `selectExpr('CAST(value AS STRING)')` : convertir la colonne value en chaîne de caractères. C'est théoriquement déjà le cas, mais l'expliciter limite les erreurs.
  - `select(from_json('value', schema).alias('json'))` : on applique notre schéma à la colonne `value`, et on appelle cette nouvelle colonne `json`.
  - `select('json.*')` : on récupère uniquement les données de la colonne `json`.

- ✅ Tester

  ````python
  iot_data_console = iot_data.writeStream\
  	.format('console')\
  	.trigger(processingTime='5 seconds')\
  	.start()
  
  sleep(10)
  iot_data_console.stop() # copier aussi la ligne vide en-dessous!
  
  ````

  Ces commandes affichent dans la console le flux toutes les 5 secondes pendant 10 sec. (Comme précédemment, si le flux continue, c'est que vous n'avez pas tapé `Entrée` après la dernière instruction. Par ailleurs, si les données sont toujours illisibles, élargissez la console Python!)

  > :sparkles: Il existe d'autres format d'output que la console pour les flux de données, comme les formats fichiers (`csv`, `json`, etc.), le format mémoire ou le format Kafka. Dans la console, les données ne peuvent pas être utilisées par d'autres processus, ce qui est un problème pour la création d'une vraie application. À la place, nous allons enregistrer nos données en mémoire, ce qui nous permet d'utiliser nos données plus tard.
  > 
  > **Remarque:** le format mémoire est utiliser ici par soucis de facilité. En pratique, il n'est utilisé que pour le déboggage. En effet, une telle façon de procéder n'est possible que tant que les données n'excèdent pas les capacités physiques de l'ordinateur, puisque les données doivent tenir en mémoire! Mais alors pourquoi utiliser Spark dans ce cas?

  ````python
  # La même chose mais ou on garde les données en mémoire pour les requêter plus tard.
  iot_data_memory = iot_data.writeStream\
      .format("memory")\
      .queryName("iot_data")\
      .start()
  
  # La partie requêtage. On va afficher les donner toutes les secondes. Remarquez que le stream dans la requête sql est le nom de la requête données plus haut.
  for x in range(10):
      spark.sql("SELECT * FROM iot_data").show()
      sleep(1)
  
  
  iot_data_memory.stop()
  
  ````

  - *format("memory"*) : on stocke les données en mémoire
  - *queryName("stream")* : on donne un nom à la requête pour la réutiliser par la suite.

- :x: Compter le nombre de ligne en erreur.

  Notre source de données peut rencontrer des erreurs, et envoyer des données malgré une erreur dans le création. Nous allons les compter le nombre de ligne en erreur.

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

  - *withColumn(...)* : on crée une colonnes error à partir d'une requête SQL

  - *groupBy("error")* : on fait un groupe by sur la colonne error

  - *count()* : on compte le nombre de ligne groupées

  - *outputMode("complete")* : à chaque étape on met à jour intégralité des données en mémoire. Cela est utile quand on s'attend à ce que les données évolues au file du temps (comme lors d'un comptage). Il existe deux autres mode :

    - update : seule les lignes modifiées sont mises à jour. Mais la sortie doit supporter les opération de mise à jour de ligne (ce qui n'est pas le cas de la mémoire car spark stocke l'objet comme un dataset, et que les dataset ne peuvent pas être mise à jour, on peut seulement ajouter des lignes). La console par contre peut utiliser le mode update.
    - append : on ajoute les données au fur et à mesure à la sortie. Cela assure que les données sont traitées une seule fois (comportement par défaut)

    Vous trouverais plus d'informations ici : [documentation spark](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#output-modes). Dans votre cas très précis, vous pouvez vous limiter à ce tableau : 

    | Format  | Agrégation | Mode             |
    | ------- | ---------- | ---------------- |
    | Console | Oui        | update, complete |
    | Console | Non        | complete, append |
    | Memory  | Oui        | complete         |
    | Memory  | Non        | append, complete |

- :hocho: Filtrer les lignes avec erreur. Ici, on considèrera qu'une ligne doit être écartée si une des variables n'est pas renseignée.

  ````python
  iot_filtered = iot_data\
      .na.drop("any")
  ````

  - na.drop("any") : on filtre toutes les lignes qui on une valeur manquante (`null` en SQL) dans n'importe quelle colonne. Cela peut par exemple résultater d'une erreur de conversion. Il aurait été possible de ne supprimer les observations avec _uniquement_ des valeurs manquantes (`na.drop("all")`) ou de spécifier un ensemble de colonnes à considérer dans l'opération de filtrage (`na.drop("<any or all>", subset=["col1", "col2"])`.

  - A partir de maintenant nous utiliserons `filterDf` en entrée de tous nos traitements.

- :ok:Tester que les erreurs sont bien filtrées

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
  filterdDf_test.stop()
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
  # Remarquez que rien ne se passe, une fois sur deux. En effet
  # nous venons de spécifier une exécution toutes les 2 secondes
  # (processingTime='2 seconds' ci dessus).
  for x in range(10):
      spark.sql("SELECT * FROM activityCount_stream").show()
      sleep(1)
  
  
  ````

  - *format("memory")* : on écrit le résultat en mémoire

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

  > :thinking: Vous allez normalement voir apparaitre une ligne avec comme activité "null". Cela provient du fait que cette activité a pour nom la chaîne de caractère "null" et pas la valeur null

- :small_red_triangle_down: Filtrer et sélectionner certaines infos

  ````python
  simpleTransformAndFilter = filterdDf.withColumn("is_stair_activity", expr("gt like '%stairs%'"))\
      .where("is_stair_activity")\
      .select("gt", "model", "arrival_time", "creation_time")\
      .writeStream\
      .queryName("simple_transform")\
      .format("memory")\
      .start()
  
  for x in range(5):
      spark.sql("SELECT * FROM simple_transform").show()
      sleep(1)
  
  simpleTransformAndFilter.stop()
  ````

  - *withColumn("contains_stairs", expr("gt like '%stairs%'"))* : on crée un colonne stairs qui vaut TRUE si la colonne gt contient la chaîne de caractère "stairs" et FALSE sinon
  - *where("contains_stairs")* : on garde que les lignes aves stairs == TRUE
  - *select("gt", "model", "arrival_time", "creation_time")* : on garde que les colonnes gt, model, arrival_time et creation_time

- :bar_chart: Quelques stats ([pour plus d'info](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#handling-late-data-and-watermarking))

  ````python
  deviceMobileStats = filterdDf\
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
    withEventTime = filterdDf.selectExpr(
        "*",
        "cast(cast(Creation_Time as double)/1000000000 as timestamp) as event_time"
    )
    ````

    Zoom sur le double cast 

    ````
    cast(
    	cast(
    		Creation_Time as double <- on dit spécifiquement que Creation_time est un double
    	)/1000000000 as timestamp <- on le divice par 10^9 pour avoir le temps en seconde et ensuite on dit que c'est un timestamp
    ) as event_time
    ````

    

  - On compte les évènements qui arrivent dans une fenêtre de 5 secondes. Sauf que comme un reçoit un flux de données le temps qui nous importe n'est pas le temps d'arrivé mais le temps de création de la données (ici event_time). En effet les données n'arrivent pas forcément dans leur ordre de création à cause du temps de transmission.

    

    ````python
    event_time = withEventTime.groupBy(window(col("event_time"), "5 seconds")).count()\
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
    sliding_windows = withEventTime.groupBy(window(col("event_time"), "10 seconds", "5 seconds")).count()\
        .writeStream\
        .queryName("event_per_window")\
        .format("memory")\
        .outputMode("complete")\
        .start()
    
    for x in range(20):
        spark.sql("SELECT * FROM event_per_window").show(50,False)
        sleep(1)
    
    sliding_windows.stop()
    
    ````

- :crossed_flags: Spark propose la possibilité de joindre un flux de données avec des données statiques

     ````python
     #Code pour charger un fichier csv
     userData = spark.read.format("csv")\
         .option("header", "true")\
         .option("sep", ";")\
         .option("inferSchema", "true")\
         .load("chemain/de/mon/fichier/données utilisateurs.csv")
     
     # On fait la jointure sur la colonne data, on ne souhaite pas avoir les colonnes "Arrival_Time", "Creation_Time", "Index", "x", "y", "z"
     streamWithUserData = filterdDf\
         .drop("Arrival_Time", "Creation_Time", "Index", "x", "y", "z")\
         .join(userData, ["User"])\
         .writeStream\
         .queryName("streamWithUserData")\
         .format("memory")\
         .start()
     
     
     for x in range(20):
         spark.sql("SELECT * FROM streamWithUserData").show(50,False)
         sleep(1)
     
     streamWithUserData.stop()
     ````
     
     Une jointure avec une fonction agrégation
     
     ````python
     deviceMobileStatsUser = filterdDf\
         .join(userData, ["User"])\
         .groupBy("User", "FirstName","LastName")\
    .count()\
         .writeStream\
         .queryName("stat_user")\
         .format("memory")\
         .outputMode("complete")\
         .start()
     
     # Le code suivant donne le même résultat (mais le plan d'exécution est différent)
     deviceMobileStatsUser = filterdDf\
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
    
     
    
- :crossed_swords: Il est également de faire des jointures entre streams ([pour plus d'info](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#stream-stream-joins))

     ````python
     # Définition d'un nouveau stream
     tcp_stream2 = spark\
     	.readStream\
         .format("socket")\
         .option("host", "127.0.0.1")\
         .option("port", "10000")\
         .load()
     
     # Schema
     schema2 = StructType()\
         .add('Arrival_Time',LongType(),True)\
         .add('Creation_Time',LongType(),True)\
         .add('Device',StringType(),True)\
         .add('Index',LongType(),True)\
         .add('Model',StringType(),True)\
         .add('User',StringType(),True)\
         .add('bpm',ShortType(),True)\
     
     # Mise au format plus filtrage
     df2 = tcp_stream2.selectExpr('CAST(value AS STRING)')\
         .select(from_json('value', schema2).alias('json'))\
         .select('json.*')\
         .na.drop("any")
     
     # Jointure des deux flux selon la variable User
     join = filterdDf.join(df2, "User").writeStream\
         .format("console")\
         .trigger(processingTime='10 seconds')\
         .start()
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
     
     

## Pour plus d'information :

- [La doc spark officielle](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#input-sources)
- ZAHARIA, B. C. M. (2018). *Spark: the Definitive Guide*. , O'Reilly Media, Inc. https://proquest.safaribooksonline.com/9781491912201
- https://databricks.com/blog/2018/03/13/introducing-stream-stream-joins-in-apache-spark-2-3.html
- https://databricks.com/blog/2016/07/28/structured-streaming-in-apache-spark.html
- https://databricks.com/blog/2015/07/30/diving-into-apache-spark-streamings-execution-model.html