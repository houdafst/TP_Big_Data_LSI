# TP2 Big Data — HDFS : stockage distribué


**FST-SBZ — A.U. 2026-2027 — 3ème LSI** 

**Dr. -Ing. Houda BENALI**  

**Prérequis : TP1 validé — Linux, Docker, Docker Compose et cluster Hadoop opérationnel**

## 1. Objectifs

À la fin de ce TP, vous devez être capables de :

- distinguer le système de fichiers local et HDFS ;
- expliquer le rôle du **NameNode** et des **DataNodes** ;
- créer une arborescence dans HDFS ;
- transférer des fichiers entre Linux et HDFS ;
- manipuler des fichiers HDFS avec des commandes proches d'Unix ;
- comprendre les notions de **bloc** et de **facteur de réplication** ;
- utiliser `hdfs fsck` pour observer les blocs et leurs emplacements ;
- vérifier l'état général du stockage HDFS ;
- préparer un jeu de données dans HDFS pour un traitement distribué au TP3.

> **Important :** ce TP réutilise le cluster Hadoop lancé au TP1. Il n'est pas nécessaire de recréer le cluster.

## 2. Architecture

```text
                     ┌──────────────────────┐
                     │       NameNode       │
                     │   métadonnées HDFS   │
                     └──────────┬───────────┘
                                │
                 ┌──────────────┴───────────────┐
                 │                              │
        ┌────────▼─────────┐          ┌─────────▼────────┐
        │    DataNode 1    │          │    DataNode 2    │
        │  blocs de données│          │  blocs de données│
        └──────────────────┘          └──────────────────┘
```

Le NameNode gère notamment l'espace de noms et les métadonnées. Les DataNodes stockent les blocs de données. Les clients utilisent le NameNode pour les métadonnées puis les DataNodes pour les données.

# Partie A — Comprendre HDFS


## A1. Vérifier que le cluster fonctionne

Depuis la racine du dépôt :

```bash
sudo docker compose -f tp1/compose.yaml ps
```

### Question 1
Quels conteneurs sont en cours d'exécution ? Quel conteneur joue le rôle du NameNode ? Quels conteneurs jouent le rôle de DataNode ?

### Question 2
Affichez les derniers messages du NameNode :

```bash
sudo docker compose -f tp1/compose.yaml logs --tail=20 namenode
```

Puis ceux d'un DataNode :

```bash
sudo docker compose -f tp1/compose.yaml logs --tail=20 datanode1
```

Que remarquez-vous ?

## A2. Entrer dans le NameNode

```bash
sudo docker exec -it namenode bash
```

Vérifiez la version :

```bash
hadoop version
```

### Question 3
Quelle version de Hadoop est utilisée ?

### Question 4
Pourquoi exécute-t-on les commandes `hdfs dfs` depuis le conteneur hadoop-namenode dans ce TP ?

> `hdfs dfs` fournit une interface de commandes de type système de fichiers pour HDFS, avec des opérations proches de `ls`, `mkdir`, `cp`, `mv`, `rm`, etc.

# Partie B — Explorer HDFS

Toutes les commandes de cette partie sont exécutées dans le conteneur `namenode`.

## B1. Explorer la racine

```bash
hdfs dfs -ls /
```

### Question 5
Que contient actuellement la racine `/` de HDFS ?

Comparez avec :

```bash
ls /
```

### Question 6
Expliquez la différence entre `/` dans Linux et `/` dans HDFS.

## B2. Créer votre espace de travail

Remplacez `<nom>` par votre identifiant ou votre prénom.

```bash
hdfs dfs -mkdir -p /user/<nom>/raw
hdfs dfs -mkdir -p /user/<nom>/processed
hdfs dfs -mkdir -p /user/<nom>/backup
```

Vérifiez :

```bash
hdfs dfs -ls -R /user/<nom>
```

### Question 7
À quoi sert l'option `-p` de `mkdir` ?

### Question 8
Quelle structure de répertoires avez-vous obtenue ?


## B3. Faire le parallèle avec Unix

Complétez :

| Linux | HDFS |
|---|---|
| `ls` | `?` |
| `mkdir` | `?` |
| `cp` | `?` |
| `mv` | `?` |
| `rm` | `?` |
| `cat` | `?` |

### Question 9
Pourquoi Hadoop propose-t-il des commandes qui ressemblent autant aux commandes Unix ?

# Partie C — Transférer des données vers HDFS


Nous utilisons le fichier :

```text
tp1/data/access.log
```

## C1. Observer le fichier local

Depuis la racine du dépôt :

```bash
wc -l tp1/data/access.log
head tp1/data/access.log
tail tp1/data/access.log
```

### Question 10
Combien de lignes contient le fichier ?

### Question 11
Quels codes HTTP apparaissent dans les logs ?

### Question 12
Pourquoi ce type de fichier constitue-t-il un exemple réaliste de donnée pouvant être stockée dans HDFS ?

## C2. Copier le fichier dans le conteneur NameNode

```bash
sudo docker cp tp1/data/access.log hadoop-namenode:/tmp/access.log
```

Vérifiez :

```bash
sudo docker exec hadoop-namenode ls -lh /tmp/access.log
```

## C3. Déposer le fichier dans HDFS

Entrez dans le NameNode :

```bash
sudo docker exec -it hadoop-namenode bash
```

Puis :

```bash
hdfs dfs -put /tmp/access.log /user/<nom>/raw/
```

Vérifiez :

```bash
hdfs dfs -ls /user/<nom>/raw
```

### Question 13
Pourquoi avons-nous besoin de `docker cp` avant d'utiliser `hdfs dfs -put` ?

### Question 14
Quelle différence entre `cp` et `hdfs dfs -put` ?

## C4. Lire le fichier depuis HDFS

```bash
hdfs dfs -cat /user/<nom>/raw/access.log
```

Puis :

```bash
hdfs dfs -head /user/<nom>/raw/access.log
hdfs dfs -tail /user/<nom>/raw/access.log
```

### Question 15
Le fichier lu avec `hdfs dfs -cat` est-il lu depuis le disque local du NameNode ou depuis HDFS ? Justifiez.

## C5. Télécharger depuis HDFS

```bash
mkdir -p /tmp/hdfs-download
hdfs dfs -get /user/<nom>/raw/access.log /tmp/hdfs-download/
ls -lh /tmp/hdfs-download/
```

### Question 16
Quelle est la différence entre `hdfs dfs -put` et `hdfs dfs -get` ?

# Partie D — Manipuler les fichiers HDFS

## D1. Copier un fichier

```bash
hdfs dfs -cp \
  /user/<nom>/raw/access.log \
  /user/<nom>/backup/access.log
```

Vérifiez :

```bash
hdfs dfs -ls -R /user/<nom>
```

### Question 17
Combien de fichiers `access.log` voyez-vous maintenant ?

## D2. Renommer / déplacer

```bash
hdfs dfs -cp \
  /user/<nom>/raw/access.log \
  /user/<nom>/processed/access.log
```

Puis :

```bash
hdfs dfs -mv \
  /user/<nom>/processed/access.log \
  /user/<nom>/processed/access_processed.log
```

### Question 18
Quelle différence entre `-cp` et `-mv` ?

## D3. Taille et comptage

```bash
hdfs dfs -du -h /user/<nom>
hdfs dfs -count /user/<nom>
hdfs dfs -df -h /
```

### Question 19
Que fournit chacune des trois commandes ?

### Question 20
Pourquoi les informations retournées par `-du` et `-df` sont-elles utiles dans un système distribué ?

## D4. Supprimer un fichier

```bash
hdfs dfs -rm /user/<nom>/processed/access_processed.log
```

Puis :

```bash
hdfs dfs -ls /user/<nom>/processed
```

Pour supprimer un répertoire non vide :

```bash
hdfs dfs -rm -r /chemin/du/repertoire
```

### Question 21
Pourquoi `-rm -r` est-il plus dangereux que `-rm` ?

# Partie E — Blocs et réplication

## E1. Observer la taille de bloc

```bash
hdfs getconf -confKey dfs.blocksize
```

### Question 22
Quelle taille de bloc est configurée ? Convertissez-la en MiB.

> Le fichier `access.log` est volontairement petit. Il occupera donc un seul bloc HDFS dans cette configuration. Cela n'empêche pas d'observer la réplication de ce bloc.

## E2. Inspecter les blocs

```bash
hdfs fsck /user/<nom>/raw/access.log \
  -files \
  -blocks \
  -locations
```

### Question 23
Combien de blocs sont associés à `access.log` ?

### Question 24
Sur quels DataNodes le bloc est-il présent ?

### Question 25
Pourquoi le même bloc peut-il apparaître sur plusieurs DataNodes ?

## E3. Observer le facteur de réplication

```bash
hdfs getconf -confKey dfs.replication
```

Puis :

```bash
hdfs fsck /user/<nom>/raw/access.log \
  -files \
  -blocks \
  -locations
```

### Question 26
Quel est le facteur de réplication configuré ?

### Question 27
Si le facteur de réplication vaut `2`, combien de copies du bloc sont normalement conservées ?

### Question 28
Pourquoi une réplication de `2` est-elle adaptée à notre cluster de TP qui possède deux DataNodes ?

## E4. Modifier temporairement la réplication

```bash
hdfs dfs -setrep -w 1 /user/<nom>/raw/access.log
```

Vérifiez :

```bash
hdfs fsck /user/<nom>/raw/access.log \
  -files \
  -blocks \
  -locations
```

Puis remettez la réplication à `2` :

```bash
hdfs dfs -setrep -w 2 /user/<nom>/raw/access.log
```

Vérifiez à nouveau.

### Question 29
Qu'est-ce qui change dans les informations retournées par `fsck` ?

### Question 30
Expliquez le lien entre : fichier, bloc(s), réplication et DataNodes


# Partie F — Mini-activité Big Data : préparer les logs

## F1. Organiser les données

Votre espace HDFS doit respecter :

```text
/user/<nom>/
├── raw/
│   └── access.log
├── processed/
└── backup/
    └── access.log
```

### Question 31
Pourquoi séparer les données `raw`, `processed` et `backup` dans un projet Big Data ?

## F2. Première exploration des logs

Sans télécharger le fichier :

```bash
hdfs dfs -cat /user/<nom>/raw/access.log
```

Puis :

```bash
hdfs dfs -cat /user/<nom>/raw/access.log | wc -l
hdfs dfs -cat /user/<nom>/raw/access.log | grep " 404 " | wc -l
hdfs dfs -cat /user/<nom>/raw/access.log | grep " 500 " | wc -l
...
```

### Question 32
Combien de requêtes ont retourné `200`, `301`, `403`, `404` et `500` ?

### Question 33
Quelle limite importante présente cette approche ?

> **Indice :** demandez-vous où sont réellement exécutés `grep` et `wc`, et si cette méthode exploite déjà le calcul distribué.

# Partie G — Synthèse et préparation du TP3

```text
Machine Linux
     │
     │ docker cp
     ▼
Conteneur NameNode
     │
     │ hdfs dfs -put
     ▼
    HDFS
     │
     ├── NameNode
     │      └── métadonnées
     │
     └── DataNodes
            └── blocs + répliques
```

### Question 34
Quelle est la différence fondamentale entre le rôle du NameNode et celui des DataNodes ?

### Question 35
Pourquoi HDFS est-il adapté au stockage de gros volumes de données ?

### Question 36
Pourquoi HDFS seul ne suffit-il pas pour réaliser un calcul distribué ?

### Question 37
Quel composant allons-nous utiliser au TP3 pour traiter les données de manière distribuée ?

# 3. Commandes essentielles à retenir

```bash
hdfs dfs -ls
hdfs dfs -mkdir
hdfs dfs -put
hdfs dfs -get
hdfs dfs -cat
hdfs dfs -head
hdfs dfs -tail
hdfs dfs -cp
hdfs dfs -mv
hdfs dfs -rm
hdfs dfs -rm -r
hdfs dfs -du
hdfs dfs -count
hdfs dfs -df
hdfs dfs -setrep
hdfs fsck
hdfs getconf
```

Pour obtenir de l'aide :

```bash
hdfs dfs -help
hdfs dfs -help ls
```

# 4. Règles de travail

- Ne modifiez pas `tp1/compose.yaml` pour ce TP.
- Ne recréez pas les conteneurs si le cluster du TP1 fonctionne déjà.
- Utilisez votre propre répertoire `/user/<nom>/`.
- N'utilisez pas `docker compose down -v` pendant le TP.
- En cas de problème, vérifiez :
  ```bash
  docker compose -f tp1/compose.yaml ps
  docker compose -f tp1/compose.yaml logs --tail=30 namenode
  ```
- Pour l'aide d'une commande :
  ```bash
  hdfs dfs -help <commande>
  ```

## Transition vers le TP3

Dans ce TP, nous avons appris à **stocker et organiser** les données dans HDFS.

Au TP3, nous passerons de :

```text
HDFS
 ↓
stockage distribué
```

à :

```text
MapReduce
 ↓
traitement distribué
```
