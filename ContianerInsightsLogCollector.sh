#! /bin/bash

datevalue=$(date +"%y%m%d_%H%M%S")
path=$datevalue'_containerinsightslog'

list_oms_pods()
{
    echo "current oms pods status:"
    kubectl get pods -n kube-system | grep omsagent
}

log_collector()
{
    echo "start log collecting"
    mkdir $path
    kubectl get deployment omsagent-rs -n kube-system -o yaml > $path/deployment.txt 2>&1
    echo "<log collection> omsagent deployment "
    kubectl get configmaps container-azm-ms-agentconfig -o yaml -n kube-system > $path/configmap.txt 2>&1
    echo "<log collection> application map "
    RSOMSPOD=$(kubectl get pods -n kube-system | grep omsagent-rs | awk '{print $1}' )
    
    #rs-pod collection
    mkdir $path/$RSOMSPOD
    kubectl logs $RSOMSPOD -n kube-system --timestamps > $path/$RSOMSPOD-containerlog.log 2>&1
    echo "<log collection> $RSOMSPOD container log "
    kubectl describe pod $RSOMSPOD -n kube-system > $path/$RSOMSPOD-describe.log 2>&1
    echo "<log collection> described $RSOMSPOD"

    kubectl cp -n kube-system $RSOMSPOD:/var/opt/microsoft/linuxmonagent/log $path/$RSOMSPOD 1>/dev/null
    echo "<log collection> $RSOMSPOD mdsd log "
    kubectl cp -n kube-system $RSOMSPOD:/var/opt/microsoft/docker-cimprov/log $path/$RSOMSPOD 1>/dev/null
    echo "<log collection> $RSOMSPOD cim log "

    for OMSPOD in $(kubectl get pods -n kube-system | grep omsagent | awk '{print $1}' )
    do
        if [ $OMSPOD == $RSOMSPOD ] ; then continue
        else 
            mkdir $path/$OMSPOD
            kubectl logs $OMSPOD -c omsagent -n kube-system --timestamps > $path/$OMSPOD-containerlog.log 2>&1
            echo "*********************************" >> $path/$OMSPOD-containerlog.log
            kubectl logs $OMSPOD -c omsagent-prometheus -n kube-system --timestamps >> $path/$OMSPOD-containerlog.log 2>&1
            echo "<log collection> $OMSPOD container log "

            kubectl describe pod $OMSPOD -n kube-system > $path/$OMSPOD-describe.log 2>&1
            echo "<log collection> described $OMSPOD"

            kubectl cp -n kube-system $OMSPOD:/var/opt/microsoft/linuxmonagent/log $path/$OMSPOD 1>/dev/null
            echo "<log collection> $OMSPOD mdsd log "
            kubectl cp -n kube-system $OMSPOD:/var/opt/microsoft/docker-cimprov/log $path/$OMSPOD 1>/dev/null
            echo "<log collection> $OMSPOD cim log "
            break
        fi
    done

    #tar -zcvf $path.tar.gz $path/ 1>/dev/null
    #rm -rf $path/

    echo "collection complete at $path"
}

pack_logs()
{
    if [ $(command -v zip |wc -l) == "1" ]; then
    zip -q -r $path.zip $path/ 1>/dev/null
    echo "packed at $path.zip"
    else
    tar -zcvf $path.tar.gz $path/ 1>/dev/null
    echo "packed at $path.tar.gz"
    fi
}


delete_oms_pod()
{
    echo "deleting OMS pods"
    for OMSPOD in $(kubectl get pods -n kube-system | grep omsagent | awk '{print $1}' )
    do
        kubectl delete pod $OMSPOD -n kube-system
    done
}


countdown()
(
  IFS=:
  set -- $*
  secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
  while [ $secs -gt 0 ]
  do
    sleep 1 &
    printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
    secs=$(( $secs - 1 ))
    wait
  done
  echo
)

echo "***********************************************"
echo "Welcome to use Container Insgihts log collector"
echo "***********************************************"

#check kubectl installed
command -v kubectl > /dev/null 2>&1 || { echo >&2 "kubectl is not installed, existing" ; exit 1 ;}

#get current cluster
current_cluster=$(kubectl config view | grep current)
echo -n "Current cluster is "
echo ${current_cluster/current-context:}

#list oms pods
list_oms_pods


#main
read -p "To minimize log size , is it ok to delete current omsagent PODs (Y/N/other key to abort):" ifdeletepod

if [ "$ifdeletepod" == "Y" ] ; then #delete pods first
delete_oms_pod
echo "waiting for 5 min"
countdown 00:05:00 
list_oms_pods
sleep 5s
log_collector
pack_logs
elif [ "$ifdeletepod" == "N" ] ; then
log_collector
pack_logs
else 
echo "please enter Y/N"
fi


