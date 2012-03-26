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
Dim googlePrice1, googlePrice2, googlePrice3
Dim dellPrice1, dellPrice2, dellPrice3
Dim currDateTime, dateTimeLabel1, dateTimeLabel2, dateTimeLabel3

lowerLimitGoog = 30
upperLimitGoog = 35
lowerLimitDell = 22
upperLimitDell = 26


'Generate random values - and round them to 2 decimal places
googlePrice1 = Int(Rnd()*100*(upperLimitGoog-lowerLimitGoog))/100+lowerLimitGoog 
googlePrice2 = Int(Rnd()*100*(upperLimitGoog-lowerLimitGoog))/100+lowerLimitGoog 
googlePrice3 = Int(Rnd()*100*(upperLimitGoog-lowerLimitGoog))/100+lowerLimitGoog 

dellPrice1 = Int(Rnd()*100*(upperLimitDell-lowerLimitDell))/100+lowerLimitDell
dellPrice2 = Int(Rnd()*100*(upperLimitDell-lowerLimitDell))/100+lowerLimitDell
dellPrice3 = Int(Rnd()*100*(upperLimitDell-lowerLimitDell))/100+lowerLimitDell

'Get the current date
currDateTime = Now()

'Get 3 labels for the data - time in format hh:mn:ss
dateTimeLabel1 = Datepart("h",currDateTime) & ":" & Datepart("n",currDateTime ) & ":" & Datepart("s",currDateTime)
'To change date time, we increment currDateTime by 20 seconds
currDateTime = Dateadd("s",20, currDateTime)
dateTimeLabel2 = Datepart("h",currDateTime) & ":" & Datepart("n",currDateTime ) & ":" & Datepart("s",currDateTime)
currDateTime = Dateadd("s",20, currDateTime)
dateTimeLabel3 = Datepart("h",currDateTime) & ":" & Datepart("n",currDateTime ) & ":" & Datepart("s",currDateTime)

'Now write it to output stream
Response.Write("&label="& dateTimeLabel1 & "," & dateTimeLabel2 & "," & dateTimeLabel3 & "&value=" & googlePrice1 & "," & googlePrice2 & "," &googlePrice3 & "|" & dellPrice1 & "," & dellPrice2 & "," & dellPrice3)
%>