#!/bin/bash

set -o allexport
source env.list
source env-distrib.list

ls /workspace
echo $DOCKER_VERS
echo $CONTAINERD_VERS
# check errors 
DIR_TEST="/workspace/test_docker-ce-${DOCKER_VERS}_containerd-${CONTAINERD_VERS}"
ls ${DIR_TEST}
# check that for each distrib of each packtype, we have a build log and a test log
# check if no error in the test log
NB_DEBS=$(eval "awk -F\- '{print NF-1}' /workspace/env-distrib.list | awk 'NR==1'")
NB_RPMS=$(eval "awk -F\- '{print NF-1}' /workspace/env-distrib.list | awk 'NR==2'")
NB_DISTROS=$(expr ${NB_DEBS} + ${NB_RPMS})
NB_BUILD_LOGS=$(eval "find build* | wc -l")
NB_TEST_LOGS=$(eval "find test* | wc -l")
echo ${NB_BUILD_LOGS}
echo ${NB_TEST_LOGS}
if [[ ${NB_BUILD_LOGS} == ${NB_DISTROS} ]] && [[ ${NB_TEST_LOGS} == ${NB_DISTROS} ]]
then
    echo "NO ERROR"
    # check the test_logs
    DISTROS=$(eval "echo $DEBS $RPMS | tr '-' '_'")
    echo $DISTROS
    for DISTRO in ${DISTROS}
    do
        echo "XXXXXXX Check tests XXXXXXX"
        echo "DISTRO"
        echo "We check the test log of each distro"
        # There is three tests : TestDistro, TestDistroInstallPackage and TestDistroPackageCheck
        TEST_LOG="${DIR_TEST}/test_${DISTRO}.log"
        TEST_1=$(eval "cat $TEST_LOG | grep exitCode | awk 'NR==2' | cut -d' ' -f 5")
        TEST_2=$(eval "cat $TEST_LOG | grep exitCode | awk 'NR==3' | cut -d' ' -f 3")
        TEST_3=$(eval "cat $TEST_LOG | grep exitCode | awk 'NR==4' | cut -d' ' -f 3")
        if [[ ${TEST_1} -eq "0" ]]
        then
            echo "Test ${DISTRO} 1 OK"
        fi
        if [[ ${TEST_2} -eq "0" ]]
        then
            echo "Test ${DISTRO} 2 OK"
        fi
        if [[ ${TEST_3} -eq "0" ]]
        then
            echo "Test ${DISTRO} 3 OK"
        fi
    done
else 
    # error and push to cos bucket ERR
    echo "ERROR"
fi