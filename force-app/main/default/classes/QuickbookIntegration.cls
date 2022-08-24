public with sharing class QuickbookIntegration {
    // the companyId/realmId is set in custom metadata types in Salesforce
    private static final Quickbooks_variables__mdt varQuickbooks = Quickbooks_variables__mdt.getInstance('company_Id');
    private static final String COMPANY_ID                       = varQuickbooks.company_id__c;

    public QuickbookIntegration() {

    }
    public static void getCustomer() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Quickbooks_Named_Credential/v3/company/'+COMPANY_ID+'/customer/39');
        req.setHeader('Accept','application/json');
        req.setHeader('Content-Type','application/json');
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
    }
    public static void getSalesReceipt(Integer receiptNo) {
        /*  SENDING RECEIPTS TO SALESFORCE
            When a receipt is paid for in QB, 
            the receipt details that are geneated should be sent to Salesforce and saved in the Payments object
            TODO: Make this class a webservice with a callback url to get receipts in real time or make it schedulable
                  so it can collect receipt details at regular intervals
            TODO: Optimize the code to handle scenarios where the receipt needs to pay the balance amount 
        */
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Quickbooks_Named_Credential/v3/company/'+COMPANY_ID+'/salesreceipt/'+receiptNo);
        req.setHeader('Accept','application/json');
        req.setHeader('Content-Type','application/json');
        req.setMethod('GET');
        try {
            HTTPResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                // get the response object
                Map<String, Object> receiptObj = (Map<String, Object>) JSON.deserializeUntyped(res.getBody()); 

                // extract the Sales receipt
                Map<String, Object> salesReceipt = (Map<String, Object>) receiptObj.get('SalesReceipt');

                // extract the record Id of the Salesforce order/oppty being paid for by the receipt
                List<Object> customFieldList = (List<Object>) salesReceipt.get('CustomField');
                Map<String, Object> customField = (Map<String, Object>) customFieldList[0];
                String recordIdRef = String.valueOf(customField.get('DefinitionId'));
                System.debug('===recordIdRef=== '+recordIdRef);

               // extract account name from the receipt
                Map<String, Object> customerRef = (Map<String, Object>) salesReceipt.get('CustomerRef');
                String paymentAccount = String.valueOf(customerRef.get('name'));
                System.debug('===paymentAccount=== '+paymentAccount);
            
                // extract the total amount paid from the receipt
                Integer totalAmount = Integer.valueOf(salesReceipt.get('TotalAmt'));
                System.debug('===totalAmount=== '+totalAmount);

                // extract the remaining balance from the receipt if any
                Integer balance = Integer.valueOf(salesReceipt.get('Balance'));
                System.debug('===balance=== '+balance);

                // extract the currency from the receipt
                Map<String, Object> currencyRef = (Map<String, Object>) salesReceipt.get('CurrencyRef');
                String receiptCurrency = String.valueOf(currencyRef.get('value'));
                System.debug('===receiptCurrency=== '+receiptCurrency);

                // extract the payment method from the receipt
                Map<String, Object> paymentMethodRef = (Map<String, Object>) salesReceipt.get('PaymentMethodRef');
                String paymentMethod = String.valueOf(paymentMethodRef.get('name'));
                System.debug('===paymentMethod=== '+paymentMethod);

                // extract the create and update date from the receipt
                Map<String, Object> metaData = (Map<String, Object>) salesReceipt.get('MetaData');
                String createtime = String.valueOf(metaData.get('CreateTime'));
                String lastUpdatedTime = String.valueOf(metaData.get('LastUpdatedTime'));
                System.debug('===createtime=== '+createtime);
                System.debug('===lastUpdatedTime=== '+lastUpdatedTime);
                
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
When the final sales order has been approved, details of the sales order including a unique Identifier of the record(eg record Id) should be posted in QB and saved in an Invoice
(We can use the custom field provided in quickbooks to store the record Id)

SENDING RECEIPT TO SALESFORCE
When a receipt is paid for in QB, the receipt details that are geneated should be sent to Salesforce and Saved in the Payments custom object that is connected to Oppty in a 
Master 
*/
