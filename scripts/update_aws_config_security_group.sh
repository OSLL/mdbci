group_name=$1
aws --output json ec2 create-security-group --group-name ${group_name} --description 'MDBCI ${group_name} security group'
if [[ $? == 0 ]]; then
  sed -i "s|security_groups : \[\(.*\)\]|security_groups : [ 'default', '${group_name}' ]|g" aws-config.yml
  echo "Security group ${group_name} added to aws-config.yml!"
else
  echo 'Error occured!'
fi
