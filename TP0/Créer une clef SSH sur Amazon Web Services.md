# Créer une clef SSH sur Amazon Web Services

## 1. Création d'une clef SSH

**SSH** (**S**ecure **SH**ell) permet de se connecter de façon sécurisée à un système Unix, Linux et Windows. Pour plus d'information, je vous conseille de lire le début de cette [page web ](https://doc.fedora-fr.org/wiki/SSH_:_Authentification_par_cl%C3%A9)

- [ ] 1-1 : Dans la barre de recherche, cherchez "EC2" et cliquez dessus  
  - [ ] 1-2 : Dans le panneaux de gauche cherchez "Paires de clef" (dans la section "Réseau et sécurité") et cliquez dessus.  
    - [ ] 1-3 : Cliquez sur "Créer une paire de clés"  
    
    - [ ] 1-4 : Donnez lui un nom (par ex: "spark_cluster_TP"),
    
  - [ ] 1-4 : Sélectionnez le format PPK, et cliquez sur "créer" si vous allez utiliser PuTTY (faites ce choix si vous êtes sur Windows)
  
  - [ ] 1-5 : Enregistrez le fichier et ne le perdez pas !  

       :warning: OU :warning:
    
  - [ ] 1-4-bis : Sélectionnez le format pem, et cliquez sur "créer" si vous allez utiliser OpenSSH (faites ce choix si vous compter utiliser de la ligne de commande)
    
  - [ ] Définissez les  autorisation de votre clef
  
       ````bash
       chmod 400 chemin/vers/ma/clef/ma_clef.pem
       ````
  
- [ ] 1-5 : Enregistrez le fichier et ne le perdez pas !  

## 2. Conversion au format PPK

:warning: Cette partie n'est utile que si vous avez une clef au format pem et que vous la voulez au format ppk.

- [ ] 2-1 : Dans la barre de recherche windows cherchez "PuTTygen"  
- [ ] 2-2 : Cliquez sur Load  
- [ ] 2-3 : Allez dans le dossier où vous avez sauvegardé votre clef. Elle ne doit pas encore apparaître.  
- [ ] 2-4 : En bas à droite sélectionnez "All Files (*\.\*)"  
- [ ] 2-5 : Sélectionnez votre clef  
- [ ] 2-6 : Un message apparait sur PuTTygen, validez le  
- [ ] 2-7 : Cliquez sur "Save private key", puis sur "Oui" (on ne va pas mettre de passphrase)  
- [ ] 2-8 : Sauvegardez votre clef privée .ppk  
- [ ] 2-9 : Quittez PuTTygen  
