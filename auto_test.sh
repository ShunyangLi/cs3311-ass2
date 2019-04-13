#!/bin/bash

./acting "james franco" > tests/out1
./title "star war" > tests/out2
./title "happy" > tests/out3
./title "mars" > tests/out4
./toprank "Action&Sci-Fi&Adventure" 10 2005 2005 > tests/out5
./toprank "Sci-Fi&Adventure&Action" 20 1920 2019 > tests/out6
./toprank 20 1920 2019 > tests/out7
./similar1 "Happy Feet" 30 > tests/out8
./similar1 "The Shawshank Redemption" 30 > tests/out9

flag=0

for i in 1 2 3 4 5 6 7 8 9
do
    if [[ `diff tests/out$i tests/exp$i` != "" ]]
    then
        flag=1
        echo "Fail test $i, using 'diff tests/out$i tests/exp$i' to check different"
    else
        rm tests/out$i
    fi
done

if [[ $flag == 0 ]]
then
    echo "Pass all tests"
fi
