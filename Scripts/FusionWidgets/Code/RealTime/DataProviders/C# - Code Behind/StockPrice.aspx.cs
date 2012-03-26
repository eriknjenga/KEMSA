using System;
using System.Data;
using System.Configuration;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;

public partial class StockPrice : System.Web.UI.Page 
{
    protected void Page_Load(object sender, EventArgs e)
    {
        //Define variable
        int randomValue;
        string dateTimeLabel;
        //Define limits
        int lowerLimit = 30;
        int upperLimit = 35;

        //Create random object
        System.Random rand;
        rand = new System.Random();

        //Generate a random value
        randomValue = (int)rand.Next(lowerLimit, upperLimit);

        //Get date object
        DateTime objToday = DateTime.Now;
        //Create time string in hh:mm:ss format
        dateTimeLabel = objToday.Hour + ":" + objToday.Minute + ":" + objToday.Second;
        
        //Now write it to output stream
        Response.Write ("&label=" + dateTimeLabel + "&value=" + randomValue);
    }
}
