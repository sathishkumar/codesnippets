puts "Hello World"

require 'rubygems'
require 'net/http'
require 'net/https'
require 'json'

# Type could be INC_CA, EXCLUDE_CA, BID_PRICE, BID_TYPE, DAILY_BUDGET, COUNTRY
TYPE=ARGV[0]
ENTITY_ID=ARGV[1] 
#camp_id: 6031950752504
API_CALL='adcampaigns'
DATA=ARGV[2]
ENTITY=ARGV[3]
if (TYPE == "" || ENTITY_ID == "" || DATA == "")
    puts "Please pass necessary args for TYPE<action to perform>, ENTITY_ID(Campaign or Adset) and DATA"
    exit
end
class FBHttps
	def initialize()
		targeting=""
		bid_info=""
		bid_type=""
		daily_budget=""
	end

	def fbPostUpdate(fb_url,type,targeting,bid_info,bid_type,daily_budget)
	        https = Net::HTTP.new(fb_url.host, fb_url.port)
	        https.use_ssl = true
	        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

	        post_req = Net::HTTP::Post.new(fb_url.request_uri, {'Content-Type' =>'application/json'})
	        #INC_CA, EXCLUDE_CA, BID_PRICE, BID_TYPE, DAILY_BUDGET, COUNTRY
	        puts type
	        if type=="INC_CA" || type=="EXCLUDE_CA" || type=="COUNTRY"
	                puts targeting
	                post_req.set_form_data('targeting' => targeting)
	        elsif type=="BID_PRICE"
	                puts bid_info
	                post_req.set_form_data('bid_info' => bid_info)
	        elsif type=="BID_TYPE"
	                puts bid_type
	                post_req.set_form_data('bid_type' => bid_type)
	        elsif type=="DAILY_BUDGET"
	                puts daily_budget
	                post_req.set_form_data('daily_budget' => daily_budget)
		else
			puts "Type didn't match any update call"
	        end
		puts post_req.body
	        post_res = https.request(post_req)
		puts post_res.body
		post_res
	end
	
	def fbGet(fb_url)
		https = Net::HTTP.new(fb_url.host, fb_url.port)
		https.use_ssl = true
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		get_req = Net::HTTP::Get.new(fb_url.request_uri)
		res = https.request(get_req)
	end

end


class ProcessReq
	def initialize()
                targeting=""
		bid_price="0"
                bid_info=""
                bid_type=""
                daily_budget=""
        end

	def adset_process(adset)
		puts adset
		puts "-------------"
	        adset_id = adset["id"]
		httpspost = FBHttps.new()

	        fb_post_url = URI.parse('https://graph.facebook.com/v2.2/'+ adset_id+ '?access_token=' + FACEBOOK_ACCESS_TOKEN)
 
	        if TYPE=="INC_CA" || TYPE=="EXCLUDE_CA" || TYPE=="COUNTRY"
	                ca = Array.new
	                if adset["targeting"]["custom_audiences"]!=nil
	                        adset["targeting"]["custom_audiences"].each do |c_aud|
	                                ca << c_aud
	                        end
	                end
 	                (TYPE=="INC_CA" ? ca << DATA : ca)
 	
	                exclude_ca = Array.new
	                if adset["targeting"]["excluded_custom_audiences"]!=nil
	                        adset["targeting"]["excluded_custom_audiences"].each do |ec_aud|
	                                exclude_ca << ec_aud
	                        end
	                end
	                (TYPE=="EXCLUDE_CA" ? exclude_ca << DATA : exclude_ca)
	                targeting=""
	       	        geo='{"countries": '
	                geo=geo.concat((TYPE=="COUNTRY" ? '["'+DATA+'"]' : adset["targeting"]["geo_locations"]["countries"])).concat('}')
        	        dynamic_aud=adset["targeting"]["dynamic_audience_ids"].to_json
	                page_types=adset["targeting"]["page_types"].to_json
	       	        ca=ca.to_json
        	        exclude_ca=exclude_ca.to_json

			targeting.concat('{"geo_locations":').concat(geo).concat(',"dynamic_audience_ids": ').concat(dynamic_aud).concat(', "page_types": ').concat(page_types).concat(',"custom_audiences": ').concat(ca).concat(',"excluded_custom_audiences": ').concat(exclude_ca).concat('}').to_json	
	        end
	        puts adset["bid_info"]["Actions"]
	        bid_price="0",bid_info="",bid_type=""
	        bid_price = (TYPE=="BID_PRICE"? DATA : adset["bid_info"]["ACTIONS"])
	        bid_info.concat('{"ACTIONS":').concat("#{bid_price}").concat('}')
	        bid_type = (TYPE=="BID_TYPE"? DATA : adset["bid_type"])
	        daily_budget = (TYPE=="DAILY_BUDGET"? DATA : adset["daily_budget"])
	
		httpspost.fbPostUpdate(fb_post_url,TYPE,targeting,bid_info,bid_type,daily_budget)
		puts "**************"
	end
end

FACEBOOK_ACCESS_TOKEN='CAAEDOFD5jeEBABSiQpiqu5Dm6BjPziaOaowD0KfHECh5cSdFLPa1cAYYpeyQ0cW8ZC3roqLNvry4BIHwsZAIrpuSSRzOjGD0Y78FPsOrzHC0wtTOr8YFk12GyK7LhTtWZBMUHUTLjj9UOUf3L723KYnZCZCrfbjwv7qb3ZCKc2uZCxcMAUucwlxJkwXZAeFyy7c63ml5YZAfRpjYUZBRAmeegm'

fb_api=(ENTITY=="ADSET"? ENTITY_ID : ENTITY_ID+ '/'+ API_CALL)
fb_url = URI.parse('https://graph.facebook.com/v2.2/'+ fb_api + '?fields=name,targeting,bid_type,bid_info,daily_budget'+ '&access_token=' + FACEBOOK_ACCESS_TOKEN) 
getObj=FBHttps.new()
fbGetRes = getObj.fbGet(fb_url)

parsed = JSON.parse(fbGetRes.body)

procAdset = ProcessReq.new()

if ENTITY=="ADSET"
	procAdset.adset_process(parsed)
elsif ENTITY=="CAMPAIGN"
	parsed["data"].each do |adset|
		procAdset.adset_process(adset)	
	end
end
