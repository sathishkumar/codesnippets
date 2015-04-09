#!/bin/bash
sync=true
spec_adv_ids=$1 #single and multipe advertiser id can be added by using comma - no ids mentioned taken as all advertiser
basequery='select distinct ci_adv_id as adv_id from CatalogItem'

mhost='20.20.20.71'
muser='root'
mpwd='Test123$'
mdb='dco'

if [ "$spec_adv_ids" = "" ]
then
        query=$basequery;
        echo "here no advertiser id(s) given"
else
        query="$basequery where ci_adv_id in ($spec_adv_ids)";
        echo "specific advertiser ids mentioned"
fi
echo $query
adv="";
mysql -h$mhost  -u$muser -p$mpwd $mdb -e "$query" | sed 1d | while read id; do echo $id; echo adv="$id $adv"; done
echo $adv
#array_adv = array(($adv))


##	echo "here in read of adv id: $adv_id";
##	if [ $sync = "true" ] 
##	then
##		file_name="_feed.txt";
##		echo "running for $adv_id" >> /tmp/dpa_dco_feed.lock
##		echo $adv_id;
##		echo $adv_id$file_name;
##		cd ~/feed_temp  && rm -rf ~/feed_temp/$adv_id$file_name

##		(echo '<?xml version="1.0"?><feed xmlns="http://www.w3.org/2005/Atom" xmlns:g="http://base.google.com/ns/1.0"><title>FirstCry Store</title><link>http://www.firstcry.com</link>';mysql -h$mhost  -u$muser -p$mpwd $mdb -e 'select (ci_sku) as id,("in stock") as availability,("new") as cond,(ci_title) as description,(ci_default_image) as image_link,concat(ci_page_link,(IF(locate("?",ci_page_link)=0,"?","&")),"ref=kmlwca_NF_DPA&utm_source=KomliWCA&utm_medium=FacebookNF&utm_content=DPA") as link,(ci_title) as title,(IF(ci_sale_price=0,ci_original_price,ci_sale_price)) as price,(ci_brand) as brand, (ic_category_name) as cat, (ic_sub_category_name) as sub_cat from CatalogItem, ItemCategory ic where ic_item_id=ci_id and ci_adv_id='$adv_id | sed 1d | sed -e 's/\t/|/g;' | while IFS="|" read id av con des img link tit pri bra cat subcat; do echo "<entry>"; echo '<g:id>'"$(echo $id | sed -e "s/'/\"/g;")</g:id>";  echo '<g:availability>'"$(echo $av | sed -e "s/'/\"/g;")</g:availability>";  echo '<g:condition>'"$(echo $con | sed -e "s/'/\"/g;")</g:condition>"; echo '<g:description>'"$(echo $des | sed -e "s/'/\"/g;")</g:description>"; echo '<g:image_link>'"$(echo $img | sed -e "s/'/\"/g;")</g:image_link>"; echo '<g:link>'"$(echo $link | sed -e "s/'/\"/g;")</g:link>"; echo '<g:title>'"$(echo $tit | sed -e "s/'/\"/g;")</g:title>"; echo '<g:price>'"$(echo $pri | sed -e "s/'/\"/g;") INR</g:price>"; echo '<g:brand>'"$(echo $bra | sed -e "s/'/\"/g;")</g:brand>"; echo '<g:google_product_category>'"$(echo $cat | sed -e "s/'/\"/g;") > $(echo $subcat | sed -e "s/'/\"/g;")</g:google_product_category>"; echo "</entry>"; done;echo '</feed>';) | sed -e 's/&/&amp;/g' > $adv_id$file_name | rm -rf /tmp/dpa_dco_feed.lock

##		iconv -f iso-8859-1 -t UTF-8 $adv_id$file_name > /atom/origin_temp/creatives/$adv_id$file_name
##		sync=false
##	else
##		sleep 1 
##	fi
##done
