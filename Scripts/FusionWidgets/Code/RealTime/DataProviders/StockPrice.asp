<%@ Language=VBScript %>
<%
'This page is meant to output the Stock Price of Google in real-time data format. 
'The data will be picked by FusionWidgets real-time line chart and plotted on chart.
'You need to make sure that the output data doesn't contain any HTML tags or carriage returns.

'For the sake of demo, we'll just be generating a random value between 30 and 35 and returning the same.
'In real life applications, you can get the data from web-service or your own data systems, convert it into real-time data format and then return to the chart.

'Set randomize timers on
Randomize()
Randomize Timer

Dim lowerLimit, upperLimit
Dim randomValue
Dim dateTimeLabel

lowerLimit = 30
upperLimit = 35

'Generate a random value - and round it to 2 decimal places
randomValue = Int(Rnd()*100*(upperLimit-lowerLimit))/100+lowerLimit

'Get label for the data - time in format hh:mn:ss
dateTimeLabel = Datepart("h",Now()) & ":" & Datepart("n",Now()) & ":" & Datepart("s",Now())

'Now write it to output stream
Response.Write("&label="& dateTimeLabel & "&value=" & randomValue)
%>