#!/bin/bash
ADV_ID=$1
DIR=/home/km/properties
#/home/skumar/properties
debug=$2
LEVEL_STARTED=false

. ${DIR}/${ADV_ID}.txt
echo $B_ACCESSTOKEN
echo $ADV_NAME


echo "$EXC_CUS_AUD"
echo "$INC_CUS_AUD"

#EXCLUDE DAYS
REC_DAYS=$3
ON_BOARDING_NEW=$([ "$4" = "" ] && echo "N" || echo "$4" )

DAYSEC=86400

if [ "$ADV_ID" = "" -o "$debug" = "" -o "$REC_DAYS" = "" ]; then
    echo "Please enter the values for ADV_ID,debug,REC_DAYS"
    exit
fi

if [ "$REC_DAYS" -eq "1" ]; then
	EXC_RETENTION_IN_SEC=1
else
	EXC_RETENTION_IN_SEC=$(($DAYSEC * ($REC_DAYS-1)))
fi
RETENTION_IN_SEC=$(($DAYSEC * $REC_DAYS))

if [ "$ON_BOARDING_NEW" = "Y" -a "$DPA_LEVEL_START" = "" ];then
	DPA_LEVEL_START=CATALOG
elif [ "$DPA_LEVEL_START" = "" ]; then
	DPA_LEVEL_START=AUDIENCE
fi

echo "EXC_RETENTION_IN_SEC: $EXC_RETENTION_IN_SEC"
echo "RETENTION_IN_SEC: $RETENTION_IN_SEC"
echo "REC_DAYS: $REC_DAYS"
echo "DPA_LEVEL_START: $DPA_LEVEL_START"

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

if [ "$DPA_LEVEL_START" = "CATALOG" ]; then
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

fi # Level starting for catalog ends here.

if [ $LEVEL_STARTED == true -o "$DPA_LEVEL_START" = "AUDIENCE" ]; then
if [ $PROD_SET_ID != "" -a $CATALOG_ID != "" ]; then
LEVEL_STARTED=true
echo " ********* Starting Job from Audience level *********";

#Create Product Audience
#=======================
#PRODUCT
echo "Creating Product Audience :: Product only ..."
PROD_AUD_PURC=$(SET=$(curl -s -F "name=${ADV_NAME} PA - Purchase Rec $REC_DAYS day(s)"  -F "product_set_id=$PROD_SET_ID"  -F "pixel_id=$DATA_PIXEL_ID" -F "inclusions=[{\"retention_seconds\": ${RETENTION_IN_SEC},\"rule\": {\"event\": {\"eq\": \"Purchase\"},}}]" -F "exclusions=[{\"retention_seconds\": ${RETENTION_IN_SEC},\"rule\": {\"event\": {\"eq\": \"ViewContent\"}}},{\"retention_seconds\": ${RETENTION_IN_SEC},\"rule\": {\"event\": {\"eq\": \"AddToCart\"}}},{\"retention_seconds\": ${EXC_RETENTION_IN_SEC},\"rule\": {\"event\": {\"eq\": \"Purchase\"}}}]" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/product_audiences ); IDExtract "$SET")
echo "PROD_AUD_PRODUCT  -- $PROD_AUD_PURC \n"
else
echo "CATALOG_ID and PROD_SET_ID are required to start from Audience level"
exit 0;
fi # Required fields check
fi # Level starting for Audience ends here.

echo $($LEVEL_STARTED == true)
if [ $LEVEL_STARTED == true -o  "$DPA_LEVEL_START" = "CAMPAIGN" ]; then
if [ "$PROD_SET_ID" != *"$ERROR"* -a "$CATALOG_ID" != *"$ERROR"* -a "$PROD_AUD_CART" != *"$ERROR"* -a "$PROD_AUD_PROD" != *"$ERROR"* ]; then
LEVEL_STARTED=true
echo " ********* Starting Job from Campaign level *********";

if $debug
then

#Create a Campaign
#=================
echo "promoted_object={\"product_catalog_id\":$CATALOG_ID}"
echo "Creating a Campaign ..."
if [ "$EXC_CUS_AUD" != "[]" -a "$INC_CUS_AUD" != "[]" ]; then
	name_appender=" - Include and Exclude CA"
elif [ "$EXC_CUS_AUD" = "[]" -a "$INC_CUS_AUD" != "[]" ]; then
	name_appender=" - Include CA"
elif [ "$EXC_CUS_AUD" != "[]" -a "$INC_CUS_AUD" = "[]" ]; then
	name_appender=" - Exclude  CA"
fi

CAMP_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA Campaign (Purchase) Rec $REC_DAYS day(s) $name_appender" -F 'objective=PRODUCT_CATALOG_SALES' -F "campaign_group_status=$CAMP_STATUS" -F "promoted_object={\"product_catalog_id\":$CATALOG_ID}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adcampaign_groups ); IDExtract "$SET")
echo "Campaign -- $CAMP_ID \n"



#Create an Ad Set
#================
#PRODUCT

#BID=$((P_BID_P / 100))
BID=$(echo "scale=2; $P_BID_P/100" | bc)
echo "name=${ADV_NAME} DPA: Purchase Adset $P_BID_TYPE - $BID"
echo "Creating a PURCHASE Ad Set ..."
PURC_ADSET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA: Purchase Adset $P_BID_TYPE - $BID" -F "bid_type=$P_BID_TYPE" -F "bid_info={\"${P_BID_ACTION}\":$P_BID_P}" -F "campaign_status=$ADSET_STATUS" -F "daily_budget=$P_DAILY_BUD" -F "campaign_group_id=$CAMP_ID" -F "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD_PURC], \"page_types\": [\"${PLACEMENT_TYPE_DESK}\"],\"custom_audiences\": $INC_CUS_AUD,\"excluded_custom_audiences\": $EXC_CUS_AUD}" -F "promoted_object={\"product_set_id\":$PROD_SET_ID}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adcampaigns ); IDExtract "$SET")
echo "Purchase Ad Set -- $PURC_ADSET_ID \n"
fi
if $debug
then
#Mobile PRODUCT

#BID=$((MP_BID_P / 100))
BID=$(echo "scale=2; $MP_BID_P/100" | bc)
echo "name=${ADV_NAME} DPA: Mobile Product Adset $MP_BID_TYPE - $BID"
echo "Creating a Mobile PRODUCT Ad Set ..."
MPURC_ADSET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA: Mobile Product Adset $MP_BID_TYPE - $BID" -F "bid_type=$MP_BID_TYPE" -F "bid_info={\"${MP_BID_ACTION}\":$MP_BID_P}" -F "campaign_status=$ADSET_STATUS" -F "daily_budget=$MP_DAILY_BUD" -F "campaign_group_id=$CAMP_ID" -F "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD_PURC], \"page_types\": [\"${PLACEMENT_TYPE_MOB}\"],\"custom_audiences\": $INC_CUS_AUD,\"excluded_custom_audiences\": $EXC_CUS_AUD}" -F "promoted_object={\"product_set_id\":$PROD_SET_ID}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adcampaigns ); IDExtract "$SET")
echo "Mobile Purchase Ad Set -- $MPURC_ADSET_ID \n"
fi

else
echo "CATALOG_ID, PROD_SET_ID and PURC_AUD_CART are required to start from Audience level"
exit 0;
fi # Required fields check
fi # Level start ends here for Campaign

if [ $LEVEL_STARTED == true -o  "$DPA_LEVEL_START" = "CREATIVE" ]; then
if [ $PROD_SET_ID != "" -a  $PROD_AUD_PURC != "" -a $CAMP_ID != "" -a $MPURC_ADSET_ID != "" -a $PURC_ADSET_ID != "" ]; then
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
#PURCHASE
echo "Creating a Purchase Ad Creative ..."
PURC_AD_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} DPA: Purchase AD" -F "campaign_id=$PURC_ADSET_ID" -F "creative={\"creative_id\":$CREATIVE_ID}" -F 'objective=PRODUCT_CATALOG_SALES' -F "tracking_specs={\"action.type\":\"offsite_conversion\",\"offsite_pixel\":\"$CONV_PIXEL_ID\"}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adgroups ); IDExtract "$SET")
echo "PROD Creative -- $PURC_AD_ID \n"

#Mobile PURCHASE
echo "Creating a Mobile PURCHASE Ad Creative ..."
MPURC_AD_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} DPA: Mobile Purchase AD" -F "campaign_id=$MPURC_ADSET_ID" -F "creative={\"creative_id\":$CREATIVE_ID}" -F 'objective=PRODUCT_CATALOG_SALES' -F "tracking_specs={\"action.type\":\"offsite_conversion\",\"offsite_pixel\":\"$CONV_PIXEL_ID\"}" -F "access_token=$SYS_ADMIN_TOKEN" ${ADV_ENTITY_FB_URL}/adgroups ); IDExtract "$SET")
echo "Mobile PROD Creative -- $MPURC_AD_ID \n"

else
echo "PROD_SET_ID, PROD_AUD_CART, PROD_AUD_PROD,CAMP_ID, MCART_ADSET_ID, MPROD_ADSET_ID, PROD_ADSET_ID and CART_ADSET_ID are required to start from Audience level"
#exit 0;
fi # Required fields check
fi # Level starting for Campaign ends here.

exit 0;
#Logging in mysql for report read.
mhost='20.20.20.71'
muser='root'
mpwd='Test123$'
mdb='social_dco'
echo "Started  - inserting data into Mysql for reporting configuration"
mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD_PROD'","ViewContent","'$CAMP_ID'","'$PROD_ADSET_ID'","'$CREATIVE_ID'","'$PROD_AD_ID'")' 

mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD_CART'","AddToCart","'$CAMP_ID'","'$CART_ADSET_ID'","'$CREATIVE_ID'","'$CART_AD_ID'")'

mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD_PROD'","ViewContent","'$CAMP_ID'","'$MPROD_ADSET_ID'","'$CREATIVE_ID'","'$MPROD_AD_ID'")'

mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'INSERT INTO `DPACampaign` (`advertiser_id`,`dpa_camp_conf_id`,`dpa_catalog_id`,`dpa_productset_id`,`dpa_audience_id`,`dpa_audience_event`,`campaign_id`,`adset_id`,`creative_id`,`adgroup_id`) VALUES ("'$ADV_ID'",0,"'$CATALOG_ID'","'$PROD_SET_ID'","'$PROD_AUD_CART'","AddToCart","'$CAMP_ID'","'$MCART_ADSET_ID'","'$CREATIVE_ID'","'$MCART_AD_ID'")'
echo "Completed - inserting data into Mysql for reporting configuration"
exit 0;
