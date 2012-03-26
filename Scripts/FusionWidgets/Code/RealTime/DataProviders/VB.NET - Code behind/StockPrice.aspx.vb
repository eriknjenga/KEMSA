
Partial Class StockPrice
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        'Define variables
        Dim dateTimeLabel As String
        Dim lowerLimit As Integer, upperLimit As Integer

        'Setting limits
        lowerLimit = 30
        upperLimit = 35

        'Generate a random value - and round it to 2 decimal places
        Dim randomValue As Integer, randomNum As New Random
        randomValue = randomNum.Next(lowerLimit, upperLimit)

        'Generate the x-axis label (time in hh:mm:ss format)
        Dim objToday As Date = Now
        dateTimeLabel = objToday.Hour.ToString + ":" + objToday.Minute.ToString + ":" + objToday.Second.ToString

        'Now write it to output stream
        Response.Write("&label=" + dateTimeLabel + "&value=" + randomValue.ToString)
    End Sub    
End Class
