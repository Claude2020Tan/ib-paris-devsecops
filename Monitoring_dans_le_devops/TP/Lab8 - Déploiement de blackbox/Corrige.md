# Déploiement de blackbox

### 1 - Installation de l'exporter et surcharge du values.yaml
Installez le blackbox exporter Prometheus à l’aide du chart helm disponible sur le [repo Prometheus-community](https://github.com/helm/charts/tree/master/stable/prometheus-blackbox-exporter)

```
mkdir  -p ~vagrant/lab8 && cd ~vagrant/lab8
git clone https://github.com/eazytrainingfr/prometheus-training.git
cp  prometheus-training/sources/blackbox-exporter/*  .
helm install blackbox-exporter prometheus-community/prometheus-blackbox-exporter -f values.yaml
```
![blackbox exporter](images/blackbox-exporter.PNG)
Il est donc diponible sur le nodeport **30770**

### 2 - Surchargez les variables du chart avec le fichier values.yaml
C'est déja fait à la question précédente ...

### 3 - Prise en compte des modifications
Modifier la fichier **config-map.yaml** afin d’intégrer le blackbox-exporter (un job si vous voulez)
```
cp prometheus-training/lab-8/* .
rm -rf prometheus-training
```

### 4 - Prise en compte des modifications
Vous devez supprimer et recréer le configmap ainsi que le deployment de Prometheus pour appliquer les modifications
```
kubectl delete configmaps prometheus-server-conf -n monitoring
kubectl create -f config-map.yaml
kubectl delete deployments.apps prometheus-deployment -n monitoring
kubectl apply -f prometheus-deployment.yaml -n monitoring
```

### 5 - Check du endpoint
Vérifiez sur l’interface de Prometheus que la target blackbox-exporter est bien présente et up
![blackbox endpoint](images/blackbox-endpoint.PNG)

### 6 -  Pour terminer, importer le dashboard blackbox **7587**
Rien de nouveau à la procédure habituelle

### 7 - Vérifiez que le dashboard nouvellement importé affiche des données
![blackbox dashboard](images/blackbox-dashboard.PNG)