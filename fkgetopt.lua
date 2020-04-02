-- ------------------------------------------------------------
-- ------------------------------------------------------------
--
-- Frank Kastenholz' CLI Option Library
--
-- ------------------------------------------------------------
-- ------------------------------------------------------------
--
-- License & Copyright, both as header and vars in the lib.
_O={}
_O.copyright="Copyright (c) 2020, Frank Kastenholz"
_O.license=[[
   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation
   files (the "Software"), to deal in the Software without
   restriction, including without limitation the rights to use, copy,
   modify, merge, publish, distribute, sublicense, and/or sell copies
   of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions: 

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software. 

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
]]
-- ---------------------------------------------------------------
--
-- version info
--
-- ---------------------------------------------------------------
_O.major_version=0
_O.minor_version=50

_O.pl = require("pl")
_O.tablex = require("pl.tablex")
_O.text = require("pl.text")

-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--
-- Command line parsing and help-text outputting.
--
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--
-- Scan the option table looking for entries that are help=
-- For each, output the help info
-- 
-- If help= is a string, just output that string as it is.
-- If help= specifies a function, call the function to
-- generate the output string. The function signature is
--     help_func(short_opt, long_opt)
-- and it should return a list of two lines of text:
--     [1] is the generic format of the option (eg "--bubba=name_of_bubba")
--     [2] is the help text.
--
-- outfunc does the actual outputting. it takes a string. If nil,
-- it defaults to print().  We assume that outfunc does a newline
-- after each call, ala print()
--
-- ----------------------------------------------------------------------
_O.help_line_len = 72
_O.help_indent_len = 8
local function output_help(opt_table,
			   outfunc)
   if (type(opt_table) ~= "table") then
      error("Error, opt_table is not a table, it is ".. type(opt_table))
      return
   end

   if (outfunc == nil) then
      outfunc = print
   end
   local _opt,_opt_spec

   -- TODO: Handle cases of option synonyms, both in order
   -- to group them all together and to avoid trying to
   -- dereference a string as a table.
   for _opt, _opt_spec in _O.tablex.sort(opt_table) do
      local helptext={}
      -- first, generate the raw help information. it consists
      -- of a list of N strings. strings [1] to [N-1] are
      -- assumed to be the option text (--opt=val or -o val or ...)
      -- the Nth string is the actual help text, which is indented
      -- and formatted to line length.
      if (type(_opt_spec.help) == "string") then
	 -- format the option string itself.
	 local ostring=""
	 if (string.len(_opt) == 1) then
	    -- the table gives the help text...
	    ostring = "-".._opt
	    if (type(_opt_spec.reqflag) ~= "nil") then
	       if (string.lower(_opt_spec.reqflag) == "required") then
		  ostring = ostring.." val"
	       elseif(string.lower(_opt_spec.reqflag) == "optional") then
		  ostring = ostring.." [val]"
	       end
	    end
	 else
	    -- do the newer --foo=bar option style
	    ostring = "--".._opt
	    if (type(_opt_spec.reqflag) ~= "nil") then
	       if (string.lower(_opt_spec.reqflag) == "required") then
		  ostring = ostring.."=val"
	       elseif(string.lower(_opt_spec.reqflag) == "optional") then
		  ostring = ostring.."[=val]"
	       end
	    end
	    if (_opt_spec.negflag == true) then
	       ostring = ostring..", --no".._opt
	    end
	 end
	 helptext[1] = ostring
	 helptext[2] = _opt_spec.help
	 -- end of generating help text when explicitly given.
      elseif (type(_opt_spec.help) == "function") then
	 if (string.len(_opt) == 1) then
	    helptext = _opt_spec.help(_opt, nil)
	 else
	    helptext = _opt_spec.help(nil, _opt)
	 end
      else
	 -- neither a string nor a function, could be nil or
	 -- a synonym reference. ignore it for now.
      end
      if (#helptext ~= 0) then
	 local newstrings={}
	 -- now format the help text.
	 outfunc(helptext[1]) -- is at least one line in help text
	 if (#helptext == 2) then
	    new_strings=_O.text.wrap(helptext[2],
				     _O.help_line_len)
	 elseif(#helptext==3) then
	    outfunc(helptext[2])
	    new_strings=_O.text.wrap(helptext[3],
				     _O.help_line_len)
	 else 
	    error("Bad nr of strings "..tostring(#helptext).." in help text")
	 end
	 local i=1
	 while (new_strings[i] ~= nil) do
	    local indstring= _O.text.indent(new_strings[i], _O.help_indent_len)
	    -- the :sub(1,-2) is so that we output all but the last character of the
	    -- string; penlight's indent gratuitiously adds a newline to the input.
	    outfunc(indstring:sub(1,-2))
	    i = i + 1
	 end
      end -- of if (#helptext ~= 0)
   end
end
_O.output_help = output_help

-- ------------------------------------------------------------------
--
-- Option table entry and appropriate function to set the
-- line length for generating help output
--
-- ------------------------------------------------------------------
local function get_help_ll()
   return _O.help_line_len
end
_O.get_help_ll = get_help_ll

local function generate_help_ll_help(short_cli_opt, long_cli_opt)
   local ht = {} -- help text
   if (long_cli_opt ~= nil) then
      ht[#ht+1] = string.format("--%s=NUMBER ", long_cli_opt)
   end
   if (short_cli_opt ~= nil) then
      ht[#ht+1] = string.format("-%s NUMBER ", short_cli_opt)
   end
   ht[#ht+1] = string.format("Set help output line length to NUMBER. Default is %d",
		      _O.get_help_ll())
   return ht
end
_O.generate_help_ll_help = generate_help_ll_help

local function set_help_ll(_v)
   local v = _O.help_line_len
   _O.help_line_len=_v
   return v
end
_O.set_help_ll = set_help_ll

local function get_help_ll_string()
   return "Help line length: ".._O.help_line_len
end
_O.get_help_ll_string = get_help_ll_string

local help_ll_opt_table={
   reqflag="required",
   func=function (word, val, optspec, negflag)
      local v = tonumber(val)
      _O.set_help_ll(v)
      return nil
   end,
   help=_O.generate_help_ll_help,
   dump=function(outfunc)
      outfunc("Help line length: ".._O.help_line_len)
   end,
}
_O.help_ll_opt_table = help_ll_opt_table

-- ------------------------------------------------------------------
--
-- Option table entry and appropriate function to set the
-- indent for generating help output
--
-- ------------------------------------------------------------------

local function get_help_indent()
   return _O.help_indent_len
end
_O.get_help_indent = get_help_indent

local function generate_help_indent_help(short_cli_opt, long_cli_opt)
   local ht = {} -- help text
   if (long_cli_opt ~= nil) then
      ht[#ht+1] = string.format("--%s=NUMBER ", long_cli_opt)
   end
   if (short_cli_opt ~= nil) then
      ht[#ht+1] = string.format("-%s NUMBER ", short_cli_opt)
   end
   ht[#ht+1] = string.format("Set help output line indent to NUMBER. Default is %d",
			     _O.get_help_indent())
   return ht
end
_O.generate_help_indent_help = generate_help_indent_help

local function set_help_indent(_v)
   local v = _O.help_indent_len
   _O.help_indent_len=_v
   return v
end
_O.set_help_indent = set_help_indent

local function get_help_indent_string()
   return "Help line length: ".._O.help_indent_len
end
_O.get_help_indent_string = get_help_indent_string

local help_indent_opt_table={
   reqflag="required",
   func=function (word, val, optspec, negflag)
      local v = tonumber(val)
      _O.set_help_indent(v)
      return nil
   end,
   help=_O.generate_help_indent_help,
   dump=function(outfunc)
      outfunc(_O.get_help_indent_string())
   end,
   
}
_O.help_indent_opt_table = help_indent_opt_table


-- ----------------------------------------------------------------------
-- 
-- Generate a useful X/NOX string for outputting in help text.
-- 
-- Basically, if BOOLVAR == BOOLTERM it returns S else it returns NO..S
-- 
-- ----------------------------------------------------------------------
local function boolstring(boolvar,boolterm,s)
   if (boolvar==boolterm) then 
      return s
   end
   return "NO"..s
end
_O.boolstring = boolstring

-- ----------------------------------------------------------------------
--
-- Parse the command line.
-- 
-- Check command line tokens in arg[] for options we understand and 
-- Do The Right Thing with regard to those options.
--
-- returns table of non-options/NIL if no error, else an error string.
--
-- opt_spec is
--   reqflag="required"|"optional"|"none"   
--                         whether the option requires additional arguments
--                         or not (or may have them)
--                         if not present, it is same as "none"
--                         if boolean then true/false are "required"/"none", 
--                         respectively.
--   func=...              function to call with the option's value (if any)
--                         takes word,value,, optspec, negflag)
--   help=..               Function or  help text, used by output_help() above
--   negflag=true/false/nil  (nil==false). If true, allow --nooption or -no
--                         to negate an option (typically a boolean)
--   dump=  function to call to dump the option value. see dump_opts.
--
-- All options are of the form  --ooo --ooo=vvv or -c -c val
--     (also allow -cvalue and -c=value ... good if c is required to have
--      a value.)
-- The "-c val" form must be a single token.
--
-- if nonnil, will call arg_upcall for each non-option on the command line,
-- also gathers them into an array and returns same.
--
-- if an option table entry is a string then that refers to another option:
--   opts={
--     ["foo"] = "bar",
--     ["bar"] = { reqflag=, func=, ...}
--   }
-- makes FOO a synonym for BAR.
--
-- arg_upcall - optional, is called for each non-option encountered.
--      This may allow options and non-options to be intertwingled.
-- bad_opt_upcall - optional; if not-nil will be called when a bad or
--      unknown option is encountered. The call signature is the same
--      as the opt_table.func signature.
--
-- Usage note:
--    for binary options (--xxx vs --noxxx) suggest having noxxx
--    be a synonym for xxx and then have the xxx handler look for
--    the no prefix.
--
-- ----------------------------------------------------------------------

-- TODO Add more detailed syntaxes for the options, such as lists of keywords,
--  numbers, strings, etc. 

-- these are all the values allowed for reqflag. the numbers make it 
-- easier.
-- 
local _required_flag_values = {
   ["optional"] = 0,
   ["opt"] = 0,
   ["required"] = 1,
   ["req"] = 1,
   ["no"] = -1,
   ["none"] = -1,
}
local function cl_parse(argv,       -- input argv[]
			opt_spec,   -- array of specifications of each option
                        arg_upcall, -- call for non-options (arguments)
			bad_opt_upcall) -- optional upcall if there is a bad/invalid argument

   local function get_req_flag_val(f)
      if type(f) == "nil" then return -1 end
      if type(f) == "boolean" then
	 if f == false then return -1 end
	 return 1
      end
      return _required_flag_values[string.lower(f)]
   end

   --
   -- find the canonical optspec that is for the given option.
   -- deals with synonyms
   --
   local function get_optspec(w, osp)
      if osp[w] == nil then return nil end
      if type(osp[w]) == "string" then return get_optspec(osp[w], osp) end
      return osp[w]
   end

   -- return N, word, val
   -- N is number of arguments used:
   --   -1 means WORD is not an option, 
   --   0 means error
   --   1,2 uses 1 or 2 words from the cli 
   -- word is the option or argument (--X ... produces X)
   -- val is the (optional) value associated with the arg
   local function get_words(arg, argnxt)
      local word=nil
      local val=nil
      if (string.match(arg, "^%-%-") == "--") then
	 -- is long-form
	 word = string.match(arg, "^%-%-(.+)=")
	 if (word == nil) then
	    word = string.match(arg, "^%-%-(.+)")
	    return 1, word, nil
	 end
	 val = string.match(arg, "=(.+)$")
	 return 1, word, val
      end
      if (string.match(arg, "^%-") == "-") then
	 -- is short-form
	 --    -x
	 --    -x <value> (must not begin with -
	 --    -x<value>
	 --    -x=<value>
	 -- handle case of just -
	 if #arg == 1 then return 0, nil, nil end
	 word = string.sub(arg, 2,2) -- get arg char
	 if #arg == 2 then
	    -- could be -x val ... see if argnxt is nonnil and its 1st 
	    -- char is not - if so, it's the value
	    if (argnxt ~= nil) then
	       if (argnxt:sub(1,1) ~= "-") then
		  -- it is of the form -x val
		  return 2, word, argnxt
	       end
	    end
	    -- argnxt is nil, or begins with -  ... we are of te form -x
	    return 1, word, nil
	 end
	 -- this arg is longer than 2 characters
	 if arg:sub(3,3) == "=" then
	    -- is form -x=ssss
	    return 1, word, arg:sub(4,-1)
	 end
	 return 1,word,arg:sub(3,-1)
      end -- of handling the -x form
      -- must be a non-arg
      return -1, arg, nil
   end -- of function to do arg parse

   local ndx=1
   local k,v
   local rc
   local ndx_inc
   local non_opts = {}

   while(true) do
      ndx_inc = 0
      local word
      local val
      if (argv[ndx] == nil) then
	 return non_opts
      end

      ndx_inc, word, val = get_words(argv[ndx], argv[ndx+1])
      if (ndx_inc == 0) then
	 return string.format("Error parsing command line \"%s\" \"%s\"",
			      argv[ndx], argv[ndx+1])
      end
      if (ndx_inc == -1) then
	 -- does not begin --, consider it an argument to pass to the app.
	 non_opts[#non_opts+1] = word
	 if (arg_upcall ~= nil) then
	    rc=arg_upcall(word)
	    if (rc ~= nil) then
	       return rc
	    end
	 end
	 ndx_inc = 0
      else
	 -- is a -x or --x
	 ndx_inc = ndx_inc - 1
	 local ospec
	 local negflag=false
	 if (word==nil) then
	    return "Parse error in command string"
	 end
	 ospec=get_optspec(word, opt_spec)
	 if (ospec == nil) then
	    -- didn't find WORD in the option table, how about NOWORD?
	    if (word:sub(1,2) == "no") then
	       -- It starts with NO...
	       ospec=get_optspec(word:sub(3,-1), opt_spec)
	       -- Find something?
	       if (ospec == nil) then
		  -- nothing...
		  if (bad_opt_upcall ~= nil) then
		     bad_opt_upcall(word, val, opt_spec, true)
		  end
		  return string.format("Unknown option \"--%s\"", word)
	       end
	       -- we found something, if there is not a NEGFLAG=TRUE then
	       -- NOWORD is not allowed here...
	       if (ospec.negflag ~= true) then
		  return string.format("NO form not allowed for option \"--%s\"", word)
	       end
	       negflag=true
	    else
	       if (bad_opt_upcall ~= nil) then
		  bad_opt_upcall(word, val, opt_spec, true)
	       end
	       return string.format("Unknown option \"--%s\"", word)
	    end -- of having a NO
	 end
	 -- ospec is the option table entry we care about.

	 local val_flag= get_req_flag_val(ospec.reqflag)
	 if (val_flag == 1) then
	    -- there better be a value to the option
	    if (val == nil) then
	       return string.format("No value for option \"--%s\", which requires one", word)
	    end
	 elseif (val_flag == -1) then
	    if (val ~= nil) then
	       return string.format(
		  "Option \"--%s\" has value \"%s\", which is prohibited", 
		  word, val)
	    end
	 end

	 rc = ospec.func(word, val, opt_spec, negflag)
	 if (rc ~= nil) then
	    return rc
	 end
      end -- end of processing an option (--xxxxx[=qqq])

      ndx = ndx + 1 + ndx_inc

   end -- of looping through cli options/arguments/
end
_O.cl_parse = cl_parse

--
-- run the option definition table, calling the dumper to dump
-- the option's current value.
--
local function dump_opts(opt_table,
			 outfunc)
   if (outfunc == nil) then
      outfunc = print
   end
   local _opt,_opt_spec

   -- TODO: Handle cases of option synonyms, both in order
   -- to group them all together and to avoid trying to
   -- dereference a string as a table.
   for _opt, _opt_spec in _O.tablex.sort(opt_table) do
      -- opt-spec could be a string, referencing another
      -- opt-spec ... only dump if it is a table.
      if (type(_opt_spec) == "table") then
	 if (type(_opt_spec.dump) == "function") then
	    _opt_spec.dump(outfunc)
	 end
      end
   end
end
_O.dump_opts = dump_opts

local dump_opts_flag = false
_O.dump_opts_flag = dump_opts_flag

local function get_dump_opts()
   return _O.dump_opts_flag
end
_O.get_dump_opts = get_dump_opts


local function set_dump_opts(_v)
   local v = _O.dump_opts_flag
   _O.dump_opts_flag=_v
   return v
end
_O.set_dump_opts = set_dump_opts

local dump_opts_table={
   reqflag="none",
   func=function (word, val, optspec, negflag)
      _O.set_dump_opts(true)
      return nil
   end,
   help="Causes the options to be dumped after the command line is parsed",
   dump=function(outfunc)
      outfunc(_O.get_help_indent_string())
   end,
}
_O.dump_opts_table = dump_opts_table

return _O
