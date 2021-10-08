#!/bin/bash
# Script checking the test_errors.txt file generated by the test.sh script

set -ue

set -o allexport
source env.list
source env-distrib.list

# check errors 
DIR_TEST="/workspace/test_docker-ce-${DOCKER_VERS}_containerd-${CONTAINERD_VERS}"
PATH_TEST_ERRORS="${DIR_TEST}/errors.txt"

if ! test -f ${PATH_TEST_ERRORS}
then
    echo "There is no file ${PATH_TEST_ERRORS} with the errors." 
    # push ERROR
    CHECK_TESTS_BOOL="ERR"
fi

ls ${DIR_TEST} 
# check that for each distrib of each packtype, we have a build log and a test log
# check if no error in the test log
NB_DEBS=$(eval "awk -F\- '{print NF-1}' /workspace/env-distrib.list | awk 'NR==1'")
NB_RPMS=$(eval "awk -F\- '{print NF-1}' /workspace/env-distrib.list | awk 'NR==2'")
NB_DISTROS=$(expr ${NB_DEBS} + ${NB_RPMS})
NB_BUILD_LOGS=$(eval "find ${DIR_TEST}/build* | wc -l")
NB_TEST_LOGS=$(eval "find ${DIR_TEST}/test* | wc -l")
echo "Nb of build logs : ${NB_BUILD_LOGS}" 
echo "Nb of test logs : ${NB_TEST_LOGS}" 
DISTROS=$(eval "echo $DEBS $RPMS | tr '-' '_'")
if [[ ${NB_BUILD_LOGS} -ne 0 ]] && [[ ${NB_TEST_LOGS} -ne 0 ]]
then
    if [[ ${NB_BUILD_LOGS} == ${NB_DISTROS} ]] && [[ ${NB_TEST_LOGS} == ${NB_DISTROS} ]]
    then
        # check if there are any 1 in the ${PATH_TEST_ERRORS}
        echo "# Check the file #" 
        TOTAL_ERRORS=$(eval "grep -c 1 ${PATH_TEST_ERRORS}")
        if [[ ${TOTAL_ERRORS} -eq 0 ]]
        then
            echo "There is no error in the test log files. We can push to the shared COS Bucket. " 
            # push NO ERROR
            CHECK_TESTS_BOOL="NOERR"
        else 
            echo "We have every log but there are errors in the test log files. " 
            # push ERROR
            CHECK_TESTS_BOOL="ERR"
        fi
    else 
        # error and push to cos bucket ERR
        echo "There are build or test log files missing. " 
        # check which test log files are missing
        for DISTRO in ${DISTROS}
        do
            TEST_LOG="${DIR_TEST}/test_${DISTRO}.log"
            find ${TEST_LOG} 
            if [[ $? -ne 0 ]]
            then
                # print the DISTRO in the {PATH_TEST_ERRORS} 
                DISTRO_NAME="$(cut -d'-' -f1 <<<"${DISTRO}")"
                DISTRO_VERS="$(cut -d'-' -f2 <<<"${DISTRO}")"
                echo "DISTRO ${DISTRO_NAME} ${DISTRO_VERS}" 
                echo "Missing" 
            fi
        done
        TOTAL_MISSING=$(eval "grep -c "Missing" ${PATH_TEST_ERRORS}")
        TOTAL_ERRORS=$(eval "grep -c 1 ${PATH_TEST_ERRORS}")
        echo "There are ${TOTAL_MISSING} test log files missing and there are ${TOTAL_ERRORS} errors for the existing test log files." 
        # push ERROR
        CHECK_TESTS_BOOL="ERR"

    fi
    echo "There are no build logs or no test logs." 
    # push ERROR
    CHECK_TESTS_BOOL="ERR"
fi
