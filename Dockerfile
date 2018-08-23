FROM gempesaw/curl-jq

COPY files/get-events.sh get-events.sh

CMD [ "./get-events.sh" ]
