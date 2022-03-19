#!/bin/bash

HEIGHT=17
WIDTH=80
CHOICE_HEIGHT=19
BACKTITLE="Gestion Blockchain version 1.3"
TITLE="Gestion de chaîne de blocs"
MENU="Choisir une des options suivantes:"

function creerConteneur() {
    read -p "Voulez-vous créer la chaîne de blocs avec Docker pour ce port ($1)? (o/n)" CHOIX
    if [[ $CHOIX =~ ^[Oo]$ ]]
    then
        cp -v -f Dockerfile Dockerfile$1
        sed -i -e "s/5000/$1/g" "Dockerfile$1"
        echo "Voici la commande qui sera exécutée:"
        echo "docker build -t blockchain$1 -f Dockerfile$1 ."
        docker build -t blockchain$1 -f Dockerfile$1 .
    fi

    read -p "Voulez-vous démarrer la chaîne de blocs pour ce port ($1)? (o/n)" CHOIX
    if [[ $CHOIX =~ ^[Oo]$ ]]
    then
        echo "Voici les commandes qui seront exécutées:"
        echo "docker rm blockchain$1"
        echo "docker run -d -p $1:$1 --network=\"blockchain\" --name blockchain$1 blockchain$1"
        docker rm blockchain$1
        docker run -d -p $1:$1 --network="blockchain" --name blockchain$1 blockchain$1
    fi
    echo "Vérification des ports ouverts..."
    sleep 1
    echo "Voici la liste des chaînes de blocs disponibles:"
    docker ps | grep --color=never blockchain
    netstat -tlpn | grep --color=never 0.0.0.0
    read -n 1 -s -r -p "Tapez une touche pour afficher le menu..."
}

# Port par défaut.
PORT=()
NOPORT=0

echo "------------------------"
echo " --- INITIALISATIION ---"
echo "------------------------"
echo "Attention, aucune chaîne de bloc n'est disponible actuellement."
echo "Vous devez en avoir au moins une."
echo ""
echo "Création du réseau blockchain..."
docker network create blockchain
echo ""
read -p "Entrez le premier port d'accès à la chaîne de bloc: " NOUVEAUPORT
PORT[${#PORT[@]}]=$NOUVEAUPORT
creerConteneur $NOUVEAUPORT

while true;
do

    OPTIONS=(1 "Lister les chaînes de bloc disponibles;"
         2 "Changer le port de la chaîne de bloc (actuellement, ${PORT[$NOPORT]});"
         3 "Créer ou démarrer une nouvelle chaîne de bloc;"
         4 "Ajouter une transaction;"
         5 "Afficher la chaîne de bloc;"
         6 "Miner les dernières transactions ajoutées;"
         7 "Enregistrer une chaîne de bloc;"
         8 "Résoudre un conflit de chaîne de bloc (consensus);"
         9 "Supprimer les conteneurs et les images associées;"
         10 "Quitter")

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
                echo "Voici la liste des chaînes de bloc disponibles (Docker):"
                docker ps | grep --color=never blockchain
                netstat -tlpn | grep --color=never 0.0.0.0
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            2)
                echo "Voici la liste des ports disponibles: " ${PORT[@]}
                read -p "Fournir le port voulu parmi cette liste ci-haut: " PORTCHOISI
                for i in "${!PORT[@]}"; do
                    if [[ "${PORT[$i]}" = "${PORTCHOISI}" ]]; then
                        NOPORT=${i}
                    fi
                done
                echo Le nouveau port considéré sera: ${PORT[$NOPORT]}
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            3)
                read -p "Entrez le nouveau port d'accès à la chaîne de bloc: " NOUVEAUPORT
                PORT[${#PORT[@]}]=$NOUVEAUPORT
                creerConteneur $NOUVEAUPORT
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
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            5)
                echo "Voici le contenu de la chaîne de bloc..."
                #curl "http://localhost:${PORT[$NOPORT]}/chain" | less
                http "http://localhost:${PORT[$NOPORT]}/chain"
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            6)
                echo "Voici le minage de la chaîne de bloc..."
                #curl "http://localhost:${PORT[$NOPORT]}/mine"
                http "http://localhost:${PORT[$NOPORT]}/mine"
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            7)
                read -p "Quel est le port de la chaîne de bloc à enregistrer? " PORTENR
                if [[ $PORTENR =~ ${PORT[$NOPORT]} ]]
                then
                    echo "ERREUR:"
                    echo "       Impossible d'enregistrer la chaîne de blocs actuelle ($PORTENR)."
                    echo "       Sinon, cela va créer une boucle sans fin au moment de l'action du consensus."
                    echo "       Retour au menu..."
                    read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                else
                    echo "Noeud ajouté: blockchain$PORTENR:$PORTENR"
                    curl -X POST -H "Content-Type: application/json" -d "{
                        \"nodes\": [ \"blockchain$PORTENR:$PORTENR\" ]
                        }" "http://localhost:${PORT[$NOPORT]}/nodes/register"
                    read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                fi
                ;;
            8)
                echo Le port considéré est: ${PORT[$NOPORT]}
                echo "La résolution (consensus) sera faite sur cette chaîne de blocs..."
                echo "http \"http://localhost:${PORT[$NOPORT]}/nodes/resolve\""
                #curl "http://localhost:${PORT[$NOPORT]}/nodes/resolve"
                http "http://localhost:${PORT[$NOPORT]}/nodes/resolve"
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            9)
                for i in "${!PORT[@]}"; do
                    echo "Arrêt du conteneur blockchain${PORT[$i]}..."
                    docker stop blockchain${PORT[$i]}
                    echo "Suppression du conteneur blockchain${PORT[$i]}..."
                    docker rm blockchain${PORT[$i]}
                    echo "Suppression de l'image blockchain${PORT[$i]}..."
                    docker rmi blockchain${PORT[$i]}
                    echo "Suppression du fichier Dockerfile${PORT[$i]}..."
                    rm -f Dockerfile${PORT[$i]}
                done
                read -n 1 -s -r -p "Tapez une touche pour revenir au menu..."
                ;;
            10)
                echo "Sortie du script."
                echo "Script de gestion du blockchain écrit en Python"
                echo "disponible à https://github.com/demers/blockchain"
                echo "Écrit par FND avril 2018, mars 2022."
                exit 0
    esac
done
