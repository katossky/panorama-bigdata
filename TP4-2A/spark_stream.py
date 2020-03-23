# %SPARK_HOME%/bin/pyspark --master local[4]  --driver-memory 2g
"""
PARTIE STREAM FROM TCP SOCKET

Pour tester l'utilisation d'un stream à partir d'un socket TCP, lancer le fichier
server.py disponible sur moodle

"""



# Par défaut quand on fait du SQL spark stocke les objets dans 200 partitions ... Comme on a
# peu de données cela va ralentir les traitements. On va fixer à 5 le nombre de partition pour
# aller plus vite (si vous voulez voir la différence, faites le teste sans ;) 
spark.conf.set("spark.sql.shuffle.partitions", 5)

from time import sleep
from pyspark.sql.functions import from_json
from pyspark.sql.types import StructType, StringType, LongType, DoubleType

# On écoute sur le port 9999 de localhost
tcp_stream = spark.readStream.format("socket").option("host", "localhost").option("port", "9999").load()

# Mais théoriquement on devrait le créer à la main
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

# En effet quand on stream, spark ne peut pas inférer le schéma, donc l'étape de spécification est obligatoire.
# Sans le champ est un simple string

# On applique le schéma
df = tcp_stream.selectExpr('CAST(value AS STRING)')\
    .select(from_json('value', schema).alias('json'))\
    .select('json.*')

# Test pour voir si tout s'affiche en console
raw_data_console = df.writeStream.format('console').start()

sleep(10)
raw_data_console.stop()

# La même chose mais ou on garde les données en mémoire pour les requêter plus tard
raw_data_memory = df.writeStream|\
    .queryName("stream")\
    .format("memory")\
    .outputMode("complete")\
    .start()

# La partie requêtage; On va afficher les donner toutes les secondes
for x in range(10):
    spark.sql("SELECT * FROM stream").show()
    sleep(1)


raw_data_memory.stop()


# On va compter copter combient chaque activité arrive. On va prendre 2 seconde de flux de données à chaque fois
activityCounts = df.groupBy("gt").count()

activityQuery = activityCounts\
    .writeStream\
    .outputMode("complete") \
    .format("console")\
    .trigger(processingTime='2 seconds')\
    .start()

# On attend 6 sec
sleep(6)

activityQuery.stop()


# On va filtrer les lignes qui ne contiennent "stairs", et on récupère gt, model, arrival_time et createion_time
from pyspark.sql.functions import expr
simpleTransform = df.withColumn("stairs", expr("gt like '%stairs%'"))\
    .where("stairs")\
    .where("gt is not null")\
    .select("gt", "model", "arrival_time", "creation_time")\
    .writeStream\
    .queryName("simple_transform")\
    .format("memory")\
    .outputMode("append")\
    .start()

for x in range(5):
    spark.sql("SELECT * FROM simple_transform").show()
    sleep(1)

simpleTransform.stop()

