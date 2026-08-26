#!/bin/bash
# Copyright Advanced Micro Devices, Inc.
# Licensed under the Apache License Version 2.0

function fail {
    echo FAIL: $@
    exit -1
}

function usage {
    echo "Usage: $0 backend device [coverage (on or off)]"
}

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    usage
    fail "Error: must specify backend and device and optionally coverage"
fi

export DGLBACKEND=$1
export DGLTESTDEV=$2
export COVERAGE=${3:-"off"}
export DGL_LIBRARY_PATH=${PWD}/build
export PYTHONPATH=tests:${PWD}/python:$PYTHONPATH
export DGL_DOWNLOAD_DIR=${PWD}/_download
export TF_FORCE_GPU_ALLOW_GROWTH=true
unset TORCH_ALLOW_TF32_CUBLAS_OVERRIDE

if [ $2 == "gpu" ] 
then
  export CUDA_VISIBLE_DEVICES=0
else
  export CUDA_VISIBLE_DEVICES=-1
fi

echo "pytests running without Logger"

python3 -m pip install expecttest

if [ ${COVERAGE} == "off" ]; then
  echo "pytests running without coverage"
  python3 -m pytest --junitxml=pytest_dgl_import.xml --durations=100 --disable-warnings tests/python/test_dgl_import.py
  python3 -m pytest --junitxml=pytest_common.xml  --durations=100 --disable-warnings tests/python/common
  python3 -m pytest --junitxml=pytest_backend.xml --durations=100 --disable-warnings tests/python/$DGLBACKEND

elif [ ${COVERAGE} == "on" ]; then
  echo "pytests running with coverage"
  python3 -m pip install pytest-cov
  python3 -m pytest --cov=dgl              --cov-report=lcov:lcov_pytest_import.info  --disable-warnings tests/python/test_dgl_import.py
  python3 -m pytest --cov=dgl --cov-append --cov-report=lcov:lcov_pytest_common.info  --disable-warnings tests/python/common
  python3 -m pytest --cov=dgl --cov-append --cov-report=lcov:lcov_pytest_backend.info --disable-warnings tests/python/$DGLBACKEND

  # TODO need to add docs for installing lcov
  lcov --add-tracefile lcov_pytest_backend.info -a lcov_pytest_common.info -a lcov_pytest_import.info -o lcov_pytest.info

  # Show summary of coverage
  coverage report -m | tee python_coverage_report.txt

else
  fail "Error: invalid coverage option: ${COVERAGE}"
fi

exit_code=$?
echo "pytest exited with code: $exit_code"

exit $exit_code
