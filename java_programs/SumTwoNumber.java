import java.util.Scanner;

public class SumTwoNumber {
        static int totalEntries = 0;
        static String newSiteAdd;
//        static String siteAdd = "";
        public static void main(String args[]){
                Scanner scan = new Scanner(System.in);
                totalEntries = Integer.parseInt(scan.next());
                
                for(int i=0; i<totalEntries; i++){
                	String siteAdd = scan.next();
                	newSiteAdd  = siteAdd.split("[.]")[1].replaceAll("[aeiouAEIOU]","")+".com";
                	System.out.println(newSiteAdd.length()+"/"+siteAdd.length());
                }
        }
}
