#!/bin/bash
set -e

function printMessage(){
  blue=`tput setaf 4`
  green=`tput setaf 2`
  reset=`tput sgr0`
  echo ""
  echo "-----------------------------------------------------------------" 
  echo "[${blue}INFO${reset}] ${green}$1${reset}"
  echo "-----------------------------------------------------------------" 
  echo ""
}

snapshot_tag="-SNAPSHOT"

resources_directory=${PWD##*/}
resources_directory=${resources_directory:-/} 

search_dir=..

suffix=`date "+%Y%m%d-%H%M%S"`

for entry in "$search_dir"/*
do
  is_snapshot=false
  if [[ $entry == *${resources_directory} ]]; then
    echo "skipping $entry"
  else
    temporal_version=$(mvn -f ${entry} -q -U -Dexpression=project.version -DforceStdout help:evaluate)
    artifact_id=$(mvn -f ${entry} -q -U -Dexpression=project.artifactId -DforceStdout help:evaluate)
    original_version=$(mvn -f ${entry} -q -U -Dexpression=project.version -DforceStdout help:evaluate)
    if [[ $temporal_version == *${snapshot_tag} ]]; then
      temporal_version=${temporal_version/${snapshot_tag}/""}
      is_snapshot=true
    fi    
    
    temporal_version="$temporal_version-$suffix"
    
    tmp_pom_file=${entry}/${suffix}-pom.xml.tmp
    cp ${entry}/pom.xml ${tmp_pom_file}
    mvn -T 1C -f ${tmp_pom_file} -U -DgenerateBackupPoms=false versions:set -DnewVersion=${temporal_version}
    mvn -T 1C -f ${tmp_pom_file} clean package -Dmaven.test.skip=true
    rm ${tmp_pom_file}
    
    tmp_dockerfile=${entry}/${suffix}-Dockerfile.tmp
    cp ${entry}/Dockerfile ${tmp_dockerfile}
    replace_args_cmd="s/app.jar/$temporal_version-app.jar/g"
    sed -i ${replace_args_cmd} ${tmp_dockerfile}
    docker_build_cmd="docker build -t ngineapps/$artifact_id:$temporal_version $entry -f $entry/$tmp_dockerfile"
    eval $docker_build_cmd
    rm ${tmp_dockerfile}    

    replace_args_cmd="\"s/$artifact_id[:]*[0-9.-]*/$artifact_id:${temporal_version}/g\""
    replace_args_cmd="sed -i -e ${replace_args_cmd} docker-compose.yml"
    eval $replace_args_cmd

  fi
done


docker_compose_up_cmd="docker-compose up"
eval $docker_compose_up_cmd

