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
        #image directory creator
        IMG_DIR=$(CreateDirIfNotExist "$sku");

        #image name formation
        IMG_NAME="$(IFS="/"; temp_arr=($url); size=${#temp_arr[@]}; echo ${temp_arr[size-1]})";
	
	NEW_IMG_NAME="${sku}_${dimension}_${IMG_NAME}"
        #Downloading default image
        wget -nv $url -P "${IMG_DIR}/default_images/"

        #resizing the image based on dimension passed and creating in mounted directory to upload into CDN.
        convert -resize "$dimension" "${IMG_DIR}/default_images/${IMG_NAME}" "${IMG_DIR}/${NEW_IMG_NAME}"

        #Folder name of product uploaded
        FOLDER_NAME=$(DirFinder $sku);

        #new image url formation
        image_url="${CDN}/${adv_id}/${FOLDER_NAME}/${NEW_IMG_NAME}"

        #Updating in mysql dco_image_resize table to don't process further.
        mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e "UPDATE dco_image_resize SET status=0,200x200_image='$image_url' WHERE sku=$sku AND adv_id=$adv_id;"

        echo "$sku product got resized and updatd in DB. **********"

        #deleting downloaed file to avoid uploading these in cdn
       # rm -rf "${IMG_DIR}/default_images/${IMG_NAME}"

done

echo "We need to create/regenerate 200x200 dimention images for $updateRec products"



#exit
exit
~                                                                                                                                                                                                             
~                                                                                                                                                                                                             
~                                                                                                                                                                                                             
~                            
