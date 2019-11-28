public class AccountFabricMethod implements Record {
    public Account getRecord() {
        String name = DataForTestFactory.getRandFirstName() + ' ' + DataForTestFactory.getRandLastName();

        return new Account(Name=name);
    }
}
