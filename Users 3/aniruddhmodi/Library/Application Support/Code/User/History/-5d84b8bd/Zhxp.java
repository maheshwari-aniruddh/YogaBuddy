public class string_formatting {
    public static void main(String[] args) {
        String info = ""; 
        info+= "My name is Bob.";
        info+= "";
        info+= "I am a builder.";
        System.out.println(info); 

        StringBuilder sb = new StringBuilder("");
        sb.append("My name is Sui.");
        sb.append(" ");
        sb.append("I am a cool kid.");
        System.out.println(sb);        

        /// Formatting /////
        System.out.println("Here is some text. \tThat was a tab. \nthat was a new line");
        System.out.printf("Total cost %d; number quantity is %d\n", 5,120);
    }

}