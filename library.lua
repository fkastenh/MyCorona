-- ----------------------------------------------------------------------------------------------
--
_L = {}
_L._COPYRIGHT=
[[
 Copyright (C) 2020 Frank Kastenholz
]]
_L._LICENSE = [[
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]
--
-- ----------------------------------------------------------------------------------------------

pl=require("pl")
date=require("date")

-- ----------------------------------------------------------------------------------------------
--
-- Read in a file in the format of "covid_19_data.csv"
-- SNo,ObservationDate,Province/State,Country/Region,Last Update,Confirmed,Deaths,Recovered
--    1,01/22/2020,Anhui,Mainland China,1/22/2020 17:00,1.0,0.0,0.0
--
-- Returns the data as a list of the following tables:
--    {
--       SNo=
--       ObservationDate=
--       Province_State=
--       Country_Region=
--       Last_Update=
--       Confirmed=
--       Deaths=
--       Recovered=
--       day_number = number of days since 1/1/2019
--    }
--    The fields map to the obvious fields in the COVID CSV file
--
-- Takes the name of the file to read
-- Will error() if there is n unrecoverable error
-- Will return false,<msg> if there is a recoverable error
-- Will return true,<table> if all is well.
--
-- ----------------------------------------------------------------------------------------------
local function read_covid_19_data_csv(filename)
   local fh = io.open(filename, "r")
   if (fh == nil) then
      return false, "Can not open \""..filename.."\""
   end

   local indata = data.read(fh, {delim=",",
			       csv=true})

   local n
   local dataset={}
   for n=1,#indata,1 do
      dataset[n] = {}
      dataset[n].SNo = indata[n][1]
      dataset[n].ObservationDate = indata[n][2]
      dataset[n].Province_State = indata[n][3]
      dataset[n].Country_Region = indata[n][4]
      dataset[n].Last_Update = indata[n][5]
      dataset[n].Confirmed = indata[n][6]
      dataset[n].Deaths = indata[n][7]
      dataset[n].Recovered = indata[n][8]
      dataset[n].day_number = _L.calculate_day_number(indata[n][2])
   end
   return true,dataset
end
_L.read_covid_19_data_csv = read_covid_19_data_csv

-- ----------------------------------------------------------------------------------------------
--
-- Given a dataset from read_covid_19_data_csv, will scan the dataset
-- and return a table indexed by the countries found in the
-- dataset. The value of the entry is the number of records found in
-- the dataset that are for the country.
--
--    country_list = get_country_list(dataset)
--    for country,count in pairs(country_list) do
--       print("Country: "..country.."  has "..tostring(count).." entries")
--    end
--
-- The country list can be iterated over with penlight's tablex.sort() 
--
-- ----------------------------------------------------------------------------------------------

local function get_country_list(dataset)
   local countries={}
   local ndx,record
   for ndx,record in pairs(dataset) do
      local c = record.Country_Region
      if countries[c] == nil then
	 countries[c] = 1
      else
	 countries[c] = countries[c] + 1
      end
   end
   return countries
end

_L.get_country_list = get_country_list

-- ----------------------------------------------------------------------------------------------
--
-- Will scan a dataset from read_covid_19_data_csv() and produce a
-- table containing confirmed cases, deaths, and recovered-cases, for
-- a specified country on a daily basis:
--
--    country_data = get_country_data(dataset, "Ruritania")
--    print("Ruritania has the following COVID 19 data:")
--    for date, record in tablex.sort(country_data) do
--       print("Date: "..date.."  has "
--             ..tostring(record.confirmed).." confirmed cases, "
--             ..tostring(record.deaths).." deaths, and "
--             ..tostring(recovered).." recovered cases.")
--    end
--
-- ----------------------------------------------------------------------------------------------
local function get_country_data(dataset, country)
  local country_data={}
   local ndx,record
   for ndx,record in pairs(dataset) do
      if (record.Country_Region == country) then
	 local d = record.ObservationDate
	 local day_number = record.day_number
	 _L.add_to_day_number_map(day_number, d)
	 local confirmed = record.Confirmed
	 local deaths = record.Deaths
	 local recovered = record.Recovered
	 if (country_data[d] == nil) then
	    country_data[d] = {}
	    country_data[d].confirmed = confirmed
	    country_data[d].deaths = deaths
	    country_data[d].recovered = recovered
	    country_data[d].day_number = day_number
	 else
	    country_data[d].confirmed = country_data[d].confirmed + confirmed
	    country_data[d].deaths = country_data[d].deaths + deaths
	    country_data[d].recovered = country_data[d].recovered + recovered
	 end
      end
   end
   return country_data
end
_L.get_country_data = get_country_data

-- ----------------------------------------------------------------------------------------------
--
-- Given a DATE string from the dataset (in form mm/dd/yyyy) will compute a relative day
-- number (number of days since 01/01/2019) and return it.
--
-- ----------------------------------------------------------------------------------------------
local function calculate_day_number(date_string)
   local mm,dd,yyyy = date_string:match("^([0-1][0-9])/([0-3][0-9])/([0-9][0-9][0-9][0-9])$")
   local d = date(yyyy, mm, dd)
   local epoch = date(2019, 1, 1)
   local date_diff = date.diff(d, epoch)
   local day_number = date_diff:spandays()
   return day_number
end
_L.calculate_day_number = calculate_day_number

-- ----------------------------------------------------------------------------------------------
--
-- This maps between day-number (since 1/1/2019) and the date-string, and vice-versa. For example
--     day_number_map[1] contains "01/02/2019"
--     day_number_map["01/02/2019"] contains 1
--
-- Only entries for which there actually are days in the data set are built.
--
-- ----------------------------------------------------------------------------------------------
local day_number_map = {}
_L.day_number_map = day_number_map
local function add_to_day_number_map(dn, ds)
   _L.day_number_map[dn] = ds
   _L.day_number_map[ds] = dn
   return
end
_L.add_to_day_number_map = add_to_day_number_map


local function run_ave_factory(d)
   local R = 0
   local alpha = 1/d

   return function (M)
      R = (alpha * M) + ((1-alpha)*R)
      return R
   end
end
local function run_ave_factoryx(n)

   local num_limit = n
   local points = {}
   local max_index = 1
   local sum=0
   
   return function (data_point)
      print("dp=",tostring(data_point))
      sum = sum + data_point
      points[max_index] = data_point
      max_index = max_index + 1
      if max_index > num_limit then
	 sum = sum -    points[max_index - num_limit]
	 points[max_index - num_limit] = nil
	 return sum/num_limit
      end
      return sum/(max_index - 1)
   end
end
_L.run_ave_factory = run_ave_factory

-- -----------------------------------------------------------------------------------
--
-- Gets dataset[n] ... where n is a day number
--
-- -----------------------------------------------------------------------------------
local function get_by_n(dataset, N)

   local d, r
   for d,r in pairs(dataset) do
      if r.day_number == N then return d,r end
   end
   return "00-00-0000",{deaths=0, recovered = 0, confirmed = 0}
end
_L.get_by_n = get_by_n

return _L
