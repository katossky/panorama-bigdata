<!-- COURS 2

[QCM]

Parallelisation = multi-threading
> local vs. distributed execution
> shared vs. distributed memory

We focus here on local parallisation ; next course is on distributed.

Limits of parallelisation:
- communication time / orchestration
- race conditions, deadlocks and other resource sharing issues

Map Reduce
Ex: avec le gros livre coupé en plusieurs + exemple 

Trade-off of the task size (small => locally short but a lot of communication / orchestration, and vice-versa).




Focus on GPU (graphic processing unit) and TPU (tensor processing unit)

2-3 exemples

## How to parallelize in practice? (cours de Matthieu)

Ex1: Going from a naive R implementation to
1. Parallelisation with `R` (locally)
2. Using GPU with R
3. Optimization in R (if possible)
4. Going lower level 1 (C)
5. Going lower level 2 (shell)

## When to paralleize easily? (Embarassingly parallel problems)

Ex2a: repeat the same procedure k times (ex: brute force ; k-fold validation)

Ex2b: inside many algorithms, some parts consist in repeating a procedure k times

## Is it always possible to parallelize?

Ex3a: Concieving an parallizable computation (median)

-> comment un humain calcule une médiane ?
-> comment on caclul la médiane de façon classique?
-> est-ce que ça se distribue? si non comment fait-on pour y remédier?
-> algo distribué
-> regarder le trade-off cas emprique sur R

Ex3b: Gradient descent

Ex3c: Something not possible to parallelize ?