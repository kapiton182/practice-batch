public class ContactAssignmentRuleFabricMethod implements Record {

    public Contact_Assignment_Rule__c getRecord() {
        String fieldName = DataForTestFactory.getRandContactField();
        String operator = DataForTestFactory.getRandOperatorFromList();
        String value;

        if (fieldName == 'LastName') {
            value = DataForTestFactory.getRandLastName();
        }
        else if (fieldName == 'DoNotCall') {
            Double randNum = Math.random();
            
            if (randNum >= 0.5) {
                value = String.valueOf(true);
                operator = '=';
            }
            else { 
                value = String.valueOf(false);
                operator = '=';
            }
        }
        else {
            Double randNum = Math.random();
            
            if (randNum >= 0.5) {
                value = String.valueOf(DataForTestFactory.getRandDoubleFromList());
            }
            else {
                String tempValue =  String.valueOf(DataForTestFactory.getRandomDouble());

                if (tempValue.length() > 5) {
                    value = tempValue.substring(0, 5);
                }
                else {
                    value = tempValue;
                }
            }
            
        }
         
        

        return new Contact_Assignment_Rule__c(Field_Value__c=value, Operator__c=operator, Field_API__c=fieldName);
    }
}
