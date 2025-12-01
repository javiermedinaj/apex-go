@RestResource(urlMapping='/B2BLeads/*')
global with sharing class B2BLeadAPI {

    //DTO
    global class B2BLeadWrapper {
        public String fullName;
        public String email;
        public String company;
        public String tier;      // VIP, Standard, Blacklist
        public String source;    // Web, Partner, etc.
    }

    @HttpPost
    global static String ingestLeads() {
        RestRequest req = RestContext.request;
        String responseMessage = '';
        
        try {
            String jsonBody = req.requestBody.toString();
            List<B2BLeadWrapper> incomingData = (List<B2BLeadWrapper>) JSON.deserialize(jsonBody, List<B2BLeadWrapper>.class);
            
            List<Lead> leadsToInsert = new List<Lead>();
            
            for(B2BLeadWrapper item : incomingData) {
                Lead newLead = new Lead();
                newLead.LastName = item.fullName; 
                newLead.Company = item.company;
                newLead.Email = item.email;
                newLead.LeadSource = item.source;
                
                // Mapeo del "Tier" que calculó Go a campos de Salesforce
                if (item.tier == 'VIP') {
                    newLead.Rating = 'Hot';
                    newLead.Description = 'CLIENTE VIP DETECTADO POR MIDDLEWARE';
                } else if (item.tier == 'BLACKLIST') {
                    newLead.Status = 'Closed - Not Converted';
                    newLead.Description = 'ALERTA: Competencia o Cliente Bloqueado';
                } else {
                    newLead.Rating = 'Warm';
                }
                
                leadsToInsert.add(newLead);
            }
            
            if(!leadsToInsert.isEmpty()) {
                insert leadsToInsert;
                responseMessage = 'Success: ' + leadsToInsert.size() + ' leads procesados.';
            }
            
        } catch (Exception e) {
            responseMessage = 'Error: ' + e.getMessage();
            System.debug('Error B2B API: ' + e.getMessage());
        }
        
        return responseMessage;
    }
}