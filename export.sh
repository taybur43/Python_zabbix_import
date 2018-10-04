#!/bin/bash
exec 1>/data/zabbix_config_version_control/logs/export.log 2>&1

export_function(){
config_file="/usr/share/zabbix-cli/zabbix-cli."$1".conf"
objtype="$2"
objname="$3"
echo "Starting zabbix-cli  to export......" 
#echo "clearing existing file in /data/zabbix_config_version_control/zabbix_exports/"
#rm -rf /data/zabbix_config_version_control/zabbix_exports/*/*.xml*
res=$(zabbix-cli -c $config_file -C "export_configuration '/data/zabbix_config_version_control/zabbix_exports/' '$objtype' '$objname'")
echo $res
trig=$(echo $res|cut -d ":" -f1)
if [[ "$trig" =~ "Error" ]]; then
   echo "Sending error email...."
   echo $trig
   email_sending 1
else
   echo "Renaming this exported file"
   file_rename
fi
}


#user_input(){
#EnvName=$1
#ObjType=$2
#ObjName=$3
#EmailAddress=$4
#ptype1="prod"
#ptype2="test"
#email_regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$"
#if [ "$EnvName" != "$ptype1" ] && [ "$EnvName" != "$ptype2" ]; then
#   echo "Please write 1st argument either 'prod' or 'test'... "
#elif ! [[ "$EmailAddress" =~ $email_regex ]];then
#       echo "You have entered wrong email address and aborting this script"
#else
#   echo "mail will send to "$EmailAddress" ..."
#   export_function "$EnvName" "$ObjType" "$ObjName"
#fi
#}

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
            for filename in /data/zabbix_config_version_control/zabbix_exports/$object/*.xml; do
            [ -f "$filename" ] || continue
            filename1=${filename//zabbix_export_$object_/}
            num=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f1)
            pat=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f2)
            #echo $num
            #echo $pat
            mv -i "$filename" "${filename1/_("$num")"$pat"/_$num.xml}"
            done
        else 	  
            for filename in /data/zabbix_config_version_control/zabbix_exports/$object/*.xml; do
            [ -f "$filename" ] || continue     
            filename1=${filename//zabbix_export_"$object"_/}
            #mv -i "$filename" "${filename1/_[0-9]*/.xml}"
            num=$(echo $filename1| awk -F "_" '{print $(NF-1)}')
            pat=$(echo $filename1| awk -F "_" '{print $(NF)}')
            #echo $num
            #echo $pat
            mv -i "$filename" "${filename1/_"$num"_"$pat"/.xml}"
            done
	fi
   done
   echo "Done renaming...."
   echo "processing for zip..."
   cd /data/zabbix_config_version_control/zabbix_exports/
   echo "Compressing in Zip...."
   zip -r export.zip *
   #now="$(date +'%d_%m_%Y_%H_%M_%S')"
   #mv  bk.zip  bk.zip_$now
   #echo "moving previous backup to bkup directory..."
   #mv bk.zip_* /data/zabbix_config_version_control/bkup/
   #echo "Compressing in Zip...."
   #zip -r bk.zip *
   #zip /root/export/bk.zip  /root/export/*
   email_sending 0
else
       if [ "$objtype" == "$for_img" ]; then
            for filename in /data/zabbix_config_version_control/zabbix_exports/$objtype/*.xml; do
            [ -f "$filename" ] || continue
            filename1=${filename//zabbix_export_images_/}
            num=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f1)
            pat=$(echo $filename1|cut -d "(" -f2 |cut -d ")" -f2)
            #echo $num
            #echo $pat
             mv -i "$filename" "${filename1/_("$num")"$pat"/_$num.xml}"
            done 
	else		
            for filename in /data/zabbix_config_version_control/zabbix_exports/$objtype/*.xml; do
            [ -f "$filename" ] || continue
            filename1=${filename//zabbix_export_"$objtype"_/}
            #mv -i "$filename" "${filename1/_[0-9]*/.xml}"
            num=$(echo $filename1| awk -F "_" '{print $(NF-1)}')
            pat=$(echo $filename1| awk -F "_" '{print $(NF)}')
            mv -i "$filename" "${filename1/_"$num"_"$pat"/.xml}"
            done
	fi		
#fi
echo "Done renaming...."
echo "Strating process for zip..."
cd /data/zabbix_config_version_control/zabbix_exports/
echo "Compressing in Zip...."
zip -r export.zip $objtype/*
#now="$(date +'%d_%m_%Y_%H_%M_%S')"
#mv  bk.zip  bk.zip_$now
#echo "moving previous backup to bkup directory..."
#mv bk.zip_* /data/zabbix_config_version_control/bkup/
#echo "Compressing in Zip...."
#zip -r bk.zip $objtype/*
email_sending 0
fi
}



email_sending(){
#To=sagor.ece@gmail.com
From=zabbix-admin@valmet.com
Server=smtp.valmet.com:25
#Auth_user=taybur.rahaman
#Auth_pass=ECE@BJIT0943#
if [ $1 -eq 1 ]; then 
   Subject="[ERROR]: This from Zabbix Auto Export script" 
   Body="Opps! we have encountered issue in: "$res" "
   echo "Sending Error Email......"
   /usr/local/bin/sendEmail  -t $EmailAddress -f $From -s $Server  -u $Subject -m $Body
else
   Subject="This from Zabbix Auto Export script"
   Attachment=/data/zabbix_config_version_control/zabbix_exports/export.zip
   Body="Congratulation,You successfully exported your desired file."$result" "
   echo "Sending Email......"
   /usr/local/bin/sendEmail  -t $EmailAddress -f $From -s $Server  -u $Subject -a $Attachment -m $Body
   echo "clearing existing file in /data/zabbix_config_version_control/zabbix_exports/"
   rm -rf /data/zabbix_config_version_control/zabbix_exports/*/*.xml*
   now="$(date +'%d_%m_%Y_%H_%M_%S')"
   mv  export.zip  backup.zip_$now
   echo "moving previous backup to bkup directory..."
   mv backup.zip_* /data/zabbix_config_version_control/bkup/

fi
#echo "Sending Email......"
}


#exec 1>/var/log/export.log 2>&1
echo "Main part is from here......Starting script...Please inser proper argument otherwise you will get error in mail"

EnvName="test"
ObjType="images"
ObjName="#all#"
EmailAddress="application.monitoring@valmet.com"
ptype1="prod"
ptype2="test"
email_regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$"
if [ "$EnvName" != "$ptype1" ] && [ "$EnvName" != "$ptype2" ]; then
   echo "Please write 1st argument either 'prod' or 'test'... "
elif ! [[ "$EmailAddress" =~ $email_regex ]];then
       echo "You have entered wrong email address and aborting this script"
else
   echo "mail will send to "$EmailAddress" ..."
   export_function "$EnvName" "$ObjType" "$ObjName"
fi



#if [ $# -ne 4 ] ;then
#   echo "Please make sure your 4 argument"
#  echo "Usage ./export.sh env_name object_type object_name email_id"
#else
#   #calling function user input
#   user_input "$1" "$2" "$3" "$4"
#fi
 
#calling function user input
#user_input
#calling function file_rename
#file_rename
#calling function email_sending
#email_sending

