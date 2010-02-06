#!/bin/bash
#
# pbrisbin 2009
#
# http://pbrisbin.com:8080/bin/coverart
#
# NOTE: always use absolute paths
#       i.e. use $HOME/ not ~/
#
# dependencies:
#       curl
#       audiotag (+atomicparsley for m4a support)
#
#
# once ~/.covers is filled, you could use ./bin/conkycovers to
# automagically display them in conky as they play in mpd
#
###

mdir="$HOME/Music"       # where be music
cdir="$HOME/.covers"     # where put covers 
list="$cdir/listing.txt" # log of what we do, to prevent duplicate work
covr="cover.jpg"         # filename use for symlinked covers, i.e. some apps might want front.jpg instead

# log unreadable tags and unfetchable artwork here
#LOG="/dev/null" # no logging
LOG="$HOME/.logs/coverart_errors.log"

logger() { echo "$(date +'[%d %b %Y %H:%M ]') :: $*" | tee -a "$LOG"; }

read_tag() {
  tag="$(audiotag -l "$1" | grep -io " ALBUM:.*\| ARTIST:.*" |\
         sort -r |\
         awk -F ':' '{print $2}' |\
         xargs -d '\n' |\
         grep "[0-9a-zA-Z]" |\
         sed -s 's/^\ //g;s/\ \ /\ /g')"

  # slashes cause issues
  echo ${tag//\//_}
}

create_list() {
  touch "$list"

  find "$mdir" -type f | while read song; do
    album="$(dirname "$song")"

    # have we not successfully processed this already 
    if ! grep -q "^${album//[/\\[}" "$list"; then
      logger "$(basename "$album") is new"

      tag="$(read_tag "$song")"

      # did we get a good tag
      if [ -n "$tag" ]; then
        logger "tag read"
        echo "$song|$tag" >> $list
      else
        logger "tag NOT read"
      fi

    fi
  done

  sort "$list" | uniq > /tmp/list.$$ && mv /tmp/list.$$ "$list"
}

fetch_cover () {
  cat "$list" | cut -d '|' -f 2- | uniq | while read album; do

    # do we have a valid album name
    if [ -n "$album" ]; then
      file="$cdir/${album// /_}.jpg"

      # have we not fetched this already
      if [ ! -f "$file" ] ; then
        logger "$(basename $file) is not in covers"

        url="http://www.albumart.org/index.php?srchkey=${album// /+}&itempage=1&newsearch=1&searchindex=Music"
        cover_url=$(curl -s "$url" | awk -F 'src=' '/zoom-icon.jpg/ {print $2}' | cut -d '"' -f 2 | head -n1)

        # is it available
        if [ -n "$cover_url" ]; then
          wget -q -O "$file" "$cover_url" && logger "cover retrieved" || logger "cover NOT retrieved"
        else
          logger "cover NOT available"
        fi
      fi
    fi
  done
}

link_them() {
  local IFS='|'

  while read file tag; do
    # skip anything we might've removed since the last run
    [ -f "$file" ] || continue;

    album="$(dirname "$file")"
    cover="$cdir/${tag// /_}.jpg"

    # do we have a valid cover
    if [ -f "$cover" ]; then

      # have we not processed this already
      #
      # note: one could remove this check and us ln -sf
      # to forcefully re link all files at every run
      # it's not bad performanc-wise and could fix mistakes
      # from previous runs
      if [ ! -L "$album/$covr" ]; then
        logger "$(basename "$album")/$covr not present"
        ln -s "$cover" "$album/$covr"
        logger "linked to $(basename "$cover")"
      fi
    fi
  done < "$list"
}

# 1. find and query your music tags to build a list
#    format: "/path/to/album/some_track.mp3|Artist Album"
create_list

# 2. fetch cover art based on this list
#    stored as: ~/.covers/Artist_Album.jpg
fetch_cover 

# 3. symlink those covers appropriately
#    example: ~/Music/.../album/cover.jpg --> ~/.covers/Artist_Album.jpg
link_them
