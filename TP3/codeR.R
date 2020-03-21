install.packages("RPostgres")

library(datastructures)
library(microbenchmark)
library(ggplot2)
library (sparklyr)
library(dplyr)
library(tidyr)
library(RPostgres)
library(tibble)
library(dplyr)
library(microbenchmark)
library(ggplot2)

install.packages("sparklyr")
library(sparklyr)
Sys.setenv(SPARK_HOME="/usr/lib/spark")
sc <- spark_connect(master="yarn-client")


pw <- "YojCqLr3Cnlw6onuzHU3" # Do not change the password !
drv <- dbDriver("PostgreSQL") # loads the PostgreSQL driver.
# (Needed to query the data)
# This is the proper connection.
# The same object will be used each time we want to connect to the
con <- dbConnect(drv, dbname = "postgres",
                 host = "tp-avion.c5bqsgv9tnea.eu-west-3.rds.amazonaws.com", port = 5432,
                 user = "postgres", password = pw)
rm(pw) # We don't need the password anymore.
dbExistsTable(con, "flight") # Check whether the "flight" table exist.

data <- dbGetQuery(con, "SELECT PASSENGERS FROM flight LIMIT 10000")

spark_data <-sdf_copy_to(sc,data, "spark_data" , overwrite = TRUE)

sdf_quantile(spark_data,"passengers",probabilities=c(0.5), relative.error = 1e-05) 

spark_data %>% summarise(median = median(passengers))

DBI::dbGetQuery(sc, "SELECT PERCENTILE(passengers,0.5) AS MEDIAN from spark_data")

test <- spark_data %>% arrange(passengers)

date_orderd <- sdf_collect(test)

date_orderd[5000,]

median_R <- function(){
  median(data$passengers)
}

median_by_hand <- function(data){
  mediane <- sort(data)[floor(length(data)/2)]
}

tm <- microbenchmark(median(data$passengers),
                     sdf_quantile(spark_data, "passengers", probabilities = c(0.5),
                                  relative.error = 1e-05) ,
                     DBI::dbGetQuery(sc, "SELECT PERCENTILE(passengers,0.5)  AS MEDIAN from spark_data "),
                     quantile(data$passengers,  probs = c(0.5)),
                     median_R() ,     
                     times=50L)

autoplot(tm)
tm


