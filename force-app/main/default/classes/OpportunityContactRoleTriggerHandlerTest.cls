/*
 * Created by Artem on 03 March 2010
 * 
 */

@isTest
private class OpportunityContactRoleTriggerHandlerTest {
    @isTest
    static void setContactIdOnOpportunityTest(){
        
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        
        Contact cont = new Contact();
        cont.LastName = 'Test';
        cont.LeadSource = 'Other';
        cont.AccountId = acc.Id;
        cont.Email = 'test@mail.com';
        insert cont;
        
        Opportunity opp = new Opportunity();
        opp.StageName = '0-SAL';
        opp.CloseDate = Date.valueOf('2021-01-01');
        opp.Name = 'Test';
        opp.AccountId = acc.Id;
        opp.LeadSource = 'Other';
        insert opp;
        
        OpportunityContactRole oppContRole = new OpportunityContactRole();
        oppContRole.ContactId = cont.Id;
        oppContRole.OpportunityId = opp.Id;
        
        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
        
        opportunityContactRoles.add(oppContRole);
       
        OpportunityContactRoleTriggerHandler.setContactIdOnOpportunity(opportunityContactRoles);              
        
        List<Opportunity> opportunities = [
            SELECT Outreach_First_Primary_Contact__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        
        System.assertEquals(cont.Id, opportunities.get(0).Outreach_First_Primary_Contact__c);
        
    }
}