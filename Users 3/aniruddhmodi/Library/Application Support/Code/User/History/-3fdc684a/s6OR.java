public class Persom {
    String name;
    int age;
    void speak() {
        System.out.println("My name is: " + name);

    }
     
    public static void main(String[] args) {
        Persom person1 = new Persom();

        person1.name = "Joe Bloggs";
        person1.age = 30;
        System.out.println(person1.name);

        
    }
}