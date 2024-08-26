

--used to create netlimitedstrings
LuaUserData.RegisterType("Barotrauma.NetLimitedString")
blue_prints.net_limited_string_type = LuaUserData.CreateStatic("Barotrauma.NetLimitedString", true)

--for accessing component values inside components
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Item"], "GetInGameEditableProperties")
LuaUserData.RegisterType("System.ValueTuple`2[System.Object,Barotrauma.SerializableProperty]")

--used to create immutable arrays
LuaUserData.RegisterType("System.Collections.Immutable.ImmutableArray")
LuaUserData.RegisterType("System.Collections.Immutable.ImmutableArray`1")
blue_prints.immutable_array_type = LuaUserData.CreateStatic("System.Collections.Immutable.ImmutableArray", false)