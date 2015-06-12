#!/bin/bash
JOB_TYPE=$1
CAMP_ID=$2
DATA=$3
ACCESS_TOKEN=CAAEDOFD5jeEBABSiQpiqu5Dm6BjPziaOaowD0KfHECh5cSdFLPa1cAYYpeyQ0cW8ZC3roqLNvry4BIHwsZAIrpuSSRzOjGD0Y78FPsOrzHC0wtTOr8YFk12GyK7LhTtWZBMUHUTLjj9UOUf3L723KYnZCZCrfbjwv7qb3ZCKc2uZCxcMAUucwlxJkwXZAeFyy7c63ml5YZAfRpjYUZBRAmeegm
IDExtract(){
#       echo "response -- $1"
        SET=$( echo "$1" | jq ".id")
        if [ "$SET" = "null" ]; then
                echo $1;
                echo "Existing here due to API exception thrown."
                exit 0;
        else
                temp="${SET%\"}";temp="${temp#\"}";echo "$temp"
        fi
}

UPDATE_ADGROUP() {
ADG_ID=$1
CREATIVE_ID=$2
echo "Updating AdGROUP: ${ADG_ID} with Creative ID: ${CREATIVE_ID}"
echo $(curl -s -X POST -F "creative={\"creative_id\":${CREATIVE_ID}}" -F "access_token=${ACCESS_TOKEN}" "https://graph.facebook.com/v2.2/${ADG_ID}");
}
UPDATE_ADSET(){
ADSET_ID=$1
CUSTOM_AUDIENCE=$2
echo "Updating AdSET:  ${ADSET_ID} with CUSTOM_AUDIENCE DATA: ${CUSTOM_AUDIENCE}"
echo $(curl -s -X POST -F "tartgeting={'custom_audiences':[{'id':6019141258704,'name':'Firstcry old buyers'}]}" -F "access_token=${ACCESS_TOKEN}" "https://graph.facebook.com/v2.2/${ADSET_ID}");
}

ADSET_TARGETING_EXTRACT(){
	SET=$( echo "$1" | jq '.data[] | .["id"]');
	echo $SET
count=0
        for fid in $SET
	do
		echo "------------------------------- ^^^^^^^^^^^^ ----------------------------"
		echo $fid
		ADSET_ID=$(temp="${fid%\"}";temp="${temp#\"}";echo "$temp");
		ADSET_TARGET[$ADSET_ID]=$(curl -s "https://graph.facebook.com/v2.2/$ADSET_ID?fields=name,targeting,promoted_object&access_token=${ACCESS_TOKEN}" | jq -c '.targeting')
		echo ${ADSET_TARGET[$ADSET_ID]}		
		#TARGET=
	done
		
}
ADGROUP_EXTRACT() {
echo "here----------------------$1 "
#echo $jsa | jq '.data[] | .["id"]'

        SET=$( echo "$1" | jq '.data[] | .["id"]');
        echo $SET
        for fid in $SET
        do
                # Do something with file id $fid
                ADGROUP_ID=$(temp="${fid%\"}";temp="${temp#\"}";echo "$temp");
                UPDATE_ADGROUP $ADGROUP_ID $DATA
        done
}

ADGROUP_LIST=$(curl -s "https://graph.facebook.com/v2.2/${CAMP_ID}/adgroups?fields=name&access_token=${ACCESS_TOKEN}");
ADSET_LIST=$(curl -s "https://graph.facebook.com/v2.2/${CAMP_ID}/adcampaigns?fields=id&access_token=${ACCESS_TOKEN}");

if [ "$JOB_TYPE" = "T_INCL_CA" ]; then
	ADSET_TARGETING_EXTRACT "${ADSET_LIST}"
elif [ "$JOB_TYPE" = "C_CHANGE" ]; then
	echo $ADGROUP_LIST
	ADGROUP_EXTRACT "${ADGROUP_LIST}"
elif [ "$JOB_TYPE" = "B_CHANGE" ]; then
	echo "Am in B_CHANGE"
elif [ "$JOB_TYPE" = "T_EXC_CA" ]; then
	echo "Am in T_EXC_CA"	
fi
#exit
exit 0;
