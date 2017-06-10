#!/bin/bash
# 
#set -xv
if [ $# -ne 1 ] ; then
   echo "Usage: $0 json-file"
   exit 1
fi
JSON=$1
if [ -f $JSON ] ; then
   echo "Checking file $JSON ..."
fi

BASEENV=variables.config

# centos image

centosami=$(aws ec2 describe-images --owners 'aws-marketplace' --filters 'Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce' --region us-west-2 --query Images[].[CreationDate,ImageId,Description] --output text | sort | tail -1)

# Debian image

debami=$(aws ec2 describe-images --owners 379101102735 --filters "Name=architecture,Values=x86_64" "Name=name,Values=debian-jessie-*" "Name=root-device-type,Values=ebs" "Name=virtualization-type,Values=hvm" --region us-west-2 --query Images[].[CreationDate,ImageId,Name] --output text | sort | tail -1 )
 
ENVFILE=logs/vars.env
NEWJSON=logs/new_$JSON

cp $BASEENV $ENVFILE
echo "$centosami" | awk '{print "AWS_CENTOS_AMI=" $2}' >> $ENVFILE
echo "$debami" | awk '{print "AWS_DEBIAN_AMI=" $2}' >> $ENVFILE

. $ENVFILE

cat $JSON | sed "s/AWS_DEBIAN_AMI/$AWS_DEBIAN_AMI/g" | sed "s/AWS_CENTOS_AMI/$AWS_CENTOS_AMI/g" > $NEWJSON

cat $NEWJSON
echo "Paching AMI ..."
packer build $NEWJSON
rm $ENVFILE
