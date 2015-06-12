#!/bin/bash

DPA_PROP_LOC=/home/km/properties
#mysql configuration.
mhost='20.20.20.71'
muser='root'
mpwd='Test123$'
mdb='social_dco'
select_columns='id, dpa_startwith, advertiser_id, advertiser_name, adv_ad_account_id, currency, image_overlay, text_color, bg_color, utm_string, utm_string_action, utm_string_remove, feed_intvl, feedintvl_type, feedintvl_value, data_pixel_id, product_set_name, product_set_filter, audience_name, audience_event, audience_retension_sec, exc_audience_retension_sec, exclude_custom_audiences_in_aud, include_custom_audiences_in_aud, campaign_group_status, bid_type, bid_info, bid_value, daily_budget, daily_budget, max_age, min_age, gender, country, placement, include_custom_audiences, exclude_custom_audiences, adset_status, page_id, call_to_action, creative_message, advertiser_link, macro_name, macro_description, max_product_count, conversion_pixel_id, ex_catalog_id, ex_prod_set_id, ex_audience_id, created_at, updated_at, job_status'
mysql -h$mhost -u$muser -p$mpwd $mdb -e "SELECT $select_columns FROM DPACampaignConfig WHERE job_status!='Completed';" | sed 1d | while read $(echo $select_columns | sed 's/, / /g'); do
if [ "$job_status" = "NotProcessed" ]; then
## FILE CREATION
	FILE_NAME="${id}_camp_conf.txt"
	sudo cp ${DPA_PROP_LOC}/SAMPLE_DPAcamp_conf.txt ${DPA_PROP_LOC}/$FILE_NAME
	echo $creative_message
## Property file column values updation
	IFS=', ' read -a  columns <<< "$select_columns"
	echo "${columns[@]}"
	for column in "${columns[@]}"
	do
		echo ${!column}
		cmd="sudo sed -i 's/##$column/${!column}/g' ${DPA_PROP_LOC}/${FILE_NAME}"
		echo "$cmd"
		eval "$cmd"
	done
elif [ "$job_status" = "PropertyAssigned" ]; then
	## Image Generation
elif [ "$job_status" = "ImageConversionDone" ]; then
	## Feed Generation
	## Campaign Creation using Config that's been uploaded
fi
done
