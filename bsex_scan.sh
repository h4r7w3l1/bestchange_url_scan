#!/bin/bash

#get and save mullvad socks5 proxy
curl -s https://api.mullvad.net/www/relays/wireguard/ | jq -r '.[] .socks_name' -> socks5.txt

#get and save all active exchangers ID
wget http://api.bestchange.ru/info.zip -O info.zip && unzip -o -j info.zip bm_exch.dat && iconv -f windows-1251 -t UTF-8 bm_exch.dat > bm_exchnew.dat && cut -d ';' -f1 bm_exchnew.dat > id.txt

#get all exchangers urls by id
while read -r line; do
    name="$line"
    curl -sI "https://www.bestchange.ru/click.php?id=$name" -w '%{redirect_url}\n' -o /dev/null --socks5-hostname "$(sort -R socks5.txt | head -n1)"
done < id.txt