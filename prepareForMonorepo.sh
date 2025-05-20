#!/usr/bin/env bash

echo "Will move not ignored files to directory ${1}"
echo "In preparation for MonoRepo"

case ${1} in
  '')
    echo "ERROR: Missing dir as argument!"
    exit 1
    ;;
  *)
    ;;
esac

DIR=${1}
mkdir -p ${DIR}
git mv -k * ${DIR}
git mv -k .* ${DIR}
git commit -m "Prepare \"${DIR}\" for monorepo"
