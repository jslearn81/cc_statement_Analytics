# Singapore Credit Card Statement Analytics

This is a hackish code written in R for me to track personal credit card spendings and to track the spending category.
I believe it might benefit others

#Currently it supports the following:

1. DBS Credit Card statement (PDF) - I only tested on my range of Credit card so far
2. UOB Credit Card xls
3. Amex CSVs download

Code Example
====

<b>1. extract_dbs_pdf_cc_table</b>


Call:
extract_dbs_pdf_cc_table('statement.pdf')

Returns:

|date       |acct |item                                     |    amt|
|:----------|:----|:----------------------------------------|------:|
|2020-08-22 |dbs  |LAZADA SINGAPORE                         |  15.57|
|2020-08-23 |dbs  |SHOPEEPAY                                | 110.00|
|2020-08-23 |dbs  |SHOPEEPAY                                |  70.25|
|2020-08-24 |dbs  |BLUESG                                   |  47.19|


<b>2. extract_amex_csv_cc_table</b>

Call:
extract_amex_csv_cc_table('amex.csv')
Returns:

|date       |acct |item                                  |     amt|
|:----------|:----|:-------------------------------------|-------:|
|2020-08-20 |AMEX |GRAB*IOS-xxxx785-9-aaa SINGAPORE      |    9.00|
|2020-08-21 |AMEX |GRAB*IOS-xxxx785-9-aaa SINGAPORE      |   13.00|
|2020-08-22 |AMEX |GRAB*IOS-xxxx785-9-aaa SINGAPORE      |   13.00|


<b>3. extract_uob_pdf_cc_table </b>

Call:
extract_uob_pdf_cc_table('downloaded.xls')

Returns:

|date       |acct                 |item                                                                     |   amt|
|:----------|:--------------------|:------------------------------------------------------------------------|-----:|
|2020-09-18 |UOB aaaa |NTUC FP-BT PANJANG PLZ   SINGAPORE    SG Ref No: 7450aaaaaaaaaaaaaaaaa61009467324190 | 25.48|



<b>4. tag_spending</b>

Call
tag_spending(df) #DF generated from above

returns:

Adds a TAG for category


|TAG                  |  N|
|:--------------------|--:|
|BILL                 |  4|
|TRANSPORT/BUSMRT     | 40|
|FOOD/RESTAURANT      | 23|



How you can contribute ? 
====
Looking for people to:
1.  Enhance/'robustify' current functions
2.  Add new Singapore banks data format to this
3.  Expand Tagging dictionary
