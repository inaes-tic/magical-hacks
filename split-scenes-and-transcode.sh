#!/bin/sh

[ -z $FFMPEG ] && FFMPEG='ffmpeg'

s=0; a="0";
for b in `cat scenes.txt`; do
        echo "scene$s: $a $b"
        sc=`printf "scene%04d" $s`;
        mkdir -p $sc;
        j=0
        for i in `seq $a $b`; do
                I=`printf "fixed-%06d.png" $i`;
                J=`printf   "$sc-%06d.png" $j`;

                ln -sf ../$I $sc/$J;
                j=$(($j+1))
        done ;
        echo "$FFMPEG -r ntsc -i '$sc-%06d.png' -c:v prores_ks -profile:v 3 -qscale:v 1 -vendor ap10 -pix_fmt yuv422p10le -vcodec prores $sc.mov" > $sc/render.sh
        a=$(($b+1));
        s=$(($s+1));
done
