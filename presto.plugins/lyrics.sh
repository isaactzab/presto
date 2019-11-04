#!/bin/bash
# dir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# key='Insert WebAPI key (see README.md)'

# function getInfo {
#     local endpoint=$(curl -s -X "GET" "https://api.spotify.com/v1/me/player/currently-playing?market=SK" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $key")

#     echo $endpoint
# } $dir

function adjust {
	local pre_result="$(echo $1 | sed -r -e 's/[^A-Za-z()]|\((.*?)\)//gi')"
    local result=${pre_result,,}

    echo $result
}

function join {
	#param: $1 joins as the first one
	#param: $2 joins to $1
	local result=$1"\ \-\ "$2
	echo $result
}

function escape {
	#param: $1 - This string will be escaped
	if [[ -z $1 ]]; then
		echo "NULL"
	else
		local first=$(echo $1 | sed -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/')
		local result=${first%%-*}
		echo $result
	fi
}
function urlHash {
    echo -n $1 | md5sum | cut -d ' ' -f 1
}
function fetch {
    hash=$(urlHash $1)
    nocache=${3:-false}
    # echo "---"
    echo $nocache

    exit
    if [[ ! -f "$tmp/$hash" &&  $nocache ]];then
        # wget -q --header="Accept: text/html" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -O $tmp"/"$hash $2
        echo "$tmp/$hash from-cache"
        
    fi
    # axel -q --header="Accept: text/html" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -o $1 $2
}

echo Loading lyrics...
# info=$(getInfo)

# track_name=$(echo $info | jq -r ".item.name")
# author_name=$(echo $info | jq -r ".item.album.artists[].name")



os=$(uname -o)
if [[ $os == "GNU/Linux" ]]; then
	folder=/tmp
else
	folder=temp
fi

# if [ ! -d temp ]; then
#   mkdir -p temp;
# fi

author_name="${1}"
track_name="${2}"
# track_name=$([[]])

[[ ! "$#" -gt 0 ]] || (track_name=${author_name##*-} && author_name="${author_name%-*}")
# echo $author_name
# echo $track_name
# exit    

rm -rf $folder/lyrics.*
# tmp=$(mktemp -d $folder/lyrics.XXX)
tmp="/tmp/lyrics"
mkdir $tmp -p
# touch $tmp/lyrics.html

artist_escaped=$(escape "$author_name")
song_escaped=$(escape "$track_name")

both_escaped=$(join "$artist_escaped" "$song_escaped")

artist=$(adjust "$author_name")
# artist=$(echo $artist | sed -r -e 's/^the//gi') #typo regex `the`, I cant remember why
song=$(adjust "$track_name")

api="http://www.azlyrics.com/lyrics/"$artist"/"$song".html"

api_suggest="https://search.azlyrics.com/suggest.php?q=${author_name} ${track_name}"


apiHash=$(urlHash $api)
apiSuggestHash=$(urlHash $api_suggest)

# if [[ -f $tmp/$apiHash ]];then
#     cached=true
#     lyricsFound="from-cache-$tmp/$artist-$song.txt"
#     # exit
# else
    # fetch $tmp/lyrics.html $api
    fetchResults=($(fetch $api)) # wrapped to convert result in array
    # [ ${fetchResults[1]+true} ] && lyricsFound=true || lyricsFound=$(cat ${fetchResults[0]} | grep "class=\"lyricsh\"")
    
    # lyricsFound=$(cat ${fetchResults[0]} | grep "class=\"lyricsh\"")
# # cat $tmp/lyrics.html
    # lyricsFound=$(cat $tmp/lyrics.html | grep "class=\"lyricsh\"")
# fi


# [ ! -z "$lyricsFound" ] && echo "yes" || echo "no"
# echo $lyricsFound
if [ ! -z "$lyricsFound" ];then
    if [ $cached ];then
        echo "from cache"
        lyric=$(cat $tmp/$artist"-"$song".txt")
    else
        lyric=$(cat $tmp/lyrics.html)
        lyric=$(sed -n "/<div class=\"lyricsh\">/,/<!-- MxM banner/p" $tmp/lyrics.html | sed "s/<br>//g" | sed 's/<[^>]*>//g' | sed -r '/^\s*$/d')
        printf "$lyric" | tee $tmp/$artist"-"$song".txt"
    fi
        printf "$lyric" | less

else
    # fetch $tmp/suggest.html $api_suggest
    suggestions=($(fetch $api_suggest true))
    
    echo "Not results for ${author_name} - ${track_name}"
    echo "Here you have some suggestions:"
    # show songs
    # songs=$(jq '.songs[] | .autocomplete + " - " + .url' $tmp/suggest.html)
    # echo ${songs}   
    
    for item in $(jq '.songs[] | @base64' ${suggestions[0]}); do
        # echo  $item | base64 --decode
        echo $(echo $item| sed -e 's/^"//' -e 's/"$//' | base64 --decode | jq '.autocomplete' | sed -e 's/[\"]//g' -e 's/"$//')
    done;

    # for row in $(cat $tmp/suggest.html | jq '.songs'); do
    #     echo $row
    #     echo "----"
    #     # _jq(){
    #     #     echo ${row} |  jq -r ${1}
    #     # }
    #     #  echo $(_jq '.autocomplete')
    # done
fi
