<!-- COURS 2

Parallelisation = multi-threading
> local vs. distributed execution
> shared vs. distributed memory

We focus here on local parallisation ; next course is on distributed.

Limits of parallelisation:
- communication time / orchestration
- race conditions, deadlocks and other resource sharing issues

Trade-off of the task size (small => locally short but a lot of communication / orchestration, and vice-versa).

Focus on GPU.

2-3 exemples

## How to parallelize in practice?

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
Ex3b: Gradient descent
Ex3b: Something not possible to parallelize ? 

-->