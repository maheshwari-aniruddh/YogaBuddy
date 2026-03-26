import java.util.Scanner;

public class Simple_astrology {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        System.out.print("Enter your birthdate (MM/DD): ");
        String birthdate = scanner.nextLine();

        String astroSign = getAstrologicalSign(birthdate);
        displaySignInfo(astroSign);

        scanner.close();
    }

    public static String getAstrologicalSign(String birthdate) {
        String[] parts = birthdate.split("/");

        if (parts.length != 2) {
            System.out.println("Invalid input format. Please enter the birthdate in MM/DD format.");
            System.exit(1);
        }

        int month = Integer.parseInt(parts[0]);
        int day = Integer.parseInt(parts[1]);

        if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
        if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
        if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
        if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
        if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
        if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
        if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
        if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
        if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
        if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn";
        if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
        return "Pisces";
    }

    private static void displaySignInfo(String astroSign) {
        System.out.println("Your astrological sign is: " + astroSign);

        switch (astroSign) {
            case "Aries":
                System.out.println("Aries are known for their energy and determination.");
                break;
            case "Taurus":
                System.out.println("Taurus individuals are often associated with stability and patience.");
                break;
            case "Gemini":
                System.out.println("Geminis are known for their versatility and curiosity.");
                break;
            case "Cancer":
                System.out.println("Cancers are often considered nurturing and empathetic.");
                break;
            case "Leo":
                System.out.println("Leos are known for their confidence and leadership qualities.");
                break;
            case "Virgo":
                System.out.println("Virgos are often associated with attention to detail and practicality.");
                break;
            case "Libra":
                System.out.println("Libras are known for their love of balance and harmony.");
                break;
            case "Scorpio":
                System.out.println("Scorpios are often associated with intensity and passion.");
                break;
            case "Sagittarius":
                System.out.println("Sagittarians are known for their adventurous and optimistic nature.");
                break;
            case "Capricorn":
                System.out.println("Capricorns are often associated with ambition and discipline.");
                break;
            case "Aquarius":
                System.out.println("Aquarians are known for their independent and innovative thinking.");
                break;
            case "Pisces":
                System.out.println("Pisceans are often considered imaginative and compassionate.");
                break;
            default:
                System.out.println("Additional information about this sign could be added here.");
        }
    }
}
