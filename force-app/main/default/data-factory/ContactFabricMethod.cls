public class ContactFabricMethod implements Record {
    public Contact getRecord() {
        String lastName = DataForTestFactory.getRandLastName();
        String firstName = DataForTestFactory.getRandFirstName();
        Contact newContact = new Contact(FirstName=firstName,LastName=lastName);
        String field = DataForTestFactory.getRandContactField();

        if (field == 'LastName') {
            return newContact;
        }

        if (field == 'DoNotCall') {
            Double randNum = Math.random();
            
            if (randNum >= 0.5) {
                newContact.put(field, true);
            }
            else {
                newContact.put(field, false);
            }
        }
        else {
            Double randNum = Math.random();
            
            if (randNum >= 0.5) {
                newContact.put(field, DataForTestFactory.getRandDoubleFromList());
            }
            else {
                newContact.put(field, DataForTestFactory.getRandomDouble());
            }
        }
        return newContact;
    }
}
