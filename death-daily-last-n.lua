--
-- Calculate "todays" death rate as a % of the number of infections
-- that occured in the last N days
--
local copyright = [[
  Copyright (C) 2020 Frank Kastenholz
]]

local license = [[

Copyright (C) 2020 Frank Kastenholz

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
local major_version = 0
local minor_version = 1

pl=require("pl")
app.require_here() -- so the library can be required
l=require("library")
getopt=require("fkgetopt")

local title = "Death rate for new cases over the last N days"
local output_file_name=nil
local do_country_list=false
local data_file = "novel-corona-virus-2019-dataset/covid_19_data.csv"
local generate_gnuplot_output = false
local gnuplot_execute = false
local country=""
local N_days = 14

local function calc_pct(yesterday, today)
   if yesterday == nil then return 0 end
   if yesterday == 0 then return 0 end
   return 100*((today-yesterday)/yesterday)
end
	 
-- ------------------------------------------------------------------------
--
-- Generates output suitable for feeding to gnuplot as a command file.
--
-- ------------------------------------------------------------------------
local function generate_gp(fh, dataset)
   ra = l.run_ave_factory(8)
   fh:write("$DataSet << EOD\n")
   local date, record
   local yesterday
   for date, record in tablex.sort(dataset) do
      local first_record_date,first_record = l.get_by_n(dataset, record.day_number - N_days)
      local deaths = record.deaths - first_record.deaths
      local confirmed = record.confirmed - first_record.confirmed
      local pct = 0
      if (confirmed ~= 0) then pct = (deaths / confirmed) * 100 end
      fh:write(string.format("%d %d %f\n",
			     confirmed, deaths, pct))
   end
   fh:write("EOD\n")
   fh:write("set terminal X11\n")
   fh:write("set y2tics\n")
   fh:write("set title \""..title.." for "..country.."\"\n")
   fh:write("plot $DataSet using 1 with linespoints lw 3  title \"Confirmed cases\", "..
	       "$DataSet using 2 with linespoints lw 3 title \"Deaths\", "..
	       "$DataSet using 3 with linespoints lw 3 title \"Death Rate\" axes x1y2\n")
   return
end
-- ------------------------------------------------------------------------
--
-- PRINT some basic command line help
--
-- ------------------------------------------------------------------------
local function print_help_text()
   print("death-rate [options] [country]")
   print("   Calculates the death rate w.r.t. the new cases over the previous")
   print("   N days of a specified country.")
   print("   CLI options are:")
end -- of print-help
-- ------------------------------------------------------------------------
--
-- CLI Argument table
--
-- ------------------------------------------------------------------------
argspec = {
   ["license"] = {
      reqflag="none", negflag=true,
      func=function(word, val, optspec, negflag)
	 print(license)
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s ", long_cli_opt)
	 end
	 ht[#ht+1] = "Print license text"
	 return ht
      end,
      dump= function(outfunc)
      end,
   },
   ["version"] = {
      reqflag="none", negflag=true,
      func=function(word, val, optspec, negflag)
	 print("DEATH-RATE.LUA, a part of MyCorona")
	 print(" Version "..tostring(major_version).."."..
		  tostring(minor_version))
	 print(copyright)
	 print(" do \"death-rate.lua --license\" for full license")
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s ", long_cli_opt)
	 end
	 ht[#ht+1] = "Print version information"
	 return ht
      end,
      dump= function(outfunc)
      end,
   },

   ["?"] = "help",
   ["help"] = {reqflag="none",
	       func=function (word, val, optspec, negflag)
		  print_help_text()
		  getopt.output_help(argspec, print)
		  os.exit(0)
	       end,
	       help="Print help text and exit",
	       dump=nil,
   },
   ["o"] = "outfile",
   ["outfile"] = {
      reqflag="required",
      func=function(word, val, optspec, negflag)
	 output_file_name = val
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s=OUTFILENAME ", long_cli_opt)
	 end
	 if (short_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("-%s OUTFILENAME ", short_cli_opt)
	 end
	 ht[#ht+1] = "Set name of output file. Default will send output to stdout."
	 return ht
      end,
      dump= function(outfunc)
	 outfunc("outfile is "..output_file_name)
      end,
   },
   ["N"] = {
      reqflag="required",
      func=function(word, val, optspec, negflag)
	 N_days = tonumber(val)
	 if (N_days == nil) then
	    error ("Expect a number for -N, not "..tostring(val))
	 end
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s=N-days ", long_cli_opt)
	 end
	 if (short_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("-%s N-days ", short_cli_opt)
	 end
	 ht[#ht+1] = "Set number of days to look at. Default is "..tostring(N_days)
	 return ht
      end,
      dump= function(outfunc)
	 outfunc("N is "..tostring(N_days))
      end,
   },
   ["gp_title"] = {
      reqflag="required",
      func=function(word, val, optspec, negflag)
	 title = val
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s=title-string ", long_cli_opt)
	 end
	 if (short_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("-%s title-string ", short_cli_opt)
	 end
	 ht[#ht+1] = "Set title string of gnuplot chart. Default is \""
	    ..title.."\""
	 return ht
      end,
      dump= function(outfunc)
	 outfunc("title is "..title)
      end,
   },
   ["datafile"] = {
      reqflag="required",
      func=function(word, val, optspec, negflag)
	 data_file = val
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s=DATA_FILE_NAME ", long_cli_opt)
	 end
	 if (short_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("-%s DATA_FILE_NAME ", short_cli_opt)
	 end
	 ht[#ht+1] = "Set name of input data file. Default is \""..data_file.."\""
	 return ht
      end,
      dump= function(outfunc)
	 outfunc("datafile is "..data_file)
      end,
   },
   ["gpx"] = {
      reqflag="optional",
      func=function(word, val, optspec, negflag)
	 if (val == nil) then
	    gnuplot_execute = true
	 else
	    gnuplot_execute = val
	 end
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s[=gnuplot command string] ", long_cli_opt)
	 end
	 if (short_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("-%s [gnuplot command string] ", short_cli_opt)
	 end
	 ht[#ht+1] = "Will cause gnuplot to be executed from within the program, plotting the "
	    .."data in the output file. The filename is appended to the command string. "
  	    .."If the command string is not given then \"../bin/gnuplot --persist \" "
	    .."is used as the string."
	 return ht
      end,
      dump= function(outfunc)
	 outfunc("datafile is "..data_file)
      end,
   },
   ["gnuplot"] = {
      reqflag="none", negflag=false,
      func=function(word, val, optspec, negflag)
	 generate_gnuplot_output = true
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s ", long_cli_opt)
	 end
	 if (short_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("-%s ", short_cli_opt)
	 end
	 ht[#ht+1] = "Will generate output suitable for feeding to gnuplot"
	 return ht
      end,
      dump= function(outfunc)
      end,
   },
   ["countrylist"] = {
      reqflag="none", negflag=false,
      func=function(word, val, optspec, negflag)
	 do_country_list = true
	 return nil
      end,
      help=function(short_cli_opt, long_cli_opt)
	 local ht = {} -- help text
	 if (long_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("--%s ", long_cli_opt)
	 end
	 if (short_cli_opt ~= nil) then
	    ht[#ht+1] = string.format("-%s ", short_cli_opt)
	 end
	 ht[#ht+1] = "Will output the country list and exit"
	 return ht
      end,
      dump= function(outfunc)
      end,
   },
}

-- ------------------------------------------------------------------------
--
-- cl_parse callback for unknown options
--
-- ------------------------------------------------------------------------
local function  bad_option_upcall(word, val, optspec, negflag)
   if (val == nil) then
      return string.format("Invalid option \"%s\" Exiting", word)
   end
   return string.format("Invalid option \"%s=%s\", exiting",
			word, tostring(val))
end

-- ------------------------------------------------------------------------
--
--
--
-- ------------------------------------------------------------------------
local function main(arg)

   local non_opts = getopt.cl_parse(arg, argspec, nil, bad_option_upcall)
   if type(non_opts) == "string" then
      utils.printf("CLI Parse error \"%s\"\n\n", non_opts)
      print_help_text()
      getopt.output_help(argspec, print)
      utils.printf("EXITING\n")
      return false, "CLI Parse error"
   end

   if (do_country_list) then
      local rc,dataset = l.read_covid_19_data_csv(data_file)
      if (rc ~= true) then
	 error("Read covid error: "..dataset)
      end
      local country_list = l.get_country_list(dataset)
      local country, count
      for country,count in tablex.sort(country_list) do
	 print("Country: "..country.."  has "..tostring(count).." entries")
      end
      return true
   end

   if (#non_opts ~= 1) then
      print("Missing country name")
      print_help_text()
      getopt.output_help(argspec, print)
      print("EXITING")
      return false, "CLI Parse error"
   end
   local of
   if output_file_name == nil then
      of = io.output()
   else
      of = io.open(output_file_name, "w")
      if (of == nil) then
	 error("Can not open output file: \""..output_file_name.."\"")
      end
   end
   --
   -- read in the raw data set
   --
   local rc,dataset = l.read_covid_19_data_csv(data_file)
   if (rc ~= true) then
      error("Read covid error: "..dataset)
   end
   --
   -- generate the day-by-day data for the country
   --
   country = non_opts[1]
   local country_data = l.get_country_data(dataset, country)

   if (generate_gnuplot_output) then
      generate_gp(of, country_data)
   else
      print(country.." has the following COVID 19 data:")

      local date, record, yesterday
      for date, record in tablex.sort(country_data) do
	 local first_record_date,first_record = l.get_by_n(country_data, record.day_number - N_days)
	 local deaths = record.deaths - first_record.deaths
	 local confirmed = record.confirmed - first_record.confirmed
	 local pct = 0
	 if (confirmed ~= 0) then pct = (deaths / confirmed) * 100 end
	 of:write(string.format("Date: %s (%d) has %d confirmed, %d deaths, %f%% death rate, end_date = %s\n",
				date, record.day_number,
				confirmed, deaths, pct, first_record_date))
      end
   end
   if output_file_name ~= nil then
      of:close()
   end

   if (generate_gnuplot_output) then
      if (gnuplot_execute ~= false) then
	 print("Executing GNUPLOT on output file")
	 if (gnuplot_execute == true) then
	    os.execute("../bin/gnuplot --persist "..output_file_name)
	 else
	    os.execute(gnuplot_execute.." "..output_file_name)
	 end
      end
   end
end



local rc,msg = pcall(main, arg)
if (rc == false) then
   print("Aborting due to error:\n", msg)
   os.exit(99)
end
os.exit(0)


