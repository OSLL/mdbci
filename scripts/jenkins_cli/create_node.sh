#!/bin/bash

# Arguments:
# 1. JENKINS_URL - url to jenkins system (http://maxscale-jenkins.mariadb.com:8090/)
# 2. NODE_NAME - uniquely identifies an agent within this Jenkins installation
# 3. NODE_DESCRIPTION - optional human-readable description for this agent, default:"This node created at $DATE by $USER"
# 4. ROOT_DIRECTORY - path to the agent machine.
# 5. NUM_EXECUTORS - the maximum number of concurrent builds that Jenkins may perform on this agent.
# 6. CRED_ID - credentials to be used for logging in to the remote host.
# 7. LABELS - to group multiple agents into one logical group
# example: ./create_node.sh http://maxscale-jenkins.mariadb.com:8090/ testNode "Some description" "/home/vagrant/" 20 vagrant test
JENKINS_URL=$1
NODE_NAME=$2
SSH_PORT=22
NODE_DESCRIPTION=$3
ROOT_DIRECTORY=$4
NUM_EXECUTORS=$5
CRED_ID=$6
LABELS=$7
USERID=${USER}

if [ -z "$NODE_DESCRIPTION" ]; then
   NODE_DESCRIPTION="This node created at $(date +%s) by ${USER}"
fi

cat <<EOF | java -jar ~/bin/jenkins-cli.jar -s $1 create-node $2
<slave>
  <name>${NODE_NAME}</name>
  <description>${NODE_DESCRIPTION}</description>
  <remoteFS>${ROOT_DIRECTORY}</remoteFS>
  <numExecutors>${NUM_EXECUTORS}</numExecutors>
  <mode>EXCLUSIVE</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.5">
    <host>${NODE_NAME}</host>
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