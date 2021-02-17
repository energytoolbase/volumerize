#!/bin/bash

 #number
 re='^[0-9]+$'

 #Influx backup
 dir="${VOLUMERIZE_SOURCE1}/"

  #log
 LOGFILE="/preexecute/backup/prescriptbackup.log"
 #keep only a week of logs 
 outdated=$(date --date "-168:00:00" '+%Y-%m-%d')
 if grep -q "${outdated}" "${LOGFILE}"; then
  sed -i "1,/${outdated}/d" "${LOGFILE}"
 fi
 
 #function for influx backup
 #Arg-something to ensure unique manifest 
 handle_files_influx() {
     #Give permission
     chmod -R 777 $dir

     # rename files in influx_periodic_backup
     # formats ####T###Z.* -> TZ.*
     #change manifest first for safety
     for f in ${dir}[0-9]*.manifest; do
    	mv -- "$f" "${dir}TZ${1}.manifest"
     done
     #change meta for custom ending
     for f in ${dir}[0-9]*.meta; do
    	mv -- "$f" "${dir}TZ${1}.meta"
    	j=$(basename ${f})
    	sed -i "s/${j}/TZ${1}.meta/g" "${dir}TZ${1}.manifest"
     done
     #Files that start with numbers
     for i in ${dir}[0-9]*; do
       if [[ $i =~ [[:digit:]]+"T"+[[:digit:]]+(.+) ]] ; then
         # grab the rest of the filename from
         # the regex capture group
         replacement="T${BASH_REMATCH[1]}"
         [[ $i =~ ${dir}+(.+) ]]
         og="${BASH_REMATCH[1]}"
         newname="${dir}$replacement"
         #Rename file
         mv "$i" "$newname"
         # need to replace lines in "fileName": "####T####z.*" TZ.manifest  (first one ends .meta the rest .s#.tar.gz)
         #Change in manifest file
         if ! [[ $i =~ (.+)+(".manifest") ]] ; then
           sed -i "s/${og}/${replacement}/g" "${dir}TZ${1}.manifest"
         fi
       fi
     done
 }
 
 
#Do the backup
(
        date '+%Y-%m-%d'
        
        if [[ ${JOB_ID} -eq 1 ]] || [[ -z  ${JOB_ID} ]]; then
          status_code=$(curl -w '%{http_code}' influxdb:8086/ping)
          echo Connection response: "${status_code}"
          #remove old backup files
          rm ${dir}*
              #make a docker back up if influx is assumed to be up
          if [[ ${status_code} -eq 204 ]] ; then
          	#Figure out what we want to backup:
          	
          	#default
          	if [[ -z "${DATABASES}" ]] || [[ ${DATABASES} == "all" ]]; then
          	  influxd backup -portable -host influxdb:8088 "${dir}"
          	  handle_files_influx "all"
          	else
          	  # split by seperated words
          	  for word in ${DATABASES}; do
          	   clean=$(sed 's/\,//g' <<< ${word})
                   influxd backup -portable -db "${clean}" -host influxdb:8088 "${dir}"
                   handle_files_influx ${clean}
                 done
               fi
	  fi

        fi


	#redis backup
	#update the backup files
	#returns an int timestamp
	if [[ ${JOB_ID} -eq 2 ]] || [[ -z  ${JOB_ID} ]]; then
  	lastsave=$(redis-cli -h redis -p 6379 lastsave)
	  recentsave=${lastsave}
	  redis-cli -h redis -p 6379 bgsave
	  while [[ ${lastsave} -eq ${recentsave} ]]; do
 		  recentsave=$(redis-cli -h redis -p 6379 lastsave)
 		  if ! [[ $recentsave =~ $re ]] ; then
   		  	echo "error: redis last save ${recentsave}" >&2; exit 1
 		  fi
 		  sleep 1
	  done
	  cp /redis/dump.rdb /source2
	  echo background save finished
	fi
) >> "${LOGFILE}" 2>&1
