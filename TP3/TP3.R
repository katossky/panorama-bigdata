install.packages("datastructures")
install.packages("microbenchmark")
install.packages("ggplot2")
install.packages("sparklyr")
install.packages("dplyr")
install.packages("tidyr")

library(datastructures)
library(microbenchmark)
library(ggplot2)
library (sparklyr)
library(dplyr)
library(tidyr)

# Va contenir les données inférieures à la médiane courante
# Les tas (heap) sont une structure où l'élément le plus petit est en haut. On a besoin de l'odre
# inverse, alors on va mettre l'opposé des nombre dans ce tas
min_heap <- binomial_heap("numeric")

# Va contenir les données supérieures à la médiane courante
max_heap <- binomial_heap("numeric")
max_heap <- insert(max_heap, 1.0, "")


update_mediane <- function(new_element, min_heap, max_heap ) {
  if (new_element >= peek(max_heap) || size(max_heap)==0) {
    # On est plus grand que le min des max alors on va dans les max
    max_heap <- insert(max_heap, new_element, new_element)
  } else {
    min_heap <- insert(min_heap, -new_element, -new_element)
  }
  
  #Si différence des tailles > 1, besoin d'un rééquilibrage
  if(size(min_heap) - size(max_heap) > 1){
    #Il manque des éléments dans max_heap
    transfered_element <- -pop(min_heap)[[1]]
    max_heap <- insert(max_heap, transfered_element, transfered_element)
  } else if ( size(max_heap) - size(min_heap) > 1){
    transfered_element <- -pop(max_heap)[[1]]
    min_heap <- insert(min_heap, transfered_element, transfered_element)
    
  }
  
  
  # Calcul de la mediane
  mediane <- NA
  if (size(min_heap) == size(max_heap)){
    # La mediane est la moyenne des racines des tas
    mediane <- (peek(max_heap)[[1]]  - peek(min_heap)[[1]])/2
  } else if (size(min_heap) < size(max_heap)){
    mediane <- peek(max_heap)[[1]]
  } else {
    mediane <- (-(peek(min_heap)[[1]]))
  }
  outputed <- c(mediane = mediane, min_heap = min_heap,max_heap=max_heap)
  return(outputed)
}

data <- rnorm(n=1000000, mean = 20, sd = 20)


# Calcul de la médiane step by step
custom_online_mediane <- function(size){
  min_heap <- binomial_heap("numeric")
  max_heap <- binomial_heap("numeric")
  
  for(i in 1:size){
    result <- update_mediane(data[i],min_heap,max_heap)
    min_heap <- result$min_heap
    max_heap   <- result$max_heap
  }
}

base_online_mediane <- function(size){
  for(i in 1:size){
    median(data[1:i])
  }
}

tm <- microbenchmark(custom_online_mediane(100000),
                     custom_online_mediane(100000),
                     times=10L)
autoplot(tm)


## SPARK
spark_install("2.0.1")
sc <- spark_connect(master="local")

spark_data<-sdf_copy_to(sc = sc, tibble(data), "spark_data")

spark_data %>% summarise(mediane = median(x = data))

DBI::dbGetQuery(sc, "SELECT PERCENTILE(data,0.5)  AS MEDIAN from spark_data ")

sdf_quantile(spark_data, "data", probabilities = c(0.5),
             relative.error = 1e-05) 

median_by_hand <- function(data){
  mediane <- sort(data)[floor(length(data)/2)]
}

tm <- microbenchmark(median(data),
                     sdf_quantile(spark_data, "data", probabilities = c(0.5),
                                  relative.error = 1e-05) ,
                     DBI::dbGetQuery(sc, "SELECT PERCENTILE(data,0.5)  AS MEDIAN from spark_data "),
                     quantile(data,  probs = c(0.5)),
                     median_by_hand(data) ,     
                     times=50L)
autoplot(tm)
