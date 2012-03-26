<%@ Page Language="C#" %>
<script runat="server">
   void Page_Load(Object sender, EventArgs e) 
   {
       //Define variable
       int randomValue;
       string dateTimeLabel;
       //Define limits
       int lowerLimit = 30;
       int upperLimit = 35;

       //Random object
       System.Random rand;
       rand = new System.Random();

       //Generate a random value
       randomValue = (int)rand.Next(lowerLimit, upperLimit);

       //Get date object
       DateTime objToday = DateTime.Now;
       //Create time string in hh:mm:ss format
       dateTimeLabel = objToday.Hour + ":" + objToday.Minute + ":" + objToday.Second;

       //Now write it to output stream
       Response.Write("&label=" + dateTimeLabel + "&value=" + randomValue);       
   }
</script>