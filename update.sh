#!/bin/bash

JSON=$(< version.json)
VERSION_URL="https://www.zentao.net/download.html"

HTML_CONTENT=$(curl -sL ${VERSION_URL} | htmlq --attribute href a)

REGULAR=(
    "zentaopms[[:digit:]]+.[[:digit:]]+"
    "biz[[:digit:]]+.[[:digit:]]+"
    "max[[:digit:]]+.[[:digit:]]+"
    "litev[[:digit:]]+.[[:digit:]]+"
    "litevipv[[:digit:]]+.[[:digit:]]+"
)

get_latest_ver(){
    local regular=${1:?regular is error!}
    grep -Eo "$regular" <<< "$HTML_CONTENT" | sort -nr | head -n 1 
}

get_news_url(){
    local regular=${1:?regular is error!}
    url=$(grep -E "$regular" <<< "$HTML_CONTENT" | sort -nr | head -n 1 )
    echo "https://www.zentao.net$url"
}

get_img_ver(){
    local regular=${1:?regular is error!}
    grep -Eo "$regular" <<< "$CUR_VER"
}

# get all release version and news url
for release in "${REGULAR[@]}"
do
    # delete regular info
    key="${release//\[\[*/}"

    # get last version
    last_ver="$(get_latest_ver "$release" | sed "s/${key}//g")"

    # have not version info
    if [ -z "$last_ver" ];then
        last_ver=$(jq -r ."$key".version <<< "$JSON")
        last_news=$(jq -r ."$key".news <<< "$JSON")
    else
        # get news info
        last_news="$(get_news_url "$release")"
    fi
    # modify json variable
    JSON=$(jq <<< "$JSON" ".$key.version=\"$last_ver\"")
    JSON=$(jq <<< "$JSON" ".$key.news=\"$last_news\"")

done

# generate md5 for last info and current info
LAST_MD5=$(echo "$JSON"|md5sum | awk '{print $1}')
CUR_MD5=$(md5sum version.json |awk '{print $1}')

if [ "$LAST_MD5" != "$CUR_MD5" ];then
    echo "New version of ZenTao detected!"
    diff --color=always -u1 <(echo "$JSON") <(cat version.json)
    jq <<< "$JSON" > version.json
fi