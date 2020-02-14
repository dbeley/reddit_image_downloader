#!/bin/bash
#
# download reddit images from subreddit

timeout=60

usage() { printf "%s" "\
Usage:    ./download-subreddit-images.sh 'subreddit_name' [hot|new|rising|top|controversial] [number] [all|year|month|week|day]
Examples: ./download-subreddit-images.sh starterpacks new 10
          ./download-subreddit-images.sh funny top 50 month
"; exit 1;
}

subreddit=$1
sort=$2
number=$3
top_time=$4

if [ -z $subreddit ]; then
    usage
fi

if [ -z $sort ]; then
    sort="hot"
fi

if [ -z $top_time ]; then
    top_time=""
fi

if [ -z $number ]; then
	number=200
fi

url="https://www.reddit.com/r/$subreddit/$sort/.json?raw_json=1&t=$top_time"
content=$(wget -T $timeout -q -O - $url)
mkdir -p $subreddit
i=1
while : ; do
    urls=$(echo -n "$content" | jq -r '.data.children[]|select(.data.post_hint|test("image")?) | .data.preview.images[0].source.url')
    names=$(echo -n "$content" | jq -r '.data.children[]|select(.data.post_hint|test("image")?) | .data.title')
    ids=$(echo -n "$content" | jq -r '.data.children[]|select(.data.post_hint|test("image")?) | .data.id')
    a=1
    wait # prevent spawning too many processes
    for url in $urls; do
        name=$(echo -n "$names" | sed -n "$a"p)
        id=$(echo -n "$ids" | sed -n "$a"p)
        ext=$(echo -n "${url##*.}" | cut -d '?' -f 1)
        newname="$subreddit"_"$sort""$timeframe"_"$(printf "%04d" $i)"_"$name"_$id.$ext
        printf "$i/$number : $newname\n"
        wget -T $timeout --no-check-certificate -nv -nc -P down -O "$subreddit/$newname" $url &>/dev/null &
    	((a=a+1))
    	((i=i+1))
		if [ $i -gt $number ] ; then
			exit 0
		fi
    done
    after=$(echo -n "$content"| jq -r '.data.after//empty')
    if [ -z $after ]; then
        break
    fi
    url="https://www.reddit.com/r/$subreddit/$sort/.json?count=200&after=$after&raw_json=1&t=$top_time"
    content=`wget -T $timeout --no-check-certificate -q -O - $url`
done
