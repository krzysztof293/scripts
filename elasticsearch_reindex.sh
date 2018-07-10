#!/bin/bash
# Script byl pouzit pro reindexaci indexu po tom co se snizil pocet shardu z 5->1 pro nove vytvorene indexy.
# Jedna z moznosti jak docilit snizeni shardu u jiz vytvorenych indexu je reindexace, smazani puvodniho indexu a vytvoreni aliasu, ktery bude odkazovat na novy index.
# Autor: rohlik
# Verze: 201807610.1

#Variables

pattern=$1
server="localhost"
size="3500"
logfile="/var/log/es-reindex.log"

if [ "$#" -ne 1 ]; then
        echo "USAGE: $0 INDEX_PATTERN"
        exit 3
fi

echo -e "###########\nSTARTING NOW\n$(date)\n###########\n\n" >> $logfile

# / 5 1/ znaci puvodni pocet shardu a pocet replik - chceme reindexovat jen indexy, ktere splnuji tuto podminku.
for index in $(curl -sXGET http://$server:9200/_cat/indices|grep $pattern|awk '/ 5 1/ {print $3}'|grep -v '^.*\-new$'); do


echo -e "\n\nReindexace: ${index}" >> $logfile
curl -H 'Content-Type: application/json' -sXPOST http://$server:9200/_reindex -d '{
  "source": {
    "index": "'${index}'",
    "size": '${size}'
  },
  "dest": {
    "index": "'${index}-new'"
  }
}'
if [ $? -eq 0 ]; then
        curl -sXDELETE http://$server:9200/${index}
        echo -e "\nSmazano: ${index}" >> $logfile
        curl -H 'Content-Type: application/json' -sXPUT http://$server:9200/${index}-new/_alias/${index}
        echo -e "\nAlias vytvoren: ${index}" >> $logfile
else
        echo "!POZOR! Index ${index} nebyl spravne reindexovan." >> $logfile
fi
done
echo -e "###########\nENDED AT\n$(date)\n###########\n\n" >> $logfile
