# API docs

## Contents
1. [Requests](#requests)
1. [Responses](#responses)
1. [Endpoints](#endpoints)
   1. [GET /exchange-rate](#get-/exchange-rate)
   1. [GET /exchange-currency](#get-/exchange-currency)
   1. [GET /supported-currencies](#get-/supported-currencies)
   1. [GET /earliest-supported-date](#get-/earliest-supported-date)
   1. [GET /latest-supported-date](#get-/latest-supported-date)

## Requests

* All currency codes on request input must conform to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217).
* All dates must be strings in the format of `YYYY-MM-DD` e.g. `2018-01-25`.

## Responses

All responses will be of JSON content type. All responses will be an object. This object will either contain the result of the request on the `result` key, where the value can be of any type, or they will contain an `errors` key which will hold an array of strings. HTTP status codes are also used to denote response types. Below are examples of valid responses.

Internal server error
```
HTTP/1.1 500 Internal Server Error
Content-Type: application/json
...

{
  "errors": [ "internal server error" ]
}
```

Bad request error
```
HTTP/1.1 400 Bad Request
Content-Type: application/json
...

{
  "errors": [ "invalid parameter X, expected Y" ]
}
```

Successful request
```
HTTP/1.1 200 OK
Content-Type: application/json
...

{
  "result": "success"
}
```

## Endpoints
### GET /exchange-rate

Gets the exchange rate as a floating point for a specific date from one currency into another.

#### Input

| Param | Type | Required? |
| ----- | ---- | --------- |
| date | String | Yes |
| from_currency_code | String | Yes |
| to_currency_code | String | Yes |

#### Output

Floating point

#### Example
```
GET /exchange-rate?date=2018-12-20&from_currency_code=USD&to_currency_code=GBP

...

{ "result": 1.1232566 }
```

### GET /exchange-currency

Converts an amount of one currency into another on a given date.

#### Input

| Param | Type | Required? |
| ----- | ---- | --------- |
| date | String | Yes |
| from_currency_code | String | Yes |
| to_currency_code | String | Yes |
| amount | Float | Yes |

#### Output

Floating point (rounded to 2 decimal places)

#### Example
```
GET /exchange-currency?date=2018-12-20&from_currency_code=USD&to_currency_code=GBP&amount=200

...

{ "result": 224.65 }
```

### GET /supported-currencies

Get a list of supported currencies on a given date.

#### Input

| Param | Type | Required? |
| ----- | ---- | --------- |
| date | String | Yes |

#### Output

Array of strings

#### Example
```
GET /supported-currencies?date=2018-12-20

...

{ "result": [ "USD", "JPN", "GBP", "AUD" ] }
```

### GET /earliest-supported-date

Get the earliest supported date.

#### Input

N/A

#### Output

String date in format `YYYY-MM-DD`

#### Example
```
GET /earliest-supported-date

...

{ "result": "2018-09-04" }
```

### GET /latest-supported-date

Get the latest supported date.

#### Input

N/A

#### Output

String date in format `YYYY-MM-DD`

#### Example
```
GET /latest-supported-date

...

{ "result": "2018-12-22" }
```
