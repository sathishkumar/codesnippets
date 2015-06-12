#!/bin/bash
CONF_ID=$1
DIR=/home/km/properties
#/home/skumar/properties
#debug=$2
LEVEL_STARTED=false

. ${DIR}/${CONF_ID}_camp_conf.txt
echo $AUD_EVENT
#EXCLUDE DAYS
REC_DAYS=$2

DAYSEC=86400

if [ "$ADV_ID" = "" ]; then
    echo "Please enter the values for ADV_ID"
    exit
fi

echo "EXC_RETENTION_IN_SEC: $EXC_RETENTION_IN_SEC"
echo "RETENTION_IN_SEC: $RETENTION_IN_SEC"
echo "REC_DAYS: $REC_DAYS"
echo "DPA_LEVEL_START: $DPA_LEVEL_START"
echo "CATALOG ID : $CATALOG_ID"
echo "PRODUCT SET ID: $PROD_SET_ID"
ERROR=error
FB_URL=https://graph.facebook.com/v2.2
ADV_ENTITY_FB_URL=${FB_URL}/act_${ADV_AD_ACCOUNT_ID}
FEED=${ADV_ID}_feed.txt.gz

IDExtract(){
#	echo "response -- $1"
	SET=$( echo "$1" | jq ".id") 
	if [ "$SET" = "null" ]; then
		echo $1;	
		echo "Existing here due to API exception thrown."
		exit 0;
	else
		temp="${SET%\"}";temp="${temp#\"}";echo "$temp"
	fi
}
#DPA Startswith 0-Catalog, 1-Audience, 2-Campaign
if [ "$DPA_LEVEL_START" = "0" ]; then
LEVEL_STARTED=true
echo " ********* Starting Job from Catalog level *********";
echo "Starting process of Creating FB entities for advertiser: $ADV_ID"
#Product Catalog:
#================
echo "Creating Product Catalog ..."
CATALOG_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} Catalog Products" -F "access_token=$B_ACCESSTOKEN" ${FB_URL}/${BUSINESS_ID}/product_catalogs); IDExtract "$SET") 
echo "CATALOG_ID - $CATALOG_ID"

#Product Catalog permission for System user:
#===========================================
#echo "Creating Product Catalog ..."
#$(curl -s -X POST -F "user=20303877" -F "role=ADMIN" -F "access_token=$B_ACCESSTOKEN" ${FB_URL}/${CATALOG_ID}/userpermissions)

#Product Feed:
#=============
echo "Creating Product Feed ..."
echo "schedule={\"interval\":\"${INTV}\", \"url\":\"${FEED_URL}/${FEED}\", \"${INTV_TYPE}\":\"${INTV_VALUE}\"}"
PROD_FEED_ID=$(SET=$(curl -s -F "name=${ADV_NAME} Feed " -F "file_name=${FEED}" -F "schedule={\"interval\":\"${INTV}\", \"url\":\"${FEED_URL}/${FEED}\", \"${INTV_TYPE}\":\"${INTV_VALUE}\"}" -F "access_token=$B_ACCESSTOKEN" ${FB_URL}/${CATALOG_ID}/product_feeds);IDExtract "$SET")
echo "PROD_FEED_ID - $PROD_FEED_ID"

#Product Set:
#============
echo "Creating Product Set..."
PROD_SET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} All Products" -F "filter={}" -F "access_token=$B_ACCESSTOKEN" ${FB_URL}/${CATALOG_ID}/product_sets);IDExtract "$SET") 
echo "PROD_SET_ID - $PROD_SET_ID"

#Pixel Product Catalog Preferences
#=================================
echo "Associate Pixel with Catalog for event tracking..."
PIX_CATALOG=$(SET=$(curl -s -F "external_event_sources=[$DATA_PIXEL_ID]" -F "access_token=$B_ACCESSTOKEN" ${FB_URL}/${CATALOG_ID}/external_event_sources); echo "$SET")
echo "Associationg done -- $PIX_CATALOG \n"

## Mysql Update 
mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'UPDATE `DPACampaignConfig` (`ex_catalog_id`) VALUES ("'$CATALOG_ID'") WHERE `session_id`=$SESSION;'
fi # Level starting for catalog ends here.

if [ $LEVEL_STARTED == true -o "$DPA_LEVEL_START" = "1" ]; then
if [ $PROD_SET_ID != "" -a $CATALOG_ID != "" ]; then
LEVEL_STARTED=true
echo " ********* Starting Job from Audience level *********";

#Create Product Audience
#=======================
#PRODUCT

## Inclusions build
if [ $AUD_EVENT = *","* ]; then
OIFS=$IFS
IFS=','
aud_eve=($AUD_EVENT)
ret_sec_arr=($RETENTION_IN_SEC)
COUNT=${#aud_eve[@]}
inclusions=""
echo $COUNT
        for ((i=1;i<=COUNT;i++));
        do
                if [ "$inclusions" != "" ]; then
                        inclusions="$inclusions , "
                fi
                inclusions="$inclusions{\"retention_seconds\": ${ret_sec_arr[i]},\"rule\": {\"event\": {\"eq\": \"${aud_eve[i]}\"}}}"
        done
IFS=$OIFS
else
	echo "---${RETENTION_IN_SEC}"
	inclusions="{\"retention_seconds\": ${RETENTION_IN_SEC},\"rule\": {\"event\": {\"eq\": \"${AUD_EVENT}\"}}}"
fi
## Exclusions build
if [ $EXC_AUD_EVENT = *","* ]; then
OIFS=$IFS
IFS=','
exc_aud_eve=($EXC_AUD_EVENT)
exc_ret_sec_arr=($EXC_RETENTION_IN_SEC)
COUNT=${#aud_eve[@]}
exclusions=""
echo $COUNT
        for ((i=1;i<=COUNT;i++));
        do
                if [ "$exclusions" != "" ]; then
                        exclusions="$exclusions , "
                fi
                exclusions="$exclusions{\"retention_seconds\": ${exc_ret_sec_arr[i]},\"rule\": {\"event\": {\"eq\": \"${exc_aud_eve[i]}\"}}}"
        done
IFS=$OIFS
else
	exclusions="{\"retention_seconds\": ${EXC_RETENTION_IN_SEC},\"rule\": {\"event\": {\"eq\": \"${EXC_AUD_EVENT}\"}}}"
fi
echo "Creating Product Audience :: Product only ..."
echo "inclusions=[${inclusions}]"
PROD_AUD=$(SET=$(curl -s -F "name=${ADV_NAME} PA - ${AUD_NAME}"  -F "product_set_id=$PROD_SET_ID"  -F "pixel_id=$DATA_PIXEL_ID" -F "inclusions=[${inclusions}]" -F "exclusions=[${exclusions}]" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/product_audiences ); IDExtract "$SET")
echo "PROD_AUD -- $PROD_AUD \n"

else
echo "CATALOG_ID and PROD_SET_ID are required to start from Audience level"
exit 0;
fi # Required fields check
fi # Level starting for Audience ends here.

echo $($LEVEL_STARTED == true)
if [ $LEVEL_STARTED == true -o  "$DPA_LEVEL_START" = "2" ]; then
if [ "$PROD_SET_ID" != *"$ERROR"* -a "$CATALOG_ID" != *"$ERROR"* -a "$PROD_AUD" != *"$ERROR"* ]; then
LEVEL_STARTED=true
echo " ********* Starting Job from Campaign level *********";

if $debug
then

#Create a Campaign
#=================
echo "promoted_object={\"product_catalog_id\":$CATALOG_ID}"
echo "Creating a Campaign ..."
if [ "$EXC_CUS_AUD" != "[]" -a "$INC_CUS_AUD" != "[]" ]; then
	name_appender="Include and Exclude CA"
elif [ "$EXC_CUS_AUD" = "[]" -a "$INC_CUS_AUD" != "[]" ]; then
	name_appender="Include CA"
elif [ "$EXC_CUS_AUD" != "[]" -a "$INC_CUS_AUD" = "[]" ]; then
	name_appender="Exclude  CA"
fi

CAMP_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA Campaign Rec - $name_appender" -F 'objective=PRODUCT_CATALOG_SALES' -F "campaign_group_status=$CAMP_STATUS" -F "promoted_object={\"product_catalog_id\":$CATALOG_ID}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adcampaign_groups ); IDExtract "$SET")
echo "Campaign -- $CAMP_ID \n"



#Create an Ad Set
#================
#PRODUCT

#BID=$((P_BID_P / 100))
BID=$(echo "scale=2; $BID_P/100" | bc)
echo "name=${ADV_NAME} DPA: Product Adset $BID_TYPE - $BID"
echo "Creating a Ad Set ..."
echo "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD], \"page_types\": [\"${PLACEMENT_TYPE}\"],\"custom_audiences\": $INC_CUS_AUD,\"excluded_custom_audiences\": $EXC_CUS_AUD}"
ADSET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA: Product Adset $BID_TYPE - $BID" -F "bid_type=$BID_TYPE" -F "bid_info={\"${BID_ACTION}\":$BID_P}" -F "campaign_status=$ADSET_STATUS" -F "daily_budget=$DAILY_BUD" -F "campaign_group_id=$CAMP_ID" -F "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD], \"page_types\": [\"${PLACEMENT_TYPE}\"],\"custom_audiences\": $INC_CUS_AUD,\"excluded_custom_audiences\": $EXC_CUS_AUD}" -F "promoted_object={\"product_set_id\":$PROD_SET_ID}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adcampaigns ); IDExtract "$SET")
echo "Ad Set -- $ADSET_ID \n"
fi

else
echo "CATALOG_ID, PROD_SET_ID,PROD_AUD_CART and PROD_AUD_PROD are required to start from Audience level"
exit 0;
fi # Required fields check
fi # Level start ends here for Campaign

if [ $LEVEL_STARTED == true -o  "$DPA_LEVEL_START" = "CREATIVE" ]; then
if [ $PROD_SET_ID != "" -a  $PROD_AUD != "" -a $CAMP_ID != "" -a $ADSET_ID != "" ]; then
LEVEL_STARTED=true
echo " ********* Starting Job from Campaign level *********";

#Create Dynamic Ad Template Creatives
#====================================
echo 
echo "Creating a Ad Template Creative ..."
echo "object_story_spec={\"page_id\": $ADV_PAGE_ID,\"template_data\": {\"call_to_action\": {\"type\": \"SHOP_NOW\"},\"message\": \"$TEMP_CREATIVE_MSG\",\"link\": \"$ADV_URL\",\"name\": \"{{product.price}}\",\"description\": \"{{product.name}}\",\"max_product_count\": 5}}"
echo "product_set_id=$PROD_SET_ID"
echo "access_token=$SYS_ADMIN_TOKEN"

CREATIVE_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} Dynamic Ad Template Creative" -F "object_story_spec={\"page_id\": $ADV_PAGE_ID,\"template_data\": {\"call_to_action\": {\"type\": \"SHOP_NOW\"},\"message\": \"$TEMP_CREATIVE_MSG\",\"link\": \"$ADV_URL\",\"name\": \"{{product.price}}\",\"description\": \"{{product.name}}\",\"max_product_count\": 5}}" -F "product_set_id=$PROD_SET_ID" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adcreatives ); IDExtract "$SET")
echo "Creative Template -- $CREATIVE_ID \n"

#Create Ad Groups
#================
#PRODUCT
echo "Creating a PROD Ad Creative ..."
AD_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} DPA: AD" -F "campaign_id=$ADSET_ID" -F "creative={\"creative_id\":$CREATIVE_ID}" -F 'objective=PRODUCT_CATALOG_SALES' -F "tracking_specs={\"action.type\":\"offsite_conversion\",\"offsite_pixel\":\"$CONV_PIXEL_ID\"}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adgroups ); IDExtract "$SET")
echo "Creative -- $AD_ID \n"

else
echo "PROD_SET_ID, PROD_AUD, CAMP_ID and ADSET_ID are required to start from Audience level"
exit 0;
fi # Required fields check
fi # Level starting for Campaign ends here.
exit 0;
#Logging in mysql for report read.
mhost='20.20.20.71'
muser='root'
mpwd='Test123$'
mdb='social_dco'
echo "Started  - inserting data into Mysql for reporting configuration"
mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD'","${AUD_EVENT}","'$CAMP_ID'","'$ADSET_ID'","'$CREATIVE_ID'","'$AD_ID'")' 

#mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD_CART'","AddToCart","'$CAMP_ID'","'$CART_ADSET_ID'","'$CREATIVE_ID'","'$CART_AD_ID'")'

#mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD_PROD'","ViewContent","'$CAMP_ID'","'$MPROD_ADSET_ID'","'$CREATIVE_ID'","'$MPROD_AD_ID'")'

#mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD_CART'","AddToCart","'$CAMP_ID'","'$MCART_ADSET_ID'","'$CREATIVE_ID'","'$MCART_AD_ID'")'
echo "Completed - inserting data into Mysql for reporting configuration"
exit 0;
