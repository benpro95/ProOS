#!/bin/bash
echo "Press any key to continue"
while [ true ] ; do
read -n 1 my_var
if [ $? = 0 ] ; then
 curl http://lcd32.home/message -H "Accept: ####?|0|0|$my_var"
fi
done


#TEXT=$(cat ~/Downloads/text.txt | awk '$1=$1' ORS=' ' | cut -c1-15384) ; curl http://lcd16x2.home/message -H "Accept: ####?|1|0|$TEXT"