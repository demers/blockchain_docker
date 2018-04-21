#!/bin/bash

HEIGHT=15
WIDTH=80
CHOICE_HEIGHT=10
BACKTITLE="Gestion Blockchain version 1.0"
TITLE="Gestion de chaîne de blocs"
MENU="Choisir une des options suivantes:"

# Port par défaut.
PORT=("5000")
NOPORT=0

OPTIONS=(1 "Lister les chaînes de blocs disponibles"
         2 "Changer le port de la chaîne de blocs"
         3 "Créer une nouvelle chaîne de blocs"
         4 "Ajouter une transaction;"
         5 "Afficher la chaîne de blocs;"
         6 "Miner les dernières transactions ajoutées;"
         7 "Enregistrer une chaîne de bloc;"
         8 "Résoudre un conflit de chaîne de blocs (consensus);"
         9 "Quitter")

while true;
do
    CHOICE=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

clear
    case $CHOICE in
            1)
                echo "Voici la liste des ports disponibles: " ${PORT[@]}
                echo "Voici la liste des chaînes de blocs disponibles (Docker):"
                docker ps
                #netstat -tlpn
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            2)
                echo "Voici la liste des ports disponibles: " ${PORT[@]}
                DERNIERPORTS=$((${#PORT[@]} - 1))
                read -p "Fournir le numéro du port à considérer (0 à $DERNIERPORTS) " NOPORT
                echo Le nouveau port considéré sera: ${PORT[$NOPORT]}
                sleep 4
                ;;
            3)
                read -p "Entrez le nouveau port d'accès à la chaîne de bloc: " NOUVEAUPORT
                PORT[${#PORT[@]}]=$NOUVEAUPORT
                echo "Voici la liste des ports disponibles: " ${PORT[@]}
                read -p "Voulez-vous créer la chaîne de blocs avec Docker pour ce port? (o/n)" CHOIX
                if [[ $CHOIX =~ ^[Oo]$ ]]
                then
                    cp -v -f Dockerfile Dockerfile$NOUVEAUPORT
                    sed -i -e "s/5000/$NOUVEAUPORT/g" "Dockerfile$NOUVEAUPORT"
                    echo "Voici les commandes qui seront exécutées:"
                    echo "docker build -t blockchain$NOUVEAUPORT -f Dockerfile$NOUVEAUPORT ."
                    echo "docker run -d -p $NOUVEAUPORT:$NOUVEAUPORT --net=host --name blockchain$NOUVEAUPORT blockchain$NOUVEAUPORT"
                    docker build -t blockchain$NOUVEAUPORT -f Dockerfile$NOUVEAUPORT .
                    sleep 1
                    docker run -d -p $NOUVEAUPORT:$NOUVEAUPORT --net=host --name blockchain$NOUVEAUPORT blockchain$NOUVEAUPORT
                fi
                echo "Vérifiez les ports ouverts..."
                echo "Voici la liste des chaînes de blocs disponibles:"
                docker ps
                #netstat -tlpn
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            4)
                read -p "Quel est l'envoyeur (sender)? " SENDER
                read -p "Vous voulez protéger l'adresse (md5) (o/n)" CHOIX
                if [[ $CHOIX =~ ^[Oo]$ ]]
                then
                    SENDER=$(echo -n $SENDER | sha256sum | cut -d' ' -f1)
                fi
                read -p "Quel est le destinataire (recicient)? " RECIPIENT
                read -p "Vous voulez protéger l'adresse (md5) (o/n)" CHOIX
                if [[ $CHOIX =~ ^[Oo]$ ]]
                then
                    RECIPIENT=$(echo -n $RECIPIENT | sha256sum | cut -d' ' -f1)
                fi
                echo -n "Quel est le montant envoyé? "
                read AMOUNT
                echo "Voici l'ajout d'une transaction..."
                curl -X POST -H "Content-Type: application/json" -d "{
                    \"sender\": \"$SENDER\",
                    \"recipient\": \"$RECIPIENT\",
                    \"amount\": $AMOUNT
                    }" "http://localhost:${PORT[$NOPORT]}/transactions/new"
                ;;
            5)
                echo "Voici le contenu de la chaîne de blocs..."
                curl "http://localhost:${PORT[$NOPORT]}/chain" | less
                ;;
            6)
                echo "Voici le minage de la chaîne de blocs..."
                curl "http://localhost:${PORT[$NOPORT]}/mine"
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            7)
                read -p "Quel est le port de la chaîne de blocs à enregistrer? " PORTENR
                curl -X POST -H "Content-Type: application/json" -d "{
                    \"nodes\": [ \"http://localhost:$PORTENR\" ]
                    }" "http://localhost:${PORT[$NOPORT]}/transactions/new"
                ;;
            8)
                echo Le port considéré est: ${PORT[$NOPORT]}
                echo "La résolution (consensus) sera faite sur cette chaîne de blocs..."
                curl "http://localhost:${PORT[$NOPORT]}/nodes/resolve"
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            9)
                echo "Sortie du script."
                echo "Script de gestion du blockchain écrit en Python"
                echo "disponible à https://github.com/dvf/blockchain"
                echo "Écrit par FND avril 2018."
                exit 0
    esac
done
