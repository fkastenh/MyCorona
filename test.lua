-- Copyright (C) 2020 Frank Kastenholz
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pl=require("pl")
app.require_here() -- so the library can be required
l=require("library")


local rc,dataset = l.read_covid_19_data_csv("novel-corona-virus-2019-dataset/covid_19_data.csv")

local country_list = l.get_country_list(dataset)
local country, count
for country,count in tablex.sort(country_list) do
   print("Country: "..country.."  has "..tostring(count).." entries")
end

local country_data = l.get_country_data(dataset, "US")
print("US has the following COVID 19 data:")
local date, record
for date, record in tablex.sort(country_data) do
   print("Date: "..date.."  has "
	    ..tostring(record.confirmed).." confirmed cases, "
	    ..tostring(record.deaths).." deaths, and "
	    ..tostring(recovered).." recovered cases.")
end

