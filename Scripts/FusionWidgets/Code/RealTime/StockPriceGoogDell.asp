<%@ Language=VBScript %>
<%
'This page is meant to output the Stock Price of Google in real-time data format. 
'The data will be picked by FusionWidgets real-time line chart and plotted on chart.
'You need to make sure that the output data doesn't contain any HTML tags or carriage returns.

'For the sake of demo, we'll just be generating random values and returning them
'In real life applications, you can get the data from web-service or your own data systems, convert it into real-time data format and then return to the chart.

'Set randomize timers on
Randomize()
Randomize Timer

Dim lowerLimitGoog, upperLimitGoog
Dim lowerLimitDell, upperLimitDell
Dim googlePrice, dellPrice
Dim dateTimeLabel

lowerLimitGoog = 30
upperLimitGoog = 35
lowerLimitDell = 22
upperLimitDell = 26


'Generate random values - and round them to 2 decimal places
googlePrice = Int(Rnd()*100*(upperLimitGoog-lowerLimitGoog))/100+lowerLimitGoog 
dellPrice = Int(Rnd()*100*(upperLimitDell-lowerLimitDell))/100+lowerLimitDell

'Get label for the data - time in format hh:mn:ss
dateTimeLabel = Datepart("h",Now()) & ":" & Datepart("n",Now()) & ":" & Datepart("s",Now())

'Now write it to output stream
Response.Write("&label="& dateTimeLabel & "&value=" & googlePrice & "|" & dellPrice)
%>