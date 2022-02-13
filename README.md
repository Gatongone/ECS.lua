用Lua实现的最简单的ECS思想，之后尝试移植到Unity3D

# Usage
```lua
require "ECS"

Move = Component
{
    speed = 1
}

Jump = Component
{
    height = 2
}

MovementSystem = System
{
    OnUpdate = function()
        Entities.Foreach({ move = Move,jump = Jump },function(entity)
            move.speed = move.speed + 1
            jump.height = jump.height + 1
            print(entity.index,move.speed,jump.height)
        end)
    end
}

local entity1 = World.EntityManager:CreateEntity(Move,Jump)
local entity2 = World.EntityManager:CreateEntity(Move,Jump)

World.EntityManager:GetComponent(entity1,Move).speed = 3

--模拟帧更新调用
for i=1,10 do
    World:OnUpdate()
end
```
