#!/bin/bash

# Script copied from: https://github.com/tzapu/WiFiManager/blob/master/travis/common.sh

function build_examples()
{
  # track the exit code for this platform
  local exit_code=0
  # loop through results and add them to the array
  examples=($(find $PWD/examples/ -name "*.pde" -o -name "*.ino"))

  # get the last example in the array
  local last="${examples[@]:(-1)}"

  # loop through example sketches
  for example in "${examples[@]}"; do

    # store the full path to the example's sketch directory
    local example_dir=$(dirname $example)

    # store the filename for the example without the path
    local example_file=$(basename $example)

    echo "$example_file: "
    local sketch="$example_dir/$example_file"
    echo "$sketch"
    #arduino -v --verbose-build --verify $sketch

    # verify the example, and save stdout & stderr to a variable
    # we have to avoid reading the exit code of local:
    # "when declaring a local variable in a function, the local acts as a command in its own right"
    local build_stdout
    build_stdout=$(arduino --verify $sketch 2>&1)

    # echo output if the build failed
    if [ $? -ne 0 ]; then
      # heavy X
      echo -e "\xe2\x9c\x96"
      echo -e "----------------------------- DEBUG OUTPUT -----------------------------\n"
      echo "$build_stdout"
      echo -e "\n------------------------------------------------------------------------\n"

      # mark as fail
      exit_code=1

    else
      # heavy checkmark
      echo -e "\xe2\x9c\x93"
    fi
  done

  return $exit_code
}

function setup_env()
{   
    # Keep track of exit code
    local exit_code=0
    # Arduino requires an X server even with command line
    # https://github.com/arduino/Arduino/issues/1981
    echo -e "Starting X Server"
    $(/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_1.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :1 -ac -screen 0 1280x1024x16)
    
    # Warn if the launch failed
    if [ $? -ne 0 ]; then
        echo -e "Launch of X server failed"
        exit_code=1
    fi
    
    sleep 3
    export DISPLAY=:1.0

    # Install the Arduino IDE
    echo -e "Downloading and installing Arduino IDE"
    $(wget http://downloads.arduino.cc/arduino-1.6.5-linux64.tar.xz)
    $(tar xf arduino-1.6.5-linux64.tar.xz)
    $(sudo mv arduino-1.6.5 /usr/local/share/arduino)
    $(sudo ln -s /usr/local/share/arduino/arduino /usr/local/bin/arduino)
    
    return $exit_code
}

# Pass the git url of a repo to install. If none is given, use the build dir
function install_repo_as_library()
{
    local library_dir="/usr/local/share/arduino/libraries/"

    # Check if the repo url was given
    if [ -z ${1+x} ]; then
        echo "Installing TRAVIS_BUILD_DIR as library";
        local lib_name=${TRAVIS_BUILD_DIR##*/}
        ln -s ${TRAVIS_BUILD_DIR} "${library_dir}${lib_name}"
    else
        echo "Installing given repo as library";
        $(cd ${library_dir}, git clone ${1})
        ls ${library_dir}
    fi
    
    return 0
}
