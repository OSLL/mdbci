#!/bin/bash

#TERMINATED=false

#function handle_int()
#{
#    echo "FUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUCK"
#    kill $(ps -o pid= --ppid $$)
#    exit 1
#}

#trap handle_int INT

GLOBAL_PREFIX='full_configs_test'
TEMPLATE_COOKBOOK_PATH='cookbook_path'
TEMPLATE_AWS_CONFIG='aws_config'
CONFIGS_DIRECTORY='confs'

AWS='aws'
DOCKER='docker'
VBOX='vbox'
LIBVIRT='libvirt'
MDBCI_BOXES=('ppc64' 'ppc64be')


# $1 - template_path
function validate_template(){
  ./mdbci validate_template --template $1 &
}

# $1 - template_path
# $2 - config_name
function generate_config(){
  ./mdbci --template $1 generate $2 &
}

# $1 - config_name
function up_config(){
  ./mdbci up $1 &
}

# $1 - config_name
function ssh_config(){
  ./mdbci ssh --command ls $1 &
}

function clear_environment(){
   ls "${CONFIGS_DIRECTORY}" | while read template; do
    local config="${GLOBAL_PREFIX}_$(get_config_name ${CONFIGS_DIRECTORY}/${template})"
    echo "----Removing config in: ${config}----"
    if [[ -n $(ls | grep "${config}") ]]; then
        if [[ -z $(ls "${config}" | grep "mdbci_template") ]]; then
          local root_dir="$(pwd)"
          cd "${config}"
          vagrant destroy -f
          cd "$root_dir"
        fi
        rm -rf "${config}"
    fi
    echo "-----------------------------------------------"
  done
  rm -rf ${GLOBAL_PREFIX}
}

function create_environment(){
    mkdir ${GLOBAL_PREFIX}
}

function create_nodes_files(){
  ls "${CONFIGS_DIRECTORY}" | while read template; do
    local config="${GLOBAL_PREFIX}_$(get_config_name ${CONFIGS_DIRECTORY}/${template})"
    echo "----Acquiring nodes for template: ${CONFIGS_DIRECTORY}/${template} in $config----"
    ruby <<-EORUBY
  require 'json'
  nodes = Array.new
  template = JSON.parse(File.read("${CONFIGS_DIRECTORY}/${template}"))
  template.each do |possible_node|
    if possible_node[0] != "${TEMPLATE_AWS_CONFIG}" and possible_node[0] != "${TEMPLATE_COOKBOOK_PATH}"
      nodes.push possible_node[0]
    end
  end
  File.open("${config}/nodes", 'w') do |file|
    nodes.each do |node_name|
        file.puts node_name
    end
  end
EORUBY
  done
}

function create_boxes_files(){
  ls "${CONFIGS_DIRECTORY}" | while read template; do
    local config="${GLOBAL_PREFIX}_$(get_config_name ${CONFIGS_DIRECTORY}/${template})"
    echo "----Acquiring boxes for template: ${CONFIGS_DIRECTORY}/${template} in $config----"
    ruby <<-EORUBY
  require 'json'
  boxes = Array.new
  template = JSON.parse(File.read("${CONFIGS_DIRECTORY}/${template}"))
  template.each do |possible_box|
    if possible_box[0] != "${TEMPLATE_AWS_CONFIG}" and possible_box[0] != "${TEMPLATE_COOKBOOK_PATH}"
      boxes.push possible_box[1]['box']
    end
  end
  File.open("${config}/boxes", 'w') do |file|
    boxes.each do |box_name|
        file.puts box_name
    end
  end
EORUBY
  done

}

# $1 - template_path
function get_config_name(){
    local config="${CONFIGS_DIRECTORY}/${1}"
    config=${config##*/}
    config=${config%.*}
    echo "$config"
}

function validate_templates(){
  ls "${CONFIGS_DIRECTORY}" | while read template; do
    echo "----Validating template: ${CONFIGS_DIRECTORY}/${template}----"
    local config="$(get_config_name ${CONFIGS_DIRECTORY}/${template})"
    validate_template "${CONFIGS_DIRECTORY}/${template}"
    if [[ "$?" -ne "0" ]]; then
        echo "----ERROR----"
        echo "----Validating template: ${CONFIGS_DIRECTORY}/${template} FAILED----"
        mkdir "$GLOBAL_PREFIX/$config"
        touch "$GLOBAL_PREFIX/$config/validate"
    fi
    echo "-----------------------------------------------"
  done
}

function generate_configs(){
  ls "${CONFIGS_DIRECTORY}" | while read template; do
    echo "----Generating config: ${CONFIGS_DIRECTORY}/${template}----"
    local config="$(get_config_name ${CONFIGS_DIRECTORY}/${template})"
    generate_config "${CONFIGS_DIRECTORY}/${template}" "${GLOBAL_PREFIX}_${config}"
    if [[ "$?" -ne "0" ]]; then
        echo "----ERROR----"
        echo "----Generating template: ${CONFIGS_DIRECTORY}/${template} FAILED----"
        mkdir "$GLOBAL_PREFIX/$config"
        touch "$GLOBAL_PREFIX/$config/generate"
    fi
    echo "-----------------------------------------------"
  done
}

function up_configs(){
  ls "${CONFIGS_DIRECTORY}" | while read template; do
    echo "----Starting config: ${CONFIGS_DIRECTORY}/${template}----"
    local config="${GLOBAL_PREFIX}_$(get_config_name ${CONFIGS_DIRECTORY}/${template})"

    ##################################################################
    #               Excluding VBOX and MDBCI prpvoders               #
    ##################################################################
    if [[ -n $(cat ${config}/boxes | grep ${VBOX}) ]]; then
        continue
    fi
    if [[ -n $(cat ${config}/boxes | grep ${MDBCI_BOXES[0]}) ]]; then
        continue
    fi
    if [[ -n $(cat ${config}/boxes | grep ${MDBCI_BOXES[1]}) ]]; then
        continue
    fi
    ##################################################################

    up_config "${config}"
    if [[ "$?" -ne "0" ]]; then
        echo "----ERROR----"
        echo "----Starting template: ${CONFIGS_DIRECTORY}/${template} FAILED----"
        mkdir "$GLOBAL_PREFIX/$config"
        touch "$GLOBAL_PREFIX/$config/up"
    fi
    echo "-----------------------------------------------"
  done
}

function ssh_configs(){
  ls "${CONFIGS_DIRECTORY}" | while read template; do
    echo "----Ssh'ing config: ${CONFIGS_DIRECTORY}/${template}----"
    local config="${GLOBAL_PREFIX}_$(get_config_name ${CONFIGS_DIRECTORY}/${template})"

    ##################################################################
    #               Excluding VBOX and MDBCI prpvoders               #
    ##################################################################
    if [[ -n $(cat ${config}/boxes | grep ${VBOX}) ]]; then
        continue
    fi
    if [[ -n $(cat ${config}/boxes | grep ${MDBCI_BOXES[0]}) ]]; then
        continue
    fi
    if [[ -n $(cat ${config}/boxes | grep ${MDBCI_BOXES[1]}) ]]; then
        continue
    fi
    ##################################################################

    ssh_config "${config}"
    if [[ "$?" -ne "0" ]]; then
        echo "----ERROR----"
        echo "----Ssh'ing template: ${CONFIGS_DIRECTORY}/${template} FAILED----"
        mkdir "$GLOBAL_PREFIX/$config"
        touch "$GLOBAL_PREFIX/$config/ssh"
    fi
    echo "-----------------------------------------------"
  done
}

clear_environment
create_environment
validate_templates
generate_configs
create_boxes_files
create_nodes_files
up_configs