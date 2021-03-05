public with sharing class AutoConvertLeads {

    private static Map<String, Id> accountsById = new Map<String, Id>();
    private static Map<Id, String> leadsByIdsWithCompanies = new Map<Id, String>();
    private static Map<Id, Lead> leads;
    private static Id currentUserId = UserInfo.getUserId();
    private static final Integer ADD_DAYS_TO_FORECAST_CLOSED_DATE = 180; 

    public static void LeadAssign(List<Id> LeadIds) {
        LeadStatus CLeadStatus= [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true Limit 1];
        System.debug('-------------------------------AutoConvertLeads.LeadAssign');
        if (!populateLeadsCompanies(LeadIds).values().isEmpty()) {
            populateAccountsByLeadsCompanies();
        }
        List<Database.LeadConvert> MassLeadconvert = new List<Database.LeadConvert>();
        for(id currentlead: LeadIds){
            Database.LeadConvert Leadconvert = new Database.LeadConvert();
            if (leadsByIdsWithCompanies.containsKey(currentlead)) {
                Leadconvert.setAccountId(accountsById.get(leadsByIdsWithCompanies.get(currentlead)));
            }
            if(leads.get(currentLead).OwnerId.getSObjectType() != User.SObjectType) {
                Leadconvert.setOwnerId(currentUserId);
            }
            Leadconvert.setLeadId(currentlead);
            Leadconvert.setConvertedStatus(CLeadStatus.MasterLabel);
            MassLeadconvert.add(Leadconvert);
        }

        if (!MassLeadconvert.isEmpty()) {
            Date forecastedClosedDate = Date.today().addDays(ADD_DAYS_TO_FORECAST_CLOSED_DATE);
            Set<Id> createdOpportunitiIds = new Set<Id>();
            List<Database.LeadConvertResult> lcr = Database.convertLead(MassLeadconvert);
            List<Opportunity> oppToUpdate = new List<Opportunity>();
            
            
            
            Map<Id,Id> oppIdContactId = new Map<Id,Id>();  // added this line (Artem)

            for (Database.LeadConvertResult lcrSingl : lcr) {
                createdOpportunitiIds.add(lcrSingl.getOpportunityId());
                oppIdContactId.put(lcrSingl.getOpportunityId(), lcrSingl.getContactId()); // added this line (Artem)
            }
           
            for (Id key : createdOpportunitiIds) {

                oppToUpdate.add(
                    new Opportunity(
                        Id = key, 
                        StageName = '0-SAL', 
                        CloseDate = forecastedClosedDate, 
                        Prospect_Action__c = '[Converted Opp]',
                        Outreach_First_Primary_Contact__c = oppIdContactId.get(key)  // added this line (Artem)
                        ));
            }
           
            update oppToUpdate;   
            
        }
    }

    private static Map<Id, String> populateLeadsCompanies(List<Id> leadIds) {
        leads = new Map<Id, Lead>([SELECT Id, Company, OwnerId FROM Lead WHERE Id IN : leadIds]);

        for (Lead l : leads.values()) {
            if (String.isNotBlank(l.Company)) {
                leadsByIdsWithCompanies.put(l.Id, l.Company);
            }
        }
        return leadsByIdsWithCompanies;
    }

    private static void populateAccountsByLeadsCompanies() {
        for (Account acc: [
                SELECT Id, Name FROM Account
                WHERE Name IN: leadsByIdsWithCompanies.values()
        ]) {
            accountsById.put(acc.Name, acc.Id);
        }
    }
}