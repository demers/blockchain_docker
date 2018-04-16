#!/bin/bash

sender=`echo "adresse1@undomaine1.com" | md5sum | cut -f1 -d" "`
echo "Le sender est: $sender"
recipient=`echo "autreadresse@undomaine2.com" | md5sum | cut -f1 -d" "`
echo "Le recipient est $recipient"
#curl -X POST -H "Content-Type: application/json" -d "{ \
 #\"sender\": \"$sender\", \
 #\"recipient\": \"$recipient\", \
 #\"amount\": 100 \
 #}" "http://localhost:5000/transactions/new"