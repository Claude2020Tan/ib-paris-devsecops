EAZYTRAINING DevOps  AWS EKS
============================================

Étape-01 : Introduction au DevOps
Comprendre les concepts DevOps
CI - Intégration Continue
CD - Déploiement continu ou livraison


En savoir plus sur les outils AWS qui nous aident à mettre en œuvre DevOps.
AWS CodeCommit
AWS CodeBuild
AWS CodePipeline


Étape-02 : Qu'allons-nous apprendre ?
Nous allons créer un référentiel ECR pour nos images Docker
Nous allons créer Code Commit Git Repository et archiver nos manifestes Docker et Kubernetes
Nous allons écrire un buildspec.ymlfichier qui finira par créer une image docker, la pousser vers le référentiel ECR et déployer le manifeste de déploiement k8s mis à jour sur le cluster EKS.
Pour réaliser tout cela, nous devons également créer ou mettre à jour quelques rôles

STS assume le rôle : EksCodeBuildKubectlRole
Politique en ligne : eksdevops-<prenom>-2022
Rôle CodeBuild : codebuild-eks-devops-<prenom>-for-pipe-service-role
Politique d'accès complet ECR : AmazonEC2ContainerRegistryFullAccess
Stratégie d'hypothèse STS : eks-codebuild-sts-assume-role
STS assume le rôle : EksCodeBuildKubectlRole
Étape-03 : vérification des prérequis
Nous allons déployer une application qui aura également un ALB Ingress Serviceet enregistrera également son nom DNS dans Route53 en utilisantExternal DNS
Ce qui signifie que nous devrions avoir les deux pods associés en cours d'exécution dans notre cluster.
kubectl get pods -n kube-system

# Verifier external-dns pod running in default namespace
kubectl get pods
Étape 04 : Créer un référentiel ECR pour nos images Docker d'application
Accédez à Services -> Elastic Container Registry -> Créer un référentiel
Nom : eks-devops-<prenom>-nginx
Immutabilité des balises : Activer
Scan On Push : Activer
Cliquez sur Créer un référentiel
Notez le nom du référentiel
# uri du repo
180789647333.dkr.ecr.us-east-1.amazonaws.com/eks-devops-<prenom>-nginx
Étape 05 : Créer un référentiel CodeCommit
Introduction à l'engagement de code
Créer un référentiel de validation de code avec le nom eks-devops-<prenom>-nginx
Créez des informations d'identification git à partir du service IAM et notez ces informations d'identification.
Clonez le référentiel git de Code Commit vers le référentiel local, pendant le processus, fournissez vos informations d'identification git générées pour vous connecter au référentiel git
git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/eks-devops-<prenom>-nginx
Copiez tous les fichiers de la section de cours 11-DevOps-with-AWS-Developer-Tools/Application-Manifests vers le référentiel local
buildspec.yml
Fichier Docker
app1
index.html
kube-manifests
01-DEVOPS-Nginx-Deployment.yml
02-DEVOPS-Nginx-NodePortService.yml
03-DEVOPS-Nginx-ALB-IngressService.yml
Commit code et Push to CodeCommit Repo
git status
git add .
git commit -am "1 Added all files"
git push
git status
Vérifiez la même chose sur CodeCommit Repository dans AWS Management Console.
Présentation des manifestes d'application
Manifestes d'application
buildspec.yml
Fichier Docker
app1
index.html
kube-manifests
01-DEVOPS-Nginx-Deployment.yml
02-DEVOPS-Nginx-NodePortService.yml
03-DEVOPS-Nginx-ALB-IngressService.yml
Étape 06 : Créer un rôle STS Assume IAM pour que CodeBuild interagisse avec AWS EKS
Dans un AWS CodePipeline, nous allons utiliser AWS CodeBuild pour déployer les modifications apportées à nos manifestes Kubernetes.
Cela nécessite un rôle AWS IAM capable d'interagir avec le cluster EKS.
Dans cette étape, nous allons créer un rôle IAM et ajouter une stratégie en ligne EKS:Describeque nous utiliserons dans l'étape CodeBuild pour interagir avec le cluster EKS via kubectl.
# Exporter l'id du compte
export ACCOUNT_ID=180789647333

# définit la policy
TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"

# Vérifiez dans la politique de confiance, votre identifiant de compte a été remplacé
echo $TRUST

# Créer un rôle IAM pour que CodeBuild interagisse avec EKS
aws iam create-role --role-name EksCodeBuildKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'

# Définir la politique en ligne avec l'autorisation eks Describe dans un fichier iam-eks-describe-policy
echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > /tmp/iam-eks-describe-policy

# Associer la politique en ligne à notre rôle IAM nouvellement créé
aws iam put-role-policy --role-name EksCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-eks-describe-policy

# Vérifiez la même chose sur la console de gestion
Étape 07 : Mettre à jour EKS Cluster aws-auth ConfigMap avec le nouveau rôle créé à l'étape précédente
Nous allons ajouter le rôle au aws-auth ConfigMappour le cluster EKS.
Une fois EKS aws-auth ConfigMapce nouveau rôle inclus, kubectl dans l'étape CodeBuild du pipeline pourra interagir avec le cluster EKS via le rôle IAM.
# Vérifiez ce qui est présent dans aws-auth configmap avant le changement
kubectl get configmap aws-auth -o yaml -n kube-system

# Exportez votre ID du compte
export ACCOUNT_ID=180789647333

# Définir la valeur RÔLE
ROLE="    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/EksCodeBuildKubectlRole\n      username: build\n      groups:\n        - system:masters"

# Obtenez les données configMap aws-auth actuelles et joignez-y de nouvelles informations de rôle
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml

# Corrigez le configmap aws-auth avec un nouveau rôle
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"

# Vérifier ce qui est mis à jour dans aws-auth configmap après modification
kubectl get configmap aws-auth -o yaml -n kube-system
Étape 08 : Passez en revue le fichier buildspec.yml pour CodeBuild et les variables d'environnement
Introduction à la construction de code
Obtenez une vue d'ensemble de haut niveau sur CodeBuild Service
Variables d'environnement pour CodeBuild
REPOSITORY_URI = 180789647333.dkr.ecr.us-east-1.amazonaws.com/eks-devops-<prenom>-nginx
EKS_KUBECTL_ROLE_ARN = arn:aws:iam::180789647333:role/EksCodeBuildKubectlRole
EKS_CLUSTER_NAME = eksdemo1
Réviser buildspec.yml
version : 0.2 
phases :
   installation :
     commandes :
      - echo "Phase d'installation - Rien à faire avec la dernière image Amazon Linux Docker pour CodeBuild qui contient tous les outils AWS - https://github.com/aws/aws-codebuild-docker-images/blob/master/al2/x86_64/standard /3.0/Dockerfile" 
  pre_build :
       commandes :
         # Balise d'image Docker avec date, heure et code Version source résolue 
        - TAG="$(date +%Y-%m-%d.%H.%M.%S).$ (echo $CODEBUILD_RESOLVED_SOURCE_VERSION | head -c 8)" 
        # Mettre à jour la balise Image dans notre manifeste de déploiement Kubernetes         
        - echo "Mettre à jour la balise Image dans kube-manifest..." 
        -sed -i 's@CONTAINER_IMAGE@'"$REPOSITORY_URI:$TAG"'@' kube-manifests/01-DEVOPS-Nginx-Deployment.yml 
        # Vérifier la version de l'AWS CLI         Build Docker Image 
      - echo "La compilation a commencé le `date`"
        - echo "Verify AWS CLI Version..." 
        - aws --version 
        # Connectez-vous au registre ECR pour que docker envoie l'image au référentiel ECR 
        - echo "Connectez-vous à Amazon ECR..." 
        - $(aws ecr get-login --no-include-email) 
        # Mettre à jour le répertoire d'accueil de la configuration de Kube 
        - export KUBECONFIG=$HOME/.kube/config 
  build :
     commands :
       # 
      - echo "Création de l'image Docker..." 
      - docker build --tag $REPOSITORY_URI : $TAG . 
  post_build :
     commandes :
       #Pousser l'image Docker vers le référentiel ECR 
      - echo "Construction terminée le `date`" 
      - echo "Pousser l'image Docker vers le référentiel ECR" 
      - docker push $REPOSITORY_URI:$TAG 
      - echo "Pousser l'image Docker vers ECR terminée - $REPOSITORY_URI:$TAG "     
      # Extraction des informations d'identification AWS à l'aide du STS Assume Role for kubectl 
      - echo "Définition des variables d'environnement liées à l'AWS CLI pour la configuration de Kube Config"           CREDENTIALS=$(aws sts assume-role --role-arn $EKS_KUBECTL_ROLE_ARN --role-session-name codebuild-kubectl --duration-seconds 900) 
      - export AWS_ACCESS_KEY_ID="$(echo ${CREDENTIALS} | jq -r '.Credentials.AccessKeyId')" 
      - exporter AWS_SECRET_ACCESS_KEY="$(echo ${CREDENTIALS} | jq -r '.Credentials.SecretAccessKey')" 
      - exporter AWS_SESSION_TOKEN="$(echo ${CREDENTIALS} | jq -r '.Credentials .SessionToken')" 
      - export AWS_EXPIRATION=$(echo ${CREDENTIALS} | jq -r '.Credentials.Expiration') 
      # Configurer kubectl avec notre cluster EKS               
      - echo "Mettre à jour la configuration de Kube"     
      - aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
      # Appliquez les modifications à notre application à l'aide de kubectl 
      - echo "Appliquer les modifications aux manifestes kube"             
      - kubectl apply -f kube-manifests/ 
      - echo "Terminé l'application des modifications aux objets Kubernetes"           
      ${AWS_ACCESS_KEY_ID}" ## Créer des artefacts que nous pouvons utiliser si nous voulons continuer notre pipeline pour d'autres étapes 
      - printf '[{"name":"01-DEVOPS-Nginx-Deployment.yml","imageUri":"%s"}]' $ REPOSITORY_URI:$TAG > build.json 
      # Commandes supplémentaires pour afficher vos identifiants       
      # - echo "La valeur des identifiants est... ${CREDENTIALS}"       
      # - echo "AWS_ACCESS_KEY_ID... ${AWS_ACCESS_KEY_ID}"             
      - echo "AWS_SECRET_ACCESS_KEY... $ {AWS_SECRET_ACCESS_KEY}"             
      # - echo "AWS_SESSION_TOKEN... ${AWS_SESSION_TOKEN}"             
      # - echo "AWS_EXPIRATION... $AWS_EXPIRATION"             
      # - echo "EKS_CLUSTER_NAME... $EKS_CLUSTER_NAME"             
artefacts :
   fichiers :
    - build.json    
    - kube-manifests/*
Étape 09 : Créer CodePipeline
Présentation de CodePipeline
Obtenez une vue d'ensemble de haut niveau sur CodePipeline Service
Créer un pipeline de code
Créer un pipeline de code
Allez dans Services -> CodePipeline -> Créer un pipeline
Paramètres du pipeline
Nom du pipeline : eks-devops-pipe
Rôle de service : nouveau rôle de service (laisser les valeurs par défaut)
Nom du rôle : renseigné automatiquement
Reposez tous les paramètres par défaut et cliquez sur Suivant
La source
Fournisseur source : AWS CodeCommit
Nom du référentiel : eks-devops-<prenom>-nginx
Nom de la succursale : maître
Modifier les options de détection : événements CloudWatch (laisser les valeurs par défaut)
Construire
Fournisseur de génération : AWS CodeBuild
Région : USA Est (Virginie du Nord)
Nom du projet : Cliquez sur Créer un projet
Créer un projet de construction
Paramétrage du projet
Nom du projet : eks-devops-cb-for-pipe
Description : Projet CodeBuild pour le pipeline EKS DevOps
Environnement
Image d'environnement : Image gérée
Système d'exploitation : Amazon Linux 2
Temps d'exécution : Standard
Image : aws/codebuild/amazonlinux2-x86_64-standard:3.0
Version de l'image : utilisez toujours la dernière version pour ce runtime
Type d'environnement : Linux
Privilégié : Activer
Nom du rôle : renseigné automatiquement
Configurations supplémentaires
Tout laisser aux valeurs par défaut sauf les variables d'environnement
Ajouter des variables d'environnement
REPOSITORY_URI = 180789647333.dkr.ecr.us-east-1.amazonaws.com/eks-devops-<prenom>-nginx
EKS_KUBECTL_ROLE_ARN = arn:aws:iam::180789647333:role/EksCodeBuildKubectlRole
EKS_CLUSTER_NAME = eksdemo1
Spécification de construction
laisser par défaut
Journaux
Nom du groupe : eks-deveops-cb-pipe
Nom du flux :
Cliquez sur Continuer vers CodePipeline
Nous devrions voir un messageSuccessfully created eks-devops-cb-for-pipe in CodeBuild.
Cliquez sur Suivant
Déployer
Cliquez sur Ignorer l'étape de déploiement
La revue
Passez en revue et cliquez sur Créer un pipeline
Étape 10 : Mettre à jour le rôle CodeBuild pour avoir accès à l'accès complet à ECR
La première exécution du pipeline échouera, car CodeBuild ne sera pas en mesure de télécharger ou de transférer l'image Docker nouvellement créée vers le référentiel ECR
Mettez à jour le rôle CodeBuild pour avoir accès à ECR afin de télécharger des images créées par codeBuild.
Nom du rôle : codebuild-eks-devops-<prenom>-for-pipe-service-role
Nom de la stratégie : AmazonEC2ContainerRegistryFullAccess
Apportez des modifications à index.html (mise à jour en tant que V2), localement et poussez la modification vers CodeCommit
git status
git commit -am "V2 Deployment"
git push
Vérifier les journaux CodeBuild
La nouvelle image doit être téléchargée sur ECR, vérifiez l'ECR avec la nouvelle date et heure de la balise d'image docker.
La construction échouera à nouveau à l'étape de post-construction dans la section STS Assume role. Corrigeons cela à l'étape suivante.
Étape 11 : Mettre à jour le rôle CodeBuild pour avoir accès au rôle d'hypothèse STS que nous avons créé à l'aide de la stratégie d'hypothèse de rôle STS
La construction doit échouer car CodeBuild n'a pas accès pour effectuer des mises à jour dans le cluster EKS.
Il ne peut même pas assumer le rôle STS Assume quoi que nous ayons créé.
Créer une stratégie d'hypothèse STS et l'associer au rôle CodeBuildcodebuild-eks-devops-<prenom>-for-pipe-service-role
Créer une stratégie de rôle STS
Accédez à Services IAM -> Stratégies -> Créer une stratégie
Dans l'onglet Éditeur visuel
Service : STS
Actions : Sous Écrire - SélectionnerAssumeRole
Ressources : spécifiques
Ajouter ARN
Spécifiez l'ARN pour le rôle : arn:aws:iam::180789647333:role/EksCodeBuildKubectlRole
Cliquez sur Ajouter
# Pour le rôle ARN, remplacez votre identifiant de compte ici, reportez-vous à l'étape 07 de la variable d'environnement EKS_KUBECTL_ROLE_ARN pour plus de détails
arn:aws:iam::<your-account-id>:role/EksCodeBuildKubectlRole
Cliquez sur Politique de révision
Nom : eks-codebuild-sts-assume-role
Description : CodeBuild pour interagir avec le cluster EKS afin d'effectuer des modifications
Cliquez sur Créer une politique
Associer la stratégie au rôle CodeBuild
Nom du rôle : codebuild-eks-devops-<prenom>-for-pipe-service-role
Politique à associer :eks-codebuild-sts-assume-role
Étape 12 : Apportez des modifications au fichier index.html
Apporter des modifications à index.html (mise à jour en V3)
Validez les modifications dans le référentiel git local et poussez vers codeCommit Repository
Surveiller le codePipeline
Testez en accédant à la page html statique
git status
git commit -am "V3 Deployment"
git push
Vérifier les journaux CodeBuild
Testez en accédant à la page html statique
http://devops.atosaws.com/app1/index.html
Étape 13 : Ajouter une modification au manifeste Ingress
Ajoutez une nouvelle entrée DNS et poussez les modifications et testez
03-DEVOPS-Nginx-ALB-IngressService.yml
# Avant 
    # DNS externe - Pour créer un jeu d'enregistrements dans Route53 
    external-dns.alpha.kubernetes.io/hostname : devops.atosaws.com   

# Après 
    # DNS externe - Pour créer un jeu d'enregistrements dans Route53 
    external-dns.alpha.kubernetes.io/hostname : devops.atosaws.com, devops2.atosaws.com       
Validez les modifications dans le référentiel git local et poussez vers codeCommit Repository
Surveiller le codePipeline
Testez en accédant à la page html statique
git status
git commit -am "V3 Deployment"
git push
Vérifier les journaux CodeBuild
Testez en accédant à la page html statique
http://devops2.atosaws.com/app1/index.html
Étape 14 : nettoyage
Supprimer tous les objets Kubernetes dans le cluster EKS
kubectl delete -f kube-manifests/
Supprimer le pipeline
Supprimer le projet CodeBuild
Supprimer le référentiel CodeCommit
Supprimer les rôles et les politiques créés