#!/bin/bash
adv_id=$1
dimension=$2
if [[ "$adv_id" == "" ]]; then
        echo "Please give the advertiser_id ";
        exit 1;
else
        echo "Social DCO Starting: Populate new product image liks and edit exiting if changes observed in dco db -dco_image_resizetable- and -CatalogItem- for Advertiser $adv_id";
fi

mhost='20.20.20.71'
muser='root'
mpwd='Test123$'
mdb='dco'

CDN=https://tor.atomex.net/social_dco_feed
CONV_DIR=/home/km/social_dco

DirFinder() {
	SKU_ID=$1
	echo ${SKU_ID:0:2}	
}

CreateDirIfNotExist() {
SKU_ID=$1
FOLDER_NAME=$(DirFinder $SKU_ID);
DIR=${CONV_DIR}/${adv_id}/${FOLDER_NAME}
	if [ ! -d "${DIR}" ]; then
		# Control will enter here if $DIRECTORY desn't exists. Creating Directory
		mkdir -p "${DIR}/default_images/"
		chmod -R 777 "${DIR}/default_images/"
	fi
echo "${DIR}"
}

mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e "SELECT sku, default_image FROM dco_image_resize WHERE status=1 AND adv_id=$adv_id limit 2" | while read sku url;
do
	echo $sku
        IMG_DIR=$(CreateDirIfNotExist "$sku");

	echo $IMG_DIR
        echo $url
        IMG_NAME="${sku}_${dimension}_$(IFS="/"; temp_arr=($url); size=${#temp_arr[@]}; echo ${temp_arr[size-1]})";
	echo $IMG_NAME	
        wget -nv $url -P "${IMG_DIR}/default_images/"
        echo "$advId --- $url";
	echo "${IMG_DIR}/default_images/${IMG_NAME}"
	echo "${IMG_DIR}/${dimension}${IMG_NAME}"
	convert -resize "$dimension" "${IMG_DIR}/default_images/${IMG_NAME}" "${IMG_DIR}/${IMG_NAME}"
	FOLDER_NAME=$(DirFinder $sku);
	image_url="${CDN}/${adv_id}/${FOLDER_NAME}/${IMG_NAME}"
	echo "UPDATE dco_image_resize SET status=0,200x200_image='$image_url' WHERE sku=$sku AND adv_id=$adv_id"
	mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e "UPDATE dco_image_resize SET status=0,200x200_image='$image_url' WHERE sku=$sku AND adv_id=$adv_id;"
	 echo "-------------------------------------------"
done

echo "We need to create/regenerate 200x200 dimention images for $updateRec products"



#exit
exit
~                                                                                                                                                                                                             
~                                                                                                                                                                                                             
~                                                                                                                                                                                                             
~                            
