#/bin/bash

##
# docker run -d -v /home/fpascual:/workspace -v /root/.docker/config.json:/root/.docker/config.json --privileged --name docker-test-staging quay.io/powercloud/docker-ce-build
# docker exec -it docker-test-staging /bin/bash
##
#set -eux

set -ue

set -o allexport
source env.list
source env-distrib.list

DIR_TEST="/workspace/test-staging_docker-ce-${DOCKER_VERS}_containerd-${CONTAINERD_VERS}"
PATH_DOCKERFILE="${PATH_SCRIPTS}/test-staging/test"
PATH_TEST_ERRORS="${DIR_TEST}/errors.txt"


echo "# Dockerd #" 
# sh ${PATH_SCRIPTS}/dockerd-entrypoint.sh &
source ${PATH_SCRIPTS}/dockerd-starting.sh

if [ -z "$pid" ]
then
    echo "There is no docker daemon."  
    exit 1
else
    if ! test -d ${DIR_TEST}
    then
        mkdir -p "${DIR_TEST}"
    fi
    if ! test -f ${PATH_TEST_ERRORS}
    then 
        touch ${PATH_TEST_ERRORS}
    else
        rm ${PATH_TEST_ERRORS}
        touch ${PATH_TEST_ERRORS}
    fi
    if ! test -d /root/.docker 
    then
        echo "# Docker login #" 
        mkdir /root/.docker
        echo "${DOCKER_SECRET_AUTH}" > /root/.docker/config.json
    fi
    if grep -Fq "index.docker.io" /root/.docker/config.json
    then
        for PACKTYPE in DEBS RPMS
        do
            echo "## Looking for distro type: ${PACKTYPE} ##" 
            # Copying
            cp ${PATH_SCRIPTS}/test_launch.sh ${PATH_DOCKERFILE}-${PACKTYPE}

            for DISTRO in ${!PACKTYPE} 
            do
                echo "### Looking for ${DISTRO} ###" 
                DISTRO_NAME="$(cut -d'-' -f1 <<<"${DISTRO}")"
                DISTRO_VERS="$(cut -d'-' -f2 <<<"${DISTRO}")"
                IMAGE_NAME="t_docker_${DISTRO_NAME}_${DISTRO_VERS}"
                CONT_NAME="t_docker_run_${DISTRO_NAME}_${DISTRO_VERS}"
                BUILD_LOG="build_${DISTRO_NAME}_${DISTRO_VERS}.log"
                TEST_LOG="test_${DISTRO_NAME}_${DISTRO_VERS}.log"

                export DISTRO_NAME
                # get in the tmp directory and copy the Dockerfile
                if ! test -d tmp
                then
                    mkdir tmp
                else 
                    rm -rf tmp
                    mkdir tmp
                fi

                echo "### # Building the test image: ${IMAGE_NAME} # ###"
                docker build -t ${IMAGE_NAME} --build-arg DISTRO_NAME=${DISTRO_NAME} --build-arg DISTRO_VERS=${DISTRO_VERS} ${PATH_DOCKERFILE}-${PACKTYPE}/Dockerfile

                if [[ $? -ne 0 ]]; then
                    echo "ERROR: docker build failed for ${DISTRO}, see details from '${BUILD_LOG}'"
                    continue
                else
                    echo "docker build done"
                fi

                echo "### # Running the tests from the container: ${CONT_NAME} # ###"
                docker run --env DOCKER_SECRET_AUTH --env DISTRO_NAME --env PATH_SCRIPTS -d -v /workspace:/workspace --privileged --name $CONT_NAME ${IMAGE_NAME}

                status_code="$(docker container wait $CONT_NAME)"
                if [[ ${status_code} -ne 0 ]]; then
                    echo "ERROR: The test suite failed for ${DISTRO}. See details from '${TEST_LOG}'"
                    docker logs $CONT_NAME 2>&1 | tee ${DIR_TEST}/${TEST_LOG}
                else
                    docker logs $CONT_NAME 2>&1 | tee ${DIR_TEST}/${TEST_LOG}
                    echo "Tests done"
                fi

                echo "### # Cleanup: ${CONT_NAME} # ###"
                docker stop ${CONT_NAME}
                docker rm ${CONT_NAME}
                docker image rm ${IMAGE_NAME}

                if test -f ${DIR_TEST}/${TEST_LOG}
                then
                    echo "### # Checking the logs # ###"
                    echo "DISTRO ${DISTRO_NAME} ${DISTRO_VERS}" 2>&1 | tee -a ${PATH_TEST_ERRORS}
                    
                    TEST_1=$(eval "cat ${DIR_TEST}/${TEST_LOG} | grep exitCode | awk 'NR==2' | rev | cut -d' ' -f 1")
                    echo "TestDistro : ${TEST_1}" 2>&1 | tee -a ${PATH_TEST_ERRORS} 

                    TEST_2=$(eval "cat ${DIR_TEST}/${TEST_LOG} | grep exitCode | awk 'NR==3' | rev | cut -d' ' -f 1")
                    echo "TestDistroInstallPackage : ${TEST_2}" 2>&1 | tee -a ${PATH_TEST_ERRORS} 

                    TEST_3=$(eval "cat ${DIR_TEST}/${TEST_LOG} | grep exitCode | awk 'NR==4' | rev | cut -d' ' -f 1")
                    echo "TestDistroPackageCheck : ${TEST_3}" 2>&1 | tee -a ${PATH_TEST_ERRORS} 

                    [[ "$TEST_1" -eq "0" ]] && [[ "$TEST_2" -eq "0" ]] && [[ "$TEST_3" -eq "0" ]]
                    echo "All : $?" 2>&1 | tee -a ${PATH_TEST_ERRORS} 
                    tail -5 ${PATH_TEST_ERRORS}
                else 
                    echo "There is no ${TEST_LOG} file."
                fi
            done
        done
    fi
fi