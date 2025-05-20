#!/usr/bin/env bash

echo "Will move not ignored files to directory ${1}"
echo "In preparation for MonoRepo"
if [ -z ${1} ]; then
  echo "ERROR: Missing dir as argument!"
  exit 1
fi

DIR=${1}
mkdir -p ${DIR}
git mv -k * ${DIR}
git mv -k .* ${DIR}
git commit -m "Prepare ${DIR} for monorepo"
