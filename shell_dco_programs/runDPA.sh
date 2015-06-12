#!/bin/bash
DPA_LOGS_DIR=/home/skumar/DPA_LOGS
DIR=/home/km/properties

. ${DIR}/${ADV_ID}.txt

#Image Overlay
if [ "$imageOverlay" = "NONE" ]; then
	echo "Image Overlay is omitted"
elif [ "$imageOverlay" = "BubbleOnly" ]; then
	nohup bash /home/skumar/DPA_BASH/ImageOverlayConvert_BubbleOnly.sh ${ADV_ID} ${CURRENCY} ${TEXT_COLOR} ${BG_COLOR} > ${DPA_LOGS_DIR}/imageConvert_${ADV_ID}.log
elif [ "$imageOverlay" = "PriceBarWithDiscount" ]; then
	nohup bash /home/skumar/DPA_BASH/ImageOverlayConvert.sh ${ADV_ID} ${CURRENCY} ${TEXT_COLOR} ${BG_COLOR} > ${DPA_LOGS_DIR}/imageConvert_${ADV_ID}.log
elif [ "$imageOverlay" = "StockImage" ]; then
	nohup bash /home/skumar/DPA_BASH/ImageOverlayConvert_StockImageOnly.sh ${ADV_ID} ${CURRENCY} ${TEXT_COLOR} ${BG_COLOR} > ${DPA_LOGS_DIR}/imageConvert_${ADV_ID}.log
fi

echo "image conversion has been started with $imageOverlay"

#Feed Configuration/Generation
if [ "$imageOverlay" = "NONE" ]; then
	/home/skumar/DPA_BASH/dco_feed_generator_tsv_image_overlay.sh ${ADV_ID} ${CURRENCY} ${BRAND} ${UTM_STRING} > ${DPA_LOGS_DIR}/generateFeed_${ADV_ID}.log
else
	/home/skumar/DPA_BASH/dco_feed_generator_tsv.sh ${ADV_ID} ${CURRENCY} ${BRAND} ${UTM_STRING} > ${DPA_LOGS_DIR}/generateFeed_${ADV_ID}.log
fi

#FB Entity Creation
#
