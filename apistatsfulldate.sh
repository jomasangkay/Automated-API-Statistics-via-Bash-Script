#!/bin/bash

error_exit() {
    echo "ERROR: $1"; exit 1
}

variables () {
lambdas="/aws/lambda/cxs-java-engaged-party-01-prod-buyLoad /aws/lambda/cxs-java-engaged-party-01-prod-paymentSessions /aws/lambda/cxs-node-common-01-prod-user /aws/lambda/cxs-node-common-05-prod-accounts /aws/lambda/cxs-node-common-05-prod-accounts-v3 /aws/lambda/cxs-node-common-05-prod-users /aws/lambda/cxs-node-engaged-party-01-prod-accounts /aws/lambda/cxs-node-engaged-party-02-prod-campaigns /aws/lambda/cxs-node-engaged-party-02-prod-promos-lambda /aws/lambda/cxs-node-engaged-party-02-prod-promos-v2 /aws/lambda/cxs-node-engaged-party-04-prod-payment-receipts /aws/lambda/cxs-node-product-01-prod-loyalty-rewards /aws/lambda/cxs-node-product-01-prod-rewards-points /aws/lambda/cxs-node-product-01-prod-subscribers /aws/lambda/cxs-java-customer-02-prod-prepaidBalance-V2 /aws/lambda/cxs-java-engaged-party-01-prod-paymentSessions /aws/lambda/cxs-node-common-02-prod-group-service /aws/lambda/cxs-node-common-02-prod-report /aws/lambda/cxs-node-common-03-prod-otp /aws/lambda/cxs-node-engaged-party-01-prod-accounts /aws/lambda/cxs-node-engaged-party-04-prod-services /aws/lambda/cxs-node-product-01-prod-loyalty-rewards /aws/lambda/cxs-node-engaged-party-04-prod-request-refund /aws/lambda/cxs-java-customer-01-prod-billingStatements-v2"


}
variables

dateandtime() {
CURRENTDATEANDTIME=`date +"%Y-%m-%dT%"`
CURRENTDATEONLY=`date +"%m/%d/%Y"`
offset=" +0800"
TIMEFORMAT='Elapsed Time: %R seconds.'
}
dateandtime

#Timestamp conversion to epoch

retry=true
while [ ${retry} = true ]; do

echo -e "\nEnter Start date and time in format of \n(MM/DD/YYYY hh:mm:ss)" 
read starttime
inputstarttime="$starttime $offset"
inputstarttimedisplay="$starttime "
echo -e "\n $inputstarttime has been set"

echo -e "\nEnter End date and time in format of \n(MM/DD/YYYY hh:mm:ss)" 
read endtime
inputendtime="$endtime $offset"
inputendtimedisplay="$endtime"
echo -e "\n $inputendtime has been set \n\n======================================================\n"

	if [[ ! -z $inputstarttime ]]; then
		if [[ ! -z $inputendtime ]]; then
startepoch=$(date --date="$inputstarttime" +"%s") || error_exit "Timestamp incorrect format."
endepoch=$(date --date="$inputendtime" +"%s") || error_exit "Timestamp incorrect format."

echo -e "$inputstarttimedisplay to $inputendtimedisplay \nConfirm if timestamp is correct? type Y or N"
read confirm

 if [ ${confirm,,} = y ]; then
            
                echo "Starting extraction..."
                retry=false
            fi
        else 
            error_exit "No timestamp provided."
        fi
    else 
        error_exit "No timestamp provided."
    fi
done

extractedfile="APIstats_Extract.csv"


#Query API stats batch 1 and 2
queryId=$(aws logs start-query --log-group-names $lambdas --start-time "$startepoch"000 --end-time "$endepoch"000 --query-string '"requestId" or "SPLUNK_LOGS RESPONSE" or ("DATA_DICTIONARY" and "GetBillingStatementsPDF") or ("DATA_DICTIONARY" and "MultiplePurchasePromo") | parse @message "operationName: '"'"'*'"'"'," as Final_API | parse @message "segment: '*'," as segment | parse @message "status: *," as Status | parse @message "requestTime: '"'"'*-*-*T*:*:*.*'"'"'," as reqYear_logred, reqM_logred, reqD_logred, reqH_logred, reqMin_logred, reqSec_logred, reqMilliSec_logred | parse @message "responseTime: '"'"'*-*-*T*:*:*.*'"'"'," as resYear_logred, resM_logred, resD_logred, resH_logred, resMin_logred, resSec_logred, resMilliSec_logred | parse @message /(CxsOperationName[^\w]+(?<API_unfinalsplunk>\w+))/ | parse @message /(statusCode[^\d]+(?<statusCode>\d+))/ | parse @message "\"CxsRequestDateTime*\":*\"*-*-*T*:*:*.*\"" as req_dum1_splunk, req_dum2_splunk, reqYear_splunk, reqM_splunk, reqD_splunk, reqH_splunk, reqMin_splunk, reqSec_splunk, reqMilliSec_raw_splunk | fields substr(reqMilliSec_raw_splunk, 0, 3) as reqMilliSec_splunk | parse @message "\"CxsResponseDateTime*\":*\"*-*-*T*:*:*.*\"" as res_dum1_splunk, res_dum2_splunk, resYear_splunk, resM_splunk, resD_splunk, resH_splunk, resMin_splunk, resSec_splunk, resMilliSec_raw_splunk | fields substr(resMilliSec_raw_splunk, 0, 3) as resMilliSec_splunk | parse @log "/aws/lambda/*" as lambda | fields lambda like /prod-promos-v2/ as ctl_value | fields lambda like /prod-promos-lambda/ as bpromo_value | fields concat(ctl_value, bpromo_value) as mpp_value | parse @message "\"event_name*\":*\"*\\*\"" as api_dum1, api_dum2, API_datdic, api_dum3 | parse @message "\"request_timestamp*\":*\"*-*-*T*:*:*.*\\*\"" as req_dum1, req_dum2, reqYear_datdic, reqM_datdic, reqD_datdic, reqH_datdic, reqMin_datdic, reqSec_datdic, reqMilliSec_datdic, req_dum3 | parse @message "\"response_timestamp*\":*\"*-*-*T*:*:*.*\\*\"" as res_dum1, res_dum2, resYear_datdic, resM_datdic, resD_datdic, resH_datdic, resMin_datdic, resSec_datdic, resMilliSec_datdic, res_dum3 | parse @message "\"provisioning_status\\\\\\\\\\\\\":\\\\\\\\\\\\\"*\\\\\\\\\\\\\"" as provisioning_status | fields provisioning_status like /SUCCESS/ as bpromo_success | parse @message "\"transaction_status\\\\\\\":\\\\\\\"*\\\\\\\"," as transaction_status | fields transaction_status like /Success/ as PDF_success | fields segment like /mobile/ and Final_API like /EnrollAccount/ as mob_seg_enroll | fields segment like /broadband/ and Final_API like /EnrollAccount/ as bb_seg_enroll | fields replace(mob_seg_enroll, "1", " (mobile)") as enrollAPI_1 | fields replace(enrollAPI_1, "0", "") as enroll_API_1 | fields replace(bb_seg_enroll, "1", " (broadband)") as enrollAPI_2 | fields replace(enrollAPI_2, "0", "") as enroll_API_2 | fields concat(enroll_API_1, enroll_API_2) as enroll_API_final | fields Final_API like /EnrollAccount/ and mob_seg_enroll like /0/ and  bb_seg_enroll like /0/ as no_enrollAPI_segment | fields replace(no_enrollAPI_segment, "1", " (othererrors)") as no_enrollAPIsegment | fields replace(no_enrollAPIsegment, "0", "") as no_enrollAPIsegment_final | fields concat(API_datdic, Final_API, API_unfinalsplunk, mpp_value,no_enrollAPIsegment_final,enroll_API_final) as API_unfinal | fields replace(API_unfinal, "00", "") as API_unfinal1 | fields replace(API_unfinal1, "-v3", "") as API_unfinal2 | fields replace(API_unfinal2, "-V3", "") as API_unfinal3 | fields replace(API_unfinal3, "-v1", "") as API_unfinal4 | fields replace(API_unfinal4, "-v3", "") as API_unfinal5 | fields replace(API_unfinal5, "-v2", "") as API_unfinal6 | fields replace(API_unfinal6, "GetEnrolledAccounts", "GetEnrolledAccount") as API_unfinal7 | fields replace(API_unfinal7, "GetPrepaidBalanceInquiryV2", "InquirePrepaidBalance") as API_unfinal8 | fields replace(API_unfinal8, "MultiplePurchasePromo01", "BuyPromoLambda-MultiplePurchasePromo") as API_unfinal9 | fields replace(API_unfinal9, "GetGcashBalance", "GetGCashBalance") as API_unfinal10 | fields replace(API_unfinal10, "-v4", "") as API_unfinal11 | fields replace(API_unfinal11, '"'"'MultiplePurchasePromo10'"'"', '"'"'CTL-CTB-MultiplePurchasePromo'"'"') as API_unfinal12 | fields replace(API_unfinal12, "10", "") as API_unfinal13 | fields replace (API_unfinal13,"'"'"'","") as API | fields concat(reqYear_logred, 	reqYear_datdic, 	reqYear_splunk) as reqYear | fields concat(reqM_logred,    	reqM_datdic,    	reqM_splunk) as reqM | fields concat(reqD_logred,    	reqD_datdic,    	reqD_splunk) as reqD | fields concat(reqH_logred,    	reqH_datdic,    	reqH_splunk) as reqH | fields concat(reqMin_logred,  	reqMin_datdic,  	reqMin_splunk) as reqMin | fields concat(reqSec_logred,      reqSec_datdic,      reqSec_splunk) as reqSec  | fields concat(reqMilliSec_logred, reqMilliSec_datdic, reqMilliSec_splunk) as reqMilliSec  | fields concat(resYear_logred, 	resYear_datdic, 	resYear_splunk) as resYear  | fields concat(resM_logred, 		resM_datdic, 		resM_splunk) as resM  | fields concat(resD_logred, 		resD_datdic, 		resD_splunk) as resD  | fields concat(resH_logred, 		resH_datdic, 		resH_splunk) as resH  | fields concat(resMin_logred, 		resMin_datdic, 		resMin_splunk) as resMin  | fields concat(resSec_logred, 		resSec_datdic, 		resSec_splunk) as resSec  | fields concat(resMilliSec_logred, resMilliSec_datdic, resMilliSec_splunk) as resMilliSec | fields reqYear - 1970 as reqYearDiff, reqYear % 4 == 0 as reqIsLeapYear, reqM/1 as reqMonth, reqD/1 as reqDay, reqH/1 as reqHour, reqMin/1 as reqMinute, reqSec/1 as reqSecond, reqMilliSec/1 as reqMilliSecond | fields ((reqYearDiff * 365) + ((reqYear % 4 == 1) * 1) + floor(reqYearDiff / 4) + ((reqMonth == 2) * 31) + ((reqMonth == 3) * 59) + ((reqMonth == 4) * 90) + ((reqMonth == 5) * 120) + ((reqMonth == 6) * 151) + ((reqMonth == 7) * 181)+ ((reqMonth == 8) * 212)+ ((reqMonth == 9) * 243)+ ((reqMonth == 10) * 273)+ ((reqMonth == 11) * 304)+ ((reqMonth == 12) * 334)+ ((reqMonth > 2) and (reqIsLeapYear == 1))+ reqDay - 1) * 24 * 60 * 60 * 1000 + reqHour * 60 * 60 * 1000+ reqMinute * 60 * 1000+ reqSecond * 1000 + reqMilliSecond  as reqMilliSeconds | fields resYear - 1970 as resYearDiff, resYear % 4 == 0 as resIsLeapYear, resM/1 as resMonth, resD/1 as resDay, resH/1 as resHour, resMin/1 as resMinute, resSec/1 as resSecond, resMilliSec/1 as resMilliSecond | fields ((resYearDiff * 365) + ((resYear % 4 == 1) * 1) + floor(resYearDiff / 4) + ((resMonth == 2) * 31) + ((resMonth == 3) * 59) + ((resMonth == 4) * 90)+ ((resMonth == 5) * 120)+ ((resMonth == 6) * 151)+ ((resMonth == 7) * 181)+ ((resMonth == 8) * 212)+ ((resMonth == 9) * 243)+ ((resMonth == 10) * 273)+ ((resMonth == 11) * 304)+ ((resMonth == 12) * 334)+ ((resMonth > 2) and (resIsLeapYear == 1)) + resDay - 1) * 24 * 60 * 60 * 1000 + resHour * 60 * 60 * 1000 + resMinute * 60 * 1000 + resSecond * 1000 + resMilliSecond as resMilliSeconds,(resMilliSeconds-reqMilliSeconds)/1000 as Duration | fields concat(Status, statusCode) as txn_status | fields txn_status like /20/ as nonprov_success | fields concat(nonprov_success, bpromo_success, PDF_success) as success | fields (Duration > 20) as high_TAT | stats count(*) as TOTAL_TRANSACTION, sum(success) as TOTAL_SUCCESS, TOTAL_TRANSACTION-TOTAL_SUCCESS as TOTAL_FAILED, sum(high_TAT) as COUNT_HIGH_TAT, max(Duration) as MAX_TAT, avg(Duration) as AVG_TAT, max(TOTAL_TRANSACTION) as MAX_TPS, concat(substr((TOTAL_FAILED/TOTAL_TRANSACTION)*100, 0, 5), '"'"'%'"'"') as ERROR_RATE by API | filter API in ["BuyLoad","BuyPromoLambda-MultiplePurchasePromo","CreatePaymentSession", "CTL-CTB-MultiplePurchasePromo","EnrollAccount (broadband)","EnrollAccount (mobile)","GetAccountDetails","GetAccountStatus","GetBillingDetails","GetCustomerCampaignPromo","GetEnrolledAccount","GetLoyaltyRewards","GetLoyaltySubscribersCouponDetails","GetPlanDetails","GetRegisteredUser","GetRewardsPoints","GetPaymentReceipt","GetTransactionHistory","GetUsageConsumptionReports","RedeemLoyaltyRewards","RetrieveGroupService","RetrieveGroupUsage","SendOTP","VerifyOTP","InquirePrepaidBalance","PaymentService","PaymentSessionCallback","RequestPaymentRefund","GetBillingStatementsPDF"] | display API,TOTAL_TRANSACTION,GROWTH_FROM_PREV_HR,TOTAL_SUCCESS,TOTAL_FAILED,COUNT_HIGH_TAT,MAX_TAT,AVG_TAT,MAX_TPS,ERROR_RATE | sort API asc' | jq '.queryId' | awk -F '"' '{print $2}')

#Query Paybills
queryIdPaybills=$(aws logs start-query --log-group-names $lambdas --start-time "$startepoch"000 --end-time "$endepoch"000 --query-string 'filter @message like /ANALYTICS_KAFKA_LAMBDA_START/ or @message like /DATA_DICTIONARY/ | parse @message "\"request_timestamp*\":*\"*\\*\"" as rqtd1, rqtd2,  request_timestamp1, rqtd3 | parse @message "\"response_timestamp*\":*\"*\\*\"" as rstd1, rstd2, response_timestamp1, rstd3 | parse @message "\"response_timestamp*\":*\"*T*:*\"" as d1, d2, date, hour, d3 | parse @message "\"token_payment_id*\":*\"*\\*\"" as tpd1, tpd2, token_payment_id1, tpd3 | parse @message "\"channel*\":*\"*\\*\"" as chd1, chd2, channel1, chd3 | parse @message "\"event_name*\":*\"*\\*\"" as evd1, evd2, API1, evd3 | parse @message "\"request_type*\":*\"*\\*\"" as rqtyd1, rqtyd2, request_type_before, rqtyd3 | parse @message "\"payment_type*\":*\"*\\*\"" as pyd1, pyd2, payment_type_noncps, pyd3 | parse @message "\"transaction_status*\":*\"*\\*\"" as trd1, trd2, transaction_status1, trd3 | parse @message "\"mobile_number*\":*\"*\\*\"" as mobd1, mobd2, mobile_number, mobd3 | parse @message "settlement_details*\"status*\":*\"*\\*\"" as pystd1, pystd2, pystd3, payment_status1, pystd4 | parse @message "\"status_remarks*\":*\"*\\*\"" as sremd1, sremd2, status_remarks, sremd3 | parse information.body "\"notification\\\\\\\":{\\\\\\\"name\\\\\\\":\\\\\\\"*\\\\\\\"" as notification | fields replace(request_type_before, '"'"' '"'"', '"'"''"'"') as request_type | fields concat(token_payment_id1, token_payment_id2) as token_payment_id | fields concat(API1, API2) as API | fields concat(channel1, channel2) as channel | fields concat(request_timestamp1, request_timestamp2) as request_timestamp | fields concat(transaction_status1, transaction_status4) as transaction_status | fields concat(payment_status1, '"'"' '"'"',remarks, '"'"' '"'"', refund_status) as payment_status | fields concat(response_timestamp1, response_timestamp2) as response_timestamp | parse @message "\"provision_status*\":*\"*\\*\"" as prnmpd1, prnmpd2, provision_status_nonmpp, prdmp3 | fields concat(provision_status_mpp, provision_status_nonmpp, remarks4) as provision_status | parse @message "\"payment_method\\\\\\\\\\\\\\\":\\\\\\\\\\\\\\\"*\\\\\\\\\\\\\\\"" as payment_method_cps | fields concat(payment_method_cps, payment_type_noncps) as payment_method | fields substr(token_payment_id, 0, 3) as channel_before | fields replace(channel_before, "GLA", "superapp") as channel_before2 | fields replace(channel_before2, "GLE", "globeonline") as channels | parse @message "payment_session*\"created_date*\":*\"*-*-*T*:*:*.*\\*\"" as dum8, dum1, dum2, reqYear, reqM, reqD, reqH, reqMin, reqSec, reqMilliSec, dum3 | parse @message "\"response_timestamp*\":*\"*-*-*T*:*:*.*\\*\"" as dum4, dum5, resYear, resM, resD, resH, resMin, resSec, resMilliSec, dum6 | fields reqYear - 1970 as reqYearDiff, reqYear % 4 == 0 as reqIsLeapYear, reqM/1 as reqMonth, reqD/1 as reqDay, reqH/1 as reqHour, reqMin/1 as reqMinute, reqSec/1 as reqSecond, reqMilliSec/1 as reqMilliSecond | fields ((reqYearDiff * 365) + ((reqYear % 4 == 1) * 1) + floor(reqYearDiff / 4) + ((reqMonth == 2) * 31) + ((reqMonth == 3) * 59) + ((reqMonth == 4) * 90) + ((reqMonth == 5) * 120) + ((reqMonth == 6) * 151) + ((reqMonth == 7) * 181)+ ((reqMonth == 8) * 212)+ ((reqMonth == 9) * 243)+ ((reqMonth == 10) * 273)+ ((reqMonth == 11) * 304)+ ((reqMonth == 12) * 334)+ ((reqMonth > 2) and (reqIsLeapYear == 1))+ reqDay - 1) * 24 * 60 * 60 * 1000 + reqHour * 60 * 60 * 1000+ reqMinute * 60 * 1000+ reqSecond * 1000 + reqMilliSecond  as reqMilliSeconds | fields resYear - 1970 as resYearDiff, resYear % 4 == 0 as resIsLeapYear, resM/1 as resMonth, resD/1 as resDay, resH/1 as resHour, resMin/1 as resMinute, resSec/1 as resSecond, resMilliSec/1 as resMilliSecond
| fields ((resYearDiff * 365) + ((resYear % 4 == 1) * 1) + floor(resYearDiff / 4) + ((resMonth == 2) * 31) + ((resMonth == 3) * 59) + ((resMonth == 4) * 90)+ ((resMonth == 5) * 120)+ ((resMonth == 6) * 151)+ ((resMonth == 7) * 181)+ ((resMonth == 8) * 212)+ ((resMonth == 9) * 243)+ ((resMonth == 10) * 273)+ ((resMonth == 11) * 304)+ ((resMonth == 12) * 334)+ ((resMonth > 2) and (resIsLeapYear == 1)) + resDay - 1) * 24 * 60 * 60 * 1000 + resHour * 60 * 60 * 1000 + resMinute * 60 * 1000 + resSecond * 1000 + resMilliSecond as resMilliSeconds,(resMilliSeconds-reqMilliSeconds)/1000 as TAToverall | fields isempty(token_payment_id) as tpi_empty | filter tpi_empty = "0" | fields provision_status like /SUCCESS/ as nonbill_success | fields (request_type like /PayBills/ or request_type like /Pay Bills/ or request_type like /Non-bill/ or request_type like /ECPay/) and payment_status like /AUTHORISED/ as paybill_success | fields payment_status like /REFUSED/ as payment_failed | fields TAToverall > 120 as twominsTAT | fields API like /CreatePaymentSession/ as cps_count | filter (API like /CreatePaymentSession/ and request_type not like /BuyVoucher/) or (request_type like /BuyLoad/ and API like /BuyLoad/) or (request_type like /BuyPromo/ and API like /PurchasePromo/) or (API like /PaymentSessionCallback/ and notification like /PaymentProcessed/ and ((request_type like /PayBills/ or request_type like /Non-bill/ or request_type like /Pay Bills/) or (payment_status like /REFUSED/))) | fields concat( request_type, '"'"' ('"'"',payment_method, '"'"')'"'"') as request_method | stats sum(cps_count) as total_transaction, sum(nonbill_success+paybill_success) as total_success, (total_transaction-total_success) as total_failed, sum(payment_failed) as total_refused,sum(twominsTAT) as morethantwominsTAT, avg(TAToverall) as avg_TAT, max(TAToverall) as max_TAT, max(total_transaction) as max_TPS, concat(substr((total_failed/total_transaction)*100,0,5), '"'"'%'"'"') as fail_rate by request_method | display request_method,total_transaction,GROWTH_FROM_PREV_HR, total_success,total_failed,morethantwominsTAT,max_TAT,avg_TAT,max_TPS,fail_rate | filter total_transaction_cps != 0 and (total_success != 0 or total_failed != 0) | filter avg_TAT > 0 | sort request_method desc | limit 10000 | filter request_type like /Bills/' | jq -r '.queryId')


  if [ -f "$extractedfile" ]; then
			echo -e "\nExisting file found!, removing existing file..."
			rm $extractedfile || error_exit "Cannot delete the file. Please close the .csv file"
			echo "Remove done!"
			echo -e "\nCreating new file $extractedfile, please wait."
			echo "API,TOTAL_TRANSACTION,GROWTH_FROM_PREV_HR,TOTAL_SUCCESS,TOTAL_FAILED,COUNT_HIGH_TAT,MAX_TAT,AVG_TAT,MAX_TPS,ERROR_RATE" > $extractedfile || error_exit "Unable to create $extractedfile! Please close the .csv file"
			echo -e "File $extractedfile Successfully Created!\n"
			
        else
            echo "Creating $extractedfile..."
            echo "API,TOTAL_TRANSACTION,GROWTH_FROM_PREV_HR,TOTAL_SUCCESS,TOTAL_FAILED,COUNT_HIGH_TAT,MAX_TAT,AVG_TAT,MAX_TPS,ERROR_RATE" > $extractedfile || error_exit "Unable to create $extractedfile! Please close the .csv file"
            echo -e "File $extractedfile Successfully Created!\n"
    fi

while true; do
    results=$(aws logs get-query-results --query-id "$queryId" | jq .)
    status=$(jq -r .status <<< "$results")
    echo -ne "            [ AWS Query is $status ]. \r" 
	sleep 0.3
	echo -ne "            [ AWS Query is $status ].. \r"
    sleep 0.4
	
	if [ $status == "Complete" ]; then
	sleep 1
	break
	fi
done

results=$(aws logs get-query-results --query-id $queryId)
echo "$results" > tempextract.txt

extracttocsv=$(cat tempextract.txt | jq -r '.results[] | [map(.value)[0],map(.value)[1],"",map(.value)[2],map(.value)[3],map(.value)[4],map(.value)[5],map(.value)[6],map(.value)[7],map(.value)[8]] | @csv' >> "$extractedfile")
        echo -e $extracttocsv || error_exit "Failed to update $extractedfile data!"

resultsPaybills=$(aws logs get-query-results --query-id $queryIdPaybills)
echo "$resultsPaybills" > tempextract2.txt

extracttocsv2=$(cat tempextract2.txt | jq -r '.results[] | [map(.value)[0],map(.value)[1],"",map(.value)[2],map(.value)[3],map(.value)[4],map(.value)[5],map(.value)[6],map(.value)[7],map(.value)[8]] | @csv' >> "$extractedfile")
        echo -e $extracttocsv2 || error_exit "Failed to update $extractedfile data!"

        echo -e "Data has been extracted successfully! \nCompleted for timestamp: $inputstarttimedisplay to $inputendtimedisplay\n"

exit 1

else 
   error_exit "Encountered problem while extracting logs."
 



