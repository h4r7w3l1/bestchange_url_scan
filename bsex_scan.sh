#!/bin/bash

BOTsecret=''
chatid=''
SaveDate=$(date +%Y.%m.%d)

# Get and save mullvad socks5 proxy in-mem array
Socks5Arr+=("$(curl -s https://api.mullvad.net/www/relays/wireguard/ | jq -r '.[] .socks_name')")
Socks5ArrSize=$(printf "%s\n" "${Socks5Arr[@]}"  | wc -l)
# Function for select random value from array
selectRndProxy() {
    index=$(("$RANDOM" % "$Socks5ArrSize"))
    echo "${Socks5Arr[$index]}"
}

# Get and save all active exchangers ID (check `unzip -hh` for read about `funzip`). Sort and uniq result.
ExchIDsArr+=("$(curl -sL api.bestchange.ru/info.zip | funzip - |  cut -d ';' -f1 | sort | uniq )")
ExchIDsArrSize=$(printf "%s\n" "${ExchIDsArr[@]}"  | wc -l)

# Inform about working datasets
printf "Uniq IDs: %s\nCount Socks5: %s\n\n"  "${ExchIDsArrSize}"  "${Socks5ArrSize}"

for line in "${ExchIDsArr[@]}";
 do
    name="$line"
    # Loop the request until we get a response from the server
    while true; do
        response=$(curl -sI "https://www.bestchange.ru/click.php?id=$name" -w '%{redirect_url}\n' -o /dev/null --socks5-hostname "$(selectRndProxy)")
        if [ $? -eq 0 ]; then
            if [[ -n "$response" ]]; then
                echo "$response"
                break
            else
                # If an empty response is received, then wait 2 seconds and try again
                sleep 2
            fi
        else
            # If the connection to the server failed, wait 2 seconds and try again
            sleep 2
        fi
    done
done >> "./urls_$SaveDate.txt"

# Send result to tg_channel
curl -F document=@"./urls_$SaveDate.txt" -F caption="BestChange_$(date +'%Y-%m-%d')" "https://api.telegram.org/bot$BOTsecret/sendDocument?chat_id=$chatid" --noproxy '*'
