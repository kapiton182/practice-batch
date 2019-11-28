@isTest
public class ChainContactsWithAccountBatchTest {
    @TestSetup
    static void setup(){
        Record accountFabric = new AccountFabricMethod();
        Record contactFabric = new ContactFabricMethod();
        Record rulesFabric = new ContactAssignmentRuleFabricMethod();

        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        List<Contact_Rule_Account_Junction__c> junctionList = new List<Contact_Rule_Account_Junction__c>();
        List<Contact_Assignment_Rule__c> ruleList = new List<Contact_Assignment_Rule__c>();

        Record junctionFabric = new JunctionAccountRuleFabricMethod(accountList, ruleList);

        for (Integer i = 0; i < 200; i++) {
            accountList.add((Account)accountFabric.getRecord());
            contactList.add((Contact)contactFabric.getRecord());
            ruleList.add((Contact_Assignment_Rule__c)rulesFabric.getRecord());
        }

        insert accountList;
        insert contactList;
        insert ruleList;

        for (Integer i = 0; i < 200; i++) {
            junctionList.add((Contact_Rule_Account_Junction__c)junctionFabric.getRecord());
        }

        insert junctionList;
    }

    @isTest
    static void setupTest() {
        Integer numOfAcc = [SELECT COUNT() FROM Account];
        Integer numOfCont = [SELECT COUNT() FROM Contact];
        Integer numOfJun = [SELECT COUNT() FROM Contact_Rule_Account_Junction__c];
        Integer numOfRul = [SELECT COUNT() FROM Contact_Assignment_Rule__c];

        System.assertEquals(numOfAcc , 200, 'smth doesnt work');
        System.assertEquals(numOfCont, 200, 'smth doesnt work');
        System.assertEquals(numOfJun, 200, 'smth doesnt work');
        System.assertEquals(numOfRul , 200, 'smth doesnt work');
    }

    @isTest
    static void executeTest() {
        Test.startTest();
            Database.executeBatch(new ChainContactsWithAccountBatch());
        Test.stopTest();

        List<Contact_Rule_Account_Junction__c> juncAccWithRuleList = [
            SELECT Contact_Assignment_Rule__r.Operator__c, Contact_Assignment_Rule__r.Field_Value__c, 
                Contact_Assignment_Rule__r.Field_API__c, Account__r.Id 
            FROM Contact_Rule_Account_Junction__c
            LIMIT 50000
        ];

        String allFieldsFromRules = getAllFieldsFromRules(juncAccWithRuleList);

        List<Account> accountList = (List<Account>)Database.query(
            'SELECT Id, Contacts_Limit__c, ('
                +'SELECT ' + getAllFieldsFromRules(juncAccWithRuleList) 
                + ' FROM Contacts) '
            +'FROM Account '
            +'WHERE Id '
            +'IN ('
                +'SELECT Account__c '
                +'FROM Contact_Rule_Account_Junction__c) '
            +'LIMIT 50000'
        );


        for (Account accountRecordItem : accountList) {
            if (accountRecordItem.Contacts.isEmpty()) {
                continue;
            }

            Integer amountOfContactOnAccount = accountRecordItem.Contacts_Limit__c == null ? 5 : Integer.valueOf(accountRecordItem.Contacts_Limit__c);
            List<Contact_Assignment_Rule__c> rulesForAccount = getRulesForAccount(juncAccWithRuleList, accountRecordItem);

            if (rulesForAccount.isEmpty()) {
                continue;
            }

            Boolean isLimitContactCorrect = accountRecordItem.Contacts.size() <= amountOfContactOnAccount;
            System.assert(isLimitContactCorrect, 'Number of Contact doesnt equall Limit on Account');

            for (Contact contactOnAccount : accountRecordItem.Contacts) {
                Boolean isContactOnAccountCorrect = isContactMatchesRules(contactOnAccount, rulesForAccount);
                System.assert(isContactOnAccountCorrect, 'Checking wasnt pass');
            }
        }
    }

    private static List<Contact_Assignment_Rule__c> getRulesForAccount(List<Contact_Rule_Account_Junction__c> ruleList, Account currentAccount) {
        List<Contact_Assignment_Rule__c> rulesForCurrentAccount = new List<Contact_Assignment_Rule__c>();
        Id currentAccountId = currentAccount.Id;

        for (Contact_Rule_Account_Junction__c ruleItem : ruleList) {
            if (currentAccountId == ruleItem.Account__r.Id) {
                rulesForCurrentAccount.add(new Contact_Assignment_Rule__c(
                    Operator__c = ruleItem.Contact_Assignment_Rule__r.Operator__c,
                    Field_Value__c = ruleItem.Contact_Assignment_Rule__r.Field_Value__c, 
                    Field_API__c = ruleItem.Contact_Assignment_Rule__r.Field_API__c
                ));
            }
        }

        return rulesForCurrentAccount;
    }

    private static Boolean isContactMatchesRules(Contact contactItem, List<Contact_Assignment_Rule__c> ruleList) {
        Map<String, Schema.SObjectField> contactFieldSetMap = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap();

        for (Contact_Assignment_Rule__c ruleItem : ruleList) {
            String fieldName = ruleItem.Field_API__c;
            String operator = ruleItem.Operator__c;
            String fieldValue = ruleItem.Field_Value__c;
            Object contFieldValue = contactItem.get(fieldName);

            Schema.DisplayType typeOfField = contactFieldSetMap.get(fieldName).getDescribe().getType();

            if (isFieldMatchRule(typeOfField, fieldValue, contFieldValue, operator) == false) {
                return false;
            }
        }

        return true;
    }

    private static String getAllFieldsFromRules(List<Contact_Rule_Account_Junction__c> junkAccountsWithRules) {
        Set<String> uniqueFields = new Set<String>();

        for (Contact_Rule_Account_Junction__c junkItem : junkAccountsWithRules) {
            uniqueFields.add(junkItem.Contact_Assignment_Rule__r.Field_API__c);
        }

        return String.join(new List<String>(uniqueFields), ',');
    }

    private static Boolean isFieldMatchRule(Schema.DisplayType typeOfField, String fieldValue, Object contFieldValue, String operator) {
        switch on typeOfField {
            when Boolean {
                return Boolean.valueOf(fieldValue) == Boolean.valueOf(contFieldValue);
            }
            when CURRENCY {
                if (operator == '>') {
                    return Double.valueOf(fieldValue) > Double.valueOf(contFieldValue);
                }
                else if (operator == '=') {
                    return Double.valueOf(fieldValue) == Double.valueOf(contFieldValue);
                }
                else if (operator == '<') {
                    return Double.valueOf(fieldValue) < Double.valueOf(contFieldValue);
                }
            }
            when String {
                if (operator == '>') {
                    return String.valueOf(fieldValue) > String.valueOf(contFieldValue);
                }
                else if (operator == '=') {
                    return String.valueOf(fieldValue) == String.valueOf(contFieldValue);
                }
                else if (operator == '<') {
                    return String.valueOf(fieldValue) < String.valueOf(contFieldValue);
                }
            }
            when Date {
                if (operator == '>') {
                    return Date.valueOf(fieldValue) > Date.valueOf(contFieldValue);
                }
                else if (operator == '=') {
                    return Date.valueOf(fieldValue) == Date.valueOf(contFieldValue);
                }
                else if (operator == '<') {
                    return Date.valueOf(fieldValue) < Date.valueOf(contFieldValue);
                }
            }
            when Datetime {
                if (operator == '>') {
                    return Datetime.valueOf(fieldValue) > Datetime.valueOf(contFieldValue);
                }
                else if (operator == '=') {
                    return Datetime.valueOf(fieldValue) == Datetime.valueOf(contFieldValue);
                }
                else if (operator == '<') {
                    return Datetime.valueOf(fieldValue) < Datetime.valueOf(contFieldValue);
                }
            }
        }

        return false;
    }
}
