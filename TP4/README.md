# panorama-bigdata

# Problème
On désire résoudre un problème de classification binaire :

* on cherche la fonction $h^*$ qui minimise l'espérance ${\cal E}(h) \stackrel{def}{=} \mathbb{E}_{(x,y) \sim \cal D}^d\left[\mathbb{1}_{h(x)\neq y}\right]$, où
	* $\cal D$ est une distribution sur $\mathbb{R}^d\times \{0,1\}$,
	* $x \in\mathbb{R}^d$ et $y \in \{0,1\}$,
	* $\mathbb{1}_{b}$ est la fonction indicatrice ($\mathbb{1}_{b}$ vaut `1` si $b$ vaut `vrai` et `0`sinon) ;
* pour ce faire on a à notre disposition $n$ tirage indépendants $(x_1, y_1), \dots, (x_n,y_n)$ selon la distribution $\cal D$ ;
* la tâche consiste donc à définir un algorithme qui retourne une fonction $\hat{h}$ telle que ${\cal E}\left(\hat h\right)$ soit le plus proche possible de ${\cal E}(h^*)$.

Par la suite on notera $x^Tx'$ le produit scalaire entre les vecteurs $x \in\mathbb{R}^d$ et $x' \in\mathbb{R}^d$.

# SVM avec noyaux
Les SVM à noyaux propose d'atteindre cette objectif en recherchant un fonction $\hat{h}$ qui s'écrive sous la forme  $\operatorname{sgn}\left(w^T\Phi(x)+b\right)$, où

* $\Phi$ est une transformation non-linéaire des données choisie par l'utilisateur et dont le résultat est dans $\mathbb{R}^m$, avec $m$ potentiellement infini,
* $w \in \mathbb{R}^m$ et  $b\in \mathbb{R}$.

Le couple de paramètres $(w, b)$ est défini comme  solution du problème de minimisation
$$
\begin{align}\begin{aligned}\min_ {w, b, \zeta} \frac{1}{2} w^T w + C \sum_{i=1}^{n} \zeta_i\\\begin{split}\text {tel que } & y_i (w^T \phi (x_i) + b) \geq 1 - \zeta_i,\\
& \zeta_i \geq 0, i=1, ..., n\end{split}\end{aligned}\end{align},$$

avec $C\in \mathbb{R}^{+*}$ est un paramètre choisi par l'utilisateur.

Cette approche est en réalité équivalente à rechercher une solution sous la forme $\operatorname{sgn}\left(\sum_{i=1}^n y_i \alpha_i K(x_i, x) + \rho\right)$ où

* $K(x_i, x)\stackrel{def}{=} \Phi(x_i)^T\Phi(x)$ est appelé noyau est défini par l'utilisateur,
* $\alpha=(\alpha_1, \dots, \alpha_n)^T\in \mathbb{R}^n$ et $\rho\in \mathbb{R}$.

Le couple de paramètres $(\alpha, \rho)$ est alors défini comme  solution du problème de minimisation
$$
 \begin{align}\begin{aligned}\min_{\alpha} \frac{1}{2} \alpha^T Q \alpha - e^T \alpha\\\begin{split}
\text {tel que } & y^T \alpha = 0\\
& 0 \leq \alpha_i \leq C, i=1, ..., n\end{split}\end{aligned}\end{align},
$$
où l'on retrouve le paramètre $C\in \mathbb{R}^{+*}$, et où $Q$ est une matrice semi-définie positive de taille $n$ définie par $Q_{ij} \stackrel{def}{=} y_i y_j K(x_i, x_j)$.

## Complexité
Cette deuxième formulation a une très bonnes propriété : Elle ne fait pas intervenir $\Phi$, mais $K$. Du coup,

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


Toutefois, des solutions existent pour contourner le problèmes. Elles consistent typiquement à apprendre la fonction $\hat{h}$ à partir d'une version approchée de la matrice $K$, ou encore à plonger les exemples dans un espace $\mathbb{R}^D$ dans lequel le produit scalaire entre deux points soit proche du produit scalaire dans l'espace $\mathbb{R}^m$ cible de la fonction $\Phi$. C'est ce que nous allons voir dans la section suivante.
