#/bin/bash

##
#set -eux

##
#List of RPM based and DEB based distros to test
##

if [[ ! -f env-distrib.list ]]
then
  DEBS="debian-bullseye debian-buster ubuntu-bionic ubuntu-focal ubuntu-groovy ubuntu-hirsute"
  RPMS="centos-7 centos-8 fedora-33 fedora-34"
else
  set -o allexport
  source env-distrib.list
fi

DATE=`date +%d%m%y-%H%S`
DIR_TEST="/test-${DATE}"
PATH_TEST="docker_ce_build_ppc64/test"


if ! test -d ${DIR_TEST}
then
  mkdir ${DIR_TEST}
fi

. ./docker_ce_build_ppc64/dockerd-starting.sh
if ! test -d /root/.docker 
  then
    mkdir /root/.docker
    echo "$SECRET_AUTH" > /root/.docker/config.json
  fi
  if grep -Fq "index.docker.io" /root/.docker/config.json
  then
  # docker login
    if [ ! -z "$pid" ]
    then
      if [[ ! -d "result" ]] ; then mkdir result; fi
      if [[ ! -d "tmp" ]] ; then mkdir tmp; fi

      pushd tmp

      for PACKTYPE in RPMS DEBS
      do
        echo "* Looking for distro type: ${PACKTYPE}"
        cp ../${PACKTYPE}/Dockerfile .

        for DISTRO in ${PACKTYPE} ; do

          echo "** Looking for ${DISTRO}"
          DISTRO_NAME="$(cut -d'-' -f1 <<<"${DISTRO}")"
          DISTRO_VER="$(cut -d'-' -f2 <<<"${DISTRO}")"
          IMAGE_NAME="t_docker_${DISTRO_NAME}_${DISTRO_VER}"
          CONT_NAME="t_docker_run_${DISTRO_NAME}_${DISTRO_VER}"
          BUILD_LOG="build_${DISTRO_NAME}_${DISTRO_VER}.log"
          TEST_LOG="test_${DISTRO_NAME}_${DISTRO_VER}.log"

          echo "*** Building the test image: ${IMAGE_NAME}"
          docker build -t ${IMAGE_NAME} --build-arg DISTRO_NAME=${DISTRO_NAME} --build-arg DISTRO_VER=${DISTRO_VER}  . &> ../result/${BUILD_LOG}

          if [[ $? -ne 0 ]]; then
            echo "ERROR: docker build failed for $DISTRO, see details below from '$BUILD_LOG'"
            tail ../result/$BUILD_LOG
            continue
          fi

          echo "*** Runing the tests from the container: $CONT_NAME"
          docker run -d -v ~/.docker:/root/.docker --privileged  --name $CONT_NAME $IMAGE_NAME

          if [[ $? -ne 0 ]]; then
            echo "ERROR: docker run failed for $DISTRO. Calling docker logs $CONT_NAME"
            docker logs $CONT_NAME

            echo "*** Cleanup: $CONT_NAME"
            docker stop $CONT_NAME
            docker rm $CONT_NAME
            continue
          fi

          docker exec $CONT_NAME /bin/bash /launch_test.sh $DISTRO_NAME  &> ../result/$TEST_LOG
          if [[ $? -ne 0 ]]; then
            echo "ERROR: The test suite failed for $DISTRO. See details below from '$TEST_LOG'"
            tail ../result/$TEST_LOG
          fi

          echo "*** Grepping for any potential tests errors from $TEST_LOG"
          grep -i err  ../result/$TEST_LOG

          echo "*** Cleanup: $CONT_NAME"
          docker stop $CONT_NAME
          docker rm $CONT_NAME
          docker image rm $IMAGE_NAME
        done

        rm Dockerfile
      done

      #popd (tmp)
      popd

      cp -r result  ${DIR_TEST}

    fi
  fi
fi