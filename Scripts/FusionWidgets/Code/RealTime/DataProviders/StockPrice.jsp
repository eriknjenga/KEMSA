<%@page language="java"%><%@page import="java.util.Calendar" %><%@page import="java.text.SimpleDateFormat" %><%
/*
This page is meant to output the Stock Price of Google in real-time data format. 
The data will be picked by FusionWidgets real-time line chart and plotted on chart.
You need to make sure that the output data doesn't contain any HTML tags or carriage returns.
For the sake of demo, we'll just be generating a random value between 30 and 35 and returning the same.
In real life applications, you can get the data from web-service or your own data systems, convert it into real-time data format and then return to the chart.
*/
/*
Note: In order to get the output without addition of any 
carriage-returns or tab spaces, there should not be spaces or empty lines
between scriptlet tags or at the end of the page.
*/
int lowerLimit = 30;
int upperLimit = 35;
//Generate a random value - between lower and upper limits

double randomValue = Math.random()*100*(upperLimit-lowerLimit)/100+lowerLimit;

// Next few steps, to round this double to 2 decimal places
long factor = (long)Math.pow(10,2);

// Shift the decimal the correct number of places
// to the right.
randomValue = randomValue * factor;

// Round to the nearest integer.
long tmp = Math.round(randomValue);

// Shift the decimal the correct number of places
// back to the left.
double roundedRandomValue=(double)tmp / factor;
//Get label for the data - time in format HH:mm:ss

Calendar cal = Calendar.getInstance();
SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
String timeLabel = sdf.format(cal.getTime());

String dataParameters = "&label=" +timeLabel+ "&value=" +roundedRandomValue;

//Now write it to output stream
out.print(dataParameters);%>