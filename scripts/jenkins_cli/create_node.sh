#!/bin/bash

# Arguments:
# 1. JENKINS_URL - url to jenkins system (http://maxscale-jenkins.mariadb.com:8090/)
# 2. NODE_NAME - uniquely identifies an agent within this Jenkins installation
# 3. HOST - to SSH connection.
# 4. NODE_DESCRIPTION - optional human-readable description for this agent, default:"This node created at $DATE by $USER"
# 5. ROOT_DIRECTORY - path to the agent machine.
# 6. NUM_EXECUTORS - the maximum number of concurrent builds that Jenkins may perform on this agent.
# 7. CRED_ID - credentials to be used for logging in to the remote host.
# 8. LABELS - to group multiple agents into one logical group
# 9. PATH_TO_JAR - path to jenkins-cli.jar.
# example: 
# ./create_node.sh http://maxscale-jenkins.mariadb.com:8090/ testNode test-node.mariadb.com "Some description" "/home/vagrant/" 20 vagrant test

JENKINS_URL=$1
NODE_NAME=$2
HOST=$3
SSH_PORT=22
NODE_DESCRIPTION=$4
ROOT_DIRECTORY=$5
NUM_EXECUTORS=$6
CRED_ID=$7
LABELS=$8
USERID=${USER}
PATH_TO_JAR=$9

if [ -z "$NODE_DESCRIPTION" ]; then
   NODE_DESCRIPTION="This node created at $(date +%s)"
fi

if [ -z "$PATH_TO_JAR" ]; then
    PATH_TO_JAR="/home/vagrant/.jenkins/war/WEB-INF"
fi

cat <<EOF | java -jar $PATH_TO_JAR/jenkins-cli.jar -s $1 create-node $2
<slave>
  <name>${NODE_NAME}</name>
  <description>${NODE_DESCRIPTION}</description>
  <remoteFS>${ROOT_DIRECTORY}</remoteFS>
  <numExecutors>${NUM_EXECUTORS}</numExecutors>
  <mode>EXCLUSIVE</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.5">
    <host>${HOST}</host>
    <port>${SSH_PORT}</port>
    <credentialsId>${CRED_ID}</credentialsId>
    <maxNumRetries>0</maxNumRetries>
    <retryWaitTime>0</retryWaitTime>
  </launcher>
  <label>${LABELS}</label>
  <nodeProperties/>
  <userId>${USERID}</userId>
</slave>
EOF