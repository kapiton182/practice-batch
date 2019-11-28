public class ChainContactsWithAccountBatch implements Database.Batchable<Account>, Database.Stateful {
    Map<String, Schema.SObjectField> contactFieldSetMap = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap();
    List<Contact_Rule_Account_Junction__c> ruleList = [
            SELECT Contact_Assignment_Rule__r.Operator__c, Contact_Assignment_Rule__r.Field_Value__c, 
                Contact_Assignment_Rule__r.Field_API__c, Account__r.Id 
            FROM Contact_Rule_Account_Junction__c
            LIMIT 50000
        ];

    public List<Account> start(Database.BatchableContext context) {
        return (List<Account>)Database.query(
            'SELECT Id, Contacts_Limit__c, ('
                +'SELECT ' + getAllFieldsFromRules(ruleList) 
                + ' FROM Contacts) '
            +'FROM Account '
            +'WHERE Id '
            +'IN ('
                +'SELECT Account__c '
                +'FROM Contact_Rule_Account_Junction__c) '
            +'LIMIT 50000'
        );
    }

    public void execute(Database.BatchableContext context, List<Account> accountRecordList) {
        List<Contact> contactList = (List<Contact>)Database.query(
            'SELECT ' + getAllFieldsFromRules(ruleList) 
            +' FROM Contact '
            +'WHERE accountId=NULL '
            +'AND (' + getAllConditions(ruleList) + ') '
            + 'LIMIT 50000'
        );

        for (Account accountRecordItem : accountRecordList) {
            Integer amountOfContactOnAccount = accountRecordItem.Contacts_Limit__c == null ? 5 : Integer.valueOf(accountRecordItem.Contacts_Limit__c);
            List<Contact_Assignment_Rule__c> rulesForAccount = getRuleListForAccount(ruleList, accountRecordItem);

            for (Contact contactOnAccount : accountRecordItem.Contacts) {
                 if (isContactMatchesRules(contactOnAccount, rulesForAccount) == false) {
                    contactOnAccount.accountId = null;
                    contactList.add(contactOnAccount);
                }
            }

            for (Contact contactItem : contactList) {
                if (amountOfContactOnAccount == 0) {
                    break;
                }

                if (isContactMatchesRules(contactItem, rulesForAccount) == true) {
                    contactItem.accountId = accountRecordItem.Id;
                    amountOfContactOnAccount--;
                }
            }
        }
        update contactList;
    }

    public void finish(Database.BatchableContext context) {

    }

    private String getAllFieldsFromRules(List<Contact_Rule_Account_Junction__c> junkAccountsWithRules) {
        Set<String> uniqueFields = new Set<String>();

        for (Contact_Rule_Account_Junction__c junkItem : junkAccountsWithRules) {
            uniqueFields.add(junkItem.Contact_Assignment_Rule__r.Field_API__c);
        }

        return String.join(new List<String>(uniqueFields), ',');
    }

    private String getAllConditions(List<Contact_Rule_Account_Junction__c> ruleList) {
        String conditionString = '';

        for (Contact_Rule_Account_Junction__c ruleItem : ruleList) {
            conditionString += getCondition(ruleItem) + ' OR ';
        }

        return conditionString.substring(0, conditionString.length() - 3);
    }

    private String getCondition(Contact_Rule_Account_Junction__c ruleItem) {
        String ruleItemValue = isQuotesNeed(ruleItem.Contact_Assignment_Rule__r.Field_API__c)
            ? '\''+ ruleItem.Contact_Assignment_Rule__r.Field_Value__c + '\''
            : ruleItem.Contact_Assignment_Rule__r.Field_Value__c;

        return ruleItem.Contact_Assignment_Rule__r.Field_API__c
            + ruleItem.Contact_Assignment_Rule__r.Operator__c
            + ruleItemValue;
    }

    private Boolean isQuotesNeed(String fieldName) {
        Schema.DisplayType type = contactFieldSetMap.get(fieldName).getDescribe().getType();
        switch on type {
            when Boolean, Integer, Long, Currency {
                return false;
            }
            when else {
                return true;
            }
        }
    }

    private List<Contact_Assignment_Rule__c> getRuleListForAccount(List<Contact_Rule_Account_Junction__c> ruleList, Account currentAccount) {
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

    private Boolean isContactMatchesRules(Contact contactItem, List<Contact_Assignment_Rule__c> ruleList) {
        for (Contact_Assignment_Rule__c ruleItem : ruleList) {
            Object contFieldValue = contactItem.get(ruleItem.Field_API__c);
            Schema.DisplayType typeOfField = contactFieldSetMap.get(ruleItem.Field_API__c).getDescribe().getType();
            if (isFieldMatchRule(typeOfField, ruleItem.Field_Value__c, contFieldValue, ruleItem.Operator__c) == false) {
                return false;
            }
        }

        return true;
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