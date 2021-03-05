/**
* Created by wildrey on 24.03.2020.
*/

@IsTest
private class LeadTriggerHandlerTest {
    @IsTest
    static void updateLeadProcessBuilderTest() {
        Account acc = new Account(
            Name = 'Test Account',
            BDR_Owner__c = UserInfo.getUserId(),
            Software_Score__c = 5
        );
        insert acc;
        
        Lead newLead = new Lead(
            FirstName = 'Test',
            LastName = 'Test',
            Account__c = acc.Id,
            Company = 'Test',
            LeanData__Routing_Status__c = 'routed - round-robin',
            LD_Matched_Account_Name__c = acc.Id,
            LD_BDR_Owner__c = UserInfo.getUserId()
            
        );
        insert newLead;
        
        Lead newLead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Test',
            Account__c = acc.Id,
            Company = 'Test',
            engagio__Matched_Account__c = acc.Id
            
        );
        insert newLead2;
        
        update newLead2;
    }
    
    @isTest
    static void setFirstPrimaryContactOnOpportunityTest(){  // created 03.03.2021 (Artem)
        
        Lead newLead = new Lead();        
        newLead.Company = 'CompanyName';
        newLead.Website = 'http://website.com';
        newLead.FirstName = 'James';
        newLead.LastName = 'Lee'; 
        newLead.Email = 'test@gmail.com';
        newLead.Country = 'Country'; 
        newLead.State = 'State';
        newLead.PostalCode = 'PostalCode';
        newLead.City = 'City';
        newLead.Street = 'Street';
        
        insert newLead;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(newLead.id);       
        
        test.startTest();
        
        LeadStatus convertStatus = [
            Select Id, MasterLabel 
            FROM LeadStatus 
            WHERE IsConverted = true 
            LIMIT 1
        ];
        
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        test.stopTest();      
        
        List<Account> convertedAccounts = [
            SELECT Id  
            FROM Account
        ];
        
        System.assert(convertedAccounts.size() == 1); 
        
        List<Contact> convertedContacts = [
            SELECT Id
            FROM Contact       
        ];
        System.assert(convertedContacts.size() == 1); 
        
        List<Opportunity> convertedOpportunities = [
            SELECT Outreach_First_Primary_Contact__c 
            FROM Opportunity       
        ];
        System.assert(convertedOpportunities.size() == 1);        
        System.assertEquals(convertedContacts.get(0).Id, convertedOpportunities.get(0).Outreach_First_Primary_Contact__c); 
        
        
    }
    
    @isTest
    static void setFirstPrimaryContactOnOpportunity_manyRecordsTest(){  // created 03.03.2021 (Artem)
        
        List<Lead> leads = new List<Lead>();
        Lead newLead;
        Integer countRecords = 35;        
        String i;
        
        for(integer j = 1; j < countRecords + 1; ++j){
            newLead = new Lead();
            if(Math.mod(j, 10) == 0){                
                i = '' + j;
                String target = '0';
                String replacement = 'a';
                i = i.replace(target, replacement);
            } else {
                i = '' + j;
            }
            newLead.Company = 'Company' + i + 'Test' + i;
            newLead.Website = 'http://website' + i + '.com';
            newLead.FirstName = 'James' + i;
            newLead.LastName = '' + i + 't' + i;             
            newLead.Email = 't' + i + 'est' + i + '@gmail.com';
            newLead.Country = 'Country' + i; 
            newLead.State = 'State' + i;
            newLead.PostalCode = '' + i + (i + 1);
            newLead.City = '' + i + 't' + i;
            newLead.Street = '' + i + 'Street' + i;
            
            leads.add(newLead);
        } 
        
        insert leads;    
        
        List<Database.LeadConvert> leadsConvert = new List<Database.LeadConvert>();
        Database.LeadConvert lc;
        
        for(Integer i1 = 0; i1 < countRecords; ++i1){
            lc = new Database.LeadConvert();
            lc.setLeadId(leads.get(i1).Id);           
            leadsConvert.add(lc);          
        }  
        
        LeadStatus convertStatus = [
            Select Id, MasterLabel 
            FROM LeadStatus 
            WHERE IsConverted = true 
            LIMIT 1
        ];      
        
        for(Database.LeadConvert lconv : leadsConvert){
            lconv.setConvertedStatus(convertStatus.MasterLabel);
        }
        
        test.startTest();
        
        List<Database.LeadConvertResult> lcResults = Database.convertLead(leadsConvert);  
        
        test.stopTest();     
        
        for(Database.LeadConvertResult lcr : lcResults){
            System.assert(lcr.isSuccess());
        }       
        
        List<Account> convertedAccounts = [
            SELECT Id  
            FROM Account
        ];
        
        System.assert(convertedAccounts.size() == countRecords); 
        
        List<Contact> convertedContacts = [
            SELECT Id
            FROM Contact       
        ];
        
        System.assert(convertedContacts.size() == countRecords); 
        
        List<OpportunityContactRole> opportunityContactRoles = [
            SELECT ContactId, OpportunityId  
            FROM OpportunityContactRole       
        ];
        System.assert(opportunityContactRoles.size() == countRecords);
        
        Map<Id,Id> opportunityIdContactId = new Map<Id,Id>();
        for(OpportunityContactRole oppContRole : opportunityContactRoles){
            opportunityIdContactId.put(oppContRole.OpportunityId, oppContRole.ContactId);             
        }
        
        List<Opportunity> convertedOpportunities = [
            SELECT Outreach_First_Primary_Contact__c 
            FROM Opportunity       
        ];
        System.assert(convertedOpportunities.size() == countRecords);        
        
        for(Opportunity opp : convertedOpportunities){
            System.assert(opp.Outreach_First_Primary_Contact__c == opportunityIdContactId.get(opp.Id));     
        } 
    } 
}