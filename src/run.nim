import times
import parsecsv
import cligen
import strutils
import tables


proc parse(csvFn: string): Table[string, (DateTime, string, float, float, bool)] =
 var par: CsvParser
 par.open(csvFn)
 defer: par.close()
 par.readHeaderRow()
 var open, close: float
 var day: string

 result = initTable[string, (DateTime, string, float, float, bool)]()

 while par.readRow():
   let dt = parse(par.rowEntry("Date"), "yyyy-MM-dd")
   open = parseFloat(par.rowEntry("Open"))
   close = parseFloat(par.rowEntry("Close"))
   day = dt.format("ddd")
   result[par.rowEntry("Date")] = (dt, day, open, close, close > open )


proc calc(data: Table[string, (DateTime, string, float, float, bool)], then: DateTime) =

  var closeInBlack = initTable[string, CountTable[bool]]
  echo data

  for k, v in data:
    if v[0] < then:
      continue
    echo v[0], " ", then
    if not closeInBlack.hasKey(v[1]):
      closeInBlack[v[1]] = initCountTable[bool]()



proc main(csvFn: string)=
  var data = parse(csvFn)
  echo data
  calc(data, now() - 1.months)
  #calc(data, now() - 6.months)
  #calc(data, now() - 1.years)

dispatch(main)
