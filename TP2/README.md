# TP2 - Profilage de code, parallélisation, big data ?

Donnée avion http://stat-computing.org/dataexpo/2009/the-data.html

Code existant

Premier constat : c'est trop long 

Echantillonnage les données + profiling et on fait des graphs

Qu'est ce qui est long ?

Erreur grossière (filtrer les données en aval, select *, boucle avec écriture vecteur en R)

Accélérer le code

Boucle for parallélisable

Echantillonner puis intervalle de confiance (stat bitch !)

Astuce "algo" (faire du calcul vect en R)

Donnée sur une fenêtre de temps à la main

Directement en SQL pour certaines infos

Code avec 3 stats, comptage, moyenne glissante et reg ? chacune dans une boucle for. Optimisation de chaque stat. Besoin de boucle for à la fin ? 

