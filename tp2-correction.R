# Ex 3.1
library(dplyr)
library(RPostgreSQL)

pw <- "YojCqLr3Cnlw6onuzHU3" # Do not change the password !

drv <- dbDriver("PostgreSQL") # loads the PostgreSQL driver.
# (Needed to query the data)

# This is the proper connection.
# The same object will be used each time we want to connect to the database.
con <- dbConnect(drv, dbname = "postgres",
                 host = "database-1.c5bqsgv9tnea.eu-west-3.rds.amazonaws.com", port = 5432,
                 user = "postgres", password = pw)

rm(pw) # We don't need the password anymore.

dbExistsTable(con, "flight") 


import <- function(n){
  dbGetQuery(con, paste("SELECT * FROM flight LIMIT", n))
}

count <- function(N){ # <----------- DO NOT MIX N AND n !
  
  COUNTS <- data.frame(
    year  = integer(),
    month = integer(), 
    count = integer()
  )
  
  n <- 0
  
  for (i in 1:N) { # <---------- CHANGED!!!!!!!
    
    flight    <- FLIGHTS[i,]
    selection <- COUNTS$year == flight$year & COUNTS$month == flight$month
    
    if(nrow(COUNTS[selection,]) > 0) {
      
      COUNTS[selection, "count"] <- COUNTS[selection, "count"]+1
      
    }else{
      
      n <- n+1
      
      COUNTS[n, "year"]  <- flight$year
      COUNTS[n, "month"] <- flight$month
      COUNTS[n, "count"] <- 1
    }
  }
  return(COUNTS) # <---------- CHANGED!!!!!!!
}

rolling_avg <- function(N){
  PASSENGERS_adjusted <- tibble()
  
  # Passengers per day
  PASSENGERS <- FLIGHTS[1:N,] %>% # <------------ CHANGED!
    group_by (year, month, day) %>%
    summarise (passengers = sum(passengers)) %>%
    arrange(year, month, day)
  
  # 5-days rolling average. Begins at day 5.
  for (i in 5:nrow(PASSENGERS)) {
    
    n <- 0
    for(j in (i-4):i) n <- n + PASSENGERS$passengers[j]
    
    new_row <- tibble(
      year          = PASSENGERS$year[i],
      month         = PASSENGERS$month[i],
      day           = PASSENGERS$day[i],
      passengers    = PASSENGERS$passengers[i],
      passengers_w5 = n/5
    )
    
    PASSENGERS_adjusted <- bind_rows(PASSENGERS_adjusted, new_row)
  }
  
  # 10-days rolling average. Begins at day 10.
  for (i in 10:nrow(PASSENGERS)) {
    
    n <- 0
    for(j in (i-9):i) n <- n + PASSENGERS$passengers[j]
    
    PASSENGERS_adjusted[i-5, "passengers_w10"] <- n/10
  }
  
  return(PASSENGERS_adjusted)
  
}


rolling_reg <- function(N){
  
  variables <- c("seats", "passengers", "freight", "mail", "distance")
  betas     <- numeric()
  DATA   <- FLIGHTS[1:N,] %>% arrange(year, month, day) # <------ CHANGED
  
  for (i in 1000:nrow(DATA)) { # <------ CHANGED
    X <- data.matrix(DATA[(i-999):i, variables]) # <------ CHANGED
    X <- cbind(intercept=1, X)
    Y <- matrix(DATA$payload[(i-999):i], nrow = 1000, ncol = 1) # <------ CHANGED
    betas <- cbind(betas, solve(t(X)%*% X) %*% t(X) %*% Y)
  }
  rownames(betas) <- c("intercept", "seats", "passengers", "freight", "mail", "distance")
  betas[,1:10]
}

FLIGHTS <- import(2000)
count(2000)
rolling_avg(2000)
rolling_reg(2000)

library(microbenchmark)
timing_import <- microbenchmark(
  times = 10,
  FLIGHTS <- import(n=250),
  FLIGHTS <- import(n=500),
  FLIGHTS <- import(n=1000),
  FLIGHTS <- import(n=2500),
  FLIGHTS <- import(n=5000),
  FLIGHTS <- import(n=10000),
  FLIGHTS <- import(n=15000)
)
library(ggplot2)
autoplot(timing_import) # install.package("ggplot2")
table_timing_import <- print(timing_import)

plot(
  x = c(250,500,1000,2500,5000,10000,15000),
  y = table_timing_import$median,
  ylim=c(0,8),
  xlab = "Nombre de lignes",
  ylab = "Temps (s)",
  main = "Complexité empirique en temps"
)

timing_count <- microbenchmark(
  times = 10,
  count(N=250),
  count(N=500),
  count(N=1000),
  count(N=2500),
  count(N=5000),
  count(N=10000),
  count(N=15000)
)
autoplot(timing_count) # install.package("ggplot2")
table_timing_count <- print(timing_count)

plot(
  x = c(250,500,1000,2500,5000,10000,15000),
  y = table_timing_count$median,
  #ylim=c(0,8),
  xlab = "Nombre de lignes",
  ylab = "Temps (ms)",
  main = "Fonction count",
  sub = "Complexité empirique en temps"
)





library(profmem)

mem_import <- list()
mem_import[[1]] <- profmem(FLIGHTS <- import(n=250))
mem_import[[2]] <- profmem(FLIGHTS <- import(n=500))
mem_import[[3]] <- profmem(FLIGHTS <- import(n=1000))
mem_import[[4]] <- profmem(FLIGHTS <- import(n=2500))
mem_import[[5]] <- profmem(FLIGHTS <- import(n=5000))
mem_import[[6]] <- profmem(FLIGHTS <- import(n=10000))
mem_import[[7]] <- profmem(FLIGHTS <- import(n=15000))

plot(
  x = c(250,500,1000,2500,5000,10000,15000),
  y = unlist(lapply(mem_import, function(e) sum(e$bytes)))
)



# 4.1

import2 <- function(n){
  dbGetQuery(con, paste(
    "SELECT passengers, year, month, day,",
    "payload, distance, freight, seats",
    "FROM flight LIMIT", n
  ))
}
library(microbenchmark)
timing_import2 <- microbenchmark(
  times = 10,
  FLIGHTS <- import2(n=250),
  FLIGHTS <- import2(n=500),
  FLIGHTS <- import2(n=1000),
  FLIGHTS <- import2(n=2500),
  FLIGHTS <- import2(n=5000),
  FLIGHTS <- import2(n=10000),
  FLIGHTS <- import2(n=15000)
)

autoplot(timing_import2) # install.package("ggplot2")
table_timing_import2 <- print(timing_import2)

plot(
  type="l",
  x = c(250,500,1000,2500,5000,10000,15000),
  y = table_timing_import$median,
  ylim=c(0,8)
)

lines(
  x = c(250,500,1000,2500,5000,10000,15000),
  y = table_timing_import2$median/1000,
  col="red"
)

# 4.2

# On peut exécuter toute la section COUNTS
# dans la base de données.

# SELECT COUNT(*), year, month FROM flight GROUP BY year, month

dbGetQuery(con, "SELECT COUNT(*), year, month FROM flight GROUP BY year, month")

# 4.3

table(FLIGHTS$year,  FLIGHTS$month)

with(FLIGHTS, table(year, month))

FLIGHTS %>% # version dplyr
  group_by(year, month) %>%
  summarize(n=n())

library(dbplyr)
tbl(con, "flight") %>%
  group_by(year, month) %>%
  summarize(n=n()) %>%
  collect()

# 5.1

n <- 100
bench::mark(
  vect     = {v <- cumprod(1:n)},
  non_vect = {v<-1; for(i in 2:n) v[i] <- v[i-1]*i ; v}
)

#

my_cumsum <- sum(PASSENGERS$passengers[1:10])

for (i in 11:nrow(PASSENGERS)) {
  
  my_cumsum <- my_cumsum + PASSENGERS$passengers[i] - PASSENGERS$passengers[i-10]
  
  PASSENGERS_adjusted[i-5, "passengers_w10"] <- my_cumsum/10
}

#

bench::mark(
  vect           ={v <- rep(1,n)},
  preallocate    ={v <- numeric(n) ; for(i in 1:n) v[i] <- 1 ; v},
  no_preallocate ={v <- numeric() ; for(i in 1:n) v[i] <- 1 ; v},
  concatenate    ={v <- numeric() ; for(i in 1:n) v <- c(1,v); v}
)




library(foreach)               # Parallel for loops
library(parallel)              # Interface between R and multiple cores
library(doParallel)            # Interface between foreach and parallel
detectCores()                  # How many cores are available ?
registerDoParallel(cores=2)    # Number of cores you want to work with
library(tictoc)
tic()
foreach(i=1:10) %dopar% Sys.sleep(1)
toc()





rolling_reg2 <- function(N){
  
  variables <- c("seats", "passengers", "freight", "mail", "distance")
  betas     <- numeric()
  DATA   <- FLIGHTS[1:N,] %>% arrange(year, month, day) # <------ CHANGED
  
  beta = foreach(i=1000:nrow(DATA), .combine = cbind) %dopar% { # <------ CHANGED
    X <- data.matrix(DATA[(i-999):i, variables])
    X <- cbind(intercept=1, X)
    Y <- matrix(DATA$payload[(i-999):i], nrow = 1000, ncol = 1) # <------ CHANGED
    solve(t(X)%*% X) %*% t(X) %*% Y
  }
  
  return(beta)
}

microbenchmark(
  rolling_reg(N=1010),
  rolling_reg2(N=1010)
)

rownames(betas) <- c("intercept", "seats", "passengers", "freight", "mail", "distance")
betas[,1:10]