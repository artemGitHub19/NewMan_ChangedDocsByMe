/*  
 * Modified by Artem 04.03.2021   
 */  


@IsTest
public with sharing class MattPipelineSummaryControllerTest {

	@testSetup 
	static void setup() {

		UserRole parentRole = new UserRole();
		parentRole.Name = 'Sales Manager Test2021';		
		insert parentRole;

		UserRole role = new UserRole();
		role.Name = 'US Sales Test2021';
		role.ParentRoleId = parentRole.Id;
		insert role;

		Profile p = [
			SELECT Id 
			FROM Profile 
			WHERE Name='System Administrator' 
			LIMIT 1
			];

		User u = new User();
		u.LocaleSidKey = 'en_US';
		u.TimeZoneSidKey = 'GMT';		
		u.LanguageLocaleKey = 'en_US';
		u.EmailEncodingKey = 'UTF-8';
		u.LastName = 'Test'; 
		u.Email = 'test@gmail.com1';
		u.Alias = 'Tcode';
		u.Username = 'testUserName@gmail.com1';
		u.ProfileID = p.Id;	
		u.UserRoleId = role.Id;
		insert u;

		User u2 = new User(); // MANAGER
		u2.LocaleSidKey = 'en_US';
		u2.TimeZoneSidKey = 'GMT';		
		u2.LanguageLocaleKey = 'en_US';
		u2.EmailEncodingKey = 'UTF-8';
		u2.LastName = 'Test2'; 
		u2.Email = 'test2@gmail.com1';
		u2.Alias = 'Tcode2';
		u2.Username = 'test2UserName@gmail.com1';
		u2.ProfileID = p.Id;	
		u2.UserRoleId = parentRole.Id;
		insert u2;
        
        User u3 = new User();
		u3.LocaleSidKey = 'en_US';
		u3.TimeZoneSidKey = 'GMT';		
		u3.LanguageLocaleKey = 'en_US';
		u3.EmailEncodingKey = 'UTF-8';
		u3.LastName = 'Test3'; 
		u3.Email = 'test3@gmail.com1';
		u3.Alias = 'Tcode3';
		u3.Username = 'test3UserName@gmail.com1';
		u3.ProfileID = p.Id;	
		u3.UserRoleId = role.Id;
		insert u3;
    }	

	@IsTest
	private static void testgetReport_oneUser() {

		User u = [
			SELECT Id 
			FROM User
			WHERE Username = 'testUserName@gmail.com1' 
		];
        
        User u3 = [
			SELECT Id 
			FROM User
			WHERE Username = 'test3UserName@gmail.com1' 
		];

		Date todayDate = Date.newInstance(2021, 1, 15); 
		System.debug('todayDate =' + todayDate);	      
        Date todayDatePlus3Months = todayDate.addMonths(3);
        
        Integer year;
        Integer month;
        Integer day;
        
        month = todayDatePlus3Months.month();
        day = todayDatePlus3Months.day();
        year = todayDatePlus3Months.year();      

		RecordType rType = [
			SELECT Name
			FROM RecordType
			WHERE Name = 'Client'
			AND SobjectType = 'Opportunity'
			AND isActive = true
		];	
        
        RecordType rType2 = [
			SELECT Name
			FROM RecordType
			WHERE Name = 'Client - Upsell'
			AND SobjectType = 'Opportunity'
			AND isActive = true
		];	

		List<Opportunity> opportunities = new List<Opportunity>();

		System.debug('CloseDate = Date.newInstance(year, month, day) = ' + Date.newInstance(year, month, day));	
		
		Opportunity opportunity1 = new Opportunity(
			CloseDate = Date.newInstance(year, month, day),
			Name = 'Test1',
			RecordTypeId = rType2.Id,
			StageName = '4-Validate',
			OwnerId = u.Id,
			Segment__c = 'Agile Enterprise'
		);		
		opportunities.add(opportunity1);

		Opportunity opportunity2 = new Opportunity(
			CloseDate = Date.newInstance(year, month + 1, day),
			Name = 'Test2',
			RecordTypeId = rType.Id,
			StageName = '4-Validate',
			OwnerId = u.Id,
			Segment__c = 'Enterprise'
		);	
		opportunities.add(opportunity2);
        
        Opportunity opportunity3= new Opportunity(
			CloseDate = Date.newInstance(year, month + 2, day),
			Name = 'Test3',
			RecordTypeId = rType.Id,
			StageName = '1-Discovery and Education',
			OwnerId = u.Id,
			Segment__c = 'Enterprise'
		);
	
		opportunities.add(opportunity3);
        
         Opportunity opportunity4= new Opportunity(
			CloseDate = Date.newInstance(year, month + 2, day),
			Name = 'Test4',
			RecordTypeId = rType.Id,
			StageName = '0-SAL',
			OwnerId = u.Id,
			Segment__c = 'Enterprise'
		);
		
		opportunities.add(opportunity4);
        
         Opportunity opportunity5 = new Opportunity(
			CloseDate = Date.newInstance(year, month + 2, day),
			Name = 'Test5',
			RecordTypeId = rType.Id,
			StageName = '0-SAL',
			OwnerId = u.Id,
			Segment__c = 'Enterprise',
            CS_Involved__c = u3.Id
		);
		
		opportunities.add(opportunity5);
        
         Opportunity opportunity6 = new Opportunity(
			CloseDate = Date.newInstance(year, month + 2, day),
			Name = 'Test6',
			RecordTypeId = rType.Id,
			StageName = '0-SAL',
			OwnerId = u.Id,
			Segment__c = 'Enterprise',
            CS_Involved__c = u3.Id
		);
		
		opportunities.add(opportunity6);

		insert opportunities;

		Id pricebookId = Test.getStandardPricebookId();

		System.debug('pricebookId = ' + pricebookId);
		
		Product2 prod = new Product2(
			Name = 'Product X',
			ProductCode = 'Pro-X',
			isActive = true
		);
		insert prod;
	
		PricebookEntry pbEntry = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = prod.Id,
			UnitPrice = 100.00,
			IsActive = true
		);
		insert pbEntry;
	
		OpportunityLineItem oli = new OpportunityLineItem(
			OpportunityId = opportunity1.Id,
			Quantity = 5,
            Fee_Type__c = 'Recurring',
			PricebookEntryId = pbEntry.Id,		
			TotalPrice = 500.00
		);
		insert oli;
        
        OpportunityLineItem oli2 = new OpportunityLineItem(
			OpportunityId = opportunity5.Id,
			Quantity = 5,
            Fee_Type__c = 'Recurring',
			PricebookEntryId = pbEntry.Id,		
			TotalPrice = 500.00
		);
		insert oli2;
        
        opportunity5.StageName = '2-Champion Building';
        update opportunity5;	
        
         OpportunityLineItem oli3 = new OpportunityLineItem(
			OpportunityId = opportunity6.Id,
			Quantity = 5,
            Fee_Type__c = 'Recurring',
			PricebookEntryId = pbEntry.Id,		
			TotalPrice = 500.00
		);
		insert oli3;
        
        opportunity6.StageName = '3-Competitive';      
        opportunity6.Customer_Type__c = 'Welcome';
        opportunity6.Competitor__c = 'Other';
        opportunity6.CMP__c = 'IME';
        update opportunity6;	

		Map<String, Map<String, Object>> report = MattPipelineSummaryController.getReport(u.Id, todayDate);

		System.assertEquals('Test', report.get(u.Id).get('name'));
		System.assertEquals('US Sales Test2021', report.get(u.Id).get('roleName'));
		System.assertEquals(1, report.get(u.Id).get('newLogoCommit'));
		System.assertEquals('April', report.get(u.Id).get('firstMonthName'));
		System.assertEquals('May', report.get(u.Id).get('secondMonthName'));
		System.assertEquals('June', report.get(u.Id).get('thirdMonthName'));
        
        System.assertEquals(0, report.get(u.Id).get('firstMonth'));
        System.assertEquals(0, report.get(u.Id).get('secondMonth'));
        System.assertEquals(1000, report.get(u.Id).get('thirdMonth'));        
		System.assertEquals('25% vs 75%', report.get(u.Id).get('agileVEnterprise'));
        System.assertEquals('75% vs 25%', report.get(u.Id).get('newVExpansion'));
        System.assertEquals(500, report.get(u.Id).get('bookingCommit'));
        
        System.assertEquals(1, report.get(u.Id).get('ofStage0'));
        System.assertEquals(1, report.get(u.Id).get('ofStage1'));
        System.assertEquals(500, report.get(u.Id).get('totalStage2Plus'));
        System.assertEquals(500, report.get(u.Id).get('midStagePipeline3'));
        System.assertEquals(500, report.get(u.Id).get('lateStagePipeline4And5'));         
	}

	@IsTest
	private static void testgetReport_userWithReportedOne() {

		User u = [
			SELECT Id 
			FROM User
			WHERE Username = 'test2UserName@gmail.com1' 
		];

		User reportedUser = [
			SELECT Id 
			FROM User
			WHERE Username = 'testUserName@gmail.com1' 
		];		

		Date todayDate = Date.newInstance(2021, 4, 1); 
        Date todayDatePlus3Months = todayDate.addMonths(3);
        
        Integer year;
        Integer month;
        Integer day;
        
        month = todayDatePlus3Months.month();
        day = todayDatePlus3Months.day();
        year = todayDatePlus3Months.year();      

		RecordType rType = [
			SELECT Name
			FROM RecordType
			WHERE Name = 'Client'
			AND SobjectType = 'Opportunity'
			AND isActive = true
		];		

		List<Opportunity> opportunities = new List<Opportunity>();

		Opportunity opportunity1 = new Opportunity(
			CloseDate = Date.newInstance(year, month, day),
			Name = 'Test1',
			RecordTypeId = rType.Id,
			StageName = '4-Validate',
			OwnerId = u.Id,
			Segment__c = 'Agile Enterprise'
		);
		opportunities.add(opportunity1);

		insert opportunities;
		
		Map<String, Map<String, Object>> report = MattPipelineSummaryController.getReport(u.Id, todayDate);

		System.assertEquals('Test2', report.get(u.Id).get('name'));
		System.assertEquals('Sales Manager Test2021', report.get(u.Id).get('roleName'));
		System.assertEquals(1, report.get(u.Id).get('newLogoCommit'));

		System.assertEquals('Test', report.get(reportedUser.Id).get('name'));
		System.assertEquals('US Sales Test2021', report.get(reportedUser.Id).get('roleName'));

	}

	@IsTest
	private static void testgetReport_noOpportunities() {

		User u = [
			SELECT Id 
			FROM User
			WHERE Username = 'testUserName@gmail.com1' 
		];

		Date todayDate = Date.newInstance(2021, 7, 1);		    

		Map<String, Map<String, Object>> report = MattPipelineSummaryController.getReport(u.Id, todayDate);

		System.assertEquals('Test', report.get(u.Id).get('name'));
		System.assertEquals('US Sales Test2021', report.get(u.Id).get('roleName'));
		System.assertEquals(0, report.get(u.Id).get('newLogoCommit'));	

	}

	@IsTest
	private static void testgetReport_noUsers() {

		User u = new User();

		Date todayDate = Date.newInstance(2021, 4, 1);  
		
		Map<String, Map<String, Object>> report = MattPipelineSummaryController.getReport(u.Id, todayDate);

		System.assertEquals(new Map<String, Map<String, Object>>(), report);

	}

	@IsTest
	private static void testgetReport_oneUser_fourthFQ() {

		User u = [
			SELECT Id 
			FROM User
			WHERE Username = 'testUserName@gmail.com1' 
		];

		Date todayDate = Date.newInstance(2021, 10, 1);       
        Date todayDatePlus3Months = todayDate.addMonths(3);    
        
        Integer year;
        Integer month;
        Integer day;
        
        month = todayDatePlus3Months.month();
        day = todayDatePlus3Months.day();
        year = todayDatePlus3Months.year();       

		RecordType rType = [
			SELECT Name
			FROM RecordType
			WHERE Name = 'Client'
			AND SobjectType = 'Opportunity'
			AND isActive = true
		];		

		List<Opportunity> opportunities = new List<Opportunity>();

		Opportunity opportunity1 = new Opportunity(
			CloseDate = Date.newInstance(year, month, day),
			Name = 'Test1',
			RecordTypeId = rType.Id,
			StageName = '4-Validate',
			OwnerId = u.Id,
			Segment__c = 'Agile Enterprise'
		);
		opportunities.add(opportunity1);

		insert opportunities;		

		Map<String, Map<String, Object>> report = MattPipelineSummaryController.getReport(u.Id, todayDate);

		System.assertEquals('Test', report.get(u.Id).get('name'));
		System.assertEquals('US Sales Test2021', report.get(u.Id).get('roleName'));
		System.assertEquals(1, report.get(u.Id).get('newLogoCommit'));
		System.assertEquals('January', report.get(u.Id).get('firstMonthName'));
		
	}
}