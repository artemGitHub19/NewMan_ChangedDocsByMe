/*  
 * Modified by Artem 02.03.2021   
 */  

public with sharing class MattPipelineSummaryController {
    
    @AuraEnabled
    public static Map<String, Map<String, Object>> getReport(Id userId, Date currentDate) { 
        
        if (userId == null)
            return new Map<String, Map<String, Object>>();  
        
        User currentUser = [
            SELECT Name, UserRole.Name, UserRoleId
            FROM User
            WHERE Id =:userId            
        ];      
        
        List<UserRole> childUserRoles = new List<UserRole>();
        
        if(currentUser.UserRoleId != null){
            childUserRoles = [
                SELECT Name, ParentRoleId
                FROM UserRole
                WHERE ParentRoleId =:currentUser.UserRoleId 
            ];
        }        
        
        List<Id> childUserRoleIds = new List<Id>();
        if(childUserRoles.size() != 0){
            for(UserRole childUserRole : childUserRoles){
                childUserRoleIds.add(childUserRole.Id);
            }
        }
        
        List<User> reportedUsers = new List<User>();
        if(childUserRoleIds.size() != 0){
            reportedUsers = [
                SELECT Name, UserRole.Name, UserRoleId
                FROM User
                WHERE UserRoleId IN :childUserRoleIds
                AND IsActive = true
            ];
        }        
        
        Date nextFiscalQuarterStartDate;
        Date nextFiscalQuarterEndDate;
        
        Date currentFiscalYearStartDate;
        Date currentFiscalYearEndDate;
        
        Integer numberOfFiscalQuarter;
        
        Map<Integer, String> mapOfMonthNameByMonthNumber = new Map<Integer, String>();        
        mapOfMonthNameByMonthNumber.put(1, 'January');
        mapOfMonthNameByMonthNumber.put(2, 'February');
        mapOfMonthNameByMonthNumber.put(3, 'March');
        mapOfMonthNameByMonthNumber.put(4, 'April');
        mapOfMonthNameByMonthNumber.put(5, 'May');
        mapOfMonthNameByMonthNumber.put(6, 'June');
        mapOfMonthNameByMonthNumber.put(7, 'July');
        mapOfMonthNameByMonthNumber.put(8, 'August');
        mapOfMonthNameByMonthNumber.put(9, 'September');
        mapOfMonthNameByMonthNumber.put(10, 'October');
        mapOfMonthNameByMonthNumber.put(11, 'November');
        mapOfMonthNameByMonthNumber.put(12, 'December');    
        
        Map<String,Date> monthOfFiscalQuarterDate = new Map<String,Date>();
        
        Date todayDate = currentDate;
        currentFiscalYearStartDate = Date.newinstance(todayDate.year(), 1, 1);
        currentFiscalYearEndDate = Date.newinstance(todayDate.year(), 12, 31);
      
        Date periodStartDate = currentFiscalYearStartDate;
        Date periodEndDate;
        if(todayDate.month() < 10){
            periodEndDate = currentFiscalYearEndDate;
        } else {
            periodEndDate = Date.newInstance(todayDate.year() + 1, 3, 31);
        }        
        
        Integer currentMonth = todayDate.month();
        
        if(currentMonth >= 1 && currentMonth <= 3){
            numberOfFiscalQuarter = 2;
            nextFiscalQuarterStartDate =  Date.newinstance(todayDate.year(), 4, 1);
            nextFiscalQuarterEndDate = Date.newinstance(todayDate.year(), 6, 30);
            
            Integer firstMonth = 4;
            monthOfFiscalQuarterDate = setMonthsInFiscalQuarter(firstMonth, currentMonth, currentDate);            
            
        } else if(currentMonth >= 4 && currentMonth <= 6){
            numberOfFiscalQuarter = 3;
            nextFiscalQuarterStartDate =  Date.newinstance(todayDate.year(), 7, 1);
            nextFiscalQuarterEndDate = Date.newinstance(todayDate.year(), 9, 30);
            
            Integer firstMonth = 7;
            monthOfFiscalQuarterDate = setMonthsInFiscalQuarter(firstMonth, currentMonth, currentDate); 
            
        } else if(currentMonth >= 7 && currentMonth <= 9){
            numberOfFiscalQuarter = 4;
            nextFiscalQuarterStartDate =  Date.newinstance(todayDate.year(), 10, 1);
            nextFiscalQuarterEndDate = Date.newinstance(todayDate.year(), 12, 31);
            
            Integer firstMonth = 10;
            monthOfFiscalQuarterDate = setMonthsInFiscalQuarter(firstMonth, currentMonth, currentDate);  
            
        } else if(currentMonth >= 10 && currentMonth <= 12){
            numberOfFiscalQuarter = 1;
            nextFiscalQuarterStartDate =  Date.newinstance(todayDate.year() + 1, 1, 1);
            nextFiscalQuarterEndDate = Date.newinstance(todayDate.year() + 1, 3, 31);
            
            Integer firstMonth = 1;
            monthOfFiscalQuarterDate = setMonthsInFiscalQuarter(firstMonth, currentMonth, currentDate);             
        }         
        
        Map<String, Object> nameInformation = new Map<String, Object>();
        
        Map<String, Map<String, Object>> result = new Map<String, Map<String, Object>>();
        
        List<User> allUsers = new List<User>();
        
        allUsers.add(currentUser);
        
        if(reportedUsers.size() != 0){            
            allUsers.addAll(reportedUsers);            
        }
        
        List<Id> allUsersIds = new List<Id>();
        for(User us: allUsers){
            allUsersIds.add(us.Id);
        }       
        
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for(List<Opportunity> opp : [SELECT Id, ARR_Total_NEW__c, OwnerId, StageName, RecordType.Name, CloseDate, Segment__c FROM Opportunity
                                     WHERE OwnerId IN :allUsersIds
                                     AND (
                                         RecordType.Name = 'Client - Upsell'
                                         OR RecordType.Name = 'Client'
                                     )
                                     AND CloseDate >= :periodStartDate
                                     AND CloseDate <= :periodEndDate]){
                    
            opportunities.addAll(opp);
            
        }
        
        Double sumArrTotalNewBookingCommit = 0;
        Double sumArrTotalNewBookingBestCase = 0;
        Integer countNewLogoCommit = 0;
        Integer countNewLogoBestCase = 0;
        Double sumArrTotalNewFirstMonth = 0;
        Double sumArrTotalNewSecondMonth = 0;
        Double sumArrTotalNewThirdMonth = 0;
        Integer countOfStage0 = 0;
        Integer countOfStage1 = 0;
        Double sumArrTotalNewTotalStage2Plus = 0;
        Double sumArrTotalNewMidStagePipeline3 = 0;
        Double sumArrTotalNewLateStagePipeline4And5 = 0;
        Integer countAgileOpportunities = 0;
        Integer countAgileAndEnterpriseOpportunities= 0;
        Integer percentOfAgileOpportunities = 0;
        Integer percentOfNewOpportunities = 0;
        Integer countNewOpportunities = 0;
        Integer countNewAndExpansionOpportunities = 0;
        
        //System.debug('allUsers = ' + allUsers.size());
       
        if(opportunities.size() != 0){
            //System.debug('allUsers = ' + allUsers.size());
            
            for(User us: allUsers){
                sumArrTotalNewBookingCommit = 0;
                sumArrTotalNewBookingBestCase = 0;
                countNewLogoCommit = 0;
                countNewLogoBestCase = 0;
                sumArrTotalNewFirstMonth = 0;
                sumArrTotalNewSecondMonth = 0;
                sumArrTotalNewThirdMonth = 0;
                countOfStage0 = 0;
                countOfStage1 = 0;
                sumArrTotalNewTotalStage2Plus = 0;
                sumArrTotalNewMidStagePipeline3 = 0;
                sumArrTotalNewLateStagePipeline4And5 = 0;
                countAgileOpportunities = 0;
                countAgileAndEnterpriseOpportunities= 0;
                percentOfAgileOpportunities = 0;
                percentOfNewOpportunities = 0;
                countNewOpportunities = 0;
                countNewAndExpansionOpportunities = 0;
                
                nameInformation = new Map<String, Object>();
                nameInformation.put('name', us.Name);
                nameInformation.put('roleName', us.UserRole.Name);
                
                for(Opportunity opp : opportunities){
                    if(us.Id == opp.OwnerId){
                        System.debug( 'nextFiscalQuarterStartDate = ' + nextFiscalQuarterStartDate);
                        if((opp.StageName == '4-Validate' || opp.StageName == '5-Contract') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= nextFiscalQuarterStartDate) && 
                           (opp.CloseDate <= nextFiscalQuarterEndDate)){
                            System.debug( 'opp.ARR_Total_NEW__c = ' + opp.ARR_Total_NEW__c);
                               sumArrTotalNewBookingCommit += opp.ARR_Total_NEW__c;
                           } 
                        
                        if((opp.StageName == '3-Competitive') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= nextFiscalQuarterStartDate) && 
                           (opp.CloseDate <= nextFiscalQuarterEndDate)){
                               
                               sumArrTotalNewBookingBestCase += opp.ARR_Total_NEW__c;
                           }   
                        
                        if((opp.StageName == '4-Validate' || opp.StageName == '5-Contract') &&
                           (opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= nextFiscalQuarterStartDate) && 
                           (opp.CloseDate <= nextFiscalQuarterEndDate)){
                               
                               ++countNewLogoCommit;
                           }   
                        
                        if((opp.StageName == '3-Competitive') &&
                           (opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= nextFiscalQuarterStartDate) && 
                           (opp.CloseDate <= nextFiscalQuarterEndDate)){
                               
                               ++countNewLogoBestCase;
                           }  
                        
                        if((opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= monthOfFiscalQuarterDate.get('firstMonthStartDate')) && 
                           (opp.CloseDate <= monthOfFiscalQuarterDate.get('firstMonthEndDate'))){
                               
                               sumArrTotalNewFirstMonth += opp.ARR_Total_NEW__c;
                           }  
                        
                        if((opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= monthOfFiscalQuarterDate.get('secondMonthStartDate')) && 
                           (opp.CloseDate <= monthOfFiscalQuarterDate.get('secondMonthEndDate'))){
                               
                               sumArrTotalNewSecondMonth += opp.ARR_Total_NEW__c;
                           }  
                        
                        if((opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= monthOfFiscalQuarterDate.get('thirdMonthStartDate')) && 
                           (opp.CloseDate <= monthOfFiscalQuarterDate.get('thirdMonthEndDate'))){
                               
                               sumArrTotalNewThirdMonth += opp.ARR_Total_NEW__c;
                           }  
                        
                        if((opp.StageName == '0-SAL') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate)){
                               
                               ++countOfStage0;
                           }
                        
                        if((opp.StageName == '1-Discovery and Education') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate)){
                               
                               ++countOfStage1;                                
                           }
                        
                        if((opp.StageName == '2-Champion Building') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate)){
                               
                               sumArrTotalNewTotalStage2Plus += opp.ARR_Total_NEW__c;
                           }
                        
                        if((opp.StageName == '3-Competitive') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate)){
                               
                               sumArrTotalNewMidStagePipeline3 += opp.ARR_Total_NEW__c;
                           }
                        
                        if((opp.StageName == '4-Validate' || opp.StageName == '5-Contract') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate)){
                               
                               sumArrTotalNewLateStagePipeline4And5 += opp.ARR_Total_NEW__c;
                           }
                        
                        if((opp.StageName == '2-Champion Building' || opp.StageName == '3-Competitive' ||
                            opp.StageName == '4-Validate' || opp.StageName == '5-Contract') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate) &&
                           opp.Segment__c == 'Agile Enterprise'){
                               
                               ++countAgileOpportunities;
                           }
                        
                        if((opp.StageName == '2-Champion Building' || opp.StageName == '3-Competitive' ||
                            opp.StageName == '4-Validate' || opp.StageName == '5-Contract') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate) &&
                           (opp.Segment__c == 'Agile Enterprise' || opp.Segment__c == 'Enterprise')){
                               
                               ++countAgileAndEnterpriseOpportunities;
                           }
                        
                        if((opp.StageName == '2-Champion Building' || opp.StageName == '3-Competitive' ||
                            opp.StageName == '4-Validate' || opp.StageName == '5-Contract') &&
                           (opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate) ){
                               
                               ++countNewOpportunities;
                           }
                        
                        if((opp.StageName == '2-Champion Building' || opp.StageName == '3-Competitive' ||
                            opp.StageName == '4-Validate' || opp.StageName == '5-Contract') &&
                           (opp.RecordType.Name == 'Client - Upsell' || opp.RecordType.Name == 'Client') &&
                           (opp.CloseDate >= currentFiscalYearStartDate) && 
                           (opp.CloseDate <= currentFiscalYearEndDate) ){
                               
                               ++countNewAndExpansionOpportunities;
                           }
                    }                    
                }   
                
                nameInformation.put('bookingCommit', sumArrTotalNewBookingCommit);
                nameInformation.put('bookingBestCase', sumArrTotalNewBookingBestCase);
                nameInformation.put('newLogoCommit', countNewLogoCommit);
                nameInformation.put('newLogoBestCase', countNewLogoBestCase);
                nameInformation.put('firstMonth', sumArrTotalNewFirstMonth);
                nameInformation.put('secondMonth', sumArrTotalNewSecondMonth);
                nameInformation.put('thirdMonth', sumArrTotalNewThirdMonth);
                nameInformation.put('ofStage0', countOfStage0);
                nameInformation.put('ofStage1', countOfStage1);
                nameInformation.put('totalStage2Plus', sumArrTotalNewTotalStage2Plus);
                nameInformation.put('midStagePipeline3', sumArrTotalNewMidStagePipeline3);
                nameInformation.put('lateStagePipeline4And5', sumArrTotalNewLateStagePipeline4And5);
                
                if(countAgileAndEnterpriseOpportunities != 0){
                    
                    percentOfAgileOpportunities = (100 * countAgileOpportunities) / countAgileAndEnterpriseOpportunities;                    
                    nameInformation.put('agileVEnterprise', '' + percentOfAgileOpportunities + '% vs ' +
                                        (100 - percentOfAgileOpportunities) + '%');  
                    
                } else {                    
                    
                    nameInformation.put('agileVEnterprise', '' + percentOfAgileOpportunities + '% vs ' + 0 + '%');
                }                  
                
                if(countNewAndExpansionOpportunities != 0){
                    percentOfNewOpportunities = (100 * countNewOpportunities) / countNewAndExpansionOpportunities;
                    nameInformation.put('newVExpansion', '' + percentOfNewOpportunities + '% vs ' +
                                        (100 - percentOfNewOpportunities) + '%');            
                } else {                    
                    nameInformation.put('newVExpansion', '' + percentOfNewOpportunities + '% vs ' + 0 + '%');
                } 
                
                System.debug('us.Id = ' + us.Id);
                result.put(us.Id, nameInformation);
                
            }
            
        } else {
            
            for(User us: allUsers){
                
                nameInformation = new Map<String, Object>();
                
                nameInformation.put('name', us.Name);
                nameInformation.put('roleName', us.UserRole.Name);               
                nameInformation.put('bookingCommit', sumArrTotalNewBookingCommit);
                nameInformation.put('bookingBestCase', sumArrTotalNewBookingBestCase);
                nameInformation.put('newLogoCommit', countNewLogoCommit);
                nameInformation.put('newLogoBestCase', countNewLogoBestCase);
                nameInformation.put('firstMonth', sumArrTotalNewFirstMonth);
                nameInformation.put('secondMonth', sumArrTotalNewSecondMonth);
                nameInformation.put('thirdMonth', sumArrTotalNewThirdMonth);
                nameInformation.put('ofStage0', countOfStage0);
                nameInformation.put('ofStage1', countOfStage1);
                nameInformation.put('totalStage2Plus', sumArrTotalNewTotalStage2Plus);
                nameInformation.put('midStagePipeline3', sumArrTotalNewMidStagePipeline3);
                nameInformation.put('lateStagePipeline4And5', sumArrTotalNewLateStagePipeline4And5);
                nameInformation.put('agileVEnterprise', '0% vs 0%');  
                nameInformation.put('newVExpansion', '0% vs 0%');
                
                //System.debug('us.Id = ' + us.Id);
                result.put(us.Id, nameInformation);
            }            
        }        
        
        for(User us: allUsers){
            userId = us.Id;
            if(numberOfFiscalQuarter == 1){
                Integer monthNumber = 1;                
                result.get(userId).put('firstMonthName', mapOfMonthNameByMonthNumber.get(monthNumber));   
                ++monthNumber;
                result.get(userId).put('secondMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
                ++monthNumber;
                result.get(userId).put('thirdMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
            } else if(numberOfFiscalQuarter == 2){
                Integer monthNumber = 4;
                result.get(userId).put('firstMonthName', mapOfMonthNameByMonthNumber.get(monthNumber));   
                ++monthNumber;
                result.get(userId).put('secondMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
                ++monthNumber;
                result.get(userId).put('thirdMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
            } else if(numberOfFiscalQuarter == 3){
                Integer monthNumber = 7;               
                result.get(userId).put('firstMonthName', mapOfMonthNameByMonthNumber.get(monthNumber));   
                ++monthNumber;
                result.get(userId).put('secondMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
                ++monthNumber;
                result.get(userId).put('thirdMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
            } else if(numberOfFiscalQuarter == 4){
                Integer monthNumber = 10;
                result.get(userId).put('firstMonthName', mapOfMonthNameByMonthNumber.get(monthNumber));   
                ++monthNumber;
                result.get(userId).put('secondMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
                ++monthNumber;
                result.get(userId).put('thirdMonthName', mapOfMonthNameByMonthNumber.get(monthNumber)); 
            }       
        }  
        
        return result;
    }
    
    public static Map<String,Date> setMonthsInFiscalQuarter(Integer firstMonth, Integer currentMonth, Date currentDate){
        
        Map<String,Date> monthOfFiscalQuarterDate = new Map<String,Date>();
        
        Integer month = firstMonth;
        
        Date todayDate = currentDate;  
        Integer year = todayDate.year();
        
        if(currentMonth >= 10 && currentMonth <= 12){ 
            ++year;                         
        } 
        monthOfFiscalQuarterDate.put('firstMonthStartDate', Date.newinstance(year, month, 1));
        monthOfFiscalQuarterDate.put('firstMonthEndDate', Date.newinstance(year, month, Date.daysInMonth(year, month)));
        
        ++month;
        monthOfFiscalQuarterDate.put('secondMonthStartDate', Date.newinstance(year, month, 1));
        monthOfFiscalQuarterDate.put('secondMonthEndDate', Date.newinstance(year, month, Date.daysInMonth(year, month)));
        
        ++month;
        monthOfFiscalQuarterDate.put('thirdMonthStartDate', Date.newinstance(year, month, 1));
        monthOfFiscalQuarterDate.put('thirdMonthEndDate', Date.newinstance(year, month, Date.daysInMonth(year, month)));
        
        return monthOfFiscalQuarterDate;
    } 
}




/*           old version

public with sharing class MattPipelineSummaryController {

	@AuraEnabled
	public static Map<String, Object> getReport(Id userId) {
		Date fodecastDate = Date.today().addDays(-60);

		if (userId == null)
			return new Map<String, Object>();

		Map<String, Object> result = new Map<String, Object> {
			'totalTargetAccounts' => Math.max([
				SELECT Id
				FROM Account
				WHERE OwnerId = :userId
                AND Sales_Priority__c = true
			].size(), 0),
			'stage1Opps' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
				AND StageName = '1-Discovery and Education'
				AND CloseDate >= :fodecastDate
			],
			'stagesARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
				AND CloseDate >= :fodecastDate
			][0].get('expr0'),
			'earlyStageARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND StageName = '2-Champion Building'
				AND CloseDate >= :fodecastDate
			][0].get('expr0'),
			'lateStageARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND (
					StageName = '5-Contract'
					OR StageName = '4-Validate'
				)
				AND CloseDate >= :fodecastDate
			][0].get('expr0'),
			'newLogoCount' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
				AND RecordType.Name = 'Client'
				AND CloseDate >= :fodecastDate
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
			],
			'newLogoARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND RecordType.Name = 'Client'
				AND CloseDate >= :fodecastDate
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
			][0].get('expr0'),
			'upsellCount' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
				AND RecordType.Name = 'Client - Upsell'
				AND CloseDate >= :fodecastDate
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
			],
			'upsellARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND RecordType.Name = 'Client - Upsell'
				AND CloseDate >= :fodecastDate
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
			][0].get('expr0'),
			'imePipelineARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND CMP__c = 'IME'
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			][0].get('expr0'),
			'programPipelineARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND CMP__c = 'CM - Program'
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			][0].get('expr0'),
			'contentPipelineARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
				AND CMP__c = 'Content'
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			][0].get('expr0'),
			'imePipeline' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
				AND CMP__c = 'IME'
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			],
			'programPipeline' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
				AND CMP__c = 'CM - Program'
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			],
			'contentPipeline' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
				AND CMP__c = 'Content'
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			],
            'forecastBestCase' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			],
            'forecastBestCaseARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			][0].get('expr0'),
            'forecastCommit' => [
				SELECT COUNT()
				FROM Opportunity
				WHERE OwnerId = :userId
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			],
            'forecastCommitARR' => [
				SELECT SUM(ARR_Total_NEW__c)
				FROM Opportunity
				WHERE OwnerId = :userId
                AND (
					StageName = '2-Champion Building'
					OR StageName = '3-Competitive'
					OR StageName = '4-Validate'
					OR StageName = '5-Contract'
				)
                AND (
                    RecordType.Name = 'Client - Upsell'
                    OR RecordType.Name = 'Client'
                )
				AND CloseDate >= :fodecastDate
			][0].get('expr0')
		};

		result.put('middleStageARR', [
			SELECT SUM(ARR_Total_NEW__c)
			FROM Opportunity
			WHERE OwnerId = :userId
			AND StageName = '3-Competitive'
		][0].get('expr0'));

		for (String key : result.keySet()) {
			if (result.get(key) == null)
				result.put(key, 0);
		}

		return result;
	}

}

*/