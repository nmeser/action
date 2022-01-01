# " df -H | grep -vE '^Filesystem|tmpfs' | awk '{ print $5 " " $1 }' | while read output "" komutu ile tüm disklerdeki kullanımdan,
#  Filesystem ve tmpfs isimleri geçen disklerin haricinde kalan disk çektılarında, 5. ve 1. sütunlarını yazdırır ve while döngüsü
#  tarafından okunur

# output değeri yazdırılır.
# output değerindeki 1. sütun alınır ve " % " lik ifadesi atılılr ve değer usage değişkenine atanır.
# usage değeri yazdırılır.
# output değerindeki 2. sütun alınır, whdisk değişkenine atanır.
# whdisk değeri yazdırlır.
# usage değeri 90 a eşit yada büyük ise echo bastırılır ve bilgilendirme maili gönderilir.


#!/bin/sh
df -H | grep -vE '^Filesystem|tmpfs' | awk '{ print $5 " " $1 }' | while read output;
do

   echo $output
   usage=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
   echo $usage
   whdisk=$(echo $output | awk '{ print $2 }' )
   echo $whdisk
   if [ $usage -ge 90 ]; then
     echo "Running out of space \"$whdisk ($usage%)\" on $(hostname) " 
     mail -s "Alert: Almost out of disk space $usep%" nmeserr@gmail.com
   fi
done