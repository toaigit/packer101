#!/bin/bash
#  this script will create environment variables of the existing EC2
#  that you may need later in packer or terraform.
#      such as key-pair, subnet-id, image-id, instance-type, security group. 

if [ $# -ne 3 ] ; then
   echo "Usage: $0 instanceID profile envfile"
   echo "  profile is your AWS profile ( $HOME/.aws/credential)"
   echo "  envfile is the new filename contained variables."
   exit 1
fi

INSTANCEID=$1
PROF=$2
CONFIG=$3

USERDATA=logs/${INSTANCEID}_userdata.txt

# get the userdata of the current instance and save it in logs/ folder

aws ec2 describe-instance-attribute --instance-id $INSTANCEID \
  --profile $PROF --attribute "userData" --output text | \
   grep USERDATA | awk '{print $2}' | base64 --decode > $USERDATA

# get SubnetID, ImageID, InstanceType and Security Group of the EC2 instance.

TMPVAR=$(aws ec2 describe-instances --instance-id $INSTANCEID --profile $PROF --query "Reservations[].Instances[][KeyName,SubnetId,ImageId,InstanceType,SecurityGroups[].GroupId]" --output text | sed '$!N;s/\n/ /' )

# store all the values in the envfile
KEYPAIR=`echo $TMPVAR | awk '{print $1}'`
SUBNETID=`echo $TMPVAR | awk '{print $2}'`
IMAGEID=`echo $TMPVAR | awk '{print $3}'`
INSTTYPE=`echo $TMPVAR | awk '{print $4}'`
SGID=`echo $TMPVAR | awk '{print $5}'`

# get the image description

IMAGEDESC=$(aws ec2 describe-images --image-ids $IMAGEID --query "Images[].Description" --profile $PROF --output text)

# get the image name

IMAGENAME=$(aws ec2 describe-images --image-ids $IMAGEID --query "Images[].Name"  --output text)

# get the autoscale name and Launch Configuration Name

TMPVAR=$(aws autoscaling describe-auto-scaling-instances --instance-ids $INSTANCEID --profile $PROF \
    --query "AutoScalingInstances[].[AutoScalingGroupName,LaunchConfigurationName]" --output text)
ASCGROUP=`echo $TMPVAR | awk '{print $1}'`
LCNAME=`echo $TMPVAR | awk '{print $2}'`

# get the instance profile name

IAMROLE=$(aws ec2 describe-instances --instance-id $INSTANCEID --profile $PROF  \
     --query "Reservations[].Instances[][IamInstanceProfile.Arn]" --output text | awk -F/ '{print $2}')

#  create environment variables in a file
cat <<EOF > $CONFIG
INSTANCETYPE=$INSTTYPE
IMAGEDESC="$IMAGEDESC"
IMAGENAME=$IMAGENAME
KEYPAIR=$KEYPAIR
SUBNETID=$SUBNETID
SGID=$SGID
IMAGEID=$IMAGEID
INSTTYPE=$INSTTYPE
ASCGROUP=$ASCGROUP
LCNAME=$LCNAME
IAMROLE=$IAMROLE
EOF

#  set the environment variables for the shell
chmod 750 $CONFIG

#  end of the ec2-info.sh
