-----------------------------------------------------------
-- NOTES: This file is run on app start after exports are done inside 
-- 		  the engine (once per context created)
-----------------------------------------------------------


-- set up path (does not actually work at the moment)
package.path = package.path .. ";script\\?.lua;script\\country\\?.lua"
package.path = package.path .. ";common\\defines\\?.lua"

--require('hoi') -- already imported by game, contains all exported classes
require('00_defines')
require('tweaks')
require('diplomacy')
require('ai_diplomacy')

