public class Classes {
    String name;
    int age;


}

public class App {
    public static void main(String[] args) {
        Classes person1 = new Classes();
        person1.name = "Joe Bloggs";
        person1.age = 37;
        System.out.println(person1.name);
    }
}