#!/bin/bash

runner="networkingrunner"
dir="actions-runner"
runner_package="actions-runner-linux-x64-2.312.0.tar.gz"
logs_dir="logs"
runner_log="/home/$USER/workspace/networking/$logs_dir/runner-log.txt"
set -e

if [ ! -d $dir ]; then
    if ! mkdir $dir; then
        echo -e "Error: Failed to create $dir directory"
        exit 1
    fi
    echo -e "-- Directory $dir created"
fi
if [ ! -d $logs_dir ]; then
    if ! mkdir $logs_dir; then
        echo -e "Error: Failed to create log directory $logs_dir/"
        exit 1
    fi
    echo -e "-- Log directory $logs_dir/ created"
fi
cd $dir

if [ ! -f $runner_package ]; then
    echo -e "-- Latest runner package not found"
    echo -e "-- Downloading latest runner package"
    curl -o $runner_package -L https://github.com/actions/runner/releases/download/v2.312.0/$runner_package
    if [ ! -f $runner_package ]; then
        echo -e "Error: Failed to download runner package: $runner_package"
        exit 1
    fi
    echo -e "-- Validating hash"
    echo "85c1bbd104d539f666a89edef70a18db2596df374a1b51670f2af1578ecbe031  $runner_package" | shasum -a 256 -c 
    if [[ $? -ne 0 ]]; then
        echo -e "Error: Failed to validate runner package hash"
        exit 1
    fi
fi
echo -e "-- Extracting installer"
if ! tar xzf ./$runner_package; then
    echo -e "Error: Failed to extract installer"
    exit 1
fi

echo -e "-- Configuring runner service"
/usr/bin/expect -c '
    puts "---- Executing automation command to register runner"
    set runner "cheki";
    set github_endpoint "https://github.com/gospodin66/networking";

    set token_file [open "/home/$runner/workspace/networking/configs/.runnertoken"];
    set token [read $token_file];
    close $token_file

    set config_path [exec realpath [exec find . -type f -name config.sh]];

    spawn /bin/bash $config_path --url $github_endpoint --token $token
        
    expect "*\[press Enter for Default\]"
    send "\r"
    
    expect "*\[press Enter for fedora\]"
    send "$runner\r"

    expect {
        "*\[press Enter to skip\]" {
            send "\r"
            exp_continue
        } 
        "*(Y/N) \[press Enter for N\]" {
            send "\r"
            exp_continue
        }
        "*\[press Enter for _work\]" {
            send "\r"
            expect eof
        }
    }
    puts "----- Automation command finished"
' | tee $runner_log

echo -e "-- Running runner"
(./run.sh &> $runner_log &)
echo -e "\nUse this YAML in your workflow file for each job"
echo -e "  runs-on: self-hosted\n"

echo -e "-- Installing runner service"
sudo ./svc.sh install $runner 

echo -e "-- Starting runner service"
sudo ./svc.sh start

echo -e "-- Github runner initialized successfuly" 
echo -e "\n-- Check runner status: sudo ./svc.sh status\n--Uninstall runner: sudo ./svc.sh uninstall\n"

exit 0

