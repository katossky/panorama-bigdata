# devtools::install_github("collectivemedia/tictoc")
library(tictoc)
library(ggplot2)
library(tidyr)
library(dplyr)

# matrix data size / time_mean / time_median
times <- matrix(data = NA, nrow = 0, ncol = 4)

profiling <- function(size) {
  time <- numeric()
  time[1] <- size
  # Data aquisition
  start_time <- Sys.time()
  data <- rnorm(size, 50,20)
  end_time <- Sys.time()
  time[2]<- end_time-start_time
  
  # Mean
  start_time <- Sys.time()
  mean(data)
  end_time <- Sys.time()
  time[3] <- end_time-start_time
  
  # Median
  start_time <- Sys.time()
  median(data)
  end_time <- Sys.time()
  time[4]<- end_time-start_time
  
  return(time)
}

for(i in 1:1000){
  size <- 1000*i
  times <- rbind(times, profiling(size))
}
colnames(times) <- c("size", "data_generation", "mean", "median")


as.data.frame(times) %>%
  pivot_longer(-size, names_to="step", values_to="time") %>%
  ggplot(aes(x=size)) + 
    geom_line(aes(y=time, colour=step), size = 1) + 
    labs(title="La génération des données prend le plus de temps", 
         subtitle="Temps des différentes étapes de notre code", 
         y="Temps en s",
         x="Taille des données") +  # title and caption
    theme()+
    theme_minimal() 
