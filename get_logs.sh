#!/bin/bash
set -o xtrace
IFS=$'\n';
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
for pod in $(kubectl get pods --no-headers  -n xb-application -o custom-columns=:metadata.name,:status.podIP)
do
	 #echo "pod $pod"
	 podName=$(echo $pod | cut -f1 -d ' ')
	 #p=`echo $i |cut -d ' ' -f1`
	 #podname='$p'
	 ip=$(echo $pod |cut -d ' ' -f4-)
	  ## Trimming spaces if any
	 ip=${ip//[[:blank:]]/}
	 echo "pod name $podName IP ADDRESS $ip"
	 
	 app_context='overseas-switch'
	 if [[ "$podName" =~ ^xb-switch-sg.* ]]; then
		app_context='sg-switch'
		#continue
	 fi

	 if [[ "$podName" =~ ^xb-switch-bo.* ]]; then
		app_context='sg-bo'
		continue
	 fi

	 logpath='logs/'$current_time'/'$app_context'/'$podName
	 #mkdir -p logs/$current_time
	 mkdir -p $logpath
	 echo "app_context $app_context current_time $current_time , logpath $logpath"

	 echo -e "COPYING LOGS INTO local file path $logpath"
	 kubectl cp $podName:logs/ $logpath/logs -n xb-application
	 echo -e "COPIED LOGS INTO local file path"
done;

set +o xtrace