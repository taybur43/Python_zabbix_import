#!/bin/bash
#exec 1>/var/log/export.log 2>&1
user_input(){
read -rp "Please Input Object Type[for all write #all]: " objtype
read -rp "Please Input Object Name [ if multiple insert ',' in between]: " objname
zabbix-cli -C "export_configuration '/root/export/' '$objtype' '$objname' "
echo "Exporting done.."
}

file_rename(){
declare -a arr=("groups" "hosts" "images" "maps" "screens" "templates")
#echo $objtype
for_all="#all#"
for_img="images"
#echo $for_all
if [ "$objtype" == "$for_all" ]; then 
   for object in "${arr[@]}";
   do
      if [ "$object" == "$for_img" ]; then
            for filename in /root/export/$object/*.xml; do
            [ -f "$filename" ] || continue
            filename1=${filename//zabbix_export_$object_/}
            num=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f1)
            pat=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f2)
            #echo $num
            #echo $pat
            mv -i "$filename" "${filename1/_("$num")"$pat"/_$num.xml}"
            done
        else 	  
            for filename in /root/export/$object/*.xml; do
            [ -f "$filename" ] || continue     
            filename1=${filename//zabbix_export_"$object"_/}
            mv -i "$filename" "${filename1/_[0-9]*/.xml}"
            done
	fi
   done
   echo "Done renaming...."
   echo "compressing in zip"
   cd /root/export/
   now="$(date +'%d_%m_%Y_%H_%M_%S')"
   mv  bk.zip  bk.zip_$now
   zip -r bk.zip *
   #zip /root/export/bk.zip  /root/export/*
else
   if [ "$objtype" == "$for_img" ]; then
            for filename in /root/export/$objtype/*.xml; do
            [ -f "$filename" ] || continue
            filename1=${filename//zabbix_export_images_/}
            num=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f1)
            pat=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f2)
            #echo $num
            #echo $pat
             mv -i "$filename" "${filename1/_("$num")"$pat"/_$num.xml}"
            done 
	else		
            for filename in /root/export/$objtype/*.xml; do
            [ -f "$filename" ] || continue
            filename1=${filename//zabbix_export_"$objtype"_/}
            mv -i "$filename" "${filename1/_[0-9]*/.xml}"
            done
	fi		
#fi
echo "Done renaming...."
echo "compressing in zip"
cd /root/export/
now="$(date +'%d_%m_%Y_%H_%M_%S')"
mv  bk.zip  bk.zip_$now
zip -r bk.zip $objtype/*
fi
}

email_sending(){
To=sagor.ece11@gmail.com
From=taybur.1@test.com
Server=bd1.tet.com:25
Auth_user=taybur.rahaman
Auth_pass=
Subject="This from Zabbix Auto Export script"
Attachment=/root/export/bk.zip
Body="Congratulation,You successfully exported your desired file."
echo "Sending Email......"
sendEmail  -t $To -f $From -s $Server -xu $Auth_user  -xp $Auth_pass -u $Subject -a $Attachment -m $Body
#echo "Sending Email......"
}


#exec 1>/var/log/export.log 2>&1
echo "Main part is from here......Starting script."
#calling function user input
user_input
#calling function file_rename
file_rename
#calling function email_sending
email_sending

