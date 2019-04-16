#!/bin/bash

./acting "james franco" > tests/out1
./title "star war" > tests/out2
./title "happy" > tests/out3
./title "mars" > tests/out4
./toprank "Action&Sci-Fi&Adventure" 10 2005 2005 > tests/out5
./toprank "Sci-Fi&Adventure&Action" 20 1920 2019 > tests/out6
./toprank 20 1920 2019 > tests/out7
./similar "Happy Feet" 30 > tests/out8
./similar "The Shawshank Redemption" 30 > tests/out9
./shortest "tom cruise" "Jeremy Renner" > tests/out10
./shortest "chris evans" "Scarlett Johansson" > tests/out11
./shortest "tom cruise" "Robert Downey Jr." > tests/out12
./shortest "brad pitt" "will smith" > tests/out13
./degrees "chris evans" 1 1 > tests/out14
./degrees "tom cruise" 1 2 | wc -l | sed 's/ //g' > tests/out15
./degrees "chris evans" 4 4 |wc -l | sed 's/ //g' > tests/out16
./degrees "chris evans" 1 6 |wc -l | sed 's/ //g' > tests/out17
./degrees "tom hanks" 1 5 |wc -l  | sed 's/ //g' > tests/out18
./degrees "emma stone" 3 6 |wc -l | sed 's/ //g' > tests/out19


flag=0

for(( i=1;i<=19;i=i+1))
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
    echo "Pass all tests which from the Assignment Spec !!"
fi



./acting "Amanda Schull" > tests/myout1
./acting "SEaN CaMeron mIchAeL" > tests/myout2
./acting "DoRian MiSsiCk" > tests/myout3
./acting "Michael Nyqvist" > tests/myout4

./title "ANIMal KingdOM" > tests/myout5
./title "Get REal" > tests/myout6

./toprank "aCtioN" 10 2005 2005 > tests/myout7
./toprank "waR" 10 2007 2007 > tests/myout8

./similar "SE7en" 10 > tests/myout9
./similar "THE Following" 20 > tests/myout10


./shortest "chris evans" "Phil Vischer" > tests/myout11
./shortest "emma stone" "al pacino" > tests/myout12
./shortest "emma stone" "adam garcia" > tests/myout13
./shortest "emma stone" "chelsea field" > tests/myout14


./degrees "Christian BalE" 1 6 > tests/myout15
./degrees "Maureen McCorMicK" 1 6 > tests/myout16


flag=0
for(( i=1;i<=16;i=i+1))
do
    if [[ `diff tests/myout$i tests/myexp$i` != "" ]]
    then
        flag=1
        echo "Fail test $i, using 'diff tests/myout$i tests/myexp$i' to check different"
    else
        rm tests/myout$i
    fi
done

if [[ $flag == 0 ]]
then
    echo "Our output is same !!"
fi











