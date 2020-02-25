#!/bin/bash
set -x -e
sudo easy_install-3.6 --upgrade pip
sudo /usr/local/bin/pip3 install -U pandas scikit-learn statsmodels matplotlib seaborn joblibspark
sudo ln -sf /usr/bin/python3 /usr/bin/python