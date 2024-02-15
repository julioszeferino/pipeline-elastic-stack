for WORD in `cat dados_sensores.json`
do
   echo $WORD
   curl -XPOST -u dados_sensores:dados_sensores --header "Content-Type: application/json" "http://localhost:8080/" -d ''$WORD''
done
