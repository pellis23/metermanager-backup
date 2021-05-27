#!/bin/bash

### FUNCTIONS() ###
take_backup() {
	echo `date +%R`" Take backup..."
	DESTIN=metermanager-live-mysql-rds-`date +%Y-%m-%d`
	DBUCKET=s3://metermanager-backup-daily
	WBUCKET=s3://metermanager-backup-weekly

	export MYSQL_PWD=d8489dh498fh3489hf
  mysqldump -h metermanager-live-mysql-rds-old.cdbxehdrfxi7.eu-west-1.rds.amazonaws.com -u metermanager --skip-extended-insert MOL2 | aws s3 cp - $DBUCKET/$DESTIN
	#mysqldump -h metermanager-live-mysql-rds.cdbxehdrfxi7.eu-west-1.rds.amazonaws.com -u metermanager --skip-extended-insert MOL2 |gzip| aws s3 cp - $DBUCKET/$DESTIN
	EX_CODE=`echo $?`

	if [ "$EX_CODE" -gt "0" ] ; then
		echo `date +%R`" Backup failed..."
		aws sns publish --topic-arn arn:aws:sns:eu-west-1:902623068040:metermanager-slack --message "AWS Backup Account - backup command has failed!"
		exit_script
	fi
	echo `date +%R`" Backup taken..."
}

check_backup() {
	echo `date +%R`" Check_backup..."
	COPIED=`aws s3 ls $DBUCKET |grep $DESTIN|awk '{print $4}'`
	aws s3 ls $DBUCKET
	if [ "$COPIED" = "$DESTIN" ] ; then
		return
	else
		echo `date +%R`" No Match!"
		aws sns publish --topic-arn arn:aws:sns:eu-west-1:902623068040:metermanager-slack --message "AWS Backup Account - backup copy has failed!"
		exit_script
	fi
}

remove_oldest_copy() {
	echo `date +%R`" Remove oldest copy..."
	BNUM=`aws s3 ls $DBUCKET |sort|wc -l`
	FILE=`aws s3 ls $DBUCKET |sort|head -1|awk '{print $4}'`
	echo $BNUM
	if [ "$BNUM" -gt "5" ] ; then
		echo `date +%R`" Delete oldest backup!"
		aws s3 rm $DBUCKET/$FILE
		DEL_ERR=`echo $?`
		echo `date +%R`" aws s3 rm "$DBUCKET/$FILE
		if [ "$DEL_ERR" -gt "0" ] ; then
			aws sns publish --topic-arn arn:aws:sns:eu-west-1:902623068040:metermanager-slack --message "AWS Backup Account - remove oldest backup failed!"
		fi
	else
		echo `date +%R`" None to delete!"
		aws sns publish --topic-arn arn:aws:sns:eu-west-1:902623068040:metermanager-slack --message "AWS Backup Account - no oldest backup to delete!"
	fi
}

weekly_copy () {
	DAY=`date +%a`
	if [ "$DAY" = "Wed"] ; then
		echo `date +%R`" Weekly copy..."
		aws s3 cp $DBUCKET/$DESTIN $WBUCKET/$DESTIN
		COPY_ERR=`echo $?`
		if [ "$COPY_ERR" -gt "0" ] ; then
			aws sns publish --topic-arn arn:aws:sns:eu-west-1:902623068040:metermanager-slack --message "AWS Backup Account - weekly copy command has failed!"
			exit_script
		fi
         fi
}

remove_oldest_weekly_copy() {
	echo `date +%R`" Remove oldest weekly copy..."
	BNUM=`aws s3 ls $WBUCKET |sort|wc -l`
	FILE=`aws s3 ls $WBUCKET |sort|head -1|awk '{print $4}'`
	echo $BNUM
	if [ "$BNUM" -gt "3" ] ; then
		echo `date +%R`" Delete oldest backup!"
		aws s3 rm $WBUCKET/$FILE
		DEL_ERR=`echo $?`
		echo `date +%R`" aws s3 rm "$WBUCKET/$FILE
		if [ "$DEL_ERR" -gt "0" ] ; then
			aws sns publish --topic-arn arn:aws:sns:eu-west-1:902623068040:metermanager-slack --message "AWS Backup Account - remove oldest weekly backup failed!"
		fi
	else
		echo `date +%R`" None to delete!"
		aws sns publish --topic-arn arn:aws:sns:eu-west-1:902623068040:metermanager-slack --message "AWS Backup Account - no oldest weekly backup to delete!"
	fi}

exit_script() {
	echo `date +%R`" End the script..."
	/usr/local/bin/python -m awslambdaric app.handler
	exit
}

### The Script ###
echo `date +%R`" Start the script...."
take_backup
check_backup
remove_oldest_copy
weekly_copy
remove_oldest_weekly_copy
exit_script

