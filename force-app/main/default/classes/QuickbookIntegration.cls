public with sharing class QuickbookIntegration {
    public QuickbookIntegration() {

    }
    // realmId or companyId: 4620816365230256810
    public static void getCustomer() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Quickbooks_Named_Credential/v3/company/4620816365230256810/customer/39');
        req.setHeader('Accept','application/json');
        req.setHeader('Content-Type','application/json');
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
    }
    public static void getSalesReceipt(Integer receiptNo) {
        /*When a receipt is paid for in QB, 
        the receipt details that are geneated should be sent to Salesforce and
        Saved in the Payments custom object that is connected to Oppty in a Master-detail relationship
        TODO: make this a webservice with a callback url to get receipt info in real time*/
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Quickbooks_Named_Credential/v3/company/4620816365230256810/salesreceipt/'+receiptNo);
        req.setHeader('Accept','application/json');
        req.setHeader('Content-Type','application/json');
        req.setMethod('GET');
        try {
            HTTPResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> receiptDetails = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('======'+receiptDetails);
                

            }
            
        } catch (CalloutException e) {
            System.debug('Callout Error '+ e.getMessage());
        }
        

    }

}

/*
ACCOUNT & CONTACTS
When a contact of a given record-type eg Customer is created/updated in Salesforce, It should be sent to QB and Saved as a Customer and vice-versa
ACCOUNT & CONTACTS in Salesforce are both recognized as Customers in QB in this case we bundle the two and save them in the customer object in QB


PRODUCTS
These are identified as Items in QB
whenever a product is added in Salesforce, It should be added in QB as well

OPPORTUNITY
When an opportunity is marked as closed won in SF, create a Draft Sales receipt(It must be approved to become an actual receipt) in QB

SENDING FINAL ORDER TO Quickbooks
When the final sales order has been approved, details of the sales order should be posted to QB and saved in an Invoice

SENDING RECEIPT TO SALESFORCE
When a receipt is paid for in QB, the receipt details that are geneated should be sent to Salesforce and Saved in the Payments custom object that is connected to Oppty in a 
Master 

*/

