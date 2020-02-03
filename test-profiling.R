library(ggplot2)
data.matrix(diamonds)
ggplot(diamonds)+geom_point(aes(x=carat, y=price))


library(gpuR)
library(microbenchmark)

n    <- 1000
x    <- matrix(rnorm(n^2,0,1),n,n)
gpux <- vclMatrix(x)

microbenchmark(times = 5,
  
  solve(x),
  solve(gpux)
)







system.time(
  for(i in 1:1e4){
    solve(x)
  })


library(gpuR)

set.seed(0)
x <- matrix(rnorm(10000,0,1),100,100)


system.time(
  for(i in 1:1e4){
    solve(gpux)
  })