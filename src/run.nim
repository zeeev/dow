import times
import parsecsv
import cligen
import strutils
import tables
import asciitables
import strformat


proc parse(csvFn: string): Table[string, (DateTime, string, float, float, bool)] =
 var par: CsvParser
 par.open(csvFn)
 defer: par.close()
 par.readHeaderRow()
 var open, close: float
 var day: string
 var month: string
 var year: string

 result = initTable[string, (DateTime, string, float, float, bool)]()

 while par.readRow():
   let dt = parse(par.rowEntry("Date"), "yyyy-MM-dd")
   open = parseFloat(par.rowEntry("Open"))
   close = parseFloat(par.rowEntry("Close"))
   day = dt.format("dddd")
   month = dt.format("MM")
   year  = dt.format("yyyy")
   result[par.rowEntry("Date")] = (dt, day, open, close, close > open )
   #echo "DATA: {year} {month} {day} {open} {close} {close - open:9.3f}".fmt

proc filter(data: Table[string, (DateTime, string, float, float, bool)], pastL: DateTime, pastH: DateTime): Table[string, (DateTime, string, float, float, bool)] =
  result = initTable[string, (DateTime, string, float, float, bool)]()

  for k, v in data:
    if v[0] < pastL:
      continue
    if v[0] > pastH:
      continue
    result[k] = v


proc countOpenClose(data: Table[string, (DateTime, string, float, float, bool)]): Table[string, CountTable[bool]] =

  result = initTable[string, CountTable[bool]]()

  for k, v in data:
    if not result.hasKey(v[1]):
      result[v[1]] = initCountTable[bool]()
    result[v[1]].inc(v[4])

proc valueOpenClose(data: Table[string, (DateTime, string, float, float, bool)]) =

  var value = initTable[WeekDay, float]()

  for k, v in data:
    var day: string = v[0].format("dddd")
    var month: string = v[0].format("MM")
    var year: string  = v[0].format("yyyy")
    discard value.hasKeyOrPut(v[0].weekday, 0)
    #echo "DATA: {year} {month} {day} {v[2]} {v[3]} {v[3]-v[2]:9.3f}".fmt
    value[v[0].weekday] += (v[3] - v[2])

  echo value


proc fc(y,n: int): string =
  var per = (float(y) / float(n + y)) * 100
  result = "{y} / {n} ({per:3.1f}%)".fmt

proc main(csvFn: string)=

  var tab = newAsciiTable()
  tab.tableWidth = 80

  var data = parse(csvFn)
  let oneMonth = filter(data, now() - 1.months, now())
  let sixMonths = filter(data, now() - 6.months, now())
  let oneYear = filter(data, now() - 1.years, now())
  let om = countOpenClose(oneMonth)
  let sm = countOpenClose(sixMonths)
  let oy = countOpenClose(oneYear)
  valueOpenClose(oneMonth)
  valueOpenClose(sixMonths)
  valueOpenClose(oneYear)

  echo now().weekday

  tab.setHeaders(@["D.O.W.", "1 month", "6 months", "1 year"])
  tab.addRow(@["Monday", fc(om["Monday"][true], om["Monday"][false]) , fc(sm["Monday"][true],sm["Monday"][false]), fc(oy["Monday"][true], oy["Monday"][false])])
  tab.addRow(@["Tuesday", fc(om["Tuesday"][true], om["Tuesday"][false]) , fc(sm["Tuesday"][true],sm["Tuesday"][false]), fc(oy["Tuesday"][true], oy["Tuesday"][false])])
  tab.addRow(@["Wednesday", fc(om["Wednesday"][true], om["Wednesday"][false]) , fc(sm["Wednesday"][true],sm["Wednesday"][false]), fc(oy["Wednesday"][true], oy["Wednesday"][false])])
  tab.addRow(@["Thursday", fc(om["Thursday"][true], om["Thursday"][false]) , fc(sm["Thursday"][true],sm["Thursday"][false]), fc(oy["Thursday"][true], oy["Thursday"][false])])
  tab.addRow(@["Friday", fc(om["Friday"][true], om["Friday"][false]) , fc(sm["Friday"][true],sm["Friday"][false]), fc(oy["Friday"][true], oy["Friday"][false])])


  printTable(tab)

dispatch(main)
