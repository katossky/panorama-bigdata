#!/bin/bash
set -x -e

# AWS EMR bootstrap script 
# for installing RStudio (and Shiny) with SparkR, SparklyR, etc  on AWS EMR 4.x and 5.x
#
# 2014-09-24 - schmidbe@amazon.de initial version for RHadoop packages and RStudio
# 2015-07-14 - Tom Zeng tomzeng@amazon.com, modified on top of Christopher Bozeman's "--sparkr" change to add "--sparkr-pkg"
# 2015-07-29 - Tom Zeng tomzeng@amazon.com, converted to AMI 4.0.0 compatible
# 2016-01-15 - Tom Zeng tomzeng@amazon.com, converted to AMI 4.2.0 compatible and added shiny
# 2016-10-07 - Tom Zeng tomzeng@amazon.com, added Sparklyr and improved install speed by 2-3x
# 2016-11-04 - Tom Zeng tomzeng@amazon.com, added RStudio 1.0, and used function rather than separate script for child process, removed --sparkr-pkg
# 2017-05-26 - Tom Zeng tomzeng@amazon.com, fixed the Shiny install typo, thanks to David Howell for spotting it
# 2018-09-23 - TOm Zeng tomzeng@amazon.com, fixed issues with the R 3.4 upgrade, and added CloudyR


# Usage:
# --no-rstudio - don't install rstudio-server
# --rstudio-url - the url for the RStudio RPM file
# --sparklyr - install RStudio's sparklyr package
# --sparkr - install SparkR package
# --shiny - install Shiny server
# --shiny-url - the url for the Shiny RPM file
#
# --user - set user for rstudio, default "hadoop"
# --user-pw - set user-pw for user USER, default "hadoop"
# --rstudio-port - set rstudio port, default 8787
#
# --rexamples - add R examples to the user home dir, default false
# --rhdfs - install rhdfs package, default false
# --plyrmr - install plyrmr package, default false
# --no-updateR - don't update latest R version
# --latestR - install latest R version, default false (build from source - caution, may cause problem with RStudio)
# --cloudyr - install the CloudyR packages

# check for master node
IS_MASTER=false
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
  IS_MASTER=true
fi

# error message
error_msg ()
{
	echo 1>&2 "Error: $1"
}

# get input parameters
RSTUDIO=true
SHINY=false
REXAMPLES=false
USER="hadoop"
USERPW="hadoop"
PLYRMR=false
RHDFS=false
UPDATER=true
LATEST_R=false
RSTUDIOPORT=8787
SPARKR=false
SPARKLYR=false
RSTUDIO_URL="https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.5033-x86_64.rpm"
MIN_USER_ID=400 # default is 500 starting from 1.0.44, EMR hadoop user id is 498

while [ $# -gt 0 ]; do
	case "$1" in
		--sparklyr)
			SPARKLYR=true
			;;
  	--rstudio)
      RSTUDIO=true
  		;;
  	--rstudio-url)
      shift
      RSTUDIO_URL=$1
  		;;
		--no-rstudio)
			RSTUDIO=false
			;;
  	--updateR)
      UPDATER=true
  		;;
		--no-updateR)
			UPDATER=false
			;;
		--latestR)
			LATEST_R=true
			UPDATER=false
			;;
    --sparkr)
    	SPARKR=true
    	;;
    --rstudio-port)
      shift
      RSTUDIOPORT=$1
      ;;
		--user)
		   shift
		   USER=$1
		   ;;
 		--user-pw)
 		   shift
 		   USERPW=$1
 		   ;;
		-*)
			# do not exit out, just note failure
			error_msg "unrecognized option: $1"
			;;
		*)
			break;
			;;
	esac
	shift
done

if [ "$IS_MASTER" = true ]; then
# signal to other BAs that this BA is running
date > /tmp/rstudio_sparklyr_emr5.tmp
fi

export MAKE='make -j 8'
sudo yum install -y xorg-x11-xauth.x86_64 xorg-x11-server-utils.x86_64 xterm libXt libX11-devel libXt-devel libcurl-devel git compat-gmp4 compat-libffi5
sudo yum install R-core R-base R-core-devel R-devel -y

# install latest R version from AWS Repo
if [ "$UPDATER" = true ]; then
  sudo yum update R-core R-base R-core-devel R-devel -y
  
  if [ -f /usr/lib64/R/etc/Makeconf.rpmnew ]; then
    sudo cp /usr/lib64/R/etc/Makeconf.rpmnew /usr/lib64/R/etc/Makeconf
  fi
  if [ -f /usr/lib64/R/etc/ldpaths.rpmnew ]; then
    sudo cp /usr/lib64/R/etc/ldpaths.rpmnew /usr/lib64/R/etc/ldpaths
  fi
fi

# create rstudio user on all machines
# we need a unix user with home directory and password and hadoop permission
if [ "$USER" != "hadoop" ]; then
  sudo adduser $USER
fi
sudo sh -c "echo '$USERPW' | passwd $USER --stdin"

mkdir /mnt/r-stuff
cd /mnt/r-stuff


# update to latest R version
if [ "$LATEST_R" = true ]; then
  pushd .
	mkdir R-latest
	cd R-latest
	wget http://cran.r-project.org/src/base/R-latest.tar.gz
	tar -xzf R-latest.tar.gz
	sudo yum install -y gcc gcc-c++ gcc-gfortran
	sudo yum install -y readline-devel cairo-devel libpng-devel libjpeg-devel libtiff-devel
	cd R-3*
	./configure --with-readline=yes --enable-R-profiling=no --enable-memory-profiling=no --enable-R-shlib --with-pic --prefix=/usr --with-x --with-libpng --with-jpeglib --with-cairo --enable-R-shlib --with-recommended-packages=yes
	make -j 8
	sudo make install
  sudo su << BASH_SCRIPT
echo '
export PATH=${PWD}/bin:$PATH
' >> /etc/profile
BASH_SCRIPT
  popd
fi

sudo sed -i 's/make/make -j 8/g' /usr/lib64/R/etc/Renviron

# set unix environment variables
sudo su << BASH_SCRIPT
echo '
export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_CMD=/usr/bin/hadoop
export HADOOP_STREAMING=/usr/lib/hadoop-mapreduce/hadoop-streaming.jar
export JAVA_HOME=/etc/alternatives/jre
' >> /etc/profile
BASH_SCRIPT
sudo sh -c "source /etc/profile"

# fix hadoop tmp permission
sudo chmod 777 -R /mnt/var/lib/hadoop/tmp

# fix java binding - R and packages have to be compiled with the same java version as hadoop
sudo R CMD javareconf


# install rstudio
# only run if master node
if [ "$IS_MASTER" = true -a "$RSTUDIO" = true ]; then
  # install Rstudio server
  # please check and update for latest RStudio version

  RSTUDIO_FILE=$(basename $RSTUDIO_URL)
  wget $RSTUDIO_URL
  sudo yum install --nogpgcheck -y $RSTUDIO_FILE
  # change port - 8787 will not work for many companies
  sudo sh -c "echo 'www-port=$RSTUDIOPORT' >> /etc/rstudio/rserver.conf"
  sudo sh -c "echo 'auth-minimum-user-id=$MIN_USER_ID' >> /etc/rstudio/rserver.conf"
  sudo perl -p -i -e "s/= 5../= 100/g" /etc/pam.d/rstudio
  sudo rstudio-server stop || true
  sudo rstudio-server start
fi

# install required packages
sudo R --no-save << R_SCRIPT
install.packages(c('devtools', 'DBI', 'ggplot2', 'dplyr', 'R.methodsS3', 'RPostgreSQL', 'datastructures'),
repos="http://cran.rstudio.com")
# here you can add your required packages which should be installed on ALL nodes
# install.packages(c(''), repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
R_SCRIPT



# the follow code will spawn a child process which waits for dependencies to be installed before proceed
child_process() {

if [ "$SPARKR" = true ] || [ "$SPARKLYR" = true ]; then 
cat << 'EOF' > /tmp/Renvextra
JAVA_HOME="/etc/alternatives/jre"
HADOOP_HOME_WARN_SUPPRESS="true"
HADOOP_HOME="/usr/lib/hadoop"
HADOOP_PREFIX="/usr/lib/hadoop"
HADOOP_MAPRED_HOME="/usr/lib/hadoop-mapreduce"
HADOOP_YARN_HOME="/usr/lib/hadoop-yarn"
HADOOP_COMMON_HOME="/usr/lib/hadoop"
HADOOP_HDFS_HOME="/usr/lib/hadoop-hdfs"
YARN_HOME="/usr/lib/hadoop-yarn"
HADOOP_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"
YARN_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"

HIVE_HOME="/usr/lib/hive"
HIVE_CONF_DIR="/usr/lib/hive/conf"

HBASE_HOME="/usr/lib/hbase"
HBASE_CONF_DIR="/usr/lib/hbase/conf"

SPARK_HOME="/usr/lib/spark"
SPARK_CONF_DIR="/usr/lib/spark/conf"

PATH=${PWD}:${PATH}
EOF
cat /tmp/Renvextra | sudo  tee -a /usr/lib64/R/etc/Renviron

# wait SparkR file to show up
while [ ! -f /var/run/spark/spark-history-server.pid ]
do
  sleep 5
done

fi

# install SparkR or the out-dated SparkR-pkg
if [ "$SPARKR" = true ]; then 
  sudo mkdir /mnt/spark
  sudo chmod a+rwx /mnt/spark
  if [ -d /mnt1 ]; then
    sudo mkdir /mnt1/spark
    sudo chmod a+rwx /mnt1/spark
  fi
  
  sudo R --no-save << R_SCRIPT
  library(devtools)
  install('/usr/lib/spark/R/lib/SparkR')
  # here you can add your required packages which should be installed on ALL nodes
  # install.packages(c(''), repos="http://cran.rstudio.com", INSTALL_opts=c('--byte-compile') )
R_SCRIPT

fi

if [ "$SPARKLYR" = true ]; then
  sudo R --no-save << R_SCRIPT
  library(devtools)
  devtools::install_github("rstudio/sparklyr")
  install.packages(c('nycflights13', 'Lahman', 'data.table'),
  repos="http://cran.rstudio.com" )
R_SCRIPT
fi

if [ "$IS_MASTER" = true ]; then

  sudo rm -f /tmp/rstudio_sparklyr_emr5.tmp

  #the following are needed only if not login in as hadoop
  if [ "$USER" != "hadoop" ]; then
    while [ ! -f /var/run/hadoop-hdfs/hadoop-hdfs-namenode.pid ]
    do
      sleep 5
    done
    sudo -u hdfs hdfs dfs -mkdir /user/$USER
    sudo -u hdfs hdfs dfs -chown $USER:$USER /user/$USER
    sudo -u hdfs hdfs dfs -chmod -R 777 /user/$USER
  fi

  sudo rstudio-server restart || true
fi # IS_MASTER

echo "rstudio server and packages installation completed"
} # end of child_process

child_process &
echo "bootstrap action completed after spwaning child process"
