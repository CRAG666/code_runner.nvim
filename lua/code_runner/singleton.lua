local function Singleton(class)
  local instance = nil

  local originalNew = class.new

  class.new = function(...)
    if instance == nil then
      if originalNew then
        instance = originalNew(...)
      else
        instance = setmetatable({}, class)
        if instance.ctor then
          instance:ctor(...)
        end
      end
    end
    return instance
  end

  return class
end
return Singleton
