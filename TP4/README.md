# panorama-bigdata

# Problème
On désire résoudre un problème de classification binaire :

* on cherche la fonction $h^*$ qui minimise l'espérance ${\cal E}(h) \stackrel{def}{=} \mathbb{E}_{(x,y) \sim \cal D}\left[\mathbb{1}_{h(x)\neq y}\right]$, où
	* $\cal D$ est une distribution sur $\mathbb{R}^d\times \{0,1\}$,
	* $x \in\mathbb{R}^d$ et $y \in \{0,1\}$,
	* $\mathbb{1}_{b}$ est la fonction indicatrice ($\mathbb{1}_{b}$ vaut `1` si $b$ vaut `vrai` et `0` sinon) ;
* pour ce faire on a à notre disposition $n$ tirages indépendants $(x_1, y_1), \dots, (x_n,y_n)$ selon la loi $\cal D$ ;
* l'objectif est alors de trouver une fonction $\hat{h}$ telle que ${\cal E}\left(\hat h\right)$ soit le plus proche possible de ${\cal E}(h^*)$.

Par la suite on notera $x^Tx'$ le produit scalaire entre les vecteurs $x$ et $x'$ de  $\mathbb{R}^d$.

# SVM avec noyaux
Les SVM à noyaux proposent d'atteindre cette objectif en recherchant un fonction $\hat{h}$ qui s'écrive sous la forme  $\operatorname{sgn}\left(w^T\Phi(x)+b\right)$, où

* $\Phi$ est une transformation non-linéaire des données, choisie par l'utilisateur, et dont le résultat est dans $\mathbb{R}^m$, avec $m$ potentiellement infini,
* $w \in \mathbb{R}^m$ et  $b\in \mathbb{R}$.

Le couple de paramètres $(w, b)$ est défini comme  solution du problème de minimisation
$$
\begin{align}\begin{aligned}\min_ {w, b, \zeta} \frac{1}{2} w^T w + C \sum_{i=1}^{n} \zeta_i\\\begin{split}\text {tel que } & y_i (w^T \phi (x_i) + b) \geq 1 - \zeta_i,\\
& \zeta_i \geq 0, i=1, ..., n\end{split}\end{aligned}\end{align},$$

avec $C\in \mathbb{R}^{+*}$ est un paramètre choisi par l'utilisateur.

Cette approche est en réalité équivalente à rechercher une solution sous la forme $\operatorname{sgn}\left(\sum_{i=1}^n y_i \alpha_i k(x_i, x) + \rho\right)$ où

* $k(x_i, x)\stackrel{def}{=} \Phi(x_i)^T\Phi(x)$ est appelé *noyau* est défini par l'utilisateur,
* $\alpha=(\alpha_1, \dots, \alpha_n)^T\in \mathbb{R}^n$ et $\rho\in \mathbb{R}$.

Le couple de paramètres $(\alpha, \rho)$ est alors défini comme  solution du problème de minimisation
$$
 \begin{align}\begin{aligned}\min_{\alpha} \frac{1}{2} \alpha^T Q \alpha - e^T \alpha\\\begin{split}
\text {tel que } & y^T \alpha = 0\\
& 0 \leq \alpha_i \leq C, i=1, ..., n\end{split}\end{aligned}\end{align},
$$
où l'on retrouve le paramètre $C\in \mathbb{R}^{+*}$, et où $Q$ est une matrice semi-définie positive de taille $n$ définie par $Q_{ij} \stackrel{def}{=} y_i y_j k(x_i, x_j)$.

## Complexité
Cette deuxième formulation a une très bonnes propriété : elle ne fait pas intervenir $\Phi$, mais $k$. Du coup,

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

# SVM Linéaire ...
Tout d'abord revenons aux SVM linéaires. Les SVM linéaires correspondent au cas particulier où $\Phi(x)=x$, ie. $k(x,x')=x^Tx'$. La première définition de la fonction $\hat h$ se simplifie alors en $\operatorname{sgn}\left(w^Tx+b\right)$, et le problème de minimisation peut se réécrire sous la forme
$$
\min_ {w, b} \widehat{\cal E}\left(\hat h\right) = \frac{1}{2} w^T w + C \sum_{i=1}^{n} \max\left(0, 1 - y_i (w^T x_i + b) \right),$$

Sous cette forme, le problème d'optimisation reste compliqué à résoudre, mais des méthodes d'optimisation de type *Newton approché* (*Quasi-Newton*) s'avèrent extrêmement efficaces en pratique lorsque l'on est confronté à de très grandes bases de données. Ces méthodes sont aussi plus faciles à paralléliser.

> ### Remarques
> * Dans cette troisième version du problème d'optimisation, apparaît une somme sur la fonction de coût $\max\left(0, 1 - y_i (w^T x_i + b)\right)$ associée à chaque exemple $i$. C'est cette somme qui ouvre la voit à des approches par descentes de gradient stochastiques ou des méthodes de Newton approché.
> * Le $\max$ dans la fonction est non-différentiable, les méthodes à base de descente de gradients doivent donc être adaptées pour fonctionner.
> * Théoriquement, on désire minimiser ${\cal E}\left(\hat h\right)$ ; en pratique on se contente de minimiser $\widehat{\cal E}\left(\hat h\right)$. Il n'est donc pas nécessaire d'optimiser très finement $\widehat{\cal E}\left(\hat h\right)$, puisque l'on désire en réalité optimiser une autre fonction. On désire plutôt trouver rapidement un couple $(w, b)$ "raisonnable". C'est une des raisons qui expliquent la force des méthodes par descente de gradient stochastique ou des méthodes de Newton approché dans ce contexte.

 
 

## ... à noyaux gaussien
Voyons maintenant comment construire un espace de représentation dans lequel un SVM linéaire se comporte comme un SVM à noyau gaussien de paramètre $\sigma^2$ : $k_\sigma(x,x') = \exp\left(-\frac{\lVert x-x'\rVert^2}{2\sigma^2}\right)$. On va pour se faire s'appuyer sur des *attributs de Fourrier aléatoires* (*Random Fourrier Features*).

Tout d'abord, on construit $D$ attributs de Fourrier aléatoires, où $D$ est un paramètre choisi par l'utilisateur :

* on tire $D$ vecteurs aléatoires indépendants $\omega_{1},\ldots,\omega_{D}\in\mathbb{R}^{d}$ selon une loi gaussienne multivariée centrée de matrice de covariance l'identité sur $\sigma^2$ ($\omega_j \sim {\cal N}(0, \sigma^{-2}I)$),
* on tire $D$ valeurs aléatoires indépendantes $a_{1},\ldots, a_{D}\in\mathbb{R}$ uniformément distribuées dans $[0, 2\pi]$,
* on définit la transformation $\Psi$ qui à chaque vecteur $x\in\mathbb{R}^d$ associe son vecteur d'attributs de Fourrier aléatoires $\Psi(x) = \sqrt{\frac{2}{D}}\left(\cos\left(\omega_{1j}^{\top}x+a_{1}\right),\ldots,\cos\left(\omega_{D}^{\top}x+a_{D}\right)\right)^{\top} \in \mathbb{R}^D$.

Puis on applique un SVM linéaire aux données $(\Psi(x_1), y_1), \dots, (\Psi(x_n),y_n)$ qui retourne une fonction $\hat{h}_\Psi(\Psi(x)) = \operatorname{sgn}\left(w^T.\Psi(x) + b\right)$.

La fonction de classification sur les données initiales est alors $\hat{h}(x) = \operatorname{sgn}\left(w^T.\Psi(x) + b\right)$.


> ### Pourquoi ça fonctionne ?
> D'une part, les lois générant les paramètres $\omega_j$ et $ a_j$ ont été choisies de façon à ce que pour tout couple de vecteurs $(x,x')$ de $\mathbb{R}^d$, $\mathbb{E}_{\omega_j, a_j}\left[2.\cos\left(\omega_{j}^{\top}x+a_{j}\right).\cos\left(\omega_{j}^{\top}x'+a_{j}\right)\right] = k_\sigma(x,x')$. Le produit scalaire $\Psi(x)^T\Psi(x')$ correspond donc à la moyenne de $D$ observations d'une variable aléatoire **bornéee** de moyenne $k_\sigma(x,x')$. Ainsi, plus $D$ est grand, plus $\Psi(x)^T\Psi(x') \approx k_\sigma(x,x')$.
> 
> D'autres part, les conditions de KKT appliquées au problème d'optimisation  du SVM linéaire impliquent que $\hat{h}(x)$ peut s'écrire sous la forme $\operatorname{sgn}\left(\sum_{i=1}^n y_i \alpha_i \Psi(x_i)^T\Psi(x) + \rho\right)$.
> Ainsi $\hat{h}(x) \approx \operatorname{sgn}\left(\sum_{i=1}^n y_i \alpha_i k_\gamma(x_i,x') + \rho\right)$, qui est la forme de la function apprise par un SVM à noyau gaussien \o/. 





# Pour aller plus loin
* l'algorithme d'optimisation utilisé dans Spark
	* Jin Yu, S.V. N. Vishwanathan, Simon Günter, Nicol N. Schraudolph. A Quasi-Newton Approach to Nonsmooth Convex Optimization Problems in Machine Learning. Journal of Machine Learning Research 11 (2010). p. 1–57.
* Algorithmes d'optimisation pour SVM et leur complexité
	* Large-Scale Kernel Machines. Edited by Léon Bottou, Olivier Chapelle, Dennis DeCoste and Jason Weston. The MIT Press.
	* Transparents d'Olivier Chapelle : [http://helper.ipam.ucla.edu/publications/sews2/sews2_7130.pdf](http://helper.ipam.ucla.edu/publications/sews2/sews2_7130.pdf)
* Version distribuée (d'une variante des SVM)
	* Chieh-Yen Lin, Cheng-Hao Tsai, Ching-Pei Lee, Chih-Jen Lin. Large-scale logistic regression and linear support vector machines using spark. IEEE International Conference on Big Data (2014). [https://www.csie.ntu.edu.tw/~cjlin/papers/spark-liblinear/spark-liblinear.pdf](https://www.csie.ntu.edu.tw/~cjlin/papers/spark-liblinear/spark-liblinear.pdf)
* Attributs de Fourrier aléatoires
	* Ali Rahimi and Ben Recht. Random Features for Large-Scale Kernel Machines. Advances in Neural Information Processing Systems (NIPS'07).

