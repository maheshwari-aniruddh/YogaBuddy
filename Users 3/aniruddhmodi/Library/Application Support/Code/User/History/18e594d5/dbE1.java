public class App {
   public static void main(String[] args) {
    Person person1 = new Person();

    System.out.println(person1.name);

    person1.name = "Joe";
    person1.age = 37;
    person1.speak();
    person1.sayHello();
    System.out.println(person1.name);


   }
    

}
