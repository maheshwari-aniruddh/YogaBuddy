public class Person {


    String name;
    int age;

    void speak() {
        System.out.println("Hello my name is " + name + " and i am " + age + "  years old");
    }
    int retirement() {
        int years = 65-age;

        return years;
    }


}

