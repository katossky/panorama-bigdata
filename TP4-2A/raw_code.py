pip install -r requirements.txt --user --proxy http://pxcache-02.ensai.fr:3128
python serveur_iot_1\server1.py
%SPARK_HOME%/bin/pyspark --master local[4]
spark.conf.set("spark.sql.shuffle.partitions", 5)
from time import sleep
from pyspark.sql.functions import from_json, window, col, expr, explode, split
from pyspark.sql.types import StructType, StringType, LongType, DoubleType, ShortType

#Ouvrir un flux
tcp_stream = spark\
	.readStream\
    .format("socket")\
    .option("host", "127.0.0.1")\
    .option("port", "9999")\
    .load()

#Afficher quelques données
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

# Définir un schéma
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

# Appliquer le schéma
iot_data = tcp_stream.selectExpr('CAST(value AS STRING)')\
    .select(from_json('value', schema_iot).alias('json'))\
    .select('json.*')

# Tester et afficher des données
iot_data_console = iot_data\
  .writeStream\
	.format('console')\
	.trigger(processingTime='5 seconds')\
	.start()

sleep(10)
iot_data_console.stop() # copier aussi la ligne vide en-dessous!

#D'autres format d'output
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

#Compter ligne en erreur
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

#Filtrer ligne en erreur
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

#Compter chaque evenement d'une activité
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

# Le même conde avec une écriture dans la console et une format d'output update.
activityCount_stream = activityCounts\
    .writeStream\
    .format("console")\
    .outputMode("update") \
    .trigger(processingTime='2 seconds')\
    .start()
    
activityCount_stream.stop()

#Filtrer et sélectionner certaines infos
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

# Des stats
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

#Convert en timestamp
iot_filtered_withEventTime = iot_filtered.selectExpr(
    "*",
    "cast(cast(Creation_Time as double)/1000000000 as timestamp) as event_time"
)

# On compte le nb d'event toutes les 5 sec
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

#Fenetre glissante
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


#Jointure
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

# Jointure et agrégation
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

##EXPERT MODE
# jointure entre stream

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

#Compter des mots
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
