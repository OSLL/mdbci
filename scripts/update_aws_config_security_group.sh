group_name=$1
aws  --profile mdbci --output json ec2 create-security-group --group-name ${group_name} --description "MDBCI ${group_name} security group"
if [[ $? == 0 ]]; then
  sed -i "s|security_groups : \[\(.*\)\]|security_groups : [ 'default', '${group_name}' ]|g" aws-config.yml
  echo "Security group ${group_name} added to aws-config.yml!"
  aws  --profile mdbci --output json ec2 authorize-security-group-ingress --group-name ${group_name} --ip-permissions '[{"PrefixListIds":[],"FromPort":0,"IpRanges":[{"CidrIp":"0.0.0.0/0"}],"ToPort":65535,"IpProtocol":"tcp","UserIdGroupPairs":[],"Ipv6Ranges":[]},{"PrefixListIds":[],"FromPort":0,"IpRanges":[{"CidrIp":"0.0.0.0/0"}],"ToPort":65535,"IpProtocol":"udp","UserIdGroupPairs":[],"Ipv6Ranges":[]},{"PrefixListIds":[],"FromPort":0,"IpRanges":[{"CidrIp":"0.0.0.0/0"}],"ToPort":-1,"IpProtocol":"icmp","UserIdGroupPairs":[],"Ipv6Ranges":[]}]'
  if [[ $? == 0 ]]; then
    echo "Security group ${group_name} configured!"
  else
    echo "Error occured while configuring security group ${group_name}!"
  fi
else
  echo echo "Error occured while creating security group ${group_name}!"
fi
