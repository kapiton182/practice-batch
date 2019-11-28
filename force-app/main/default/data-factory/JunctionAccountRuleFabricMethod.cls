public class JunctionAccountRuleFabricMethod implements Record {
    List<Account> accountList;
    List<Contact_Assignment_Rule__c> ruleList;

    public Contact_Rule_Account_Junction__c getRecord() {
        Account randAccount = DataForTestFactory.getRandElemFromList(accountList);
        Contact_Assignment_Rule__c randRule = DataForTestFactory.getRandElemFromList(ruleList);

        return new Contact_Rule_Account_Junction__c(Account__c=randAccount.Id, Contact_Assignment_Rule__c=randRule.Id);
    }

    public JunctionAccountRuleFabricMethod(List<Account> accountList, List<Contact_Assignment_Rule__c> ruleList) {
        this.accountList = accountList;
        this.ruleList = ruleList;
    }

}
