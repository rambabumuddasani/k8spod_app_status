#!/bin/bash
set -o xtrace
IFS=$'\n';
for i in in {1..10}
do
	echo -e "    ITERATION STARTS at  $i"
	sleep 5
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
		continue
	 fi

	 if [[ "$podName" =~ ^xb-switch-bo.* ]]; then
		app_context='sg-bo'
		continue
	 fi

	 logpath='logs/'$current_time'/'$app_context'/'$podName
	 #mkdir -p logs/$current_time
	 mkdir -p $logpath
	 echo "app_context $app_context current_time $current_time , logpath $logpath"
	 file_name_suffix='_'$current_time

	 mettrics=$(cat mettrics.txt)
	 for mettric in $mettrics
	 do
		mettric="${mettric%%[[:cntrl:]]}"
		echo -e "\n METRIC NAME $mettric START"
		kubectl exec $podName -n xb-application -- curl  http://$ip:8080/$app_context/actuator/metrics/$mettric |  tee $logpath/$mettric'.'$podName.json
		echo -e "METRIC $mettric END\n"
	 done

	 echo "Health check for the app START"
	 kubectl exec $podName -n xb-application -- curl  http://$ip:8080/$app_context/actuator/health | tee $logpath/health.$podName.json
	 echo "Health check for the app END"
	 
	 echo "Thread Dump for the Java Virtual Machine process START"
	 kubectl exec $podName -n xb-application -- curl  http://$ip:8080/$app_context/actuator/threaddump | tee $logpath/threaddump.$podName.json
	 echo "Thread Dump for the Java Virtual Machine process END"

	 echo "Thread Dump for the Java Virtual Machine process START"
	 kubectl exec $podName -n xb-application -- curl  http://$ip:8080/$app_context/actuator/heapdump -o logs/'heapdump_'$current_time
	 echo "Thread Dump for the Java Virtual Machine process END"

	
	 echo -e "COPYING HEAP DUMP INTO local file path $logpath"
	 kubectl cp $podName:logs/ $logpath/heapdump -n xb-application
	 echo -e "COPIED HEAP DUMP INTO local file path"
	done;
	echo -e "    ITERATION ENDs at  $i \r\r\r"
done;

set +o xtrace