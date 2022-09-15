# Mini Projet Jenkins : CICD du site web statique

## Objectif
Ce projet a pour but de mettre en place un pipeline complet cicd sur une application donnée, que vous devrez conteneuriser au préalable.
Il faudra refaire exactement les même étapes que celles vu dans le cours, à quelques différences prêt, nottament le déploiement à faire sur des serveurs provisionné à l'avance. il faudra utiliser ansible pour déployer l'application.

## L'application en question
L'application est un site web statique disponible [à cette adresse](https://github.com/diranetafen/static-website-example.git)

### Instructions
- Un squelette de Dockerfile  vous est fourni, il faut le compléter et lancer le build de l'image
 - Pour lancer le conteneur après le build, voici un exemple de commande : 
    ```
    docker run --name cont_name -d -e PORT=80 -p 80:80 ${ID_DOCKERHUB}/$IMAGE_NAME:$IMAGE_TAG 
    ```    
- Le déploiement en staging et production sera fait sur des VMs et non dans Heroku comme vu dans le cours
- On utilisera **Ansible** pour se faciliter la tâche de déploiement
    - Qui dit ansible dit créer des playbooks dans le repos git, celà sera votre mission supplémentaire
- Pour vous aider, un **Vagranfile** vous est fourni, ce dernier déploie : 
    - **Le serveur jenkins**, avec **docker** et **ansible** installé sur ce dernier
    - Les deux serveurs de Staging et de Production, aucun outil d'installé sur ces serveurs
    - Les trois serveurs sont joignables au niveau réseau

## Aide : Pour la partie déploiement avec ansible uniquement
- Le répertoire **ressources ansible** contient des éléments pour vous aider
- Un exemple d'inventaire (**hosts.yml**), **ansible.cfg**, **host_vars** et **group_vars** sont fournis, vous pouvez vous en inspirer...
- Le playbook d'installation de docker (**docker.yml**) est fourni.
- Un utilisateur **jenkins** existe sur les 3 machines crées, il sera utilisé comme user de connexion ansible
- Le répertoire personnel du user jenkins est **/var/lib/jenkins**  sur les 3 serveurs
- Ce user jenkins est configuré en **nologin** uniquement sur le serveur jenkins, c'est à dire que par défaut, vous ne pouvea pas vous logguer avec un **su jenkins**
- Cet utilisateur **jenkins** ne possède pas de mot de passe, mais **une paire de clés ssh**.
    - Le couple de clés se trouve dans **/var/lib/jenkins/.ssh**
    - La clés publique est dépa déposée sur les serveurs **worker1** et **worker2** dans le fichier **authorized_keys**
    - Pour passer la clés dans les commandes ansible, utiliser l'option : **--private-key <fichier de la clés privée>**
        * Example : 
        ```
        ansible all -m ping --private-key /var/lib/jenkins/.ssh/id_rsa 
        ```                
- La clés privée poura être rajoutée comme **secret file**  dans le serveur jenkins, et être récupérée dans une variable.
    * Exemple : 
    ```
            PRIVATE_KEY = credentials('private_key')
    ```
    !!! - Cette variable PRIVATE_KEY contient le chemin vers le fichier et non le contenu du fichier            
- Cette clé privée  pourrait être passée dans les commandes ansible pour se connecter aux machines, vous pouvez la récupéer dans votre projet si vous le souhaiter (c'est pas obloigatoire), comme suit : 
```
    cp $PRIVATE_KEY  ./id_rsa
    chmod 600 id_rsa
```        

### Corrigé
Un corrigé est disponible [ici](https://github.com/ulrichmonji/ib-cicd-static-website.git)