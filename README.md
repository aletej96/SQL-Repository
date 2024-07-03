Ahora vamos a crear un directorio con todos los scripts que he visto en el bootcamp de data analisis
/*Aqui estan los datos para crear un fomato de table de fecha en power bi*/
Date =
ADDCOLUMNS (
CALENDAR( MIN(orders[orderDate]) , MAX(orders[orderDate])),
"DateAsInteger", FORMAT ( [Date], "YYYYMMDD" ),
"Year", YEAR ( [Date] ),
"Monthnumber", FORMAT ( [Date], "MM" ),
"DayNumber", FORMAT( [Date], "dd" ),
"YearMonthnumber", FORMAT ( [Date], "YYYY/MM" ),
"Evolution", FORMAT ( [Date], "YYYY/MM" ),
"YearMonthShort", FORMAT ( [Date], "YYYY/mmm" ),
"MonthNameShort", FORMAT ( [Date], "mmm" ),
"MonthNameLong", FORMAT ( [Date], "mmmm" ),
"DayOfWeekNumber", WEEKDAY ( [Date] ),
"DayOfWeek", FORMAT ( [Date], "dddd" ),
"DayOfWeekShort", FORMAT ( [Date], "ddd" ),
"Quarter", "Q" & FORMAT ( [Date], "Q" ),
"YearQuarter", FORMAT ( [Date], "YYYY" ) & "/Q" & FORMAT ( [Date], "Q" )
)
