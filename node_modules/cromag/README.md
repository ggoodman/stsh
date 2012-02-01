# Cromag - Advanced Date and Time, No Monkeys

## In a Nutshell

- Drop in replacement for `Date`
- Adds tons of functionality
- Works in Node.js and in the browser
- No monkeys

## Using in the browser

    <script src="cromag.min.js"></script>
    <script>
      var now = new Cromag();
      console.log(now.toString());
    </script>

## Using in Node.js

    $ npm install cromag
    
    var Cromag = require('cromag');
    
    var now = new Cromag();
    console.log(now.toString());

## API

### Constructor

Creates a `Cromag` instance which allows you to work with dates and times.

    new Cromag()
    new Cromag(milliseconds)
    new Cromag(dateString)
    new Cromag(year, month, day [, hour, minute, second, millisecond ])

**milliseconds** - `Number` representing the number of milliseconds since `1 January 1970 00:00:00 UTC`
**dateString** - `String` value representing a date
**year** - `Number` representing the year
**month** - `Number` representing the month, `0` for `January` through `11` for `December`
**day** - `Number` representing the day of the month `1-31`
**hour** - `Number` representing the hour of the day `0-23`
**minute** - `Number` representing the minute of the hour `0-59`
**second** - `Number` representing the second of the minute `0-59`
**millisecond** - `Number` representing the millisecond `0-999`

### Static Methods

#### now

Returns the number of `milliseconds` of the current time.  Equivalent to `+new Cromag()` or `new Cromag().valueOf()`

    Cromag.now()

#### parse

Returns the number of `milliseconds` of the time passed as `dateString`.

    Cromag.parse(dateString)
    Cromag.parse(dateString, format)

**dateString** - `String` value representing a date
**format** - `String` representing a date format

#### UTC

Returns the number of `milliseconds` representing universal time for the parameters provided.  These parameters are the same as the long form of the `constructor`.

    Cromag.UTC(year, month, day)
    Cromag.UTC(year, month, day, hour)
    Cromag.UTC(year, month, day, hour, minute)
    Cromag.UTC(year, month, day, hour, minute, second)
    Cromag.UTC(year, month, day, hour, minute, second, millisecond)

**year** - `Number` representing the year
**month** - `Number` representing the month, `0` for `January` through `11` for `December`
**day** - `Number` representing the day of the month `1-31`
**hour** - `Number` representing the hour of the day `0-23`
**minute** - `Number` representing the minute of the hour `0-59`
**second** - `Number` representing the second of the minute `0-59`
**millisecond** - `Number` representing the millisecond `0-999`

#### today

Returns a new instance of `Cromag` set to `00:00:00` local time of the current day.

    Cromag.today()

#### tomorrow

Returns a new instance of `Cromag` set to `00:00:00` local time of the next day.

    Cromag.tomorrow()

#### yesterday

Returns a new instance of `Cromag` set to `00:00:00` local time of the previous day.

#### validateDay

Returns `boolean` as to whether the date passed is valid.

    Cromag.validateDay(day, year, month)

**day** - `Number` representing the day of the month, `1-31`
**year** - `Number` representing the year
**month** - `Number` representing the month, `0-11`

#### validateYear

Returns `boolean` as to whether the year passed is valid

    Cromag.validateYear(year)

**year** - `Number` representing the year

#### validateMonth

Returns `boolean` as to whether the month passed is valid

    Cromag.validateMonth(month)

**month** - `Number` representing the month, `1-31`

#### validateHour

Returns `boolean` as to whether the hour passed is valid

    Cromag.validateHour(hour)

**hour** - `Number` representing the hour, `0-23`

#### validateMinute

Returns `boolean` as to whether the minute passed is valid

    Cromag.validateMinute(minute)

**minute** - `Number` representing the minute, `0-59`

#### validateSecond

Returns `boolean` as to whether the second passed is valid

    Cromag.validateSecond(second)

**second** - `Number` representing the second, `0-59`

#### validateMillisecond

Returns `boolean` as to whether the millisecond passed is valid

    Cromag.validateMillisecond(millisecond)

**millisecond** - `Number` representing the millisecond, `0-999`

#### compare

Returns `-1` if `date1` is less than `date2`, `0` if they are the same, or `1` if `date1` is more recent than `date2`.

    Cromag.compare(date1, date2)

**date1** - `Cromag` first date/time to compare
**date2** - `Cromag` second date/time to compare

#### equals

Returns `boolean` as to whether `date1` is equal to `date2`.

    Cromag.equals(date1, date2)

**date1** - `Cromag` first date/time to compare
**date2** - `Cromag` second date/time to compare

#### getDayNumberFromName

Returns the `Number` representing the day passed in, `0-7`

    Cromag.getDayNumberFromName(name)

**name** - `String` day as 2 characters, 3 characters, or full day, `su/sun/sunday`

#### getMonthNumberFromName

Returns the `Number` representing the month passed in, `0-11`

    Cromag.getMonthNumberFromName(name)

**name** - `String` day as 3 characters or full month, `jan/january`

#### isLeapYear

Returns `boolean` as to whether the year passed is a leap year

    Cromag.isLeapYear(year)

**year** - `Number` year to check

#### getDaysInMonth

Returns the `Number` of days in the month passed, `1-31`

    Cromag.getDaysInMonth(monthNumber)

**monthNumber** - `Number` of the month to check, `0-11`

### Instance Methods

#### getDate

Returns the `Number` day of the month, `1-31`

    d.getDate()

#### getDay

Returns the `Number` day of the week, `0-6`

    d.getDay()

#### getFullYear

Returns the `Number` full year, 4 digits

    d.getFullYear()

#### getHours

Returns the `Number` of the hour, `0-23`

    d.getHours()

#### getMilliseconds

Returns the `Number` of the milliseconds, `0-999`

    d.getMilliseconds()

#### getMinutes

Returns the `Number` of the minutes, `0-59`

    d.getMinutes()

#### getMonth

Returns the `Number` of the month, `0-11`

    d.getMonth()
