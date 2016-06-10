#!/bin/bash

#set -x

function download_trace_files() {
    for TRACE in perf-staging ; do
	rm -rf $SCRIPTDIR/$TRACE
	curl -so $SCRIPTDIR/$TRACE.zip https://s3.amazonaws.com/download.draios.com/falco-tests/$TRACE.zip &&
	unzip -d $SCRIPTDIR $SCRIPTDIR/$TRACE.zip &&
	rm -rf $SCRIPTDIR/$TRACE.zip
    done
}

function time_cmd() {
    cmd="$1"
    file="$2"

    shortfile=`basename $file .scap`

    for i in `seq 1 5`; do
	time=`date --iso-8601=sec`
	/usr/bin/time -a -o ~/results.txt --format "{\"time\": \"$time\", \"shortfile\": \"$shortfile\", \"file\": \"$file\", \"config\": \"$config\", \"elapsed\": {\"real\": %e, \"user\": %U, \"sys\": %S}}," $cmd
    done
}

function run_falco_on() {
    file="$1"

    cmd="$root/build/userspace/falco/falco -c $root/falco.yaml -r $root/rules/falco_rules.yaml --option=stdout_output.enabled=false -e $file"

    time_cmd "$cmd" "$file"
}

function run_sysdig_on() {
    file="$1"

    cmd="$root/build/userspace/sysdig/sysdig -z -r $file evt.type=none"

    time_cmd "$cmd" "$file"
}

function run() {
    for file in /mnt/sf_mstemm/traces-perf/*.scap ; do
	if [[ $root == *"falco"* ]]; then
	    run_falco_on "$file"
	else
	    run_sysdig_on "$file"
	fi
    done
}

if [ -z $1 ]; then
    echo "A config type must be provided. Not continuing."
    exit 1
fi

config="$1"
root="$2"

if [ -z "$root" ]; then
    root=`dirname $0`/..
fi

#download_trace_files
run
