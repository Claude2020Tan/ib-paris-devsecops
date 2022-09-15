# Configuration  du webhook dans slack
Dans slack, on va chercher l'application **Webhooks entrants** et la rajouter
![Slack app webhook](images/slack%20appli%20webhook%20entrant.PNG)

Ceci s'ouvre dans le navigateur
![Slack app webhook](images/salck%202.PNG)

On va configurer : 
- Configurer le channel d'envoie des notifications
  ![Slack app webhook](images/salck%203.PNG)
- Récupérer l'url du webhook générée
  ![Slack app webhook](images/salck_4.PNG)

Une fois configuré, on va retourner intégrer celà dans Grafana
  ![Grafana Integration](images/grafana_1.PNG)
  ensuite : 
  ![Grafana Integration](images/grafana_2.PNG)
Du coup, on peut voir le test de notification dans le channel slack
  ![Slack notif Integration](images/salck_5.PNG)

A présent, il faut créer la règle devant déclencer l'alerting.
Dans le dashboard blackbox exporter, On va rajouter un nouveau graphe : 
![Slack notif Integration](images/grafana_3.PNG)
On configure le type de graphe et les axes
![Slack notif Integration](images/grafana_4.PNG)
On configure l'alarming
![Slack notif Integration](images/grafana_5.PNG)
Dans l'alarming, on configure le message à envoyer et à quel channel
![Slack notif Integration](images/grafana_6.PNG)

En suite on sauvegarde
![Slack notif Integration](images/grafana_8.PNG)
On a à présent le nouveau graphe dans le dashboard qui apparait
![new dashobard blackbox](images/grafana_9.PNG)

Il est à présent question de simuler une alarme
On va scaler le nombre de replicat de notre deploiement odoo à zéro : 
```
kubectl scale deployment odoo --replicas 0
kubectl get deploy
```
On a ceci : 
![scale odoo to zero](images/scale_odoo_to_o.PNG)

Le Dashboard détecte direcement que l'applicatione est Down
![scale odoo to zero](images/grafana_10.PNG)

Dans le channel slack, on devrait avoir une notification
![Alert on SLack](images/grafana11.PNG)