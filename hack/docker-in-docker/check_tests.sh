#!/bin/bash

set -o allexport
source env.list
source env-distrib.list

PATH_TEST_ERRORS="/workspace/test_errors.txt"

if ! test -f ${PATH_TEST_ERRORS}
then 
    touch ${PATH_TEST_ERRORS}
else
    rm ${PATH_TEST_ERRORS}
    touch ${PATH_TEST_ERRORS}
fi
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
DISTROS=$(eval "echo $DEBS $RPMS | tr '-' '_'")
if [[ ${NB_BUILD_LOGS} -ne 0 ]] && [[ ${NB_TEST_LOGS} -ne 0 ]]
    if [[ ${NB_BUILD_LOGS} == ${NB_DISTROS} ]] && [[ ${NB_TEST_LOGS} == ${NB_DISTROS} ]]
    then
        echo "# Check tests #"
        # check the test_logs
        
        echo $DISTROS
        for DISTRO in ${DISTROS}
        do
            echo "## DISTRO $DISTRO ##" 2>&1 | tee -a ${PATH_TEST_ERRORS}
            # There is three tests : TestDistro, TestDistroInstallPackage and TestDistroPackageCheck
            TEST_LOG="${DIR_TEST}/test_${DISTRO}.log"

            TEST_1=$(eval "cat ${TEST_LOG} | grep exitCode | awk 'NR==2' | cut -d' ' -f 5")
            echo "TestDistro : ${TEST_1}" 2>&1 | tee -a ${PATH_TEST_ERRORS} 

            TEST_2=$(eval "cat ${TEST_LOG} | grep exitCode | awk 'NR==3' | cut -d' ' -f 3")
            echo "TestDistroInstallPackage : ${TEST_2}" 2>&1 | tee -a ${PATH_TEST_ERRORS} 

            TEST_3=$(eval "cat ${TEST_LOG} | grep exitCode | awk 'NR==4' | cut -d' ' -f 3")
            echo "TestDistroPackageCheck : ${TEST_3}" 2>&1 | tee -a ${PATH_TEST_ERRORS} 

            [[ "$TEST_1" -eq "0" ]] && [[ "$TEST_2" -eq "0" ]] && [[ "$TEST_3" -eq "0" ]]
            echo "All : $?" 2>&1 | tee -a ${PATH_TEST_ERRORS} 
        done
        # check if there are any 1 in the ${PATH_TEST_ERRORS}
        echo "### Check the files ###"
        TOTAL_ERRORS=$(eval "grep -c 1 ${PATH_TEST_ERRORS}")
        if [[ ${TOTAL_ERRORS} -eq 0 ]]
        then
            echo "There is no error in the test log files. We can push to the shared COS Bucket. " 
        else 
            echo "There are errors in the test log files. "
        fi
    else 
        # error and push to cos bucket ERR
        echo "There was an error of build."
        # check which test log files are missing
        for DISTRO in ${DISTROS}
        do
            TEST_LOG="${DIR_TEST}/test_${DISTRO}.log"
            find ${TEST_LOG}
            if [[ $? -eq 0 ]]
            then
            fi
        done


    fi
    echo "There are no build logs or no test logs." 2>&1 | tee -a ${PATH_LOG}
fi