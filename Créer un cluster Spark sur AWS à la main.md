# Créer un cluster Spark sur AWS "à la main"

## Pré-requis

### 1- Générer une clef-ssh

- [ ] 1 : Générer une clef-ssh pour se connecter à vos instances

  - [ ] 1-1 : Connecter vous à votre compte amazon AWS
  - [ ] 1-2 : Dans la barre de recherche, cherche "EC2" et cliquez dessus
  - [ ] 1-3 : Dans le panneaux de gauche cherchez "Paires de clef" dans le section "Réseau et sécurité" et cliquez dessus. Cela vous amènera vers une image similaire.

  ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\step1.3 Paires de clés EC2 Management Console.png)

  - [ ] 1-4 : Cliquez sur "créer une paire de clés"
  - [ ] 1-5 : Donnez lui le nom "spark_cluster_TP" et cliquez sur créer
  - [ ] 1-6 : Enregistrer le fichier et ne le perdez pas !
  - [ ] 1-7 : Dans la barre de recherche windows cherchez "PuTTygen"
  - [ ] 1-8 : Cliquez sur Load
  - [ ] 1-9 : Allez dans le dossier ou vous avez sauvegarder votre clef. Elle ne doit pas encore apparaitre.
  - [ ] 1-10 : En bas à droite sélectionnez "All Files (*\.\*)"
  - [ ] 1-11 : Sélectionnez votre clef
  - [ ] 1-12 : Un message apparait sur PuTTygen, validez le
  - [ ] 1-13 : Cliquez sur "Save private key", puis sur "Oui" (on ne va pas mettre de passphrase)
  - [ ] 1-14 : Sauvegarder votre clef privée .ppk
  - [ ] 1-15 : Quittez PuTTygen
  - [ ] 1-16 : Vous avez fini de générer votre clef ssh.

## 2-Créer des machines virtuelles

- [ ] 2 : Créer l'instances EC2 qui serviront pour notre cluster.

  - [ ] 2-1 : Retournez sur votre navigateur web, et cliquez dans le volet à gauche sur "Instances" dans la section "Instances". Vous arriverez une un écran similaire, mais vous n'aurez pas d'instances déjà existantes normalement

  ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\step2 .1Instances EC2 Management Console.png)

  - [ ] 2-2 : Cliquer sur "Lancer une instance"

  - [ ] 2-3 : Voici les choix à faire

    - [ ] 2-3-1 : AMI :  Ubuntu Server 18.04 LTS (HVM), SSD Volume Type

    - [ ] 2-3-2 : Type d'instance : m5a.large

    - [ ] 2-3-3 : "Vérifier et lancer"

    - [ ] 2-3-4 : "Lancer"

    - [ ] 2-3-5 :  Sélectionnez la clef "spark_cluster_TP" et cochez la case

    - [ ] 2-3-6 : "Lancez des instances"

    - [ ] 2-3-7 : "Affichez les instances"

      Bravo vous venez de lancer votre première machine virtuelle sur amazon AWS.

  - [ ] 2-4 : Notez dans un fichier les informations suivantes :

    Master :

    - DNS public XXXX
    - DNS privé YYYY

    Vous trouverez ses informations dans la fenêtre du bas une fois votre instance sélectionnée 

  ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\step2.4 Instances EC2 Management Console.png)

  

  - [ ] 2-5 : Créez un modèle de lancement à partir de votre instance. Cela permettra de créer plus facilement des pour notre cluster

    - [ ] 2-5-1 : Sélectionnez votre instance
    - [ ] 2-5-2 : "Actions"
    - [ ] 2-5-3 : "Create Template From Instance"
    - [ ] 2-5-4 : Appelez votre template : "node_cluster_spark"
    - [ ] 2-5-5 : Pour la description : "Une instance pour notre cluster spark"
    - [ ] 2-5-6 : Descendez en bas de la page et "Créer un modèle de lancement"
    - [ ] 2-5-7 : En haut de la page cliquez sur "EC2"

  - [ ] 2-6 : Cliquez sur "Instances"

  - [ ] 2-7 : Lancer une machine worker

    - [ ] 2-7-1 :  Flèche vers le bas de "Lancer une instance", "Lancement d'un instance à partir d'un modèle"
    - [ ] 2-7-2 : Sélectionner votre modèle
    - [ ] 2-7-3 : Pour commencer on ne va créer qu'une nouvelle instance
    - [ ] 2-7-4 : Descendez en base de la page
    - [ ] 2-7-5 : "Lancer une instance à partir d'un modèle"

  - [ ] 2-8 : Retournez sur l'écran avec vos instances et sélectionner votre nouvelle instance (celle la plus bas)

  - [ ] 2-9 : Dans votre fichier ajoutez

    worker 1 : 

    - DNS public XXXX
    - DNS privé YYYY

  - [ ] 2-10 : Vous venez de créer vos deux premières instances EC2 qui vont servir de base à notre cluster.

### 3- Se connecter à nos machines virtuelles

- [ ] 3 : Se connecter à nos machines virtuelles

  - [ ] 3-1 : Ouvrez Putty 

  - [ ] 3-2 : Dans Host Name mettez : ubuntu@le dns public du master

  - [ ] 3-3 : Connexion ssh, port 22

  - [ ] 3-4 : Menu de gauche : Connection / SSH / Auth

  - [ ] 3-5 : Allez chercher votre clef privée .ppk

    ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\step3.5 putty.png)

  - [ ] 3-6 : Menu de gauche : session

  - [ ] 3-7 : Sauvegarder votre session avec le nom "spark-master"

  - [ ] 3-8 : Une fenêtre apparait, cliquez sur oui

  - [ ] 3-10 : Vous voilà connecter à votre master node, pour vous connecter à votre worker, ouvrez une autre fenêtre PuTTy, faite les mêmes étapes en utilisant le dns du worker

## 4 - Installer Java et Scala sur vos instances EC2

- [ ] 4 - Installer Java et Scala sur vos instances EC2

  L'installation de java et scala doit se faire sur chacun des machines !

  - [ ] 4-1 Ouvrez la fenêtre ssh qui vous connecte à votre master

  - [ ] 

  - [ ] 4-2 Installez java :

    - [ ] 4-2-1 : 

    ```shell
    sudo apt update
    sudo apt install openjdk-11-jre-headless
    ```

    - [ ] 4-2-2 : Quand on vous le demande appuyez sur Y puis Enter

    - [ ] 4-2-3 :

      ```shell
      java --version
      ```

      ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\step4.1 java.png)

    - [ ] 

  - [ ] 4-3 Installer scala :

    - [ ] 4-3-1 : 

      ```shell
      sudo apt install scala
      ```

    - [ ] 4-3-2 : Quand on vous le demande appuyez sur Y puis Enter

    - [ ] 4-3-3 : 

      ```shell
      scala -version
      ```

      ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\step4.3 scala.png)

  - [ ]  Voici un script synthétique 

    ```shell
    sudo apt update
    sudo apt install openjdk-11-jre-headless
    Y
    sudo apt install scala
    Y
    ```

  - [ ] 4-4 : Recommencer cette étape pour TOUTES vos machines !

### 5 - Configurer la connexion SSH entre vos machines

Nous allons maintenant configurer les connexion SSH entre vos machines pour que la machine maitre puisse contrôler les machine workers.

- [ ] 5-1 : Sur le master :

  - [ ] 5-1-1 : Installez openssh-server et openssh-client

    ```shell
    sudo apt install openssh-server openssh-client
    ```

  - [ ] 5-1-2 : Créer un couple de clefs RSA

    ```shell
    ssh-keygen -t rsa -P ""
    ```

    Appuyer sur entrer, votre clef est enregistrée dans ~/.ssh/id_rsa.pub

  - [ ] 5-1-3  : Copier la clef dans votre presse papier

    ````shell
    cat ~/.ssh/id_rsa.pub
    ````

    ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\5-3 rsa key.png)

- [ ] 5-2 : Sur les workers

  - [ ] 5-2-1 Ajouter la clef aux clefs autorisées

    ```shell
    cat >> ~/.ssh/authorized_keys
    [paste your clipboard contents]
    [ctrl+d to exit]
    ```

    Si vous avez copiez les commandes au dessus, vous allez devoir de nouveau allez chercher votre clef !

- [ ] 5-3 : Testez votre connexion sur le master

  ```
  ssh -i ~/.ssh/id_rsa ubuntu@DNS privé worker
  ```

  Tapez yes. Vous devez arrivez sur un terminal de ce genre

  ![](C:\Users\VEDA\Documents\2A\big data\panorama-bigdata\img\step7 ssh entre instances.png)

  Tapez 

  ````
  exit
  ````

  pour mettre fin à la connection ssh

- [ ] 5 -4 : Vous venez de configurer les connections ssh entre vos machines

## Installer Spark (enfin) 

- [ ] 6 : installez Spark sur chacune de vos machines

  - [ ] 6-1 : Télécharger Spark

    ```shell
    wget http://apache.crihan.fr/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz
    ```

  - [ ] 6-2 : Extraire l'archive, la déplacer dans /usr/local/spark et ajouter spark/bin  dans la variable PATH

    ```
    tar xvf spark-2.4.4-bin-hadoop2.7.tgz
    sudo mv spark-2.4.4-bin-hadoop2.7/ /usr/local/spark
    export PATH=/usr/local/spark/bin:$PATH
    ```

- [ ] 7 : Configurer le master pour qu'il garde trace des workers

  - [ ] 
    ```
    cd /
    cd /usr/local/spark/conf/
    nano spark-env.sh
    ```

  - [ ] ```
    export SPARK_MASTER_HOST=35.180.58.144
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
    ```

  - [ ] ````
    nano slaves
    ````

  - [ ] 