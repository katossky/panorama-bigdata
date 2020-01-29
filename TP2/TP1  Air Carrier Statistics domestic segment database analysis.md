# TP1 : Air Carrier Statistics, domestic segment database analysis

You will find the code of this practical session on moodle.

## 1- Run the code

1. Run the code. 
2. Does it take time ? Any idea why ?
3. Update the code to make it run.

## 2- Code profiling

Now the code is running, we will try to find how many time take each part and prioritize our work

1. Add instruction to the code to calculate the time took by each part. This [page](https://www.r-bloggers.com/5-ways-to-measure-running-time-of-r-code/) can help you
2. What are the empirical time complexity of each part ? You can make a time-input size plot to help you.
3. What are the parts to optimize in priority ?

 ## 3- Optimization

1. SQL optimization

   1. Do we really need to do
   ```SQL
   	SELECT * FROM flight
   ```
   
   ?
   
   2. Can we transfer some treatments done in R to the DB ? If so, update the R code
   
2. Optimize the computation of the mean of flight number by month.

   1. With R statements
   2. With SQL statements
   3. Which is the faster ?

3. Think how sliding mean work. How can you change the code to optimize it ?
4. Statistics ?

## 4- On a bigger machine ?

Create a powerful EC2 instance to run you code (like a m5.2xlarge with 8 cores and 32 GB or Ram) to run your code and see if there is a big difference. To do this you have to

1. Create an EC2 instance with ubuntu on it

2. Authorize SSH connection to the instance (see : "Etablir une connexion SSH avec votre cluster" in the previous session)

3. Connect with SSH with a SSH tunnel from port 8157
4. Install and configure foxyproxy (see : "Installer FoxyProxy" in the previous session. It seems that foxyproxy doesn't work well with chrome, please use Firefox)
5. Install Rstudio server

```bash
# Install R
sudo apt-get install r-base
# To install local package
sudo apt-get install gdebi-core
# Donwload Rstudio server
wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5033-amd64.deb
# Install it
sudo gdebi rstudio-server-1.2.5033-amd64.deb
```

6. Create a Rstudio user

```bash
# Make User
sudo useradd -m rstudio-user
sudo passwd rstudio-user
```



6. Connect to Rstudio server : https://[public-DNS]:8787 with [public-DNS] the public DNS of the instance

You will find all the steps and explanation in the previous practical session. The main differences are :

- you don't create an EMR cluster, just an EC2 instance
- you have to connect to the EC2 instance with it DNS public address

## 5- On a spark cluster ?

Create a spark cluster, install Rstudio-server on it (previous session) and update the code to use spark function. Run the code.

- sparklyr documentation : https://spark.rstudio.com/