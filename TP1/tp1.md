# TP1 Apache Spark

<!-- NOTION À ABORDER -->
<!-- exécution sur quel processeur / noeud -->
<!-- montrer la duplication -->
<!-- montrer le choix de lieu de stockage -->
<!-- les différentes possibilités -->
<!-- temps d'exécution -->


## 1. Introduction

Spark (https://spark.apache.org , [Wikipedia](https://en.wikipedia.org/wiki/Apache_Spark)) is a popular, open-source framework for cluster-computing designed for data science. Programmed mostly in Scala, it can be used interactively natively from the command line interface[^1] in Scala (`spark-shell`), Python (`pyspark`) and R (`sparkR`). It is also possible to build applications using Scala or Java (which is not available at the console), for instance building an additional interface to Spark from R with `sparklyR`.

Spark actually runs independantly of any of these programs: it is essentially a task-manager (or job manager) built on top of a resource manager (such as YARN) and a distributed file system (such as HDFS). It runs in the background no matter what happens until we explicitly ask it to shut down. (When we do so, all the data is lost!) Each of the programs communicating with the same Spark-managed cluster are called _clients_. Today, we will be using three such clients: `sparkR` (very briefly), `pyspark` and `sparklyr`.

[^1] "(Bash) command line interface" (or CLI) (**FR:** _interface en ligne de commande Bash_), "(Bash) console" (**FR:** _console_), "(Bash) command prompt" (**FR:** _invite de commande Bash_), "(Bash) terminal" (**FR:** _terminal *Bash*_), "(Unix / Bash) shell" (**FR:** _*shell* Unix / Bash_) ... are common names for the texte-based interface with the computer that is available for Unix computers, such as thoses under MacOS or Linux operating systems. All of these expressions (except the "Bash/Unix" parts) can more broadly be used to designate any command line interface, such as R's. In such interfaces, the computer let the user know it is ready to interact thanks to a dedicated series of characters — `>` in R and `$` in Unix shell. This is called the **prompt**. The user can then type a **command**. Simple Bash commands include `ls` (= list) for listing the content a folder, or `mkdir` (= make directory) for creating a folder. One can open the CLI of R, Python and Scala directly from the Bash console by running respectively `R`, `python`/`python3` and `scala` (and quit it to return to the console with respectively `q()`, `quit()` or `:q`).

**Q 1.1** Describe what's the role of each of a cluster's components.

**Task manager or job manager:**
**Resource manager:**
**Distributed file system:**
**Client:**

## 2. Setup

### a. Launching a cluster on AWS

<!--

--------- LOCAL HADOOP MODE -------------------

https://medium.com/@jayden.chua/installing-hadoop-on-macos-a334ab45bb3

1. enable ssh connection to localhost

brew install pdsh

ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa_spark
cat ~/.ssh/id_rsa_spark.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

sudo systemsetup -setremotelogin on # authorize ssh connection to localhost

ssh localhost # now works

2. install hadoop

brew install hadoop

# files to modify

hadoop-env.sh
yarn-site.xml
hdfs-site.xml
core-site.xml

3. launch sdfs and yarn

cd /usr/local/Cellar/hadoop/3.2.1/libexec
sbin/start-dfs.sh 
sbin/start-yarn.sh

4. Check everything is working

jps # Java Virtual Machine Process Status

--------- STAND ALONE MODE -----------------------
brew install apache-spark
/usr/local/Cellar/apache-spark/2.4.3/libexec/sbin/start-master.sh
/usr/local/Cellar/apache-spark/2.4.3/libexec/sbin/start-slave.sh spark://$HOSTNAME:7077

-->

### b. Launching Python with `pyspark` on a distinct (distant) node

<!-- 
Locally on Arthur's MacOS, the default Python version is 2.7.17.
I have to `export PYSPARK_PYTHON=python3` before launching Python to get version 3.7.4.

--------- LOCAL HADOOP MODE -------------------
export PYSPARK_PYTHON=python3
export HADOOP_CONF_DIR=/usr/local/Cellar/hadoop/3.2.1/libexec/etc/hadoop
pyspark --master yarn --deploy-mode client

--------- STAND ALONE MODE -----------------------
export PYSPARK_PYTHON=python3
pyspark --master spark://$HOSTNAME:7077 --total-executor-cores 1



-->

```python

```

The **documentation** is available here: https://spark.rstudio.com.

### c. Launching R with `SparkR` on Spark's master node

```r
iris_distant <- createDataFrame(iris)
```

<!-- 
Locally on Arthur's MacOS, the default Python version is 2.7.17.
I have to `export PYSPARK_PYTHON=python3` before launching Python to get version 3.7.4.

sparkR --master spark://$HOSTNAME:7077 --total-executor-cores 1
-->


**Note:** `sparkR` (with a small `s`) is the name of the bash command launching R with the `SparkR` library (with a big `S`) already loaded.

The **documentation** is available here: https://spark.apache.org/docs/latest/sparkr.html.

### d. Launching R with `sparklyr` locally

On your own computer, open RStudio.
Install and load the libraries `dplyr` and `sparklyr`.
Open a connection to Spark with the `spark_connect` function.
Load a data set to the cluster using the `copy_to` function.

```r
install.package(c("dplyr", "sparklyr"))
load(dplyr, sparklyr)
sc <- spark_connect(....................)
# master <- str_c("spark://", system("hostname", intern=TRUE), ":7077")
# sc <- spark_connect(master=master, version="2.4.3", spark_home="/usr/local/Cellar/apache-spark/2.4.3/libexec")
iris_distant <- iris %>% copy_to(sc, .)
```

**Q 2.1** `%>%` is called the pipe operator and is shipped with the `dplyr` package. It basically transforms a series of nested function calls `f1("a", f2(f3(f4(x, param=1), variable)), param="b")` into the easier-to-follow: `x %>% f4(param=1) %>% f3(variable) %>% f2() %>% f1("a", ., param="b")`.

Rewrite `iris %>% copy_to(sc, .)` in its base-R equivalent.

The **documentation** for `sparklyr` is available [here](https://spark.rstudio.com) and a **cheat-sheet** [here](https://github.com/rstudio/cheatsheets/raw/master/sparklyr.pdf).
The **documentation** for `dplyr` is available [here](https://dplyr.tidyverse.org) and a **cheat-sheet** [here](https://github.com/rstudio/cheatsheets/raw/master/data-transformation.pdf).

### e. Checks

Check that the tasks / jobs have correctly been received and executed by Spark on the Spark web user interface.

**Q 2.2** Where can you find the identifiers of the job submitters (also called applications or clients) ?

Check that the datasets are correctly created on the HDFS web user interface.

**Q 2.3** Where can we find how much ressources from AWS we have used so far? How much did it cost us?

## 3. Basic usage and concepts

|                             | sparklyr           | sparkR                | pyspark | scala |
|-----------------------------|--------------------| ----------------------|---------|-------|
| Upload the `df` dataset     | `copy_to(df, sc)`  | `createDataFrame(df)` |
| Download the `df` dataset   | `collect(df)`      | `collect(df)`         | `df.collect()` |
| List existing datasets      | `src_tbls(sc)`     | listTables()        |
| Link to an existing dataset | 
|

**Q 3.1** From `R/sparklyr`, upload the native `faithful` dataset[^2] to the cluster. Retrieve this dataset from `pyspark` and from `R/sparkR` under the name `faithfull_distant`.

[^2]: The `faithful` dataset records the length of eruptions and the waiting time between eruptions of the _Old Faithful_ geyser in the Yosemite National Park ([Wikipedia](https://en.wikipedia.org/wiki/Old_Faithful)).

**Q 3.2** What happens when you try to evaluate your new datasets? You have to use `collect(faithfull_distant)` in R or `faithfull_distant.collect()` in Python for forcing Spark to return the data. Download a local copy of your data under the name `faithful`. Refresh your task manager web interface. What has just happenned?

<!-- By default, nothing is evaluated. You need to explicitly collect the data. Python code: ..................................... One can see on the task manager that some computation have been executed. -->

**Q 3.3** In one of the R sessions, compare:

```r
object.size(faithful)
object.size(faithful_distant)
```

In your Python session compare:

```python
sys.getsizeof(faithful)
sys.getsizeof(faithful_distant)
```

Can you explain the difference?

<!-- `faithful_distant` is just a pointer towards the distant object, not the object itself -->

**Q 3.4** Where can we see the actual memory space used to store `faithful` on the cluster? How can we explain the new mismatch?

<!-- duplication of information for ensuring redundancy -->

**Q 3.5** In your R/sparkR session, compare:

```r
        faithful        [faithful        $eruptions>1,"waiting"]  # (1)
        faithful_distant[faithful_distant$eruptions>1,"waiting"]  # (2)
collect(faithful_distant[faithful_distant$eruptions>1,"waiting"]) # (3)

faithful$waiting/60          # (4)
faithful_distant$waiting/60  # (5)

faithful        $waiting_hours <- faithful$waiting/60
faithful_distant$waiting_hours <- faithful_distant$waiting/60 # !!!!!!! DOES NOT FAIL! BUT RDD ARE SUPPOSED TO BE IMMUTABLE! (Have to try in the same session, from 2 clients sharing the same ref, to see if this does not change.)
```

In your R/sparklyr session, compare the following lines. (Don't let you disturb by `dplyr`'s syntax.)

```r
faithful        [faithful        $eruptions>1,"waiting"]
faithful_distant[faithful_distant$eruptions>1,"waiting"] # (*)

faithful         %>% filter(eruptions>1) %>% select(waiting)
faithful_distant %>% filter(eruptions>1) %>% select(waiting)
faithful_distant %>% filter(eruptions>1) %>% select(waiting) %>% collect()
faithful         %>% mutate(waiting_hours = waiting/60)
faithful_distant %>% mutate(waiting_hours = waiting/60) # (@)
```

- Why are (2), (5) or () not computed on the fly? <!-- Evaluation is costly. -->
- Why do line `(*)` fail ? Or why have lines (1) and (3) different outputs? (The numbers are the same, but the format is different.) <!-- The base functions are not available, developpers of the packages have to redefine — or "overload"" — the definitions so that they can apply to the new objects. -->
- Why do line `(+)` fail and not line `(@)` ? <!-- RDD are immutable. -->

-----------------------------------

Contrary to the local `faithful` object, which is stored in memory on one machine, the `faithful_distant` one is distributed accross many different virtual machines, called nodes. The distributed file system manager splits the data into chunks, deals them among the available nodes, and monitors the mapping between file names and chunks. Each chunk is duplicated to ensure fault tolerance.

Thus, `faithful_distant` is just a connector to the real distributed data set. It does not countain any data. If `[` or `filter()` work, it is because those functions have been overloaded with new definitions relatively to their base-R counterpart. You can not take for granted that any function existing in base R will work with a distant dataset. For instance, `[` does not work with the `sparklyr` library.

An other r `$` will fail because they are meant to be used with actual datasets. On a more conceptual level, `$<-` fails because Spark data frames are **immutable**. Indeed, once loaded in the cluster, any change in value is strongly discouraged, as it would necessitate to propagate these changes to the multiple copies of the data chunks spread across the nodes.

## 4. Lazy evaluation

**Q 4.1** <!-- connect to big dataset from teachers on R/sparklyr // copy on your own cloud a sample (the share is taken randomly between 1% and 50%) // maybe move at the beginning because it's going to take time! // add explanation of the data set-->

**Q 4.2** `xxxxxxxxx <- .............. %>% group_by(var1, var2) %>% summarize(var3=sum(var3), N=n()) %>% filter(var1 == ........)`. What are we asking for? Is the call executed? Where can you check?

<!-- filter on a categorial variable, the least frequent as possible -->

**Q 4.3** Add `collect()` to the chain and run. What about now? 

**Q 4.4** How much have you been charged for this request? How much data have been processed?

**Q 4.5** In your opinion, when was the `filter` operation performed? You can check by using the explain() function <!--(exists in Scala, but in R???????????) -->.

**Q 4.6** What if we now want `xxxxxxxxx <- .............. %>% group_by(var1, var2) %>% summarize(var3=sum(var3), N=n()) %>% filter(var1 == .....) %>% select(var2, var3)` ?

**Q 4.7.** Il est possible de forcer l'évaluation d'un résultat intermédiaire avec les méthodes `cache()` et `persist()`. Cela est utile quand votre flux de donnees (EN: _data flow_) possède des "branches", c-à-d lorsqu'une étape de pré-traitement est réutilisée par plusieurs traitements en aval. En ne modifiant qu'une seule ligne de code, appliquez ce principe au calcul de moyenne précédent.

<!--
var numbers = flights2018.map(flight => scala.util.Random.nextFloat).cache()
var sum = numbers.reduce(_+_)
var count = numbers.count()
sum/count
numbers.map( n => (n, 1) ).reduce( (a,b) => ((a._1*a._2+b._1*b._2)/(a._2+b._2), a._2+b._2) )
// mêmes résultats maintenant
-->


---------------------
L'évaluation paresseuse (*lazy evaluation*) signifie que Spark attendra jusqu'au tout dernier moment pour exécuter le graphe des instructions de calcul.
Dans Spark, au lieu de modifier les données immédiatement lorsque vous exprimez une opération, vous construisez un plan de transformations que vous aimeriez appliquer aux données de base.
En attendant la dernière minute pour exécuter le code, Spark compile ce plan à partir de vos transformations brutes en un plan physique rationalisé qui s'exécutera aussi efficacement que possible sur l'ensemble du cluster.
Cela offre d'immenses avantages car Spark peut optimiser le processus de l'ensemble des flux de données d'un bout à l'autre.
Par exemple si nous construisons une grosse tâche Spark mais spécifions un filtre à la fin qui nous demande seulement de récupérer une seule ligne de nos données, la façon la plus efficace de l'exécuter est d'accéder à cette unique ligne dont nous avons besoin.
Spark va en fait optimiser cela pour nous en poussant le filtre vers le bas automatiquement.

## 5. Map-reduce

The _map-reduce_ principle is a subset of distributed computation. It consists in the decomposition a large computation in two steps:

1. the _map_ step, in which we apply a first series of operations to each line of data, without exchange of information between the lines
2. the _reduce_ step, in which we now accumulate the results of the first step into the final result

A good analogy would be vote counting in an election. Each polling station counts their votes, and then these intermediary results are agreagated at the national level. Exactly like in the election case, the very decomposition of the overall task into smaller tasks makes the whole processeing less error-prone (or more _fault-tolerant_). The failure of _one_ polling station to properly count the votes does not corrupt the whole election process, and the task can be carried out again at the polling station level in case needed. Likewise, a failure at the processor / node level does not compromise the overall calculation, as the failed sub-tasks are immediately reallocated to other processors / nodes.

**Q 5.1.** Find two exemples of calculation that are easy to parallelize according to the _map-reduce_ paradigm, and one counter-exemple of a problem difficult or impossible to parallelize with this principle[^2]. <!-- Facile: moyenne, somme, techniques de Monte Carlo. Difficile: inversion de matrice. Impossible: travelling salesman. Opposition entre "embarassingly parallel problems" et "inherently sequential problems". -->

[^2]: https://softwareengineering.stackexchange.com/questions/144787/what-kind-of-problems-does-mapreduce-solve ; https://stackoverflow.com/questions/806569/whats-the-opposite-of-embarrassingly-parallel ; https://en.wikipedia.org/wiki/Embarrassingly_parallel

Counting is also a _map-reduce_ operation. `flights2018.count()` is equivalent to:

```{scala}
flights2018
  .map(flight => 1)
  .reduce( (accumulator, value) => accumulator + value ) // equivalent syntax: .reduce(_+_)
```

**Q 5.2.** Pourquoi ce code produit-il le même résultat que `count`? Expliquez la syntaxe `flight => 1` et `(accumulator, value) => accumulator + value`. Comment appelle-t-on ce type d'objet en programmation?

<!-- Au fur et à mesure que les différentes sous-tâches ont fini leur exécution, `accumulator` se rapproche du résultat attendu. (En réalité l'opération `reduce` est le plus souvent commutative puisque le résultat final doit être le même quel que soit l'ordre d'exécution des tâches du `map`. La distinction formelle entre `accumulator` et `value` est donc plus pédagogique qu'autre chose.) -->

**Q 5.3** Changez une ligne du code précédent pour calculer la distance totale parcourue par des avions de ligne au mois de janvier 2018. (La syntaxe Scala pour récupérer la propriété `p` de type `t` de la ligne `l` d'une _data-frame_ est `l.getAs[t]("p")`.)

<!-- flights2018.map(flight => flight.getAs[Double]("DISTANCE")).reduce( (accumulator, value) => accumulator + value ) -->

**Q 5.4** Que fait la fonction suivante? Et le code qui suit?

```{scala}
def myFunction( a:Double, b:Double ) : Double = if(b > a) b else a

flights2018
  .map(flight => flight.getAs[Double]("ARR_DELAY"))
  .reduce( myFunction _ ) // Le _ force Scala à interpéter myFunction comme une fonction.
```
<!-- Il est possible d'utiliser des fonctions nommées dans l'étape reduce. 
flights2018.map(flight => flight.getAs[Double]("ARR_DELAY")).reduce( myFunction _ )
-->

**Q 5.5** L'étape `map` peut renvoyer un n-uplet (EN: _tupple_) et l'opération `reduce` porter sur le n-uplet retourné par chaque processeur / nœud. Que fait le code suivant?

```{scala}
flights2018
  .map(flight => (flight.getAs[Double]("ARR_DELAY"), flight.getAs[java.sql.Date]("FL_DATE")))
  .reduce( (a, b) => if(a._1 > b._1) a else b )
```

## 6. Performance

Create a local copy of your dataset and perform the computation from question 4.2.
How long did it take?

From here (link to collaboratively filled dataset), download data about how long it took to complete the same task in a distributed dataset. Graphically, what is the importance of: the number of cores? the size of the data set? ... to be completed ...













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


**Q.3.6.** Répétez l'opération pour le calcul de la variance.

<!-- **Q.3.7.** La somme peut être réalisée soit dans l'étape _map_ (sur un seul processeur, donc séquentiellement) soit dans l'étape _reduce_ (parallélisé mais besoin de temps pour additionner). Essayer plusieurs façon de découper le data frame en évaluant le temps d'exécution. -->




















The `sparkR` library has a lot of utility functions to replace basic functionnalities (filtering rows, selecting columns) that are no longer available from base R. Unfortunately their specific syntax only works with parallelized datasets while some choices are just purely confusing. That is why we recommend using `dplyr` + `sparklyr`. The syntax is also different from base R, but at least the syntax is coherent and works similarly in local and distant data sets, distributed or not.


```python
sc == spark.sparkContext
sc.uiWebUrl # get the web ui URL
```

```r
# sparkR
sparkR.uiWebUrl()
```

```r
```

Difference between spark sessions (`spark`) and spark context (`sc`) not crystal clear for me: https://stackoverflow.com/questions/43802809/difference-between-sparkcontext-javasparkcontext-sqlcontext-and-sparksession and https://www.quora.com/What-is-the-difference-between-spark-context-and-spark-session.




















For this practice, we will use the database of commercial flights maintained by the US Bureau of Transportation Statistics, accessible at this address: https://www.transtats.bts.gov/DL_SelectFields.asp?Table_ID=236&DB_Short_Name=On-Time








## Exercice 1: Apache Spark

<!-- peut-être nécessaire de passer en Scala en fait pour accéder au map-reduce, qui n'est pas exposé dans sparkR ni dans sparklyr ; utiliser sparklyr pour les benchmarks? ex: en local, en ligne avec  2 cores, 3 cores, 4 cores, etc. vs taille des données -->





**Q1.6** The `dplyr` equivalent of `faithful[faithful$eruptions>10,"waiting"]` is `faithful %>% filter(eruptions>10) %>% select(waiting)`. Try this syntax both for `faithful` and `faithful_distant`. Is there any difference in output?

You can notice that the code for `faithful_distant` is not executed. This is on purpose: it forces us to wisely use the resources of the cluster, in order to spare any unnecessary processing. One can use the `collect()` function to retrieve the results.

### Spark UI & AWS monitoring

Lors du démarrage de spark-shell, une ligne de ce type est affichée `Spark context Web UI available at http://xxx.xxx.xxx.xx:xxxx`.
Ouvrir un navigateur à cette adresse permet d'afficher Spark UI. You can also access the Amazon usage console at xxxxxx.xxxxxxxx.xxxx.



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

## Exercice 2: introducing the map-reduce paradigm


<!-- flights2018.map(flight => (flight.getAs[Double]("ARR_DELAY"), flight.getAs[java.sql.Date]("FL_DATE"))).reduce( (a, b) => if(a._1 > b._1) a else b ) -->

**Remarque:** `a._1` permet d'accéder au premier élément du n-upplet `a`.


**Pour patienter:** refaire les exercices en Python et en R

<!--
flights2018
  .map(flight => flight.DEP_TIME)
  .sort()
  .reduce((a,b) => {println(b);return 1})
-->

<!-- oordre d'exécution-->
<!-- flatMap : reprgorammer la fonciton filter ? -->













## Pour approfondir/ réviser:

- Une série de billets introductifs en français:
    1. https://aseigneurin.github.io/2014/10/29/introduction-apache-spark.html
    2. https://aseigneurin.github.io/2014/11/01/initiation-mapreduce-avec-apache-spark.html
    3. https://aseigneurin.github.io/2014/11/06/mapreduce-et-manipulations-par-cles-avec-apache-spark.html
    
- "Quick start", sur le site officiel de Spark: https://spark.apache.org/docs/latest/quick-start.html

- Introduction à Scala: https://docs.scala-lang.org/tutorials/tour/tour-of-scala.html

- Spark: The Definitive Guide, by Bill Chambers and Matei Zaharia, O'Reilly.


**Sources used to write this course:**

- https://medium.com/@chris_bour/6-differences-between-pandas-and-spark-dataframes-1380cec394d2
- https://databricks.com/blog/2015/08/12/from-pandas-to-apache-sparks-dataframe.html
- https://ogirardot.wordpress.com/2015/07/31/from-pandas-to-apache-sparks-dataframe/
- https://lab.getbase.com/pandarize-spark-dataframes/
- https://spark.rstudio.com/examples/stand-alone-aws/
- https://spark.rstudio.com/examples/yarn-cluster-emr/
- https://eddjberry.netlify.com/post/2017-12-05-sparkr-vs-sparklyr/
- https://stackoverflow.com/questions/31012765/how-to-do-map-and-reduce-in-sparkr


- https://stackoverflow.com/questions/39494484/sparkr-vs-sparklyr
- https://stackoverflow.com/questions/34878804/how-to-share-data-from-spark-rdd-between-two-applications "The short answer is you can't share RDD's between jobs. The only way you can share data is to write that data to HDFS and then pull it within the other job."


Apache Sppark:
- https://spark.apache.org/docs/latest/
- https://spark.apache.org/docs/latest/quick-start.html
- https://spark.apache.org/docs/latest/sql-programming-guide.html
- https://spark.apache.org/docs/latest/sql-getting-started.html
- https://spark.apache.org/docs/latest/cluster-overview.html
- https://spark.apache.org/docs/latest/spark-standalone.html
- https://spark.apache.org/docs/latest/running-on-yarn.html
- https://spark.apache.org/docs/latest/submitting-applications.html

Apache Hadoop:
- https://hadoop.apache.org
- 

Incredibly akward syntax in SparkR:

```{r}
df <- read.json("examples/src/main/resources/people.json")

# Show the content of the DataFrame
head(df)

# Print the schema in a tree format
printSchema(df)

# Select only the "name" column
head(select(df, "name"))

# Select everybody, but increment the age by 1
head(select(df, df$name, df$age + 1))

# Select people older than 21
head(where(df, df$age > 21))

# Count people by age
head(count(groupBy(df, "age")))
```


```{python}
from pyspark.sql import Row

sc = spark.sparkContext

# Load a text file and convert each line to a Row.
lines = sc.textFile("examples/src/main/resources/people.txt")
parts = lines.map(lambda l: l.split(","))
people = parts.map(lambda p: Row(name=p[0], age=int(p[1])))

# Infer the schema, and register the DataFrame as a table.
schemaPeople = spark.createDataFrame(people)
schemaPeople.createOrReplaceTempView("people")

# SQL can be run over DataFrames that have been registered as a table.
teenagers = spark.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")
```


# Points de recherches:
- HDFS
- YARN
- Hive

dataset (the Java / Scala primary interface) vs. dataframe (the R/Python primary interface)
dataframe = "dataset organized into columns", "in Scala and Java, ... represented by a dataset of rows."
(pas encore parfaitement clair)



There are several useful things to note about this architecture:

1. Each application gets its own executor processes, which stay up for the duration of the whole application and run tasks in multiple threads. This has the benefit of isolating applications from each other, on both the scheduling side (each driver schedules its own tasks) and executor side (tasks from different applications run in different JVMs). However, it also means that data cannot be shared across different Spark applications (instances of SparkContext) without writing it to an external storage system.
2. Spark is agnostic to the underlying cluster manager. As long as it can acquire executor processes, and these communicate with each other, it is relatively easy to run it even on a cluster manager that also supports other applications (e.g. Mesos/YARN).
3. The driver program must listen for and accept incoming connections from its executors throughout its lifetime (e.g., see spark.driver.port in the network config section). As such, the driver program must be network addressable from the worker nodes.
4. Because the driver schedules tasks on the cluster, it should be run close to the worker nodes, preferably on the same local area network. If you’d like to send requests to the cluster remotely, it’s better to open an RPC to the driver and have it submit operations from nearby than to run a driver far away from the worker nodes.

There exists a "cluster" mode and a "client" mode for the Spark driver process. In "client" mode, the driver is launched outside the cluster. (Maybe more clear for the students.)

Distinction between job and task. One job = mulitple tasks. A job is submitted to the driver program, which in turns sumbits tasks to the executors (local driver programs situated on the worker nodes). Executors are specific to 1 application (cached data can thus not be shared accross applications).

By default, standalone Spark will attribute all available cores to the first application (which does not make sens if you have more thant 1 application)






https://docs.aws.amazon.com/fr_fr/AmazonS3/latest/dev/RequesterPaysBuckets.html






























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



