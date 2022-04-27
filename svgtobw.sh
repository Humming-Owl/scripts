#!/bin/bash

if [ -f "data.txt" ]; then

	rm data.txt
fi

if [ ! -d "final" ]; then

	mkdir final

fi

for f in input/*.svg
do

	convert -antialias -density 2000 -background none -gravity center $f temp.bmp

	percentwhite=$( convert temp.bmp -fuzz 60% -fill white -opaque white -fill black +opaque white -format "%[fx:100*mean]" info: | sed "s/\..*//" )

	newname=$( echo $f | sed "s/input\///" | sed "s/.svg//" )

	echo $percentwhite >> data.txt
	echo "$percentwhite > $newname.svg"

	convert temp.bmp -colorspace gray -morphology edgeout:3 Disk -negate -transparent white -threshold 100% temp_extra.bmp

	if (( $percentwhite >= 0 && $percentwhite <= 40 )); then

		./magick temp.bmp -auto-threshold Triangle temp_threshold.bmp

	elif (( $percentwhite > 40 && $percentwhite <= 100 )); then

		./magick temp.bmp -auto-threshold OTSU temp_threshold.bmp

	fi

	convert temp.bmp -threshold 100% temp_background.bmp
	composite temp_threshold.bmp temp_background.bmp final/$newname.bmp
	composite temp_extra.bmp final/$newname.bmp final/$newname.bmp
	convert final/$newname.bmp -gravity center -extent 752x752 -morphology Erode Disk:4 final/$newname.bmp
	potrace --height 2048pt --width 2048pt -s final/$newname.bmp -o final/$newname.svg

	percentwhite2=$( convert final/$newname.bmp -fuzz 60% -fill white -opaque white -fill black +opaque white -format "%[fx:100*mean]" info: | sed "s/\..*//" )

	echo "final $percentwhite2"

	if (( $percentwhite2 <= 50 )); then

		convert final/$newname.bmp -morphology Dilate Disk:8 final/$newname.bmp
		potrace --height 2048pt --width 2048pt -s final/$newname.bmp -o final/$newname.svg

	elif (( $percentwhite2 > 50 )); then

		convert final/$newname.bmp -morphology Erode Disk:8 final/$newname.bmp
		potrace --height 2048pt --width 2048pt -s final/$newname.bmp -o final/$newname.svg

	fi

	rm final/*.bmp

done

rm temp.bmp temp_extra.bmp temp_threshold.bmp temp_background.bmp