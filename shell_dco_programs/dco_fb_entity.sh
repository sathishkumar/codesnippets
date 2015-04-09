#!/bin/bash
ADV_ID=$1
DIR=/home/km/properties
#/home/skumar/properties
debug=$2

. ${DIR}/${ADV_ID}.txt
echo $B_ACCESSTOKEN
echo $ADV_NAME

FB_URL=https://graph.facebook.com/v2.2
ADV_ENTITY_FB_URL=${FB_URL}/act_${ADV_AD_ACCOUNT_ID}
FEED=${ADV_ID}_feed.txt.gz

IDExtract(){
	SET=$( echo "$1" | jq ".id") 
	if [ "$SET" = "" ]; then
		echo $1;	
		echo "Existing here due to API exception thrown."
		exit 0;
	else
		temp="${SET%\"}";temp="${temp#\"}";echo "$temp"
	fi
}

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

#Create Product Audience
#=======================
#PRODUCT
echo "Creating Product Audience :: Product only ..."
PROD_AUD_PROD=$(SET=$(curl -s -F "name=${ADV_NAME} PA - Prod Rec 7"  -F "product_set_id=$PROD_SET_ID"  -F "pixel_id=$DATA_PIXEL_ID" -F 'inclusions=[{"retention_seconds": 604800,"rule": {"event": {"eq": "ViewContent"},}}]' -F 'exclusions=[{"retention_seconds": 604800,"rule": {"event": {"eq": "Purchase"}}},{"retention_seconds": 604800,"rule": {"event": {"eq": "AddToCart"},}}]' -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/product_audiences ); IDExtract "$SET")
echo "PROD_AUD_PRODUCT  -- $PROD_AUD_PROD \n"
#CART
echo "Creating Product Audience :: Cart only ..."
PROD_AUD_CART=$(SET=$(curl -s -F "name=${ADV_NAME} PA - Cart Rec 7"  -F "product_set_id=$PROD_SET_ID"  -F "pixel_id=$DATA_PIXEL_ID" -F 'inclusions=[{"retention_seconds": 604800,"rule": {"event": {"eq": "AddToCart"},}}]' -F 'exclusions=[{"retention_seconds": 604800,"rule": {"event": {"eq": "Purchase"}}}]' -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/product_audiences ); IDExtract "$SET")
echo "PROD_AUD_CART  -- $PROD_AUD_CART \n"

#Pixel Product Catalog Preferences
#=================================
echo "Associate Pixel with Catalog for event tracking..."
PIX_CATALOG=$(SET=$(curl -s -F "external_event_sources=[$DATA_PIXEL_ID]" -F "access_token=$B_ACCESSTOKEN" ${FB_URL}/${CATALOG_ID}/external_event_sources); echo "$SET")
echo "Associationg done -- $PIX_CATALOG \n"
if $debug
then

#Create a Campaign
#=================
echo "promoted_object={\"product_catalog_id\":$CATALOG_ID}"
echo "Creating a Campaign ..."
CAMP_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA Campaign Group" -F 'objective=PRODUCT_CATALOG_SALES' -F "campaign_group_status=$CAMP_STATUS" -F "promoted_object={\"product_catalog_id\":$CATALOG_ID}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adcampaign_groups ); IDExtract "$SET")
echo "Campaign -- $CAMP_ID \n"



#Create an Ad Set
#================
#PRODUCT

BID=$((P_BID_P / 100))
echo "name=${ADV_NAME} DPA: Product Adset $P_BID_TYPE - $BID"
echo "Creating a PRODUCT Ad Set ..."
PROD_ADSET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA: Product Adset $P_BID_TYPE - $BID" -F "bid_type=$P_BID_TYPE" -F "bid_info={\"${P_BID_ACTION}\":$P_BID_P}" -F "campaign_status=$ADSET_STATUS" -F "daily_budget=$P_DAILY_BUD" -F "campaign_group_id=$CAMP_ID" -F "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD_PROD], \"page_types\": [\"${PLACEMENT_TYPE_DESK}\"]}" -F "promoted_object={\"product_set_id\":$PROD_SET_ID}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adcampaigns ); IDExtract "$SET")
echo "Product Ad Set -- $PROD_ADSET_ID \n"
fi
if $debug
then
#CART
BID=$((C_BID_P / 100))
echo "Creating a CART Ad Set ..."
CART_ADSET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA: CART Adset $C_BID_TYPE - $BID" -F "bid_type=$C_BID_TYPE" -F "bid_info={\"${C_BID_ACTION}\":$C_BID_P}" -F "campaign_status=$ADSET_STATUS" -F "daily_budget=$C_DAILY_BUD" -F "campaign_group_id=$CAMP_ID" -F "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD_CART], \"page_types\": [\"${PLACEMENT_TYPE_DESK}\"]}" -F "promoted_object={\"product_set_id\":$PROD_SET_ID}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adcampaigns ); IDExtract "$SET")
echo "CART Ad Set -- $CART_ADSET_ID \n"

#Mobile PRODUCT

BID=$((MP_BID_P / 100))
echo "name=${ADV_NAME} DPA: Mobile Product Adset $MP_BID_TYPE - $BID"
echo "Creating a Mobile PRODUCT Ad Set ..."
MPROD_ADSET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA: Mobile Product Adset $MP_BID_TYPE - $BID" -F "bid_type=$MP_BID_TYPE" -F "bid_info={\"${MP_BID_ACTION}\":$MP_BID_P}" -F "campaign_status=$ADSET_STATUS" -F "daily_budget=$MP_DAILY_BUD" -F "campaign_group_id=$CAMP_ID" -F "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD_PROD], \"page_types\": [\"${PLACEMENT_TYPE_MOB}\"]}" -F "promoted_object={\"product_set_id\":$PROD_SET_ID}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adcampaigns ); IDExtract "$SET")
echo "Mobile Product Ad Set -- $MPROD_ADSET_ID \n"
fi
if $debug
then
#Mobile CART
BID=$((MC_BID_P / 100))
echo "Creating a Mobile CART Ad Set ..."
MCART_ADSET_ID=$(SET=$(curl -s -F "name=${ADV_NAME} DPA: Mobile CART Adset $MC_BID_TYPE - $BID" -F "bid_type=$MC_BID_TYPE" -F "bid_info={\"${MC_BID_ACTION}\":$MC_BID_P}" -F "campaign_status=$ADSET_STATUS" -F "daily_budget=$MC_DAILY_BUD" -F "campaign_group_id=$CAMP_ID" -F "targeting={\"geo_locations\": {\"countries\": [\"${COUN}\"]},\"dynamic_audience_ids\": [$PROD_AUD_CART], \"page_types\": [\"${PLACEMENT_TYPE_MOB}\"]}" -F "promoted_object={\"product_set_id\":$PROD_SET_ID}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adcampaigns ); IDExtract "$SET")
echo "Mobile CART Ad Set -- $MCART_ADSET_ID \n"

#Create Dynamic Ad Template Creatives
#====================================
echo 
echo "Creating a Ad Template Creative ..."
CREATIVE_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} Dynamic Ad Template Creative" -F "object_story_spec={\"page_id\": $ADV_PAGE_ID,\"template_data\": {\"call_to_action\": {\"type\": \"SHOP_NOW\"},\"message\": \"$TEMP_CREATIVE_MSG\",\"link\": \"$ADV_URL\",\"name\": \"{{product.price}}\",\"description\": \"{{product.name}}\",\"max_product_count\": 5}}" -F "product_set_id=$PROD_SET_ID" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adcreatives ); IDExtract "$SET")
echo "Creative Template -- $CREATIVE_ID \n"

#Create Ad Groups
#================
#PRODUCT
echo "Creating a PROD Ad Creative ..."
PROD_AD_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} DPA: Product AD" -F "campaign_id=$PROD_ADSET_ID" -F "creative={\"creative_id\":$CREATIVE_ID}" -F 'objective=PRODUCT_CATALOG_SALES' -F "tracking_specs={\"action.type\":\"offsite_conversion\",\"offsite_pixel\":\"$CONV_PIXEL_ID\"}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adgroups ); IDExtract "$SET")
echo "PROD Creative -- $PROD_AD_ID \n"

#CART
echo "Creating a CART Ad Creative ..."
CART_AD_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} DPA: CART AD" -F "campaign_id=$CART_ADSET_ID" -F "creative={\"creative_id\":$CREATIVE_ID}" -F 'objective=PRODUCT_CATALOG_SALES' -F "tracking_specs={\"action.type\":\"offsite_conversion\",\"offsite_pixel\":\"$CONV_PIXEL_ID\"}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adgroups ); IDExtract "$SET")
echo "CART Creative -- $CART_AD_ID \n"


#Mobile PRODUCT
echo "Creating a Mobile PROD Ad Creative ..."
MPROD_AD_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} DPA: Mobile Product AD" -F "campaign_id=$MPROD_ADSET_ID" -F "creative={\"creative_id\":$CREATIVE_ID}" -F 'objective=PRODUCT_CATALOG_SALES' -F "tracking_specs={\"action.type\":\"offsite_conversion\",\"offsite_pixel\":\"$CONV_PIXEL_ID\"}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adgroups ); IDExtract "$SET")
echo "Mobile PROD Creative -- $MPROD_AD_ID \n"

#CART
echo "Creating a Mobile CART Ad Creative ..."
MCART_AD_ID=$(SET=$(curl -s -X POST -F "name=${ADV_NAME} DPA: Mobile Cart AD" -F "campaign_id=$MCART_ADSET_ID" -F "creative={\"creative_id\":$CREATIVE_ID}" -F 'objective=PRODUCT_CATALOG_SALES' -F "tracking_specs={\"action.type\":\"offsite_conversion\",\"offsite_pixel\":\"$CONV_PIXEL_ID\"}" -F "access_token=$ADV_ACCESSTOKEN" ${ADV_ENTITY_FB_URL}/adgroups ); IDExtract "$SET")
echo "Mobile CART Creative -- $MCART_AD_ID \n"

fi

