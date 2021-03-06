# TP 3 : Support Vector Machines

## Mise en place du cluster

Dans ce TP nous allons une nouvelle fois mettre en place un cluster EMR, mais cette fois-ci nous n'allons pas installer R-studio server dessus, mais directement utiliser l'interface de notebook proposée par AWS pour faire du **python**.

- [ ] Uploadez le fichier "install-package.sh" que vous trouverez sur moodle dans un  compartiment s3. Ce script va permettre d'installer les packages python utiles pour le TP
- [ ] Cliquez sur "Chemin de copie" et collez dans un bloc note le lien s3 du fichier. 

- [ ] Créez un cluser EMR
  - [ ] Cliquez sur "Accéder aux options avancées"
  - [ ] Sélectionnez :
    - [ ] Hadoop 2.8.5
    - [ ] Ganglia 3.7.2
    - [ ] Spark 2.4.4
    - [ ] Zeppelin 0.8.2
  - [ ] Cliquez sur "Suivant"
  - [ ] Cliquez sur "Suivant"
  - [ ] Dans "Paramètres de cluster généraux" dépliez option d'amorçage, sélectionnez "action personnalisée" et cliquez sur "Configurer et ajouter"
    - [ ] Nom : install package
    - [ ] Emplacement du script : le chemin vers votre script s3 que vous avez au préalable copié.
  - [ ] Cliquez sur "Suivant"
  - [ ] Choisissez une clef SSH pour votre cluster
  - [ ] Lancez le cluster
- [ ] Créer un bloc-notes
  - [ ] Dans la fenêtre de gauche cliquez sur "blocs-notes"
  - [ ] "Créer une bloc notes"
  - [ ] Donnez lui le nom que vous souhaitez
  - [ ] Choisissez le cluster créé précédemment
  - [ ] Créez un bloc notes



Pour ce TP nous allons utiliser le package python [scikit-learn](https://scikit-learn.org/stable/index.html) qui est open source ([le github](https://github.com/scikit-learn/scikit-learn)) et propose un grand nombre d'outil de machine learning pour python.

Dans un notebook **pyspark** copiez les lignes de codes suivantes pour initier le TP. Attention chaque bloc doit être écrit dans une cellule différente.

````python
%%configure -f
{ "conf":{
"spark.pyspark.python": "python3",
"spark.pyspark.virtualenv.enabled": "true",
"spark.pyspark.virtualenv.type":"native",
"spark.pyspark.virtualenv.bin.path":"/usr/bin/virtualenv"
}}
````

````python
%%local
%matplotlib inline

# Standard scientific Python imports
import matplotlib.pyplot as plt
import numpy as np
from time import time

# Import datasets, classifiers and performance metrics
from sklearn import datasets, svm, pipeline
from sklearn.kernel_approximation import (RBFSampler,
                                          Nystroem)
from sklearn.decomposition import PCA

# The digits dataset
digits = datasets.load_digits(n_class=9)

# Need to flatten the image
n_samples = len(digits.data)
data = digits.data / 16.
data -= data.mean(axis=0)

# We learn the digits on the first half of the digits.
data_train, targets_train = (data[:n_samples // 2],
                             digits.target[:n_samples // 2])


# Now predict the value of the digit on the second half.
data_test, targets_test = (data[n_samples // 2:],
                           digits.target[n_samples // 2:])
````

Comme nous sommes dans un environnement pyspark, pour faire du python sans spark (le début du TP) vos cellules doivent commencer par **%%local**.

## Problème

On désire résoudre un problème de classification binaire :

* on cherche la fonction $h^*$ qui minimise l'espérance ${\cal E}(h) \stackrel{def}{=} \mathbb{E}_{(x,y) \sim \cal D}\left[\mathbb{1}_{h(x)\neq y}\right]$, où
	* $\cal D$ est une distribution sur $\mathbb{R}^d\times \{0,1\}$,
	* $x \in\mathbb{R}^d$ et $y \in \{0,1\}$,
	* $\mathbb{1}_{b}$ est la fonction indicatrice ($\mathbb{1}_{b}$ vaut `1` si $b$ vaut `vrai` et `0` sinon) ;
* pour ce faire on a à notre disposition $n$ tirages indépendants $(x_1, y_1), \dots, (x_n,y_n)$ selon la loi $\cal D$ ;
* l'objectif est alors de trouver une fonction $\hat{h}$ telle que ${\cal E}\left(\hat h\right)$ soit le plus proche possible de ${\cal E}(h^*)$.

Par la suite on notera $x^Tx'$ le produit scalaire entre les vecteurs $x$ et $x'$ de  $\mathbb{R}^d$.

## SVM avec noyaux
Les SVM à noyaux proposent d'atteindre cette objectif en recherchant un fonction $\hat{h}$ qui s'écrive sous la forme  $\operatorname{sgn}\left(w^T\Phi(x)+b\right)$, où

* $\Phi$ est une transformation non-linéaire des données, choisie par l'utilisateur, et dont le résultat est dans $\mathbb{R}^m$, avec $m$ potentiellement infini,
* $w \in \mathbb{R}^m$ et  $b\in \mathbb{R}$.

Le couple de paramètres $(w, b)$ est défini comme  solution du problème de minimisation
$$
\begin{align}\begin{aligned}\min_ {w, b, \zeta} \frac{1}{2} w^T w + C \sum_{i=1}^{n} \zeta_i\\\begin{split}\text {tel que } & y_i (w^T \phi (x_i) + b) \geq 1 - \zeta_i,\\
& \zeta_i \geq 0, i=1, ..., n\end{split}\end{aligned}\end{align},
$$

avec $C\in \mathbb{R}^{+*}$ est un paramètre choisi par l'utilisateur.

Cette approche est en réalité équivalente à rechercher une solution sous la forme 

$$
\operatorname{sgn}\left(\sum_{i=1}^n y_i \alpha_i k(x_i, x) + \rho\right)
$$

où

* $k(x_i, x)\stackrel{def}{=} \Phi(x_i)^T\Phi(x)$ est appelé *noyau* est défini par l'utilisateur,
* $\alpha=(\alpha_1, \dots, \alpha_n)^T\in \mathbb{R}^n$ et $\rho\in \mathbb{R}$.

Le couple de paramètres $(\alpha, \rho)$ est alors défini comme  solution du problème de minimisation
$$
 \begin{align}\begin{aligned}\min_{\alpha} \frac{1}{2} \alpha^T Q \alpha - e^T \alpha\\\begin{split}
\text {tel que } & y^T \alpha = 0\\
& 0 \leq \alpha_i \leq C, i=1, ..., n\end{split}\end{aligned}\end{align},
$$
où l'on retrouve le paramètre $C\in \mathbb{R}^{+*}$, et où $Q$ est une matrice semi-définie positive de taille $n$ définie par $Q_{ij} \stackrel{def}{=} y_i y_j k(x_i, x_j)$.

### Complexité
Cette deuxième formulation a une très bonne propriété : elle ne fait pas intervenir $\Phi$, mais $k$. Du coup,

* on peut apprendre une fonction linéaire dans un espace $\mathbb{R}^m$ de dimension infinie ;
* la complexité de l'algorithme dépend uniquement du nombre de données $n$, et pas de la dimension $m$ de l'espace dans lequel la fonction est apprise.

Le problème est que le problème d'optimisation associé est un problème quadratique (QP pour *Quadratic Programming*) qui est donc "compliqué" à résoudre. Avec cette formulation du problème, les meilleurs algorithmes améliorent progressivement les paramètres en observant des couples de points. Ces algorithmes on une complexité polynomiale en $n$ et sont difficilement parallélisables. À titre d'exemple, Spark.ML ne fournit pas d'implémentation de SVM à noyaux, et les discussions sur le sujets se finissent typiquement par ce genre de réponse :
	
> Joseph K. Bradley added a comment - 27/Jan/17 00:03
> 
> Commenting here b/c of the recent dev list thread: Non-linear kernels for SVMs in Spark would be great to have. The main barriers are:
> 
> * Kernelized SVM training is hard to distribute. Naive methods require a lot of communication. To get this feature into Spark, we'd need to do proper background research and write up a good design.
> * Other ML algorithms are arguably more in demand and still need improvements (as of the date of this comment). Tree ensembles are first-and-foremost in my mind.
> 
> [source](https://issues.apache.org/jira/browse/SPARK-4638?focusedCommentId=15840711&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-15840711)

Toutefois, des solutions existent pour contourner le problèmes. Elles consistent typiquement à apprendre la fonction $\hat{h}$ à partir d'une version approchée de la matrice de noyau, ou encore à plonger les exemples dans un espace $\mathbb{R}^D$ dans lequel le produit scalaire entre deux points est proche du produit scalaire dans l'espace $\mathbb{R}^m$ dans lequel $\Phi$ plonge les exemples. C'est ce que nous allons voir dans la section suivante.

### En pratique

1. En vous aidant de la [documentation](https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVC.html) de scikit-learn sur les SMV à noyaux, implémentez-en un sur les données MNIST (il y a un exemple en bas de la page).

2. Faites varier la taille de votre échantillon d'entrainement et :

   1. Opposez la à la qualité de votre modèle
   2. Opposez là au temps de calcul de votre modèle.


Pour ce faire utilisez :

- La fonction time() pour récupérer le temps de calcul du modèle ([documentation](https://docs.python.org/fr/3/library/time.html#time.time))

- Créez 3 vecteurs :

  - Un avec la taille de l'échantillon
  - Un avec le temps
  - Et un avec la qualité du modèle

- Aidez vous du code suivant :

  ````python
  %matplotlib inline
  # %matplotlib inline doit être mis au début de la cellule !
  
  # plot the results:
  # Size of the plot windows
  plt.figure(figsize=(16, 4))
  # First plot, accuracy, position
  accuracy = plt.subplot(121)
  # Second plot, timescale, position
  timescale = plt.subplot(122)
  
  # Set the lines to draw on accuracy plot
  accuracy.plot(linear_svm_sizes_sample, linear_svm_scores, label="SVM linéaire")
  
  # Set the lines to draw on timescale ploto plot
  timescale.plot(linear_svm_sizes_sample, linear_svm_times, '--',
                 label="SVM linéaire")
  
  # legends and labels
  accuracy.set_title("Classification accuracy")
  timescale.set_title("Training times")
  accuracy.set_xlim(linear_svm_sizes_sample[0], linear_svm_sizes_sample[-1])
  accuracy.set_xlabel("Size of the data sample")
  accuracy.set_xticks(())
  timescale.set_xlabel("Size of the data sample")
  accuracy.set_ylabel("Classification accuracy")
  timescale.set_ylabel("Training time in seconds")
  accuracy.legend(loc='best')
  timescale.legend(loc='best')
  plt.tight_layout()
  plt.show()
  ````

## SVM Linéaire ...
Tout d'abord revenons aux SVM linéaires. Les SVM linéaires correspondent au cas particulier où $\Phi(x)=x$, ie. $k(x,x')=x^Tx'$. La première définition de la fonction $\hat h$ se simplifie alors en $\operatorname{sgn}\left(w^Tx+b\right)$, et le problème de minimisation peut se réécrire sous la forme
$$
\min_ {w, b} \widehat{\cal E}\left(\hat h\right) = \frac{1}{2} w^T w + C \sum_{i=1}^{n} \max\left(0, 1 - y_i (w^T x_i + b) \right)
$$

Sous cette forme, le problème d'optimisation reste compliqué à résoudre, mais des méthodes d'optimisation de type *Newton approché* (*Quasi-Newton*) s'avèrent extrêmement efficaces en pratique lorsque l'on est confronté à de très grandes bases de données. Ces méthodes sont aussi plus faciles à paralléliser.

> #### Remarques
> * Dans cette troisième version du problème d'optimisation, apparaît une somme sur la fonction de coût $\max\left(0, 1 - y_i (w^T x_i + b)\right)$ associée à chaque exemple $i$. C'est cette somme qui ouvre la voie à des approches par descentes de gradients stochastiques ou des méthodes de Newton approché.
> * Le $\max$ dans la fonction est non-différentiable, les méthodes à base de descentes de gradients doivent donc être adaptées pour fonctionner.
> * Théoriquement, on désire minimiser ${\cal E}\left(\hat h\right)$ ; en pratique on se contente de minimiser $\widehat{\cal E}\left(\hat h\right)$. Il n'est donc pas nécessaire d'optimiser très finement $\widehat{\cal E}\left(\hat h\right)$, puisque l'on désire en réalité optimiser une autre fonction. On désire plutôt trouver rapidement un couple $(w, b)$ "raisonnable". C'est une des raisons qui expliquent la force des méthodes par descente de gradient stochastique ou des méthodes de Newton approché dans ce contexte.

 ### En pratique

1. En vous aidant de la [documentation](https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVC.html) de scikit-learn sur les SMV linéaires, implémentez-en un sur les données MNIST.

2. Faites varier la taille de votre échantillon d'entrainement et :

   1. Opposez la à la qualité de votre modèle
   2. Opposez là au temps de calcul de votre modèle.

   Faites cela en ajoutant sur les graphiques fait précédemment les courbes que vous obtenez.

## ... à noyaux gaussien

Voyons maintenant comment construire un espace de représentation dans lequel un SVM linéaire se comporte comme un SVM à noyau gaussien de paramètre $\sigma^2$ : $k_\sigma(x,x') = \exp\left(-\frac{\lVert x-x'\rVert^2}{2\sigma^2}\right)$. On va pour se faire s'appuyer sur des *attributs de Fourrier aléatoires* (*Random Fourrier Features*).

Tout d'abord, on construit $D$ attributs de Fourrier aléatoires, où $D$ est un paramètre choisi par l'utilisateur :

* on tire $D$ vecteurs aléatoires indépendants $\omega_{1},\ldots,\omega_{D}\in\mathbb{R}^{d}$ selon une loi gaussienne multivariée centrée de matrice de covariance l'identité sur $\sigma^2$ ($\omega_j \sim {\cal N}(0, \sigma^{-2}I)$),
* on tire $D$ valeurs aléatoires indépendantes $a_{1},\ldots, a_{D}\in\mathbb{R}$ uniformément distribuées dans $[0, 2\pi]$,
* on définit la transformation $\Psi$ qui à chaque vecteur $x\in\mathbb{R}^d$ associe son vecteur d'attributs de Fourrier aléatoires $\Psi(x) = \sqrt{\frac{2}{D}}\left(\cos\left(\omega_{1j}^{\top}x+a_{1}\right),\ldots,\cos\left(\omega_{D}^{\top}x+a_{D}\right)\right)^{\top} \in \mathbb{R}^D$.

Puis on applique un SVM linéaire aux données $(\Psi(x_1), y_1), \dots, (\Psi(x_n),y_n)$ qui retourne une fonction $\hat{h}_\Psi(\Psi(x)) = \operatorname{sgn}\left(w^T.\Psi(x) + b\right)$.

La fonction de classification sur les données initiales est alors $\hat{h}(x) = \operatorname{sgn}\left(w^T.\Psi(x) + b\right)$.


> #### Pourquoi ça fonctionne ?
> D'une part, les lois générant les paramètres $\omega_j$ et $ a_j$ ont été choisies de façon à ce que pour tout couple de vecteurs $(x,x')$ de $\mathbb{R}^d$, $\mathbb{E}_{\omega_j, a_j}\left[2.\cos\left(\omega_{j}^{\top}x+a_{j}\right).\cos\left(\omega_{j}^{\top}x'+a_{j}\right)\right] = k_\sigma(x,x')$. Le produit scalaire $\Psi(x)^T\Psi(x')$ correspond donc à la moyenne de $D$ observations d'une variable aléatoire bornée de moyenne $k_\sigma(x,x')$. Ainsi, plus $D$ est grand, plus $\Psi(x)^T\Psi(x') \approx k_\sigma(x,x')$.
> 
> D'autres part, les conditions de KKT (*Karush–Kuhn–Tucker*) appliquées au problème d'optimisation  du SVM linéaire impliquent que $\hat{h}(x)$ peut s'écrire sous la forme $\operatorname{sgn}\left(\sum_{i=1}^n y_i \alpha_i \Psi(x_i)^T\Psi(x) + \rho\right)$.
> Ainsi $\hat{h}(x) \approx \operatorname{sgn}\left(\sum_{i=1}^n y_i \alpha_i k_\gamma(x_i,x') + \rho\right)$, qui est la forme de la fonction apprise par un SVM à noyau gaussien \o/. 

 ### En pratique

- Utilisez la [documentation](https://scikit-learn.org/stable/modules/generated/sklearn.kernel_approximation.RBFSampler.html#sklearn-kernel-approximation-rbfsampler) suivante pour implémenter une SVM par approximation du noyaux par approximation de la transformé de Fourier du noyau par méthode de Monte Carlo.
- Il est également possible d'approchez le noyau en utilisant un échantillon des données. En utilisant la [documentation](https://scikit-learn.org/stable/modules/generated/sklearn.kernel_approximation.RBFSampler.html#sklearn-kernel-approximation-rbfsampler) suivante mettez en place l'approximation du noyaux par échantillonnage. 

Voici un bout de code pour vous aider :

```python
linear_svm = svm.LinearSVC()

# create pipeline from kernel approximation and linear svm
feature_map_fourier = RBFSampler(gamma=.2, random_state=1)
feature_map_nystroem = Nystroem(gamma=.2, random_state=1)
fourier_approx_svm = pipeline.Pipeline([("feature_map", feature_map_fourier),
                                        ("svm", svm.LinearSVC())])

nystroem_approx_svm = pipeline.Pipeline([("feature_map", feature_map_nystroem),
                                        ("svm", svm.LinearSVC())])

for D in sample_sizes:
    # pass the sample
    fourier_approx_svm.set_params(feature_map__n_components=D)
    nystroem_approx_svm.set_params(feature_map__n_components=D)
    
    #nystorem approx
    start = time()
    nystroem_approx_svm.fit(data_train, targets_train)
    nystroem_times.append(time() - start)

    #fourier approx
    start = time()
    fourier_approx_svm.fit(data_train, targets_train)
    fourier_times.append(time() - start)

    fourier_score = fourier_approx_svm.score(data_test, targets_test)
    nystroem_score = nystroem_approx_svm.score(data_test, targets_test)
    nystroem_scores.append(nystroem_score)
    fourier_scores.append(fourier_score)
```



## Avec Spark

Nous allons voir deux façons d'utiliser Spark pour faire une SVM. La première avec la fonction LinearSVC de Spark, et une autre utilisant le package joblibspark ([documentation](https://github.com/joblib/joblib-spark)) qui sert d'interface pour distribuer des tâches sur un cluster Spark.

### Spark SVM

La fonction [LinearSVC](https://spark.apache.org/docs/2.2.0/api/python/pyspark.ml.html#pyspark.ml.classification.LinearSVC) prend en paramètre un spark dataframe avec une colonnes features. Voici le code pour créer un tel dataframe à partir des données utilisées dans le TP

````python
from pyspark.mllib.linalg import Vectors

targets_train_df = np.concatenate(([targets_train.tolist()],data_train.T.tolist()), axis = 0).T
targets_train_df = map(lambda x: (int(x[0]), Vectors.dense(x[1:])), targets_train_df)
targets_train_df = spark.createDataFrame(targets_train_df,schema=["label", "features"])
````

### Joblibspark

Voici le code de la documentation pour utiliser joblibspark. Il est possible que redémarrer le noyau soit nécessaire pour que le code fonctionne.

````python
from sklearn.utils import parallel_backend
from sklearn.model_selection import cross_val_score
from sklearn import datasets
from sklearn import svm
from joblibspark import register_spark

iris = datasets.load_iris()
clf = svm.SVC(kernel='linear', C=1)
with parallel_backend('spark', n_jobs=3):
  scores = cross_val_score(clf, iris.data, iris.target, cv=5)

print(scores)
````

## Pour aller plus loin

* l'algorithme d'optimisation utilisé dans Spark
	* Jin Yu, S.V. N. Vishwanathan, Simon Günter, Nicol N. Schraudolph. A Quasi-Newton Approach to Nonsmooth Convex Optimization Problems in Machine Learning. Journal of Machine Learning Research 11 (2010). p. 1–57.
* Algorithmes d'optimisation pour SVM et leur complexité
	* Large-Scale Kernel Machines. Edited by Léon Bottou, Olivier Chapelle, Dennis DeCoste and Jason Weston. The MIT Press.
	* Transparents d'Olivier Chapelle : [http://helper.ipam.ucla.edu/publications/sews2/sews2_7130.pdf](http://helper.ipam.ucla.edu/publications/sews2/sews2_7130.pdf)
* Version distribuée (d'une variante des SVM)
	* Chieh-Yen Lin, Cheng-Hao Tsai, Ching-Pei Lee, Chih-Jen Lin. Large-scale logistic regression and linear support vector machines using spark. IEEE International Conference on Big Data (2014). [https://www.csie.ntu.edu.tw/~cjlin/papers/spark-liblinear/spark-liblinear.pdf](https://www.csie.ntu.edu.tw/~cjlin/papers/spark-liblinear/spark-liblinear.pdf)
* Attributs de Fourrier aléatoires
	* Ali Rahimi and Ben Recht. Random Features for Large-Scale Kernel Machines. Advances in Neural Information Processing Systems (NIPS'07).

