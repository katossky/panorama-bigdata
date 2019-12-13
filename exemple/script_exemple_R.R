install.packages("sparklyr")
install.packages("dplyr")
install.packages("ggplot2")

library(sparklyr)
library(dplyr)
library(ggplot2)
Sys.setenv(SPARK_HOME="/usr/lib/spark")
config <- spark_config()
sc <- spark_connect(master = "yarn-client", config = config, version = '2.4.4')

rd_1<-spark_read_csv(sc,name = "gdelt",path = "s3://gdelt-open-data/v2/events/20150218230000.export.csv",header = T,delimiter = "\t")
