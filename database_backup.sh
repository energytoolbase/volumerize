#!/bin/bash

 #number
 re='^[0-9]+$'

 #Influx backup
 dir="${VOLUMERIZE_SOURCE1}/"

  #log
 LOGFILE="/preexecute/backup/prescriptbackup.log"
(
        date
        if [[ ${JOB_ID} -eq 1 ]] || [[ -z  ${JOB_ID} ]]; then
          status_code=$(curl -w '%{http_code}' influxdb:8086/ping)
          echo Connection response: "${status_code}"
          #remove old backup files [Should be stored in cloud already if script fails]
          rm -f ${dir}*
         #make a docker back up if influx is assumed to be up
          if [[ ${status_code} -eq 204 ]] ; then
                influxd backup -portable -host influxdb:8088 "${dir}"

                #Give permission
                chmod -R 777 $dir

                #rename files in influx_periodic_backup
                # formats ####T###Z.* -> TZ.*
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
                                # need to replace lines in "fileName": "####T####z.*" TZ.manifest  (first one ends .meta the            rest .s#.tar.gz)
                                #Change in manifest file, happens to be first file, but portability may need to change this
                                if ! [[ $i =~ (.+)+(".manifest") ]] ; then
                                        sed -i "s/${og}/${replacement}/g" "${dir}TZ.manifest"
                                fi
                        fi
                done
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
