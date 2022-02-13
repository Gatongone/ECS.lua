if not setfenv then
    local function findenv(f)
        local level = 1
        --遍历拿到上文
        repeat
            local name, value = debug.getupvalue(f, level)
            if name == "_ENV" then
                return level, value
            end
            level = level + 1
        until name == nil
        return nil
    end
    ---Version: >= Lua5.2
    getfenv = function(f)
        return (select(2, findenv(f)) or _G)
    end
    ---Version: >= Lua5.2
    setfenv = function(f, t)
        local level = findenv(f)
        if level then
            debug.setupvalue(f, level, t)
        end
        return f
    end
end

if table.copy == nil  then
    function table.copy(target)
        local clone = {}
        for key, value in pairs(target) do
            clone[key] = value
        end
        return clone
    end
end

---------------ECS---------------

-- 实体
Entity = function ()
    return 
    {
        index = 0,
        version = 1,
        isActived = true,
    }
end
-- 组件
Component = function (...)
    World.MaxComponentId = World.MaxComponentId + 1
    local result = ...
    result.index = World.MaxComponentId
    return result
end
-- 系统
System = function (...)
    local system = ...
    system.isActived = true
    table.insert(World.Systems,system)
    return system
end

-- 实体集合
Entities = 
{
    --- @param argsTable table
    --- @param callback function
    Foreach = function (argsTable,callback)     
        local components = nil
        setmetatable(argsTable,{__index = _G})
        for i = 1, #Entities do
            entity = Entities[i]
            if entity ~= nil then
                components = World.EntityManager.Entity2ComponentMapping[entity]
                for key, value in pairs(argsTable) do
                    argsTable[key] = components[value.index]
                end
                setfenv(callback,argsTable)
                callback(entity)
            end
        end
    end
}

-- 世界，在这里调用所有系统的生命周期
World =
{
    -- 组件最大ID
    MaxComponentId = 0,
    -- 系统集合
    Systems = {},
    -- 实体集合
    Entities = Entities,
    -- 实体管理器
    EntityManager = 
    {
        -- 实体池
        EntityPool = {},
        -- 实体组件映射
        Entity2ComponentMapping = {},
        CreateEntity = function (this,...)
            local entity = nil
            if #this.EntityPool == 0 then
                entity = table.copy(Entity())
                table.insert(Entities,entity)
                entity.index = #Entities
            else
                entity = this.EntityPool[#this.EntityPool]
                table.remove(this.EntityPool)
                Entities[entity.index] = entity
                entity.isActived = true
            end
            this:AddComponent(entity,...)
            if entity.OnEnable then
                entity:OnEnable()
            end
            return entity
        end,
        RecycleEntity = function(this,entity)
            this.Entity2ComponentMapping[entity] = nil
            Entities[entity.index] = nil
            table.insert(this.EntityPool,entity)
            entity.version = entity.version + 1
            entity.isActived = false
            if entity.OnRecycle then
                entity:OnRecycle()
            end
        end,
        DestroyEntity = function (this,entity)
            this.Entity2ComponentMapping[entity] = nil
            Entities[entity.index] = nil
            if entity.OnDestroy then
                entity:OnDestroy()
            end
        end,
        AddComponent = function (this,entity,...)

            if this.Entity2ComponentMapping[entity] == nil then
                this.Entity2ComponentMapping[entity] = { }
            end

            local args = {...}

            for i=1,#args do
                this.Entity2ComponentMapping[entity][args[i].index] = table.copy(args[i])
            end
        end,
        RemoveComponent = function (entity,componentType)
            this.Entity2ComponentMapping[entity][componentType.index]= nil
        end,
        GetComponent = function (this,entity,componentType)
            return this.Entity2ComponentMapping[entity][componentType.index]
        end,
    },
    --系统开始前调用
    OnStart = function ()
        local system = nil
        for i = 1, #World.Systems do
            system = World.Systems[i]
            if system.isActived and system.OnStart then
                system.OnStart()
            end
        end
    end,
    --帧更新调用
    OnUpdate = function ()
        local system = nil
        for i = 1, #World.Systems do
            system = World.Systems[i]
            if system.isActived and system.OnUpdate then
                system.OnUpdate()
            end
        end
    end,
    --设置系统激活状态
    SetSystemActived = function (system,actived)
        system.isActived = actived
        if actived then
            if system.OnEnable then
                system.OnEnable()
            end
        else
            if system.OnDisabled then
                system.OnDisable()
            end
        end
    end
}
