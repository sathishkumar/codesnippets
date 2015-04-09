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

#Add new products into our image resizer table in dco db.
echo "Started: Populating new product's image link...";
echo $(mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e "INSERT INTO dco_image_resize (adv_id, sku, default_image, feed_id,status) SELECT ci_adv_id, ci_sku, ci_default_image, ci_feed_id,0 as status FROM CatalogItem WHERE ci_adv_id=$adv_id AND ci_sku NOT IN (SELECT sku FROM dco_image_resize WHERE adv_id=$adv_id)");
echo "Completed: Populating new product's image link.";

#echo $(mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e "update dco_image_resize set default_image=substring(default_image,10,100) limit 10");

echo "Started: Update product's image link which has been changeed recently in feed ... ";
echo $(mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e "UPDATE dco_image_resize INNER JOIN CatalogItem ON ci_adv_id=adv_id AND ci_sku=sku SET status=1, default_image=ci_default_image WHERE default_image!=ci_default_image AND ci_adv_id=$adv_id");
echo "Completed: Update product's image link which has been changeed recently in feed.";

echo "****Completed addition/updation****";
updateRec=$(mysql -h$mhost -u$muser -p$mpwd $mdb -s -N -e 'select count(*) as Update_required from dco_image_resize WHERE status=1');
echo "We need to create/regenerate 200x200 dimention images for $updateRec products"

#exit
exit 
