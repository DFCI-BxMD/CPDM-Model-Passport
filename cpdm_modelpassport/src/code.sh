set -exo pipefail


manifest_download_dxda() {
    # run the dx-download-agent (dxda) on a manifest of manifest files
    if [[ -f "/home/dnanexus/meta/dxdaManifestDownloadManifest.json" ]]; then
       echo "Using dxda version: $(dx-download-agent version)"
       head -n 20 "/home/dnanexus/meta/dxdaManifestDownloadManifest.json"
       echo ""
       bzip2 "/home/dnanexus/meta/dxdaManifestDownloadManifest.json"

       # Run the download agent, and store the return code; do not exit on error.
       # We need to run it from the root directory, because it uses relative paths.
       cd /
       dxda_error_code=0
       dx-download-agent download "/home/dnanexus/meta/dxdaManifestDownloadManifest.json.bz2" || dxda_error_code=$? && true

       # if there was an error during download, print out the download log
       if [[ $dxda_error_code != 0 ]]; then
           echo "download agent failed rc=$dxda_error_code"
           if [[ -f "/home/dnanexus/meta/dxdaManifestDownloadManifest.json.bz2.download.log" ]]; then
              echo "The download log is:"
              cat "/home/dnanexus/meta/dxdaManifestDownloadManifest.json.bz2.download.log"
           fi
           exit $dxda_error_code
       fi

       # The download was ok, check file integrity on disk
       dx-download-agent inspect "/home/dnanexus/meta/dxdaManifestDownloadManifest.json.bz2"
    fi
}

workflow_manifest_download_dxda() {
    # run the dx-download-agent (dxda) on a manifest of workflow manifest files
    if [[ -f "/home/dnanexus/meta/dxdaWorkflowManifestDownloadManifest.json" ]]; then
       echo "Using dxda version: $(dx-download-agent version)"
       head -n 20 "/home/dnanexus/meta/dxdaWorkflowManifestDownloadManifest.json"
       echo ""
       bzip2 "/home/dnanexus/meta/dxdaWorkflowManifestDownloadManifest.json"

       # Run the download agent, and store the return code; do not exit on error.
       # We need to run it from the root directory, because it uses relative paths.
       cd /
       dxda_error_code=0
       dx-download-agent download "/home/dnanexus/meta/dxdaWorkflowManifestDownloadManifest.json.bz2" || dxda_error_code=$? && true

       # if there was an error during download, print out the download log
       if [[ $dxda_error_code != 0 ]]; then
           echo "download agent failed rc=$dxda_error_code"
           if [[ -f "/home/dnanexus/meta/dxdaWorkflowManifestDownloadManifest.json.bz2.download.log" ]]; then
              echo "The download log is:"
              cat "/home/dnanexus/meta/dxdaWorkflowManifestDownloadManifest.json.bz2.download.log"
           fi
           exit $dxda_error_code
       fi

       # The download was ok, check file integrity on disk
       dx-download-agent inspect "/home/dnanexus/meta/dxdaWorkflowManifestDownloadManifest.json.bz2"
    fi
}

body() {
    java -jar ${DX_FS_ROOT}/dxExecutorWdl.jar task run ${HOME} -traceLevel 1       -streamFiles PerFile 
}

download_dxda() {
    # run the dx-download-agent (dxda) on a manifest of files
    if [[ -f "/home/dnanexus/meta/dxdaFileDownloadManifest.json" ]]; then
       echo "Using dxda version: $(dx-download-agent version)"
       head -n 20 "/home/dnanexus/meta/dxdaFileDownloadManifest.json"
       echo ""
       bzip2 "/home/dnanexus/meta/dxdaFileDownloadManifest.json"

       # Run the download agent, and store the return code; do not exit on error.
       # We need to run it from the root directory, because it uses relative paths.
       cd /
       dxda_error_code=0
       dx-download-agent download "/home/dnanexus/meta/dxdaFileDownloadManifest.json.bz2" || dxda_error_code=$? && true

       # if there was an error during download, print out the download log
       if [[ $dxda_error_code != 0 ]]; then
           echo "download agent failed rc=$dxda_error_code"
           if [[ -f "/home/dnanexus/meta/dxdaFileDownloadManifest.json.bz2.download.log" ]]; then
              echo "The download log is:"
              cat "/home/dnanexus/meta/dxdaFileDownloadManifest.json.bz2.download.log"
           fi
           exit $dxda_error_code
       fi

       # The download was ok, check file integrity on disk
       dx-download-agent inspect "/home/dnanexus/meta/dxdaFileDownloadManifest.json.bz2"
    fi
}

download_dxfuse() {
    # Run dxfuse on a manifest of files. It will provide remote access
    # to DNAx files.
    if [[ -f "/home/dnanexus/meta/dxfuseDownloadManifest.json" ]]; then
       echo "Using dxfuse version: $(dxfuse -version)"
       head -n 20 "/home/dnanexus/meta/dxfuseDownloadManifest.json"
       echo ""

       # make sure the mountpoint exists
       mkdir -p "/home/dnanexus/mnt"

       # don't leak the token to stdout. We need the DNAx token to be accessible
       # in the environment, so that dxfuse could get it.
       source environment >& /dev/null

       dxfuse_version=$(dxfuse -version)
       echo "dxfuse version ${dxfuse_version}"

       # run dxfuse so that it will not exit after the bash script exists.
       echo "mounting dxfuse on /home/dnanexus/mnt"
       dxfuse_err_code=0
       dxfuse -readOnly "/home/dnanexus/mnt" "/home/dnanexus/meta/dxfuseDownloadManifest.json" || dxfuse_err_code=$? && true
       dxfuse_log=/root/.dxfuse/dxfuse.log
       if [[ $dxfuse_err_code != 0 ]]; then
           echo "error starting dxfuse, rc=$dxfuse_err_code"
           # wait a second for the log to sync
           sleep 1
           if [[ -f $dxfuse_log ]]; then
               cat $dxfuse_log
           fi
           exit $dxfuse_err_code
       fi

       echo ""
       ls -Rl "/home/dnanexus/mnt"
    fi
}

before_command() {
    # Make the inputs folder read-only
    mkdir -p "/home/dnanexus/inputs"
    chmod -R 500 "/home/dnanexus/inputs"
}

run_command() {
    echo "bash command encapsulation script:"
    cat "/home/dnanexus/meta/commandScript" >&2

    # Run the shell script generated by instantiateCommand.
    # Capture the stderr/stdout in files
    if [[ -f "/home/dnanexus/meta/containerRunScript" ]]; then
        echo "docker submit script:"
        cat "/home/dnanexus/meta/containerRunScript"
        /home/dnanexus/meta/containerRunScript
    else
        whoami
        /bin/bash "/home/dnanexus/meta/commandScript"
    fi

    # check return code of the script
    rc=1
    if [[ -f "/home/dnanexus/meta/returnCode" ]]; then
        file_rc=`cat "/home/dnanexus/meta/returnCode"`
        if [[ -z "$file_rc" ]]; then
            # the rc file exists but is empty, perhaps due to lack of disk space
            echo "return code file exists but is empty"
        else
            rc=$file_rc
        fi
    else
        # the rc file does not exist, perhaps due to lack of disk space
        echo "command completed but no return code file"
    fi
    if [[ $rc != 0 ]]; then
        if [[ -f "$dxfuse_log" ]]; then
            echo "=== dxfuse filesystem log === "
            cat $dxfuse_log
        fi
        exit $rc
    fi
}

upload_files() {
    # Upload files using UA
    if [[ -f "/home/dnanexus/meta/dxuaManifest.json" ]]; then
        rc=0
        ua --manifest "/home/dnanexus/meta/dxuaManifest.json" >/root/ua.log 2>&1 || rc=$? && true

        # if there was an error during upload, print out the log
        if [[ $rc != 0 ]]; then
            echo "upload agent failed rc=$rc"
            if [[ -f /root/ua.log ]]; then
                echo "The upload log is:"
                cat /root/ua.log
            fi
            exit $rc
        fi
    fi
}

cleanup() {
    # unmount dxfuse
    if [[ -f "/home/dnanexus/meta/dxfuseDownloadManifest.json" ]]; then
        echo "unmounting dxfuse"
        umount "/home/dnanexus/mnt"
    fi
}


main() {
    body
}