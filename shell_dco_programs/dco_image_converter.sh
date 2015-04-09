#!/bin/bash
adv_id=$1

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

CONV_DIR=/home/km/social_dco
CreateDirIfNotExist() {
sku_id=$1
DIR=${CONV_DIR}/${adv_id}/${sku_id:0:2}
echo $DIR
if [ ! -d "${DIR}" ]; then
	# Control will enter here if $DIRECTORY desn't exists. Creating Directory
	mkdir -p $DIR
fi
}

mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e "SELECT sku, default_image FROM dco_image_resize WHERE status=1 AND adv_id=$adv_id" | sed 1d | while read sku url;
do
	echo $sku
	CreateDirIfNotExist "$sku"
        echo "$advId --- $url";
done

echo "We need to create/regenerate 200x200 dimention images for $updateRec products"



#exit
exit
~                                                                                                                                                                                                             
~                                                                                                                                                                                                             
~                                                                                                                                                                                                             
~                            
