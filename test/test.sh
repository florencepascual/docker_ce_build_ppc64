#!/bin/bash

sh ./docker_ce_build_ppc64/dockerd-entrypoint.sh &
source ./docker_ce_build_ppc64/dockerd-starting.sh
echo $DAEMON
echo $pid


set -o allexport
source env.list
source env-distrib.list

DIR_TEST="/workspace/test_docker-ce-${DOCKER_VERS}_containerd-${CONTAINERD_VERS}"
PATH_DOCKERFILE="/workspace/docker_ce_build_ppc64/test"

if [ ! -z "$pid" ]
then
  if ! test -d ${DIR_TEST}
  then
    mkdir -p "${DIR_TEST}"
  fi
  if ! test -d /root/.docker 
  then
    mkdir /root/.docker
    echo "${SECRET_AUTH}" > /root/.docker/config.json
  fi
  if grep -Fq "index.docker.io" /root/.docker/config.json
  then
  # docker login
    for PACKTYPE in RPMS DEBS
    do
      echo "* Looking for distro type: ${PACKTYPE}"
      cp ${PATH_DOCKERFILE}/${PACKTYPE}/Dockerfile .
      
      for DISTRO in ${PACKTYPE} 
      do
        echo "** Looking for ${DISTRO}"
        DISTRO_NAME="$(cut -d'-' -f1 <<<"${DISTRO}")"
        DISTRO_VERS="$(cut -d'-' -f2 <<<"${DISTRO}")"
        IMAGE_NAME="t_docker_${DISTRO_NAME}_${DISTRO_VERS}"
        CONT_NAME="t_docker_run_${DISTRO_NAME}_${DISTRO_VERS}"
        BUILD_LOG="build_${DISTRO_NAME}_${DISTRO_VERS}.log"
        DOCKER_LOG="docker_${DISTRO_NAME}_${DISTRO_VERS}.log"
        TEST_LOG="test_${DISTRO_NAME}_${DISTRO_VERS}.log"

        echo "*** Building the test image: ${IMAGE_NAME}"
        docker build -t ${IMAGE_NAME} --build-arg DISTRO_NAME=${DISTRO_NAME} --build-arg DISTRO_VERS=${DISTRO_VERS} --build-arg DOCKER_VERS=${DOCKER_VERS} --build-arg CONTAINERD_VERS=${CONTAINERD_VERS} . &> ${DIR_TEST}/${BUILD_LOG}

        if [[ $? -ne 0 ]]; then
          echo "ERROR: docker build failed for ${DISTRO}, see details below from '${BUILD_LOG}'"
          continue
        fi

        echo "*** Running the tests from the container: ${CONT_NAME}"
        docker run -dt --env SECRET_AUTH -v /workspace/docker-ce-${DOCKER_VERS}:/workspace/docker-ce-${DOCKER_VERS} -v /workspace/containerd-${CONTAINERD_VERS}:/workspace/containerd-${CONTAINERD_VERS} -v /workspace/dockertest:/workspace/dockertest -v /workspace/docker_ce_build_ppc64:/workspace/docker_ce_build_ppc64 --privileged --name ${CONT_NAME} ${IMAGE_NAME}

        if [[ $? -ne 0 ]]; then
          echo "ERROR: docker run failed for ${DISTRO}. Calling docker logs ${CONT_NAME}"
          docker logs ${CONT_NAME} &> ${DIR_TEST}/${RUN_LOG}

          echo "*** Cleanup: ${CONT_NAME}"
          docker stop ${CONT_NAME}
          docker rm ${CONT_NAME}
          continue
        fi

        docker exec ${CONT_NAME} /bin/bash /workspace/docker_ce_build_ppc64/test_launch.sh ${DISTRO_NAME}  &> ${DIR_TEST}/${TEST_LOG}
        status_code="$(docker container wait $CONT_NAME)"
        if [[ status_code -ne 0 ]]; then
          echo "ERROR: The test suite failed for ${DISTRO}. See details below from '${TEST_LOG}'"
        fi

        echo "*** Grepping for any potential tests errors from ${TEST_LOG}"
        grep -i err  ${DIR_TEST}/${TEST_LOG}

        echo "*** Cleanup: ${CONT_NAME}"
        docker stop ${CONT_NAME}
        docker rm ${CONT_NAME}
        docker image rm ${IMAGE_NAME}
      done

      rm Dockerfile
    done
  fi
fi
