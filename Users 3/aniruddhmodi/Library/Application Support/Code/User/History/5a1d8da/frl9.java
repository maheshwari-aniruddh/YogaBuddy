public class App1 {
    public static void main(String[] args) {

        Thing thing1 = new Thing();
        thing1.name = ("Mrbeast");
        Thing.description="This is static and remains with the class only";
        System.out.println(thing1.name);
        System.out.println(Thing.description);

        
    }

}
