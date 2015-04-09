Steps:
1.  Mysql Create talbe
2.  mysql -h20.20.20.71 -uroot -pTest123$ dco -e "truncate dco_image_resize;"
3.  sudo sh shell_dco_programs/dco_image_resize.sh 5870
4.  sudo bash shell_dco_programs/dco_image_converter.sh 5870 200x200
5.  Verify, mysql -h20.20.20.71 -uroot -pTest123$ dco -e "SELECT sku,default_image,200x200_image FROM dco_image_resize WHERE status=0 AND adv_id=5870 limit 10";
